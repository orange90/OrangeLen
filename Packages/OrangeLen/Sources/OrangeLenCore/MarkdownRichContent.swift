import Foundation

public struct MarkdownRichContent: Sendable {
    public enum Kind: String, Sendable { case math, displayMath, mermaid }
    public let range: NSRange
    public let source: NSRange
    public let kind: Kind
    public let content: String
    public init(range: NSRange, source: NSRange, kind: Kind, content: String) {
        self.range = range; self.source = source; self.kind = kind; self.content = content
    }
}

extension MarkdownModel {
    // Work against the original source so cmark's emphasis/escape normalization never
    // changes TeX. Replace mapped display spans, keeping every consumer on one model.
    static func projectMath(_ input: TextModel, cancellation: Cancellation) throws -> TextModel {
        var model = input
        let source = input.source as NSString
        let protected = input.blocks.filter { if case .code = $0.kind { return true }; if case .html = $0.kind { return true }; return false }.map(\.source)
          + input.styles.filter { $0.style.contains(.code) }.compactMap { input.sourceRange(for: $0.range) }
          + input.images.compactMap { input.sourceRange(for: $0.range) }
          + input.richContent.map(\.source)
        let pattern = #"(?<!\\)\$\$([\s\S]+?)(?<!\\)\$\$|(?<!\\)\\\[([\s\S]+?)(?<!\\)\\\]|(?<![\\$])\$(?![\s$])([^\r\n]+?)(?<![\\\s])\$(?![\d$])|(?<!\\)\\\(([^\r\n]+?)(?<!\\)\\\)"#
        let regex = try NSRegularExpression(pattern: pattern)
        var candidates: [(NSRange, NSRange, MarkdownRichContent.Kind, String)] = []
        regex.enumerateMatches(in: input.source, range: NSRange(location: 0, length: source.length)) { match, _, stop in
            guard let match else { return }
            if candidates.count >= 64 { stop.pointee = true; return }
            guard !protected.contains(where: { NSIntersectionRange($0, match.range).length > 0 }), match.range.length <= 16_384 else { return }
            let spans = input.mapping.filter { NSIntersectionRange($0.source, match.range).length > 0 }
            guard let first = spans.first, let last = spans.last else { return }
            let start = first.display.location + (first.exact ? max(0, match.range.location - first.source.location) : 0)
            let end = last.exact ? min(NSMaxRange(last.display), last.display.location + NSMaxRange(match.range) - last.source.location) : NSMaxRange(last.display)
            guard end > start else { return }
            let group = (1...4).first { match.range(at: $0).location != NSNotFound }!
            candidates.append((NSRange(location: start, length: end - start), match.range, group <= 2 ? .displayMath : .math, source.substring(with: match.range(at: group))))
        }
        for (range, original, kind, content) in candidates.reversed() {
            try cancellation.check()
            let delta = 1 - range.length
            func shifted(_ r: NSRange) -> NSRange {
                func position(_ p: Int, end: Bool) -> Int {
                    if p <= range.location { return p }
                    if p >= NSMaxRange(range) { return p + delta }
                    return range.location + (end ? 1 : 0)
                }
                let start = position(r.location, end: false), end = position(NSMaxRange(r), end: true)
                return NSRange(location: start, length: max(0, end - start))
            }
            model.display = (model.display as NSString).replacingCharacters(in: range, with: "\u{FFFC}")
            var mappings: [MappingSpan] = []
            for span in model.mapping {
                if NSIntersectionRange(span.display, range).length == 0 {
                    mappings.append(.init(display: shifted(span.display), source: span.source, exact: span.exact)); continue
                }
                if span.display.location < range.location {
                    let length = range.location - span.display.location
                    mappings.append(.init(display: NSRange(location: span.display.location, length: length), source: span.exact ? NSRange(location: span.source.location, length: length) : span.source, exact: span.exact))
                }
                if NSMaxRange(span.display) > NSMaxRange(range) {
                    let length = NSMaxRange(span.display) - NSMaxRange(range)
                    mappings.append(.init(display: NSRange(location: range.location + 1, length: length), source: span.exact ? NSRange(location: NSMaxRange(span.source) - length, length: length) : span.source, exact: span.exact))
                }
            }
            mappings.append(.init(display: NSRange(location: range.location, length: 1), source: original, exact: false))
            model.mapping = mappings.sorted { $0.display.location < $1.display.location }
            model.styles = model.styles.map { .init(range: shifted($0.range), style: $0.style) }.filter { $0.range.length > 0 }
            model.blocks = model.blocks.map { .init(range: shifted($0.range), source: $0.source, kind: $0.kind) }
            model.links = model.links.map { .init(range: shifted($0.range), destination: $0.destination) }
            model.images = model.images.map { .init(range: shifted($0.range), destination: $0.destination, alt: $0.alt) }
            model.cells = model.cells.map { .init(range: shifted($0.range), table: $0.table, row: $0.row, column: $0.column, columns: $0.columns, alignment: $0.alignment) }
            model.paragraphs = model.paragraphs.map { .init(range: shifted($0.range), listDepth: $0.listDepth, quoteDepth: $0.quoteDepth, firstInItem: $0.firstInItem) }
            model.richContent = model.richContent.map { .init(range: shifted($0.range), source: $0.source, kind: $0.kind, content: $0.content) }
            model.richContent.append(.init(range: NSRange(location: range.location, length: 1), source: original, kind: kind, content: content))
        }
        model.richContent.sort { $0.range.location < $1.range.location }
        return model
    }
}
