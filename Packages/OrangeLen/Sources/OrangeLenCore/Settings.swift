import Foundation
import CryptoKit
public struct ReaderSettings: Codable, Equatable, Sendable {
    public var codeSize: Double = 15
    public var documentSize: Double = 18
    public var rulerLines = 3
    public var focus = false
    public var highlight = true
    public var dim = true
    public var wrapCode = true
    public var lineNumbers = true
    public var theme = "System"
    public var remember = false
    public var ignored = Array(FolderLoader.defaultIgnored).sorted()
    public init() {}
}
public final class SettingsStore {
    public static let shared = SettingsStore()
    public let defaults: UserDefaults
    public let sharedAvailable: Bool
    public let directory: URL
    public init(group: String? = Bundle.main.object(forInfoDictionaryKey: "OrangeLenAppGroup") as? String, defaults overrideDefaults: UserDefaults? = nil, directory overrideDirectory: URL? = nil) {
        let groupURL = group.flatMap { $0.isEmpty ? nil : FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) }
        sharedAvailable = groupURL != nil
        defaults = overrideDefaults ?? (groupURL == nil ? .standard : (UserDefaults(suiteName: group!) ?? .standard))
        directory = overrideDirectory ?? (groupURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]).appendingPathComponent("OrangeLenReading", isDirectory: true)
    }
    public func load() -> ReaderSettings {
        guard let data = defaults.data(forKey: "readerSettings"), let settings = try? JSONDecoder().decode(ReaderSettings.self, from: data) else { return .init() }
        return settings
    }
    public func save(_ settings: ReaderSettings) { if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: "readerSettings") } }
    struct State: Codable { let revision: String; let offset: Int; let date: Date; var section: String? = nil }
    private func file(_ url: URL) -> URL {
        // Salt is local metadata, never source content or a credential. Shared state remains disabled without a configured group.
        let salt = defaults.string(forKey: "readingSalt") ?? UUID().uuidString
        defaults.set(salt, forKey: "readingSalt")
        let key = SHA256.hash(data: Data((salt + url.standardizedFileURL.path).utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(key + ".json")
    }
    public func restore(_ url: URL, revision: String) -> Int? {
        guard load().remember, let data = try? Data(contentsOf: file(url)), let state = try? JSONDecoder().decode(State.self, from: data), state.revision == revision, Date().timeIntervalSince(state.date) < 30 * 86400 else { return nil }
        return state.offset
    }
    public func restoreSection(_ url: URL, revision: String) -> String? {
        guard load().remember, let data = try? Data(contentsOf:file(url)), let state = try? JSONDecoder().decode(State.self,from:data), state.revision == revision, Date().timeIntervalSince(state.date) < 30 * 86400 else { return nil }
        return state.section
    }
    public func remember(_ url: URL, revision: String, offset: Int, section: String? = nil) {
        guard load().remember else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(State(revision: revision, offset: max(0, offset), date: Date(), section:section))
            var error: NSError?
            NSFileCoordinator().coordinate(writingItemAt: file(url), options: .forReplacing, error: &error) { target in try? data.write(to: target, options: .atomic) }
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey]).sorted { a, b in
                (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast > (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            }
            for (index, file) in files.enumerated() {
                let date = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                if index >= 200 || Date().timeIntervalSince(date) > 30 * 86400 { try? FileManager.default.removeItem(at: file) }
            }
        } catch { /* Reading state is optional and never prevents a preview. */ }
    }
    public func clear() { try? FileManager.default.removeItem(at: directory) }
}
