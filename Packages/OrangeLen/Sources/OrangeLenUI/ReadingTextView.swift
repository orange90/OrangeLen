import AppKit
import os
import OrangeLenCore

public final class ReadingTextView: NSTextView {
    public var model = TextModel.plain("")
    public var anchor = 0
    public var copyFeedback: ((String) -> Void)?
    public var findAction: (() -> Void)?
    var attachmentAction: ((Int) -> Bool)?
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    public override func copy(_ sender: Any?) {
        Logger(subsystem: "local.OrangeLen", category: "Input").notice("copy requested selectionLength=\(self.selectedRange().length)")
        let value = model.copiedSource(selectedRange())
        guard !value.isEmpty else { copyFeedback?("请先选择要复制的内容"); return }
        Clipboard.write(value, feedback: copyFeedback)
    }
    private var contextCode: NSRange?
    public override func menu(for event: NSEvent) -> NSMenu? {
        let menu = super.menu(for: event) ?? NSMenu()
        let point = convert(event.locationInWindow, from: nil)
        let index = characterIndexForInsertion(at: point)
        contextCode = model.blocks.first { block in
            guard case .code = block.kind else { return false }
            return NSLocationInRange(index, block.range)
        }?.range
        if contextCode != nil {
            let item = NSMenuItem(title: "复制代码块原文", action: #selector(copyCodeBlock), keyEquivalent: ""); item.target = self
            menu.insertItem(item, at: 0)
        }
        return menu
    }
    @objc func copyCodeBlock() {
        guard let contextCode, let range = model.sourceRange(for: contextCode) else { return }
        Clipboard.write((model.source as NSString).substring(with: range), feedback: copyFeedback)
    }
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers?.lowercased() {
            case "f": findAction?(); return true
            case "c": copy(nil); return true
            case "a": selectAll(nil); return true
            default: break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
    public override func mouseDown(with event: NSEvent) {
        Logger(subsystem: "local.OrangeLen", category: "Input").notice("text mouseDown")
        window?.makeFirstResponder(self)
        if let layout = layoutManager, let container = textContainer {
            let point = convert(event.locationInWindow, from: nil)
            let inContainer = NSPoint(x: point.x - textContainerOrigin.x, y: point.y - textContainerOrigin.y)
            let glyph = layout.glyphIndex(for: inContainer, in: container)
            if glyph < layout.numberOfGlyphs {
                let index = layout.characterIndexForGlyph(at: glyph)
                let rect = layout.boundingRect(forGlyphRange: NSRange(location: glyph, length: 1), in: container)
                if rect.contains(inContainer), textStorage?.attribute(.attachment, at: index, effectiveRange: nil) != nil, attachmentAction?(index) == true { return }
            }
        }
        super.mouseDown(with: event)
    }
    public func setAnchor(at offset: Int) {
        anchor = min(max(0, offset), max(0, model.display.utf16.count - 1))
    }
}

final class LineRuler: NSRulerView {
    weak var text: NSTextView?
    var starts: [Int] = [0]
    init(scroll: NSScrollView, text: NSTextView) {
        self.text = text; super.init(scrollView: scroll, orientation: .verticalRuler)
        clientView = text; ruleThickness = 52; clipsToBounds = true
    }
    required init(coder: NSCoder) { fatalError("init(coder:) not supported") }
    func update(_ string: String) { starts = [0]; for (index, c) in string.utf16.enumerated() where c == 10 { starts.append(index + 1) }; needsDisplay = true }
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let text, let layout = text.layoutManager, let container = text.textContainer else { return }
        NSColor.windowBackgroundColor.setFill(); bounds.intersection(rect).fill()
        let visible = text.visibleRect.offsetBy(dx: -text.textContainerOrigin.x, dy: -text.textContainerOrigin.y)
        let glyphs = layout.glyphRange(forBoundingRect: visible, in: container)
        layout.enumerateLineFragments(forGlyphRange: glyphs) { line, _, _, range, _ in
            let character = layout.characterIndexForGlyph(at: range.location)
            var lo = 0, hi = self.starts.count
            while lo < hi { let mid = (lo + hi) / 2; if self.starts[mid] <= character { lo = mid + 1 } else { hi = mid } }
            let index = max(0, lo - 1)
            guard self.starts[index] == character else { return }
            let p = self.convert(NSPoint(x: 0, y: line.minY + text.textContainerOrigin.y), from: text)
            let value = "\(index + 1)" as NSString
            value.draw(at: NSPoint(x: 8, y: p.y), withAttributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular), .foregroundColor: NSColor.secondaryLabelColor])
        }
    }
}
