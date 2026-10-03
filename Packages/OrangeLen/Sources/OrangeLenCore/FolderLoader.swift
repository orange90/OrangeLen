import Foundation
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
}
public enum FolderLoader {
    public static let defaultIgnored: Set<String> = [".git", "node_modules", ".build", "build", "dist", "__pycache__", ".venv", "DerivedData"]
    public static func page(_ url: URL, root: URL, offset: Int = 0, showIgnored: Bool = false, ignored: Set<String> = defaultIgnored, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> FolderPage {
        let scoped = root.startAccessingSecurityScopedResource()
        defer { if scoped { root.stopAccessingSecurityScopedResource() } }
        try AccessBroker.validate(url, root: root)
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey, .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey]
        var enumerationError: Error?
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys, options: [.skipsSubdirectoryDescendants], errorHandler: { _, error in enumerationError = error; return false }) else { throw CocoaError(.fileReadNoPermission) }
        let start = Date(); var scanned = 0; var entries: [FolderEntry] = []; var more = false
        while let child = enumerator.nextObject() as? URL {
            try cancellation.check()
            if scanned >= offset + limits.directoryBatch { more = true; break }
            guard scanned < limits.directoryScanItems, Date().timeIntervalSince(start) < limits.directorySeconds else { throw PreviewError.limit("目录扫描 20,000 项 / 3 秒；已加载项仍可阅读") }
            scanned += 1
            if scanned <= offset { continue }
            if !showIgnored && (ignored.contains(child.lastPathComponent) || child.lastPathComponent.hasPrefix(".")) { continue }
            let v = try child.resourceValues(forKeys: Set(keys))
            entries.append(FolderEntry(url: child, directory: v.isDirectory == true, symbolicLink: v.isSymbolicLink == true, package: v.isPackage == true, unavailable: v.isUbiquitousItem == true && v.ubiquitousItemDownloadingStatus == .notDownloaded))
        }
        if let enumerationError { throw enumerationError }
        return FolderPage(entries: entries.sorted { a, b in
            if a.directory != b.directory { return a.directory }
            return a.url.lastPathComponent.localizedStandardCompare(b.url.lastPathComponent) == .orderedAscending
        }, scanned: scanned, nextOffset: more ? scanned : nil)
    }
}
