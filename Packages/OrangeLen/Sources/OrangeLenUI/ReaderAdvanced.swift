import AppKit
import PDFKit
import OrangeLenCore

extension ReaderController {
    func loadAdvanced(_ url: URL, root: URL?, id: UUID, token: Cancellation) -> Bool {
        let ext = url.pathExtension.lowercased()
        if ext == "onnx" {
            mode.isEnabled = false
            PreviewWorkQueue.parsing.submit(cancellation: token, work: {
                try ONNXDocument.load(url, root: root, cancellation: token)
            }, completion: { [weak self] result in
                guard let self, self.generation == id else { return }
                do { let document = try result.get(); self.advancedView = ScientificPreview(document); self.showContent(self.advancedView!); self.status.stringValue = "ONNX · metadata only"; self.finish(nil) }
                catch { self.showMessage(error.localizedDescription); self.status.stringValue = "ONNX · Preview unavailable"; self.finish(error) }
            })
            return true
        }
        if ["xmind", "mmap"].contains(ext) {
            mode.isEnabled = false
            PreviewWorkQueue.parsing.submit(cancellation: token, work: {
                try ext == "mmap" ? MindManagerDocument.load(url, root: root, cancellation: token) : XMindDocument.load(url, root: root, cancellation: token)
            }, completion: { [weak self] result in
                guard let self, self.generation == id else { return }
                do {
                    self.advancedView = DiagramPreview(try result.get())
                    self.showContent(self.advancedView!)
                    self.status.stringValue = url.lastPathComponent + (ext == "mmap" ? " · MindManager" : " · XMind")
                    self.finish(nil)
                } catch { self.showMessage(error.localizedDescription); self.finish(error) }
            })
            return true
        }
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
        if ["parquet", "arrow", "ipc", "feather"].contains(ext) {
            mode.isEnabled = false
            PreviewWorkQueue.parsing.submit(cancellation:token,work:{ () -> Data in
                var limits = PreviewLimits(); limits.fileBytes = 25 * 1024 * 1024
                let data = try AccessBroker.readBytes(url,root:root,limits:limits,cancellation:token).data
                if ext != "parquet", data.starts(with: Data("FEA1".utf8)) {
                    throw PreviewError.malformed("Feather V1 is not supported. Export Feather V2 / Arrow IPC to preview.")
                }
                if ext == "parquet" { _ = try ParquetHeader.parse(data,cancellation:token) }; return data
            },completion:{ [weak self] result in
                guard let self, self.generation == id else { return }
                do {
                    let data = try result.get(), renderer = RichContentRenderer(resourceName:ext == "parquet" ? "ParquetRenderer" : "ArrowRenderer"); self.richRenderer = renderer
                    self.richTask = Task { @MainActor [weak self] in
                        guard let self else { return }; defer { renderer.cancel() }
                        do { let document: ScientificDocument
                            if ext == "parquet" { document = try await renderer.readParquet(data,in:self.view) } else { document = try await renderer.readArrow(data,in:self.view) }; guard self.generation == id else { return }; self.advancedView = ScientificPreview(document); self.showContent(self.advancedView!); self.status.stringValue = url.lastPathComponent + " · " + (ext == "parquet" ? L10n.text("Parquet 前 500 行") : "Arrow IPC / Feather · first 500 rows"); self.finish(nil) }
                        catch { guard self.generation == id else { return }; self.showMessage(error.localizedDescription); self.status.stringValue = url.lastPathComponent + " · Preview unavailable"; self.finish(error) }
                        if self.generation == id { self.richTask = nil; self.richRenderer = nil }
                    }
                } catch { self.showMessage(error.localizedDescription); self.status.stringValue = url.lastPathComponent + " · Preview unavailable"; self.finish(error) }
            }); return true
        }
        guard ["dot","gv","jsx","tsx","mdx","tex","typ","drawio","canvas","mm","opml"].contains(ext) else { return false }
        mode.isEnabled = false
        PreviewWorkQueue.parsing.submit(cancellation:token,work:{ () -> (SourceSnapshot,Result<DiagramDocument?,Error>) in
            let snapshot = try AccessBroker.read(url,root:root,cancellation:token)
            let graph = Result { ["drawio","canvas","mm","opml"].contains(ext) ? try DiagramDocument.parseIfKnown(snapshot.text,name:url.lastPathComponent,cancellation:token)?.resolvingCards(document:url,root:root,cancellation:token) : nil }
            return (snapshot,graph)
        },completion:{ [weak self] result in
            guard let self, self.generation == id else { return }
            do {
                let (snapshot,parsedGraph) = try result.get(); self.source = snapshot; self.format = .code; self.mode.selectedSegment = 0
                if let graph = try parsedGraph.get() { self.advancedView = DiagramPreview(graph); self.present(); self.finish(nil); return }
                self.present()
                if ext == "typ", SourceCodeFormats.isSQLTypeDefinition(snapshot.text) { self.finish(nil); return }
                if ["mm", "opml"].contains(ext) { self.finish(nil); return }
                let renderer = RichContentRenderer(resourceName:["dot","gv"].contains(ext) ? "DotRenderer" : ext == "tex" ? "LaTeXRenderer" : ext == "typ" ? "TypstCompiler" : "ComponentRenderer"); self.richRenderer = renderer
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
                            let image = try await renderer.renderSource(snapshot.text,kind:["dot","gv"].contains(ext) ? "dot" : ext == "mdx" ? "mdx" : "react",in:self.view)
                            guard self.generation == id else { return }; self.canvasImage = image; self.canvasLabel = ext.uppercased()
                            self.parseWarning = ["dot","gv"].contains(ext) ? "Graphviz DOT · offline snapshot; external images unavailable" : L10n.text("离线组件快照；仅内置 React，外部依赖与网络不可用")
                        }
                    } catch { guard self.generation == id else { return }; self.parseWarning = error.localizedDescription + L10n.text(" · 已降级源码") }
                    guard self.generation == id else { return }; self.present(); self.finish(nil); self.richTask = nil; self.richRenderer = nil
                }
            } catch {
                // macOS also assigns .dot to legacy Word templates.
                if ext == "dot", self.source == nil,
                   let failure = error as? PreviewError {
                    switch failure {
                    case .binary, .encoding: self.loadSystemPreview(url, root: root); return
                    default: break
                    }
                }
                // Always preserve readable source for invalid structured text.
                if self.source != nil { self.format = .code; self.parseWarning = error.localizedDescription + L10n.text(" · 已降级源码"); self.present(); self.finish(nil) }
                else { self.showMessage(error.localizedDescription); self.finish(error) }
            }
        }); return true
    }
}
