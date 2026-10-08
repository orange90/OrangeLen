import Foundation
/// Immutable parent-linked path; ancestors are shared, never copied per descendant.
private final class JSONPath: @unchecked Sendable {
    let parent: JSONPath?
    let segment: String
    let byteCount: Int
    init(_ segment: String, parent: JSONPath? = nil) {
        self.segment = segment; self.parent = parent
        byteCount = (parent?.byteCount ?? 0) + segment.utf8.count
    }
    var string: String {
        var segments: [String] = [], current: JSONPath? = self
        while let value = current { segments.append(value.segment); current = value.parent }
        return segments.reversed().joined()
    }
}
public final class JSONNode: @unchecked Sendable {
    public let name: String
    private let location: JSONPath
    public var path: String { location.string }
    /// Only this node’s segment is stored; useful for model budget accounting.
    public var storedPathBytes: Int { location.segment.utf8.count }
    public let range: NSRange
    public let children: [JSONNode]
    public let kind: String
    fileprivate init(name: String, path: JSONPath, range: NSRange, children: [JSONNode], kind: String) {
        self.name = name; self.location = path; self.range = range; self.children = children; self.kind = kind
    }
}
public struct JSONTree: Sendable {
    public let root: JSONNode
    public let duplicateKeys: Bool
}
public enum JSONDialect: Sendable {
    case strict, jsonc, json5
    public static func detect(_ url: URL) -> Self {
        let name = url.lastPathComponent.lowercased()
        if url.pathExtension.lowercased() == "json5" { return .json5 }
        if url.pathExtension.lowercased() == "jsonc" { return .jsonc }
        if name.hasSuffix(".json") && (name == "tsconfig.json" || name.hasPrefix("tsconfig.") || name == "jsconfig.json" || name.hasPrefix("jsconfig.")) { return .jsonc }
        if url.deletingLastPathComponent().lastPathComponent == ".vscode" && ["settings.json","tasks.json","launch.json","extensions.json"].contains(name) { return .jsonc }
        return .strict
    }
}
public enum JSONParser {
    /// Node ranges always refer to the untouched source, including nondecimal numbers and duplicate keys.
    public static func parse(_ source: String, dialect: JSONDialect = .strict, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> JSONTree {
        guard source.utf8.count <= limits.fileBytes else { throw PreviewError.limit(L10n.text("JSON 输入字节预算")) }
        let parser = Parser(source, dialect, limits, cancellation)
        let node = try parser.value(name: "$", path: JSONPath("$"), depth: 0)
        try parser.whitespace()
        guard parser.i == parser.chars.count else { throw PreviewError.malformed(L10n.text("JSON 尾部存在多余内容")) }
        return JSONTree(root: node, duplicateKeys: parser.duplicates)
    }
    private final class Parser {
        let source: NSString; let chars: [UInt16]; let limits: PreviewLimits; let cancellation: Cancellation; let dialect: JSONDialect
        var i = 0; var nodes = 0; var duplicates = false; var modelBytes = 0
        init(_ source: String, _ dialect: JSONDialect, _ limits: PreviewLimits, _ cancellation: Cancellation) { self.source = source as NSString; chars = Array(source.utf16); self.dialect = dialect; self.limits = limits; self.cancellation = cancellation }
        func check() throws { if i % 4096 == 0 { try cancellation.check() } }
        func isSpace(_ c: UInt16) -> Bool {
            [9,10,13,32].contains(c) || (dialect == .json5 && (c == 11 || c == 12 || c == 0xFEFF || c == 0x2028 || c == 0x2029 || UnicodeScalar(c).map { CharacterSet(charactersIn:"\u{00A0}\u{1680}\u{2000}\u{2001}\u{2002}\u{2003}\u{2004}\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{200A}\u{202F}\u{205F}\u{3000}").contains($0) } == true))
        }
        func whitespace() throws {
            while i < chars.count {
                try check()
                if isSpace(chars[i]) { i += 1; continue }
                guard dialect != .strict, i + 1 < chars.count, chars[i] == 47 else { return }
                if chars[i + 1] == 47 {
                    i += 2
                    while i < chars.count && ![10,13,0x2028,0x2029].contains(chars[i]) { try check(); i += 1 }
                } else if chars[i + 1] == 42 {
                    i += 2
                    while i + 1 < chars.count && !(chars[i] == 42 && chars[i+1] == 47) { try check(); i += 1 }
                    guard i + 1 < chars.count else { throw PreviewError.malformed(L10n.text("JSON 注释未闭合")) }
                    i += 2
                } else { return }
            }
        }
        func consume(_ c: UInt16) throws -> Bool { try whitespace(); if i < chars.count && chars[i] == c { i += 1; return true }; return false }
        func hex(_ count: Int) throws -> UInt16 {
            guard i + count <= chars.count else { throw PreviewError.malformed(L10n.text("JSON 转义字符不完整")) }
            var result: UInt16 = 0
            for _ in 0..<count {
                let c = chars[i]; i += 1; let digit: UInt16
                switch c { case 48...57: digit = c - 48; case 65...70: digit = c - 55; case 97...102: digit = c - 87; default: throw PreviewError.malformed(L10n.text("JSON 十六进制转义无效")) }
                result = result * 16 + digit
            }
            return result
        }
        func string() throws -> String {
            try whitespace(); let start = i
            guard i < chars.count, chars[i] == 34 || (dialect == .json5 && chars[i] == 39) else { throw PreviewError.malformed(L10n.text("JSON 字符串缺少引号")) }
            let quote = chars[i]; i += 1; var decoded: [UInt16] = []
            while i < chars.count {
                try check(); let c = chars[i]; i += 1
                if c == quote {
                    if dialect == .json5 { return String(decoding: decoded, as: UTF16.self) }
                    let literal = source.substring(with: NSRange(location: start, length: i - start))
                    guard let value = try? JSONDecoder().decode(String.self, from: Data(literal.utf8)) else { throw PreviewError.malformed(L10n.text("JSON 转义字符")) }
                    return value
                }
                if dialect != .json5 {
                    guard c >= 32 else { throw PreviewError.malformed(L10n.text("JSON 字符串含控制字符")) }
                    if c == 92 {
                        guard i < chars.count, chars[i] >= 32 else { throw PreviewError.malformed(L10n.text("JSON 转义字符不完整")) }; i += 1
                    }
                    continue
                }
                guard c != 10 && c != 13 else { throw PreviewError.malformed(L10n.text("JSON5 字符串含未转义换行")) }
                if c != 92 { decoded.append(c); continue }
                guard i < chars.count else { throw PreviewError.malformed(L10n.text("JSON5 转义字符不完整")) }
                let e = chars[i]; i += 1
                switch e {
                case 10,0x2028,0x2029: break
                case 13: if i < chars.count && chars[i] == 10 { i += 1 }
                case 98: decoded.append(8)
                case 102: decoded.append(12)
                case 110: decoded.append(10)
                case 114: decoded.append(13)
                case 116: decoded.append(9)
                case 118: decoded.append(11)
                case 48:
                    guard i == chars.count || !(48...57).contains(chars[i]) else { throw PreviewError.malformed(L10n.text("JSON5 不支持八进制转义")) }; decoded.append(0)
                case 49...57: throw PreviewError.malformed(L10n.text("JSON5 不支持数字转义"))
                case 120: decoded.append(try hex(2))
                case 117: decoded.append(try hex(4))
                default: decoded.append(e)
                }
            }
            throw PreviewError.malformed(L10n.text("JSON 字符串未闭合"))
        }
        func key() throws -> String {
            try whitespace()
            if i < chars.count && (chars[i] == 34 || chars[i] == 39) { return try string() }
            guard dialect == .json5 else { throw PreviewError.malformed(L10n.text("JSON 键必须使用双引号")) }
            var units: [UInt16] = []
            while i < chars.count {
                try check(); let c = chars[i]
                if c == 92 {
                    i += 1; guard i < chars.count && chars[i] == 117 else { throw PreviewError.malformed(L10n.text("JSON5 标识符转义无效")) }; i += 1; units.append(try hex(4))
                } else if isSpace(c) || [58,44,123,125,91,93,47].contains(c) { break }
                else { units.append(c); i += 1 }
            }
            let name = String(decoding: units, as: UTF16.self)
            guard name.range(of:#"\A[\p{L}\p{Nl}$_][\p{L}\p{Nl}\p{Mn}\p{Mc}\p{Nd}\p{Pc}$\u200C\u200D]*\z"#,options:.regularExpression) != nil else { throw PreviewError.malformed(L10n.text("JSON5 标识符无效")) }
            return name
        }
        func value(name: String, path: JSONPath, depth: Int) throws -> JSONNode {
            try cancellation.check(); nodes += 1
            let storage = name.utf8.count + path.segment.utf8.count + 256
            guard path.byteCount <= limits.jsonPathBytes, storage <= limits.modelBytes - modelBytes else { throw PreviewError.limit(L10n.text("JSON 路径或模型字节预算")) }
            modelBytes += storage
            guard depth <= limits.structureDepth, nodes <= limits.structureNodes else { throw PreviewError.limit(L10n.text("JSON 最大深度 \(limits.structureDepth)、节点 \(limits.structureNodes)")) }
            try whitespace(); let start = i; var children: [JSONNode] = []; var kind = "value"
            if try consume(123) {
                kind = "object"; var keys: Set<String> = []
                if try !consume(125) {
                    while true {
                        let key = try key(); if !keys.insert(key).inserted { duplicates = true }
                        guard try consume(58) else { throw PreviewError.malformed(L10n.text("JSON 缺少冒号")) }
                        let keyJSON = String(data: try JSONEncoder().encode(key), encoding: .utf8)!
                        children.append(try value(name: key, path: JSONPath("[" + keyJSON + "]", parent: path), depth: depth + 1))
                        if try consume(125) { break }
                        guard try consume(44) else { throw PreviewError.malformed(L10n.text("JSON 对象缺少逗号或未闭合")) }
                        if dialect != .strict, try consume(125) { break }
                    }
                }
            } else if try consume(91) {
                kind = "array"
                if try !consume(93) {
                    while true {
                        children.append(try value(name: "[\(children.count)]", path: JSONPath("[\(children.count)]", parent: path), depth: depth + 1))
                        if try consume(93) { break }
                        guard try consume(44) else { throw PreviewError.malformed(L10n.text("JSON 数组缺少逗号或未闭合")) }
                        if dialect != .strict, try consume(93) { break }
                    }
                }
            } else if i < chars.count && (chars[i] == 34 || (dialect == .json5 && chars[i] == 39)) { _ = try string(); kind = "string" }
            else {
                while i < chars.count && !isSpace(chars[i]) && ![44,93,125].contains(chars[i]) {
                    if dialect != .strict && chars[i] == 47 { break }
                    try check(); i += 1
                }
                let token = source.substring(with: NSRange(location: start, length: i - start))
                let pattern = dialect == .json5 ? #"^[+-]?(?:Infinity|NaN|0[xX][0-9a-fA-F]+|(?:(?:0|[1-9][0-9]*)(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?)$"# : #"^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$"#
                guard ["true", "false", "null"].contains(token) || token.range(of: pattern, options: .regularExpression) != nil else { throw PreviewError.malformed(L10n.text("JSON 值非法（UTF-16 偏移 \(start)）")) }
            }
            return JSONNode(name: name, path: path, range: NSRange(location: start, length: i - start), children: children, kind: kind)
        }
    }
}
