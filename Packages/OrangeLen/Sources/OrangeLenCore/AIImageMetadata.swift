import Foundation
import CZlib

/// Optional, untrusted generation recipes. A bad recipe must never prevent image decoding.
public struct AIImageMetadata: Sendable {
    public struct Field: Sendable { public let name: String, value: String }
    public let fields: [Field]
    public let warnings: [String]
    public var text: String {
        fields.map { $0.name + "\n" + $0.value }.joined(separator: "\n\n")
    }
    public static func parse(_ data: Data, cancellation: Cancellation = .init()) throws -> Self {
        guard data.count <= 25 * 1024 * 1024 else { throw PreviewError.limit(L10n.text("图片字节预算")) }
        let b = [UInt8](data)
        var fields: [Field] = [], warnings: [String] = [], total = 0
        let maximum = 1024 * 1024
        func warn() { if warnings.isEmpty { warnings.append(L10n.text("部分生成参数损坏或超过预算，图片仍可预览")) } }
        func add(_ key: String, _ value: String) {
            guard !value.isEmpty else { return }
            guard fields.count < 32, value.utf8.count <= maximum - total else { warn(); return }
            total += value.utf8.count; fields.append(.init(name: key, value: value))
        }
        func accept(_ key: String, _ payload: Data) throws {
            try cancellation.check()
            guard ["parameters", "prompt", "workflow", "Description", "Comment", "UserComment"].contains(key) else { return }
            guard payload.count <= maximum, let text = String(data: payload, encoding: .utf8) else { warn(); return }
            if key == "parameters" { add(L10n.text("生成参数"), text); return }
            if key == "prompt" || key == "workflow" {
                do {
                    _ = try JSONParser.parse(text, cancellation: cancellation)
                    if key == "prompt", let nodes = try JSONSerialization.jsonObject(with: payload) as? [String: Any] {
                        var summary: [String] = []
                        for id in nodes.keys.sorted().prefix(5000) {
                            try cancellation.check()
                            guard let node = nodes[id] as? [String: Any], let inputs = node["inputs"] as? [String: Any] else { continue }
                            for name in ["text", "ckpt_name", "unet_name", "lora_name", "seed", "noise_seed", "steps", "cfg", "sampler_name", "scheduler", "denoise"] {
                                guard let value = inputs[name], !(value is [Any]), !(value is [String: Any]), summary.count < 64 else { continue }
                                let line = id + "." + name + ": " + String(describing: value)
                                if line.utf8.count < 8192 { summary.append(line) }
                            }
                        }
                        if !summary.isEmpty { add(L10n.text("参数概览"), summary.joined(separator: "\n")) }
                    }
                }
                catch is CancellationError { throw CancellationError() }
                catch { warn() } // Keep the literal field for inspection, even when malformed.
                add(key, text); return
            }
            // ComfyUI WebP stores workflow:{JSON} and prompt:{JSON} as EXIF strings.
            if let prefix = ["workflow:", "prompt:"].first(where: { text.hasPrefix($0) }) {
                try accept(String(prefix.dropLast()), Data(text.dropFirst(prefix.count).utf8))
            } else if (try? JSONParser.parse(text, cancellation: cancellation)) != nil,
                      let object = try? JSONSerialization.jsonObject(with: payload) as? [String: Any] {
                for name in ["prompt", "workflow", "parameters"] {
                    guard let value = object[name] else { continue }
                    if let string = value as? String { try accept(name, Data(string.utf8)) }
                    else if JSONSerialization.isValidJSONObject(value) {
                        try accept(name, JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]))
                    }
                }
            } else if text.contains("Steps:") && text.contains("Seed:") { add(L10n.text("生成参数"), text) }
        }
        func acceptXMP(_ payload: Data) throws {
            guard payload.count <= maximum else { warn(); return }
            guard let xml = String(data:payload,encoding:.utf8) else { return }
            let root = try BoundedXML.parse(xml,token:cancellation)
            func visit(_ node: BoundedXML.Node) throws {
                try cancellation.check()
                let name = node.name.components(separatedBy:":").last ?? node.name
                let text = node.text + node.descendants("rdf:li").map(\.text).joined(separator:"\n")
                if ["parameters","prompt","workflow"].contains(name) { try accept(name,Data(text.utf8)) }
                else if ["description","Description","UserComment","Comment"].contains(name) { try accept("Description",Data(text.utf8)) }
                for (key,value) in node.attributes {
                    let name = key.components(separatedBy:":").last ?? key
                    if ["parameters","prompt","workflow"].contains(name) { try accept(name,Data(value.utf8)) }
                }
                for child in node.children { try visit(child) }
            }
            try visit(root)
        }
        func big(_ offset: Int) -> Int { (0..<4).reduce(0) { ($0 << 8) | Int(b[offset + $1]) } }
        func little(_ offset: Int) -> Int { (0..<4).reduce(0) { $0 | Int(b[offset + $1]) << (8 * $1) } }
        if b.starts(with: [137,80,78,71,13,10,26,10]) {
            var cursor = 8, count = 0
            while cursor + 12 <= b.count {
                try cancellation.check(); count += 1
                guard count <= 100_000 else { warn(); break }
                let length = big(cursor)
                guard length <= b.count - cursor - 12 else { warn(); break }
                let kind = String(bytes: b[(cursor + 4)..<(cursor + 8)], encoding: .ascii) ?? ""
                let start = cursor + 8, end = start + length
                if ["tEXt", "zTXt", "iTXt"].contains(kind) {
                    if length > maximum { warn() }
                    else {
                        do {
                            let chunk = Data(b[(cursor + 4)..<end])
                            let crc = chunk.withUnsafeBytes { crc32(0, $0.bindMemory(to: Bytef.self).baseAddress, uInt(chunk.count)) }
                            guard UInt32(truncatingIfNeeded: crc) == UInt32(big(end)) else { throw PreviewError.malformed("CRC") }
                            guard let zero = b[start..<end].firstIndex(of: 0), zero - start <= 79,
                                  let key = String(bytes: b[start..<zero], encoding: .isoLatin1) else { throw PreviewError.malformed("PNG text") }
                            if ["parameters", "prompt", "workflow", "Description", "Comment"].contains(key) {
                                var payload: Data
                                if kind == "tEXt" { payload = Data(b[(zero + 1)..<end]) }
                                else if kind == "zTXt" {
                                    guard zero + 2 <= end, b[zero + 1] == 0 else { throw PreviewError.malformed("zTXt") }
                                    payload = try ArchiveDocument.inflate(Data(b[(zero + 2)..<end]), window: 15, maximum: maximum - total, token: cancellation)
                                } else {
                                    guard zero + 3 <= end, b[zero + 1] <= 1, b[zero + 2] == 0,
                                          let languageEnd = b[(zero + 3)..<end].firstIndex(of: 0),
                                          let translatedEnd = b[(languageEnd + 1)..<end].firstIndex(of: 0) else { throw PreviewError.malformed("iTXt") }
                                    payload = Data(b[(translatedEnd + 1)..<end])
                                    if b[zero + 1] == 1 { payload = try ArchiveDocument.inflate(payload, window: 15, maximum: maximum - total, token: cancellation) }
                                }
                                // PNG tEXt/zTXt is Latin-1 by spec; many AI tools write UTF-8.
                                if kind != "iTXt", String(data: payload, encoding: .utf8) == nil,
                                   let latin = String(data: payload, encoding: .isoLatin1) { payload = Data(latin.utf8) }
                                try accept(key, payload)
                            }
                        } catch is CancellationError { throw CancellationError() }
                        catch { warn() }
                    }
                }
                cursor = end + 4
                if kind == "IEND" { break }
            }
        } else if b.count >= 12, String(bytes: b[0..<4], encoding: .ascii) == "RIFF", String(bytes: b[8..<12], encoding: .ascii) == "WEBP" {
            let declared = little(4)
            guard declared <= b.count - 8 else { return .init(fields: [], warnings: [L10n.text("部分生成参数损坏或超过预算，图片仍可预览")]) }
            var cursor = 12, count = 0
            while cursor + 8 <= declared + 8 {
                try cancellation.check()
                count += 1; guard count <= 100_000 else { warn(); break }
                let length = little(cursor + 4), start = cursor + 8
                guard length <= declared + 8 - start else { warn(); break }
                if String(bytes: b[cursor..<(cursor + 4)], encoding: .ascii) == "EXIF" {
                    if length > maximum { warn() }
                    else {
                        for value in exifComments(Data(b[start..<(start + length)])) {
                            try accept("UserComment", Data(value.utf8))
                        }
                    }
                }
                if String(bytes:b[cursor..<(cursor + 4)],encoding:.ascii) == "XMP " {
                    do { try acceptXMP(Data(b[start..<(start + length)])) } catch is CancellationError { throw CancellationError() } catch { warn() }
                }
                cursor = start + length + length % 2
            }
        }
        if b.count >= 4, b[0] == 255, b[1] == 216 {
            var cursor = 2, segments = 0
            while cursor + 4 <= b.count {
                try cancellation.check(); segments += 1; guard segments <= 10000 else { warn(); break }
                guard b[cursor] == 255 else { break }; let marker = b[cursor + 1]
                if marker == 218 || marker == 217 { break }
                if marker == 255 { cursor += 1; continue }
                if marker == 1 || (208...215).contains(marker) { cursor += 2; continue }
                let length = Int(b[cursor + 2]) * 256 + Int(b[cursor + 3])
                guard length >= 2, length <= b.count - cursor - 2 else { warn(); break }
                let payload = Data(b[(cursor + 4)..<(cursor + 2 + length)])
                if marker == 225 {
                    do {
                        if payload.starts(with:[69,120,105,102,0,0]) { for value in exifComments(payload) { try accept("UserComment",Data(value.utf8)) } }
                        else if payload.starts(with:Data("http://ns.adobe.com/xap/1.0/\0".utf8)) { try acceptXMP(Data(payload.dropFirst(29))) }
                    } catch is CancellationError { throw CancellationError() } catch { warn() }
                }
                if marker == 235, String(decoding:payload,as:UTF8.self).contains("c2pa") { add("C2PA", "Embedded provenance container present; cryptographic authenticity is not verified.") }
                cursor += 2 + length
            }
        }
        if data.first == 123 { try accept("Description",data) }
        else if data.first != 60, let text = String(data:data,encoding:.utf8), text.contains("Steps:"), text.contains("Seed:") { try accept("parameters",data) }
        if data.first == 60 { do { try acceptXMP(data) } catch is CancellationError { throw CancellationError() } catch { warn() } }
        return .init(fields: fields, warnings: warnings)
    }
    public func addingProvenance(_ data: Data, cancellation: Cancellation) throws -> Self {
        let document = try ProvenanceDocument.parse(data,cancellation:cancellation)
        return merging(.init(fields:[.init(name:"C2PA · unverified",value:document.text)],warnings:[]))
    }
    public func merging(_ other: Self) -> Self {
        var result = fields, bytes = fields.reduce(0,{$0 + $1.value.utf8.count})
        for field in other.fields where result.count < 32 { guard field.value.utf8.count <= 1024 * 1024 - bytes else { break }; bytes += field.value.utf8.count; result.append(field) }
        return .init(fields:result,warnings:Array(Set(warnings + other.warnings)).sorted())
    }
    /// Bounded TIFF reader for EXIF ImageDescription and ExifIFD.UserComment only.
    static func exifComments(_ raw: Data) -> [String] {
        var bytes = [UInt8](raw)
        if bytes.starts(with: [69,120,105,102,0,0]) { bytes.removeFirst(6) }
        guard bytes.count >= 8 else { return [] }
        let le = bytes[0] == 73 && bytes[1] == 73
        guard le || (bytes[0] == 77 && bytes[1] == 77) else { return [] }
        func number(_ at: Int, _ size: Int) -> Int? {
            guard at >= 0, at <= bytes.count - size else { return nil }
            return (0..<size).reduce(0) { $0 | Int(bytes[at + $1]) << (8 * (le ? $1 : size - 1 - $1)) }
        }
        guard number(2, 2) == 42, let first = number(4, 4) else { return [] }
        var visited = Set<Int>(), values: [String] = []
        func scan(_ offset: Int) {
            guard visited.count < 2, visited.insert(offset).inserted, let count = number(offset, 2), count <= 512 else { return }
            for index in 0..<count {
                let at = offset + 2 + index * 12
                guard let tag = number(at, 2), let type = number(at + 2, 2), let size = number(at + 4, 4), let value = number(at + 8, 4) else { return }
                if tag == 0x8769, type == 4, size == 1 { scan(value); continue }
                guard tag == 0x9286 || tag == 0x010e, [1,2,7].contains(type), size <= 1024 * 1024 else { continue }
                let begin = size <= 4 ? at + 8 : value
                guard begin >= 0, begin <= bytes.count, size <= bytes.count - begin else { continue }
                var payload = Data(bytes[begin..<(begin + size)])
                var encoding = String.Encoding.utf8
                if payload.count >= 8 {
                    let prefix = String(data: payload.prefix(8), encoding: .ascii) ?? ""
                    if prefix.hasPrefix("ASCII") { payload.removeFirst(8) }
                    else if prefix.hasPrefix("UNICODE") { payload.removeFirst(8); encoding = le ? .utf16LittleEndian : .utf16BigEndian }
                }
                if let text = String(data: payload, encoding: encoding) ?? String(data: payload, encoding: .isoLatin1) {
                    values.append(text.trimmingCharacters(in: CharacterSet(charactersIn: "\0")))
                }
            }
        }
        scan(first); return values
    }
}
