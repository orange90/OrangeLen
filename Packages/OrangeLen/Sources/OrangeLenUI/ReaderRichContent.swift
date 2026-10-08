import AppKit
import OrangeLenCore

extension ReaderController {
    func refreshAttachments() {
        guard format == .markdown, mode.selectedSegment == 0, rendered != nil else { return }
        let selection = text.selectedRange(), position = scroll.contentView.bounds.origin
        text.textStorage?.setAttributedString(TextStyler.attributed(text.model, markdown: true, settings: settings, assets: markdownAssets, width: renderedWidth))
        text.setSelectedRange(selection); scroll.contentView.scroll(to: position)
        text.needsDisplay = true
    }
    func startRichRendering() {
        guard let model = rendered, !model.richContent.isEmpty else { return }
        let id = generation
        let renderer = RichContentRenderer(); richRenderer = renderer
        richTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let started = Date(); var pixels = 0
            for (index, item) in model.richContent.enumerated() {
                guard !Task.isCancelled, self.generation == id else { break }
                do {
                    guard index < 32, Date().timeIntervalSince(started) < 30, pixels < 8_000_000 else { throw PreviewError.limit("公式/图表预算，查看源码") }
                    let image = try await renderer.render(item, in: self.view)
                    guard !Task.isCancelled, self.generation == id else { break }
                    let count = Int(image.size.width * image.size.height * 4)
                    guard pixels + count <= 8_000_000 else { throw PreviewError.limit("公式/图表像素预算，查看源码") }
                    pixels += count; self.markdownAssets.rich[item.range.location] = image
                } catch {
                    guard !Task.isCancelled, self.generation == id else { break }
                    self.markdownAssets.richFailures[item.range.location] = "\(item.kind == .mermaid ? "图表" : "公式")未渲染 · 查看源码"
                }
                self.refreshAttachments()
            }
            renderer.cancel()
            if self.generation == id { self.richRenderer = nil; self.richTask = nil }
        }
    }
    @objc func loadRemoteImages() {
        guard let model = rendered else { return }
        beginRemoteImages(model.images.filter { ["http", "https"].contains(URL(string: $0.destination)?.scheme?.lowercased() ?? "") && markdownAssets.images[$0.range.location] == nil })
    }
    func beginRemoteImages(_ images: [MarkdownImage]) {
        guard remoteTask == nil, !images.isEmpty else { return }
        let id = generation
        remoteButton.isEnabled = false; remoteStatus.stringValue = "正在加载远程图片…"
        remoteTask = Task { @MainActor [weak self] in
            guard let self else { return }
            var successes = 0, failures = 0
            for image in images {
                guard !Task.isCancelled, self.generation == id else { break }
                do {
                    guard self.remoteAttempts < 8, self.remoteBytes <= 15 * 1024 * 1024 else { throw PreviewError.limit("本次文档远程图片预算已用尽") }
                    self.remoteAttempts += 1
                    let loader = RemoteImageRequest(); self.remoteLoader = loader
                    let data = try await loader.load(image.destination)
                    guard !Task.isCancelled, self.generation == id else { break }
                    self.remoteBytes += data.count
                    guard self.remoteBytes <= 20 * 1024 * 1024 else { throw PreviewError.limit("远程图片总计最多 20 MiB") }
                    let token = self.cancellation ?? Cancellation()
                    let decoded = try await Task.detached(priority: .utility) { try ImagePreview.decode(data, cancellation: token, maxSourcePixels: 25_000_000) }.value
                    guard !Task.isCancelled, self.generation == id else { break }
                    let pixels = self.markdownAssets.images.values.reduce(0) { $0 + $1.width * $1.height }
                    guard pixels + decoded.image.width * decoded.image.height <= 8_000_000 else { throw PreviewError.limit("文档图片像素预算") }
                    self.markdownAssets.images[image.range.location] = decoded.image
                    self.markdownAssets.failures[image.range.location] = nil; successes += 1
                } catch {
                    guard !Task.isCancelled, self.generation == id else { break }
                    self.markdownAssets.failures[image.range.location] = error.localizedDescription
                    failures += 1
                }
                self.refreshAttachments()
            }
            guard self.generation == id else { return }
            self.remoteLoader = nil; self.remoteTask = nil; self.remoteButton.isEnabled = true
            self.remoteStatus.stringValue = "已加载 \(successes) 张" + (failures > 0 ? " · \(failures) 张未加载（安全限制、网络或预算）" : "")
        }
    }
}
