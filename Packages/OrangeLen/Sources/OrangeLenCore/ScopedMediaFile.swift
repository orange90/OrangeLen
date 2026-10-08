import Foundation
import Darwin

/// Streaming access retains one verified descriptor, never reopens by URL.
/// Atomic replacement, in-place changes and cloud placeholders fail closed.
public final class ScopedMediaFile: @unchecked Sendable {
    public let length: Int64
    private let fd: Int32, url: URL, scoped: Bool, initial: stat
    private let lock = NSLock()
    private var bytesRead: Int64 = 0
    public init(_ url: URL, root: URL? = nil) throws {
        let scope = url.startAccessingSecurityScopedResource()
        do {
            try AccessBroker.validate(url, root: root)
            let fd = try AccessBroker.openWithoutSymlinks(url)
            var info = stat()
            guard fstat(fd, &info) == 0, info.st_mode & S_IFMT == S_IFREG else { Darwin.close(fd); throw PreviewError.unsafePath }
            guard info.st_flags & UInt32(SF_DATALESS) == 0 else { Darwin.close(fd); throw PreviewError.unavailable }
            guard info.st_size >= 0, info.st_size <= 64 * 1024 * 1024 * 1024 else { Darwin.close(fd); throw PreviewError.limit("媒体文件最多 64 GiB") }
            self.fd = fd; self.initial = info; self.url = url; self.scoped = scope; self.length = info.st_size
        } catch { if scope { url.stopAccessingSecurityScopedResource() }; throw error }
    }
    deinit { Darwin.close(fd); if scoped { url.stopAccessingSecurityScopedResource() } }
    public func read(offset: Int64, count: Int, cancellation: Cancellation) throws -> Data {
        lock.lock(); defer { lock.unlock() }
        try cancellation.check()
        guard offset >= 0, offset <= length, count >= 0, count <= 64 * 1024 else { throw PreviewError.limit("媒体读取范围") }
        let size = min(Int64(count), length - offset)
        guard bytesRead + size <= 4 * 1024 * 1024 * 1024 else { throw PreviewError.limit("本次媒体预览读取已达 4 GiB，请重载") }
        func checkIdentity() throws {
            var current = stat(), path = stat()
            guard fstat(fd, &current) == 0, lstat(url.path, &path) == 0,
                  current.st_size == initial.st_size, current.st_mtimespec.tv_sec == initial.st_mtimespec.tv_sec,
                  current.st_mtimespec.tv_nsec == initial.st_mtimespec.tv_nsec,
                  current.st_ctimespec.tv_sec == initial.st_ctimespec.tv_sec, current.st_ctimespec.tv_nsec == initial.st_ctimespec.tv_nsec,
                  path.st_dev == initial.st_dev, path.st_ino == initial.st_ino else { throw PreviewError.changed }
            guard current.st_flags & UInt32(SF_DATALESS) == 0 else { throw PreviewError.unavailable }
        }
        try checkIdentity()
        var data = Data(count: Int(size))
        let amount = data.withUnsafeMutableBytes { pread(fd, $0.baseAddress, Int(size), off_t(offset)) }
        guard amount == size else { throw PreviewError.changed }
        try checkIdentity(); try cancellation.check(); bytesRead += size
        return data
    }
}
