import AppKit
import WebKit
import OrangeLenCore

// This private, ephemeral WebKit surface only runs the bundled renderer. Document
// data is passed as a structured argument, never interpolated into executable HTML.
// The user reads native TextKit attachments; this view is never the preview UI.
@MainActor final class RichContentRenderer: NSObject, WKNavigationDelegate {
    private let resourceName: String
    init(resourceName: String = "RichRenderer") { self.resourceName = resourceName; super.init() }
    private let embedded = EmbeddedResourceHandler()
    private var web: WKWebView?
    private var ready: CheckedContinuation<Void, Error>?
    private var evaluation: CheckedContinuation<Any?, Error>?
    private var snapshotResult: CheckedContinuation<NSImage, Error>?
    private var stopped = false
    private var deadline: Task<Void, Never>?
    private var budget: Task<Void, Never>?
    func cancel() {
        stopped = true; embedded.input = nil; deadline?.cancel(); budget?.cancel()
        ready?.resume(throwing: CancellationError()); ready = nil
        evaluation?.resume(throwing: CancellationError()); evaluation = nil
        snapshotResult?.resume(throwing: CancellationError()); snapshotResult = nil
        web?.stopLoading(); web?.removeFromSuperview(); web = nil
    }
    private func boot(in parent: NSView) async throws {
        guard web == nil else { return }
        guard !stopped else { throw CancellationError() }
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.setURLSchemeHandler(embedded,forURLScheme:"orangelen-resource")
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        // Embedded KaTeX/LaTeX fonts are data URLs in the bundled HTML. Keep
        // external/file URLs blocked while retaining those offline font faces.
        let rules = #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}},{"trigger":{"url-filter":"^orangelen-resource:"},"action":{"type":"ignore-previous-rules"}},{"trigger":{"url-filter":"^data:font/"},"action":{"type":"ignore-previous-rules"}}]"#
        let list = try await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "OrangeLenOfflineRenderer-v1", encodedContentRuleList: rules)
        if let list { config.userContentController.add(list) }
        try Task.checkCancellation(); guard !stopped else { throw CancellationError() }
        let web = WKWebView(frame: NSRect(x: -2000, y: -2000, width: 820, height: 1550), configuration: config)
        self.web = web; web.navigationDelegate = self
        // Keep attached for reliable macOS layout/snapshots, outside the visible clip.
        parent.addSubview(web)
        guard let url = UIResources.url(forResource: resourceName, withExtension: "html") else { throw PreviewError.malformed(L10n.text("缺少离线渲染资源")) }
        let html = try String(contentsOf: url, encoding: .utf8)
        try await withCheckedThrowingContinuation { continuation in
            ready = continuation
            deadline = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                guard !Task.isCancelled else { return }; self?.cancel()
            }
            web.loadHTMLString(html, baseURL: nil)
        }
    }
    func render(_ item: MarkdownRichContent, in parent: NSView) async throws -> NSImage {
        guard item.content.utf8.count <= 16_384 else { throw PreviewError.limit(L10n.text("公式/图表最多 16 KiB")) }
        return try await renderSource(item.content, kind: item.kind.rawValue, in: parent)
    }
    func renderExcalidraw(_ scene: ExcalidrawPreview, in parent: NSView) async throws -> NSImage {
        try await renderSource(scene.json, kind: "excalidraw", in: parent)
    }
    func renderSVG(_ document: SVGDocument, in parent: NSView) async throws -> NSImage {
        try await renderSource(document.xml, kind: "svg", in: parent)
    }
    func readParquet(_ data: Data, in parent: NSView) async throws -> ScientificDocument {
        let header = try ParquetHeader.parse(data)
        try await boot(in: parent)
        guard let web, !stopped, let url = UIResources.url(forResource: "parquet", withExtension: "wasm") else { throw PreviewError.unavailable }
        _ = url; embedded.input = data
        budget = Task { [weak self] in try? await Task.sleep(nanoseconds:10_000_000_000); if !Task.isCancelled { self?.cancel() } }
        defer { budget?.cancel() }
        let result: Any? = try await withCheckedThrowingContinuation { continuation in
            evaluation = continuation
            web.callAsyncJavaScript("return await window.orangeParquet(wasm, bytes)", arguments:["wasm":"orangelen-resource://assets/parquet.wasm","bytes":"orangelen-resource://assets/input.parquet"], in:nil,in:.page) { [weak self] result in
                self?.evaluation?.resume(with:result.map { Optional($0) }); self?.evaluation = nil
            }
        }
        try Task.checkCancellation()
        guard !stopped, let object = result as? [String:Any], let columns = object["columns"] as? [String], columns.count <= 256, let rows = object["rows"] as? [[String]], rows.count <= 500,
              rows.allSatisfy({ $0.count <= 256 && $0.allSatisfy({ $0.utf8.count <= 65536 }) }) else { throw PreviewError.limit("Parquet result") }
        return .init(title:"Parquet",summary:"\(header.rows) rows · \(header.rowGroups) row groups · \(header.columns) columns\nSample: first \(rows.count) rows (maximum 500) · read-only, offline Arrow decoder",columns:columns,rows:rows)
    }
    func readArrow(_ data: Data, in parent: NSView) async throws -> ScientificDocument {
        try await boot(in: parent)
        guard let web, !stopped else { throw PreviewError.unavailable }
        embedded.input = data
        budget = Task { [weak self] in try? await Task.sleep(nanoseconds:10_000_000_000); if !Task.isCancelled { self?.cancel() } }
        defer { budget?.cancel() }
        let result: Any? = try await withCheckedThrowingContinuation { continuation in
            evaluation = continuation
            web.callAsyncJavaScript("return await window.orangeArrow(bytes)", arguments:["wasm":"orangelen-resource://assets/parquet.wasm","bytes":"orangelen-resource://assets/input.parquet"], in:nil,in:.page) { [weak self] result in
                self?.evaluation?.resume(with:result.map { Optional($0) }); self?.evaluation = nil
            }
        }
        try Task.checkCancellation()
        guard !stopped, let object = result as? [String:Any], let columns = object["columns"] as? [String], columns.count <= 256, let rows = object["rows"] as? [[String]], rows.count <= 500,
              rows.allSatisfy({ $0.count <= 256 && $0.allSatisfy({ $0.utf8.count <= 65536 }) }) else { throw PreviewError.limit("Arrow result") }
        return .init(title:"Arrow",summary:object["summary"] as? String ?? "Arrow IPC",columns:columns,rows:rows)
    }
    func compileDocument(_ source: String, typst: Bool, in parent: NSView) async throws -> Data {
        guard source.utf8.count <= 65536 else { throw PreviewError.limit("Typesetting source 64 KiB") }
        try await boot(in:parent)
        guard let web, !stopped else { throw CancellationError() }
        budget = Task { [weak self] in try? await Task.sleep(nanoseconds:15_000_000_000); if !Task.isCancelled { self?.cancel() } }
        defer { budget?.cancel() }
        var arguments: [String:Any] = ["source":source]
        let script: String
        if typst {
            guard let wasmURL = UIResources.url(forResource:"typst",withExtension:"wasm") else { throw PreviewError.unavailable }
            _ = wasmURL; arguments["wasm"] = "orangelen-resource://assets/typst.wasm"
            arguments["fonts"] = try ["LibertinusSerif-Regular", "NewCMMath-Book", "NotoSerifCJKsc-Regular"].map { name -> String in
                guard let url = UIResources.url(forResource:name,withExtension:"otf") else { throw PreviewError.unavailable }; _ = url; return "orangelen-resource://assets/" + name + ".otf"
            }
            script = "return await window.orangeTypst(wasm,fonts,source)"
        } else { script = "return await window.orangeRender('tex',source)" }
        let result: Any? = try await withCheckedThrowingContinuation { continuation in
            evaluation = continuation
            web.callAsyncJavaScript(script,arguments:arguments,in:nil,in:.page) { [weak self] result in
                self?.evaluation?.resume(with:result.map {Optional($0)}); self?.evaluation = nil
            }
        }
        try Task.checkCancellation(); guard !stopped else { throw CancellationError() }
        let data: Data
        if typst {
            guard let value = result as? String, value.utf8.count <= 36 * 1024 * 1024, let decoded = Data(base64Encoded:value) else { throw PreviewError.malformed("Typst PDF result") }; data = decoded
        } else {
            guard let size = result as? [String:NSNumber], let height = size["height"]?.doubleValue, height.isFinite, height > 0, height <= 20000 else { throw PreviewError.limit("LaTeX HTML height 20,000 pt") }
            web.setFrameSize(NSSize(width:800,height:height))
            let config = WKPDFConfiguration(); config.rect = NSRect(x:0,y:0,width:780,height:height)
            data = try await web.pdf(configuration:config)
        }
        guard data.count <= 25 * 1024 * 1024 else { throw PreviewError.limit("Compiled PDF 25 MiB") }; return data
    }
    func renderSource(_ source: String, kind: String, in parent: NSView) async throws -> NSImage {
        try await boot(in: parent)
        try Task.checkCancellation()
        guard let web, !stopped else { throw CancellationError() }
        budget = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }; self?.cancel()
        }
        defer { budget?.cancel() }
        let value: Any? = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any?, Error>) in
            evaluation = continuation
            web.callAsyncJavaScript("return await window.orangeRender(kind, source)", arguments: ["kind": kind, "source": source], in: nil, in: .page) { [weak self] result in
                guard let self else { return }
                self.evaluation?.resume(with: result.map { Optional($0) }); self.evaluation = nil
            }
        }
        try Task.checkCancellation(); guard !stopped else { throw CancellationError() }
        guard let size = value as? [String: NSNumber], let width = size["width"]?.doubleValue, let height = size["height"]?.doubleValue,
              width > 0, width <= 800, height > 0, height <= 1500 else { throw PreviewError.limit(L10n.text("公式/图表尺寸")) }
        let snapshot = WKSnapshotConfiguration()
        snapshot.rect = NSRect(x: size["x"]?.doubleValue ?? 0, y: size["y"]?.doubleValue ?? 0, width: width, height: height)
        snapshot.snapshotWidth = NSNumber(value: width * 2)
        let image: NSImage = try await withCheckedThrowingContinuation { continuation in
            snapshotResult = continuation
            web.takeSnapshot(with: snapshot) { [weak self] image, error in
                guard let self else { return }
                if let image { self.snapshotResult?.resume(returning: image) }
                else { self.snapshotResult?.resume(throwing: error ?? PreviewError.malformed(L10n.text("无法生成图像"))) }
                self.snapshotResult = nil
            }
        }
        try Task.checkCancellation(); guard !stopped else { throw CancellationError() }
        image.size = NSSize(width: width, height: height)
        return image
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        deadline?.cancel(); ready?.resume(); ready = nil
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        deadline?.cancel(); ready?.resume(throwing: error); ready = nil
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { self.webView(webView, didFail: navigation, withError: error) }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { cancel() }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(navigationAction.request.url?.absoluteString == "about:blank" ? .allow : .cancel)
    }
}
