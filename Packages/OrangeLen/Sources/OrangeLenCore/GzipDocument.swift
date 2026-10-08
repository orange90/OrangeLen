import Foundation

/// One bounded gzip stream. It never trusts the optional embedded filename or writes a file.
public struct GzipDocument: Sendable {
    public let name: String
    public let text: String
    public static func isPlainStream(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "gz" && !url.lastPathComponent.lowercased().hasSuffix(".tar.gz")
    }
    public static func parse(_ data: Data, name: String, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> Self {
        guard data.count <= limits.containerBytes else { throw PreviewError.limit(L10n.text("gzip 输入字节预算")) }
        let ratioLimit = min(limits.fileBytes, max(1, data.count) * limits.archiveRatio)
        let bytes = try ArchiveDocument.inflate(data, window: 31, maximum: ratioLimit, token: cancellation)
        try cancellation.check()
        let inner = String(URL(fileURLWithPath: name).lastPathComponent.dropLast(3))
        let innerURL = URL(fileURLWithPath: inner.isEmpty ? "compressed.txt" : inner)
        guard ReadableFormat.isText(innerURL) || ["jsonl", "ndjson"].contains(innerURL.pathExtension.lowercased()) || innerURL.pathExtension.isEmpty else { throw PreviewError.malformed(L10n.text("gzip 内层格式尚不支持")) }
        return Self(name: innerURL.lastPathComponent, text: try AccessBroker.decode(bytes).0)
    }
}
