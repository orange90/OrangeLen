import AppKit
import OrangeLenCore

private final class ArchiveEntryRow: NSTableRowView {
    var activate: (() -> Void)?
    override func accessibilityPerformPress() -> Bool { guard let activate else { return false }; activate(); return true }
}
private final class ArchiveEntryButton: NSButton {
    var activate: (() -> Void)?
    init(_ title: String, activate: @escaping () -> Void) {
        super.init(frame: .zero); self.title = title; self.activate = activate
        isBordered = false; alignment = .left; lineBreakMode = .byTruncatingMiddle
        target = self; action = #selector(pressed)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:)") }
    @objc func pressed() { activate?() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
final class ArchiveController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSSearchFieldDelegate {
    final class Node {
        let path: String
        var entry: ArchiveEntry?
        var children: [Node] = []
        init(_ path: String) { self.path = path }
        var name: String { (path as NSString).lastPathComponent }
        var size = 0
    }
    let outline = NSOutlineView(), reader = ReaderController(), filter = NSSearchField(), sort = NSPopUpButton()
    let info = NSTextField(labelWithString: "")
    var roots: [Node] = [], archive: ArchiveDocument?, origin: URL?, revision = ""
    var token: Cancellation?, generation = UUID()
    struct ReadingState { let path: String?; let filter: String; let sort: Int; let position: ReaderController.ReadingPosition? }
    var restoredPosition: ReaderController.ReadingPosition?
    var readingState: ReadingState { .init(path: (outline.item(atRow: outline.selectedRow) as? Node)?.path, filter: filter.stringValue, sort: sort.indexOfSelectedItem, position: reader.readingPosition) }
    override func loadView() {
        let split = NSSplitView(frame: NSRect(x: 0, y: 0, width: 1000, height: 720)); split.isVertical = true; split.dividerStyle = .thin
        let left = NSStackView(); left.orientation = .vertical; left.alignment = .leading; left.spacing = 8
        left.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        filter.placeholderString = "筛选归档完整路径"; filter.delegate = self
        sort.addItems(withTitles: ["名称 A–Z", "名称 Z–A", "大小从大到小", "大小从小到大"]); sort.target = self; sort.action = #selector(sortChanged)
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true; scroll.documentView = outline
        let name = NSTableColumn(identifier: .init("name")); name.title = "归档目录"; name.width = 235; name.minWidth = 140
        let size = NSTableColumn(identifier: .init("size")); size.title = "展开大小"; size.width = 85; size.minWidth = 85; size.maxWidth = 85
        outline.addTableColumn(name); outline.addTableColumn(size); outline.outlineTableColumn = name
        outline.dataSource = self; outline.delegate = self; outline.rowHeight = 27; outline.setAccessibilityLabel("归档目录树")
        outline.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle; outline.autoresizingMask = [.width]
        outline.autoresizesOutlineColumn = false
        info.font = .systemFont(ofSize: 11); info.textColor = .secondaryLabelColor
        for child in [filter, sort, scroll, info] { left.addArrangedSubview(child); child.widthAnchor.constraint(equalTo: left.widthAnchor, constant: -20).isActive = true }
        split.addArrangedSubview(left); addChild(reader); reader.compactPreferred = true; split.addArrangedSubview(reader.view)
        let width = left.widthAnchor.constraint(equalToConstant: 320); width.priority = .defaultHigh; width.isActive = true
        left.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        split.setHoldingPriority(.defaultHigh, forSubviewAt: 0); split.setHoldingPriority(.defaultLow, forSubviewAt: 1)
        view = split; split.setPosition(320, ofDividerAt: 0)
    }
    override func viewDidLayout() {
        super.viewDidLayout()
        if let width = outline.enclosingScrollView?.contentSize.width, width > 0 {
            outline.tableColumns.last?.isHidden = width < 250
            outline.tableColumns.first?.width = max(140, width - (width < 250 ? 0 : 85))
        }
    }
    func open(_ archive: ArchiveDocument, origin: URL, revision: String, restoring state: ReadingState? = nil) throws {
        loadViewIfNeeded(); cancel(); self.archive = archive; self.origin = origin; self.revision = revision
        roots = try Self.tree(archive.entries); filter.stringValue = state?.filter ?? ""; sort.selectItem(at: state?.sort ?? 0); sortChanged()
        let size = archive.entries.filter { !$0.directory }.reduce(0) { $0 + $1.size }
        info.stringValue = "\(archive.entries.count) 项 · \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)) · 不解压到磁盘"
        reader.showMessage("选择左侧文件，在此阅读归档内容。\n可筛选完整路径或按大小排序。")
        outline.expandItem(nil, expandChildren: true)
        restoredPosition = state?.position
        if let path = state?.path, let row = (0..<outline.numberOfRows).first(where: { (outline.item(atRow: $0) as? Node)?.path == path }) {
            outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }
    static func tree(_ entries: [ArchiveEntry]) throws -> [Node] {
        let root = Node(""); var paths: [String: Node] = ["": root]
        for entry in entries {
            guard entry.path.split(separator: "/").count <= 64 else { throw PreviewError.limit("归档目录深度") }
            var prefix = "", parent = root
            for component in entry.path.split(separator: "/") {
                prefix = prefix.isEmpty ? String(component) : prefix + "/" + component
                let node: Node
                if let existing = paths[prefix] { node = existing }
                else { guard paths.count < 20_000 else { throw PreviewError.limit("归档目录节点数") }; node = Node(prefix); parent.children.append(node); paths[prefix] = node }
                parent = node
            }
            parent.entry = entry
        }
        func total(_ node: Node) -> Int {
            node.size = node.entry?.directory == false ? node.entry!.size : node.children.reduce(0) { $0 + total($1) }
            return node.size
        }
        _ = total(root)
        return root.children
    }
    func visible(_ nodes: [Node]) -> [Node] {
        let query = filter.stringValue
        func matches(_ node: Node) -> Bool { query.isEmpty || node.path.localizedCaseInsensitiveContains(query) || node.children.contains(where: matches) }
        return nodes.filter(matches)
    }
    @objc func sortChanged() {
        let index = sort.indexOfSelectedItem
        func order(_ nodes: inout [Node]) {
            nodes.sort {
                if ($0.children.isEmpty) != ($1.children.isEmpty), index < 2 { return !$0.children.isEmpty }
                if index >= 2, $0.size != $1.size { return index == 2 ? $0.size > $1.size : $0.size < $1.size }
                let comparison = $0.name.localizedStandardCompare($1.name)
                return index == 1 ? comparison == .orderedDescending : comparison == .orderedAscending
            }
            for node in nodes { order(&node.children) }
        }
        order(&roots); outline.reloadData()
    }
    func controlTextDidChange(_ obj: Notification) { outline.reloadData(); if !filter.stringValue.isEmpty { outline.expandItem(nil, expandChildren: true) } }
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int { visible((item as? Node)?.children ?? roots).count }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any { visible((item as? Node)?.children ?? roots)[index] }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool { !(item as! Node).children.isEmpty }
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let node = item as! Node
        if tableColumn?.identifier.rawValue == "name", node.entry?.directory == false {
            let button = ArchiveEntryButton(node.name + (node.entry?.blocked == nil ? "" : " · 受限")) { [weak self] in self?.activate(node) }
            button.setAccessibilityLabel("预览归档成员 " + node.path); return button
        }
        let cell = NSTableCellView()
        let field = NSTextField(labelWithString: tableColumn?.identifier.rawValue == "size" ? ByteCountFormatter.string(fromByteCount: Int64(node.size), countStyle: .file) : node.name + (node.entry?.blocked == nil ? "" : " · 受限"))
        field.lineBreakMode = .byTruncatingMiddle; field.toolTip = node.path
        field.translatesAutoresizingMaskIntoConstraints = false; cell.addSubview(field); cell.textField = field
        NSLayoutConstraint.activate([field.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 3), field.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -3), field.centerYAnchor.constraint(equalTo: cell.centerYAnchor)])
        return cell
    }
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let node = item as? Node, node.entry?.directory == false else { return nil }
        let row = ArchiveEntryRow(); row.setAccessibilityRole(.button); row.setAccessibilityLabel("预览归档成员 " + node.path)
        row.activate = { [weak self] in self?.activate(node) }; return row
    }
    func activate(_ node: Node) {
        let row = outline.row(forItem: node)
        guard row >= 0 else { return }
        if outline.selectedRow != row { outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false) }
        else { outlineViewSelectionDidChange(Notification(name: NSOutlineView.selectionDidChangeNotification)) }
    }
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let node = outline.item(atRow: outline.selectedRow) as? Node, let entry = node.entry, !entry.directory, let archive, let origin else { return }
        token?.cancel(); let token = Cancellation(); self.token = token; let id = UUID(); generation = id
        let position = restoredPosition; restoredPosition = nil
        reader.cancelPending(); reader.showMessage("加载 \(entry.path)…")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Result { () -> (DocumentSection, MarkdownAssets) in
                let data = try archive.read(entry, cancellation: token), fake = URL(fileURLWithPath: entry.path)
                if ImagePreview.supports(fake) {
                    var assets = MarkdownAssets(); assets.images[0] = try ImagePreview.decode(data, cancellation: token).image
                    return (.init(id: entry.path, title: entry.path, text: "![归档图片](image.png)", markdown: true), assets)
                }
                guard ReadableFormat.isText(fake) else { return (.init(id: entry.path, title: entry.path, text: "此格式尚不支持正文预览 · \(entry.size) bytes"), .init()) }
                let source = try AccessBroker.decode(data).0, markdown = PreviewFormat.detect(fake) == .markdown
                let assets = markdown ? try CollectionController.archiveAssets(MarkdownModel.parse(source, cancellation: token), archive: archive, base: entry.path, encrypted: [], token: token) : .init()
                return (.init(id: entry.path, title: entry.path, text: source, markdown: markdown, warning: "归档成员 · 只读内存"), assets)
            }
            DispatchQueue.main.async {
                guard let self, self.generation == id else { return }
                switch result {
                case .success(let content): self.reader.openMemory(content.0, origin: origin, revision: self.revision, assets: content.1, restoring: position)
                case .failure(let error): self.reader.showMessage(error.localizedDescription)
                }
            }
        }
    }
    func cancel() { token?.cancel(); generation = UUID(); reader.close(); archive = nil; roots = [] }
}
