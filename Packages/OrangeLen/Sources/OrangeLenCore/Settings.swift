import Foundation
import CryptoKit
import Darwin
public struct ReaderSettings: Codable, Equatable, Sendable {
    public var codeSize: Double = 15
    public var documentSize: Double = 18
    public var wrapCode = true
    public var lineNumbers = true
    public var theme = "System"
    public var remember = false
    public var liveReload = true
    public var markdownOutline = true
    public var ignored = Array(FolderLoader.defaultIgnored).sorted()
    public init() {}
    enum CodingKeys: String, CodingKey { case codeSize, documentSize, wrapCode, lineNumbers, theme, remember, liveReload, markdownOutline, ignored }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        codeSize = try values.decodeIfPresent(Double.self, forKey: .codeSize) ?? 15
        documentSize = try values.decodeIfPresent(Double.self, forKey: .documentSize) ?? 18
        wrapCode = try values.decodeIfPresent(Bool.self, forKey: .wrapCode) ?? true
        lineNumbers = try values.decodeIfPresent(Bool.self, forKey: .lineNumbers) ?? true
        theme = try values.decodeIfPresent(String.self, forKey: .theme) ?? "System"
        remember = try values.decodeIfPresent(Bool.self, forKey: .remember) ?? false
        liveReload = try values.decodeIfPresent(Bool.self, forKey: .liveReload) ?? true
        markdownOutline = try values.decodeIfPresent(Bool.self, forKey: .markdownOutline) ?? true
        ignored = try values.decodeIfPresent([String].self, forKey: .ignored) ?? Array(FolderLoader.defaultIgnored).sorted()
    }
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
        let local = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("OrangeLenReading", isDirectory: true)
        if let overrideDirectory { directory = overrideDirectory }
        else if let groupURL {
            let shared = groupURL.appendingPathComponent("OrangeLenReading", isDirectory: true)
            do { try FileManager.default.createDirectory(at: shared, withIntermediateDirectories: true); directory = shared }
            catch { directory = local } // Finder can deny group filesystem writes while CFPrefs remains available.
        } else { directory = local }
    }
    private var preferencesFile: URL { directory.appendingPathComponent(".settings.json") }
    private struct Identity: Codable { var salt: String; var generation: String }
    private var identityFile: URL { directory.appendingPathComponent(".identity.json") }
    /// A stable lock inode serializes atomic replacements across host and extensions.
    /// Lock acquisition is bounded so optional preferences never hang the UI.
    private func transaction<T>(_ action: () throws -> T) throws -> T {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fd = Darwin.open(directory.appendingPathComponent(".lock").path, O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw PreviewError.unavailable }
        defer { Darwin.close(fd) }
        let deadline = ProcessInfo.processInfo.systemUptime + 0.25
        while flock(fd, LOCK_EX | LOCK_NB) != 0 {
            guard errno == EWOULDBLOCK, ProcessInfo.processInfo.systemUptime < deadline else { throw PreviewError.limit(L10n.text("设置正在由其他进程更新，请重试")) }
            usleep(2_000)
        }
        defer { flock(fd, LOCK_UN) }
        return try action()
    }
    private func boundedData(_ url: URL) -> Data? {
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= 64 * 1024 else { return nil }
        return try? Data(contentsOf: url)
    }
    public func load() -> ReaderSettings {
        let data = boundedData(preferencesFile) ?? defaults.data(forKey: "readerSettings")
        let settings = data.flatMap { try? JSONDecoder().decode(ReaderSettings.self, from: $0) } ?? .init()
        var fields = (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(settings))) as? [String: Any] ?? [:]
        for key in Array(fields.keys) { if let value = defaults.object(forKey: "readerField." + key) { fields[key] = value } }
        guard let merged = try? JSONSerialization.data(withJSONObject: fields), var result = try? JSONDecoder().decode(ReaderSettings.self, from: merged) else { return settings }
        result.codeSize = min(32, max(10, result.codeSize)); result.documentSize = min(36, max(10, result.documentSize))
        return result
    }
    /// CFPrefs supports the extra Quick Look sandbox. One preference key per
    /// field means independent windows never replace each other's entire object.
    private func publishFields(from before: ReaderSettings?, to after: ReaderSettings) {
        let old = before.flatMap { try? JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) as? [String: Any] } ?? [:]
        guard let fields = try? JSONSerialization.jsonObject(with: JSONEncoder().encode(after)) as? [String: Any] else { return }
        for (key, value) in fields {
            if let previous = old[key] as? NSObject, previous.isEqual(value) { continue }
            defaults.set(value, forKey: "readerField." + key)
        }
    }
    private func write(_ settings: ReaderSettings) throws {
        let data = try JSONEncoder().encode(settings)
        guard data.count <= 64 * 1024 else { throw PreviewError.limit(L10n.text("设置大小")) }
        try data.write(to: preferencesFile, options: .atomic)
        defaults.set(data, forKey: "readerSettings") // Migration compatibility, not the cross-process authority.
    }
    public func save(_ settings: ReaderSettings) { publishFields(from: nil, to: settings); try? transaction { try write(settings) } }
    /// Merge only fields changed by this view, preserving concurrent edits elsewhere.
    @discardableResult public func update(from before: ReaderSettings, to after: ReaderSettings) -> ReaderSettings {
        publishFields(from: before, to: after)
        return (try? transaction {
            var current = load()
            if before.codeSize != after.codeSize { current.codeSize = min(32, max(10, after.codeSize)) }
            if before.documentSize != after.documentSize { current.documentSize = min(36, max(10, after.documentSize)) }
            if before.wrapCode != after.wrapCode { current.wrapCode = after.wrapCode }
            if before.lineNumbers != after.lineNumbers { current.lineNumbers = after.lineNumbers }
            if before.theme != after.theme { current.theme = after.theme }
            if before.remember != after.remember { current.remember = after.remember }
            if before.liveReload != after.liveReload { current.liveReload = after.liveReload }
            if before.markdownOutline != after.markdownOutline { current.markdownOutline = after.markdownOutline }
            if before.ignored != after.ignored { current.ignored = after.ignored }
            try write(current); return current
        }) ?? load()
    }
    private func identity() throws -> Identity {
        if let data = boundedData(identityFile), var value = try? JSONDecoder().decode(Identity.self, from: data) {
            if let cleared = defaults.string(forKey: "readingClearGeneration"), cleared != value.generation {
                value.generation = cleared
                for file in try recordFiles() { try? FileManager.default.removeItem(at: file) }
                try JSONEncoder().encode(value).write(to: identityFile, options: .atomic)
            }
            return value
        }
        let value = Identity(salt: defaults.string(forKey: "readingSalt") ?? UUID().uuidString, generation: defaults.string(forKey: "readingClearGeneration") ?? UUID().uuidString)
        try JSONEncoder().encode(value).write(to: identityFile, options: .atomic)
        return value
    }
    public var readingGeneration: String { defaults.string(forKey: "readingClearGeneration") ?? ((try? transaction { try identity().generation }) ?? "unavailable") }
    struct State: Codable { let revision: String; let offset: Int; let date: Date; var section: String? = nil; var byteOffset: Int? = nil; var pageHistory: [Int]? = nil; var generation: String? = nil }
    private func file(_ url: URL, salt: String) -> URL {
        let key = SHA256.hash(data: Data((salt + url.standardizedFileURL.path).utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(key + ".json")
    }
    private func state(_ url: URL, revision: String) -> State? {
        try? transaction {
            guard load().remember, let data = boundedData(file(url, salt: try identity().salt)),
                  let state = try? JSONDecoder().decode(State.self, from: data), state.revision == revision,
                  defaults.string(forKey: "readingClearGeneration") == nil || state.generation == defaults.string(forKey: "readingClearGeneration"),
                  (0..<(30 * 86400)).contains(Date().timeIntervalSince(state.date)) else { throw PreviewError.unavailable }
            return state
        }
    }
    public func restore(_ url: URL, revision: String, byteOffset: Int = 0) -> Int? {
        guard let state = state(url, revision: revision), (state.byteOffset ?? 0) == byteOffset else { return nil }
        return max(0, state.offset)
    }
    public struct PagePosition { public let byteOffset: Int; public let history: [Int] }
    public func restorePage(_ url: URL, revision: String) -> PagePosition? {
        guard let state = state(url, revision: revision) else { return nil }
        let offset = max(0, state.byteOffset ?? 0)
        return .init(byteOffset: offset, history: Array(Set((state.pageHistory ?? []).filter { $0 >= 0 && $0 < offset })).sorted().suffix(128).map { $0 })
    }
    public func restoreSection(_ url: URL, revision: String) -> String? { state(url, revision: revision)?.section }
    public func remember(_ url: URL, revision: String, offset: Int, section: String? = nil, byteOffset: Int = 0, pageHistory: [Int] = [], generation: String? = nil) {
        try? transaction {
            let identity = try identity()
            guard load().remember, generation == nil || generation == (defaults.string(forKey: "readingClearGeneration") ?? identity.generation) else { return }
            let data = try JSONEncoder().encode(State(revision: revision, offset: max(0, offset), date: Date(), section: section, byteOffset: max(0, byteOffset), pageHistory: Array(pageHistory.filter { $0 >= 0 && $0 < byteOffset }.suffix(128)), generation: defaults.string(forKey: "readingClearGeneration") ?? identity.generation))
            guard data.count <= 64 * 1024 else { return }
            try data.write(to: file(url, salt: identity.salt), options: .atomic)
            let files = try recordFiles().sorted { a, b in
                ((try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) > ((try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
            }
            for (index, file) in files.enumerated() {
                let date = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                if index >= 200 || Date().timeIntervalSince(date) > 30 * 86400 { try? FileManager.default.removeItem(at: file) }
            }
        }
    }
    private func recordFiles() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey]).filter { !$0.lastPathComponent.hasPrefix(".") && $0.pathExtension == "json" }
    }
    /// Clear includes every currently open reading session. Only reopening a document
    /// adopts the new generation and may create a new record.
    public func clear() {
        let generation = UUID().uuidString; defaults.set(generation, forKey: "readingClearGeneration")
        try? transaction {
            var value = try identity(); value.generation = generation
            try JSONEncoder().encode(value).write(to: identityFile, options: .atomic)
            for file in try recordFiles() { try? FileManager.default.removeItem(at: file) }
        }
    }
}
