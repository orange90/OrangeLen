import AppKit
import PDFKit
import OrangeLenCore

extension ReaderController {
    func loadAdvanced(_ url: URL, root: URL?, id: UUID, token: Cancellation) -> Bool {
        let ext = url.pathExtension.lowercased()
        if MeshDocument.supports(url) {
            mode.isEnabled = false
            PreviewWorkQueue.parsing.submit(cancellation:token,work:{try MeshDocument.load(url,root:root,cancellation:token)},completion:{ [weak self] result in
                guard let self, self.generation == id else { return }
                do { self.advancedView = MeshPreview(try result.get()); self.showContent(self.advancedView!); self.status.stringValue = url.lastPathComponent + " · " + L10n.text("3D 只读预览"); self.finish(nil) }
                catch { self.showMessage(error.localizedDescription); self.status.stringValue = L10n.text("预览未完成 · 可重载或选择其他文件"); self.finish(error) }
            }); return true
        }
        if ScientificDocument.supports(url) {
            mode.isEnabled = false
            PreviewWorkQueue.parsing.submit(cancellation:token,work:{try ScientificDocument.load(url,root:root,cancellation:token)},completion:{ [weak self] result in
                guard let self, self.generation == id else { return }
                do { let value = try result.get().0; self.advancedView = ScientificPreview(value); self.showContent(self.advancedView!); self.status.stringValue = url.lastPathComponent + " · " + L10n.text("只读结构与样本"); self.finish(nil) }
                catch { self.showMessage(error.localizedDescription); self.finish(error) }
            }); return true
        }
        if ext == "parquet" {
            mode.isEnabled = false
            PreviewWorkQueue.parsing.submit(cancellation:token,work:{ () -> Data in
                var limits = PreviewLimits(); limits.fileBytes = 25 * 1024 * 1024
                let data = try AccessBroker.readBytes(url,root:root,limits:limits,cancellation:token).data
                _ = try ParquetHeader.parse(data,cancellation:token); return data
            },completion:{ [weak self] result in
                guard let self, self.generation == id else { return }
                do {
                    let data = try result.get(), renderer = RichContentRenderer(resourceName:"ParquetRenderer"); self.richRenderer = renderer
                    self.richTask = Task { @MainActor [weak self] in
                        guard let self else { return }; defer { renderer.cancel() }
                        do { let document = try await renderer.readParquet(data,in:self.view); guard self.generation == id else { return }; self.advancedView = ScientificPreview(document); self.showContent(self.advancedView!); self.status.stringValue = url.lastPathComponent + " · " + L10n.text("Parquet 前 500 行"); self.finish(nil) }
                        catch { guard self.generation == id else { return }; self.showMessage(error.localizedDescription); self.finish(error) }
                        if self.generation == id { self.richTask = nil; self.richRenderer = nil }
                    }
                } catch { self.showMessage(error.localizedDescription); self.finish(error) }
            }); return true
        }
        guard ["jsx","tsx","mdx","tex","typ","drawio","canvas"].contains(ext) else { return false }
        mode.isEnabled = false
        PreviewWorkQueue.parsing.submit(cancellation:token,work:{ () -> (SourceSnapshot,Result<DiagramDocument?,Error>) in
            let snapshot = try AccessBroker.read(url,root:root,cancellation:token)
            let graph = Result { ["drawio","canvas"].contains(ext) ? try DiagramDocument.parseIfKnown(snapshot.text,name:url.lastPathComponent,cancellation:token)?.resolvingCards(document:url,root:root,cancellation:token) : nil }
            return (snapshot,graph)
        },completion:{ [weak self] result in
            guard let self, self.generation == id else { return }
            do {
                let (snapshot,parsedGraph) = try result.get(); self.source = snapshot; self.format = .code; self.mode.selectedSegment = 0
                if let graph = try parsedGraph.get() { self.advancedView = DiagramPreview(graph); self.present(); self.finish(nil); return }
                self.present()
                let renderer = RichContentRenderer(resourceName:ext == "tex" ? "LaTeXRenderer" : ext == "typ" ? "TypstCompiler" : "ComponentRenderer"); self.richRenderer = renderer
                self.richTask = Task { @MainActor [weak self] in
                    guard let self else { return }; defer { renderer.cancel() }
                    do {
                        if ext == "tex" || ext == "typ" {
                            let data = try await renderer.compileDocument(snapshot.text,typst:ext == "typ",in:self.view)
                            guard self.generation == id else { return }
                            guard let document = PDFDocument(data:data), document.pageCount <= 200 else { throw PreviewError.malformed("Compiled PDF") }
                            self.pdf.document = document; self.advancedView = self.pdf
                            self.parseWarning = ext == "tex" ? L10n.text("LaTeX 基础排版；外部宏包与文件不加载") : L10n.text("Typst 离线单文件编译；外部文件与包不加载")
                        } else {
                            guard snapshot.text.utf8.count <= 65536 else { throw PreviewError.limit("Component 64 KiB") }
                            let image = try await renderer.renderSource(snapshot.text,kind:ext == "mdx" ? "mdx" : "react",in:self.view)
                            guard self.generation == id else { return }; self.canvasImage = image; self.canvasLabel = ext.uppercased()
                            self.parseWarning = L10n.text("离线组件快照；仅内置 React，外部依赖与网络不可用")
                        }
                    } catch { guard self.generation == id else { return }; self.parseWarning = error.localizedDescription + L10n.text(" · 已降级源码") }
                    guard self.generation == id else { return }; self.present(); self.finish(nil); self.richTask = nil; self.richRenderer = nil
                }
            } catch {
                // Always preserve readable source for invalid structured text.
                if self.source != nil { self.format = .code; self.parseWarning = error.localizedDescription + L10n.text(" · 已降级源码"); self.present(); self.finish(nil) }
                else { self.showMessage(error.localizedDescription); self.finish(error) }
            }
        }); return true
    }
}
