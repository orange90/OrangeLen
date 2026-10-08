import OrangeLenCore
import AppKit

/// Native zoom/pan surface shared by drawings, SVG and enlarged Markdown attachments.
final class ZoomCanvasView: NSImageView {
    var zoom: CGFloat = 1, pan = NSPoint.zero
    var onDismiss: (() -> Void)? { didSet { back.isHidden = onDismiss == nil } }
    private let label = NSTextField(labelWithString: L10n.text("适合窗口")), back = NSButton(title: L10n.text("返回正文"), target: nil, action: nil)
    private var lastPoint: NSPoint?
    override var image: NSImage? { didSet { fit(); needsDisplay = true } }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        let controls = NSStackView(); controls.spacing = 6
        for (title, action) in [("−", #selector(smaller)), ("+", #selector(larger)), (L10n.text("适合窗口"), #selector(fit)), ("100%", #selector(actual))] {
            let button = NSButton(title: title, target: self, action: action); button.bezelStyle = .rounded
            controls.addArrangedSubview(button)
        }
        back.target = self; back.action = #selector(dismiss); back.isHidden = true
        controls.addArrangedSubview(back); controls.addArrangedSubview(label)
        label.font = .systemFont(ofSize: 11); label.textColor = .secondaryLabelColor
        controls.translatesAutoresizingMaskIntoConstraints = false; addSubview(controls)
        NSLayoutConstraint.activate([controls.topAnchor.constraint(equalTo: topAnchor, constant: 10), controls.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)])
        setAccessibilityLabel(L10n.text("可缩放画布；拖动平移，捏合缩放"))
        setAccessibilityRole(.group)
        setAccessibilityChildren(controls.arrangedSubviews)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:)") }
    private var content: NSRect { NSRect(x: 12, y: 12, width: max(1, bounds.width - 24), height: max(1, bounds.height - 60)) }
    private var fitScale: CGFloat {
        guard let image, image.size.width > 0, image.size.height > 0 else { return 1 }
        return min(content.width / image.size.width, content.height / image.size.height)
    }
    @objc func fit() { zoom = 1; pan = .zero; updateLabel() }
    @objc func actual() { zoom = min(32, max(0.05, 1 / fitScale)); pan = .zero; updateLabel() }
    @objc func smaller() { setZoom(zoom / 1.25) }
    @objc func larger() { setZoom(zoom * 1.25) }
    @objc func dismiss() { onDismiss?() }
    func setZoom(_ value: CGFloat) { zoom = min(32, max(0.05, value)); updateLabel() }
    private func updateLabel() { label.stringValue = L10n.text("\(Int((fitScale * zoom * 100).rounded()))% · 拖动平移"); needsDisplay = true }
    override func layout() {
        super.layout(); label.isHidden = bounds.width < 520
        if let controls = subviews.first as? NSStackView {
            controls.arrangedSubviews.compactMap { $0 as? NSButton }.first { $0.title == "100%" }?.isHidden = bounds.width < 400
        }
    }
    override func setFrameSize(_ newSize: NSSize) { super.setFrameSize(newSize); updateLabel() }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill(); dirtyRect.fill()
        guard let image else { return }
        let scale = fitScale * zoom, size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        let rect = NSRect(x: content.midX - size.width / 2 + pan.x, y: content.midY - size.height / 2 + pan.y, width: size.width, height: size.height)
        NSGraphicsContext.saveGraphicsState(); content.clip(); NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        NSGraphicsContext.restoreGraphicsState()
    }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { lastPoint = convert(event.locationInWindow, from: nil); NSCursor.closedHand.push() }
    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let previous = lastPoint { pan.x += point.x - previous.x; pan.y += point.y - previous.y; needsDisplay = true }
        lastPoint = point
    }
    override func mouseUp(with event: NSEvent) { if lastPoint != nil { NSCursor.pop() }; lastPoint = nil }
    override func magnify(with event: NSEvent) { setZoom(zoom * (1 + event.magnification)) }
    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.command) { setZoom(zoom * pow(1.02, event.scrollingDeltaY)) }
        else { pan.x += event.scrollingDeltaX; pan.y -= event.scrollingDeltaY; needsDisplay = true }
    }
}
