import AppKit
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

final class FolderController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSSearchFieldDelegate {
    final class Node {
        let url: URL
        let directory: Bool
        var children: [Node] = []
        var loaded = false
        var loading = false
        var nextOffset: Int?
        var more = false
        var detail = ""
        init(_ url: URL, directory: Bool) { self.url = url; self.directory = directory }
    }
    let outline = NSOutlineView()
    let filter = NSSearchField()
    let ignored = NSButton(checkboxWithTitle: "显示忽略项", target: nil, action: nil)
    let status = NSTextField(wrappingLabelWithString: "仅扫描已展开目录")
    var root: Node?
    var tasks: [Cancellation] = []
    var generation = UUID()
    var onSelect: ((URL) -> Void)?
    var onSummary: ((String) -> Void)?
    var selectedURL: URL?
    override func loadView() {
        let stack = NSStackView(); stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        filter.placeholderString = "文件名筛选（已加载项）"; filter.delegate = self
        ignored.target = self; ignored.action = #selector(resetIgnored)
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true
        let column = NSTableColumn(identifier: .init("name")); column.title = "目录"; column.width = 235
        outline.addTableColumn(column); outline.outlineTableColumn = column; outline.headerView = nil
        outline.dataSource = self; outline.delegate = self; outline.rowHeight = 25
        outline.selectionHighlightStyle = .regular
        outline.setAccessibilityLabel("项目目录树")
        scroll.documentView = outline
        status.font = .systemFont(ofSize: 11); status.textColor = .secondaryLabelColor
        for child in [filter, ignored, scroll, status] { stack.addArrangedSubview(child); child.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -16).isActive = true }
        view = stack
    }
    func open(_ url: URL) {
        loadViewIfNeeded(); cancel(); selectedURL = nil; root = Node(url, directory: true)
        summarize(url)
        outline.reloadData(); if let root { load(root); outline.expandItem(root) }
    }
    func cancel() { generation = UUID(); tasks.forEach { $0.cancel() }; tasks = [] }
    @objc func resetIgnored() { if let root { open(root.url) } }
    func load(_ node: Node) {
        guard !node.loading, let root else { return }
        node.loading = true
        let token = Cancellation(); tasks.append(token); let current = generation
        let show = ignored.state == .on; let offset = node.nextOffset ?? 0; let ignoredNames = Set(SettingsStore.shared.load().ignored)
        status.stringValue = "正在读取直接子项…"
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Result { try FolderLoader.page(node.url, root: root.url, offset: offset, showIgnored: show, ignored: ignoredNames, cancellation: token) }
            DispatchQueue.main.async {
                guard let self, self.generation == current else { return }
                self.tasks.removeAll { $0 === token }
                node.loading = false; node.loaded = true
                switch result {
                case .success(let page):
                    node.children.removeAll { $0.more }
                    node.children += page.entries.map { entry in
                        let child = Node(entry.url, directory: entry.directory && !entry.symbolicLink && !entry.package && !entry.unavailable)
                        child.detail = entry.symbolicLink ? " ↗（不跟随）" : entry.unavailable ? " ☁ 未下载" : entry.package ? "（文件包）" : ""
                        return child
                    }
                    node.nextOffset = page.nextOffset
                    if page.nextOffset != nil { let more = Node(node.url, directory: false); more.more = true; node.children.append(more) }
                    self.status.stringValue = "当前目录已扫描 \(page.scanned) 项\(page.nextOffset == nil ? "（完成）" : "（部分）")"
                case .failure(let error): self.status.stringValue = error.localizedDescription
                }
                self.outline.reloadItem(node, reloadChildren: true); self.outline.expandItem(node)
            }
        }
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
            let cell = NSTableCellView()
            let button = FileEntryButton(title: node.url.lastPathComponent + node.detail) { [weak self] in self?.activate(node) }
            button.setAccessibilityLabel("预览 " + node.url.lastPathComponent)
            button.translatesAutoresizingMaskIntoConstraints = false; cell.addSubview(button)
            NSLayoutConstraint.activate([button.leadingAnchor.constraint(equalTo: cell.leadingAnchor), button.trailingAnchor.constraint(equalTo: cell.trailingAnchor), button.topAnchor.constraint(equalTo: cell.topAnchor), button.bottomAnchor.constraint(equalTo: cell.bottomAnchor)])
            return cell
        }
        let label = NSTextField(labelWithString: node.more ? "继续加载 500 项…" : (node.directory ? "▸ " : "") + node.url.lastPathComponent + node.detail)
        label.lineBreakMode = .byTruncatingMiddle; return label
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
        let token = Cancellation(); tasks.append(token); let id = generation
        onSummary?("文件夹：\(url.lastPathComponent) · 正在统计大小和项目数量…")
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let result = Result { try FolderSummary.scan(url, cancellation: token) }
            DispatchQueue.main.async {
                guard let self, self.generation == id else { return }
                self.tasks.removeAll { $0 === token }
                switch result {
                case .success(let summary):
                    let size = ByteCountFormatter.string(fromByteCount: summary.bytes, countStyle: .file)
                    self.onSummary?("文件夹：\(url.lastPathComponent) · \(summary.complete ? "总大小" : "已统计大小") \(size) · \(summary.files) 个文件 · \(summary.folders) 个文件夹\(summary.links > 0 ? " · \(summary.links) 个符号链接" : "") · \(summary.complete ? "含隐藏项，递归统计完成" : "部分统计：" + summary.reason)")
                case .failure(let error): self.onSummary?("文件夹：\(url.lastPathComponent) · 统计未完成：\(error.localizedDescription)")
                }
            }
        }
    }
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let node = item as? Node, !node.directory, !node.more else { return nil }
        let row = FileEntryRow()
        row.activate = { [weak self] in self?.activate(node) }
        return row
    }
    func outlineViewItemWillExpand(_ notification: Notification) {
        if let node = notification.userInfo?["NSObject"] as? Node, !node.loaded { load(node) }
    }
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let node = outline.item(atRow: outline.selectedRow) as? Node else { return }
        if node.more, let parent = outline.parent(forItem: node) as? Node { load(parent) }
        else if node.directory { if !node.loaded { load(node) }; outline.expandItem(node) }
        else { activate(node) }
    }
}
