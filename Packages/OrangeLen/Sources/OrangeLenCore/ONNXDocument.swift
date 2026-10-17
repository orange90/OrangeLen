import Foundation

/// A bounded Protobuf wire reader. Tensor payloads and attribute/subgraph payloads are skipped.
public enum ONNXDocument {
    public static func load(_ url: URL, root: URL?, cancellation: Cancellation = .init()) throws -> ScientificDocument {
        let wire = try Wire(url: url, root: root, token: cancellation)
        let result = try parse(wire)
        try wire.verify()
        return result
    }
    public static func parse(_ data: Data, cancellation: Cancellation = .init()) throws -> ScientificDocument {
        try parse(Wire(data: data, token: cancellation))
    }
    private static func parse(_ w: Wire) throws -> ScientificDocument {
        let model = try w.fields(0..<w.total)
        guard let ir = model.first(where: { $0.number == 1 && $0.integer != nil })?.integer,
              let graph = model.first(where: { $0.number == 7 && $0.range != nil })?.range else { throw PreviewError.malformed("ONNX ModelProto IR / graph") }
        let producer = try w.string(model, 2), version = try w.string(model, 3)
        let opsets = try model.filter { $0.number == 8 && $0.range != nil }.map { field -> String in
            let fields = try w.fields(field.range!)
            return try w.string(fields, 1) + ":" + String(fields.first { $0.number == 2 }?.integer ?? 0)
        }
        let fields = try w.fields(graph)
        var rows: [[String]] = [], nodes = 0, weights = 0
        var ops: [String: Int] = [:]
        func append(_ row: [String]) throws { guard rows.count < 10000 else { throw PreviewError.limit("ONNX 10,000 rows") }; rows.append(row) }
        for field in fields {
            try w.token.check()
            guard let range = field.range else { continue }
            if [11,12].contains(field.number) {
                let info = try w.fields(range), name = try w.string(info, 1)
                var type = "unknown", shape = "unknown"
                if let typeRange = info.first(where: { $0.number == 2 })?.range {
                    let typeFields = try w.fields(typeRange)
                    if let tensor = typeFields.first(where: { $0.number == 1 })?.range {
                        let t = try w.fields(tensor)
                        type = dtype(t.first { $0.number == 1 }?.integer ?? 0)
                        if let dims = t.first(where: { $0.number == 2 })?.range {
                            shape = try w.fields(dims).filter { $0.number == 1 && $0.range != nil }.map { dim -> String in
                                let d = try w.fields(dim.range!)
                                if let value = d.first(where: { $0.number == 1 })?.integer { return String(value) }
                                let parameter = try w.string(d, 2); return parameter.isEmpty ? "?" : parameter
                            }.joined(separator: " × ")
                            if shape.isEmpty { shape = "scalar" }
                        }
                    } else { type = "sequence / map / optional / other" }
                }
                try append([field.number == 11 ? "Input" : "Output", name, type, shape, ""])
            } else if field.number == 1 {
                nodes += 1
                let n = try w.fields(range), op = try w.string(n, 4), domain = try w.string(n, 7)
                ops[domain.isEmpty ? op : domain + ":" + op, default: 0] += 1
                let inputs = try w.strings(n, 1), outputs = try w.strings(n, 2)
                try append(["Node", try w.string(n, 3), domain.isEmpty ? op : domain + ":" + op, inputs.joined(separator: ", "), outputs.joined(separator: ", ")])
            } else if field.number == 5 {
                weights += 1
                let tensor = try w.fields(range)
                let external = try tensor.filter { $0.number == 13 && $0.range != nil }.map { value -> String in
                    let pair = try w.fields(value.range!); return try w.string(pair, 1) + "=" + w.string(pair, 2)
                }.joined(separator: "; ")
                try append(["Initializer", try w.string(tensor, 8), dtype(tensor.first { $0.number == 2 }?.integer ?? 0), "payload skipped", external.isEmpty ? "embedded weights (not loaded)" : external])
            }
        }
        let summary = "ONNX · IR \(ir) · \(producer) \(version)\nOpsets: \(opsets.joined(separator: ", "))\n\(nodes) nodes · \(weights) initializers · \(w.total) file bytes\n" + ops.keys.sorted().map { "\($0): \(ops[$0]!)" }.joined(separator: " · ") + "\nMetadata only. Weights, attributes, nested graphs and external files are not loaded; no inference."
        return .init(title: "ONNX", summary: summary, columns: ["Kind", "Name", "Type / operator", "Shape / inputs", "Outputs / storage"], rows: rows)
    }
    private static func dtype(_ value: UInt64) -> String {
        [1:"float32",2:"uint8",3:"int8",4:"uint16",5:"int16",6:"int32",7:"int64",8:"string",9:"bool",10:"float16",11:"float64",12:"uint32",13:"uint64",14:"complex64",15:"complex128",16:"bfloat16"][value] ?? "dtype \(value)"
    }
    private struct Field { let number: Int; let integer: UInt64?; let range: Range<Int>? }
    private final class Wire {
        let token: Cancellation, total: Int
        let url: URL?, root: URL?, revision: String?
        var cache: Data, cacheStart = 0, accessed = 0, fieldCount = 0
        init(data: Data, token: Cancellation) { self.token = token; total = data.count; cache = data; url = nil; root = nil; revision = nil }
        init(url: URL, root: URL?, token: Cancellation) throws {
            self.url = url; self.root = root; self.token = token
            var limits = PreviewLimits(); limits.fileBytes = 65536
            let initial = try AccessBroker.readBytes(url, root: root, limits: limits, cancellation: token, allowPartial: true)
            total = initial.totalBytes; revision = initial.revision; cache = initial.data
        }
        func verify() throws {
            guard let url else { return }; var limits = PreviewLimits(); limits.fileBytes = 1
            guard try AccessBroker.readBytes(url, root: root, limits: limits, cancellation: token, allowPartial: true).revision == revision else { throw PreviewError.changed }
        }
        func byte(_ offset: Int) throws -> UInt8 {
            try token.check()
            guard offset >= 0, offset < total else { throw PreviewError.malformed("ONNX truncated wire") }
            if offset < cacheStart || offset >= cacheStart + cache.count {
                guard let url else { throw PreviewError.malformed("ONNX range") }
                accessed += 65536; guard accessed <= 16 * 1024 * 1024 else { throw PreviewError.limit("ONNX metadata read 16 MiB") }
                var limits = PreviewLimits(); limits.fileBytes = 65536
                let value = try AccessBroker.readBytes(url, root: root, limits: limits, cancellation: token, byteOffset: offset, allowPartial: true)
                guard value.revision == revision else { throw PreviewError.changed }; cache = value.data; cacheStart = offset
            }
            return cache[offset - cacheStart]
        }
        func varint(_ offset: inout Int, end: Int) throws -> UInt64 {
            var value: UInt64 = 0
            for shift in stride(from: 0, through: 63, by: 7) {
                guard offset < end else { throw PreviewError.malformed("ONNX varint") }
                let b = try byte(offset); offset += 1
                guard shift != 63 || b <= 1 else { throw PreviewError.malformed("ONNX integer overflow") }
                value |= UInt64(b & 127) << shift
                if b < 128 { return value }
            }
            throw PreviewError.malformed("ONNX varint")
        }
        func fields(_ range: Range<Int>) throws -> [Field] {
            var offset = range.lowerBound, result: [Field] = []
            while offset < range.upperBound {
                fieldCount += 1; guard fieldCount <= 200000 else { throw PreviewError.limit("ONNX fields") }
                let tag = try varint(&offset, end: range.upperBound), number = tag >> 3
                guard number > 0, number <= 536870911 else { throw PreviewError.malformed("ONNX field number") }
                var length = 0, payload: Range<Int>?, integer: UInt64?
                switch tag & 7 {
                case 0: integer = try varint(&offset, end: range.upperBound)
                case 1: length = 8
                case 2:
                    let size = try varint(&offset, end: range.upperBound)
                    guard size <= UInt64(range.upperBound - offset) else { throw PreviewError.malformed("ONNX payload length") }; length = Int(size); payload = offset..<(offset + length)
                case 5: length = 4
                default: throw PreviewError.malformed("ONNX unsupported wire type")
                }
                guard length <= range.upperBound - offset else { throw PreviewError.malformed("ONNX truncated field") }
                offset += length
                result.append(.init(number: Int(number), integer: integer, range: payload))
            }
            return result
        }
        func string(_ fields: [Field], _ number: Int) throws -> String { try strings(fields, number).first ?? "" }
        func strings(_ fields: [Field], _ number: Int) throws -> [String] {
            try fields.filter { $0.number == number && $0.range != nil }.map { field in
                let range = field.range!; guard range.count <= 65536 else { throw PreviewError.limit("ONNX string") }
                let data = Data(try range.map { try byte($0) })
                guard let value = String(data: data, encoding: .utf8) else { throw PreviewError.encoding }; return value
            }
        }
    }
}
