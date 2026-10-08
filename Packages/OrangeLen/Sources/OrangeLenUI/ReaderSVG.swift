import AppKit
import OrangeLenCore

extension ReaderController {
    func loadSVG(_ url: URL, root: URL?, id: UUID, token: Cancellation) {
        mode.isEnabled = false; headings.isEnabled = false
        DispatchQueue.global(qos:.userInitiated).async { [weak self] in
            let result = Result { () -> (SourceSnapshot,Result<SVGDocument,Error>) in
                let scoped = root?.startAccessingSecurityScopedResource() ?? false
                defer { if scoped { root?.stopAccessingSecurityScopedResource() } }
                let source = try AccessBroker.read(url,root:root,cancellation:token)
                return (source,Result { try SVGDocument.parse(source.text,cancellation:token) })
            }
            DispatchQueue.main.async {
                guard let self, self.generation == id else { return }
                do {
                    let (source, document) = try result.get(); self.source = source; self.format = .code; self.mode.selectedSegment = 0
                    let svg = try document.get()
                    self.parseWarning = svg.omitted > 0 ? "已省略 \(svg.omitted) 项脚本、样式、外部资源或不支持内容；源码保留" : ""
                    let renderer = RichContentRenderer(resourceName:"SVGRenderer"); self.richRenderer = renderer
                    self.richTask = Task { @MainActor [weak self] in
                        guard let self else { return }; defer { renderer.cancel() }
                        do {
                            let image = try await renderer.renderSVG(svg,in:self.view)
                            guard self.generation == id else { return }
                            self.canvasImage = image
                            self.picture.setAccessibilityLabel("SVG 图像：\(url.lastPathComponent)；切换源码可读取文字")
                            self.present(); self.finish(nil)
                        } catch {
                            guard self.generation == id else { return }
                            self.parseWarning = "SVG 渲染失败：\(error.localizedDescription) · 已降级源码"; self.present(); self.finish(nil)
                        }
                        if self.generation == id { self.richRenderer = nil; self.richTask = nil }
                    }
                } catch {
                    self.parseWarning = "\(error.localizedDescription) · 已降级源码"
                    if self.source != nil { self.present(); self.finish(nil) }
                    else { self.showMessage(error.localizedDescription); self.finish(error) }
                }
            }
        }
    }
}
