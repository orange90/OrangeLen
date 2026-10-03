import Foundation
import Darwin

public enum PreviewError: Error, LocalizedError {
    case limit(String), encoding, binary, unavailable, changed, unsafePath, malformed(String)
    public var errorDescription: String? {
        switch self {
        case .limit(let reason): return "超过安全预算：\(reason)"
        case .encoding: return "无法识别编码。支持严格 UTF-8、带 BOM 的 UTF-16。"
        case .binary: return "这是二进制或含空字符的文件，不能作为文本预览。"
        case .unavailable: return "文件尚未下载到本机；预览不会自动下载。"
        case .changed: return "读取期间文件已变化，请重新载入。"
        case .unsafePath: return "符号链接、特殊文件或根目录之外的路径不在本次读取范围。"
        case .malformed(let reason): return "格式损坏：\(reason)"
        }
    }
}
public final class Cancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    public init() {}
    public func cancel() { lock.lock(); cancelled = true; lock.unlock() }
    public func check() throws { lock.lock(); let value = cancelled; lock.unlock(); if value { throw CancellationError() } }
}
public struct SourceSnapshot: Sendable {
    public let text: String
    public let encoding: String
    public let byteCount: Int
    public let revision: String
}
public struct FileSnapshot: Sendable {
    public let data: Data
    public let revision: String
}
public enum AccessBroker {
    public static func validate(_ url: URL, root: URL? = nil) throws {
        guard url.isFileURL else { throw PreviewError.unsafePath }
        let normalized = url.standardizedFileURL
        guard normalized.resolvingSymlinksInPath().path == normalized.path else { throw PreviewError.unsafePath }
        if let root {
            let base = root.standardizedFileURL.resolvingSymlinksInPath().pathComponents
            guard normalized.pathComponents.starts(with: base) else { throw PreviewError.unsafePath }
        }
        let values = try url.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey, .isSymbolicLinkKey])
        guard values.isSymbolicLink != true else { throw PreviewError.unsafePath }
        if values.isUbiquitousItem == true && values.ubiquitousItemDownloadingStatus == .notDownloaded { throw PreviewError.unavailable }
    }
    public static func read(_ url: URL, root: URL? = nil, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> SourceSnapshot {
        let raw = try readBytes(url, root: root, limits: limits, cancellation: cancellation)
        let decoded = try decode(raw.data)
        return SourceSnapshot(text: decoded.0, encoding: decoded.1, byteCount: raw.data.count, revision: raw.revision)
    }
    public static func readBytes(_ url: URL, root: URL? = nil, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> FileSnapshot {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        try validate(url, root: root); try cancellation.check()
        var coordinationError: NSError?
        var result: Result<FileSnapshot, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinationError) { coordinated in
            result = Result {
                try cancellation.check()
                try validate(coordinated, root: root)
                let fd = try openWithoutSymlinks(coordinated)
                guard fd >= 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
                defer { Darwin.close(fd) }
                var before = stat()
                guard fstat(fd, &before) == 0, before.st_mode & S_IFMT == S_IFREG else { throw PreviewError.unsafePath }
                guard before.st_flags & UInt32(SF_DATALESS) == 0 else { throw PreviewError.unavailable }
                guard before.st_size <= limits.fileBytes else { throw PreviewError.limit("文件最大 \(limits.fileBytes / 1024 / 1024) MiB") }
                var data = Data(); var buffer = [UInt8](repeating: 0, count: 65536)
                while true {
                    try cancellation.check()
                    let count = Darwin.read(fd, &buffer, min(buffer.count, limits.fileBytes + 1 - data.count))
                    if count < 0 { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
                    if count == 0 { break }
                    data.append(contentsOf: buffer.prefix(count))
                    if data.count > limits.fileBytes { throw PreviewError.limit("读取字节上限") }
                }
                var after = stat(); guard fstat(fd, &after) == 0 else { throw PreviewError.changed }
                guard before.st_size == after.st_size, before.st_mtimespec.tv_sec == after.st_mtimespec.tv_sec, before.st_mtimespec.tv_nsec == after.st_mtimespec.tv_nsec else { throw PreviewError.changed }
                var pathStat = stat()
                guard lstat(coordinated.path, &pathStat) == 0, pathStat.st_ino == before.st_ino, pathStat.st_dev == before.st_dev else { throw PreviewError.changed }
                try cancellation.check()
                return FileSnapshot(data: data, revision: "\(before.st_dev):\(before.st_ino):\(before.st_size):\(before.st_mtimespec.tv_sec):\(before.st_mtimespec.tv_nsec)")
            }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw PreviewError.changed }
        return try result.get()
    }
    private static func openWithoutSymlinks(_ url: URL) throws -> Int32 {
        var parent = Darwin.open("/", O_SEARCH)
        guard parent >= 0 else { throw PreviewError.unsafePath }
        // Foundation deliberately preserves macOS's protected /var, /tmp and /etc aliases.
        // Expand only these system aliases; never resolve arbitrary project symlinks.
        var path = url.standardizedFileURL.path
        for alias in ["/var/", "/tmp/", "/etc/"] where path.hasPrefix(alias) { path = "/private" + path; break }
        let components = path.split(separator: "/").map(String.init)
        for (index, component) in components.enumerated() {
            let last = index == components.count - 1
            let next = openat(parent, component, O_NOFOLLOW | O_NONBLOCK | (last ? O_RDONLY : O_SEARCH))
            let code = errno
            Darwin.close(parent)
            guard next >= 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(code)) }
            parent = next
        }
        return parent
    }
    public static func decode(_ input: Data) throws -> (String, String) {
        var data = input
        var encoding = String.Encoding.utf8
        var label = "UTF-8"
        if data.starts(with: [0xEF, 0xBB, 0xBF]) { data.removeFirst(3); label = "UTF-8 BOM" }
        else if data.starts(with: [0xFF, 0xFE]) { data.removeFirst(2); encoding = .utf16LittleEndian; label = "UTF-16 LE" }
        else if data.starts(with: [0xFE, 0xFF]) { data.removeFirst(2); encoding = .utf16BigEndian; label = "UTF-16 BE" }
        guard let text = String(data: data, encoding: encoding) else { throw PreviewError.encoding }
        guard !text.utf16.contains(0) else { throw PreviewError.binary }
        return (text, label)
    }
}

public enum PreviewFormat: String, Sendable {
    case markdown, json, csv, tsv, code, text
    public static func detect(_ url: URL) -> Self {
        if ["Makefile", "Dockerfile", "Gemfile"].contains(url.lastPathComponent) { return .code }
        switch url.pathExtension.lowercased() {
        case "md", "markdown": return .markdown
        case "json": return .json
        case "csv": return .csv
        case "tsv": return .tsv
        case "txt", "": return .text
        default: return .code
        }
    }
}
