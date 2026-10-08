import AppKit
import OrangeLenCore

private final class ContainerEntryButton: NSButton {
    var activate: (() -> Void)?
    init(_ title: String, action: @escaping () -> Void) { super.init(frame:.zero); self.title = title; activate = action; isBordered = false; alignment = .left; lineBreakMode = .byTruncatingMiddle; target = self; self.action = #selector(pressed) }
    required init?(coder:NSCoder) { fatalError("init(coder:)") }
    @objc func pressed() { activate?() }
}

/// A native, lazy entry/section browser. Child readers consume memory snapshots, never extract or execute files.
final class CollectionController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    let list = NSTableView()
    let reader = ReaderController()
    let message = NSTextField(wrappingLabelWithString:"正在读取容器…")
    struct Descriptor { let id: String; let title: String }
    var titles: [String] = []
    var entryIDs: [String] = []
    var select: ((Int, Cancellation) throws -> (DocumentSection, MarkdownAssets))?
    var token: Cancellation?
    var id = UUID()
    var url: URL?
    var revision = ""
    struct ReadingState { let section: String?; let position: ReaderController.ReadingPosition? }
    var restoredPosition: ReaderController.ReadingPosition?
    var readingState: ReadingState { .init(section: entryIDs.indices.contains(list.selectedRow) ? entryIDs[list.selectedRow] : nil, position: reader.readingPosition) }
    override func loadView() {
        let split = NSSplitView(); split.isVertical = true; split.dividerStyle = .thin
        let left = NSStackView(); left.orientation = .vertical; left.alignment = .leading
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.documentView = list
        let column = NSTableColumn(identifier:.init("entry")); column.title = "章节 / 条目 / 表 / Cell"; column.width = 230
        list.addTableColumn(column); list.dataSource = self; list.delegate = self; list.rowHeight = 28
        list.setAccessibilityLabel("容器条目列表")
        message.font = .systemFont(ofSize:11)
        left.addArrangedSubview(message); left.addArrangedSubview(scroll)
        message.widthAnchor.constraint(equalTo:left.widthAnchor).isActive = true; scroll.widthAnchor.constraint(equalTo:left.widthAnchor).isActive = true
        split.addArrangedSubview(left); reader.compactPreferred = true; addChild(reader); split.addArrangedSubview(reader.view)
        left.widthAnchor.constraint(greaterThanOrEqualToConstant:180).isActive = true
        left.widthAnchor.constraint(lessThanOrEqualToConstant:320).isActive = true
        let preferred = left.widthAnchor.constraint(equalToConstant:240); preferred.priority = .defaultHigh; preferred.isActive = true
        split.setHoldingPriority(.defaultHigh,forSubviewAt:0)
        reader.updateToolbars(400)
        split.setPosition(240,ofDividerAt:0); view = split
    }
    func open(_ url: URL, root: URL?, restoring state: ReadingState? = nil, completion: @escaping (Error?) -> Void) {
        loadViewIfNeeded(); cancel(); self.url = url; reader.readingGeneration = SettingsStore.shared.readingGeneration
        reader.showMessage("正在读取 \(url.lastPathComponent)…"); list.reloadData()
        let continuousNotebook = url.pathExtension.lowercased() == "ipynb" || (GzipDocument.isPlainStream(url) && !["jsonl","ndjson"].contains(url.deletingPathExtension().pathExtension.lowercased()))
        (view as? NSSplitView)?.arrangedSubviews.first?.isHidden = continuousNotebook
        let current = id; let cancellation = Cancellation(); token = cancellation
        message.stringValue = "本地、只读；按条目加载，不执行内容"
        PreviewWorkQueue.parsing.submit(cancellation: cancellation, work: { () -> (String, [Descriptor], (Int,Cancellation) throws -> (DocumentSection,MarkdownAssets)) in
                let scoped = root?.startAccessingSecurityScopedResource() ?? false
                defer { if scoped { root?.stopAccessingSecurityScopedResource() } }
                var limits = PreviewLimits(); limits.fileBytes = limits.containerBytes
                let snapshot = try AccessBroker.readBytes(url,root:root,limits:limits,cancellation:cancellation)
                let ext = url.pathExtension.lowercased()
                if GzipDocument.isPlainStream(url) {
                    let stream = try GzipDocument.parse(snapshot.data,name:url.lastPathComponent,cancellation:cancellation)
                    let inner = URL(fileURLWithPath:stream.name)
                    var sections: [DocumentSection]
                    if ["jsonl","ndjson"].contains(inner.pathExtension.lowercased()) {
                        sections = try EnhancedDocuments.jsonLines(stream.text,cancellation:cancellation).map {
                            DocumentSection(id:$0.id+".json",title:$0.title,text:$0.text,warning:$0.warning)
                        }
                        sections.append(.init(id:"__source__.txt",title:"完整解压源文",text:stream.text))
                    } else {
                        sections = [.init(id:stream.name,title:stream.name,text:stream.text,markdown:PreviewFormat.detect(inner) == .markdown)]
                    }
                    let immutable = sections
                    return (snapshot.revision,immutable.map { Descriptor(id:$0.id,title:$0.title) },{ index, token in
                        try token.check(); return (immutable[index],.init())
                    })
                }
                if ext == "epub" {
                    let book = try EPUBDocument.parse(snapshot.data,cancellation:cancellation)
                    return (snapshot.revision,book.chapters.map { Descriptor(id:$0.id,title:$0.title) },{ index, token in
                        let section = try book.chapter(book.chapters[index],cancellation:token)
                        let model = try MarkdownModel.parse(section.text,cancellation:token)
                        let assets = try Self.archiveAssets(model,archive:book.archive,base:"root",encrypted:book.encryptedPaths,token:token)
                        return (section,assets)
                    })
                }
                if ["zip","tar","tgz","gz"].contains(ext) {
                    let archive = try ArchiveDocument.parse(snapshot.data,name:url.lastPathComponent,cancellation:cancellation)
                    return (snapshot.revision,archive.entries.map { Descriptor(id:$0.path,title:$0.path + ($0.blocked == nil ? "" : " · 受限")) },{ index, token in
                        let entry = archive.entries[index]
                        if entry.directory || entry.blocked != nil {
                            return (.init(id:entry.path,title:entry.path,text:entry.blocked ?? "目录条目；在列表中选择子文件",warning:"不解压到磁盘"),.init())
                        }
                        let data = try archive.read(entry,cancellation:token)
                        let fake = URL(fileURLWithPath:entry.path)
                        if ImagePreview.supports(fake) {
                            let image = try ImagePreview.decode(data,cancellation:token)
                            var assets = MarkdownAssets(); assets.images[0] = image.image
                            return (.init(id:entry.path,title:entry.path,text:"![归档图片](image.png)",markdown:true),assets)
                        }
                        guard ReadableFormat.isText(fake) else {
                            return (.init(id:entry.path,title:entry.path,text:"此条目类型尚不支持。\n\(entry.size) bytes\n不会尝试执行或强制文本解码。"),.init())
                        }
                        let source = try AccessBroker.decode(data).0
                        let markdown = PreviewFormat.detect(fake) == .markdown
                        let assets = markdown ? try Self.archiveAssets(MarkdownModel.parse(source,cancellation:token),archive:archive,base:entry.path,encrypted:[],token:token) : MarkdownAssets()
                        return (.init(id:entry.path,title:entry.path,text:source,markdown:markdown,warning:"单条目有界预览，不解压到磁盘"),assets)
                    })
                }
                if ["sqlite","sqlite3","db"].contains(ext) {
                    let database = try DatabaseDocument(data:snapshot.data,cancellation:cancellation)
                    return (snapshot.revision,database.tableNames.map { Descriptor(id:$0,title:$0) },{ index, token in
                        let name = database.tableNames[index], rows = try database.rows(name,cancellation:token)
                        let source = rows.map { $0.map { "\"" + $0.replacingOccurrences(of:"\"",with:"\"\"") + "\"" }.joined(separator:",") }.joined(separator:"\n")
                        return (.init(id:name,title:name,text:source,warning:"只读内存快照 · 最多 500 行 · BLOB 仅字节数 · 不提供 SQL 执行"),.init())
                    })
                }
                guard snapshot.data.count <= PreviewLimits().fileBytes else { throw PreviewError.limit("文档最大 5 MiB") }
                let source = try AccessBroker.decode(snapshot.data).0
                var sections: [DocumentSection]
                if ext == "har" { sections = try EnhancedDocuments.har(source,cancellation:cancellation) }
                else if ["openapi.json","swagger.json"].contains(url.lastPathComponent.lowercased()) { sections = try EnhancedDocuments.openAPI(source,cancellation:cancellation) }
                else if ext == "jsonl" || ext == "ndjson" { sections = try EnhancedDocuments.jsonLines(source,cancellation:cancellation) }
                else if ext == "ipynb" {
                    let content = try Self.continuousNotebook(source, title:url.lastPathComponent, token:cancellation)
                    return (snapshot.revision,[Descriptor(id:content.0.id,title:content.0.title)],{ _, token in
                        try token.check(); return content
                    })
                }
                else { sections = try EnhancedDocuments.diff(source,cancellation:cancellation) }
                sections.append(.init(id:"__source__",title:"完整原始源文",text:source,warning:"容器/记录解析不改变此原始源文"))
                let immutable = sections
                return (snapshot.revision,immutable.map { Descriptor(id:$0.id,title:$0.title) },{ index, token in
                    var assets = MarkdownAssets()
                    if let data = immutable[index].image { assets.images[0] = try ImagePreview.decode(data,cancellation:token,maxPixelSize:1200,maxSourcePixels:25_000_000).image }
                    return (immutable[index],assets)
                })
        }, completion: { [weak self] result in
                guard let self, self.id == current else { completion(CancellationError()); return }
                switch result {
                case .success(let loaded):
                    self.revision = loaded.0; self.titles = loaded.1.map(\.title); self.entryIDs = loaded.1.map(\.id); self.select = loaded.2; self.list.reloadData()
                    self.message.stringValue = "\(loaded.1.count) 个条目 · 仅选择项加载"
                    if continuousNotebook {
                        do {
                            let content = try loaded.2(0,cancellation)
                            self.reader.openMemory(content.0,origin:url,revision:loaded.0,assets:content.1,restoring:state?.position)
                        } catch { completion(error); return }
                    } else if !self.titles.isEmpty {
                        let selected = (state?.section ?? SettingsStore.shared.restoreSection(url,revision:loaded.0)).flatMap { self.entryIDs.firstIndex(of:$0) } ?? 0
                        self.restoredPosition = state?.section == self.entryIDs[selected] ? state?.position : nil
                        self.list.selectRowIndexes(IndexSet(integer:selected),byExtendingSelection:false)
                    }
                    else { self.message.stringValue = "没有可预览条目"; self.reader.showMessage(url.lastPathComponent + " · 没有可预览条目") }
                    completion(nil)
                case .failure(let error):
                    self.message.stringValue = error.localizedDescription
                    self.reader.showMessage(url.lastPathComponent + " · " + error.localizedDescription + "\n可使用上方重载重试，或选择其他文件。")
                    completion(error)
                }
        })
    }
    /// One scrollable document keeps each stored output beside its input cell.
    static func continuousNotebook(_ source: String, title: String, token: Cancellation) throws -> (DocumentSection, MarkdownAssets) {
        let sections = try EnhancedDocuments.notebook(source,cancellation:token)
        var chunks: [String] = [], images: [String:Data] = [:]
        func fenced(_ value: String) -> String {
            // Choose a delimiter that cannot be closed by notebook source/output.
            let longest = value.split(omittingEmptySubsequences:false,whereSeparator:{ $0 != "`" }).map(\.count).max() ?? 0
            let fence = String(repeating:"`",count:max(3,longest+1))
            return fence + "\n" + value + "\n" + fence
        }
        for section in sections {
            try token.check()
            if section.id.contains("-output-") {
                if let image = section.image {
                    let path = "orangelen-notebook-" + section.id + ".png"
                    images[path] = image
                    let detail = String(section.text.dropFirst("![已有 PNG 输出](output.png)\n\n".count))
                    chunks.append("![已有输出](" + path + ")\n\n" + fenced(detail))
                } else { chunks.append(fenced(section.text)) }
            } else if section.markdown { chunks.append(section.text) }
            else { chunks.append("---\n\n" + fenced(section.text)) }
        }
        let body = chunks.joined(separator:"\n\n")
        let model = try MarkdownModel.parse(body,cancellation:token)
        var assets = MarkdownAssets(), pixels = 0
        for image in model.images {
            try token.check()
            guard let data = images[image.destination] else { continue }
            do {
                guard pixels < 8_000_000 else { throw PreviewError.limit("Notebook 总图片像素") }
                let decoded = try ImagePreview.decode(data,cancellation:token,maxPixelSize:1200,maxSourcePixels:25_000_000)
                let count = decoded.image.width * decoded.image.height
                guard pixels + count <= 8_000_000 else { throw PreviewError.limit("Notebook 总图片像素") }
                pixels += count; assets.images[image.range.location] = decoded.image
            } catch is CancellationError { throw CancellationError() }
            catch { assets.failures[image.range.location] = "输出图片不可显示或超过预览预算" }
        }
        return (.init(id:"notebook-continuous",title:title,text:body,markdown:true),assets)
    }
    static func archiveAssets(_ model: TextModel, archive: ArchiveDocument, base: String, encrypted: Set<String>, token: Cancellation) throws -> MarkdownAssets {
        var assets = MarkdownAssets(); var bytes = 0; var pixels = 0
        for (index,image) in model.images.enumerated() {
            try token.check()
            guard index < 8, let path = EPUBDocument.resolve(image.destination,base:base), !encrypted.contains(path), let entry = archive.entry(path), bytes <= 15*1024*1024 else { assets.failures[image.range.location] = "容器图片受限或缺失"; continue }
            do {
                let data = try archive.read(entry,cancellation:token); bytes += data.count
                let decoded = try ImagePreview.decode(data,cancellation:token,maxPixelSize:1200,maxSourcePixels:25_000_000)
                pixels += decoded.image.width * decoded.image.height
                guard pixels <= 8_000_000 else { throw PreviewError.limit("容器图片像素") }
                assets.images[image.range.location] = decoded.image
            } catch is CancellationError { throw CancellationError() }
            catch { assets.failures[image.range.location] = "容器图片不可安全显示" }
        }
        return assets
    }
    func numberOfRows(in tableView: NSTableView) -> Int { titles.count }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        ContainerEntryButton(titles[row]) { [weak self] in
            guard let self else { return }
            if self.list.selectedRow != row { self.list.selectRowIndexes(IndexSet(integer:row),byExtendingSelection:false) }
            else { self.loadSelection() }
        }
    }
    func tableViewSelectionDidChange(_ notification: Notification) { loadSelection() }
    func loadSelection() {
        let index = list.selectedRow
        guard index >= 0, index < titles.count, let select, let url else { return }
        token?.cancel(); let token = Cancellation(); self.token = token; let current = UUID(); id = current
        let position = restoredPosition; restoredPosition = nil
        reader.savePosition(); reader.cancelPending(); reader.showMessage("正在读取 \(titles[index])…"); message.stringValue = "加载选中条目…"
        PreviewWorkQueue.parsing.submit(cancellation: token, work: {
            return try { try select(index,token) }()
        }, completion: { [weak self] result in
                guard let self, self.id == current else { return }
                switch result {
                case .success(let content):
                    self.reader.openMemory(content.0,origin:url,revision:self.revision,assets:content.1,restoring:position)
                    SettingsStore.shared.remember(url,revision:self.revision,offset:0,section:content.0.id, generation: self.reader.readingGeneration)
                    self.message.stringValue = "\(self.titles.count) 项 · \(content.0.warning)"
                case .failure(let error): self.reader.showMessage(error.localizedDescription); self.message.stringValue = "选中条目未完成；可选择其他条目"
                }
        })
    }
    func cancel() { token?.cancel(); token = nil; id = UUID(); reader.close(); titles = []; entryIDs = []; select = nil }
}
