import Foundation

/// Decodes content, never loads a JVM class or evaluates a property list.
public enum BinarySourcePreview {
    public static func text(_ data: Data, extension ext: String, cancellation: Cancellation = .init()) throws -> (text: String, label: String)? {
        try cancellation.check()
        guard data.count <= PreviewLimits().fileBytes else { throw PreviewError.limit("Source input 5 MiB") }
        if ext == "class" { return (try JavaClassPreview.parse(data, cancellation: cancellation), "Java class · declarations and bytecode") }
        if SourceCodeFormats.propertyListExtensions.contains(ext), data.starts(with: Data("bplist00".utf8)) {
            var format = PropertyListSerialization.PropertyListFormat.binary
            let value = try PropertyListSerialization.propertyList(from: data, options: [], format: &format)
            guard format == .binary else { throw PreviewError.malformed("Binary property list") }
            var nodes = 0
            func validate(_ value: Any, depth: Int) throws {
                try cancellation.check(); nodes += 1
                guard depth <= 64, nodes <= 20_000 else { throw PreviewError.limit("Property list structure") }
                if let list = value as? [Any] { for child in list { try validate(child, depth: depth + 1) } }
                if let dictionary = value as? [String: Any] { for child in dictionary.values { try validate(child, depth: depth + 1) } }
            }
            try validate(value, depth: 0)
            let xml = try PropertyListSerialization.data(fromPropertyList: value, format: .xml, options: 0)
            guard xml.count <= PreviewLimits().fileBytes else { throw PreviewError.limit("Property list XML 5 MiB") }
            try cancellation.check()
            return (try AccessBroker.decode(xml).0, "Binary plist → XML")
        }
        if ext == "a3x", (try? AccessBroker.decode(data)) == nil {
            // AutoIt compiled scripts have no source text to color. Show an
            // explicit bounded byte view rather than claiming decompilation.
            let bytes = [UInt8](data.prefix(4096))
            let lines = stride(from: 0, to: bytes.count, by: 16).map { offset in
                String(format: "%08x  ", offset) + bytes[offset..<min(offset + 16, bytes.count)].map { String(format: "%02x", $0) }.joined(separator: " ")
            }
            return ((["AutoIt compiled script (.a3x)", "Binary bytes only; source decompilation is unavailable.", "First \(bytes.count) of \(data.count) bytes", ""] + lines).joined(separator: "\n"), "AutoIt · binary bytes")
        }
        return nil
    }
}

