import Foundation

/// Safe display extensions keep original UTF-16 source positions, including metadata
/// and relocated footnotes. No YAML tags, HTML, or document configuration is executed.
enum MarkdownExtras {
    struct Definition { let id: String; let source: NSRange; let content: String; let offsets: [Int] }
    struct Prepared { let masked: String; let front: NSRange?; let frontBody: NSRange?; let definitions: [Definition] }
    static func prepare(_ source: String, cancellation: Cancellation) throws -> Prepared {
        let ns = source as NSString
        var lines: [NSRange] = [], offset = 0
        while offset < ns.length {
            if lines.count % 1024 == 0 { try cancellation.check() }
            guard lines.count < 200_000 else { throw PreviewError.limit("Markdown 行数") }
            let range = ns.lineRange(for: .init(location: offset, length: 0)); lines.append(range); offset = NSMaxRange(range)
        }
        var front: NSRange?, frontBody: NSRange?, definitions: [Definition] = [], masks: [NSRange] = []
        if let first = lines.first, ns.substring(with: first).trimmingCharacters(in: .newlines) == "---", let end = lines.dropFirst().prefix(500).first(where: { ["---", "..."].contains(ns.substring(with: $0).trimmingCharacters(in: .newlines)) }) {
            front = NSRange(location: 0, length: NSMaxRange(end)); frontBody = NSRange(location: NSMaxRange(first), length: end.location - NSMaxRange(first)); masks.append(front!)
        }
        let pattern = try NSRegularExpression(pattern: #"^ {0,3}\[\^([^\]\r\n]{1,64})\]:[ \t]*(.*?)[\r\n]*$"#)
        var i = 0, fence: Character?, fenceCount = 0
        while i < lines.count {
            try cancellation.check()
            let line = lines[i], text = ns.substring(with: line)
            if front.map({ NSIntersectionRange($0, line).length > 0 }) == true { i += 1; continue }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if let first = trimmed.first, first == "`" || first == "~" {
                let count = trimmed.prefix(while: { $0 == first }).count
                if count >= 3 {
                    if fence == nil { fence = first; fenceCount = count }
                    else if fence == first && count >= fenceCount { fence = nil }
                    i += 1; continue
                }
            }
            guard fence == nil, !text.hasPrefix("    "), !text.hasPrefix("\t"), definitions.count < 256, let match = pattern.firstMatch(in: text, range: .init(location: 0, length: text.utf16.count)) else { i += 1; continue }
            let id = (text as NSString).substring(with: match.range(at: 1))
            guard !definitions.contains(where: { $0.id == id }) else { i += 1; continue }
            let contentRange = match.range(at: 2)
            var content = (text as NSString).substring(with: contentRange), offsets = Array((line.location + contentRange.location)...(line.location + NSMaxRange(contentRange)))
            var end = NSMaxRange(line), next = i + 1
            while next < lines.count {
                let continuation = ns.substring(with: lines[next])
                let indent = continuation.hasPrefix("    ") ? 4 : continuation.hasPrefix("\t") ? 1 : 0
                guard indent > 0 else { break }
                let body = (continuation as NSString).substring(from: indent).trimmingCharacters(in: .newlines)
                content += "\n" + body
                if !offsets.isEmpty { offsets.removeLast() }
                offsets.append(end - 1)
                let start = lines[next].location + indent
                offsets += Array(start...(start + body.utf16.count))
                end = NSMaxRange(lines[next]); next += 1
            }
            let range = NSRange(location: line.location, length: end - line.location)
            definitions.append(.init(id: id, source: range, content: content, offsets: offsets)); masks.append(range); i = next
        }
        var masked = source
        for range in masks.sorted(by: { $0.location > $1.location }) {
            let blank = ns.substring(with: range).unicodeScalars.map { scalar -> String in
                scalar == "\n" || scalar == "\r" ? String(scalar) : String(repeating: " ", count: scalar.utf16.count)
            }.joined()
            masked = (masked as NSString).replacingCharacters(in: range, with: blank)
        }
        return Prepared(masked: masked, front: front, frontBody: frontBody, definitions: definitions)
    }
    static func apply(_ input: TextModel, prepared: Prepared, cancellation: Cancellation, limits: PreviewLimits) throws -> TextModel {
        var model = input
        if let front = prepared.front, let body = prepared.frontBody {
            let value = "文档信息\n" + (input.source as NSString).substring(with: body)
            var prefix = TextModel.plain(""); prefix.source = input.source; prefix.display = value
            prefix.mapping = [.init(display: .init(location: 0, length: 4), source: front, exact: false), .init(display: .init(location: 5, length: body.length), source: body, exact: true)]
            prefix.styles = [.init(range: .init(location: 0, length: 4), style: .strong), .init(range: .init(location: 0, length: value.utf16.count), style: .metadata)]
            prefix.blocks = [.init(range: .init(location: 0, length: value.utf16.count), source: front, kind: .paragraph)]
            prefix.append(model); model = prefix
        }
        let callouts = try NSRegularExpression(pattern: #"\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]"#)
        let labels = ["NOTE": "说明", "TIP": "提示", "IMPORTANT": "重要", "WARNING": "警告", "CAUTION": "注意"]
        let display = model.display as NSString
        for match in callouts.matches(in: model.display, range: .init(location: 0, length: display.length)).reversed() {
            guard model.paragraphs.contains(where: { $0.quoteDepth > 0 && NSLocationInRange(match.range.location, $0.range) && (model.display as NSString).substring(with: .init(location: $0.range.location, length: match.range.location - $0.range.location)).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }), !model.styles.contains(where: { $0.style.contains(.code) && NSIntersectionRange($0.range, match.range).length > 0 }) else { continue }
            let original = model.sourceRange(for: match.range)
            let title = labels[display.substring(with: match.range(at: 1))] ?? "说明"
            model.replaceDisplay(match.range, value: title, source: original)
            model.styles.append(.init(range: .init(location: match.range.location, length: title.utf16.count), style: [.strong, .callout]))
        }
        let refPattern = try NSRegularExpression(pattern: #"(?<!\\)\[\^([^\]\r\n]{1,64})\]"#)
        let references = refPattern.matches(in: model.display, range: .init(location: 0, length: model.display.utf16.count))
        var ordered: [String] = []
        for match in references {
            let name = (model.display as NSString).substring(with: match.range(at: 1))
            if !model.copiedSource(match.range).hasPrefix("\\["), !model.styles.contains(where: { ($0.style.contains(.code) || $0.style.contains(.metadata)) && NSIntersectionRange($0.range, match.range).length > 0 }), prepared.definitions.contains(where: { $0.id == name }), !ordered.contains(name) { ordered.append(name) }
        }
        for match in references.reversed() {
            try cancellation.check()
            let name = (model.display as NSString).substring(with: match.range(at: 1))
            guard !model.copiedSource(match.range).hasPrefix("\\["), let number = ordered.firstIndex(of: name), !model.styles.contains(where: { ($0.style.contains(.code) || $0.style.contains(.metadata)) && NSIntersectionRange($0.range, match.range).length > 0 }) else { continue }
            let original = model.sourceRange(for: match.range), value = "[\(number + 1)]"
            model.replaceDisplay(match.range, value: value, source: original)
            model.links.append(.init(range: .init(location: match.range.location, length: value.utf16.count), destination: "orangelen-footnote:" + name))
        }
        let definitions = ordered.compactMap { name in prepared.definitions.first { $0.id == name } } + prepared.definitions.filter { !ordered.contains($0.id) }
        if !definitions.isEmpty { model.display += "\n脚注\n" }
        for (index, definition) in definitions.enumerated() {
            try cancellation.check()
            let start = model.display.utf16.count
            model.display += "\(index + 1). "
            model.mapping.append(.init(display: .init(location: start, length: model.display.utf16.count - start), source: definition.source, exact: false))
            var note = try MarkdownModel.base(definition.content, cancellation: cancellation, limits: limits)
            func original(_ range: NSRange) -> NSRange {
                guard definition.offsets.indices.contains(range.location), definition.offsets.indices.contains(NSMaxRange(range)) else { return definition.source }
                let start = definition.offsets[range.location], end = definition.offsets[NSMaxRange(range)]
                return NSRange(location: start, length: max(0, end - start))
            }
            note.mapping = note.mapping.map { span in
                let source = original(span.source)
                let exact = (input.source as NSString).substring(with: source) == (note.display as NSString).substring(with: span.display)
                return .init(display: span.display, source: source, exact: exact)
            }
            note.blocks = note.blocks.map { .init(range: $0.range, source: original($0.source), kind: $0.kind) }
            note.richContent = note.richContent.map { .init(range: $0.range, source: original($0.source), kind: $0.kind, content: $0.content) }
            model.append(note)
            model.anchors.append(.init(name: definition.id, range: .init(location: start, length: model.display.utf16.count - start)))
            if !model.display.hasSuffix("\n") { model.display += "\n" }
        }
        model.mapping.sort { $0.display.location < $1.display.location }
        return model
    }
}

extension TextModel {
    mutating func append(_ other: TextModel) {
        let offset = display.utf16.count
        func shift(_ range: NSRange) -> NSRange { .init(location: range.location + offset, length: range.length) }
        display += other.display
        mapping += other.mapping.map { .init(display: shift($0.display), source: $0.source, exact: $0.exact) }
        styles += other.styles.map { .init(range: shift($0.range), style: $0.style) }
        blocks += other.blocks.map { .init(range: shift($0.range), source: $0.source, kind: $0.kind) }
        links += other.links.map { .init(range: shift($0.range), destination: $0.destination) }
        images += other.images.map { .init(range: shift($0.range), destination: $0.destination, alt: $0.alt) }
        let tableOffset = cells.map(\.table).max() ?? 0
        cells += other.cells.map { .init(range: shift($0.range), table: $0.table + tableOffset, row: $0.row, column: $0.column, columns: $0.columns, alignment: $0.alignment) }
        paragraphs += other.paragraphs.map { .init(range: shift($0.range), listDepth: $0.listDepth, quoteDepth: $0.quoteDepth, firstInItem: $0.firstInItem) }
        richContent += other.richContent.map { .init(range: shift($0.range), source: $0.source, kind: $0.kind, content: $0.content) }
        codeLanguages += other.codeLanguages.map { .init(range: shift($0.range), language: $0.language) }
        anchors += other.anchors.map { .init(name: $0.name, range: shift($0.range)) }
        warnings += other.warnings
    }
    mutating func replaceDisplay(_ range: NSRange, value: String, source original: NSRange?) {
        let delta = value.utf16.count - range.length
        func shift(_ item: NSRange) -> NSRange {
            func position(_ offset: Int, end: Bool) -> Int {
                if offset <= range.location { return offset }
                if offset >= NSMaxRange(range) { return offset + delta }
                return range.location + (end ? value.utf16.count : 0)
            }
            let start = position(item.location, end: false), end = position(NSMaxRange(item), end: true)
            return .init(location: start, length: max(0, end - start))
        }
        display = (display as NSString).replacingCharacters(in: range, with: value)
        var updated: [MappingSpan] = []
        for span in mapping {
            if NSIntersectionRange(span.display, range).length == 0 { updated.append(.init(display: shift(span.display), source: span.source, exact: span.exact)); continue }
            if span.display.location < range.location {
                let count = range.location - span.display.location
                updated.append(.init(display: .init(location: span.display.location, length: count), source: span.exact ? .init(location: span.source.location, length: count) : span.source, exact: span.exact))
            }
            if NSMaxRange(span.display) > NSMaxRange(range) {
                let count = NSMaxRange(span.display) - NSMaxRange(range)
                updated.append(.init(display: .init(location: range.location + value.utf16.count, length: count), source: span.exact ? .init(location: NSMaxRange(span.source) - count, length: count) : span.source, exact: span.exact))
            }
        }
        if let original { updated.append(.init(display: .init(location: range.location, length: value.utf16.count), source: original, exact: false)) }
        mapping = updated.sorted { $0.display.location < $1.display.location }
        styles = styles.map { .init(range: shift($0.range), style: $0.style) }
        blocks = blocks.map { .init(range: shift($0.range), source: $0.source, kind: $0.kind) }
        links = links.map { .init(range: shift($0.range), destination: $0.destination) }
        images = images.map { .init(range: shift($0.range), destination: $0.destination, alt: $0.alt) }
        cells = cells.map { .init(range: shift($0.range), table: $0.table, row: $0.row, column: $0.column, columns: $0.columns, alignment: $0.alignment) }
        paragraphs = paragraphs.map { .init(range: shift($0.range), listDepth: $0.listDepth, quoteDepth: $0.quoteDepth, firstInItem: $0.firstInItem) }
        richContent = richContent.map { .init(range: shift($0.range), source: $0.source, kind: $0.kind, content: $0.content) }
        codeLanguages = codeLanguages.map { .init(range: shift($0.range), language: $0.language) }
        anchors = anchors.map { .init(name: $0.name, range: shift($0.range)) }
    }
}
