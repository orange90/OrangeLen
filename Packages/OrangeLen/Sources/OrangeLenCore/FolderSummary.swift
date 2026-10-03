import Foundation
import Darwin

/// Metadata-only recursive totals, independent of tree expansion and ignore filters.
public struct FolderSummary: Sendable {
    public var bytes: Int64 = 0
    public var files = 0
    public var folders = 0
    public var links = 0
    public var complete = true
    public var reason = ""
    public static func scan(_ root: URL, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> Self {
        let scope = root.startAccessingSecurityScopedResource()
        defer { if scope { root.stopAccessingSecurityScopedResource() } }
        try AccessBroker.validate(root); try cancellation.check()
        var result = Self()
        var pending = [root]; var visited = 0
        let start = Date()
        func partial(_ reason: String) { result.complete = false; if result.reason.isEmpty { result.reason = reason } }
        while let directory = pending.popLast() {
            try cancellation.check()
            var directoryStat = stat()
            guard lstat(directory.path, &directoryStat) == 0, directoryStat.st_mode & S_IFMT == S_IFDIR else { partial("不可访问的目录"); continue }
            guard directoryStat.st_flags & UInt32(SF_DATALESS) == 0 else { partial("跳过未下载目录"); continue }
            do { try AccessBroker.validate(directory, root: root) } catch { partial("跳过不可读取目录"); continue }
            guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey], options: [.skipsSubdirectoryDescendants], errorHandler: { _, _ in partial("部分项目无读取权限"); return false }) else { partial("无法枚举目录"); continue }
            while let child = enumerator.nextObject() as? URL {
                try cancellation.check()
                if visited >= limits.directoryScanItems || Date().timeIntervalSince(start) >= limits.directorySeconds { partial("达到项目数或时间预算"); return result }
                visited += 1
                var info = stat()
                guard lstat(child.path, &info) == 0 else { partial("项目发生变化或无权限"); continue }
                switch info.st_mode & S_IFMT {
                case S_IFLNK: result.links += 1 // Never follow links, even to another authorized subtree.
                case S_IFREG: result.files += 1; result.bytes += max(0, info.st_size)
                case S_IFDIR:
                    result.folders += 1
                    let cloud = try? child.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
                    if info.st_flags & UInt32(SF_DATALESS) != 0 || cloud?.ubiquitousItemDownloadingStatus == .notDownloaded { partial("跳过未下载目录") }
                    else { pending.append(child) }
                default: partial("跳过特殊文件")
                }
            }
        }
        return result
    }
}
