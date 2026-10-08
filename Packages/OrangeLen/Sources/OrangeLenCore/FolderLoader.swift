import Foundation
import Darwin
public struct FolderEntry: Sendable {
    public let url: URL
    public let directory: Bool
    public let symbolicLink: Bool
    public let package: Bool
    public let unavailable: Bool
}
public struct FolderPage: Sendable {
    public let entries: [FolderEntry]
    public let scanned: Int
    public let nextOffset: Int?
    public let revision: String
}
public enum FolderLoader {
    public static let defaultIgnored: Set<String> = [".git", "node_modules", ".build", "build", "dist", "__pycache__", ".venv", "DerivedData"]
    public static func page(_ url: URL, root: URL, offset: Int = 0, showIgnored: Bool = false, ignored: Set<String> = defaultIgnored, limits: PreviewLimits = .init(), expectedRevision: String? = nil, cancellation: Cancellation = .init()) throws -> FolderPage {
        let scoped = root.startAccessingSecurityScopedResource()
        defer { if scoped { root.stopAccessingSecurityScopedResource() } }
        try AccessBroker.validate(url, root: root)
        func revision() throws -> String {
            var value = stat()
            guard lstat(url.path, &value) == 0, value.st_mode & S_IFMT == S_IFDIR else { throw PreviewError.changed }
            guard value.st_flags & UInt32(SF_DATALESS) == 0 else { throw PreviewError.unavailable }
            return "\(value.st_dev):\(value.st_ino):\(value.st_mtimespec.tv_sec):\(value.st_mtimespec.tv_nsec):\(value.st_ctimespec.tv_sec):\(value.st_ctimespec.tv_nsec)"
        }
        let before = try revision()
        guard expectedRevision == nil || expectedRevision == before else { throw PreviewError.changed }
        guard offset >= 0, offset <= limits.directoryScanItems else { throw PreviewError.limit("目录分页范围") }
        // Enumerate names only. Foundation resource prefetch can query metadata for
        // an entire directory before returning its first child (and again per page).
        try cancellation.check()
        let descriptor = try AccessBroker.openWithoutSymlinks(url)
        guard let directory = fdopendir(descriptor) else {
            let code = errno; Darwin.close(descriptor)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(code))
        }
        defer { closedir(directory) }
        let start = ProcessInfo.processInfo.systemUptime
        var scanned = 0; var entries: [FolderEntry] = []; var more = false
        while true {
            try cancellation.check()
            errno = 0
            guard let item = readdir(directory) else {
                if errno != 0 { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
                break
            }
            let length = Int(item.pointee.d_namlen)
            let name = withUnsafePointer(to: &item.pointee.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: length + 1) {
                    FileManager.default.string(withFileSystemRepresentation: $0, length: length)
                }
            }
            if name == "." || name == ".." { continue }
            if scanned >= offset + limits.directoryBatch { more = true; break }
            guard scanned < limits.directoryScanItems, ProcessInfo.processInfo.systemUptime - start < limits.directorySeconds else { throw PreviewError.limit("目录扫描 20,000 项 / 3 秒；已加载项仍可阅读") }
            scanned += 1
            if scanned <= offset { continue }
            if !showIgnored && (ignored.contains(name) || name.hasPrefix(".")) { continue }
            let child = url.appendingPathComponent(name)
            var info = stat()
            guard fstatat(dirfd(directory), name, &info, AT_SYMLINK_NOFOLLOW) == 0 else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            }
            let isDirectory = info.st_mode & S_IFMT == S_IFDIR
            let isLink = info.st_mode & S_IFMT == S_IFLNK
            // Package classification is only needed for directories. Never query a
            // link's target. SF_DATALESS covers local file-provider placeholders.
            let unavailable = info.st_flags & UInt32(SF_DATALESS) != 0
            let isPackage = isDirectory && !unavailable
                ? try child.resourceValues(forKeys: [.isPackageKey]).isPackage == true : false
            entries.append(FolderEntry(url: child, directory: isDirectory, symbolicLink: isLink,
                                       package: isPackage, unavailable: unavailable))
        }
        try cancellation.check()
        guard try revision() == before else { throw PreviewError.changed }
        return FolderPage(entries: entries.sorted { a, b in
            if a.directory != b.directory { return a.directory }
            return a.url.lastPathComponent.localizedStandardCompare(b.url.lastPathComponent) == .orderedAscending
        }, scanned: scanned, nextOffset: more ? scanned : nil, revision: before)
    }
}
