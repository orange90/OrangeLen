import AppKit

/// A small number of native surfaces, with no custom shaders or animation timers.
/// Keeps the same content and actions when accessibility preferences change.
final class GlassSurface: NSView {
    let content: NSView
    private let radius: CGFloat
    private let inset: CGFloat
    private var effect: NSView?
    private var observer: NSObjectProtocol?
    private(set) var usesGlass = false

    init(content: NSView, radius: CGFloat = 12, inset: CGFloat = 0) {
        self.content = content; self.radius = radius; self.inset = inset
        super.init(frame: .zero)
        refreshMaterial()
        observer = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refreshMaterial()
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) } }

    func refreshMaterial() {
        setGlassEnabled(!NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency && !NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast)
    }
    func setGlassEnabled(_ enabled: Bool) {
        var available = false
        if #available(macOS 26.0, *) { available = enabled }
        guard effect == nil || usesGlass != available else { return }
        if #available(macOS 26.0, *), let glass = effect as? NSGlassEffectView { glass.contentView = nil }
        content.removeFromSuperview(); effect?.removeFromSuperview()
        usesGlass = available
        if #available(macOS 26.0, *), available {
            let glass = NSGlassEffectView(); glass.style = .regular; glass.cornerRadius = radius
            content.translatesAutoresizingMaskIntoConstraints = true; glass.contentView = content
            effect = glass; addSubview(glass)
        } else {
            let backing = NSView(); backing.addSubview(content)
            content.translatesAutoresizingMaskIntoConstraints = true; content.autoresizingMask = [.width, .height]
            effect = backing; addSubview(backing)
        }
        needsLayout = true; needsDisplay = true
    }
    override func layout() {
        super.layout()
        effect?.frame = bounds.insetBy(dx: inset, dy: inset)
        if !usesGlass, let effect { content.frame = effect.bounds }
    }
    override func draw(_ dirtyRect: NSRect) {
        if !usesGlass {
            NSColor.windowBackgroundColor.setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: inset, dy: inset), xRadius: radius, yRadius: radius).fill()
        }
    }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsDisplay = true }
}
