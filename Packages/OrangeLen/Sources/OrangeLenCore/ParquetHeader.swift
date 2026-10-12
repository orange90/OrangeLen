import Foundation

/// Bounded Thrift Compact footer inspection before the offline Arrow decoder runs.
public struct ParquetHeader: Sendable {
    public let rows: Int64, rowGroups: Int, uncompressedBytes: Int64, columns: Int
    indirect enum Value { case integer(Int64), text(String), list([Value]), fields([Int: Value]), other }
    struct Compact {
        var cursor: BinaryCursor; var nodes = 0
        mutating func variable() throws -> UInt64 {
            var value: UInt64 = 0
            for i in 0..<10 { let byte = try cursor.uint(1); guard i < 9 || byte <= 1 else { throw PreviewError.malformed("Thrift integer") }; value |= (byte & 127) << (i * 7); if byte & 128 == 0 { return value } }
            throw PreviewError.malformed("Thrift integer")
        }
        mutating func integer() throws -> Int64 { let raw = try variable(); return Int64(bitPattern:(raw >> 1) ^ (0 &- (raw & 1))) }
        mutating func fields(_ depth: Int) throws -> Value {
            var result: [Int:Value] = [:], last = 0
            while true {
                let header = try cursor.uint(1); if header == 0 { break }
                let delta = Int(header >> 4), field = delta == 0 ? Int(try integer()) : last + delta
                guard field > 0, result[field] == nil else { throw PreviewError.malformed("Thrift field") }
                last = field; result[field] = try value(header & 15,depth + 1)
            }
            return .fields(result)
        }
        mutating func value(_ type: UInt64, _ depth: Int) throws -> Value {
            nodes += 1; guard depth <= 64, nodes <= 100000 else { throw PreviewError.limit("Parquet metadata") }
            switch type {
            case 1,2: return .other
            case 3: _ = try cursor.uint(1); return .other
            case 4,5,6: return .integer(try integer())
            case 7: _ = try cursor.bytes(8); return .other
            case 8:
                let size = try variable(); guard size <= 1_048_576 else { throw PreviewError.limit("Thrift string") }
                return .text(String(decoding:try cursor.bytes(Int(size)),as:UTF8.self))
            case 9,10:
                let header = try cursor.uint(1), short = header >> 4, count = short == 15 ? try variable() : short
                guard count <= 20000 else { throw PreviewError.limit("Thrift list") }
                var result: [Value] = []; for _ in 0..<Int(count) { result.append(try value(header & 15,depth + 1)) }; return .list(result)
            case 11:
                let count = try variable(); guard count <= 20000 else { throw PreviewError.limit("Thrift map") }
                if count > 0 { let types = try cursor.uint(1); for _ in 0..<Int(count) { _ = try value(types >> 4,depth + 1); _ = try value(types & 15,depth + 1) } }; return .other
            case 12: return try fields(depth + 1)
            default: throw PreviewError.malformed("Thrift type")
            }
        }
    }
    public static func parse(_ data: Data, cancellation: Cancellation = .init()) throws -> Self {
        guard data.count >= 12, data.count <= 25 * 1024 * 1024, data.prefix(4) == Data("PAR1".utf8), data.suffix(4) == Data("PAR1".utf8) else { throw PreviewError.malformed("Parquet signature/25 MiB budget") }
        var tail = BinaryCursor(data:data.subdata(in:(data.count - 8)..<(data.count - 4)),token:cancellation)
        let size = try tail.length(4,maximum:4 * 1024 * 1024)
        guard size <= data.count - 12 else { throw PreviewError.malformed("Parquet footer") }
        var compact = Compact(cursor:.init(data:data.subdata(in:(data.count - 8 - size)..<(data.count - 8)),token:cancellation))
        guard case .fields(let fields) = try compact.fields(0), case .integer(let rows) = fields[3], case .list(let groups) = fields[4], rows >= 0 else { throw PreviewError.malformed("Parquet metadata") }
        var bytes: Int64 = 0, columns = 0
        for group in groups {
            guard case .fields(let fields) = group, case .integer(let size) = fields[2], case .list(let chunks) = fields[1], size >= 0, size <= 64 * 1024 * 1024 - bytes else { throw PreviewError.limit("Parquet uncompressed 64 MiB") }
            bytes += size; columns = max(columns,chunks.count)
            for chunk in chunks {
                guard case .fields(let outer) = chunk else { throw PreviewError.malformed("Parquet chunk") }
                if case .text(let path) = outer[1], !path.isEmpty { throw PreviewError.unsafePath }
            }
        }
        guard columns <= 256 else { throw PreviewError.limit("Parquet 256 columns") }
        return .init(rows:rows,rowGroups:groups.count,uncompressedBytes:bytes,columns:columns)
    }
}
