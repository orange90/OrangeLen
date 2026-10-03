import AppKit
import OrangeLenCore

enum TextStyler {
    static func attributed(_ model: TextModel, markdown: Bool, settings: ReaderSettings, focus: Bool, assets: MarkdownAssets = .init(), width: CGFloat = 760) -> NSAttributedString {
        let size = markdown ? settings.documentSize : settings.codeSize
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = markdown ? size * 0.30 : 3
        paragraph.paragraphSpacing = markdown ? size * 0.7 : 0
        paragraph.defaultTabInterval = size * 9
        let color = focus && settings.dim ? NSColor.secondaryLabelColor : NSColor.textColor
        let result = NSMutableAttributedString(string: model.display, attributes: [.font: markdown ? NSFont.systemFont(ofSize: size) : NSFont.monospacedSystemFont(ofSize: size, weight: .regular), .foregroundColor: color, .paragraphStyle: paragraph])
        for span in model.styles {
            var font = span.style.contains(.code) ? NSFont.monospacedSystemFont(ofSize: size * 0.9, weight: .regular) : NSFont.systemFont(ofSize: size)
            if span.style.contains(.strong) { font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask) }
            if span.style.contains(.emphasis) { font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask) }
            result.addAttribute(.font, value: font, range: span.range)
            if span.style.contains(.code) { result.addAttribute(.backgroundColor, value: NSColor.quaternaryLabelColor.withAlphaComponent(0.08), range: span.range) }
            if span.style.contains(.strike) { result.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: span.range) }
            if span.style.contains(.link) { result.addAttributes([.foregroundColor: NSColor.linkColor, .underlineStyle: NSUnderlineStyle.single.rawValue], range: span.range) }
            if span.style.contains(.quote) { result.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: span.range) }
        }
        for block in model.blocks {
            if case .heading(let level) = block.kind {
                result.addAttribute(.font, value: NSFont.systemFont(ofSize: size * [1.8,1.5,1.25,1.12,1.0,1.0][min(5, max(0, level-1))], weight: .bold), range: block.range)
                let p = paragraph.mutableCopy() as! NSMutableParagraphStyle
                p.paragraphSpacingBefore = level <= 2 ? size : size * 0.6; p.paragraphSpacing = size * 0.55
                result.addAttribute(.paragraphStyle, value: p, range: (model.display as NSString).paragraphRange(for: block.range))
            }
            if markdown, case .code = block.kind {
                let p = paragraph.mutableCopy() as! NSMutableParagraphStyle; p.lineSpacing = 4; p.paragraphSpacing = 0
                let box = NSTextBlock(); box.setContentWidth(100, type: .percentageValueType); box.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.07)
                box.setWidth(12, type: .absoluteValueType, for: .padding)
                box.setWidth(6, type: .absoluteValueType, for: .margin)
                p.textBlocks = [box]
                result.addAttribute(.paragraphStyle, value: p, range: (model.display as NSString).paragraphRange(for: block.range))
                highlight(result, range: block.range)
            }
        }
        if markdown {
            for item in model.paragraphs where item.listDepth > 0 || item.quoteDepth > 0 {
                let p = paragraph.mutableCopy() as! NSMutableParagraphStyle
                let indent = CGFloat(item.listDepth) * size * 1.4
                p.headIndent = indent; p.firstLineHeadIndent = item.firstInItem ? max(0, indent - size * 1.3) : indent
                p.tabStops = [NSTextTab(textAlignment: .left, location: indent)]
                p.paragraphSpacing = size * 0.4
                if item.quoteDepth > 0 {
                    let quote = NSTextBlock(); quote.setContentWidth(100, type: .percentageValueType); quote.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.06)
                    quote.setWidth(3, type: .absoluteValueType, for: .border, edge: .minX)
                    quote.setBorderColor(.separatorColor)
                    quote.setWidth(CGFloat(item.quoteDepth) * 12, type: .absoluteValueType, for: .padding, edge: .minX)
                    quote.setWidth(8, type: .absoluteValueType, for: .padding, edge: .maxX)
                    p.textBlocks = [quote]
                }
                result.addAttribute(.paragraphStyle, value: p, range: item.range)
            }
            var tables: [Int: NSTextTable] = [:]
            for cell in model.cells {
                let table: NSTextTable
                if let existing = tables[cell.table] { table = existing }
                else {
                    table = NSTextTable(); table.numberOfColumns = cell.columns; table.layoutAlgorithm = .fixedLayoutAlgorithm
                    table.collapsesBorders = true; table.hidesEmptyCells = false; table.setContentWidth(100, type: .percentageValueType)
                    tables[cell.table] = table
                }
                let box = NSTextTableBlock(table: table, startingRow: cell.row, rowSpan: 1, startingColumn: cell.column, columnSpan: 1)
                box.setContentWidth(100 / CGFloat(cell.columns), type: .percentageValueType)
                box.setWidth(8, type: .absoluteValueType, for: .padding)
                box.setWidth(0.5, type: .absoluteValueType, for: .border); box.setBorderColor(.separatorColor)
                box.backgroundColor = cell.row == 0 ? NSColor.quaternaryLabelColor.withAlphaComponent(0.16) : cell.row % 2 == 0 ? NSColor.quaternaryLabelColor.withAlphaComponent(0.05) : .clear
                box.verticalAlignment = .topAlignment
                let p = paragraph.mutableCopy() as! NSMutableParagraphStyle
                p.textBlocks = [box]; p.paragraphSpacing = 0; p.lineSpacing = size * 0.2
                p.alignment = cell.alignment == 1 ? .center : cell.alignment == 2 ? .right : .left
                result.addAttribute(.paragraphStyle, value: p, range: cell.range)
            }
            for link in model.links where link.range.length > 0 {
                result.addAttributes([.link: link.destination, .toolTip: link.destination], range: link.range)
            }
            for image in model.images {
                let attachment = NSTextAttachment()
                if let loaded = assets.images[image.range.location] {
                    let columns = model.cells.first { NSLocationInRange(image.range.location, $0.range) }?.columns ?? 1
                    let available = max(32, min(width / CGFloat(columns) - 32, 900))
                    let scale = min(1, available / CGFloat(loaded.width))
                    let rendered = NSImage(cgImage: loaded, size: NSSize(width: CGFloat(loaded.width) * scale, height: CGFloat(loaded.height) * scale))
                    attachment.attachmentCell = NSTextAttachmentCell(imageCell: rendered)
                } else {
                    attachment.attachmentCell = placeholderCell(assets.failures[image.range.location] ?? "图片未加载", width: width)
                }
                result.addAttributes([.attachment: attachment, .toolTip: image.alt], range: image.range)
                if assets.images[image.range.location] == nil, ["http", "https"].contains(URL(string: image.destination)?.scheme?.lowercased() ?? "") {
                    result.addAttribute(.link, value: "orangelen-remote:\(image.range.location)", range: image.range)
                }
            }
        }
        if markdown {
            for item in model.richContent {
                let attachment = NSTextAttachment()
                if let image = assets.rich[item.range.location] {
                    let columns = model.cells.first { NSLocationInRange(item.range.location, $0.range) }?.columns ?? 1
                    let available = max(32, width / CGFloat(columns) - 32)
                    let scale = min(size / 18, available / max(1, image.size.width))
                    let copy = image.copy() as! NSImage
                    copy.size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
                    attachment.attachmentCell = NSTextAttachmentCell(imageCell: copy)
                } else {
                    attachment.attachmentCell = placeholderCell(assets.richFailures[item.range.location] ?? "正在渲染\(item.kind == .mermaid ? "图表" : "公式")…", width: width)
                }
                result.addAttributes([.attachment: attachment, .toolTip: item.content], range: item.range)
            }
        }
        if !markdown { highlight(result, range: NSRange(location: 0, length: result.length)) }
        return result
    }
    static func placeholderCell(_ title: String, width: CGFloat) -> NSTextAttachmentCell {
        let paragraph = NSMutableParagraphStyle(); paragraph.lineBreakMode = .byTruncatingTail
        let label = NSAttributedString(string: title, attributes: [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.linkColor, .paragraphStyle: paragraph])
        let size = NSSize(width: max(40, min(min(420, max(40, width - 32)), label.size().width + 20)), height: 28)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.controlBackgroundColor.setFill(); NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 5, yRadius: 5).fill()
            NSColor.separatorColor.setStroke(); NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 5, yRadius: 5).stroke()
            label.draw(in: NSRect(x: 10, y: 6, width: rect.width - 20, height: 17)); return true
        }
        let cell = NSTextAttachmentCell(imageCell: image); cell.setAccessibilityLabel(title)
        return cell
    }
    static func highlight(_ text: NSMutableAttributedString, range: NSRange) {
        let range = NSIntersectionRange(range, NSRange(location: 0, length: min(text.length, PreviewLimits().highlightUTF16)))
        guard range.length > 0 else { return }
        let sourceString = text.string
        // Lexical styling only; never invokes a compiler, interpreter or project tool.
        let patterns: [(String, NSColor)] = [
            (#"\b(?:let|var|func|class|struct|enum|import|from|def|return|if|else|for|while|const|function|async|await|true|false|null|nil|SELECT|FROM|WHERE)\b"#, .systemPurple),
            (#"\b[0-9]+(?:\.[0-9]+)?\b"#, .systemOrange),
            (#"\"(?:[^\"\\]|\\.)*\"|'(?:[^'\\]|\\.)*'"#, .systemRed),
            (#"(?m)//[^\r\n]*|^\s*#[^\r\n]*|/\*[\s\S]*?\*/"#, .systemGreen)
        ]
        for (pattern, color) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            regex.enumerateMatches(in: sourceString, range: range) { match, _, _ in
                if let match { text.addAttribute(.foregroundColor, value: color, range: match.range) }
            }
        }
    }
}
