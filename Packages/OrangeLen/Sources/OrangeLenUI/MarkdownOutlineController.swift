import AppKit
import OrangeLenCore

final class MarkdownOutlineController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    struct Item { let title: String; let level: Int; let range: NSRange }
    final class OutlineTable: NSTableView {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    }
    let table = OutlineTable()
    var items: [Item] = []
    var onSelect: ((NSRange) -> Void)?
    private var updating = false
    override func loadView() {
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.documentView = table
        let column = NSTableColumn(identifier: .init("heading")); column.title = "文档大纲"; column.width = 210
        table.addTableColumn(column); table.dataSource = self; table.delegate = self; table.rowHeight = 28
        table.setAccessibilityLabel("Markdown 文档大纲")
        view = scroll
    }
    func show(_ model: TextModel) {
        loadViewIfNeeded(); updating = true; defer { updating = false }
        items = model.blocks.compactMap { block in
            guard case .heading(let level) = block.kind else { return nil }
            return Item(title: (model.display as NSString).substring(with: block.range), level: level, range: block.range)
        }
        table.reloadData()
    }
    func active(_ offset: Int) {
        guard let index = items.lastIndex(where: { $0.range.location <= offset }), table.selectedRow != index else { return }
        updating = true; table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false); table.scrollRowToVisible(index); updating = false
    }
    func numberOfRows(in tableView: NSTableView) -> Int { items.count }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard items.indices.contains(row) else { return nil }
        let item = items[row], field = NSTextField(labelWithString: String(repeating: "  ", count: max(0, item.level - 1)) + item.title)
        field.font = item.level <= 2 ? .systemFont(ofSize: 12, weight: .semibold) : .systemFont(ofSize: 12)
        field.lineBreakMode = .byTruncatingTail; field.toolTip = item.title
        return field
    }
    func tableViewSelectionDidChange(_ notification: Notification) { if !updating, items.indices.contains(table.selectedRow) { onSelect?(items[table.selectedRow].range) } }
}
