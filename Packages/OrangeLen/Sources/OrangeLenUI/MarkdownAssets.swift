import AppKit
import CoreGraphics
import OrangeLenCore

struct MarkdownAssets {
    var rich: [Int: NSImage] = [:]
    var richFailures: [Int: String] = [:]
    var images: [Int: CGImage] = [:]
    var failures: [Int: String] = [:]
    static func load(_ model: TextModel, document: URL, root: URL?, cancellation: Cancellation) throws -> Self {
        var result = Self(); var bytes = 0; var pixels = 0
        let boundary = root ?? document.deletingLastPathComponent()
        for (index, image) in model.images.enumerated() {
            try cancellation.check()
            do {
                guard index < 8, bytes < 20 * 1024 * 1024, pixels < 8_000_000 else { throw PreviewError.limit("文档图片预算") }
                guard let url = MarkdownNavigation.localURL(image.destination, document: document, root: boundary) else {
                    result.failures[image.range.location] = image.destination.hasPrefix("http") ? "加载远程图片" : "图片路径不可访问"; continue
                }
                guard ImagePreview.supports(url) else { result.failures[image.range.location] = "暂不支持此图片格式"; continue }
                let loaded = try ImagePreview.load(url, root: boundary, cancellation: cancellation, maxBytes: min(5 * 1024 * 1024, 20 * 1024 * 1024 - bytes), maxPixelSize: 1200)
                bytes += loaded.bytes
                guard pixels + loaded.image.width * loaded.image.height <= 8_000_000 else { throw PreviewError.limit("文档图片像素预算") }
                pixels += loaded.image.width * loaded.image.height
                result.images[image.range.location] = loaded.image
            } catch is CancellationError { throw CancellationError() }
            catch { result.failures[image.range.location] = "本地图片不可读或超出预算" }
        }
        return result
    }
}

enum MarkdownNavigation {
    static func localURL(_ target: String, document: URL, root: URL) -> URL? {
        guard !target.isEmpty, !target.hasPrefix("//"), let parts = URLComponents(string: target), parts.scheme == nil, parts.host == nil,
              let decoded = parts.percentEncodedPath.removingPercentEncoding, !decoded.isEmpty else { return nil }
        let url = (decoded.hasPrefix("/") ? URL(fileURLWithPath: decoded) : document.deletingLastPathComponent().appendingPathComponent(decoded)).standardizedFileURL
        guard url.pathComponents.starts(with: root.standardizedFileURL.pathComponents) else { return nil }
        return url
    }
    static func slug(_ value: String) -> String {
        value.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_" || CharacterSet.whitespaces.contains($0) }.map(String.init).joined().split(whereSeparator: { $0.isWhitespace }).joined(separator: "-")
    }
}
