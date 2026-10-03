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
final class TableController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    var copyFeedback: ((String) -> Void)?
    let table = NSTableView()
    var data = TableData(rows: [], partial: false)
    var header = true
    var loaded = 500
    override func loadView() {
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true
        table.dataSource = self; table.delegate = self; table.rowHeight = 27; table.allowsColumnSelection = true
        table.columnAutoresizingStyle = .noColumnAutoresizing
        let menu = NSMenu()
        menu.addItem(withTitle: "复制单元格", action: #selector(copyCell), keyEquivalent: "").target = self
        menu.addItem(withTitle: "复制行（TSV）", action: #selector(copyRow), keyEquivalent: "").target = self
        table.menu = menu; scroll.documentView = table; view = scroll
    }
    func show(_ data: TableData) {
        loadViewIfNeeded(); self.data = data
        for column in table.tableColumns { table.removeTableColumn(column) }
        let count = min(256, data.rows.map(\.count).max() ?? 0)
        for index in 0..<count {
            let column = NSTableColumn(identifier: .init("\(index)")); column.width = 180
            column.title = header && (data.rows.first?.count ?? 0) > index ? data.rows[0][index].value : "\(index + 1)"
            table.addTableColumn(column)
        }
        table.reloadData()
    }
    func numberOfRows(in tableView: NSTableView) -> Int { min(loaded, max(0, data.rows.count - (header ? 1 : 0))) }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let column = Int(tableColumn?.identifier.rawValue ?? "0") ?? 0; let record = data.rows[row + (header ? 1 : 0)]
        let field = NSTextField(labelWithString: column < record.count ? record[column].value : "")
        field.lineBreakMode = .byWordWrapping; field.maximumNumberOfLines = 5; field.toolTip = field.stringValue; return field
    }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let record = data.rows[row + (header ? 1 : 0)]
        let lines = record.map { min(5, $0.value.components(separatedBy: "\n").count) }.max() ?? 1
        return CGFloat(lines) * 18 + 9
    }
    func reveal(sourceRange: NSRange) {
        guard let row = data.rows.firstIndex(where: { $0.contains { NSIntersectionRange($0.sourceRange, sourceRange).length > 0 } }) else { return }
        loaded = max(loaded, row + 1); table.reloadData()
        let index = row - (header ? 1 : 0)
        if index >= 0 { table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false); table.scrollRowToVisible(index) }
    }
    @objc func copyCell() {
        let row = table.clickedRow >= 0 ? table.clickedRow : table.selectedRow
        let column = table.clickedColumn >= 0 ? table.clickedColumn : table.selectedColumn
        guard row >= 0, column >= 0 else { return }
        let record = data.rows[row + (header ? 1 : 0)]; if column < record.count { copy(record[column].value) }
    }
    @objc func copyRow() {
        let row = table.clickedRow >= 0 ? table.clickedRow : table.selectedRow; guard row >= 0 else { return }
        copy(data.rows[row + (header ? 1 : 0)].map(\.value).joined(separator: "\t"))
    }
    func copy(_ value: String) { Clipboard.write(value, feedback: copyFeedback) }
}
