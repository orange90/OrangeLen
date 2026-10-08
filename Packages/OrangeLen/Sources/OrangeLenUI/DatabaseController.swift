import AppKit
import OrangeLenCore

/// Paginated database view uses SQLite's native ordering (numbers stay numbers).
final class DatabaseController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    let table = NSTableView(), selector = NSPopUpButton()
    let previous = NSButton(title: "上一页", target: nil, action: nil)
    let next = NSButton(title: "下一页", target: nil, action: nil)
    let status = NSTextField(labelWithString: ""), metadata = NSTextField(wrappingLabelWithString: "")
    var database: DatabaseDocument?
    var page: DatabaseDocument.Page?
    var offset = 0, sortColumn: Int?, ascending = true
    var token: Cancellation?, generation = UUID()
    var copyFeedback: ((String) -> Void)?
    struct ReadingState { let name: String?; let offset: Int; let sortColumn: Int?; let ascending: Bool }
    var readingState: ReadingState { .init(name: selector.titleOfSelectedItem, offset: offset, sortColumn: sortColumn, ascending: ascending) }
    override func loadView() {
        let root = NSStackView(); root.orientation = .vertical; root.alignment = .leading; root.spacing = 8
        root.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        let controls = NSStackView(views: [selector, previous, next, status]); controls.spacing = 8
        selector.target = self; selector.action = #selector(selectTable)
        previous.target = self; previous.action = #selector(previousPage)
        next.target = self; next.action = #selector(nextPage)
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true; scroll.documentView = table
        table.dataSource = self; table.delegate = self; table.rowHeight = 27; table.columnAutoresizingStyle = .noColumnAutoresizing
        table.setAccessibilityLabel("SQLite 分页数据表")
        let menu = NSMenu()
        menu.addItem(withTitle: "复制单元格", action: #selector(copyCell), keyEquivalent: "").target = self
        menu.addItem(withTitle: "复制选中行（TSV）", action: #selector(copyRows), keyEquivalent: "").target = self
        table.menu = menu
        metadata.font = .systemFont(ofSize: 11); metadata.textColor = .secondaryLabelColor
        for child in [controls, scroll, metadata] { root.addArrangedSubview(child); child.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -24).isActive = true }
        view = root
    }
    func open(_ database: DatabaseDocument, selected: String? = nil, restoring state: ReadingState? = nil) {
        loadViewIfNeeded(); self.database = database
        selector.removeAllItems(); selector.addItems(withTitles: database.tableNames)
        let chosen = state?.name ?? selected
        if let chosen, database.tableNames.contains(chosen) { selector.selectItem(withTitle: chosen) }
        if let state, selector.titleOfSelectedItem == state.name {
            offset = state.offset; sortColumn = state.sortColumn; ascending = state.ascending
            loadPage()
        } else { selectTable() }
    }
    @objc func selectTable() { offset = 0; sortColumn = nil; ascending = true; table.sortDescriptors = []; loadPage() }
    @objc func previousPage() { offset = max(0, offset - 500); loadPage() }
    @objc func nextPage() { guard page?.hasNext == true else { return }; offset += 500; loadPage() }
    func loadPage() {
        guard let database, let name = selector.titleOfSelectedItem else { return }
        token?.cancel(); let token = Cancellation(); self.token = token
        let id = UUID(); generation = id
        let offset = offset, sort = sortColumn, ascending = ascending
        previous.isEnabled = false; next.isEnabled = false; table.isEnabled = false
        status.stringValue = "读取中…"
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Result {
                let columns = try database.page(name, pageSize: 1, cancellation: token).columns
                let validSort = sort.flatMap { columns.indices.contains($0) ? $0 : nil }
                return try database.page(name, offset: offset, sortColumn: validSort, ascending: ascending, cancellation: token)
            }
            DispatchQueue.main.async {
                guard let self, self.generation == id else { return }
                self.table.isEnabled = true
                switch result {
                case .success(let page):
                    if page.rows.isEmpty && offset > 0 { self.offset = 0; self.loadPage(); return }
                    self.page = page
                    if let index = self.sortColumn, !page.columns.indices.contains(index) { self.sortColumn = nil; self.table.sortDescriptors = [] }
                    if self.table.tableColumns.map(\.title) != page.columns.map(\.name) {
                        for column in self.table.tableColumns { self.table.removeTableColumn(column) }
                        for (i, column) in page.columns.enumerated() {
                            let item = NSTableColumn(identifier: .init(String(i))); item.title = column.name; item.width = 180
                            item.sortDescriptorPrototype = NSSortDescriptor(key: String(i), ascending: true)
                            self.table.addTableColumn(item)
                        }
                    }
                    self.table.reloadData(); self.table.scrollRowToVisible(0)
                    self.previous.isEnabled = offset > 0; self.next.isEnabled = page.hasNext
                    self.status.stringValue = page.rows.isEmpty ? "此页无记录" : "第 \(offset + 1)–\(offset + page.rows.count) 行" + (page.hasNext ? " · 后面还有数据" : " · 已到末尾")
                    self.metadata.stringValue = page.columns.map { $0.name + ": " + ($0.declaredType.isEmpty ? "未声明类型" : $0.declaredType) + ($0.primaryKey > 0 ? " · 主键" : "") + ($0.notNull ? " · NOT NULL" : "") }.joined(separator: "   |   ")
                case .failure(let error):
                    self.status.stringValue = error.localizedDescription
                    self.previous.isEnabled = offset > 0
                }
            }
        }
    }
    func numberOfRows(in tableView: NSTableView) -> Int { page?.rows.count ?? 0 }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let page, page.rows.indices.contains(row), let column = Int(tableColumn?.identifier.rawValue ?? ""), page.rows[row].indices.contains(column) else { return nil }
        let value = page.rows[row][column]
        let field = NSTextField(labelWithString: value); field.lineBreakMode = .byTruncatingTail; field.toolTip = value
        return field
    }
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let descriptor = tableView.sortDescriptors.first, let column = Int(descriptor.key ?? "") else { return }
        sortColumn = column; ascending = descriptor.ascending; offset = 0; loadPage()
    }
    @objc func copyCell() {
        let row = table.clickedRow >= 0 ? table.clickedRow : table.selectedRow, column = table.clickedColumn
        guard let page, page.rows.indices.contains(row), page.rows[row].indices.contains(column) else { return }
        Clipboard.write(page.rows[row][column], feedback: copyFeedback)
    }
    @objc func copyRows() {
        guard let page else { return }
        let selected = table.selectedRowIndexes.isEmpty && table.clickedRow >= 0 ? IndexSet(integer: table.clickedRow) : table.selectedRowIndexes
        let rows = selected.filter { page.rows.indices.contains($0) }.map { page.rows[$0].joined(separator: "\t") }
        if !rows.isEmpty { Clipboard.write(rows.joined(separator: "\n"), feedback: copyFeedback) }
    }
    func cancel() { token?.cancel(); generation = UUID(); database = nil; page = nil }
}
