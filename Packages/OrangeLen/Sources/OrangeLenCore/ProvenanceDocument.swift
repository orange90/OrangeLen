import Foundation

/// JUMBF box catalogue and bounded JSON/CBOR assertion inspection, not signature verification.
public enum ProvenanceDocument {
    public static func parse(_ data: Data, cancellation: Cancellation = .init()) throws -> ScientificDocument {
        guard data.count <= 8 * 1024 * 1024 else { throw PreviewError.limit("C2PA sidecar 8 MiB") }
        var rows: [[String]] = [], assertions: [String] = [], count = 0
        func boxes(_ data: Data, _ path: String, _ depth: Int) throws {
            guard depth <= 16 else { throw PreviewError.limit("JUMBF depth") }
            var c = BinaryCursor(data:data,token:cancellation)
            while c.offset < data.count {
                count += 1; guard count <= 1000 else { throw PreviewError.limit("JUMBF boxes") }
                let start = c.offset; var size = try c.uint(4,big:true)
                let type = String(decoding:try c.bytes(4),as:UTF8.self)
                if size == 1 { size = try c.uint(8,big:true) }; if size == 0 { size = UInt64(data.count - start) }
                let header = c.offset - start
                guard size >= UInt64(header), size <= UInt64(data.count - start) else { throw PreviewError.malformed("JUMBF box length") }
                let payload = try c.bytes(Int(size) - header), name = path + "/" + type
                rows.append([name,String(size)])
                if type == "jumb" { try boxes(payload,name,depth + 1) }
                else if type == "jumd", payload.count >= 17 {
                    let flags = payload[16]
                    if flags & 2 != 0, let end = payload.dropFirst(17).firstIndex(of:0) { assertions.append(name + " label: " + String(decoding:payload[17..<end],as:UTF8.self)) }
                } else if type == "json", payload.count <= 1024 * 1024 {
                    let source = String(decoding:payload,as:UTF8.self); _ = try JSONParser.parse(source,cancellation:cancellation); assertions.append(name + "\n" + source)
                } else if type == "cbor", payload.count <= 1024 * 1024 {
                    var decoder = CBOR(cursor:.init(data:payload,token:cancellation))
                    let value = try decoder.read(0)
                    if JSONSerialization.isValidJSONObject(value) { let json = try JSONSerialization.data(withJSONObject:value,options:[.prettyPrinted,.sortedKeys]); assertions.append(name + "\n" + String(decoding:json,as:UTF8.self)) }
                }
            }
        }
        try boxes(data,"",0)
        guard !rows.isEmpty, rows.contains(where:{$0[0].contains("jumb")}) else { throw PreviewError.malformed("C2PA JUMBF container") }
        let summary = "C2PA / JUMBF\nContent credentials structure only. Cryptographic signatures and trust chains are NOT verified.\n" + String(assertions.joined(separator:"\n\n").prefix(65536))
        return .init(title:"C2PA",summary:summary,columns:["Box path","Bytes"],rows:rows)
    }
    struct CBOR {
        var cursor: BinaryCursor; var count = 0
        mutating func read(_ depth: Int) throws -> Any {
            count += 1; guard depth <= 32, count <= 20000 else { throw PreviewError.limit("CBOR structure") }
            let first = try cursor.uint(1), type = first >> 5, info = first & 31
            guard info < 28 else { throw PreviewError.malformed("CBOR indefinite/reserved items") }
            let raw = info < 24 ? info : try cursor.uint([24:1,25:2,26:4,27:8][info]!,big:true)
            switch type {
            case 0: return raw <= UInt64(Int64.max) ? NSNumber(value:raw) : String(raw)
            case 1: guard raw <= UInt64(Int64.max) else { return "negative integer" }; return -1 - Int64(raw)
            case 2,3:
                guard raw <= 1024 * 1024 else { throw PreviewError.limit("CBOR string") }; let data = try cursor.bytes(Int(raw))
                return type == 3 ? String(decoding:data,as:UTF8.self) : "binary: \(data.count) bytes"
            case 4:
                guard raw <= 5000 else { throw PreviewError.limit("CBOR array") }; var result: [Any] = []; for _ in 0..<Int(raw) { result.append(try read(depth + 1)) }; return result
            case 5:
                guard raw <= 5000 else { throw PreviewError.limit("CBOR map") }; var result: [String:Any] = [:]
                for _ in 0..<Int(raw) { let key = String(describing:try read(depth + 1)); result[key] = try read(depth + 1) }; return result
            case 6: return try read(depth + 1)
            case 7:
                if info == 20 { return false }; if info == 21 { return true }; if info == 22 || info == 23 { return NSNull() }
                if info == 25 { let v = Float(Float16(bitPattern:UInt16(raw))); return v.isFinite ? String(v) : "non-finite" }
                if info == 26 { let v = Float(bitPattern:UInt32(raw)); return v.isFinite ? String(v) : "non-finite" }
                if info == 27 { let v = Double(bitPattern:raw); return v.isFinite ? String(v) : "non-finite" }; return "simple \(raw)"
            default: throw PreviewError.malformed("CBOR")
            }
        }
    }
}
