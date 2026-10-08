import Foundation
import CryptoKit
import Darwin

/// Short-lived IPC for a directory explicitly selected in the containing app.
/// Uses an implicit-scope bookmark, not a persistent security-scoped bookmark.
public final class ImageDirectoryGrant {
    public static let shared = ImageDirectoryGrant()
    private let directory: URL?
    private struct Record: Codable {
        let owner: UUID
        let revision: String
        let expires: Date
        let issued: Date
        let continuous: TimeInterval
        let boot: String
        let bookmark: Data
    }
    public struct Grant {
        public let owner: UUID
        public let directory: URL
    }
    public init(directory: URL? = nil, group: String? = Bundle.main.object(forInfoDictionaryKey: "OrangeLenAppGroup") as? String) {
        self.directory = directory ?? group.flatMap { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) }?.appendingPathComponent("OrangeLenImageGrants", isDirectory: true)
    }
    /// Continuous time includes sleep, unlike the awake-only uptime clock.
    public static func continuousTime() -> TimeInterval {
        var info = mach_timebase_info_data_t(); mach_timebase_info(&info)
        return Double(mach_continuous_time()) * Double(info.numer) / Double(info.denom) / 1_000_000_000
    }
    public static func bootID() -> String {
        var bytes = [CChar](repeating: 0, count: 128), size = 128
        guard sysctlbyname("kern.bootsessionuuid", &bytes, &size, nil, 0) == 0 else { return "" }
        return String(cString: bytes)
    }
    public var available: Bool { directory != nil }
    private func file(_ document: URL) -> URL? {
        let key = SHA256.hash(data: Data(document.standardizedFileURL.path.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory?.appendingPathComponent(key + ".json")
    }
    public func publish(_ imageDirectory: URL, document: URL, revision: String, owner: UUID, now: Date = Date(), continuous: TimeInterval = ImageDirectoryGrant.continuousTime(), boot: String = ImageDirectoryGrant.bootID()) throws {
        guard let directory, let target = file(document) else { return }
        // Issuer keeps the selected directory open. No .withSecurityScope: this
        // is Apple's process-to-process transfer, and expires without a heartbeat.
        let bookmark = try imageDirectory.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        guard bookmark.count <= 48 * 1024 else { throw PreviewError.limit(L10n.text("图片目录授权信息")) }
        let record = Record(owner: owner, revision: revision, expires: now.addingTimeInterval(30), issued: now, continuous: continuous, boot: boot, bookmark: bookmark)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try transaction {
        try JSONEncoder().encode(record).write(to: target, options: .atomic)
        // Remove abandoned records, including those left by a crashed host.
        for url in (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [] where url != target {
            if let record = read(url), record.expires < now { try? FileManager.default.removeItem(at: url) }
        }
        }
    }
    private func read(_ url: URL) -> Record? {
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= 72 * 1024,
              let data = try? Data(contentsOf: url), let record = try? JSONDecoder().decode(Record.self, from: data) else { return nil }
        return record
    }
    public func resolve(document: URL, revision: String, now: Date = Date(), continuous: TimeInterval = ImageDirectoryGrant.continuousTime(), boot: String = ImageDirectoryGrant.bootID()) -> Grant? {
        guard let target = file(document), let record = read(target), record.revision == revision, record.expires > now, now >= record.issued, record.boot == boot, !boot.isEmpty, (0..<30).contains(continuous - record.continuous) else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: record.bookmark, options: [.withoutUI, .withoutImplicitStartAccessing], relativeTo: nil, bookmarkDataIsStale: &stale), !stale else { return nil }
        let base = document.deletingLastPathComponent().standardizedFileURL.pathComponents
        guard url.standardizedFileURL.pathComponents.starts(with: base) else { return nil }
        return .init(owner: record.owner, directory: url)
    }
    private func transaction(_ work: () throws -> Void) throws {
        guard let directory else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fd = Darwin.open(directory.appendingPathComponent(".lock").path, O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw PreviewError.unavailable }; defer { Darwin.close(fd) }
        let deadline = Self.continuousTime() + 0.1
        while flock(fd, LOCK_EX | LOCK_NB) != 0 {
            guard errno == EWOULDBLOCK, Self.continuousTime() < deadline else { throw PreviewError.limit(L10n.text("图片授权忙，请重试")) }
            usleep(1000)
        }
        defer { flock(fd, LOCK_UN) }; try work()
    }
    public func remove(document: URL, owner: UUID) {
        try? transaction {
            guard let target = file(document), read(target)?.owner == owner else { return }
            try? FileManager.default.removeItem(at: target)
        }
    }
}
