import Foundation

@objc public protocol DocumentBrokerProtocol {
    func prepare(reply: @escaping () -> Void)
    func importDocument(_ data: Data, type: String, reply: @escaping (Data?, String?) -> Void)
}
/// Only bounded text and simple formatting cross the process boundary. The host
/// never deserializes importer objects, attachments, links or executable content.
public struct NativeDocumentPayload: Codable, Sendable {
    public struct Span: Codable, Sendable {
        public let location: Int, length: Int
        public let size: Double
        public let bold: Bool, italic: Bool
        public init(location: Int, length: Int, size: Double, bold: Bool, italic: Bool) {
            self.location = location; self.length = length; self.size = size; self.bold = bold; self.italic = italic
        }
    }
    public let text: String
    public let spans: [Span]
    public init(text: String, spans: [Span]) { self.text = text; self.spans = spans }
    public func validate() throws {
        let length = text.utf16.count
        guard text.utf8.count <= 5 * 1024 * 1024, length <= 1_000_000, spans.count <= 20_000 else { throw PreviewError.limit(L10n.text("原生文档输出")) }
        for span in spans {
            guard span.location >= 0, span.length >= 0, span.location <= length,
                  span.length <= length - span.location, span.size.isFinite, (6...72).contains(span.size) else { throw PreviewError.malformed(L10n.text("原生文档格式范围")) }
        }
    }
}
