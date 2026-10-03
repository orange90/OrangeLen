import AppKit
import OrangeLenCore
import os

public final class ReaderController: NSViewController, NSSearchFieldDelegate, NSTextViewDelegate {
    let copyNotice = NSStackView()
    let copyNoticeLabel = NSTextField(labelWithString: "")
    var hideCopyNotice: DispatchWorkItem?
    let text = ReadingTextView()
    let scroll = NSScrollView()
    let picture = NSImageView()
    let folderInfo = NSTextField(wrappingLabelWithString: "")
    let search = FocusSearchField()
    let caseButton = NSButton(checkboxWithTitle: "Aa", target: nil, action: nil)
    let resultLabel = NSTextField(labelWithString: "")
    let status = NSTextField(wrappingLabelWithString: "OrangeLen · Quick Look for Developers\n使用 ⌘O 选择文件或文件夹。应用内预览是补充入口，Finder 支持请查看验证记录。")
    let mode = NSSegmentedControl(labels: ["阅读", "源码"], trackingMode: .selectOne, target: nil, action: nil)
    let focus = NSButton(checkboxWithTitle: "专注", target: nil, action: nil)
    let ruler = NSPopUpButton()
    let headings = NSPopUpButton()
    let lineField = NSTextField()
    let split = NSSplitView()
    let body = NSView()
    let folder = FolderController()
    let json = JSONController()
    let table = TableController()
    var lineRuler: LineRuler!
    var settings = SettingsStore.shared.load()
    var source: SourceSnapshot?
    var markdownAssets = MarkdownAssets()
    var richTask: Task<Void, Never>?
    var richRenderer: RichContentRenderer?
    var remoteTask: Task<Void, Never>?
    var remoteLoader: RemoteImageRequest?
    var remoteAttempts = 0
    var remoteBytes = 0
    let remoteBar = NSStackView()
    let remoteButton = NSButton(title: "加载远程图片", target: nil, action: nil)
    let remoteStatus = NSTextField(labelWithString: "远程图片尚未加载")
    var remoteHeight: NSLayoutConstraint!
    var renderedWidth: CGFloat = 0
    var rendered: TextModel?
    var jsonTree: JSONTree?
    var tableData: TableData?
    var parseWarning = ""
    var format: PreviewFormat = .text
    var currentURL: URL?
    var rootURL: URL?
    var rootScope = false
    var generation = UUID()
    var cancellation: Cancellation?
    var completion: ((Error?) -> Void)?
    var matches: [NSRange] = []
    var matchIndex = -1
    var currentContent: NSView?
    var settingsTimer: Timer?
    var headingOffsets: [Int] = []
    let logger = Logger(subsystem: "local.OrangeLen", category: "Reader")
    var optionsMenu = NSPopUpButton()
    public override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 720))
        root.autoresizingMask = [.width, .height]
        let bar = NSStackView(); bar.orientation = .horizontal; bar.spacing = 6
        mode.selectedSegment = 0; mode.target = self; mode.action = #selector(toggleSource)
        headings.target = self; headings.action = #selector(jumpHeading); headings.addItem(withTitle: "目录")
        focus.target = self; focus.action = #selector(changeFocus)
        ruler.addItems(withTitles: ["无阅读尺", "1 行尺", "3 行尺", "5 行尺"]); ruler.target = self; ruler.action = #selector(changeRuler)
        optionsMenu.addItems(withTitles: ["显示设置", "切换行号", "切换代码换行", "切换当前句高亮", "切换正文变淡", "切换表头", "表格再加载 500 行", "跟随系统", "浅色", "深色"])
        optionsMenu.target = self; optionsMenu.action = #selector(optionChanged)
        for control in [mode, headings, focus, button("上一句", #selector(previousSentence)), button("下一句", #selector(nextSentence)), ruler, button("A−", #selector(smaller)), button("A+", #selector(larger)), optionsMenu, button("重载", #selector(reload))] { bar.addArrangedSubview(control) }
        let findbar = NSStackView(); findbar.orientation = .horizontal; findbar.spacing = 6
        search.placeholderString = Bundle.main.bundleURL.pathExtension == "appex" ? "查找已加载内容（点击输入）" : "查找已加载内容 ⌘F"; search.delegate = self; search.widthAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        caseButton.target = self; caseButton.action = #selector(searchChanged)
        lineField.placeholderString = "行号"; lineField.widthAnchor.constraint(equalToConstant: 65).isActive = true
        lineField.target = self; lineField.action = #selector(jumpLine)
        resultLabel.font = .systemFont(ofSize: 11)
        for control in [button("查找", #selector(focusSearch)), search, caseButton, button("↑", #selector(previousMatch)), button("↓", #selector(nextMatch)), resultLabel, lineField, button("定位", #selector(jumpLine)), button("全选", #selector(selectBody)), button("复制选择", #selector(copySelection)), button("取消加载", #selector(cancelLoad))] { findbar.addArrangedSubview(control) }
        addChild(folder); addChild(json); addChild(table)
        split.isVertical = true; split.dividerStyle = .thin
        split.addArrangedSubview(folder.view); split.addArrangedSubview(body)
        folder.view.isHidden = true
        folderInfo.font = .systemFont(ofSize: 12); folderInfo.textColor = .secondaryLabelColor
        folder.onSummary = { [weak self] in self?.folderInfo.stringValue = $0 }
        picture.setContentHuggingPriority(.defaultLow, for: .vertical); picture.setContentHuggingPriority(.defaultLow, for: .horizontal)
        picture.setContentCompressionResistancePriority(.defaultLow, for: .vertical); picture.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        picture.imageScaling = .scaleProportionallyUpOrDown; picture.setAccessibilityLabel("图片预览")
        folder.onSelect = { [weak self] url in self?.loadFile(url, completion: { _ in }) }
        scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true; scroll.autohidesScrollers = true
        text.delegate = self
        text.isEditable = false; text.isSelectable = true; text.isRichText = false
        text.isAutomaticLinkDetectionEnabled = false
        text.minSize = NSSize(width: 0, height: 0); text.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        text.isVerticallyResizable = true; text.isHorizontallyResizable = false; text.autoresizingMask = [.width]
        text.textContainerInset = NSSize(width: 22, height: 18)
        text.textContainer?.widthTracksTextView = true
        text.textContainer?.containerSize = NSSize(width: 800, height: CGFloat.greatestFiniteMagnitude)
        text.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        text.setAccessibilityLabel("OrangeLen 只读正文")
        text.findAction = { [weak self] in self?.view.window?.makeFirstResponder(self?.search) }
        text.anchorChanged = { [weak self] in self?.savePosition() }
        scroll.documentView = text
        lineRuler = LineRuler(scroll: scroll, text: text); scroll.verticalRulerView = lineRuler; scroll.hasVerticalRuler = true
        status.font = .systemFont(ofSize: 11); status.textColor = .secondaryLabelColor
        remoteButton.target = self; remoteButton.action = #selector(loadRemoteImages)
        remoteBar.orientation = .horizontal; remoteBar.spacing = 10
        remoteStatus.font = .systemFont(ofSize: 12); remoteStatus.textColor = .secondaryLabelColor
        remoteBar.addArrangedSubview(remoteButton); remoteBar.addArrangedSubview(remoteStatus)
        remoteHeight = remoteBar.heightAnchor.constraint(equalToConstant: 0); remoteHeight.isActive = true
        remoteBar.isHidden = true
        for child in [bar, findbar, remoteBar, split, folderInfo, status] { child.translatesAutoresizingMaskIntoConstraints = false; root.addSubview(child) }
        NSLayoutConstraint.activate([
            bar.heightAnchor.constraint(equalToConstant: 30), findbar.heightAnchor.constraint(equalToConstant: 28),
            bar.topAnchor.constraint(equalTo: root.topAnchor, constant: 8), bar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10), bar.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -10),
            findbar.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 8), findbar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10), findbar.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -10),
            remoteBar.topAnchor.constraint(equalTo: findbar.bottomAnchor, constant: 4), remoteBar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10), remoteBar.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -10),
            split.topAnchor.constraint(equalTo: remoteBar.bottomAnchor, constant: 4), split.leadingAnchor.constraint(equalTo: root.leadingAnchor), split.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            folderInfo.topAnchor.constraint(equalTo: split.bottomAnchor, constant: 6), folderInfo.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12), folderInfo.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12), status.topAnchor.constraint(equalTo: folderInfo.bottomAnchor, constant: 4), status.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12), status.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12), status.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -8), status.heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
        copyNotice.addArrangedSubview(copyNoticeLabel)
        copyNotice.edgeInsets = NSEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        copyNotice.wantsLayer = true; copyNotice.layer?.cornerRadius = 8
        copyNotice.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        copyNoticeLabel.font = .boldSystemFont(ofSize: 13); copyNoticeLabel.textColor = .white
        copyNotice.translatesAutoresizingMaskIntoConstraints = false; root.addSubview(copyNotice)
        NSLayoutConstraint.activate([copyNotice.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -18), copyNotice.topAnchor.constraint(equalTo: split.topAnchor, constant: 12)])
        copyNotice.isHidden = true
        let copied: (String) -> Void = { [weak self] in self?.showCopyNotice($0) }
        text.copyFeedback = copied; json.copyFeedback = copied; table.copyFeedback = copied
        view = root; showContent(scroll); applySettings()
    }
    func showCopyNotice(_ message: String) {
        hideCopyNotice?.cancel()
        copyNoticeLabel.stringValue = message; copyNotice.isHidden = false
        let pending = DispatchWorkItem { [weak self] in self?.copyNotice.isHidden = true }
        hideCopyNotice = pending
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: pending)
    }
    func clearCopyNotice() {
        hideCopyNotice?.cancel(); hideCopyNotice = nil; copyNotice.isHidden = true
    }
    public override func viewDidLayout() {
        super.viewDidLayout()
        guard currentContent === scroll else { return }
        scroll.tile()
        let wrap = (format == .markdown && mode.selectedSegment == 0) || settings.wrapCode
        let width = max(100, scroll.contentSize.width)
        if wrap && abs(text.frame.width - width) > 1 { text.setFrameSize(NSSize(width: width, height: max(text.frame.height, scroll.contentSize.height))) }
        text.textContainer?.widthTracksTextView = wrap
        if format == .markdown && mode.selectedSegment == 0 && (!text.model.images.isEmpty || !text.model.richContent.isEmpty) {
            let available = width - 44
            if abs(available - renderedWidth) > 2 {
                renderedWidth = available
                let selection = text.selectedRange()
                text.textStorage?.setAttributedString(TextStyler.attributed(text.model, markdown: true, settings: settings, focus: settings.focus, assets: markdownAssets, width: available))
                text.setSelectedRange(selection)
            }
        }
        text.needsDisplay = true; lineRuler.needsDisplay = true
    }
    func button(_ title: String, _ action: Selector) -> NSButton { let b = NSButton(title: title, target: self, action: action); b.bezelStyle = .rounded; return b }
    func showContent(_ child: NSView) {
        if currentContent === child { return }
        currentContent?.removeFromSuperview(); child.translatesAutoresizingMaskIntoConstraints = false; body.addSubview(child)
        NSLayoutConstraint.activate([child.leadingAnchor.constraint(equalTo: body.leadingAnchor), child.trailingAnchor.constraint(equalTo: body.trailingAnchor), child.topAnchor.constraint(equalTo: body.topAnchor), child.bottomAnchor.constraint(equalTo: body.bottomAnchor)])
        currentContent = child
    }
    public func open(_ url: URL, completion: @escaping (Error?) -> Void) {
        loadViewIfNeeded(); close(); rootURL = nil; folderInfo.stringValue = ""; picture.image = nil
        settingsTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let value = SettingsStore.shared.load()
            if value != self.settings { self.settings = value; self.present() }
        }
        rootScope = url.startAccessingSecurityScopedResource()
        let directory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        if directory {
            rootURL = url; folder.view.isHidden = false; split.setPosition(250, ofDividerAt: 0); folder.open(url)
            currentURL = nil; source = nil; rendered = nil; jsonTree = nil; tableData = nil; matches = []; text.sentences = []; text.focusEnabled = false; scroll.rulersVisible = false; text.model = .plain(""); text.string = "\(url.lastPathComponent)\n\n选择左侧文件，在同一窗口阅读。\n目录按需枚举；脚本与项目依赖不会执行。\nREADME、package.json、pyproject.toml 等可作为项目线索点开阅读。"; showContent(scroll)
            status.stringValue = "文件夹 · 仅已展开目录 · 子项权限以实际读取结果为准"
            completion(nil)
        } else {
            if rootScope { url.stopAccessingSecurityScopedResource(); rootScope = false }
            folder.view.isHidden = true; loadFile(url, completion: completion)
        }
    }
    func loadFile(_ url: URL, completion handler: @escaping (Error?) -> Void) {
        clearCopyNotice(); savePosition(); cancelPending()
        let id = UUID(); generation = id; let token = Cancellation(); cancellation = token; completion = handler
        remoteAttempts = 0; remoteBytes = 0; remoteStatus.stringValue = "远程图片尚未加载（点击后仅下载图片）"; remoteBar.isHidden = true; remoteHeight.constant = 0
        currentURL = url; source = nil; rendered = nil; markdownAssets = .init(); jsonTree = nil; tableData = nil; parseWarning = ""
        text.model = .plain(""); text.sentences = []; matches = []; text.anchor = 0; table.loaded = 500
        text.string = "正在读取…"; status.stringValue = "OrangeLen · 本地、只读 · 正在载入 \(url.lastPathComponent)"; showContent(scroll)
        let root = rootURL; let detected = PreviewFormat.detect(url); format = detected
        if ImagePreview.supports(url) {
            picture.image = nil; mode.isEnabled = false; headings.isEnabled = false
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let scoped = root?.startAccessingSecurityScopedResource() ?? false
                defer { if scoped { root?.stopAccessingSecurityScopedResource() } }
                let result = Result { try ImagePreview.load(url, root: root, cancellation: token) }
                DispatchQueue.main.async {
                    guard let self, self.generation == id else { return }
                    switch result {
                    case .success(let image):
                        self.picture.image = NSImage(cgImage: image.image, size: .zero)
                        self.picture.setAccessibilityLabel("图片预览：\(url.lastPathComponent)，\(image.width) × \(image.height) 像素")
                        self.showContent(self.picture)
                        self.status.stringValue = "\(url.lastPathComponent) · \(image.width) × \(image.height) 像素 · \(ByteCountFormatter.string(fromByteCount: Int64(image.bytes), countStyle: .file)) · 适合窗口（最长边解码至 2048 像素，动图显示首帧）"
                        self.finish(nil)
                    case .failure(let error):
                        self.text.string = error.localizedDescription
                        self.status.stringValue = "图片预览未完成 · 可重载或选择其他文件"; self.finish(error)
                    }
                }
            }
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Result { () -> (SourceSnapshot, TextModel?, JSONTree?, TableData?, String, MarkdownAssets) in
                let scoped = root?.startAccessingSecurityScopedResource() ?? false
                defer { if scoped { root?.stopAccessingSecurityScopedResource() } }
                let snapshot = try AccessBroker.read(url, root: root, cancellation: token)
                var assets = MarkdownAssets()
                var markdown: TextModel?; var tree: JSONTree?; var table: TableData?; var warning = ""
                do {
                    switch detected {
                    case .markdown:
                        markdown = try MarkdownModel.parse(snapshot.text, cancellation: token)
                        if let markdown { assets = try MarkdownAssets.load(markdown, document: url, root: root, cancellation: token) }
                    case .json: tree = try JSONParser.parse(snapshot.text, cancellation: token)
                    case .csv, .tsv: table = try CSVParser.parse(snapshot.text, separator: detected == .csv ? 44 : 9, cancellation: token)
                    default: break
                    }
                } catch is CancellationError { throw CancellationError() }
                catch { warning = error.localizedDescription + " · 已降级源码" }
                try token.check()
                return (snapshot, markdown, tree, table, warning, assets)
            }
            DispatchQueue.main.async {
                guard let self, self.generation == id else { return }
                switch result {
                case .success(let loaded):
                    self.source = loaded.0; self.rendered = loaded.1; self.jsonTree = loaded.2; self.tableData = loaded.3; self.parseWarning = loaded.4; self.markdownAssets = loaded.5
                    self.mode.selectedSegment = 0; self.present(); self.startRichRendering()
                    self.scroll.contentView.scroll(to: .zero); self.scroll.reflectScrolledClipView(self.scroll.contentView)
                    if let offset = SettingsStore.shared.restore(url, revision: loaded.0.revision) {
                        let display = self.text.model.displayOffset(forSource: offset); self.text.sentence(at: display)
                        self.text.scrollRangeToVisible(NSRange(location: min(display, self.text.string.utf16.count), length: 0))
                    }
                    self.logger.notice("loaded format=\(detected.rawValue, privacy: .public) bytes=\(loaded.0.byteCount, privacy: .public) folderChild=\(root != nil, privacy: .public)")
                    self.finish(nil)
                case .failure(let error):
                    self.text.string = error is CancellationError ? "已取消" : error.localizedDescription
                    self.status.stringValue = "预览未完成 · 可重载或选择其他文件"
                    self.logger.notice("load failed code=\((error as NSError).code, privacy: .public)"); self.finish(error)
                }
            }
        }
    }
    public func textView(_ textView: NSTextView, clickedOn cell: NSTextAttachmentCellProtocol, in cellFrame: NSRect, at charIndex: Int) {
        guard let image = rendered?.images.first(where: { $0.range.location == charIndex }), markdownAssets.images[charIndex] == nil,
              ["http", "https"].contains(URL(string: image.destination)?.scheme?.lowercased() ?? "") else { return }
        beginRemoteImages([image])
    }
    public func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        let target = (link as? String) ?? (link as? URL)?.absoluteString ?? ""
        if target.hasPrefix("orangelen-remote:"), let offset = Int(target.dropFirst("orangelen-remote:".count)), offset == charIndex,
           let image = rendered?.images.first(where: { $0.range.location == offset }) {
            beginRemoteImages([image]); return true
        }
        if target.hasPrefix("#") {
            let anchor = String(target.dropFirst()).removingPercentEncoding ?? String(target.dropFirst())
            if let block = text.model.blocks.first(where: { block in
                guard case .heading = block.kind else { return false }
                return MarkdownNavigation.slug((text.model.display as NSString).substring(with: block.range)) == anchor.lowercased()
            }) { text.scrollRangeToVisible(block.range); text.sentence(at: block.range.location) }
            else { showCopyNotice("未找到文内标题") }
            return true
        }
        if let url = URL(string: target), ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
            // Only an explicit link click opens the browser. Rendering never fetches a URL.
            if !NSWorkspace.shared.open(url) { showCopyNotice("无法打开链接") }
            return true
        }
        if let document = currentURL, let url = MarkdownNavigation.localURL(target, document: document, root: rootURL ?? document.deletingLastPathComponent()) {
            loadFile(url) { _ in }
        } else { showCopyNotice("此链接不可在预览中打开") }
        return true // Block scripts, custom schemes and arbitrary app launching.
    }
    func finish(_ error: Error?) { let handler = completion; completion = nil; handler?(error) }
    func cancelPending() { richTask?.cancel(); richTask = nil; richRenderer?.cancel(); richRenderer = nil; remoteTask?.cancel(); remoteTask = nil; remoteLoader?.cancel(); remoteLoader = nil; remoteButton.isEnabled = true; cancellation?.cancel(); cancellation = nil; generation = UUID(); finish(CancellationError()) }
    public func close() {
        clearCopyNotice(); savePosition(); cancelPending(); folder.cancel(); settingsTimer?.invalidate(); settingsTimer = nil
        if rootScope { rootURL?.stopAccessingSecurityScopedResource(); rootScope = false }
        logger.notice("closed / pending work cancelled")
    }
    @objc func cancelLoad() { cancelPending(); folder.cancel(); status.stringValue = "已取消后台读取" }
    func present() {
        guard let source else { return }
        settings = SettingsStore.shared.load()
        let renderedMode = mode.selectedSegment == 0
        let markdown = format == .markdown && renderedMode && rendered != nil
        let model = markdown ? rendered! : (renderedMode && tableData != nil ? tableData!.textModel(source: source.text) : TextModel.plain(source.text, code: format != .text))
        let hasRemote = markdown && model.images.contains { ["http", "https"].contains(URL(string: $0.destination)?.scheme?.lowercased() ?? "") }
        remoteBar.isHidden = !hasRemote; remoteHeight.constant = hasRemote ? 28 : 0
        text.isRichText = markdown
        text.clearDecoration(); text.model = model; text.sentences = model.sentences()
        renderedWidth = max(100, scroll.contentSize.width - 44)
        text.textStorage?.setAttributedString(TextStyler.attributed(model, markdown: markdown, settings: settings, focus: settings.focus, assets: markdownAssets, width: renderedWidth))
        text.sentence(at: min(text.anchor, model.display.utf16.count))
        scroll.rulersVisible = !markdown && settings.lineNumbers
        text.textContainerInset = NSSize(width: scroll.rulersVisible ? 74 : 22, height: 18)
        lineRuler.update(model.display)
        let wrap = markdown || settings.wrapCode
        text.isHorizontallyResizable = !wrap; text.autoresizingMask = wrap ? [.width] : []
        text.textContainer?.widthTracksTextView = wrap
        text.textContainer?.containerSize = NSSize(width: wrap ? max(100, scroll.contentSize.width - 2 * text.textContainerInset.width) : 100000, height: CGFloat.greatestFiniteMagnitude)
        if !wrap { text.sizeToFit() }
        if wrap { text.setFrameSize(NSSize(width: max(100, scroll.contentSize.width), height: text.frame.height)) }
        headings.removeAllItems(); headings.addItem(withTitle: "目录"); headingOffsets = []
        for block in model.blocks {
            if case .heading(let level) = block.kind {
                headings.addItem(withTitle: String(repeating: "  ", count: level - 1) + (model.display as NSString).substring(with: block.range)); headingOffsets.append(block.range.location)
            }
        }
        headings.isEnabled = !headingOffsets.isEmpty
        if renderedMode, let jsonTree { json.show(jsonTree, source: source.text); showContent(json.view) }
        else if renderedMode, let tableData { table.show(tableData); showContent(table.view) }
        else { showContent(scroll) }
        mode.isEnabled = rendered != nil || jsonTree != nil || tableData != nil
        status.stringValue = "\(currentURL?.lastPathComponent ?? "") · \(source.encoding) · \(source.byteCount) bytes · \(format.rawValue) · \(tableData?.partial == true ? "前 5,000 行，部分内容" : "完整文件")"
        let notices = [
            parseWarning,
            jsonTree?.duplicateKeys == true ? "重复键已保留为独立节点。" : "",
            SettingsStore.shared.sharedAvailable ? "" : "设置限当前容器；App Group 未配置。"
        ].filter { !$0.isEmpty }
        if !notices.isEmpty { status.stringValue += "\n" + notices.joined(separator: " ") }
        if let data = tableData, renderedMode { status.stringValue += " 表格已解析 \(data.rows.count) 行；每批显示 500 行，可在显示设置继续加载。" }
        if source.text.utf16.count > PreviewLimits().highlightUTF16 { status.stringValue += " 高亮限前 250,000 UTF-16 单元；正文完整。" }
        applySettings(); searchChanged()
    }
    func applySettings() {
        focus.state = settings.focus ? .on : .off
        ruler.selectItem(at: [0,1,3,5].firstIndex(of: settings.rulerLines) ?? 2)
        text.focusEnabled = settings.focus; text.rulerLines = settings.rulerLines; text.highlightEnabled = settings.highlight; text.dimEnabled = settings.dim
        view.appearance = settings.theme == "Dark" ? NSAppearance(named: .darkAqua) : settings.theme == "Light" ? NSAppearance(named: .aqua) : nil
        text.needsDisplay = true
    }
    func saveSettings() { SettingsStore.shared.save(settings); present() }
    func savePosition() {
        guard let currentURL, let source else { return }
        var displayOffset = text.anchor
        if !settings.focus, let layout = text.layoutManager, let container = text.textContainer, layout.numberOfGlyphs > 0 {
            let visible = text.visibleRect.offsetBy(dx: -text.textContainerOrigin.x, dy: -text.textContainerOrigin.y)
            let glyph = layout.glyphRange(forBoundingRect: visible, in: container)
            if glyph.location < layout.numberOfGlyphs { displayOffset = layout.characterIndexForGlyph(at: glyph.location) }
        }
        let offset = text.model.sourceRange(for: NSRange(location: displayOffset, length: 1))?.location ?? 0
        SettingsStore.shared.remember(currentURL, revision: source.revision, offset: offset)
    }
    @objc func toggleSource() {
        let sourceOffset = text.model.sourceRange(for: NSRange(location: text.anchor, length: 1))?.location ?? 0
        present(); text.sentence(at: text.model.displayOffset(forSource: sourceOffset))
        text.scrollRangeToVisible(NSRange(location: text.anchor, length: 0))
    }
    @objc func changeFocus() { settings.focus = focus.state == .on; saveSettings() }
    @objc func changeRuler() { settings.rulerLines = [0,1,3,5][ruler.indexOfSelectedItem]; saveSettings() }
    @objc func smaller() { resize(-1) }
    @objc func larger() { resize(1) }
    func resize(_ delta: Double) { if format == .markdown && mode.selectedSegment == 0 { settings.documentSize = min(36, max(10, settings.documentSize + delta)) } else { settings.codeSize = min(32, max(10, settings.codeSize + delta)) }; saveSettings() }
    @objc func previousSentence() { text.moveSentence(-1) }
    @objc func nextSentence() { text.moveSentence(1) }
    @objc func focusSearch() {
        let accepted = view.window?.makeFirstResponder(search) ?? false
        search.selectText(nil)
        logger.notice("explicit search focus accepted=\(accepted, privacy: .public)")
    }
    @objc func selectBody() { view.window?.makeFirstResponder(text); text.selectAll(nil) }
    @objc func copySelection() {
        if currentContent === table.view { table.copyCell() }
        else if currentContent === json.view { json.copyValue() }
        else { text.copy(nil) }
    }
    @objc func reload() { if let currentURL { loadFile(currentURL, completion: { _ in }) } else if let rootURL { open(rootURL) { _ in } } }
    @objc func optionChanged() {
        switch optionsMenu.indexOfSelectedItem {
        case 1: settings.lineNumbers.toggle()
        case 2: settings.wrapCode.toggle()
        case 3: settings.highlight.toggle()
        case 4: settings.dim.toggle()
        case 5: table.header.toggle()
        case 6: table.loaded += 500
        case 7: settings.theme = "System"
        case 8: settings.theme = "Light"
        case 9: settings.theme = "Dark"
        default: break
        }
        optionsMenu.selectItem(at: 0); saveSettings()
    }
    @objc func jumpHeading() { let i = headings.indexOfSelectedItem - 1; if i >= 0 && i < headingOffsets.count { jump(NSRange(location: headingOffsets[i], length: 1)) } }
    @objc func jumpLine() {
        let n = lineField.integerValue
        guard n > 0, let source else { return }
        let ns = source.text as NSString; var line = 1; var offset = 0
        while line < n && offset < ns.length { offset = NSMaxRange(ns.lineRange(for: NSRange(location: offset, length: 0))); line += 1 }
        let display = text.model.displayOffset(forSource: offset); jump(NSRange(location: min(display, text.string.utf16.count), length: 0))
    }
    public func controlTextDidChange(_ obj: Notification) { searchChanged() }
    @objc func searchChanged() {
        logger.notice("search event queryLength=\(self.search.stringValue.utf16.count)")
        matches = text.model.search(search.stringValue, caseSensitive: caseButton.state == .on); matchIndex = -1
        let all = NSRange(location: 0, length: text.string.utf16.count)
        text.layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: all)
        for range in matches.prefix(1000) { text.layoutManager?.addTemporaryAttribute(.backgroundColor, value: NSColor.systemOrange.withAlphaComponent(0.24), forCharacterRange: range) }
        resultLabel.stringValue = search.stringValue.isEmpty ? "已加载内容" : "\(matches.count) 项（已加载）"
    }
    @objc func nextMatch() { moveMatch(1) }
    @objc func previousMatch() { moveMatch(-1) }
    func moveMatch(_ delta: Int) {
        guard !matches.isEmpty else { return }
        matchIndex = (matchIndex + delta + matches.count) % matches.count
        let range = matches[matchIndex]
        let indexToRestore = matchIndex
        if currentContent === table.view { table.reveal(sourceRange: text.model.sourceRange(for: range) ?? range) }
        else { if currentContent === json.view { mode.selectedSegment = 1; present() }; jump(range) }
        matchIndex = indexToRestore
        resultLabel.stringValue = "\(matchIndex + 1)/\(matches.count)"
    }
    func jump(_ range: NSRange) { text.setSelectedRange(range); text.sentence(at: range.location); text.scrollRangeToVisible(range); savePosition() }
}

final class FocusSearchField: NSSearchField {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        Logger(subsystem: "local.OrangeLen", category: "Input").notice("search mouseDown")
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }
}