public enum JavaClassPreview {
    /// A bounded JVM class-file reader. Bytecode remains bytes; this is not a
    /// reconstruction of the original Java source. No external JDK is required.
    public static func parse(_ data: Data, cancellation: Cancellation = .init()) throws -> String {
        guard data.count <= PreviewLimits().fileBytes else { throw PreviewError.limit("Java class 5 MiB") }
        var reader = ClassBytes(bytes: [UInt8](data))
        guard try reader.u4() == 0xCAFEBABE else { throw PreviewError.malformed("Java class magic") }
        let minor = try reader.u2(), major = try reader.u2(), count = try reader.u2()
        guard count > 0 else { throw PreviewError.malformed("Java constant pool") }
        var strings: [Int: String] = [:], classes: [Int: Int] = [:]
        var index = 1
        while index < count {
            try cancellation.check()
            switch try reader.u1() {
            case 1:
                let bytes = try reader.take(reader.u2())
                // JVM uses modified UTF-8. Decode through UTF-16 to preserve
                // supplementary characters and the special encoded NUL.
                strings[index] = try modifiedUTF8(bytes)
            case 7: classes[index] = try reader.u2()
            case 3, 4, 9, 10, 11, 12, 17, 18: try reader.skip(4)
            case 5, 6:
                guard index + 1 < count else { throw PreviewError.malformed("Java wide constant") }
                try reader.skip(8); index += 1
            case 8, 16, 19, 20: try reader.skip(2)
            case 15: try reader.skip(3)
            default: throw PreviewError.malformed("Java constant tag")
            }
            index += 1
        }
        func utf(_ index: Int) throws -> String {
            guard let value = strings[index] else { throw PreviewError.malformed("Java UTF-8 reference") }; return value
        }
        func className(_ index: Int) throws -> String {
            guard let name = classes[index] else { throw PreviewError.malformed("Java class reference") }
            return try utf(name).replacingOccurrences(of: "/", with: ".")
        }
        let flags = try reader.u2(), this = try reader.u2(), parent = try reader.u2()
        var lines = ["// JVM class file \(major).\(minor)", "// Declarations and raw method bytecode; original source is unavailable.",
                     "class \(try className(this))" + (parent == 0 ? "" : " extends \(try className(parent))") + " {", String(format: "  // access flags: 0x%04x", flags)]
        var outputBytes = lines.joined().utf8.count
        func append(_ line: String) throws {
            outputBytes += line.utf8.count
            guard outputBytes <= 1024 * 1024 else { throw PreviewError.limit("Java output 1 MiB") }
            lines.append(line)
        }
        for _ in 0..<(try reader.u2()) {
            try cancellation.check()
            try append("  // implements \(try className(reader.u2()))")
        }
        for kind in ["field", "method"] {
            let members = try reader.u2()
            guard members <= 10_000 else { throw PreviewError.limit("Java member count") }
            for _ in 0..<members {
                try cancellation.check()
                let access = try reader.u2(), name = try utf(reader.u2()), descriptor = try utf(reader.u2())
                try append(String(format: "  // %@ flags: 0x%04x", kind, access))
                try append("  \(kind) \(name) : \(descriptor)")
                let attributes = try reader.u2()
                for _ in 0..<attributes {
                    try cancellation.check()
                    let attribute = try utf(reader.u2()), size = try reader.u4()
                    let payload = try reader.take(size)
                    if kind == "method", attribute == "Code" {
                        var code = ClassBytes(bytes: payload)
                        let stack = try code.u2(), locals = try code.u2(), length = try code.u4()
                        guard length <= 65535 else { throw PreviewError.malformed("Java bytecode size") }
                        let bytes = try code.take(length)
                        try append("    // stack=\(stack), locals=\(locals), code=\(length) bytes")
                        for offset in stride(from: 0, to: min(bytes.count, 4096), by: 16) {
                            try append(String(format: "    %04x: ", offset) + bytes[offset..<min(offset + 16, bytes.count)].map { String(format: "%02x", $0) }.joined(separator: " "))
                        }
                        if bytes.count > 4096 { try append("    // Remaining bytecode omitted after 4096 bytes.") }
                        try code.skip((try code.u2()) * 8)
                        for _ in 0..<(try code.u2()) { _ = try utf(code.u2()); try code.skip(code.u4()) }
                        guard code.atEnd else { throw PreviewError.malformed("Java Code attribute size") }
                    }
                }
            }
        }
        for _ in 0..<(try reader.u2()) { _ = try utf(reader.u2()); try reader.skip(reader.u4()) }
        guard reader.atEnd else { throw PreviewError.malformed("Java trailing data") }
        try append("}"); try cancellation.check()
        return lines.joined(separator: "\n")
    }
    private static func modifiedUTF8(_ bytes: [UInt8]) throws -> String {
        var units: [UInt16] = [], i = 0
        while i < bytes.count {
            let a = bytes[i]; i += 1
            if a > 0, a < 0x80 { units.append(UInt16(a)); continue }
            if a & 0xE0 == 0xC0, i < bytes.count {
                let b = bytes[i]; i += 1
                guard b & 0xC0 == 0x80 else { throw PreviewError.malformed("Java modified UTF-8") }
                let unit = UInt16(a & 31) << 6 | UInt16(b & 63)
                guard unit >= 0x80 || (a == 0xC0 && b == 0x80) else { throw PreviewError.malformed("Java modified UTF-8") }
                units.append(unit)
            } else if a & 0xF0 == 0xE0, i + 1 < bytes.count {
                let b = bytes[i], c = bytes[i + 1]; i += 2
                guard b & 0xC0 == 0x80, c & 0xC0 == 0x80 else { throw PreviewError.malformed("Java modified UTF-8") }
                let unit = UInt16(a & 15) << 12 | UInt16(b & 63) << 6 | UInt16(c & 63)
                guard unit >= 0x800 else { throw PreviewError.malformed("Java modified UTF-8") }; units.append(unit)
            } else { throw PreviewError.malformed("Java modified UTF-8") }
        }
        return String(decoding: units, as: UTF16.self)
    }
}
private struct ClassBytes {
    let bytes: [UInt8]
    var offset = 0
    var atEnd: Bool { offset == bytes.count }
    mutating func take(_ count: Int) throws -> [UInt8] {
        guard count >= 0, count <= bytes.count - offset else { throw PreviewError.malformed("Java class truncated") }
        defer { offset += count }; return Array(bytes[offset..<offset + count])
    }
    mutating func skip(_ count: Int) throws {
        guard count >= 0, count <= bytes.count - offset else { throw PreviewError.malformed("Java class truncated") }; offset += count
    }
    mutating func u1() throws -> Int { Int(try take(1)[0]) }
    mutating func u2() throws -> Int { try take(2).reduce(0) { ($0 << 8) | Int($1) } }
    mutating func u4() throws -> Int { try take(4).reduce(0) { ($0 << 8) | Int($1) } }
}
