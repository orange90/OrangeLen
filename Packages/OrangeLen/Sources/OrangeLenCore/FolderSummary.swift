import Foundation
import Darwin

/// Metadata-only recursive totals. Traversal continues until done or cancelled;
/// the enumerator keeps depth-first state instead of retaining every sibling URL.
public enum FolderFileKind: String, CaseIterable, Sendable {
    case documents = "文档", code = "代码", data = "数据与配置", images = "图片", media = "音视频", other = "其他"
    public static func detect(_ url: URL) -> Self {
        let ext = url.pathExtension.lowercased(), name = url.lastPathComponent.lowercased()
        if ["md", "markdown", "txt", "pdf", "doc", "docx", "rtf", "odt", "epub"].contains(ext) { return .documents }
        if ["swift", "py", "js", "jsx", "ts", "tsx", "rs", "go", "c", "h", "cpp", "hpp", "java", "kt", "rb", "sh", "zsh", "html", "css", "scss", "vue", "svelte", "sql"].contains(ext) || ["makefile", "dockerfile", "containerfile"].contains(name) { return .code }
        if ["json", "jsonc", "json5", "jsonl", "csv", "tsv", "toml", "yaml", "yml", "xml", "ini", "conf", "env", "sqlite", "db", "xlsx", "xls", "ipynb"].contains(ext) || name.hasPrefix(".env") { return .data }
        if ["png", "jpg", "jpeg", "gif", "webp", "heic", "tiff", "tif", "bmp", "svg", "avif", "excalidraw"].contains(ext) { return .images }
        if ["mp4", "mov", "m4v", "mkv", "mp3", "m4a", "wav", "aac", "flac", "aiff"].contains(ext) { return .media }
        return .other
    }
}

public struct FolderSummary: Sendable {
    public var categories: [FolderFileKind: Int] = [:]
    public var bytes: Int64 = 0
    public var files = 0
    public var folders = 0
    public var links = 0
    public var complete = true
    public var reason = ""
    public static func scan(_ root: URL, cancellation: Cancellation = .init(),
                            progressInterval: TimeInterval = 0.2,
                            progress: ((Self) -> Void)? = nil) throws -> Self {
        let scope = root.startAccessingSecurityScopedResource()
        defer { if scope { root.stopAccessingSecurityScopedResource() } }
        try AccessBroker.validate(root); try cancellation.check()
        var result = Self(), visited = 0
        var lastProgress = ProcessInfo.processInfo.systemUptime
        func reportProgress() {
            guard let progress else { return }
            let now = ProcessInfo.processInfo.systemUptime
            guard now - lastProgress >= max(0, progressInterval) else { return }
            lastProgress = now
            var snapshot = result; snapshot.complete = false; progress(snapshot)
        }
        func partial(_ reason: String) { result.complete = false; if result.reason.isEmpty { result.reason = reason } }
        var rootStat = stat()
        guard lstat(root.path, &rootStat) == 0, rootStat.st_mode & S_IFMT == S_IFDIR else { throw PreviewError.unsafePath }
        guard rootStat.st_flags & UInt32(SF_DATALESS) == 0 else { throw PreviewError.unavailable }
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil, options: [], errorHandler: { _, _ in partial("部分项目无读取权限"); return true }) else { throw PreviewError.unavailable }
        while let child = enumerator.nextObject() as? URL {
            try cancellation.check()
            visited += 1
            // Yield disk/CPU time without reinstating the removed total-item/time cap.
            if visited % 256 == 0 { Thread.sleep(forTimeInterval: 0.002); try cancellation.check() }
            defer { reportProgress() }
            autoreleasepool {
                var info = stat()
                guard lstat(child.path, &info) == 0 else { partial("项目发生变化或无权限"); enumerator.skipDescendants(); return }
                switch info.st_mode & S_IFMT {
                case S_IFLNK: result.links += 1 // Enumerator never follows symlinks; skipDescendants here can skip the next sibling.
                case S_IFREG:
                    result.files += 1
                    result.categories[FolderFileKind.detect(child), default: 0] += 1
                    let addition = max(0, info.st_size)
                    if addition > Int64.max - result.bytes { partial("逻辑文件大小总和超出显示范围") }
                    else { result.bytes += addition }
                case S_IFDIR:
                    result.folders += 1
                    guard info.st_flags & UInt32(SF_DATALESS) == 0 else { partial("跳过未下载目录"); enumerator.skipDescendants(); return }
                    do { try AccessBroker.validate(child, root: root) }
                    catch { partial("跳过不可读取目录"); enumerator.skipDescendants() }
                default: partial("跳过特殊文件")
                }
            }
        }
        try cancellation.check()
        return result
    }
}
