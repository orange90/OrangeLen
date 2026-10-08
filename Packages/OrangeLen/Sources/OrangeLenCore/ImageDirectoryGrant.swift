import Foundation
import CryptoKit

/// Short-lived IPC for a directory explicitly selected in the containing app.
/// Uses an implicit-scope bookmark, not a persistent security-scoped bookmark.
public final class ImageDirectoryGrant {
    public static let shared = ImageDirectoryGrant()
    private let directory: URL?
    private struct Record: Codable {
        let owner: UUID
        let revision: String
        let expires: Date
        let bookmark: Data
    }
    public struct Grant {
        public let owner: UUID
        public let directory: URL
    }
    public init(directory: URL? = nil, group: String? = Bundle.main.object(forInfoDictionaryKey: "OrangeLenAppGroup") as? String) {
        self.directory = directory ?? group.flatMap { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) }?.appendingPathComponent("OrangeLenImageGrants", isDirectory: true)
    }
    public var available: Bool { directory != nil }
    private func file(_ document: URL) -> URL? {
        let key = SHA256.hash(data: Data(document.standardizedFileURL.path.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory?.appendingPathComponent(key + ".json")
    }
    public func publish(_ imageDirectory: URL, document: URL, revision: String, owner: UUID, now: Date = Date()) throws {
        guard let directory, let target = file(document) else { return }
        // Issuer keeps the selected directory open. No .withSecurityScope: this
        // is Apple's process-to-process transfer, and expires without a heartbeat.
        let bookmark = try imageDirectory.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        guard bookmark.count <= 48 * 1024 else { throw PreviewError.limit("图片目录授权信息") }
        let record = Record(owner: owner, revision: revision, expires: now.addingTimeInterval(30), bookmark: bookmark)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(record).write(to: target, options: .atomic)
        // Remove abandoned records, including those left by a crashed host.
        for url in (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [] where url != target {
            if let record = read(url), record.expires < now { try? FileManager.default.removeItem(at: url) }
        }
    }
    private func read(_ url: URL) -> Record? {
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= 72 * 1024,
              let data = try? Data(contentsOf: url), let record = try? JSONDecoder().decode(Record.self, from: data) else { return nil }
        return record
    }
    public func resolve(document: URL, revision: String, now: Date = Date()) -> Grant? {
        guard let target = file(document), let record = read(target), record.revision == revision, record.expires > now else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: record.bookmark, options: [.withoutUI, .withoutImplicitStartAccessing], relativeTo: nil, bookmarkDataIsStale: &stale), !stale else { return nil }
        let base = document.deletingLastPathComponent().standardizedFileURL.pathComponents
        guard url.standardizedFileURL.pathComponents.starts(with: base) else { return nil }
        return .init(owner: record.owner, directory: url)
    }
    public func remove(document: URL, owner: UUID) {
        guard let target = file(document), read(target)?.owner == owner else { return }
        try? FileManager.default.removeItem(at: target)
    }
}
