import AppKit
import OrangeLenCore

private final class ImageMetadataPanel: NSView {
    let canvas: NSView, details: NSScrollView
    private let divider = NSBox()
    override var isFlipped: Bool { true }
    init(canvas: NSView, details: NSScrollView) {
        self.canvas = canvas; self.details = details
        super.init(frame: .zero)
        for child in [canvas, details, divider] {
            child.translatesAutoresizingMaskIntoConstraints = true; addSubview(child)
        }
        divider.boxType = .separator
    }
    required init?(coder: NSCoder) { fatalError("init(coder:)") }
    override func layout() {
        super.layout()
        // A canvas has the image's intrinsic size. Explicit frames keep the two
        // surfaces visible even when Quick Look first lays out a zero-size view.
        if bounds.width >= 760 {
            let width = floor(max(0, bounds.width - 1) * 0.55)
            canvas.frame = NSRect(x: 0, y: 0, width: width, height: bounds.height)
            divider.frame = NSRect(x: width, y: 0, width: 1, height: bounds.height)
            details.frame = NSRect(x: width + 1, y: 0, width: max(0, bounds.width - width - 1), height: bounds.height)
        } else {
            let height = floor(max(0, bounds.height - 1) * 0.5)
            canvas.frame = NSRect(x: 0, y: 0, width: bounds.width, height: height)
            divider.frame = NSRect(x: 0, y: height, width: bounds.width, height: 1)
            details.frame = NSRect(x: 0, y: height + 1, width: bounds.width, height: max(0, bounds.height - height - 1))
        }
    }
}

extension ReaderController {
    func loadMermaid(_ url: URL, root: URL?, id: UUID, token: Cancellation) {
        canvasLabel = "Mermaid"; mode.isEnabled = false; headings.isEnabled = false
        PreviewWorkQueue.parsing.submit(cancellation: token, work: { try AccessBroker.read(url, root: root, cancellation: token) }, completion: { [weak self] result in
            guard let self, self.generation == id else { return }
            do {
                let snapshot = try result.get(); self.source = snapshot; self.format = .code; self.mode.selectedSegment = 0
                self.present()
                self.startMermaidRendering(snapshot, id: id)
            } catch { self.showMessage(error.localizedDescription); self.finish(error) }
        })
    }
    func startMermaidRendering(_ snapshot: SourceSnapshot, id: UUID) {
        let renderer = RichContentRenderer(); self.richRenderer = renderer
        self.richTask = Task { @MainActor [weak self] in
            guard let self else { return }; defer { renderer.cancel() }
            do {
                guard !snapshot.partial else { throw PreviewError.limit(L10n.text("图表超出完整读取预算")) }
                let item = MarkdownRichContent(range: .init(location: 0, length: 0), source: .init(location: 0, length: snapshot.text.utf16.count), kind: .mermaid, content: snapshot.text)
                let image = try await renderer.render(item, in: self.view)
                guard self.generation == id else { return }
                self.canvasImage = image; self.picture.setAccessibilityLabel("Mermaid · " + (self.currentURL?.lastPathComponent ?? ""))
            } catch {
                guard self.generation == id else { return }
                self.parseWarning = L10n.text("图表渲染失败：\(error.localizedDescription) · 已降级源码")
            }
            guard self.generation == id else { return }
            self.present(); self.finish(nil); self.richRenderer = nil; self.richTask = nil
        }
    }
    func loadSubtitles(_ url: URL, root: URL?, id: UUID, token: Cancellation) {
        PreviewWorkQueue.parsing.submit(cancellation: token, work: { () -> (SourceSnapshot, Result<SubtitleDocument, Error>) in
            let snapshot = try AccessBroker.read(url, root: root, cancellation: token)
            return (snapshot, Result {
                guard !snapshot.partial else { throw PreviewError.limit(L10n.text("字幕超出完整读取预算")) }
                return try SubtitleDocument.parse(snapshot.text, webVTT: url.pathExtension.lowercased() == "vtt", cancellation: token)
            })
        }, completion: { [weak self] result in
            guard let self, self.generation == id else { return }
            do {
                let (snapshot, parsed) = try result.get(); self.source = snapshot; self.format = .text; self.mode.selectedSegment = 0
                do {
                    let document = try parsed.get(); self.tableData = document.table
                    self.parseWarning = L10n.text("字幕 \(document.cues.count) 条 · 结束时间 \(SubtitleDocument.timestamp(document.duration)) · 无效条目 \(document.rejected)")
                } catch { self.parseWarning = L10n.text("\(error.localizedDescription) · 已降级源码") }
                self.present(); self.finish(nil)
            } catch { self.showMessage(error.localizedDescription); self.finish(error) }
        })
    }
}

extension ReaderController {
    func showImageDetails(_ image: ImagePreview) {
        let metadata = image.metadata
        guard !metadata.fields.isEmpty || !metadata.warnings.isEmpty else { showContent(picture); return }
        let details = NSTextView(); imageMetadataText = details; details.isEditable = false; details.isSelectable = true
        details.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        details.textContainerInset = NSSize(width: 14, height: 14)
        details.string = L10n.text("AI 图片生成参数") + "\n\n" + metadata.text + "\n\n" + metadata.warnings.joined(separator: "\n")
        details.setAccessibilityLabel(L10n.text("AI 图片生成参数"))
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.documentView = details
        details.isHorizontallyResizable = false; details.autoresizingMask = [.width]
        details.textContainer?.widthTracksTextView = true
        // Let showContent detach the former surface before reparenting its canvas.
        let holder = NSView(); imageDetails = holder; showContent(holder)
        let panel = ImageMetadataPanel(canvas: picture, details: scroll)
        panel.translatesAutoresizingMaskIntoConstraints = false; holder.addSubview(panel)
        NSLayoutConstraint.activate([panel.leadingAnchor.constraint(equalTo: holder.leadingAnchor), panel.trailingAnchor.constraint(equalTo: holder.trailingAnchor), panel.topAnchor.constraint(equalTo: holder.topAnchor), panel.bottomAnchor.constraint(equalTo: holder.bottomAnchor)])
        updateToolbars(view.bounds.width)
    }
}
