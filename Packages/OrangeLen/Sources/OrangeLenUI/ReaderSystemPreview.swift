import AppKit
import QuickLookUI
import OrangeLenCore
import AVKit

extension ReaderController {
    func loadSystemPreview(_ url: URL, root: URL?) {
        if url.startAccessingSecurityScopedResource() { systemPreviewScope = url }
        do {
            try AccessBroker.validate(url, root: root)
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isPackageKey])
            guard values.isRegularFile == true || values.isPackage == true else { throw PreviewError.unsafePath }
            if SystemPreviewFormat.isMedia(url) {
                let player = AVPlayer(url: url)
                let preview = AVPlayerView(frame: documentBody.bounds)
                preview.controlsStyle = .floating
                preview.player = player
                mediaPreview = preview
                mode.isEnabled = false; headings.isEnabled = false
                showContent(preview)
                status.stringValue = "\(url.lastPathComponent) · 音视频预览 · 点击播放"
                let id = generation
                mediaObservation = player.currentItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
                    let failure = item.status == .failed
                    DispatchQueue.main.async {
                        guard let self, self.generation == id, failure else { return }
                        self.status.stringValue = "音视频无法解码 · 可在“更多操作”中用默认应用打开"
                    }
                }
                finish(nil)
                return
            }
            let documentTypes: [String: NSAttributedString.DocumentType] = [
                "doc": .docFormat, "docx": .officeOpenXML, "docm": .officeOpenXML,
                "dot": .docFormat, "dotx": .officeOpenXML, "odt": .openDocument, "rtf": .rtf
            ]
            if let type = documentTypes[url.pathExtension.lowercased()] {
                loadNativeDocument(url, root: root, type: type)
                return
            }
            if OfficeContentPreview.supports(url) {
                loadNativeDocument(url, root: root, type: nil)
                return
            }
            // QLPreviewView cannot contact Quick Look services from a preview
            // extension's sandbox. Do not pretend its generic icon is a preview.
            if Bundle.main.bundleURL.pathExtension == "appex" {
                closeSystemPreview()
                showMessage("此格式需要系统单文件预览。\n请在“更多操作”中选择“在 Finder 中显示”，再按空格预览文件。")
                status.stringValue = "Finder 扩展内无法嵌套系统预览 · 可单独预览此文件"
                finish(nil)
                return
            }
            guard let preview = QLPreviewView(frame: documentBody.bounds, style: .normal) else {
                throw PreviewError.malformed("无法创建系统预览")
            }
            preview.shouldCloseWithWindow = false
            preview.autostarts = false
            systemPreview = preview
            mode.isEnabled = false; headings.isEnabled = false
            showContent(preview)
            preview.previewItem = url as NSURL
            status.stringValue = "\(url.lastPathComponent) · 系统 Quick Look · 若系统仅显示图标，可在“更多操作”中用默认应用打开"
            // Quick Look loads asynchronously; this callback only acknowledges handoff.
            finish(nil)
        } catch {
            closeSystemPreview()
            showMessage(error.localizedDescription)
            status.stringValue = "系统预览未能打开 · 可重载或选择其他文件"
            finish(error)
        }
    }

    func closeSystemPreview() {
        mediaObservation = nil
        mediaPreview?.player?.pause()
        mediaPreview?.player?.replaceCurrentItem(with: nil)
        mediaPreview?.player = nil
        mediaPreview?.removeFromSuperview()
        nativeDocumentPreview?.removeFromSuperview()
        if currentContent === mediaPreview || currentContent === nativeDocumentPreview { currentContent = nil }
        mediaPreview = nil; nativeDocumentPreview = nil
        systemPreview?.close()
        systemPreview?.removeFromSuperview()
        if currentContent === systemPreview { currentContent = nil }
        systemPreview = nil
        if let url = systemPreviewScope { url.stopAccessingSecurityScopedResource() }
        systemPreviewScope = nil
    }

    func loadNativeDocument(_ url: URL, root: URL?, type: NSAttributedString.DocumentType?) {
        let id = generation, token = cancellation ?? Cancellation()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Result { () -> NSAttributedString in
                var limits = PreviewLimits(); limits.fileBytes = 25 * 1024 * 1024
                let data = try AccessBroker.readBytes(url, root: root, limits: limits, cancellation: token).data
                guard let type else {
                    return NSAttributedString(string: try OfficeContentPreview.text(data, cancellation: token), attributes: [.font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular), .foregroundColor: NSColor.textColor])
                }
                // Bound ZIP expansion before handing Office XML to the system importer.
                if type == .officeOpenXML || type == .openDocument {
                    _ = try ArchiveDocument.parse(data, name: "document.zip", cancellation: token)
                }
                let document = try NSAttributedString(data: data, options: [.documentType: type], documentAttributes: nil)
                try token.check()
                return document
            }
            DispatchQueue.main.async {
                guard let self, self.generation == id else { return }
                do {
                    let document = try result.get()
                    self.showNativeDocument(document)
                    self.status.stringValue = type == nil ? "\(url.lastPathComponent) · Office 内容预览 · 不含原始版式/图表" : "\(url.lastPathComponent) · 原生文档预览 · 复杂版式可能简化"
                    self.finish(nil)
                } catch {
                    self.closeSystemPreview(); self.showMessage(error.localizedDescription)
                    self.status.stringValue = "文档预览未完成 · 可在“更多操作”中用默认应用打开"
                    self.finish(error)
                }
            }
        }
    }

    func showNativeDocument(_ document: NSAttributedString) {
        let preview = NSScrollView(frame: documentBody.bounds)
        preview.hasVerticalScroller = true; preview.hasHorizontalScroller = false
        let content = NSTextView(frame: preview.bounds)
        content.isEditable = false; content.isSelectable = true
        content.isVerticallyResizable = true; content.isHorizontallyResizable = false
        content.autoresizingMask = [.width]
        content.textContainer?.widthTracksTextView = true
        content.textContainerInset = NSSize(width: 24, height: 24)
        content.textStorage?.setAttributedString(document)
        // Imported Word text commonly has explicit black foreground colors.
        // Give it a document-white page even when Finder is in dark mode.
        if !OfficeContentPreview.supports(currentURL ?? URL(fileURLWithPath: "/")) {
            content.backgroundColor = .white
            content.appearance = NSAppearance(named: .aqua)
        }
        content.setAccessibilityLabel("文档预览正文")
        preview.documentView = content
        nativeDocumentPreview = preview
        mode.isEnabled = false; headings.isEnabled = false
        showContent(preview)
    }
}
