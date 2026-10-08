import Foundation
import Markdown

public enum MarkdownModel {
    public static func parse(_ source: String, cancellation: Cancellation = .init(), limits: PreviewLimits = .init()) throws -> TextModel {
        let extras = try MarkdownExtras.prepare(source, cancellation: cancellation)
        var model = try base(extras.masked, cancellation: cancellation, limits: limits)
        model.source = source
        model = try MarkdownExtras.apply(model, prepared: extras, cancellation: cancellation, limits: limits)
        return try projectMath(model, cancellation: cancellation)
    }
    static func base(_ source: String, cancellation: Cancellation, limits: PreviewLimits) throws -> TextModel {
        try cancellation.check()
        let document = Document(parsing: source, options: [.parseSymbolLinks])
        try cancellation.check()
        let builder = Builder(source: source, cancellation: cancellation, limits: limits)
        try builder.visit(document, style: [], depth: 0)
        return builder.model
    }
    private final class Builder {
        var model: TextModel
        let bytes: [UInt8]
        var lines = [0]
        var byteOffsets: [Int32] = []
        let cancellation: Cancellation
        let limits: PreviewLimits
        var nodes = 0
        var tableID = 0
        init(source: String, cancellation: Cancellation, limits: PreviewLimits) {
            model = TextModel(source: source, display: "", mapping: [], styles: [], blocks: [], warnings: [])
            bytes = Array(source.utf8); self.cancellation = cancellation; self.limits = limits
            for (i, c) in bytes.enumerated() where c == 10 { lines.append(i + 1) }
            byteOffsets = [Int32](repeating: 0, count: bytes.count + 1)
            var byte = 0; var utf16 = 0
            for scalar in source.unicodeScalars {
                for j in 0..<scalar.utf8.count { byteOffsets[byte + j] = Int32(utf16) }
                byte += scalar.utf8.count; utf16 += scalar.utf16.count
            }
            byteOffsets[byte] = Int32(utf16)
        }
        func sourceRange(_ node: any Markup) -> NSRange {
            guard let r = node.range else { return NSRange(location: 0, length: 0) }
            func offset(_ loc: SourceLocation) -> Int {
                let line = min(max(0, loc.line - 1), lines.count - 1)
                let byte = min(bytes.count, lines[line] + max(0, loc.column - 1))
                return Int(byteOffsets[byte])
            }
            let start = offset(r.lowerBound); let end = offset(r.upperBound)
            return NSRange(location: start, length: max(0, end - start))
        }
        func append(_ value: String, source: NSRange?, style: TextStyle = []) {
            guard !value.isEmpty else { return }
            let display = NSRange(location: model.display.utf16.count, length: value.utf16.count)
            model.display += value
            if let source, source.length > 0 {
                model.mapping.append(.init(display: display, source: source, exact: (model.source as NSString).substring(with: source) == value))
            }
            if !style.isEmpty { model.styles.append(.init(range: display, style: style)) }
        }
        func appendText(_ value: String, source range: NSRange, style: TextStyle) throws {
            let raw = (model.source as NSString).substring(with: range)
            if raw == value { append(value, source: range, style: style); return }
            // Decode escaped punctuation and entities into separate spans, so selecting
            // a neighboring character never copies the entire transformed Text node.
            let rawNS = raw as NSString
            var pieces: [(String, NSRange)] = []; var i = 0
            while i < rawNS.length {
                try cancellation.check()
                guard pieces.count + model.mapping.count < limits.structureNodes else { throw PreviewError.limit("Markdown 映射片段数") }
                if rawNS.character(at: i) == 92 && i + 1 < rawNS.length {
                    let next = rawNS.substring(with: NSRange(location: i + 1, length: 1))
                    if next.rangeOfCharacter(from: .punctuationCharacters) != nil || next.rangeOfCharacter(from: .symbols) != nil {
                        pieces.append((next, NSRange(location: range.location + i, length: 2))); i += 2; continue
                    }
                }
                if rawNS.character(at: i) == 38 {
                    let tail = NSRange(location: i, length: min(40, rawNS.length - i))
                    let end = rawNS.range(of: ";", range: tail)
                    if end.location != NSNotFound {
                        let r = NSRange(location: i, length: end.location - i + 1)
                        let entity = rawNS.substring(with: r)
                        let parsed = Document(parsing: entity)
                        if let paragraph = parsed.children.first(where: { _ in true }) as? Paragraph, let text = paragraph.children.first(where: { _ in true }) as? Markdown.Text, text.string != entity {
                            pieces.append((text.string, NSRange(location: range.location + i, length: r.length))); i += r.length; continue
                        }
                    }
                }
                let start = i
                i = NSMaxRange(rawNS.rangeOfComposedCharacterSequence(at: i))
                while i < rawNS.length && rawNS.character(at: i) != 38 && rawNS.character(at: i) != 92 { i = NSMaxRange(rawNS.rangeOfComposedCharacterSequence(at: i)) }
                let r = NSRange(location: start, length: i - start)
                pieces.append((rawNS.substring(with: r), NSRange(location: range.location + r.location, length: r.length))); i = NSMaxRange(r)
            }
            if pieces.map({ $0.0 }).joined() == value {
                for piece in pieces { append(piece.0, source: piece.1, style: style) }
            } else { append(value, source: range, style: style); model.warnings.append("部分规范化文本按完整解析节点映射；源码视图可精确选择。") }
        }
        func newline() { if !model.display.isEmpty && !model.display.hasSuffix("\n") { append("\n", source: nil) } }
        func visit(_ node: any Markup, style inherited: TextStyle, depth: Int) throws {
            try cancellation.check(); nodes += 1
            guard depth <= limits.structureDepth, nodes <= limits.structureNodes else { throw PreviewError.limit("Markdown 结构深度/节点数") }
            let range = sourceRange(node)
            var style = inherited
            if node is Strong { style.insert(.strong) }
            if node is Emphasis { style.insert(.emphasis) }
            if node is Strikethrough { style.insert(.strike) }
            if node is Link { style.insert(.link) }
            if node is BlockQuote { style.insert(.quote) }
            if let text = node as? Markdown.Text { try appendText(text.string, source: range, style: style); return }
            if node is SoftBreak { append(" ", source: range, style: style); return }
            if node is LineBreak { append("\u{2028}", source: range, style: style); return }
            if let code = node as? InlineCode { append(code.code, source: range, style: style.union(.code)); return }
            if let image = node as? Image {
                let start = model.display.utf16.count
                let alt = image.plainText.isEmpty ? "图片" : image.plainText
                append("\u{FFFC}", source: range)
                model.images.append(.init(range: NSRange(location: start, length: 1), destination: image.source ?? "", alt: alt))
                // Keep alt text searchable and source-copyable without changing attachment offsets.
                append(" " + alt, source: range, style: .quote)
                if (image.source ?? "").hasPrefix("http") { model.warnings.append("远程图片不自动加载") }
                return
            }
            if let table = node as? Table {
                newline(); tableID += 1; let id = tableID
                let columns = table.maxColumnCount
                guard columns <= 32 else { throw PreviewError.limit("Markdown 表格最多 32 列") }
                let rows: [any Markup] = [table.head] + table.body.children.map { $0 }
                for (rowIndex, row) in rows.enumerated() {
                    for (columnIndex, cell) in row.children.enumerated() {
                        try cancellation.check(); nodes += 1
                        guard nodes <= limits.structureNodes else { throw PreviewError.limit("Markdown 表格节点数") }
                        let start = model.display.utf16.count
                        for child in cell.children { try visit(child, style: rowIndex == 0 ? style.union(.strong) : style, depth: depth + 2) }
                        if model.display.utf16.count == start { append("\u{200B}", source: nil) }
                        let content = NSRange(location: start, length: model.display.utf16.count - start)
                        model.blocks.append(.init(range: content, source: sourceRange(cell), kind: .cell))
                        append("\n", source: nil)
                        let alignment = table.columnAlignments[columnIndex]
                        model.cells.append(.init(range: NSRange(location: start, length: model.display.utf16.count - start), table: id, row: rowIndex, column: columnIndex, columns: columns, alignment: alignment == .center ? 1 : alignment == .right ? 2 : 0))
                    }
                }
                append("\n", source: nil); return
            }
            if let code = node as? CodeBlock {
                newline(); let start = model.display.utf16.count
                if ["mermaid", "math", "latex", "tex"].contains(code.language?.lowercased() ?? "") {
                    append("\u{FFFC}", source: range)
                    let display = NSRange(location: start, length: 1)
                    model.richContent.append(.init(range: display, source: range, kind: code.language?.lowercased() == "mermaid" ? .mermaid : .displayMath, content: code.code))
                    model.blocks.append(.init(range: display, source: range, kind: .paragraph))
                    newline(); return
                }
                // Preserve exact source for fenced code when cmark's literal occurs verbatim.
                let raw = (model.source as NSString).substring(with: range) as NSString
                let match = Self.fencedContents(raw) ?? raw.range(of: code.code)
                let mapped = match.location == NSNotFound ? range : NSRange(location: range.location + match.location, length: match.length)
                let content = match.location == NSNotFound ? code.code : (model.source as NSString).substring(with: mapped)
                append(content, source: mapped, style: .code)
                if let language = code.language?.split(separator: " ").first { model.codeLanguages.append(.init(range: NSRange(location: start, length: content.utf16.count), language: String(language))) }
                model.blocks.append(.init(range: NSRange(location: start, length: model.display.utf16.count - start), source: range, kind: .code))
                newline(); return
            }
            if node is HTMLBlock || node is InlineHTML {
                let start = model.display.utf16.count
                append((model.source as NSString).substring(with: range), source: range, style: .code)
                model.blocks.append(.init(range: NSRange(location: start, length: model.display.utf16.count - start), source: range, kind: .html))
                if node is HTMLBlock { newline() }; return
            }
            if node is ThematicBreak { append("────────────\n", source: range); return }
            if let item = node as? ListItem {
                newline()
                let marker: String
                if let checkbox = item.checkbox { marker = checkbox == .checked ? "☑" : "☐" }
                else if let ordered = item.parent as? OrderedList { marker = "\(ordered.startIndex + UInt(item.indexInParent))." }
                else { marker = "•" }
                append(marker + "\t", source: nil)
            }
            let isBlock = node is Paragraph || node is Heading || node is Table.Cell
            if node is Heading { newline() }
            let start = model.display.utf16.count
            for child in node.children { try visit(child, style: style, depth: depth + 1) }
            if let link = node as? Link, let destination = link.destination {
                model.links.append(.init(range: NSRange(location: start, length: model.display.utf16.count - start), destination: destination))
            }
            if isBlock {
                let kind: ReadingBlock.Kind
                if let heading = node as? Heading { kind = .heading(heading.level) }
                else if node is Table.Cell { kind = .cell }
                else { kind = .paragraph }
                model.blocks.append(.init(range: NSRange(location: start, length: model.display.utf16.count - start), source: range, kind: kind))
                newline()
                var listDepth = 0, quoteDepth = 0
                var parent = node.parent
                while let current = parent {
                    if current is ListItem { listDepth += 1 }
                    if current is BlockQuote { quoteDepth += 1 }
                    parent = current.parent
                }
                let line = (model.display as NSString).paragraphRange(for: NSRange(location: start, length: max(0, model.display.utf16.count - start)))
                model.paragraphs.append(.init(range: line, listDepth: listDepth, quoteDepth: quoteDepth, firstInItem: node.parent is ListItem && node.indexInParent == 0))
            }
            if node is Table.Row || node is Table.Head { newline() }
        }
        // Search inside the fences, never in the language label. Preserve blank
        // lines and CRLF in the source instead of trimming cmark's normalized text.
        static func fencedContents(_ raw: NSString) -> NSRange? {
            guard let opening = try? NSRegularExpression(pattern: "^[ \\t]*(`{3,}|~{3,})[^\\r\\n]*(?:\\r\\n|\\n|\\r)"),
                  let match = opening.firstMatch(in: raw as String, range: NSRange(location: 0, length: raw.length)) else { return nil }
            let fence = raw.substring(with: match.range(at: 1))
            let marker = fence.first!
            let start = NSMaxRange(match.range)
            var cursor = start
            while cursor < raw.length {
                let line = raw.lineRange(for: NSRange(location: cursor, length: 0))
                let value = raw.substring(with: line).trimmingCharacters(in: .whitespacesAndNewlines)
                let count = value.prefix { $0 == marker }.count
                if count >= fence.count && value.dropFirst(count).allSatisfy({ $0 == " " || $0 == "\t" }) {
                    return NSRange(location: start, length: cursor - start)
                }
                cursor = NSMaxRange(line)
            }
            return NSRange(location: start, length: raw.length - start)
        }
    }
}
