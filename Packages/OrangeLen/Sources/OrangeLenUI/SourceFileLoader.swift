import Foundation
import OrangeLenCore

enum SourceFileLoader {
    static func read(_ url: URL, root: URL?, byteOffset: Int = 0, cancellation: Cancellation) throws -> SourceSnapshot {
        let ext = url.pathExtension.lowercased()
        if ext != "class" {
            do {
                return try AccessBroker.readPreview(url, root: root, byteOffset: byteOffset, pageBytes: 64 * 1024, fullReadThreshold: 1024 * 1024, cancellation: cancellation)
            } catch let error as PreviewError {
                switch error {
                case .binary, .encoding:
                    guard byteOffset == 0, SourceCodeFormats.propertyListExtensions.contains(ext) || SourceCodeFormats.appleScriptExtensions.contains(ext) || ext == "a3x" else { throw error }
                default: throw error
                }
            }
        }
        guard byteOffset == 0 else { throw PreviewError.changed }
        let raw = try AccessBroker.readBytes(url, root: root, cancellation: cancellation)
        if let converted = try BinarySourcePreview.text(raw.data, extension: ext, cancellation: cancellation) {
            return SourceSnapshot(text: converted.text, encoding: converted.label, byteCount: raw.data.count, revision: raw.revision)
        }
        if SourceCodeFormats.appleScriptExtensions.contains(ext) {
            let text = try NativeDocumentClient.decompileAppleScript(raw.data, cancellation: cancellation)
            return SourceSnapshot(text: text, encoding: "AppleScript · decompiled source", byteCount: raw.data.count, revision: raw.revision)
        }
        throw PreviewError.binary
    }
}
