import AppKit
import WebKit
import OrangeLenCore

private final class HTMLSnapshotImageView: NSImageView {
    override var isFlipped: Bool { true }
}

/// Browser rendering in a nonpersistent WebKit session. Real files retain their base
/// URL for relative resources; the caller supplies the currently authorized read root.
final class HTMLPreview: NSView, WKNavigationDelegate {
    let webView: WKWebView
    var onFailure: (() -> Void)?
    private var awaitingInitialDocument = true
    private let documentURL: URL?
    private var scopedURLs: [URL] = []
    private var refreshTimer: Timer?
    private var snapshotInProgress = false
    private var contentRevision: Int = -1
    private var checkingRevision = false
    private var presented = true
    private var timeout: DispatchWorkItem?
    // Quick Look hosts an out-of-process view: WebKit's remote layer can be blank
    // there. Use a bounded native snapshot, as with the other rich renderers.
    private let usesSnapshot: Bool
    private let pageScroll = NSScrollView()
    private let pageImage = HTMLSnapshotImageView()
    var snapshotImage: NSImage? { pageImage.image }
    private var loaded = false
    private var renderedWidth: CGFloat = 0
    private var snapshotTask: Task<Void, Never>?
    private var snapshotRequest = UUID()
    var onTruncation: (() -> Void)?

    static func supports(_ url: URL?) -> Bool {
        ["html", "htm", "xhtml"].contains(url?.pathExtension.lowercased() ?? "")
    }

