import AppKit
import OrangeLenCore

final class JSONController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    var copyFeedback: ((String) -> Void)?
    let outline = NSOutlineView()
    var tree: JSONTree?
    var source = "" as NSString
    override func loadView() {
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true
        let column = NSTableColumn(identifier: .init("json")); column.title = "JSON · 原始值（不转换浮点数）"; column.width = 700
        outline.addTableColumn(column); outline.outlineTableColumn = column
        outline.dataSource = self; outline.delegate = self; outline.rowHeight = 25
        let menu = NSMenu(); menu.addItem(withTitle: "复制路径", action: #selector(copyPath), keyEquivalent: "").target = self
        menu.addItem(withTitle: "复制原始值", action: #selector(copyValue), keyEquivalent: "").target = self
        outline.menu = menu
        scroll.documentView = outline; view = scroll
    }
    func show(_ tree: JSONTree, source: String) { loadViewIfNeeded(); self.tree = tree; self.source = source as NSString; outline.reloadData(); outline.expandItem(tree.root) }
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int { (item as? JSONNode)?.children.count ?? (tree == nil ? 0 : 1) }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any { (item as? JSONNode)?.children[index] ?? tree!.root }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool { !(item as! JSONNode).children.isEmpty }
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let node = item as! JSONNode
        let value = node.children.isEmpty ? String(source.substring(with: node.range).prefix(500)) : "\(node.kind) · \(node.children.count) 项"
        return NSTextField(labelWithString: node.name + ": " + value)
    }
    func current() -> JSONNode? { outline.item(atRow: outline.clickedRow >= 0 ? outline.clickedRow : outline.selectedRow) as? JSONNode }
    @objc func copyPath() { if let node = current() { copy(node.path) } }
    @objc func copyValue() { if let node = current() { copy(source.substring(with: node.range)) } }
    func copy(_ value: String) { Clipboard.write(value, feedback: copyFeedback) }
}
final class TableController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    var copyFeedback: ((String) -> Void)?
    let table = NSTableView()
    var data = TableData(rows: [], partial: false)
    var header = true
    var loaded = 500
    let filter = NSSearchField(), countLabel = NSTextField(labelWithString: "")
    var rowOrder: [Int] = []
    override func loadView() {
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true
        table.dataSource = self; table.delegate = self; table.rowHeight = 27; table.allowsColumnSelection = true
        table.columnAutoresizingStyle = .noColumnAutoresizing
        let menu = NSMenu()
        menu.addItem(withTitle: "复制单元格", action: #selector(copyCell), keyEquivalent: "").target = self
        menu.addItem(withTitle: "复制行（TSV）", action: #selector(copyRow), keyEquivalent: "").target = self
        table.menu = menu; scroll.documentView = table
        filter.placeholderString = "筛选已解析单元格"; filter.delegate = self
        countLabel.font = .systemFont(ofSize: 11); countLabel.textColor = .secondaryLabelColor
        let controls = NSStackView(views: [filter, countLabel]); controls.spacing = 8
        let root = NSStackView(views: [controls, scroll]); root.orientation = .vertical; root.alignment = .leading; root.spacing = 8
        root.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        controls.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -16).isActive = true
        scroll.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -16).isActive = true
        view = root
    }
    func show(_ data: TableData) {
        loadViewIfNeeded(); self.data = data
        for column in table.tableColumns { table.removeTableColumn(column) }
        let count = min(256, data.rows.map(\.count).max() ?? 0)
        for index in 0..<count {
            let column = NSTableColumn(identifier: .init("\(index)")); column.width = 180
            column.title = header && (data.rows.first?.count ?? 0) > index ? data.rows[0][index].value : "\(index + 1)"
            column.sortDescriptorPrototype = NSSortDescriptor(key: String(index), ascending: true)
            table.addTableColumn(column)
        }
        rebuildOrder()
    }
    func resetNavigation() { filter.stringValue = ""; table.sortDescriptors = []; loaded = 500 }
    func rebuildOrder() {
        let start = header ? 1 : 0, query = filter.stringValue
        rowOrder = Array(min(start, data.rows.count)..<data.rows.count).filter { row in query.isEmpty || data.rows[row].contains { $0.value.localizedCaseInsensitiveContains(query) } }
        if let descriptor = table.sortDescriptors.first, let column = Int(descriptor.key ?? "") {
            rowOrder.sort { a, b in
                let left = data.rows[a].indices.contains(column) ? data.rows[a][column].value : "", right = data.rows[b].indices.contains(column) ? data.rows[b][column].value : ""
                let order = left.compare(right, options: [.numeric, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
                if order == .orderedSame { return a < b }
                return descriptor.ascending ? order == .orderedAscending : order == .orderedDescending
            }
        }
        table.reloadData()
        countLabel.stringValue = "显示 \(min(loaded, rowOrder.count)) / \(rowOrder.count) 行" + (data.partial ? " · 部分文件" : "")
    }
    func controlTextDidChange(_ obj: Notification) { loaded = 500; rebuildOrder() }
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) { rebuildOrder() }
    func numberOfRows(in tableView: NSTableView) -> Int { min(loaded, rowOrder.count) }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard rowOrder.indices.contains(row) else { return nil }
        let index = rowOrder[row]
        guard data.rows.indices.contains(index) else { return nil }
        let column = Int(tableColumn?.identifier.rawValue ?? "0") ?? 0; let record = data.rows[index]
        let field = NSTextField(labelWithString: column < record.count ? record[column].value : "")
        field.lineBreakMode = .byWordWrapping; field.maximumNumberOfLines = 5; field.toolTip = field.stringValue; return field
    }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        // AppKit may ask about rows from the previous table while columns are being replaced.
        guard rowOrder.indices.contains(row) else { return 27 }
        let index = rowOrder[row]
        guard data.rows.indices.contains(index) else { return 27 }
        let record = data.rows[index]
        let lines = record.map { min(5, $0.value.components(separatedBy: "\n").count) }.max() ?? 1
        return CGFloat(lines) * 18 + 9
    }
    func reveal(sourceRange: NSRange) {
        guard let row = data.rows.firstIndex(where: { $0.contains { NSIntersectionRange($0.sourceRange, sourceRange).length > 0 } }) else { return }
        if !rowOrder.contains(row) { filter.stringValue = ""; rebuildOrder() }
        guard let index = rowOrder.firstIndex(of: row) else { return }
        loaded = max(loaded, index + 1); rebuildOrder()
        table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false); table.scrollRowToVisible(index)
    }
    @objc func copyCell() {
        let row = table.clickedRow >= 0 ? table.clickedRow : table.selectedRow
        let column = table.clickedColumn >= 0 ? table.clickedColumn : table.selectedColumn
        guard rowOrder.indices.contains(row), column >= 0, data.rows.indices.contains(rowOrder[row]) else { return }
        let record = data.rows[rowOrder[row]]; if column < record.count { copy(record[column].value) }
    }
    @objc func copyRow() {
        let row = table.clickedRow >= 0 ? table.clickedRow : table.selectedRow; guard rowOrder.indices.contains(row), data.rows.indices.contains(rowOrder[row]) else { return }
        copy(data.rows[rowOrder[row]].map { DatabaseDocument.tsvField($0.value) }.joined(separator: "\t"))
    }
    func copy(_ value: String) { Clipboard.write(value, feedback: copyFeedback) }
}
