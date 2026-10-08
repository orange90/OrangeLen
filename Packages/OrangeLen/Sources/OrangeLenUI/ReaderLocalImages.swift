import AppKit
import OrangeLenCore

extension ReaderController {
    @objc func authorizeLocalImages() {
        guard !virtualDocument, let document = currentURL else { return }
        if Bundle.main.bundleURL.pathExtension == "appex" {
            let alert = NSAlert()
            alert.messageText = "允许此文档的本地图片"
            alert.informativeText = ImageDirectoryGrant.shared.available
                ? "在 OrangeLen 中用 ⌘O 打开此文档，点击“允许本地图片…”并选择图片目录。保持文档打开，返回 Finder 即可重新加载图片。关闭宿主文档后，本次共享授权结束。\n\n\(document.path)"
                : "当前构建没有可用的共享 app group。可在 OrangeLen 中用 ⌘O 打开此文档，再点“允许本地图片…”在宿主阅读图片；此构建不能将授权共享给 Finder。\n\n\(document.path)"
            alert.addButton(withTitle: "知道了")
            if let window = view.window { alert.beginSheetModal(for: window) }
            return
        }
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = false
        panel.title = "允许读取文档中的本地图片"
        panel.message = ImageDirectoryGrant.shared.available
            ? "选择文档目录或图片子目录，用于当前文档及它的 Finder 预览。关闭宿主文档后结束共享；不保存长期授权。"
            : "选择文档目录或图片子目录，仅用于当前宿主文档。此构建没有可用的 Finder 授权共享；不保存长期授权。"
        panel.prompt = "允许本次读取"; panel.directoryURL = document.deletingLastPathComponent()
        panel.begin { [weak self] result in
            guard result == .OK, let directory = panel.url, let self, self.currentURL == document else { return }
            let base = document.deletingLastPathComponent().standardizedFileURL.pathComponents
            guard directory.standardizedFileURL.pathComponents.starts(with: base) else { self.showCopyNotice("请选择文档目录或它的图片子目录"); return }
            self.useImageDirectory(directory, for: document)
        }
    }
    func useImageDirectory(_ directory: URL, for document: URL) {
        guard currentURL == document else { return }
        if imageRootScope { imageRootURL?.stopAccessingSecurityScopedResource() }
        imageRootURL = directory; imageDocumentURL = document; imageRootScope = directory.startAccessingSecurityScopedResource()
        if Bundle.main.bundleURL.pathExtension != "appex" { imageGrantOwner = UUID(); publishImageDirectory() }
        reloadPreservingPosition(document, notice: "本地图片已重新读取")
    }
    func releaseImageDirectory() {
        if Bundle.main.bundleURL.pathExtension != "appex", let owner = imageGrantOwner, let document = imageDocumentURL { ImageDirectoryGrant.shared.remove(document: document, owner: owner) }
        if imageRootScope { imageRootURL?.stopAccessingSecurityScopedResource() }
        imageRootScope = false; imageRootURL = nil; imageDocumentURL = nil; imageGrantOwner = nil; imageGrantPublished = .distantPast
    }
    func publishImageDirectory() {
        guard ImageDirectoryGrant.shared.available, Date().timeIntervalSince(imageGrantPublished) > 5, let directory = imageRootURL, let document = imageDocumentURL, let owner = imageGrantOwner, let revision = Self.fileRevision(document) else { return }
        do { try ImageDirectoryGrant.shared.publish(directory, document: document, revision: revision, owner: owner); imageGrantPublished = Date() }
        catch { showCopyNotice("宿主图片可读；Finder 授权共享未成功") }
    }
    func syncImageDirectory() {
        guard Bundle.main.bundleURL.pathExtension == "appex" else { publishImageDirectory(); return }
        guard !virtualDocument, completion == nil, !autoReload, let document = currentURL, format == .markdown, let revision = Self.fileRevision(document) else { return }
        let grant = ImageDirectoryGrant.shared.resolve(document: document, revision: revision)
        guard grant?.owner != imageGrantOwner else { return }
        releaseImageDirectory()
        if let grant {
            imageRootURL = grant.directory; imageDocumentURL = document; imageRootScope = grant.directory.startAccessingSecurityScopedResource(); imageGrantOwner = grant.owner
        }
        reloadPreservingPosition(document, notice: grant == nil ? "本次图片授权已结束" : "已使用宿主授权重新读取本地图片")
    }
    func adoptImageDirectory(_ document: URL) {
        guard Bundle.main.bundleURL.pathExtension == "appex", imageGrantOwner == nil, PreviewFormat.detect(document) == .markdown, let revision = Self.fileRevision(document), let grant = ImageDirectoryGrant.shared.resolve(document: document, revision: revision) else { return }
        imageRootURL = grant.directory; imageDocumentURL = document; imageRootScope = grant.directory.startAccessingSecurityScopedResource(); imageGrantOwner = grant.owner
    }
}
