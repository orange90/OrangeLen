import AppKit
import UniformTypeIdentifiers
import OrangeLenCore

private final class FileEntryRow: NSTableRowView {
    var activate: (() -> Void)?
    override func accessibilityPerformPress() -> Bool { guard let activate else { return false }; activate(); return true }
}

private final class FileEntryButton: NSButton {
    var activate: (() -> Void)?
    init(title: String, activate: @escaping () -> Void) {
        super.init(frame: .zero); self.title = title; self.activate = activate
        isBordered = false; alignment = .left; lineBreakMode = .byTruncatingMiddle
        target = self; action = #selector(openEntry)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    @objc private func openEntry() { activate?() }
}

private final class FolderSidebarStack: NSStackView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedWhite: effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? 0.12 : 0.97, alpha: 1).setFill()
        bounds.fill()
    }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsDisplay = true }
}

private final class FolderOverviewButton: NSButton {
    override func draw(_ dirtyRect: NSRect) {
        if state == .on {
            NSColor.controlAccentColor.withAlphaComponent(0.12).setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 7, yRadius: 7).fill()
        }
        super.draw(dirtyRect)
    }
}

final class FolderController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSSearchFieldDelegate {
    final class Node {
        let url: URL
        let directory: Bool
        var children: [Node] = []
        var loaded = false
        var loading = false
        var revision: String?
        var nextOffset: Int?
        var more = false
        var detail = ""
        init(_ url: URL, directory: Bool) { self.url = url; self.directory = directory }
    }
    let overviewButton: NSButton = FolderOverviewButton(title: "文件夹概览", target: nil, action: nil)
    var onOverview: (() -> Void)?
    var onStatistics: ((FolderSummary?, Bool, String) -> Void)?
    private lazy var directoryIcon = NSWorkspace.shared.icon(for: .folder)
    let outline = NSOutlineView()
    let filter = NSSearchField()
    let ignored = NSButton(checkboxWithTitle: "显示忽略项", target: nil, action: nil)
    let retry = NSButton(title: "重新读取目录", target: nil, action: nil)
    let summaryButton = NSButton(title: "停止统计", target: nil, action: nil)
    var summaryToken: Cancellation?
    var summaryRequest = UUID()
    var lastSummary: FolderSummary?
    let status = NSTextField(wrappingLabelWithString: "仅扫描已展开目录")
    var root: Node?
    var tasks: [Cancellation] = []
    var generation = UUID()
    var onSelect: ((URL) -> Void)?
    var onSummary: ((String) -> Void)?
    var selectedURL: URL?
    override func loadView() {
        let stack = FolderSidebarStack(); stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        filter.placeholderString = "筛选文件"; filter.delegate = self
        retry.target = self; retry.action = #selector(retryDirectory)
        summaryButton.target = self; summaryButton.action = #selector(toggleSummary)
        ignored.target = self; ignored.action = #selector(resetIgnored)
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true
        let column = NSTableColumn(identifier: .init("name")); column.title = "目录"; column.width = 235; column.minWidth = 60
        outline.addTableColumn(column); outline.outlineTableColumn = column; outline.headerView = nil
        outline.dataSource = self; outline.delegate = self; outline.rowHeight = 30; outline.backgroundColor = .clear
        outline.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle; outline.autoresizingMask = [.width]
        outline.selectionHighlightStyle = .regular
        outline.setAccessibilityLabel("项目目录树")
        scroll.documentView = outline
        status.font = .systemFont(ofSize: 11); status.textColor = .secondaryLabelColor
        overviewButton.target = self; overviewButton.action = #selector(showOverview)
        overviewButton.bezelStyle = .rounded; overviewButton.contentTintColor = .controlAccentColor
        overviewButton.isBordered = false; overviewButton.alignment = .left; overviewButton.state = .on
        overviewButton.font = .systemFont(ofSize: 13, weight: .medium)
        overviewButton.heightAnchor.constraint(equalToConstant: 34).isActive = true
        overviewButton.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil); overviewButton.imagePosition = .imageLeading
        ignored.title = "显示隐藏与忽略项"; ignored.font = .systemFont(ofSize: 11)
        retry.title = "刷新目录"; retry.isBordered = false; retry.font = .systemFont(ofSize: 11)
        scroll.drawsBackground = false
        let caption = NSTextField(labelWithString: "文件"); caption.font = .systemFont(ofSize: 11); caption.textColor = .secondaryLabelColor
        for child in [filter, overviewButton, caption, scroll, status, retry, ignored] { stack.addArrangedSubview(child); child.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -16).isActive = true }
        view = stack
    }
    override func viewDidLayout() {
        super.viewDidLayout()
        if let width = outline.enclosingScrollView?.contentSize.width, width > 0 { outline.tableColumns.first?.width = width; outline.sizeLastColumnToFit() }
    }
    func open(_ url: URL) {
        loadViewIfNeeded(); cancel(); selectedURL = nil; root = Node(url, directory: true)
        summarize(url)
        outline.reloadData(); if let root { load(root); outline.expandItem(root) }
    }
    func cancel() {
        stopSummary()
        generation = UUID(); tasks.forEach { $0.cancel() }; tasks = []
        func reset(_ node: Node) { node.loading = false; for child in node.children { reset(child) } }
        if let root { reset(root) }
        status.stringValue = "已取消后台读取 · 重新点选目录可重试"
    }
    @objc func showOverview() { outline.deselectAll(nil); selectedURL = nil; onOverview?() }
    @objc func retryDirectory() {
        guard let node = (outline.item(atRow: outline.selectedRow) as? Node).flatMap({ $0.directory ? $0 : nil }) ?? root else { return }
        guard !node.loading else { return }
        node.children = []; node.nextOffset = nil; node.revision = nil; node.loaded = false
        outline.reloadItem(node, reloadChildren: true); load(node)
    }
    @objc func toggleSummary() { if summaryToken != nil { stopSummary() } else if let root { summarize(root.url) } }
    func stopSummary() {
        guard summaryToken != nil else { return }
        summaryToken?.cancel(); summaryToken = nil; summaryRequest = UUID(); summaryButton.title = "重新统计"
        onStatistics?(lastSummary, false, "已停止统计 · 当前为部分结果")
        let count = lastSummary?.files ?? 0, bytes = lastSummary?.bytes ?? 0
        onSummary?("已停止统计 · 已统计 \(count) 个文件 · \(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)) · 可点“重新统计”")
    }
    @objc func resetIgnored() { if let root { open(root.url) } }
    func load(_ node: Node) {
        guard !node.loading, let root else { return }
        node.loading = true
        let token = Cancellation(); tasks.append(token); let current = generation
        let expectedRevision = node.nextOffset == nil ? nil : node.revision
        let show = ignored.state == .on; let offset = node.nextOffset ?? 0; let ignoredNames = Set(SettingsStore.shared.load().ignored)
        status.stringValue = "正在读取直接子项…"
        PreviewWorkQueue.browsing.submit(cancellation: token, work: {
            return try { try FolderLoader.page(node.url, root: root.url, offset: offset, showIgnored: show, ignored: ignoredNames, expectedRevision: expectedRevision, cancellation: token) }()
        }, completion: { [weak self] result in
                guard let self, self.generation == current else { return }
                self.tasks.removeAll { $0 === token }
                node.loading = false
                switch result {
                case .success(let page):
                    node.loaded = true; node.revision = page.revision
                    node.children.removeAll { $0.more }
                    let existing = Set(node.children.map { $0.url.standardizedFileURL.path })
                    node.children += page.entries.filter { !existing.contains($0.url.standardizedFileURL.path) }.map { entry in
                        let child = Node(entry.url, directory: entry.directory && !entry.symbolicLink && !entry.package && !entry.unavailable)
                        child.detail = entry.symbolicLink ? " ↗（不跟随）" : entry.unavailable ? " ☁ 未下载" : entry.package ? "（文件包）" : ""
                        return child
                    }
                    node.children.sort { a, b in
                        if a.directory != b.directory { return a.directory }
                        return a.url.lastPathComponent.localizedStandardCompare(b.url.lastPathComponent) == .orderedAscending
                    }
                    node.nextOffset = page.nextOffset
                    if page.nextOffset != nil { let more = Node(node.url, directory: false); more.more = true; node.children.append(more) }
                    self.status.stringValue = "当前目录已扫描 \(page.scanned) 项\(page.nextOffset == nil ? "（完成）" : "（部分）")"
                case .failure(let error):
                    if case PreviewError.changed = error {
                        node.children = []; node.nextOffset = nil; node.revision = nil; node.loaded = false
                        self.status.stringValue = "目录已变化 · 点击“重新读取目录”获取一致列表"
                    } else { self.status.stringValue = error.localizedDescription + " · 可重新读取目录" }
                }
                self.outline.reloadItem(node, reloadChildren: true); if node.loaded { self.outline.expandItem(node) }
        })
    }
    func visible(_ node: Node?) -> [Node] {
        guard let node else { return root.map { [$0] } ?? [] }
        let query = filter.stringValue
        if query.isEmpty { return node.children }
        return node.children.filter { $0.directory || $0.more || $0.url.lastPathComponent.localizedCaseInsensitiveContains(query) }
    }
    func controlTextDidChange(_ obj: Notification) { outline.reloadData() }
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int { visible(item as? Node).count }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any { visible(item as? Node)[index] }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool { (item as? Node)?.directory == true }
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? Node else { return nil }
        if !node.directory && !node.more {
            let button = FileEntryButton(title: node.url.lastPathComponent + node.detail) { [weak self] in self?.activate(node) }
            button.font = .systemFont(ofSize: 13); button.contentTintColor = .labelColor
            button.image = NSImage(systemSymbolName: "doc", accessibilityDescription: nil); button.imagePosition = .imageLeading
            button.setAccessibilityLabel("预览 " + node.url.lastPathComponent)
            return button
        }
        let label = NSTextField(labelWithString: node.more ? "继续加载 500 项…" : node.url.lastPathComponent + node.detail)
        label.font = .systemFont(ofSize: 13); label.lineBreakMode = .byTruncatingMiddle
        guard node.directory && !node.more else { return label }
        // NSOutlineView supplies the disclosure arrow. Use the system folder artwork
        // without querying each directory (which could touch slow or cloud storage).
        let icon = NSImageView(image: directoryIcon)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.setAccessibilityElement(false)
        icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let cell = NSTableCellView(frame: NSRect(x: 0, y: 0, width: 220, height: 30))
        cell.imageView = icon; cell.textField = label
        icon.translatesAutoresizingMaskIntoConstraints = false; label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(icon); cell.addSubview(label)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor), icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 6), label.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }
    func activate(_ node: Node) {
        // Cell buttons consume mouseDown; explicitly keep the outline selection in sync.
        let row = outline.row(forItem: node)
        if row >= 0 && outline.selectedRow != row {
            outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            return // Selection delegate activates exactly once.
        }
        selectedURL = node.url
        onSelect?(node.url)
    }
    func summarize(_ url: URL) {
        stopSummary()
        let token = Cancellation(); summaryToken = token; let id = generation; let request = UUID(); summaryRequest = request
        lastSummary = nil; summaryButton.title = "停止统计"
        onSummary?("文件夹：\(url.lastPathComponent) · 正在统计大小和项目数量…")
        onStatistics?(nil, true, "正在统计…")
        let progress = LatestDelivery<FolderSummary> { [weak self] summary in
            guard let self, self.generation == id, self.summaryRequest == request, self.summaryToken != nil else { return }
            self.showSummary(summary, url: url, scanning: true)
        }
        PreviewWorkQueue.directories.submit(cancellation: token, work: {
            try FolderSummary.scan(url, cancellation: token, progress: progress.send)
        }, completion: { [weak self] result in
                guard let self, self.generation == id, self.summaryRequest == request else { return }
                self.summaryToken = nil; self.summaryButton.title = "重新统计"
                switch result {
                case .success(let summary):
                    self.showSummary(summary, url: url, scanning: false)
                case .failure(let error):
                    self.onStatistics?(self.lastSummary, false, "统计未完成：" + error.localizedDescription)
                    self.onSummary?("文件夹：\(url.lastPathComponent) · 统计未完成：\(error.localizedDescription)")
                }
        })
    }
    private func showSummary(_ summary: FolderSummary, url: URL, scanning: Bool) {
        lastSummary = summary
        onStatistics?(summary, scanning, scanning ? "正在统计 · 数字持续更新" : (summary.complete ? "已完成统计 · 包含子文件夹与隐藏项" : "部分结果 · " + summary.reason))
        let size = ByteCountFormatter.string(fromByteCount: summary.bytes, countStyle: .file)
        let state = scanning ? "正在统计…" : (summary.complete ? "含隐藏项，递归统计完成" : "统计结束，部分结果：" + summary.reason)
        onSummary?("文件夹：\(url.lastPathComponent) · \(summary.complete ? "总大小" : "已统计大小") \(size) · 包含 \(summary.files + summary.folders + summary.links) 个项目 · \(summary.files) 个文件 · \(summary.folders) 个文件夹\(summary.links > 0 ? " · \(summary.links) 个符号链接" : "") · \(state)")
    }
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let node = item as? Node, !node.directory, !node.more else { return nil }
        let row = FileEntryRow(); row.setAccessibilityRole(.button); row.setAccessibilityLabel("预览 " + node.url.lastPathComponent)
        row.activate = { [weak self] in self?.activate(node) }
        return row
    }
    func outlineViewItemWillExpand(_ notification: Notification) {
        if let node = notification.userInfo?["NSObject"] as? Node, !node.loaded { load(node) }
    }
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let node = outline.item(atRow: outline.selectedRow) as? Node else { return }
        if node.more, let parent = outline.parent(forItem: node) as? Node { load(parent) }
        else if node.directory { if node === root { onOverview?() }; if !node.loaded { load(node) }; outline.expandItem(node) }
        else { activate(node) }
    }
}
