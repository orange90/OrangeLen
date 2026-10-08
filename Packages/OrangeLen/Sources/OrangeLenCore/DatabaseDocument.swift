import Foundation
import CSQLite

public final class DatabaseDocument: @unchecked Sendable {
    private var database: OpaquePointer?
    private let lock = NSLock()
    private let limits: PreviewLimits
    private final class Budget {
        let token: Cancellation; let deadline: TimeInterval
        init(_ token: Cancellation, _ seconds: Double) { self.token = token; deadline = ProcessInfo.processInfo.systemUptime + seconds }
    }
    public init(data: Data, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws {
        self.limits = limits
        try cancellation.check()
        guard data.count >= 100, data.count <= limits.containerBytes, data.starts(with: Data("SQLite format 3\0".utf8)) else { throw PreviewError.malformed(L10n.text("SQLite 头或大小")) }
        guard data[18] == 1, data[19] == 1 else { throw PreviewError.malformed(L10n.text("WAL 数据库不能作为独立一致快照；请预览完整的已关闭数据库副本")) }
        var db: OpaquePointer?
        guard sqlite3_open_v2(":memory:", &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK, let db else { throw PreviewError.malformed(L10n.text("SQLite 初始化")) }
        database = db
        guard let buffer = sqlite3_malloc64(UInt64(data.count)) else { sqlite3_close(db); database = nil; throw PreviewError.limit(L10n.text("数据库内存")) }
        data.copyBytes(to: buffer.assumingMemoryBound(to: UInt8.self), count:data.count)
        let code = sqlite3_deserialize(db,"main",buffer.assumingMemoryBound(to:UInt8.self),Int64(data.count),Int64(data.count),UInt32(SQLITE_DESERIALIZE_READONLY | SQLITE_DESERIALIZE_FREEONCLOSE))
        guard code == SQLITE_OK else { sqlite3_close(db); database = nil; throw PreviewError.malformed(L10n.text("数据库快照不可用")) }
        // Apple SDK omits load-extension APIs; no extension loading is exposed.
        sqlite3_limit(db,SQLITE_LIMIT_LENGTH,1_000_000); sqlite3_limit(db,SQLITE_LIMIT_COLUMN,Int32(limits.tableColumns)); sqlite3_limit(db,SQLITE_LIMIT_EXPR_DEPTH,64)
        sqlite3_exec(db,"PRAGMA trusted_schema=OFF; PRAGMA query_only=ON; PRAGMA temp_store=MEMORY;",nil,nil,nil)
        let budget = Budget(cancellation,limits.databaseSeconds)
        sqlite3_progress_handler(db,1000,{ context in
            guard let context else { return 1 }; let value = Unmanaged<Budget>.fromOpaque(context).takeUnretainedValue()
            return ((try? value.token.check()) == nil || ProcessInfo.processInfo.systemUptime > value.deadline) ? 1 : 0
        },Unmanaged.passUnretained(budget).toOpaque())
        defer { sqlite3_progress_handler(db,0,nil,nil) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db,"SELECT name FROM sqlite_schema WHERE type='table' AND name NOT LIKE 'sqlite_%' AND sql NOT LIKE 'CREATE VIRTUAL%' ORDER BY name LIMIT 257",-1,&statement,nil) == SQLITE_OK else { throw PreviewError.malformed(L10n.text("数据库结构不可读")) }
        defer { sqlite3_finalize(statement) }
        var names: [String] = []; var step = sqlite3_step(statement)
        while step == SQLITE_ROW {
            try cancellation.check()
            if let c = sqlite3_column_text(statement,0) { names.append(String(cString:c)) }
            step = sqlite3_step(statement)
        }
        guard step == SQLITE_DONE, names.count <= 256 else { throw PreviewError.limit(L10n.text("数据库结构/时间预算")) }
        self.tableStorage = names
    }
    private var tableStorage: [String] = []
    public var tableNames: [String] { tableStorage }
    deinit { if let database { sqlite3_close(database) } }
    public struct Column: Sendable, Equatable {
        public let name: String
        public let declaredType: String
        public let notNull: Bool
        public let primaryKey: Int
    }
    public enum Cell: Sendable, Equatable {
        case null, number(String), text(String), blob(Data), invalidText(Data)
        public var display: String {
            switch self {
            case .null: return "NULL"
            case .number(let value), .text(let value): return value
            case .blob(let data): return "[BLOB \(data.count) bytes]"
            case .invalidText(let data): return L10n.text("[非 UTF-8 TEXT \(data.count) bytes]")
            }
        }
        public var kind: String {
            switch self { case .null: return "NULL"; case .number: return L10n.text("数值"); case .text: return "TEXT"; case .blob: return "BLOB"; case .invalidText: return L10n.text("TEXT（非 UTF-8）") }
        }
        /// Lossless SQLite literal, including NULL, arbitrary blobs, and text NULs.
        public var sqlLiteral: String {
            func hex(_ data: Data) -> String { "X'" + data.map { String(format: "%02X", $0) }.joined() + "'" }
            switch self {
            case .null: return "NULL"
            case .number(let value): return value
            case .text(let value): return value.contains("\0") ? "CAST(" + hex(Data(value.utf8)) + " AS TEXT)" : "'" + value.replacingOccurrences(of: "'", with: "''") + "'"
            case .blob(let data): return hex(data)
            case .invalidText(let data): return "CAST(" + hex(data) + " AS TEXT)"
            }
        }
    }
    public static func tsvField(_ value: String) -> String {
        value.contains(where: { "\t\r\n\"".contains($0) }) ? "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" : value
    }
    public struct Page: Sendable {
        public let columns: [Column]
        public let cells: [[Cell]]
        public var rows: [[String]] { cells.map { $0.map(\.display) } }
        public let offset: Int
        public let hasNext: Bool
    }
    public func rows(_ table: String, cancellation: Cancellation = .init()) throws -> [[String]] {
        let result = try page(table, cancellation: cancellation)
        return [result.columns.map(\.name)] + result.rows
    }
    /// Only validated table/column names enter generated read-only queries. Values in
    /// the database never become SQL. Each page has its own time and byte budget.
    public func page(_ table: String, offset: Int = 0, pageSize: Int = 500, sortColumn: Int? = nil, ascending: Bool = true, cancellation: Cancellation = .init()) throws -> Page {
        lock.lock(); defer { lock.unlock() }
        guard tableStorage.contains(table), let db = database else { throw PreviewError.unsafePath }
        guard offset >= 0, offset <= Int(Int32.max), pageSize > 0, pageSize <= 1000 else { throw PreviewError.limit(L10n.text("数据库分页范围")) }
        try cancellation.check()
        let budget = Budget(cancellation, limits.databaseSeconds)
        sqlite3_progress_handler(db, 1000, { context in
            guard let context else { return 1 }
            let value = Unmanaged<Budget>.fromOpaque(context).takeUnretainedValue()
            return ((try? value.token.check()) == nil || ProcessInfo.processInfo.systemUptime > value.deadline) ? 1 : 0
        }, Unmanaged.passUnretained(budget).toOpaque())
        defer { sqlite3_progress_handler(db, 0, nil, nil) }
        func quote(_ value: String) -> String { "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        let quoted = quote(table)
        var info: OpaquePointer?
        guard sqlite3_prepare_v2(db, "PRAGMA table_xinfo(\(quoted))", -1, &info, nil) == SQLITE_OK else { throw PreviewError.malformed(L10n.text("数据库列结构")) }
        defer { sqlite3_finalize(info) }
        var columns: [Column] = []
        var state = sqlite3_step(info)
        while state == SQLITE_ROW {
            try cancellation.check()
            // Hidden virtual-table fields are not part of SELECT; generated columns (2/3) are.
            if sqlite3_column_int(info, 6) == 1 { state = sqlite3_step(info); continue }
            guard columns.count < limits.tableColumns else { throw PreviewError.limit(L10n.text("数据库列数")) }
            columns.append(.init(name: String(cString: sqlite3_column_text(info, 1)), declaredType: String(cString: sqlite3_column_text(info, 2)), notNull: sqlite3_column_int(info, 3) != 0, primaryKey: Int(sqlite3_column_int(info, 5))))
            state = sqlite3_step(info)
        }
        guard state == SQLITE_DONE, !columns.isEmpty else { throw PreviewError.malformed(L10n.text("数据库列结构不可读")) }
        if let sortColumn, !columns.indices.contains(sortColumn) { throw PreviewError.unsafePath }
        var ordering: [String] = []
        if let sortColumn { ordering.append(quote(columns[sortColumn].name) + (ascending ? " ASC" : " DESC")) }
        // Stable ties make moving between pages predictable. Use PK where present,
        // otherwise the unshadowed rowid alias of a regular table.
        let primary = columns.filter { $0.primaryKey > 0 }.sorted { $0.primaryKey < $1.primaryKey }
        ordering += primary.map { quote($0.name) + " ASC" }
        if primary.isEmpty, let rowID = ["_rowid_", "rowid", "oid"].first(where: { alias in !columns.contains { $0.name.lowercased() == alias } }) {
            ordering.append(quote(rowID) + " ASC")
        }
        let order = ordering.isEmpty ? "" : " ORDER BY " + ordering.joined(separator: ", ")
        var statement: OpaquePointer?
        let selectedColumns = columns.map { quote($0.name) }.joined(separator: ", ")
        let sql = "SELECT \(selectedColumns) FROM \(quoted)\(order) LIMIT \(pageSize + 1) OFFSET \(offset)"
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { throw PreviewError.malformed(L10n.text("表不可安全读取")) }
        defer { sqlite3_finalize(statement) }
        guard Int(sqlite3_column_count(statement)) == columns.count else { throw PreviewError.malformed(L10n.text("数据库列与结果不一致")) }
        guard sqlite3_stmt_readonly(statement) != 0 else { throw PreviewError.unsafePath }
        var rows: [[Cell]] = [], bytes = 0
        var step = sqlite3_step(statement)
        while step == SQLITE_ROW {
            try cancellation.check()
            var row: [Cell] = []
            for i in 0..<sqlite3_column_count(statement) {
                let type = sqlite3_column_type(statement, i)
                let count = Int(sqlite3_column_bytes(statement, i))
                bytes += count + 32
                guard bytes <= limits.archiveEntryBytes else { throw PreviewError.limit(L10n.text("表显示字节")) }
                let value: Cell
                if type == SQLITE_NULL { value = .null }
                else if type == SQLITE_INTEGER { value = .number(String(sqlite3_column_int64(statement, i))) }
                else if type == SQLITE_FLOAT {
                    let number = sqlite3_column_double(statement, i)
                    value = .number(number.isInfinite ? (number.sign == .minus ? "-9e999" : "9e999") : String(number))
                }
                else if type == SQLITE_BLOB {
                    value = .blob(sqlite3_column_blob(statement, i).map { Data(bytes: $0, count: count) } ?? Data())
                } else if let text = sqlite3_column_text(statement, i) {
                    let data = Data(bytes: text, count: Int(sqlite3_column_bytes(statement, i)))
                    if type == SQLITE_TEXT {
                        value = String(data: data, encoding: .utf8) == nil ? .invalidText(data) : .text(String(decoding: data, as: UTF8.self))
                    } else { value = .number(String(decoding: data, as: UTF8.self)) }
                } else { value = .text("") }
                row.append(value)
            }
            rows.append(row); step = sqlite3_step(statement)
        }
        guard step == SQLITE_DONE else { throw PreviewError.malformed(L10n.text("SQLite 读取取消、超时或损坏")) }
        let hasNext = rows.count > pageSize
        if hasNext { rows.removeLast() }
        return Page(columns: columns, cells: rows, offset: offset, hasNext: hasNext)
    }
}
