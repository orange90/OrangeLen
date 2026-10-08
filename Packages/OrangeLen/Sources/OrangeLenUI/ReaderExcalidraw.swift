import AppKit
import OrangeLenCore

extension ReaderController {
    func loadExcalidraw(_ url: URL, root: URL?, id: UUID, token: Cancellation) {
        mode.isEnabled = false; headings.isEnabled = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Result { () -> (SourceSnapshot, Result<ExcalidrawPreview, Error>) in
                let scoped = root?.startAccessingSecurityScopedResource() ?? false
                defer { if scoped { root?.stopAccessingSecurityScopedResource() } }
                let source = try AccessBroker.read(url, root: root, cancellation: token)
                return (source, Result { try ExcalidrawPreview.parse(source.text, cancellation: token) })
            }
            DispatchQueue.main.async {
                guard let self, self.generation == id else { return }
                do {
                    let (source, sceneResult) = try result.get()
                    self.source = source; self.format = .json; self.mode.selectedSegment = 0
                    let scene = try sceneResult.get()
                    self.parseWarning = scene.warning
                    let renderer = RichContentRenderer(resourceName: "ExcalidrawRenderer")
                    self.richRenderer = renderer
                    self.richTask = Task { @MainActor [weak self] in
                        guard let self else { return }
                        defer { renderer.cancel() }
                        do {
                            let image = try await renderer.renderExcalidraw(scene, in: self.view)
                            guard self.generation == id else { return }
                            self.canvasImage = image
                            self.picture.setAccessibilityLabel("Excalidraw 画布：\(url.lastPathComponent)，\(scene.count) 个元素；切换源码可读取文字")
                            self.present(); self.finish(nil)
                        } catch {
                            guard self.generation == id else { return }
                            self.parseWarning = "画布渲染失败：\(error.localizedDescription) · 已降级源码"
                            self.present(); self.finish(nil)
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
