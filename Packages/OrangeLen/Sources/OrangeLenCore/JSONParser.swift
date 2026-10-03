import Foundation
public final class JSONNode: @unchecked Sendable {
    public let name: String
    public let path: String
    public let range: NSRange
    public let children: [JSONNode]
    public let kind: String
    init(name: String, path: String, range: NSRange, children: [JSONNode], kind: String) {
        self.name = name; self.path = path; self.range = range; self.children = children; self.kind = kind
    }
}
public struct JSONTree: Sendable {
    public let root: JSONNode
    public let duplicateKeys: Bool
}
public enum JSONParser {
    public static func parse(_ source: String, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> JSONTree {
        let parser = Parser(source, limits, cancellation)
        let node = try parser.value(name: "$", path: "$", depth: 0)
        parser.whitespace()
        guard parser.i == parser.chars.count else { throw PreviewError.malformed("JSON 尾部存在多余内容") }
        return JSONTree(root: node, duplicateKeys: parser.duplicates)
    }
    private final class Parser {
        let source: NSString; let chars: [UInt16]; let limits: PreviewLimits; let cancellation: Cancellation
        var i = 0; var nodes = 0; var duplicates = false
        init(_ source: String, _ limits: PreviewLimits, _ cancellation: Cancellation) { self.source = source as NSString; chars = Array(source.utf16); self.limits = limits; self.cancellation = cancellation }
        func whitespace() { while i < chars.count && [9,10,13,32].contains(chars[i]) { i += 1 } }
        func consume(_ c: UInt16) -> Bool { whitespace(); if i < chars.count && chars[i] == c { i += 1; return true }; return false }
        func string() throws -> String {
            whitespace(); let start = i
            guard i < chars.count && chars[i] == 34 else { throw PreviewError.malformed("JSON 字符串缺少引号") }; i += 1
            var escaped = false
            while i < chars.count {
                let c = chars[i]; i += 1
                if c < 32 { throw PreviewError.malformed("JSON 字符串含控制字符") }
                if c == 34 && !escaped {
                    let literal = source.substring(with: NSRange(location: start, length: i - start))
                    guard let decoded = try? JSONDecoder().decode(String.self, from: Data(literal.utf8)) else { throw PreviewError.malformed("JSON 转义字符") }
                    return decoded
                }
                if c == 92 && !escaped { escaped = true } else { escaped = false }
            }
            throw PreviewError.malformed("JSON 字符串未闭合")
        }
        func value(name: String, path: String, depth: Int) throws -> JSONNode {
            try cancellation.check(); nodes += 1
            guard depth <= limits.structureDepth, nodes <= limits.structureNodes else { throw PreviewError.limit("JSON 最大深度 \(limits.structureDepth)、节点 \(limits.structureNodes)") }
            whitespace(); let start = i; var children: [JSONNode] = []; var kind = "value"
            if consume(123) {
                kind = "object"; var keys: Set<String> = []
                if !consume(125) {
                    repeat {
                        let key = try string(); if !keys.insert(key).inserted { duplicates = true }
                        guard consume(58) else { throw PreviewError.malformed("JSON 缺少冒号") }
                        let keyJSON = String(data: try JSONEncoder().encode(key), encoding: .utf8)!
                        children.append(try value(name: key, path: path + "[" + keyJSON + "]", depth: depth + 1))
                    } while consume(44)
                    guard consume(125) else { throw PreviewError.malformed("JSON 对象未闭合") }
                }
            } else if consume(91) {
                kind = "array"
                if !consume(93) {
                    repeat { children.append(try value(name: "[\(children.count)]", path: path + "[\(children.count)]", depth: depth + 1)) } while consume(44)
                    guard consume(93) else { throw PreviewError.malformed("JSON 数组未闭合") }
                }
            } else if i < chars.count && chars[i] == 34 { _ = try string(); kind = "string" }
            else {
                while i < chars.count && ![9,10,13,32,44,93,125].contains(chars[i]) { i += 1 }
                let token = source.substring(with: NSRange(location: start, length: i - start))
                guard ["true", "false", "null"].contains(token) || token.range(of: #"^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$"#, options: .regularExpression) != nil else { throw PreviewError.malformed("JSON 值非法（UTF-16 偏移 \(start)）") }
            }
            return JSONNode(name: name, path: path, range: NSRange(location: start, length: i - start), children: children, kind: kind)
        }
    }
}
