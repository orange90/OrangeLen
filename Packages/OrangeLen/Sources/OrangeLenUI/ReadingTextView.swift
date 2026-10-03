import AppKit
import os
import OrangeLenCore

public final class ReadingTextView: NSTextView {
    public var model = TextModel.plain("")
    public var sentences: [NSRange] = []
    public var activeSentence = 0
    public var anchor = 0
    public var focusEnabled = false
    public var highlightEnabled = true
    public var dimEnabled = true
    public var rulerLines = 3
    public var copyFeedback: ((String) -> Void)?
    public var findAction: (() -> Void)?
    public var anchorChanged: (() -> Void)?
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    public override func copy(_ sender: Any?) {
        Logger(subsystem: "local.OrangeLen", category: "Input").notice("copy requested selectionLength=\(self.selectedRange().length)")
        let value = model.copiedSource(selectedRange())
        guard !value.isEmpty else { copyFeedback?("请先选择要复制的内容"); return }
        Clipboard.write(value, feedback: copyFeedback)
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
    public override func keyDown(with event: NSEvent) {
        if focusEnabled && event.modifierFlags.contains(.option) && (event.keyCode == 125 || event.keyCode == 126) {
            moveSentence(event.keyCode == 125 ? 1 : -1); return
        }
        super.keyDown(with: event)
    }
    public override func mouseDown(with event: NSEvent) {
        Logger(subsystem: "local.OrangeLen", category: "Input").notice("text mouseDown")
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        super.mouseDown(with: event)
        if focusEnabled && selectedRange().length == 0 {
            anchor = characterIndexForInsertion(at: point)
            activeSentence = sentences.firstIndex { NSLocationInRange(anchor, $0) } ?? activeSentence
            needsDisplay = true; anchorChanged?()
        }
    }
    public func moveSentence(_ delta: Int) {
        guard !sentences.isEmpty else { return }
        activeSentence = min(max(activeSentence + delta, 0), sentences.count - 1)
        anchor = sentences[activeSentence].location
        scrollRangeToVisible(sentences[activeSentence]); needsDisplay = true; anchorChanged?()
    }
    public func sentence(at offset: Int) {
        anchor = min(max(0, offset), max(0, model.display.utf16.count - 1))
        activeSentence = sentences.firstIndex { NSLocationInRange(anchor, $0) } ?? 0
        needsDisplay = true
    }
    /// Table cells may share a visual baseline while occupying different glyph ranges.
    /// Group actual line fragments by screen Y, not by logical paragraph/cell order.
    func visualRulerRects() -> [NSRect] {
        guard rulerLines > 0, !string.isEmpty, let layout = layoutManager, let container = textContainer else { return [] }
        let safe = min(anchor, (string as NSString).length - 1)
        let glyph = layout.glyphIndexForCharacter(at: safe)
        guard glyph < layout.numberOfGlyphs else { return [] }
        let current = layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        let radius = max(400, current.height * 6)
        let region = NSRect(x: 0, y: max(0, current.minY - radius), width: max(bounds.width, container.containerSize.width), height: radius * 2 + current.height)
        let nearby = layout.glyphRange(forBoundingRect: region, in: container)
        var fragments: [NSRect] = []
        layout.enumerateLineFragments(forGlyphRange: nearby) { rect, _, _, _, _ in
            guard rect.height > 0 else { return }
            fragments.append(NSRect(x: -self.textContainerOrigin.x, y: rect.minY, width: self.bounds.width, height: rect.height))
        }
        fragments.sort { $0.minY < $1.minY }
        var rows: [NSRect] = []
        for rect in fragments {
            if let last = rows.last, abs(last.minY - rect.minY) < 1 {
                rows[rows.count - 1] = last.union(rect)
            } else { rows.append(rect) }
        }
        guard let index = rows.firstIndex(where: { abs($0.minY - current.minY) < 1 }) else { return [] }
        let start = max(0, min(index - rulerLines / 2, rows.count - rulerLines))
        return Array(rows.dropFirst(start).prefix(rulerLines))
    }
    public override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)
        guard focusEnabled, let layout = layoutManager, let container = textContainer, !sentences.isEmpty else { return }
        let sentence = sentences[min(activeSentence, sentences.count - 1)]
        let origin = textContainerOrigin
        for band in visualRulerRects() {
            let band = band.offsetBy(dx: origin.x, dy: origin.y)
            NSColor.systemGreen.withAlphaComponent(0.10).setFill(); band.fill()
            NSColor.systemGreen.withAlphaComponent(0.65).setFill(); NSRect(x: 4, y: band.minY, width: 3, height: band.height).fill()
        }
        if highlightEnabled {
            let glyphs = layout.glyphRange(forCharacterRange: sentence, actualCharacterRange: nil)
            NSColor.systemYellow.withAlphaComponent(0.27).setFill()
            layout.enumerateEnclosingRects(forGlyphRange: glyphs, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: container) { r, _ in
                NSBezierPath(roundedRect: r.offsetBy(dx: origin.x, dy: origin.y), xRadius: 3, yRadius: 3).fill()
            }
        }
    }
    public override func draw(_ dirtyRect: NSRect) {
        // Only the prior and current sentence colors change; the attributed document is not rebuilt on navigation.
        if focusEnabled && dimEnabled, let layout = layoutManager, !sentences.isEmpty {
            if let previous = previousBright { layout.removeTemporaryAttribute(.foregroundColor, forCharacterRange: previous) }
            let current = sentences[min(activeSentence, sentences.count - 1)]
            textStorage?.enumerateAttribute(.foregroundColor, in: current) { value, range, _ in
                let original = value as? NSColor ?? .textColor
                let color = original == NSColor.secondaryLabelColor ? NSColor.textColor : original
                layout.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: range)
            }
            previousBright = current
        } else if let previous = previousBright { layoutManager?.removeTemporaryAttribute(.foregroundColor, forCharacterRange: previous); previousBright = nil }
        super.draw(dirtyRect)
    }
    private var previousBright: NSRange?
    public func clearDecoration() { previousBright = nil }
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
