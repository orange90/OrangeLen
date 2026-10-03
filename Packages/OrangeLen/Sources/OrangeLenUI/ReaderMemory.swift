import AppKit
import OrangeLenCore

extension ReaderController {
    func showMessage(_ value: String) {
        source = nil; rendered = nil; mode.isEnabled = false; headings.isEnabled = false
        text.model = .plain(value); text.string = value; text.sentences = []; text.focusEnabled = false
        scroll.rulersVisible = false; showContent(scroll)
    }
    func openMemory(_ section: DocumentSection, origin: URL, revision: String, assets: MarkdownAssets) {
        loadViewIfNeeded(); savePosition(); cancelPending(); virtualDocument = true; virtualTitle = section.title
        // A synthetic identity is only hashed for local reading state; it is never opened on disk.
        currentURL = origin.appendingPathComponent(section.id)
        let ext = origin.pathExtension.lowercased()
        if section.markdown { format = .markdown }
        else if section.id.hasSuffix(".csv") || ["sqlite","db","sqlite3"].contains(ext) { format = .csv }
        else if ["jsonl","ndjson"].contains(ext) || section.id.hasSuffix(".json") { format = .json }
        else if ["diff","patch"].contains(ext) || ["diff","patch"].contains(URL(fileURLWithPath:section.id).pathExtension) { format = .diff }
        else { format = .code }

        let snapshot = SourceSnapshot(text:section.text,encoding:"容器内存",byteCount:section.text.utf8.count,revision:revision+":"+section.id)
        source = nil; rendered = nil; text.clearDecoration(); text.sentences = []; text.focusEnabled = false
        let token = Cancellation(); cancellation = token; let current = generation; let detected = format
        text.string = "正在解析选中内容…"; showContent(scroll)
        DispatchQueue.global(qos:.userInitiated).async { [weak self] in
            var markdown: TextModel?; var tree: JSONTree?; var table: TableData?; var warning = section.warning
            do {
                if section.markdown { markdown = try MarkdownModel.parse(section.text,cancellation:token) }
                else if detected == .json { tree = try JSONParser.parse(section.text,cancellation:token) }
                else if detected == .csv { table = try CSVParser.parse(section.text,cancellation:token) }
                try token.check()
            } catch is CancellationError { return }
            catch { warning += " · " + error.localizedDescription }
            DispatchQueue.main.async {
                guard let self, self.generation == current else { return }
                self.source = snapshot; self.markdownAssets = assets; self.jsonTree = tree; self.tableData = table; self.rendered = markdown; self.parseWarning = warning
                self.mode.selectedSegment = 0; self.text.anchor = 0; self.present(); self.startRichRendering()
                self.remoteBar.isHidden = true; self.remoteHeight.constant = 0
                if let offset = SettingsStore.shared.restore(self.currentURL!,revision:snapshot.revision) {
                    let display = self.text.model.displayOffset(forSource:offset); self.text.sentence(at:display); self.text.scrollRangeToVisible(.init(location:min(display,self.text.string.utf16.count),length:0))
                } else { self.scroll.contentView.scroll(to:.zero) }
            }
        }
    }
}

extension ReaderController {
    func loadProjectOverview(_ root: URL) {
        let token = Cancellation(); cancellation = token; let current = generation
        DispatchQueue.global(qos:.userInitiated).async { [weak self] in
            let result = Result { try ProjectOverview.read(root,cancellation:token) }
            DispatchQueue.main.async {
                guard let self, self.generation == current, self.currentURL == nil else { return }
                if let content = try? result.get() {
                    self.source = .init(text:content,encoding:"项目概览",byteCount:content.utf8.count,revision:"overview")
                    self.format = .markdown; self.rendered = try? MarkdownModel.parse(content); self.mode.selectedSegment = 0; self.present()
                    self.status.stringValue = "项目概览 · 只读声明线索 · 左侧点选文件继续阅读"
                }
            }
        }
    }
}
