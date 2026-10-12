import Foundation

struct BinaryCursor {
    let data: Data; var offset = 0; let token: Cancellation
    mutating func bytes(_ count: Int) throws -> Data {
        try token.check(); guard count >= 0, offset >= 0, offset <= data.count, count <= data.count - offset else { throw PreviewError.malformed("Binary header is truncated") }
        defer { offset += count }; return data.subdata(in: offset..<(offset + count))
    }
    mutating func uint(_ count: Int, big: Bool = false) throws -> UInt64 {
        guard count <= 8 else { throw PreviewError.malformed("Integer width") }
        return try bytes(count).enumerated().reduce(0) { $0 | UInt64($1.element) << (8 * (big ? count - 1 - $1.offset : $1.offset)) }
    }
    mutating func length(_ count: Int = 8, maximum: Int = 1_000_000) throws -> Int {
        let value = try uint(count); guard value <= UInt64(maximum) else { throw PreviewError.limit("Binary count") }; return Int(value)
    }
    mutating func string() throws -> String { let count = try length(maximum: 1024 * 1024); guard let s = String(data: try bytes(count),encoding: .utf8) else { throw PreviewError.encoding }; return s }
}

public struct ScientificDocument: Sendable {
    public var title: String, summary: String, columns: [String], rows: [[String]]
    public init(title: String, summary: String, columns: [String], rows: [[String]]) { self.title = title; self.summary = summary; self.columns = columns; self.rows = rows }
    public var text: String { summary + "\n\n" + ([columns] + rows).map { $0.map { $0.replacingOccurrences(of:"\t",with:" ").replacingOccurrences(of:"\n",with:" ") }.joined(separator: "\t") }.joined(separator: "\n") }
    public static func supports(_ url: URL) -> Bool { ["c2pa","npy","safetensors","gguf","latent"].contains(url.pathExtension.lowercased()) }
    /// Header reads for multi-gigabyte weights never load the tensor payload.
    public static func load(_ url: URL, root: URL?, cancellation: Cancellation) throws -> (Self, String) {
        var limits = PreviewLimits(); limits.fileBytes = 8 * 1024 * 1024
        let ext = url.pathExtension.lowercased()
        if ["safetensors","latent"].contains(ext) {
            limits.fileBytes = 8
            let prefix = try AccessBroker.readBytes(url,root:root,limits:limits,cancellation:cancellation,allowPartial:true)
            var cursor = BinaryCursor(data:prefix.data,token:cancellation)
            let length = try cursor.length(maximum:4 * 1024 * 1024)
            guard length <= prefix.totalBytes - 8 else { throw PreviewError.malformed("Safetensors header length") }
            limits.fileBytes = length + 8
            let header = try AccessBroker.readBytes(url,root:root,limits:limits,cancellation:cancellation,allowPartial:true)
            guard header.revision == prefix.revision else { throw PreviewError.changed }
            return (try parse(header.data,name:url.lastPathComponent,totalBytes:header.totalBytes,cancellation:cancellation),header.revision)
        }
        let raw = try AccessBroker.readBytes(url,root:root,limits:limits,cancellation:cancellation,allowPartial:true)
        return (try parse(raw.data,name:url.lastPathComponent,totalBytes:raw.totalBytes,cancellation:cancellation), raw.revision)
    }
    public static func parse(_ data: Data, name: String, totalBytes: Int? = nil, cancellation: Cancellation = .init()) throws -> Self {
        let ext = (name as NSString).pathExtension.lowercased(), total = totalBytes ?? data.count
        if ext == "c2pa" { guard data.count == total else { throw PreviewError.limit("C2PA complete 8 MiB") }; return try ProvenanceDocument.parse(data,cancellation:cancellation) }
        if ext == "npy" { return try numpy(data,total:total,token:cancellation) }
        if ext == "gguf" { return try gguf(data,total:total,token:cancellation) }
        return try tensors(data,total:total,token:cancellation)
    }
    static func numpy(_ data: Data, total: Int, token: Cancellation) throws -> Self {
        var c = BinaryCursor(data:data,token:token)
        guard try c.bytes(6) == Data([147,78,85,77,80,89]) else { throw PreviewError.malformed("NPY signature") }
        let version = try c.length(1,maximum:3); let minor = try c.uint(1)
        guard version >= 1, minor == 0 else { throw PreviewError.malformed("NPY version") }
        let count = try c.length(version == 1 ? 2 : 4,maximum:65536)
        let header = String(decoding:try c.bytes(count),as:UTF8.self)
        func match(_ pattern: String) -> String? {
            guard let r = try? NSRegularExpression(pattern:pattern), let m = r.firstMatch(in:header,range:NSRange(location:0,length:header.utf16.count)), m.numberOfRanges > 1 else { return nil }
            return (header as NSString).substring(with:m.range(at:1))
        }
        guard let descriptor = match("['\"]descr['\"]\\s*:\\s*['\"]([^'\"]+)['\"]"), let shapeText = match("['\"]shape['\"]\\s*:\\s*\\(([^)]*)\\)"), let order = match("['\"]fortran_order['\"]\\s*:\\s*(True|False)") else {
            return .init(title:"NumPy",summary:"NPY structured dtype (header only; object/pickle payload is never evaluated)\n" + String(header.prefix(65536)),columns:[],rows:[])
        }
        let shape = shapeText.split(separator:",").map { $0.trimmingCharacters(in:.whitespaces) }.filter { !$0.isEmpty }
        guard shape.count <= 32, shape.allSatisfy({ Int($0).map { $0 >= 0 } == true }) else { throw PreviewError.malformed("NPY shape") }
        let dims = shape.compactMap(Int.init)
        var elements = 1
        for n in dims { let product = elements.multipliedReportingOverflow(by:n); guard !product.overflow else { throw PreviewError.limit("NPY shape product") }; elements = product.partialValue }
        let chars = Array(descriptor); let parsedSize = descriptor.hasSuffix("O") ? 8 : Int(String(chars.dropFirst(2))); guard chars.count >= 2, let size = parsedSize, size > 0, size <= 65536 else { throw PreviewError.malformed("NPY dtype") }
        let kind = chars[1], width = kind == "U" ? size * 4 : size
        let payload = elements.multipliedReportingOverflow(by:width)
        guard !payload.overflow else { throw PreviewError.limit("NPY payload size") }
        let object = kind == "O"
        if !object { guard c.offset <= total, payload.partialValue == total - c.offset else { throw PreviewError.malformed("NPY payload length") } }
        var rows: [[String]] = [], sampleBytes = 0
        let available = min(5000,min(elements,(data.count - c.offset) / width)), big = chars[0] == ">"
        if !object {
            for i in 0..<available {
                try token.check(); let valueData = try c.bytes(width); var v = BinaryCursor(data:valueData,token:token); let value: String
                if ["i","u","b","f"].contains(kind), [1,2,4,8].contains(width) {
                    let bits = try v.uint(width,big:big)
                    if kind == "f" && width == 2 { value = String(Float(Float16(bitPattern:UInt16(bits)))) }
                    else if kind == "f" && width == 4 { value = String(Float(bitPattern:UInt32(bits))) }
                    else if kind == "f" && width == 8 { value = String(Double(bitPattern:bits)) }
                    else if kind == "b" { value = bits == 0 ? "false" : "true" }
                    else if kind == "i" { let shift = 64 - width * 8; value = String((Int64(bitPattern:bits << shift)) >> shift) }
                    else { value = String(bits) }
                } else if kind == "S" { value = String(decoding:valueData.prefix(while:{$0 != 0}),as:UTF8.self) }
                else if kind == "U" {
                    var scalars = String.UnicodeScalarView()
                    for _ in 0..<size { let raw = try v.uint(4,big:big); if raw == 0 { break }; if let scalar = UnicodeScalar(UInt32(raw)) { scalars.append(scalar) } }
                    value = String(scalars)
                } else { value = valueData.prefix(32).map { String(format:"%02x",$0) }.joined(separator:" ") }
                let sample = String(value.prefix(4096)); sampleBytes += sample.utf8.count; if sampleBytes > 1024 * 1024 { break }; rows.append([String(i),sample])
            }
        }
        return .init(title:"NumPy",summary:"dtype: \(descriptor)\nshape: (\(shape.joined(separator:", ")))\nstorage: \(order == "True" ? "Fortran" : "C")\nelements: \(elements)\nShown \(rows.count) values in physical storage order. Object arrays: header only; pickle never runs.",columns:["Storage index","Value"],rows:rows)
    }
    static func tensors(_ data: Data, total: Int, token: Cancellation) throws -> Self {
        var c = BinaryCursor(data:data,token:token)
        let count = try c.length(maximum:4 * 1024 * 1024), header = try c.bytes(count)
        let source = String(decoding:header,as:UTF8.self); _ = try JSONParser.parse(source,cancellation:token)
        guard let object = try JSONSerialization.jsonObject(with:header) as? [String:Any], object.count <= 20000 else { throw PreviewError.malformed("Safetensors header") }
        var rows: [[String]] = [], ranges: [(Int,Int)] = []
        for key in object.keys.sorted() where key != "__metadata__" {
            try token.check(); guard let tensor = object[key] as? [String:Any], let dtype = tensor["dtype"] as? String, let shape = tensor["shape"] as? [Int], shape.count <= 32, shape.allSatisfy({$0 >= 0}), let offsets = tensor["data_offsets"] as? [Int], offsets.count == 2, offsets[0] >= 0, offsets[1] >= offsets[0], offsets[1] <= total - c.offset else { throw PreviewError.malformed("Safetensors tensor/offset") }
            if let width = ["BOOL":1,"U8":1,"I8":1,"F8_E4M3":1,"F8_E5M2":1,"U16":2,"I16":2,"F16":2,"BF16":2,"U32":4,"I32":4,"F32":4,"U64":8,"I64":8,"F64":8][dtype] {
                var elements = 1
                for n in shape { let next = elements.multipliedReportingOverflow(by:n); guard !next.overflow else { throw PreviewError.limit("Tensor shape product") }; elements = next.partialValue }
                let bytes = elements.multipliedReportingOverflow(by:width)
                guard !bytes.overflow, bytes.partialValue == offsets[1] - offsets[0] else { throw PreviewError.malformed("Tensor dtype/shape/byte length") }
            }
            ranges.append((offsets[0],offsets[1])); rows.append([key,dtype,shape.map(String.init).joined(separator:" × "),String(offsets[1] - offsets[0])])
        }
        ranges.sort {$0.0 < $1.0}; var previous = 0
        for range in ranges { guard range.0 == previous else { throw PreviewError.malformed("Safetensors overlaps or gaps") }; previous = range.1 }
        guard previous == total - c.offset else { throw PreviewError.malformed("Safetensors payload coverage") }
        let meta = object["__metadata__"] as? [String:String] ?? [:]
        let summary = "Safetensors / ComfyUI latent\n\(rows.count) tensors · \(total) bytes\nHeader only; tensor weights are not decoded.\n" + meta.keys.sorted().map { $0 + ": " + (meta[$0] ?? "") }.joined(separator:"\n")
        return .init(title:"Safetensors",summary:summary,columns:["Tensor","Dtype","Shape","Bytes"],rows:rows)
    }
    static func gguf(_ data: Data, total: Int, token: Cancellation) throws -> Self {
        var c = BinaryCursor(data:data,token:token)
        guard try c.bytes(4) == Data("GGUF".utf8), [2,3].contains(try c.uint(4)) else { throw PreviewError.malformed("GGUF v2/v3 signature") }
        let tensors = try c.length(maximum:20000), keys = try c.length(maximum:20000)
        var visited = 0
        func value(_ type: UInt64, _ cursor: inout BinaryCursor, _ depth: Int) throws -> String {
            try token.check(); visited += 1; guard visited <= 1_000_000, depth <= 4 else { throw PreviewError.limit("GGUF metadata") }
            switch type {
            case 8: return try cursor.string()
            case 9:
                let subtype = try cursor.uint(4), count = try cursor.length(maximum:1_000_000); var sample: [String] = []
                for i in 0..<count { let item = try value(subtype,&cursor,depth + 1); if i < 8 { sample.append(String(item.prefix(100))) } }
                return "[\(sample.joined(separator:", "))] (\(count) items)"
            case 0,1,2,3,4,5,6,7,10,11,12:
                let widths: [UInt64:Int] = [0:1,1:1,2:2,3:2,4:4,5:4,6:4,7:1,10:8,11:8,12:8]
                let size = widths[type]!, bits = try cursor.uint(size)
                if type == 6 { return String(Float(bitPattern:UInt32(bits))) }; if type == 12 { return String(Double(bitPattern:bits)) }
                if type == 7 { return bits == 0 ? "false" : "true" }
                if [1,3,5,11].contains(type) { let shift = 64 - size * 8; return String(Int64(bitPattern:bits << shift) >> shift) }
                return String(bits)
            default: throw PreviewError.malformed("GGUF metadata type")
            }
        }
        var metadata: [String] = []
        for _ in 0..<keys { let key = try c.string(), type = try c.uint(4); metadata.append(key + ": " + (try value(type,&c,0))) }
        var rows: [[String]] = []
        for _ in 0..<tensors {
            let name = try c.string(), dimensions = try c.length(4,maximum:8); var shape: [String] = []
            for _ in 0..<dimensions { shape.append(String(try c.uint(8))) }
            let type = try c.uint(4), offset = try c.uint(8)
            guard offset <= UInt64(total) else { throw PreviewError.malformed("GGUF tensor offset") }
            rows.append([name,"GGML type \(type)",shape.joined(separator:" × "),String(offset)])
        }
        return .init(title:"GGUF",summary:"\(tensors) tensors · \(total) bytes\nHeader only; weights are not loaded.\n" + metadata.joined(separator:"\n"),columns:["Tensor","Dtype","Shape","Relative offset"],rows:rows)
    }
}