    init(source: String, documentURL: URL? = nil, readAccessURL: URL? = nil, usesSnapshot: Bool = Bundle.main.bundleURL.pathExtension == "appex") {
        self.documentURL = documentURL
        self.usesSnapshot = usesSnapshot
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        // Observation runs in an isolated world. Page scripts have no native message
        // bridge. Poll just the revision once per second while a Finder preview is shown.
        if usesSnapshot {
            let observer = WKUserScript(source: """
                window.orangeRevision = 0;
                const changed = () => { window.orangeRevision++; };
                new MutationObserver(changed).observe(document, {subtree:true, childList:true, attributes:true, characterData:true});
                document.addEventListener('load', changed, true);
                document.fonts.ready.then(changed);
                """, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: .defaultClient)
            configuration.userContentController.addUserScript(observer)
        }
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(frame: .zero)
        webView.navigationDelegate = self
        webView.setAccessibilityLabel(L10n.text("HTML 页面效果"))
        addSubview(webView)
        let surface: NSView
        if usesSnapshot {
            pageScroll.hasVerticalScroller = true; pageScroll.autohidesScrollers = true
            pageImage.imageScaling = .scaleNone; pageImage.setAccessibilityLabel(L10n.text("HTML 页面效果"))
            pageScroll.documentView = pageImage; addSubview(pageScroll)
            surface = pageScroll
            webView.frame = NSRect(x: -10000, y: 0, width: 760, height: 600)
        } else { surface = webView }
        surface.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            surface.leadingAnchor.constraint(equalTo: leadingAnchor), surface.trailingAnchor.constraint(equalTo: trailingAnchor),
            surface.topAnchor.constraint(equalTo: topAnchor), surface.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        if let documentURL {
            for url in Set([documentURL, readAccessURL ?? documentURL]) where url.startAccessingSecurityScopedResource() { scopedURLs.append(url) }
            webView.loadFileURL(documentURL, allowingReadAccessTo: readAccessURL ?? documentURL)
        } else {
            webView.loadHTMLString(source, baseURL: nil)
        }
        let timeout = DispatchWorkItem { [weak self] in self?.onFailure?() }
        self.timeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: timeout)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = action.request.url
        // Subresources use normal WebKit loading, CORS and the document's own CSP.
        // Do not turn a file preview into an arbitrary top-level browser session.
        if action.targetFrame?.isMainFrame == false {
            decisionHandler(["https", "http", "about", "data", "blob"].contains(url?.scheme ?? "") ? .allow : .cancel)
            return
        }
        let initialURL = documentURL?.absoluteString ?? "about:blank"
        let initial = awaitingInitialDocument && action.navigationType == .other && url?.absoluteString == initialURL && action.targetFrame?.isMainFrame == true
        if initial { awaitingInitialDocument = false }
        let fragment = url?.fragment != nil && url?.absoluteString.components(separatedBy: "#").first == initialURL.components(separatedBy: "#").first
        decisionHandler(initial || fragment ? .allow : .cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaded = true
        if usesSnapshot {
            refreshSnapshot()
            refreshTimer?.invalidate()
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.checkForPageChanges() }
        } else { timeout?.cancel(); timeout = nil }
    }

    func setPresented(_ value: Bool) {
        presented = value
        if value { checkForPageChanges() }
    }

    private func checkForPageChanges() {
        guard usesSnapshot, loaded, presented, !snapshotInProgress, !checkingRevision else { return }
        checkingRevision = true
        webView.evaluateJavaScript("window.orangeRevision || 0", in: nil, in: .defaultClient) { [weak self] result in
            guard let self else { return }
            self.checkingRevision = false
            guard self.presented, !self.snapshotInProgress,
                  case .success(let value) = result, let revision = value as? Int,
                  revision != self.contentRevision else { return }
            self.contentRevision = revision; self.refreshSnapshot()
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        if loaded { refreshSnapshot() }
    }

    override func layout() {
        super.layout()
        if usesSnapshot, loaded, abs(pageScroll.contentSize.width - renderedWidth) > 2 { refreshSnapshot() }
    }

    func refreshSnapshot() {
        guard usesSnapshot, loaded, presented, pageScroll.contentSize.width > 0 else { return }
        snapshotTask?.cancel()
        let request = UUID(); snapshotRequest = request; snapshotInProgress = true
        let width = min(2000, max(100, pageScroll.contentSize.width)); renderedWidth = pageScroll.contentSize.width
        snapshotTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { if self.snapshotRequest == request { self.snapshotInProgress = false } }
            do {
                try await Task.sleep(nanoseconds: 120_000_000)
                self.webView.frame = NSRect(x: -10000, y: 0, width: width, height: 600)
                let measured: Double = try await withCheckedThrowingContinuation { continuation in
                    self.webView.evaluateJavaScript("Math.max(document.body?.scrollHeight || 0, document.documentElement.scrollHeight)", in: nil, in: .defaultClient) { result in
                        continuation.resume(with: result.map { ($0 as? NSNumber)?.doubleValue ?? 600 })
                    }
                }
                try Task.checkCancellation()
                guard self.snapshotRequest == request else { return }
                let height = min(8000, max(600, measured))
                self.webView.setFrameSize(NSSize(width: width, height: height))
                let config = WKSnapshotConfiguration()
                config.rect = NSRect(x: 0, y: 0, width: width, height: height)
                config.snapshotWidth = NSNumber(value: Double(width) * min(2, sqrt(8_000_000 / (Double(width) * height))))
                let image = try await self.webView.takeSnapshot(configuration: config)
                try Task.checkCancellation()
                guard self.snapshotRequest == request else { return }
                image.size = NSSize(width: width, height: height)
                self.pageImage.image = image; self.pageImage.setFrameSize(image.size)
                self.timeout?.cancel(); self.timeout = nil
                if measured > 8000 { self.onTruncation?() }
            } catch is CancellationError { }
            catch { if self.snapshotRequest == request { self.onFailure?() } }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { onFailure?() }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { onFailure?() }
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { onFailure?() }
    func cancel() { loaded = false; presented = false; refreshTimer?.invalidate(); refreshTimer = nil; scopedURLs.forEach { $0.stopAccessingSecurityScopedResource() }; scopedURLs = []; snapshotRequest = UUID(); snapshotTask?.cancel(); snapshotTask = nil; timeout?.cancel(); timeout = nil; onFailure = nil; onTruncation = nil; webView.stopLoading(); webView.navigationDelegate = nil; removeFromSuperview() }
}


extension ReaderController {
    @objc func openHTMLInBrowser() {
        guard !virtualDocument, let url = currentURL, HTMLPreview.supports(url),
              let browser = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!) else { return }
        NSWorkspace.shared.open([url], withApplicationAt: browser, configuration: .init()) { [weak self] _, error in
            if error != nil { DispatchQueue.main.async { self?.showCopyNotice(L10n.text("无法打开链接")) } }
        }
    }

    func prepareHTMLPreview(url: URL?, snapshot: SourceSnapshot) {
        guard HTMLPreview.supports(url), !snapshot.partial, snapshot.byteCount <= 1024 * 1024 else { return }
        let id = generation
        let fileURL = virtualDocument ? nil : url
        let authorizedRoot = imageRootURL ?? rootURL
        let readRoot = authorizedRoot.flatMap { root in
            fileURL?.standardizedFileURL.pathComponents.starts(with: root.standardizedFileURL.pathComponents) == true ? root : nil
        }
        let preview = HTMLPreview(source: snapshot.text, documentURL: fileURL, readAccessURL: readRoot)
        htmlPreview = preview
        preview.onTruncation = { [weak self, weak preview] in
            guard let self, self.generation == id, self.htmlPreview === preview else { return }
            self.parseWarning = L10n.text("页面过长，仅显示前 8000 点；源码完整保留")
            self.present()
        }
        preview.onFailure = { [weak self, weak preview] in
            guard let self, self.generation == id, self.htmlPreview === preview else { return }
            self.htmlPreview?.cancel(); self.htmlPreview = nil
            self.parseWarning = L10n.text("HTML 效果载入失败，已显示源码")
            self.mode.selectedSegment = 1; self.present()
        }
    }
}
