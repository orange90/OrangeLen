import Foundation
import CSQLite

public final class DatabaseDocument: @unchecked Sendable {
    private var database: OpaquePointer?
    private let lock = NSLock()
    private let limits: PreviewLimits
    private final class Budget {
        let token: Cancellation; let deadline: Date
        init(_ token: Cancellation, _ seconds: Double) { self.token = token; deadline = Date().addingTimeInterval(seconds) }
    }
    public init(data: Data, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws {
        self.limits = limits
        guard data.count >= 100, data.count <= limits.containerBytes, data.starts(with: Data("SQLite format 3\0".utf8)) else { throw PreviewError.malformed("SQLite 头或大小") }
        guard data[18] == 1, data[19] == 1 else { throw PreviewError.malformed("WAL 数据库不能作为独立一致快照；请预览完整的已关闭数据库副本") }
        var db: OpaquePointer?
        guard sqlite3_open_v2(":memory:", &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK, let db else { throw PreviewError.malformed("SQLite 初始化") }
        database = db
        guard let buffer = sqlite3_malloc64(UInt64(data.count)) else { sqlite3_close(db); database = nil; throw PreviewError.limit("数据库内存") }
        data.copyBytes(to: buffer.assumingMemoryBound(to: UInt8.self), count:data.count)
        let code = sqlite3_deserialize(db,"main",buffer.assumingMemoryBound(to:UInt8.self),Int64(data.count),Int64(data.count),UInt32(SQLITE_DESERIALIZE_READONLY | SQLITE_DESERIALIZE_FREEONCLOSE))
        guard code == SQLITE_OK else { sqlite3_close(db); database = nil; throw PreviewError.malformed("数据库快照不可用") }
        // Apple SDK omits load-extension APIs; no extension loading is exposed.
        sqlite3_limit(db,SQLITE_LIMIT_LENGTH,1_000_000); sqlite3_limit(db,SQLITE_LIMIT_COLUMN,Int32(limits.tableColumns)); sqlite3_limit(db,SQLITE_LIMIT_EXPR_DEPTH,64)
        sqlite3_exec(db,"PRAGMA trusted_schema=OFF; PRAGMA query_only=ON; PRAGMA temp_store=MEMORY;",nil,nil,nil)
        let budget = Budget(cancellation,limits.databaseSeconds)
        sqlite3_progress_handler(db,1000,{ context in
            guard let context else { return 1 }; let value = Unmanaged<Budget>.fromOpaque(context).takeUnretainedValue()
            return ((try? value.token.check()) == nil || Date() > value.deadline) ? 1 : 0
        },Unmanaged.passUnretained(budget).toOpaque())
        defer { sqlite3_progress_handler(db,0,nil,nil) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db,"SELECT name FROM sqlite_schema WHERE type='table' AND name NOT LIKE 'sqlite_%' AND sql NOT LIKE 'CREATE VIRTUAL%' ORDER BY name LIMIT 257",-1,&statement,nil) == SQLITE_OK else { throw PreviewError.malformed("数据库结构不可读") }
        defer { sqlite3_finalize(statement) }
        var names: [String] = []; var step = sqlite3_step(statement)
        while step == SQLITE_ROW {
            try cancellation.check()
            if let c = sqlite3_column_text(statement,0) { names.append(String(cString:c)) }
            step = sqlite3_step(statement)
        }
        guard step == SQLITE_DONE, names.count <= 256 else { throw PreviewError.limit("数据库结构/时间预算") }
        self.tableStorage = names
    }
    private var tableStorage: [String] = []
    public var tableNames: [String] { tableStorage }
    deinit { if let database { sqlite3_close(database) } }
    public func rows(_ table: String, cancellation: Cancellation = .init()) throws -> [[String]] {
        lock.lock(); defer { lock.unlock() }
        guard tableStorage.contains(table), let db = database else { throw PreviewError.unsafePath }
        try cancellation.check()
        let budget = Budget(cancellation,limits.databaseSeconds)
        sqlite3_progress_handler(db,1000,{ context in
            guard let context else { return 1 }; let value = Unmanaged<Budget>.fromOpaque(context).takeUnretainedValue()
            return ((try? value.token.check()) == nil || Date() > value.deadline) ? 1 : 0
        },Unmanaged.passUnretained(budget).toOpaque())
        defer { sqlite3_progress_handler(db,0,nil,nil) }
        let quoted = "\"" + table.replacingOccurrences(of:"\"",with:"\"\"") + "\""
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db,"SELECT * FROM \(quoted) LIMIT \(limits.databaseRows)",-1,&statement,nil) == SQLITE_OK else { throw PreviewError.malformed("表不可安全读取（可能为虚拟表或不可信 schema）") }
        defer { sqlite3_finalize(statement) }
        var rows: [[String]] = []; let count = sqlite3_column_count(statement); var bytes = 0
        rows.append((0..<count).map { String(cString:sqlite3_column_name(statement,$0)) })
        var step = sqlite3_step(statement)
        while step == SQLITE_ROW {
            try cancellation.check()
            var row: [String] = []
            for i in 0..<count {
                let type = sqlite3_column_type(statement,i)
                let value: String
                if type == SQLITE_NULL { value = "NULL" }
                else if type == SQLITE_BLOB { value = "[BLOB \(sqlite3_column_bytes(statement,i)) bytes]" }
                else if let text = sqlite3_column_text(statement,i) { value = String(decoding:UnsafeBufferPointer(start:text,count:Int(sqlite3_column_bytes(statement,i))),as:UTF8.self) }
                else { value = "" }
                bytes += value.utf8.count; guard bytes <= limits.archiveEntryBytes else { throw PreviewError.limit("表显示字节") }
                row.append(value)
            }
            rows.append(row); step = sqlite3_step(statement)
        }
        guard step == SQLITE_DONE else { throw PreviewError.malformed("SQLite 读取取消、超时或损坏") }
        return rows
    }
}
