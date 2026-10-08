import AppKit
import OrangeLenCore

extension ReaderController {
    struct ReadingPosition { let sourceOffset: Int; let mode: Int }
    var readingPosition: ReadingPosition? {
        guard source != nil else { return nil }
        var offset = text.anchor
        if let layout = text.layoutManager, let container = text.textContainer, layout.numberOfGlyphs > 0 {
            let visible = text.visibleRect.offsetBy(dx: -text.textContainerOrigin.x, dy: -text.textContainerOrigin.y)
            let glyphs = layout.glyphRange(forBoundingRect: visible, in: container)
            if glyphs.location < layout.numberOfGlyphs { offset = layout.characterIndexForGlyph(at: glyphs.location) }
        }
        return .init(sourceOffset: text.model.sourceRange(for: .init(location: offset, length: 1))?.location ?? 0, mode: mode.selectedSegment)
    }
    func showMessage(_ value: String) {
        outlineSidebar.view.isHidden = true; outlineToggle.isHidden = true
        source = nil; rendered = nil; mode.isEnabled = false; headings.isEnabled = false
        text.model = .plain(value); text.string = value
        scroll.rulersVisible = false; showContent(scroll)
    }
    func openMemory(_ section: DocumentSection, origin: URL, revision: String, assets: MarkdownAssets, restoring position: ReadingPosition? = nil) {
        loadViewIfNeeded(); savePosition(); cancelPending(); preparedHighlights = nil; canvasImage = nil; virtualDocument = true; virtualTitle = section.title
        // A synthetic identity is only hashed for local reading state; it is never opened on disk.
        currentURL = origin.appendingPathComponent(section.id)
        let ext = origin.pathExtension.lowercased()
        if section.markdown { format = .markdown }
        else if ["sqlite","db","sqlite3"].contains(ext) { format = .csv }
        else if ["jsonl","ndjson"].contains(ext) { format = .json }
        else if ["diff","patch"].contains(ext) || ["diff","patch"].contains(URL(fileURLWithPath:section.id).pathExtension) { format = .diff }
        else { format = PreviewFormat.detect(URL(fileURLWithPath: section.id)) }

        let snapshot = SourceSnapshot(text:section.text,encoding:L10n.text("容器内存"),byteCount:section.text.utf8.count,revision:revision+":"+section.id)
        source = nil; rendered = nil
        let token = Cancellation(); cancellation = token; let current = generation; let detected = format
        text.string = L10n.text("正在解析选中内容…"); showContent(scroll)
        PreviewWorkQueue.parsing.submit(cancellation: token, work: { () -> (TextModel?, JSONTree?, TableData?, String) in
            var markdown: TextModel?; var tree: JSONTree?; var table: TableData?; var warning = section.warning
            do {
                if section.markdown { markdown = try MarkdownModel.parse(section.text,cancellation:token) }
                else if detected == .json { tree = try JSONParser.parse(section.text,dialect:JSONDialect.detect(URL(fileURLWithPath:section.id)),cancellation:token) }
                else if detected == .csv || detected == .tsv { table = try CSVParser.parse(section.text,separator:detected == .tsv ? 9 : 44,cancellation:token) }
                try token.check()
            } catch is CancellationError { throw CancellationError() }
            catch {
                let reason = error.localizedDescription
                if !warning.contains(reason) { warning = [warning,reason].filter { !$0.isEmpty }.joined(separator:" · ") }
            }
            return (markdown, tree, table, warning)
        }, completion: { [weak self] result in
                guard let self, self.generation == current else { return }
                guard case .success(let content) = result else { if case .failure(let error) = result { self.showMessage(error.localizedDescription) }; return }
                let (markdown, tree, table, warning) = content
                self.source = snapshot; self.markdownAssets = assets; self.jsonTree = tree; self.tableData = table; self.rendered = markdown; self.parseWarning = warning
                self.mode.selectedSegment = 0; self.text.anchor = 0; self.present(); self.startRichRendering()
                self.remoteBar.isHidden = true; self.remoteHeight.constant = 0
                if let position, self.mode.isEnabled { self.mode.selectedSegment = position.mode; self.present() }
                if let offset = position?.sourceOffset ?? SettingsStore.shared.restore(self.currentURL!,revision:snapshot.revision) {
                    let display = self.text.model.displayOffset(forSource:offset); self.text.setAnchor(at:display); self.text.scrollRangeToVisible(.init(location:min(display,self.text.string.utf16.count),length:0))
                } else { self.scroll.contentView.scroll(to:.zero) }
        })
    }
}

extension ReaderController {
    func loadProjectOverview(_ root: URL) {
        let token = Cancellation(); cancellation = token; let current = generation
        PreviewWorkQueue.parsing.submit(cancellation: token, work: {
            try ProjectOverview.readme(root, cancellation: token)
        }, completion: { [weak self] result in
            guard let self, self.generation == current, self.currentURL == nil else { return }
            switch result {
            case .success(let readme): self.folderOverview.showReadme(readme)
            case .failure: self.folderOverview.readmeFailed()
            }
        })
    }
}
