import AppKit

/// Quick Look's enclosing window can stay light when the reader chooses dark.
/// Paint our own dynamic background so toolbar/status text has matching contrast.
class ReaderBackgroundView: NSView {
    override var isOpaque: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(rect: bounds).fill()
    }
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance(); needsDisplay = true
    }
}
