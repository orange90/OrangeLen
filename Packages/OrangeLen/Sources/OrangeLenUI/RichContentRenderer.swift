import AppKit
import WebKit
import OrangeLenCore

// This private, ephemeral WebKit surface only runs the bundled renderer. Document
// data is passed as a structured argument, never interpolated into executable HTML.
// The user reads native TextKit attachments; this view is never the preview UI.
@MainActor final class RichContentRenderer: NSObject, WKNavigationDelegate {
    private let resourceName: String
    init(resourceName: String = "RichRenderer") { self.resourceName = resourceName; super.init() }
    private var web: WKWebView?
    private var ready: CheckedContinuation<Void, Error>?
    private var evaluation: CheckedContinuation<Any?, Error>?
    private var snapshotResult: CheckedContinuation<NSImage, Error>?
    private var stopped = false
    private var deadline: Task<Void, Never>?
    private var budget: Task<Void, Never>?
    func cancel() {
        stopped = true; deadline?.cancel(); budget?.cancel()
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
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        let rules = #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}}]"#
        let list = try await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "OrangeLenOfflineRenderer-v1", encodedContentRuleList: rules)
        if let list { config.userContentController.add(list) }
        try Task.checkCancellation(); guard !stopped else { throw CancellationError() }
        let web = WKWebView(frame: NSRect(x: -2000, y: -2000, width: 820, height: 1550), configuration: config)
        self.web = web; web.navigationDelegate = self
        // Keep attached for reliable macOS layout/snapshots, outside the visible clip.
        parent.addSubview(web)
        guard let url = Bundle.module.url(forResource: resourceName, withExtension: "html") else { throw PreviewError.malformed(L10n.text("缺少离线渲染资源")) }
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
    private func renderSource(_ source: String, kind: String, in parent: NSView) async throws -> NSImage {
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
