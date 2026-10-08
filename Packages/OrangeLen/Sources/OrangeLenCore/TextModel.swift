import Foundation
import NaturalLanguage
public struct MappingSpan: Sendable {
    public let display: NSRange
    public let source: NSRange
    public let exact: Bool
}
public struct TextStyle: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let strong = Self(rawValue: 1)
    public static let emphasis = Self(rawValue: 2)
    public static let code = Self(rawValue: 4)
    public static let strike = Self(rawValue: 8)
    public static let link = Self(rawValue: 16)
    public static let quote = Self(rawValue: 32)
    public static let metadata = Self(rawValue: 64)
    public static let callout = Self(rawValue: 128)
}
public struct StyledSpan: Sendable {
    public let range: NSRange
    public let style: TextStyle
}
public struct CodeLanguageSpan: Sendable {
    public let range: NSRange
    public let language: String
}
public struct ReadingBlock: Sendable {
    public enum Kind: Sendable { case paragraph, heading(Int), code, cell, html }
    public let range: NSRange
    public let source: NSRange
    public let kind: Kind
}
public struct MarkdownAnchor: Sendable {
    public let name: String
    public let range: NSRange
}
public struct MarkdownLink: Sendable {
    public let range: NSRange
    public let destination: String
}
public struct MarkdownImage: Sendable {
    public let range: NSRange
    public let destination: String
    public let alt: String
}
public struct MarkdownCell: Sendable {
    public let range: NSRange
    public let table: Int
    public let row: Int
    public let column: Int
    public let columns: Int
    public let alignment: Int // 0 left, 1 center, 2 right
}
public struct MarkdownParagraph: Sendable {
    public let range: NSRange
    public let listDepth: Int
    public let quoteDepth: Int
    public let firstInItem: Bool
}
public struct TextModel: Sendable {
    public var anchors: [MarkdownAnchor] = []
    public var codeLanguages: [CodeLanguageSpan] = []
    public var richContent: [MarkdownRichContent] = []
    public var links: [MarkdownLink] = []
    public var images: [MarkdownImage] = []
    public var cells: [MarkdownCell] = []
    public var paragraphs: [MarkdownParagraph] = []
    public var source: String
    public var display: String
    public var mapping: [MappingSpan]
    public var styles: [StyledSpan]
    public var blocks: [ReadingBlock]
    public var warnings: [String]
    public static func plain(_ source: String, code: Bool = false) -> Self {
        let ns = source as NSString
        var blocks: [ReadingBlock] = []; var start = 0
        while start < ns.length && blocks.count < PreviewLimits().structureNodes {
            let r = ns.lineRange(for: NSRange(location: start, length: 0))
            blocks.append(ReadingBlock(range: r, source: r, kind: code ? .code : .paragraph)); start = NSMaxRange(r)
        }
        return Self(source: source, display: source, mapping: [.init(display: NSRange(location: 0, length: ns.length), source: NSRange(location: 0, length: ns.length), exact: true)], styles: [], blocks: blocks, warnings: [])
    }
    public func sourceRange(for displayRange: NSRange) -> NSRange? {
        let spans = mapping.filter { NSIntersectionRange($0.display, displayRange).length > 0 }
        guard !spans.isEmpty else { return nil }
        let ranges = spans.map { span -> NSRange in
            guard span.exact else { return span.source }
            let clipped = NSIntersectionRange(span.display, displayRange)
            return NSRange(location: span.source.location + clipped.location - span.display.location, length: clipped.length)
        }
        let start = ranges.map(\.location).min()!, end = ranges.map { NSMaxRange($0) }.max()!
        guard start >= 0, end >= start, end <= (source as NSString).length else { return nil }
        return NSRange(location: start, length: end - start)
    }
    public func displayOffset(forSource offset: Int) -> Int {
        guard let span = mapping.first(where: { $0.exact && NSLocationInRange(offset, $0.source) }) ?? mapping.first(where: { NSLocationInRange(offset, $0.source) }) ?? mapping.last else { return 0 }
        return span.display.location + (span.exact ? min(max(0, offset - span.source.location), span.display.length) : 0)
    }
    public func copiedSource(_ range: NSRange) -> String {
        if !display.isEmpty, range.location == 0, range.length >= display.utf16.count { return source }
        guard let sourceRange = sourceRange(for: range) else { return "" }
        return (source as NSString).substring(with: sourceRange)
    }
    public func search(_ query: String, caseSensitive: Bool = false) -> [NSRange] {
        guard !query.isEmpty else { return [] }
        let ns = display as NSString; var result: [NSRange] = []; var start = 0
        while start < ns.length && result.count < 20000 {
            let found = ns.range(of: query, options: caseSensitive ? [] : [.caseInsensitive], range: NSRange(location: start, length: ns.length - start))
            if found.location == NSNotFound { break }
            result.append(found); start = NSMaxRange(found)
        }
        for item in richContent where item.content.range(of: query, options: caseSensitive ? [] : [.caseInsensitive]) != nil {
            result.append(item.range)
        }
        return result.sorted { $0.location < $1.location }
    }
    public func sentences() -> [NSRange] {
        var result: [NSRange] = []
        let ns = display as NSString
        for block in blocks {
            if result.count >= PreviewLimits().structureNodes { break }
            switch block.kind {
            case .code, .html:
                var start = block.range.location
                while start < NSMaxRange(block.range) && result.count < PreviewLimits().structureNodes {
                    let line = NSIntersectionRange(ns.lineRange(for: NSRange(location: start, length: 0)), block.range)
                    if line.length == 0 { break }
                    result.append(line); start = NSMaxRange(line)
                }
            default:
                let part = ns.substring(with: block.range)
                let tokenizer = NLTokenizer(unit: .sentence); tokenizer.string = part
                tokenizer.enumerateTokens(in: part.startIndex..<part.endIndex) { range, _ in
                    let local = NSRange(range, in: part)
                    result.append(NSRange(location: block.range.location + local.location, length: local.length)); return result.count < PreviewLimits().structureNodes
                }
            }
        }
        return result
    }
}
