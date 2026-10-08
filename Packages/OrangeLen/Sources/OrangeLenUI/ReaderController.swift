import AppKit
import OrangeLenCore
import os
import PDFKit
import QuickLookUI
import AVKit
import Darwin

private final class ResponsiveReaderView: ReaderBackgroundView {
    var resized: ((CGFloat) -> Void)?
    var didLayout: (() -> Void)?
    override func setFrameSize(_ newSize: NSSize) { super.setFrameSize(newSize); resized?(newSize.width) }
    override func layout() { super.layout(); didLayout?() }
}

public final class ReaderController: NSViewController, NSSearchFieldDelegate, NSTextViewDelegate {
    public var previewCategory: String?
    var compactPreferred = false
    var toolbarViews: [NSView] = []
    var toolbarHeights: [NSLayoutConstraint] = []
    var collection: CollectionController?
    var databaseController: DatabaseController?
    var archiveController: ArchiveController?
    var virtualDocument = false
    var virtualTitle = ""
    let pdf = PDFView()
    var systemPreview: QLPreviewView?
    var systemPreviewScope: URL?
    var mediaResource: LocalMediaResource?
    var mediaPreview: AVPlayerView?
    var mediaObservation: NSKeyValueObservation?
    var nativeDocumentPreview: NSScrollView?
    var mainControls: [NSView] = []
    var findControls: [NSView] = []
    let overflow = NSPopUpButton()
    let sidebarButton = NSButton(checkboxWithTitle: L10n.text("目录树"), target: nil, action: nil)
    let copyNotice = NSStackView()
    let copyNoticeLabel = NSTextField(labelWithString: "")
    var hideCopyNotice: DispatchWorkItem?
    let text = ReadingTextView()
    let scroll = NSScrollView()
    let picture = ZoomCanvasView(frame: .zero)
    let folderInfo = NSTextField(wrappingLabelWithString: "")
    let folderOverview = FolderOverviewView()
    let overviewToolbarTitle = NSTextField(labelWithString: L10n.text("文件夹概览"))
    let overviewToolbarSpacer = NSView()
    var sidebarGlass: GlassSurface!
    var refreshGlass: GlassSurface!
    let overviewRefresh = NSButton(title: "", target: nil, action: nil)
    let search = FocusSearchField()
    let caseButton = NSButton(checkboxWithTitle: "Aa", target: nil, action: nil)
    let resultLabel = NSTextField(labelWithString: "")
    let status = NSTextField(wrappingLabelWithString: L10n.text("OrangeLen · Quick Look for Developers\n使用 ⌘O 选择文件或文件夹。应用内预览是补充入口，Finder 支持请查看验证记录。"))
    let mode = NSSegmentedControl(labels: [L10n.text("阅读"), L10n.text("源码")], trackingMode: .selectOne, target: nil, action: nil)
    let headings = NSPopUpButton()
    let lineField = NSTextField()
    let split = NSSplitView()
    let body = NSView()
    let documentBody = NSView(), documentSplit = NSSplitView()
    let outlineSidebar = MarkdownOutlineController()
    let outlineToggle = NSButton(checkboxWithTitle: L10n.text("大纲"), target: nil, action: nil)
    var scrollObservation: NSObjectProtocol?
    let folder = FolderController()
    let json = JSONController()
    let table = TableController()
    var lineRuler: LineRuler!
    var settings = SettingsStore.shared.load()
    var settingsBaseline = SettingsStore.shared.load()
    var readingGeneration = SettingsStore.shared.readingGeneration
    var source: SourceSnapshot?
    var markdownAssets = MarkdownAssets()
    var canvasImage: NSImage?
    var canvasLabel = "Excalidraw"
    var richTask: Task<Void, Never>?
    var richRenderer: RichContentRenderer?
    var remoteTask: Task<Void, Never>?
    var remoteLoader: RemoteImageRequest?
    var remoteAttempts = 0
    var remoteBytes = 0
    let remoteBar = NSStackView()
    let remoteButton = NSButton(title: L10n.text("加载远程图片"), target: nil, action: nil)
    let remoteStatus = NSTextField(labelWithString: L10n.text("远程图片尚未加载"))
    var remoteHeight: NSLayoutConstraint!
    var renderedWidth: CGFloat = 0
    var rendered: TextModel?
    var jsonTree: JSONTree?
    var tableData: TableData?
    var parseWarning = ""
    var pageHistory: [Int] = []
    let pageBar = NSStackView()
    let firstPageButton = NSButton(title: L10n.text("回到开头"), target: nil, action: nil)
    let previousPageButton = NSButton(title: L10n.text("上一页"), target: nil, action: nil)
    let nextPageButton = NSButton(title: L10n.text("下一页"), target: nil, action: nil)
    let pageLabel = NSTextField(labelWithString: "")
    var pageHeight: NSLayoutConstraint!
    var format: PreviewFormat = .text
    var currentURL: URL?
    var rootURL: URL?
    var rootScope = false
    var imageRootURL: URL?, imageDocumentURL: URL?
    var imageRootScope = false
    var imageGrantOwner: UUID?
    var imageGrantPublished = Date.distantPast
    let localImagesButton = NSButton(title: L10n.text("允许本地图片…"), target: nil, action: nil)
    var highlightToken: Cancellation?
    var preparedHighlights: (text: String, tokens: [SyntaxHighlighter.Token])?
    var highlightGeneration = UUID()
    var generation = UUID()
    var cancellation: Cancellation?
    var completion: ((Error?) -> Void)?
    var matches: [NSRange] = []
    var matchIndex = -1
    var currentContent: NSView?
    var settingsTimer: Timer?
    var observedRevision: String?
    var observedURL: URL?
    var autoReload = false
    var headingOffsets: [Int] = []
    let logger = Logger(subsystem: "local.OrangeLen", category: "Reader")
    var optionsMenu = NSPopUpButton()
    public override func loadView() {
        let root = ResponsiveReaderView(frame: NSRect(x: 0, y: 0, width: 1000, height: 720))
        root.autoresizingMask = [.width, .height]
        let bar = NSStackView(); bar.orientation = .horizontal; bar.spacing = 6
        mode.selectedSegment = 0; mode.target = self; mode.action = #selector(toggleSource)
        headings.target = self; headings.action = #selector(jumpHeading); headings.addItem(withTitle: L10n.text("文档目录"))
        // Menu items retain full headings, but must not set the toolbar's minimum width.
        for (popup, width) in [(headings, CGFloat(180)), (overflow, CGFloat(144)), (optionsMenu, CGFloat(160))] {
            popup.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            popup.widthAnchor.constraint(lessThanOrEqualToConstant: width).isActive = true
            popup.cell?.lineBreakMode = .byTruncatingTail
        }
        optionsMenu.addItems(withTitles: [L10n.text("显示设置"), L10n.text("切换行号"), L10n.text("切换代码换行"), L10n.text("切换表头"), L10n.text("表格再加载 500 行"), L10n.text("跟随系统"), L10n.text("浅色"), L10n.text("深色")])
        optionsMenu.target = self; optionsMenu.action = #selector(optionChanged)
        for control in [mode, headings, button("A−", #selector(smaller)), button("A+", #selector(larger)), optionsMenu, button(L10n.text("重载"), #selector(reload))] { bar.addArrangedSubview(control); mainControls.append(control) }
        let findbar = NSStackView(); findbar.orientation = .horizontal; findbar.spacing = 6
        search.placeholderString = Bundle.main.bundleURL.pathExtension == "appex" ? L10n.text("查找已加载内容（点击输入）") : L10n.text("查找已加载内容 ⌘F"); search.delegate = self; search.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        search.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        caseButton.target = self; caseButton.action = #selector(searchChanged)
        lineField.placeholderString = L10n.text("行号"); lineField.widthAnchor.constraint(equalToConstant: 65).isActive = true
        lineField.target = self; lineField.action = #selector(jumpLine)
        resultLabel.font = .systemFont(ofSize: 11)
        for control in [button(L10n.text("查找"), #selector(focusSearch)), search, caseButton, button("↑", #selector(previousMatch)), button("↓", #selector(nextMatch)), resultLabel, lineField, button(L10n.text("定位"), #selector(jumpLine)), button(L10n.text("全选"), #selector(selectBody)), button(L10n.text("复制选择"), #selector(copySelection)), button(L10n.text("取消加载"), #selector(cancelLoad))] { findbar.addArrangedSubview(control); findControls.append(control) }
        overflow.addItems(withTitles: [L10n.text("更多操作"), L10n.text("减小字号"), L10n.text("增大字号"), L10n.text("重载"), L10n.text("定位到行"), L10n.text("取消加载"), L10n.text("在 Finder 中显示"), L10n.text("默认应用打开"), L10n.text("阅读/源码切换")])
        overflow.target = self; overflow.action = #selector(overflowChanged); bar.addArrangedSubview(overflow)
        sidebarButton.setButtonType(.pushOnPushOff); sidebarButton.title = ""; sidebarButton.isBordered = false
        sidebarButton.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: L10n.text("显示或隐藏目录树"))
        sidebarButton.toolTip = L10n.text("显示或隐藏目录树")
        sidebarButton.target = self; sidebarButton.action = #selector(toggleSidebar)
        sidebarGlass = GlassSurface(content: sidebarButton, radius: 14)
        sidebarGlass.widthAnchor.constraint(equalToConstant: 38).isActive = true
        sidebarGlass.heightAnchor.constraint(equalToConstant: 28).isActive = true
        bar.addArrangedSubview(sidebarGlass); sidebarGlass.isHidden = true; sidebarButton.isHidden = true
        outlineToggle.target = self; outlineToggle.action = #selector(toggleOutline); outlineToggle.isHidden = true; bar.addArrangedSubview(outlineToggle)
        pdf.autoScales = true
        addChild(folder); addChild(json); addChild(table)
        split.isVertical = true; split.dividerStyle = .thin
        split.addArrangedSubview(folder.view); split.addArrangedSubview(body)
        addChild(outlineSidebar); documentSplit.isVertical = true; documentSplit.dividerStyle = .thin
        documentSplit.addArrangedSubview(outlineSidebar.view); documentSplit.addArrangedSubview(documentBody)
        outlineSidebar.view.isHidden = true
        let outlineWidth = outlineSidebar.view.widthAnchor.constraint(equalToConstant: 220); outlineWidth.priority = .defaultHigh; outlineWidth.isActive = true
        outlineSidebar.onSelect = { [weak self] in self?.jump($0) }
        documentSplit.translatesAutoresizingMaskIntoConstraints = false; body.addSubview(documentSplit)
        NSLayoutConstraint.activate([documentSplit.leadingAnchor.constraint(equalTo: body.leadingAnchor), documentSplit.trailingAnchor.constraint(equalTo: body.trailingAnchor), documentSplit.topAnchor.constraint(equalTo: body.topAnchor), documentSplit.bottomAnchor.constraint(equalTo: body.bottomAnchor)])
        overviewToolbarTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        overviewRefresh.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: L10n.text("刷新文件夹"))
        overviewRefresh.isBordered = false; overviewRefresh.target = self; overviewRefresh.action = #selector(reload)
        refreshGlass = GlassSurface(content: overviewRefresh, radius: 14)
        refreshGlass.widthAnchor.constraint(equalToConstant: 38).isActive = true
        refreshGlass.heightAnchor.constraint(equalToConstant: 28).isActive = true
        bar.addArrangedSubview(overviewToolbarTitle); bar.addArrangedSubview(overviewToolbarSpacer); bar.addArrangedSubview(refreshGlass)
        folderOverview.onScan = { [weak self] in self?.folder.toggleSummary() }
        folderOverview.onReadme = { [weak self] url in self?.loadFile(url, completion: { _ in }) }
        folder.onOverview = { [weak self] in self?.returnToFolderOverview() }
        let folderWidth = folder.view.widthAnchor.constraint(equalToConstant:250); folderWidth.priority = .defaultHigh; folderWidth.isActive = true
        folder.view.widthAnchor.constraint(greaterThanOrEqualToConstant:220).isActive = true
        split.setHoldingPriority(.defaultHigh,forSubviewAt:0)
        folder.view.isHidden = true
        folderInfo.font = .systemFont(ofSize: 12); folderInfo.textColor = .secondaryLabelColor
        folder.onSummary = { [weak self] summary in
            guard let self else { return }
            self.folderInfo.stringValue = self.currentContent === self.folderOverview ? "" : summary
        }
        folder.onStatistics = { [weak self] summary, scanning, message in
            self?.folderOverview.update(summary, scanning: scanning, message: message)
        }
        picture.setContentHuggingPriority(.defaultLow, for: .vertical); picture.setContentHuggingPriority(.defaultLow, for: .horizontal)
        picture.setContentCompressionResistancePriority(.defaultLow, for: .vertical); picture.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        picture.imageScaling = .scaleProportionallyUpOrDown; picture.setAccessibilityLabel(L10n.text("图片预览"))
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
        text.setAccessibilityLabel(L10n.text("OrangeLen 只读正文"))
        text.findAction = { [weak self] in self?.view.window?.makeFirstResponder(self?.search) }
        text.attachmentAction = { [weak self] index in self?.activateAttachment(index) ?? false }
        scroll.documentView = text
        scroll.contentView.postsBoundsChangedNotifications = true
        scrollObservation = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: scroll.contentView, queue: .main) { [weak self] _ in self?.updateActiveHeading() }
        lineRuler = LineRuler(scroll: scroll, text: text); scroll.verticalRulerView = lineRuler; scroll.hasVerticalRuler = true
        status.font = .systemFont(ofSize: 11); status.textColor = .secondaryLabelColor
        remoteButton.target = self; remoteButton.action = #selector(loadRemoteImages)
        remoteBar.orientation = .horizontal; remoteBar.spacing = 10
        remoteStatus.font = .systemFont(ofSize: 12); remoteStatus.textColor = .secondaryLabelColor
        // Hidden auxiliary bars still participate in Auto Layout. Longer translations
        // must not impose a minimum width on the entire preview.
        remoteStatus.lineBreakMode = .byTruncatingTail
        for control in [remoteStatus, localImagesButton, remoteButton] {
            control.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        remoteBar.setClippingResistancePriority(.defaultLow, for: .horizontal)
        pageBar.setClippingResistancePriority(.defaultLow, for: .horizontal)
        localImagesButton.target = self; localImagesButton.action = #selector(authorizeLocalImages)
        if Bundle.main.bundleURL.pathExtension == "appex" { localImagesButton.title = L10n.text("本地图片授权说明") }
        remoteBar.addArrangedSubview(localImagesButton); remoteBar.addArrangedSubview(remoteButton); remoteBar.addArrangedSubview(remoteStatus)
        remoteHeight = remoteBar.heightAnchor.constraint(equalToConstant: 0); remoteHeight.isActive = true
        remoteBar.isHidden = true
        firstPageButton.target = self; firstPageButton.action = #selector(firstTextPage)
        previousPageButton.target = self; previousPageButton.action = #selector(previousTextPage)
        nextPageButton.target = self; nextPageButton.action = #selector(nextTextPage)
        pageBar.spacing = 8; pageBar.addArrangedSubview(firstPageButton); pageBar.addArrangedSubview(previousPageButton); pageBar.addArrangedSubview(nextPageButton); pageBar.addArrangedSubview(pageLabel)
        pageLabel.lineBreakMode = .byTruncatingMiddle; pageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        pageLabel.font = .systemFont(ofSize: 11); pageBar.isHidden = true
        pageHeight = pageBar.heightAnchor.constraint(equalToConstant: 0); pageHeight.isActive = true
        for child in [bar, findbar, remoteBar, pageBar, split, folderInfo, status] { child.translatesAutoresizingMaskIntoConstraints = false; root.addSubview(child) }
        toolbarViews = [bar,findbar]
        toolbarHeights = [bar.heightAnchor.constraint(equalToConstant:30),findbar.heightAnchor.constraint(equalToConstant:28)]
        NSLayoutConstraint.activate(toolbarHeights)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: root.topAnchor, constant: 8), bar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10), bar.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -10),
            findbar.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 8), findbar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10), findbar.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -10),
            remoteBar.topAnchor.constraint(equalTo: findbar.bottomAnchor, constant: 4), remoteBar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10), remoteBar.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -10),
            pageBar.topAnchor.constraint(equalTo: remoteBar.bottomAnchor, constant: 4), pageBar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10), pageBar.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -10), split.topAnchor.constraint(equalTo: pageBar.bottomAnchor, constant: 4), split.leadingAnchor.constraint(equalTo: root.leadingAnchor), split.trailingAnchor.constraint(equalTo: root.trailingAnchor),
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
        view = root; root.resized = { [weak self] width in self?.updateToolbars(width) }
        root.didLayout = { [weak self] in self?.updateTextViewport() }
        showContent(scroll); applySettings(); updateToolbars(root.bounds.width)
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
        updateToolbars(view.bounds.width)
        updateTextViewport()
    }
    private func updateTextViewport() {
        guard currentContent === scroll else { return }
        scroll.tile()
        let wrap = (format == .markdown && mode.selectedSegment == 0) || settings.wrapCode
        let width = max(100, scroll.contentSize.width)
        if wrap && abs(text.frame.width - width) > 1 { text.setFrameSize(NSSize(width: width, height: max(text.frame.height, scroll.contentSize.height))) }
        text.textContainer?.widthTracksTextView = wrap
        if wrap {
            let containerWidth = max(1, width - 2 * text.textContainerInset.width)
            if let container = text.textContainer, abs(container.containerSize.width - containerWidth) > 1 {
                container.containerSize = NSSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude)
            }
        }
        if format == .markdown && mode.selectedSegment == 0 && (!text.model.images.isEmpty || !text.model.richContent.isEmpty) {
            let available = width - 44
            if abs(available - renderedWidth) > 2 {
                renderedWidth = available
                let selection = text.selectedRange()
                text.textStorage?.setAttributedString(TextStyler.attributed(text.model, markdown: true, settings: settings, assets: markdownAssets, width: available))
                applyPreparedHighlights(); text.setSelectedRange(selection)
            }
        }
        text.needsDisplay = true; lineRuler.needsDisplay = true
    }
    func updateToolbars(_ width: CGFloat) {
        let overview = currentContent === folderOverview
        folder.overviewButton.state = overview ? .on : .off
        overviewToolbarSpacer.isHidden = !overview; overviewToolbarTitle.isHidden = !overview; overviewRefresh.isHidden = !overview; refreshGlass.isHidden = !overview
        overflow.isHidden = overview
        let container = (archiveController != nil && currentContent === archiveController?.view) || (collection != nil && currentContent === collection?.view) || (databaseController != nil && currentContent === databaseController?.view)
        for (i, toolbar) in toolbarViews.enumerated() { toolbar.isHidden = container && i != 0 }
        for (i,height) in toolbarHeights.enumerated() { height.constant = container && i != 0 ? 0 : (i == 0 ? 30 : 28) }
        let compact = compactPreferred || width < 1280
        for (index,control) in mainControls.enumerated() { control.isHidden = compactPreferred || width < 600 ? ![4].contains(index) : compact && ![0,1,4].contains(index) }
        for (index,control) in findControls.enumerated() { control.isHidden = compactPreferred || width < 600 ? ![0,1,9].contains(index) : compact && ![0,1,8,9,10].contains(index) }
        if systemPreview != nil || mediaPreview != nil || nativeDocumentPreview != nil {
            for control in mainControls { control.isHidden = true }
            for (index, control) in findControls.enumerated() { control.isHidden = nativeDocumentPreview == nil || ![8,9].contains(index) }
            toolbarHeights.last?.constant = nativeDocumentPreview == nil ? 0 : 28
        }
        if container { for control in mainControls { control.isHidden = true }; overflow.isHidden = false }
        if overview {
            for control in mainControls + findControls { control.isHidden = true }
            toolbarViews.last?.isHidden = true; toolbarHeights.last?.constant = 0
        }
        sidebarButton.isHidden = rootURL == nil; sidebarGlass.isHidden = rootURL == nil
        let hasOutline = currentContent === scroll && format == .markdown && mode.selectedSegment == 0 && !headingOffsets.isEmpty && !(rootURL != nil && currentURL == nil)
        outlineToggle.isHidden = !hasOutline || width < 600 || compactPreferred
        outlineSidebar.view.isHidden = !hasOutline || !settings.markdownOutline || documentSplit.bounds.width < 650 || compactPreferred
    }
    func button(_ title: String, _ action: Selector) -> NSButton { let b = NSButton(title: title, target: self, action: action); b.bezelStyle = .rounded; return b }
    func showContent(_ child: NSView) {
        if currentContent === child { return }
        currentContent?.removeFromSuperview(); child.translatesAutoresizingMaskIntoConstraints = false; documentBody.addSubview(child)
        NSLayoutConstraint.activate([child.leadingAnchor.constraint(equalTo: documentBody.leadingAnchor), child.trailingAnchor.constraint(equalTo: documentBody.trailingAnchor), child.topAnchor.constraint(equalTo: documentBody.topAnchor), child.bottomAnchor.constraint(equalTo: documentBody.bottomAnchor)])
        currentContent = child
        if child !== scroll { outlineSidebar.view.isHidden = true; outlineToggle.isHidden = true }
        updateToolbars(view.bounds.width)
    }
    func returnToFolderOverview() {
        guard let rootURL else { return }
        savePosition(); cancelPending(); collection?.cancel(); databaseController?.cancel(); archiveController?.cancel()
        currentURL = nil; source = nil; rendered = nil; virtualDocument = false
        remoteBar.isHidden = true; remoteHeight.constant = 0; pageBar.isHidden = true; pageHeight.constant = 0
        folderInfo.stringValue = ""; status.stringValue = ""
        showContent(folderOverview); loadProjectOverview(rootURL)
    }
    public func open(_ url: URL, completion: @escaping (Error?) -> Void) {
        loadViewIfNeeded(); close(); rootURL = nil; folderInfo.stringValue = ""; picture.image = nil
        settingsTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let value = SettingsStore.shared.load()
            if value != self.settings { self.settings = value; self.settingsBaseline = value; self.applySettings(); self.present() }
            self.checkForFileChanges()
            self.syncImageDirectory()
        }
        rootScope = url.startAccessingSecurityScopedResource()
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
        let directory = values?.isDirectory == true && values?.isPackage != true
        if directory {
            rootURL = url; sidebarButton.state = .on; folder.view.isHidden = false; split.setPosition(240, ofDividerAt: 0)
            currentURL = nil; source = nil; rendered = nil; jsonTree = nil; tableData = nil; matches = []
            remoteBar.isHidden = true; remoteHeight.constant = 0
            folderOverview.configure(url); folder.open(url); showContent(folderOverview)
            folderInfo.stringValue = ""; status.stringValue = ""
            loadProjectOverview(url)
            completion(nil)
        } else {
            if rootScope { url.stopAccessingSecurityScopedResource(); rootScope = false }
            folder.view.isHidden = true; loadFile(url, completion: completion)
        }
    }
    func loadFile(_ url: URL, byteOffset requestedByteOffset: Int? = nil, pageOffsets: [Int]? = nil, completion handler: @escaping (Error?) -> Void) {
        savePosition()
        if currentURL != url { readingGeneration = SettingsStore.shared.readingGeneration }
        let previousEncoding = currentURL == url ? source?.encoding : nil
        let savedPage = requestedByteOffset == nil ? Self.fileRevision(url).flatMap { SettingsStore.shared.restorePage(url, revision: $0) } : nil
        let byteOffset = requestedByteOffset ?? savedPage?.byteOffset ?? 0
        let databaseState = autoReload ? databaseController?.readingState : nil
        let archiveState = autoReload ? archiveController?.readingState : nil
        let collectionState = autoReload ? collection?.readingState : nil
        outlineSidebar.view.isHidden = true; outlineToggle.isHidden = true
        if imageDocumentURL != url { releaseImageDirectory() }
        adoptImageDirectory(url)
        pageBar.isHidden = true; pageHeight.constant = 0
        if byteOffset == 0 { pageHistory = [] }
        if let savedPage { pageHistory = savedPage.history }
        if let pageOffsets { pageHistory = pageOffsets }
        clearCopyNotice(); cancelPending(); collection?.cancel(); databaseController?.cancel(); archiveController?.cancel(); virtualDocument = false
        let id = UUID(); generation = id; let token = Cancellation(); cancellation = token; completion = handler
        remoteAttempts = 0; remoteBytes = 0; remoteStatus.stringValue = L10n.text("远程图片尚未加载（点击后仅下载图片）"); remoteBar.isHidden = true; remoteHeight.constant = 0
        preparedHighlights = nil; canvasImage = nil; picture.onDismiss = nil; currentURL = url; observedURL = url; observedRevision = Self.fileRevision(url); source = nil; rendered = nil; markdownAssets = .init(); jsonTree = nil; tableData = nil; parseWarning = ""
        text.model = .plain(""); matches = []; text.anchor = 0; table.resetNavigation()
        text.string = L10n.text("正在读取…"); status.stringValue = L10n.text("OrangeLen · 本地、只读 · 正在载入 \(url.lastPathComponent)"); showContent(scroll)
        let loadStarted = ProcessInfo.processInfo.systemUptime
        let root = rootURL, imageRoot = imageRootURL ?? rootURL; let detected = PreviewFormat.detect(url); format = detected
        let enhanced = previewCategory == nil || previewCategory == PreviewCategory.folders.rawValue || previewCategory == PreviewCategory.detect(url).rawValue
        if enhanced && url.pathExtension.lowercased() == "excalidraw" {
            canvasLabel = "Excalidraw"
            loadExcalidraw(url, root: root, id: id, token: token)
            return
        }
        if enhanced && url.pathExtension.lowercased() == "svg" {
            canvasLabel = "SVG"
            loadSVG(url, root: root, id: id, token: token)
            return
        }
        if enhanced && ["sqlite", "sqlite3", "db"].contains(url.pathExtension.lowercased()) {
            if databaseController == nil { let child = DatabaseController(); addChild(child); databaseController = child }
            showContent(databaseController!.view)
            databaseController?.copyFeedback = { [weak self] in self?.showCopyNotice($0) }
            PreviewWorkQueue.parsing.submit(cancellation: token, work: { () -> DatabaseDocument in
                    var limits = PreviewLimits(); limits.fileBytes = limits.containerBytes
                    return try DatabaseDocument(data: AccessBroker.readBytes(url, root: root, limits: limits, cancellation: token).data, cancellation: token)
            }, completion: { [weak self] result in
                    guard let self, self.generation == id else { return }
                    switch result {
                    case .success(let database): self.databaseController?.open(database, restoring: databaseState); self.status.stringValue = L10n.text("SQLite · 只读快照 · 点击列标题排序 · 每页 500 行"); self.finish(nil)
                    case .failure(let error): self.showMessage(error.localizedDescription); self.finish(error)
                    }
            })
            return
        }
        if enhanced && ["zip", "tar", "tgz", "gz"].contains(url.pathExtension.lowercased()) && !GzipDocument.isPlainStream(url) {
            if archiveController == nil { let child = ArchiveController(); addChild(child); archiveController = child }
            showContent(archiveController!.view)
            PreviewWorkQueue.parsing.submit(cancellation: token, work: { () -> (ArchiveDocument, String) in
                    var limits = PreviewLimits(); limits.fileBytes = limits.containerBytes
                    let snapshot = try AccessBroker.readBytes(url, root: root, limits: limits, cancellation: token)
                    return (try ArchiveDocument.parse(snapshot.data, name: url.lastPathComponent, cancellation: token), snapshot.revision)
            }, completion: { [weak self] result in
                    guard let self, self.generation == id else { return }
                    switch result {
                    case .success(let value):
                        do { try self.archiveController?.open(value.0, origin: url, revision: value.1, restoring: archiveState); self.status.stringValue = L10n.text("归档 · 目录树 / 完整路径筛选 / 大小排序 · 成员按需读取"); self.finish(nil) }
                        catch { self.showMessage(error.localizedDescription); self.finish(error) }
                    case .failure(let error): self.showMessage(error.localizedDescription); self.finish(error)
                    }
            })
            return
        }
        if enhanced && ReadableFormat.isCollection(url) {
            if collection == nil { let child = CollectionController(); addChild(child); collection = child }
            showContent(collection!.view)
            collection!.open(url, root: root, restoring: collectionState) { [weak self] error in guard let self, self.generation == id else { return }; self.status.stringValue = url.lastPathComponent + (error == nil ? L10n.text(" · 容器预览 · 本地、只读") : L10n.text(" · 读取失败 · 可重载或选择其他文件")); self.finish(error) }
            return
        }
        if url.pathExtension.lowercased() == "pdf" {
            PreviewWorkQueue.parsing.submit(cancellation: token, work: { () -> Data in var limits = PreviewLimits(); limits.fileBytes = 25 * 1024 * 1024; return try AccessBroker.readBytes(url,root:root,limits:limits,cancellation:token).data
            }, completion: { [weak self] result in
                    guard let self, self.generation == id else { return }
                    do { let data = try result.get(); guard let document = PDFDocument(data:data), document.pageCount <= 2000 else { throw PreviewError.malformed(L10n.text("PDF 损坏或页数超过 2,000")) }; self.pdf.document = document; self.showContent(self.pdf); self.status.stringValue = L10n.text("PDF · \(document.pageCount) 页 · 原生只读预览"); self.finish(nil) }
                    catch { self.showMessage(error.localizedDescription); self.finish(error) }
            })
            return
        }
        // Rich text must reach Quick Look before the broad UTType.text check.
        // Keep OrangeLen's existing image, SVG and document renderers first.
        if !ImagePreview.supports(url) && SystemPreviewFormat.supports(url) {
            loadSystemPreview(url, root: root)
            return
        }
        if enhanced && !ImagePreview.supports(url) && !ReadableFormat.isText(url) {
            let size = (try? url.resourceValues(forKeys:[.fileSizeKey]).fileSize) ?? 0
            showMessage(L10n.text("暂不支持此格式：\(url.pathExtension.isEmpty ? L10n.text("无后缀") : url.pathExtension)\n\(ByteCountFormatter.string(fromByteCount:Int64(size),countStyle:.file))\n可在“更多操作”中用默认应用打开或在 Finder 中显示。\n预览不会执行此文件或强制二进制解码。"))
            status.stringValue = L10n.text("不支持的格式 · 明确降级"); finish(nil); return
        }
        if ImagePreview.supports(url) {
            picture.image = nil; mode.isEnabled = false; headings.isEnabled = false
            PreviewWorkQueue.parsing.submit(cancellation: token, work: {
                let scoped = root?.startAccessingSecurityScopedResource() ?? false
                defer { if scoped { root?.stopAccessingSecurityScopedResource() } }
                return try ImagePreview.load(url, root: root, cancellation: token)
            }, completion: { [weak self] result in
                    guard let self, self.generation == id else { return }
                    switch result {
                    case .success(let image):
                        self.picture.image = NSImage(cgImage: image.image, size: .zero)
                        self.picture.setAccessibilityLabel(L10n.text("图片预览：\(url.lastPathComponent)，\(image.width) × \(image.height) 像素"))
                        self.showContent(self.picture)
                        self.status.stringValue = L10n.text("\(url.lastPathComponent) · \(image.width) × \(image.height) 像素 · \(ByteCountFormatter.string(fromByteCount: Int64(image.bytes), countStyle: .file)) · 适合窗口（最长边解码至 2048 像素，动图显示首帧）")
                        self.finish(nil)
                    case .failure(let error):
                        self.text.string = error.localizedDescription
                        self.status.stringValue = L10n.text("图片预览未完成 · 可重载或选择其他文件"); self.finish(error)
                    }
            })
            return
        }
        PreviewWorkQueue.parsing.submit(cancellation: token, work: { [weak self] () -> (SourceSnapshot, TextModel?, JSONTree?, TableData?, String, MarkdownAssets) in
                let scoped = root?.startAccessingSecurityScopedResource() ?? false
                defer { if scoped { root?.stopAccessingSecurityScopedResource() } }
                var snapshot: SourceSnapshot
                var pagingNotice = ""
                do {
                    snapshot = try AccessBroker.readPreview(url, root: root, byteOffset: byteOffset, pageBytes: 64 * 1024, fullReadThreshold: 1024 * 1024, cancellation: token)
                    if byteOffset > 0, let previousEncoding, snapshot.encoding != previousEncoding { throw PreviewError.changed }
                } catch let error as PreviewError where byteOffset > 0 {
                    switch error {
                    case .encoding, .binary, .changed, .limit:
                        snapshot = try AccessBroker.readPreview(url, root: root, pageBytes: 64 * 1024, fullReadThreshold: 1024 * 1024, cancellation: token)
                        pagingNotice = L10n.text("文件已变化，旧分页位置失效，已返回开头。")
                    default: throw error
                    }
                }
                self?.logger.notice("preview read_ms=\((ProcessInfo.processInfo.systemUptime - loadStarted) * 1000, privacy: .public) bytes=\(snapshot.byteCount, privacy: .public)")
                var assets = MarkdownAssets()
                var markdown: TextModel?; var tree: JSONTree?; var table: TableData?; var warning = pagingNotice
                do {
                    switch (snapshot.partial || !enhanced) ? PreviewFormat.code : detected {
                    case .markdown:
                        markdown = try MarkdownModel.parse(snapshot.text, cancellation: token)
                        if let markdown { assets = try MarkdownAssets.load(markdown, document: url, root: imageRoot, cancellation: token) }
                    case .json: tree = try JSONParser.parse(snapshot.text, dialect: JSONDialect.detect(url), cancellation: token)
                    case .csv, .tsv: table = try CSVParser.parse(snapshot.text, separator: detected == .csv ? 44 : 9, cancellation: token)
                    default: break
                    }
                } catch is CancellationError { throw CancellationError() }
                catch { warning = error.localizedDescription + L10n.text(" · 已降级源码") }
                try token.check()
                try token.check()
                return (snapshot, markdown, tree, table, warning, assets)
        }, completion: { [weak self] result in
                guard let self, self.generation == id else { return }
                switch result {
                case .success(let loaded):
                    if loaded.0.byteOffset == 0 { self.pageHistory = [] }
                    self.source = loaded.0; self.rendered = loaded.1; self.jsonTree = loaded.2; self.tableData = loaded.3; self.parseWarning = loaded.4; self.markdownAssets = loaded.5
                    self.mode.selectedSegment = 0; self.present(); self.startRichRendering()
                    self.scroll.contentView.scroll(to: .zero); self.scroll.reflectScrolledClipView(self.scroll.contentView)
                    if let offset = SettingsStore.shared.restore(url, revision: loaded.0.revision, byteOffset: loaded.0.byteOffset) {
                        let display = self.text.model.displayOffset(forSource: offset); self.text.setAnchor(at: display)
                        self.text.scrollRangeToVisible(NSRange(location: min(display, self.text.string.utf16.count), length: 0))
                    }
                    self.logger.notice("loaded format=\(detected.rawValue, privacy: .public) bytes=\(loaded.0.byteCount, privacy: .public) folderChild=\(root != nil, privacy: .public)")
                    self.logger.notice("preview ready_ms=\((ProcessInfo.processInfo.systemUptime - loadStarted) * 1000, privacy: .public)")
                    self.finish(nil)
                case .failure(let error):
                    self.text.string = error is CancellationError ? L10n.text("已取消") : error.localizedDescription
                    self.status.stringValue = L10n.text("预览未完成 · 可重载或选择其他文件")
                    self.logger.notice("load failed code=\((error as NSError).code, privacy: .public)"); self.finish(error)
                }
        })
    }
    public func textView(_ textView: NSTextView, clickedOn cell: NSTextAttachmentCellProtocol, in cellFrame: NSRect, at charIndex: Int) {
        _ = activateAttachment(charIndex)
    }
    func activateAttachment(_ charIndex: Int) -> Bool {
        if let enlarged = markdownAssets.rich[charIndex] {
            picture.image = enlarged; picture.onDismiss = { [weak self] in self?.present() }; showContent(picture); return true
        }
        if let enlarged = markdownAssets.images[charIndex] {
            picture.image = NSImage(cgImage: enlarged, size: .zero); picture.onDismiss = { [weak self] in self?.present() }; showContent(picture); return true
        }
        guard !virtualDocument, let image = rendered?.images.first(where: { $0.range.location == charIndex }), markdownAssets.images[charIndex] == nil,
              ["http", "https"].contains(URL(string: image.destination)?.scheme?.lowercased() ?? "") else { return false }
        beginRemoteImages([image])
        return true
    }
    public func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        let target = (link as? String) ?? (link as? URL)?.absoluteString ?? ""
        if !virtualDocument, target.hasPrefix("orangelen-remote:"), let offset = Int(target.dropFirst("orangelen-remote:".count)), offset == charIndex,
           let image = rendered?.images.first(where: { $0.range.location == offset }) {
            beginRemoteImages([image]); return true
        }
        if target.hasPrefix("orangelen-footnote:"), let anchor = text.model.anchors.first(where: { $0.name == String(target.dropFirst("orangelen-footnote:".count)) }) { jump(anchor.range); return true }
        if target.hasPrefix("#") {
            let anchor = String(target.dropFirst()).removingPercentEncoding ?? String(target.dropFirst())
            if let block = text.model.blocks.first(where: { block in
                guard case .heading = block.kind else { return false }
                return MarkdownNavigation.slug((text.model.display as NSString).substring(with: block.range)) == anchor.lowercased()
            }) { text.scrollRangeToVisible(block.range); text.setAnchor(at: block.range.location) }
            else { showCopyNotice(L10n.text("未找到文内标题")) }
            return true
        }
        if let url = URL(string: target), ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
            // Only an explicit link click opens the browser. Rendering never fetches a URL.
            if !NSWorkspace.shared.open(url) { showCopyNotice(L10n.text("无法打开链接")) }
            return true
        }
        if !virtualDocument, let document = currentURL ?? rootURL?.appendingPathComponent("overview.md"), let url = MarkdownNavigation.localURL(target, document: document, root: rootURL ?? document.deletingLastPathComponent()) {
            loadFile(url) { _ in }
        } else { showCopyNotice(L10n.text("此链接不可在预览中打开")) }
        return true // Block scripts, custom schemes and arbitrary app launching.
    }
    func finish(_ error: Error?) {
        let handler = completion; completion = nil; handler?(error)
        let id = generation
        DispatchQueue.main.async { [weak self] in
            guard let self, self.generation == id, self.isViewLoaded else { return }
            let message = (self.currentURL?.lastPathComponent ?? L10n.text("预览")) + " · " + self.status.stringValue
            self.view.setAccessibilityLabel(message)
            NSAccessibility.post(element: self.view, notification: .announcementRequested, userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.medium.rawValue])
        }
    }
    func cancelPending() { highlightToken?.cancel(); highlightToken = nil; closeSystemPreview(); richTask?.cancel(); richTask = nil; richRenderer?.cancel(); richRenderer = nil; remoteTask?.cancel(); remoteTask = nil; remoteLoader?.cancel(); remoteLoader = nil; remoteButton.isEnabled = true; cancellation?.cancel(); cancellation = nil; generation = UUID(); finish(CancellationError()) }
    public func close() {
        pageBar.isHidden = true; pageHeight?.constant = 0
        savePosition(); pageHistory = []; releaseImageDirectory()
        clearCopyNotice(); cancelPending(); collection?.cancel(); databaseController?.cancel(); archiveController?.cancel(); pdf.document = nil; folder.cancel(); settingsTimer?.invalidate(); settingsTimer = nil
        if rootScope { rootURL?.stopAccessingSecurityScopedResource(); rootScope = false }
        source = nil; rendered = nil; jsonTree = nil; tableData = nil; currentURL = nil
        json.tree = nil; json.source = ""; json.outline.reloadData()
        table.data = .init(rows: [], partial: false); table.rowOrder = []; table.table.reloadData()
        preparedHighlights = nil; markdownAssets = .init(); canvasImage = nil; picture.image = nil; matches = []
        text.model = .plain(""); text.string = ""
        logger.notice("closed / pending work cancelled")
    }
    @objc func cancelLoad() {
        savePosition(); cancelPending(); collection?.cancel(); databaseController?.cancel(); archiveController?.cancel(); folder.cancel()
        if source == nil { showMessage(L10n.text("已取消读取 · 可点击重载或选择其他文件")) }
        else if currentContent !== scroll && currentContent !== json.view && currentContent !== table.view && currentContent !== picture { showMessage(L10n.text("已取消读取 · 可点击重载")) }
        status.stringValue = L10n.text("已取消后台读取 · 可重载；已加载正文为取消前快照")
    }
    /// Paint only foreground attributes after the first presentation; never replace
    /// the text storage, selection, search highlights or scroll position.
    func applyPreparedHighlights() {
        guard let preparedHighlights, let storage = text.textStorage, storage.string == preparedHighlights.text else { return }
        SyntaxHighlighter.shared.apply(preparedHighlights.tokens, to: storage)
    }
    func schedulePageHighlight(_ snapshot: SourceSnapshot) {
        scheduleHighlight(model: .plain(snapshot.text), partial: true, markdown: false)
    }
    func scheduleHighlight(model: TextModel, partial: Bool, markdown: Bool) {
        if preparedHighlights?.text == model.display { applyPreparedHighlights(); return }
        let request = UUID(); highlightGeneration = request
        highlightToken?.cancel(); let token = Cancellation(); highlightToken = token
        let id = generation
        let language = SyntaxHighlighter.language(url: currentURL, source: model.source)
        let display = model.display
        // One document-wide budget, even when it contains thousands of fenced blocks.
        let budget = partial ? 16_384 : PreviewLimits().highlightUTF16
        let spans: [(range: NSRange, language: String)] = markdown ? model.codeLanguages.map { ($0.range, $0.language) } : [(NSRange(location: 0, length: display.utf16.count), language ?? "")]
        let started = ProcessInfo.processInfo.systemUptime
        PreviewWorkQueue.highlight.async(cancellation: token) { [weak self] in
            guard (try? token.check()) != nil else { return }
            let utf16 = display as NSString
            var remaining = budget, result: [SyntaxHighlighter.Token] = []
            for span in spans {
                guard remaining > 0, (try? token.check()) != nil else { break }
                var count = min(span.range.length, remaining)
                let end = span.range.location + count
                if end < utf16.length, count > 0, (0xD800...0xDBFF).contains(utf16.character(at: end - 1)) { count -= 1 }
                guard count > 0 else { continue }
                let part = utf16.substring(with: NSRange(location: span.range.location, length: count))
                let tokens = SyntaxHighlighter.shared.tokens(part, language: span.language, cancellation: token)
                result += tokens.map { .init(range: NSRange(location: $0.range.location + span.range.location, length: $0.range.length), scope: $0.scope) }
                remaining -= count
            }
            guard (try? token.check()) != nil else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, self.generation == id, self.highlightGeneration == request,
                      let storage = self.text.textStorage, storage.string == display else { return }
                self.preparedHighlights = (display, result)
                storage.beginEditing(); self.applyPreparedHighlights(); storage.endEditing()
                self.logger.notice("preview highlight_ms=\((ProcessInfo.processInfo.systemUptime - started) * 1000, privacy: .public)")
            }
        }
    }
    func present() {
        guard let source else { return }
        settings = SettingsStore.shared.load(); settingsBaseline = settings
        let renderedMode = mode.selectedSegment == 0
        let markdown = format == .markdown && renderedMode && rendered != nil
        let model = markdown ? rendered! : (renderedMode && tableData != nil ? tableData!.textModel(source: source.text) : TextModel.plain(source.text, code: format != .text))
        let hasRemote = !virtualDocument && markdown && model.images.contains { ["http", "https"].contains(URL(string: $0.destination)?.scheme?.lowercased() ?? "") }
        let hasLocalFailures = !virtualDocument && markdown && model.images.contains { image in
            guard let components = URLComponents(string: image.destination), components.scheme == nil else { return false }
            return markdownAssets.images[image.range.location] == nil
        }
        localImagesButton.isHidden = !hasLocalFailures
        remoteButton.isHidden = !hasRemote; remoteStatus.isHidden = !hasRemote
        remoteBar.isHidden = !hasRemote && !hasLocalFailures; remoteHeight.constant = remoteBar.isHidden ? 0 : 28
        text.isRichText = markdown
        text.model = model
        renderedWidth = max(100, scroll.contentSize.width - 44)
        text.textStorage?.setAttributedString(TextStyler.attributed(model, markdown: markdown, settings: settings, assets: markdownAssets, width: renderedWidth, language: SyntaxHighlighter.language(url: currentURL, source: source.text), highlight: !source.partial))
        if format == .diff, let storage = text.textStorage { TextStyler.colorDiff(storage) }
        scheduleHighlight(model: model, partial: source.partial, markdown: markdown)
        text.setAnchor(at: min(text.anchor, model.display.utf16.count))
        scroll.rulersVisible = !markdown && settings.lineNumbers
        text.textContainerInset = NSSize(width: scroll.rulersVisible ? 74 : 22, height: 18)
        lineRuler.update(model.display)
        let wrap = markdown || settings.wrapCode
        text.isHorizontallyResizable = !wrap; text.autoresizingMask = wrap ? [.width] : []
        text.textContainer?.widthTracksTextView = wrap
        text.textContainer?.containerSize = NSSize(width: wrap ? max(100, scroll.contentSize.width - 2 * text.textContainerInset.width) : 100000, height: CGFloat.greatestFiniteMagnitude)
        if !wrap { text.sizeToFit() }
        if wrap { text.setFrameSize(NSSize(width: max(100, scroll.contentSize.width), height: text.frame.height)) }
        headings.removeAllItems(); headings.addItem(withTitle: L10n.text("文档目录")); headingOffsets = []
        for block in model.blocks {
            if case .heading(let level) = block.kind {
                headings.addItem(withTitle: String(repeating: "  ", count: level - 1) + (model.display as NSString).substring(with: block.range)); headingOffsets.append(block.range.location)
            }
        }
        headings.isEnabled = !headingOffsets.isEmpty
        outlineSidebar.show(model)
        let isFolderSummary = rootURL != nil && currentURL == nil
        outlineToggle.isHidden = !markdown || headingOffsets.isEmpty || isFolderSummary
        outlineToggle.state = settings.markdownOutline ? .on : .off
        outlineSidebar.view.isHidden = !markdown || !settings.markdownOutline || headingOffsets.isEmpty || isFolderSummary
        if !outlineSidebar.view.isHidden { documentSplit.setPosition(220, ofDividerAt: 0) }
        while overflow.numberOfItems > 9 { overflow.removeItem(at:9) }
        for item in headings.itemTitles.dropFirst() { overflow.addItem(withTitle:L10n.text("标题：")+item) }
        if renderedMode, let canvasImage { picture.image = canvasImage; showContent(picture) }
        else if renderedMode, let jsonTree { json.show(jsonTree, source: source.text); showContent(json.view) }
        else if renderedMode, let tableData { table.show(tableData); showContent(table.view) }
        else { showContent(scroll) }
        mode.isEnabled = canvasImage != nil || rendered != nil || jsonTree != nil || tableData != nil
        status.stringValue = "\(virtualDocument ? virtualTitle : currentURL?.lastPathComponent ?? "") · \(source.encoding) · \(source.byteCount) bytes · \(format.rawValue) · \(virtualDocument ? L10n.text("已加载条目（有界）") : source.partial ? L10n.text("分页源码片段") : tableData?.partial == true ? L10n.text("前 5,000 行，部分内容") : L10n.text("完整文件"))"
        if canvasImage != nil { status.stringValue = L10n.text("\(currentURL?.lastPathComponent ?? "") · \(canvasLabel) · 离线只读画布 · 可切换源码") }
        let notices = [
            parseWarning,
            jsonTree?.duplicateKeys == true ? L10n.text("重复键已保留为独立节点。") : "",
            SettingsStore.shared.sharedAvailable ? "" : L10n.text("设置限当前容器；App Group 未配置。")
        ].filter { !$0.isEmpty }
        if !notices.isEmpty { status.stringValue += "\n" + notices.joined(separator: " ") }
        if let data = tableData, renderedMode { status.stringValue += L10n.text(" 表格已解析 \(data.rows.count) 行；每批显示 500 行，可在显示设置继续加载。") }
        if source.partial {
            status.stringValue += L10n.text(" 高亮在正文显示后补充，限本页前 16,384 UTF-16 单元。")
        } else if source.text.utf16.count > PreviewLimits().highlightUTF16 {
            status.stringValue += source.partial
                ? L10n.text(" 高亮限本页前 250,000 UTF-16 单元；本页源码完整。")
                : L10n.text(" 高亮限前 250,000 UTF-16 单元；正文完整。")
        }
        pageBar.isHidden = !source.partial; pageHeight.constant = source.partial ? 28 : 0
        if source.partial {
            firstPageButton.isEnabled = source.byteOffset > 0
            previousPageButton.isEnabled = !pageHistory.isEmpty; nextPageButton.isEnabled = source.nextByteOffset != nil
            pageLabel.stringValue = L10n.text("字节 \(source.byteOffset + 1)–\(source.byteOffset + source.byteCount) / \(source.totalBytes) · 查找、行号与复制针对本页") + (source.byteOffset > 0 && pageHistory.isEmpty ? L10n.text(" · 更早历史已清理，可回到开头") : "")
        }
        applySettings(); searchChanged()
    }
    func applySettings() {
        view.appearance = settings.theme == "Dark" ? NSAppearance(named: .darkAqua) : settings.theme == "Light" ? NSAppearance(named: .aqua) : nil
        view.needsDisplay = true; text.needsDisplay = true
    }
    func saveSettings() { settings = SettingsStore.shared.update(from: settingsBaseline, to: settings); settingsBaseline = settings; applySettings(); present() }
    func savePosition() {
        guard let currentURL, let source else { return }
        var displayOffset = text.anchor
        if let layout = text.layoutManager, let container = text.textContainer, layout.numberOfGlyphs > 0 {
            let visible = text.visibleRect.offsetBy(dx: -text.textContainerOrigin.x, dy: -text.textContainerOrigin.y)
            let glyph = layout.glyphRange(forBoundingRect: visible, in: container)
            if glyph.location < layout.numberOfGlyphs { displayOffset = layout.characterIndexForGlyph(at: glyph.location) }
        }
        let offset = text.model.sourceRange(for: NSRange(location: displayOffset, length: 1))?.location ?? 0
        SettingsStore.shared.remember(currentURL, revision: source.revision, offset: offset, byteOffset: source.byteOffset, pageHistory: pageHistory, generation: readingGeneration)
    }
    @objc func nextTextPage() {
        guard let currentURL, let source, let next = source.nextByteOffset else { return }
        loadFile(currentURL, byteOffset: next, pageOffsets: Array((pageHistory + [source.byteOffset]).suffix(128))) { _ in }
    }
    @objc func previousTextPage() {
        guard let currentURL, let previous = pageHistory.last else { return }
        loadFile(currentURL, byteOffset: previous, pageOffsets: Array(pageHistory.dropLast())) { _ in }
    }
    @objc func firstTextPage() { if let currentURL { loadFile(currentURL, byteOffset: 0, pageOffsets: []) { _ in } } }
    static func fileRevision(_ url: URL) -> String? {
        var value = stat()
        guard lstat(url.path, &value) == 0 else { return nil }
        return "\(value.st_dev):\(value.st_ino):\(value.st_size):\(value.st_mtimespec.tv_sec):\(value.st_mtimespec.tv_nsec)"
    }
    func checkForFileChanges() {
        guard settings.liveReload, !virtualDocument, !autoReload, completion == nil, let url = currentURL, observedURL == url else { return }
        let revision = Self.fileRevision(url)
        guard revision != observedRevision else { return }
        observedRevision = revision
        guard revision != nil else { status.stringValue = L10n.text("文件已移走或删除；当前显示的是已加载快照。"); return }
        reloadPreservingPosition(url, notice: L10n.text("文件已更新"))
    }
    func reloadPreservingPosition(_ url: URL, notice: String) {
        var offset = text.anchor
        if let layout = text.layoutManager, let container = text.textContainer, layout.numberOfGlyphs > 0 {
            let visible = text.visibleRect.offsetBy(dx: -text.textContainerOrigin.x, dy: -text.textContainerOrigin.y)
            let glyphs = layout.glyphRange(forBoundingRect: visible, in: container)
            if glyphs.location < layout.numberOfGlyphs { offset = layout.characterIndexForGlyph(at: glyphs.location) }
        }
        let sourceOffset = text.model.sourceRange(for: .init(location: offset, length: 1))?.location ?? 0
        let mode = mode.selectedSegment, byteOffset = source?.byteOffset ?? 0, history = pageHistory
        autoReload = true
        loadFile(url, byteOffset: byteOffset) { [weak self] error in
            guard let self else { return }; self.autoReload = false
            let restoredSamePage = self.source?.byteOffset == byteOffset
            self.pageHistory = restoredSamePage ? history : []
            if error == nil, self.source != nil {
                if self.mode.isEnabled { self.mode.selectedSegment = mode; self.present() }
                let display = self.text.model.displayOffset(forSource: restoredSamePage ? sourceOffset : 0)
                self.text.setAnchor(at: display); self.text.scrollRangeToVisible(.init(location: min(display, self.text.string.utf16.count), length: 0))
                self.showCopyNotice(notice)
            }
        }
    }
    @objc func toggleSource() {
        let sourceOffset = text.model.sourceRange(for: NSRange(location: text.anchor, length: 1))?.location ?? 0
        present(); text.setAnchor(at: text.model.displayOffset(forSource: sourceOffset))
        text.scrollRangeToVisible(NSRange(location: text.anchor, length: 0))
    }
    @objc func smaller() { resize(-1) }
    @objc func larger() { resize(1) }
    func resize(_ delta: Double) { if format == .markdown && mode.selectedSegment == 0 { settings.documentSize = min(36, max(10, settings.documentSize + delta)) } else { settings.codeSize = min(32, max(10, settings.codeSize + delta)) }; saveSettings() }
    @objc func focusSearch() {
        let accepted = view.window?.makeFirstResponder(search) ?? false
        search.selectText(nil)
        logger.notice("explicit search focus accepted=\(accepted, privacy: .public)")
    }
    @objc func selectBody() {
        let content = (nativeDocumentPreview?.documentView as? NSTextView) ?? text
        view.window?.makeFirstResponder(content); content.selectAll(nil)
    }
    @objc func copySelection() {
        if let content = nativeDocumentPreview?.documentView as? NSTextView { content.copy(nil) }
        else if currentContent === table.view { table.copyCell() }
        else if currentContent === json.view { json.copyValue() }
        else { text.copy(nil) }
    }
    @objc func reload() { guard !virtualDocument else { showCopyNotice(L10n.text("请在左侧重新选择条目")); return }; if let currentURL { loadFile(currentURL, completion: { _ in }) } else if let rootURL { open(rootURL) { _ in } } }
    @objc func toggleOutline() { settings.markdownOutline = outlineToggle.state == .on; saveSettings() }
    func updateActiveHeading() {
        guard currentContent === scroll, !outlineSidebar.view.isHidden, let layout = text.layoutManager, let container = text.textContainer else { return }
        let visible = text.visibleRect.offsetBy(dx: -text.textContainerOrigin.x, dy: -text.textContainerOrigin.y)
        let range = layout.glyphRange(forBoundingRect: visible, in: container)
        if range.location < layout.numberOfGlyphs { outlineSidebar.active(layout.characterIndexForGlyph(at: range.location)) }
    }
    deinit { if let scrollObservation { NotificationCenter.default.removeObserver(scrollObservation) } }
    @objc func toggleSidebar() { folder.view.isHidden = sidebarButton.state != .on; if !folder.view.isHidden { split.setPosition(min(250,view.bounds.width * 0.35),ofDividerAt:0) } }
    @objc func overflowChanged() {
        switch overflow.indexOfSelectedItem {
        case 1: smaller()
        case 2: larger()
        case 3: reload()
        case 4: let alert = NSAlert(); alert.messageText = L10n.text("定位到源码行"); let field = NSTextField(frame:NSRect(x:0,y:0,width:200,height:24)); alert.accessoryView = field; alert.addButton(withTitle:L10n.text("定位")); alert.addButton(withTitle:L10n.text("取消")); if alert.runModal() == .alertFirstButtonReturn { lineField.stringValue = field.stringValue; jumpLine() }
        case 5: cancelLoad()
        case 6: if let currentURL, !virtualDocument { NSWorkspace.shared.activateFileViewerSelecting([currentURL]) }
        case 7: if let currentURL, !virtualDocument { NSWorkspace.shared.open(currentURL) }
        case 8: if mode.isEnabled { mode.selectedSegment = mode.selectedSegment == 0 ? 1 : 0; toggleSource() }
        default: let index = overflow.indexOfSelectedItem - 9; if index >= 0 && index < headingOffsets.count { jump(NSRange(location:headingOffsets[index],length:1)) }
        }
        overflow.selectItem(at:0)
    }
    @objc func optionChanged() {
        switch optionsMenu.indexOfSelectedItem {
        case 1: settings.lineNumbers.toggle()
        case 2: settings.wrapCode.toggle()
        case 3: table.header.toggle()
        case 4: table.loaded += 500
        case 5: settings.theme = "System"
        case 6: settings.theme = "Light"
        case 7: settings.theme = "Dark"
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
        resultLabel.stringValue = search.stringValue.isEmpty ? L10n.text("已加载内容") : L10n.text("\(matches.count) 项（已加载）")
    }
    @objc func nextMatch() { moveMatch(1) }
    @objc func previousMatch() { moveMatch(-1) }
    func moveMatch(_ delta: Int) {
        guard !matches.isEmpty else { return }
        matchIndex = (matchIndex + delta + matches.count) % matches.count
        let range = matches[matchIndex]
        let indexToRestore = matchIndex
        if currentContent === table.view { table.reveal(sourceRange: text.model.sourceRange(for: range) ?? range) }
        else { if currentContent === json.view || (canvasImage != nil && currentContent === picture) { mode.selectedSegment = 1; present() }; jump(range) }
        matchIndex = indexToRestore
        resultLabel.stringValue = "\(matchIndex + 1)/\(matches.count)"
    }
    func jump(_ range: NSRange) { text.setSelectedRange(range); text.setAnchor(at: range.location); text.scrollRangeToVisible(range); savePosition() }
}

final class FocusSearchField: NSSearchField {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        Logger(subsystem: "local.OrangeLen", category: "Input").notice("search mouseDown")
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }
}
