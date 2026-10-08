import Foundation
import UniformTypeIdentifiers

/// Formats delegated to the OS, without registering OrangeLen for their UTIs.
public enum SystemPreviewFormat {
    public static func isMedia(_ url: URL) -> Bool {
        UTType(filenameExtension: url.pathExtension.lowercased())?.conforms(to: .audiovisualContent) == true
    }
    public static func supports(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        // macOS also maps .ts to MPEG transport streams; our .ts files are code.
        if ReadableFormat.codeExtensions.contains(ext) || ReadableFormat.isNamedText(url) { return false }
        if ["doc", "docx", "docm", "dot", "dotx", "xls", "xlsx", "xlsm", "ppt", "pptx", "pptm",
            "pages", "numbers", "key", "odt", "ods", "odp", "rtf", "rtfd", "webarchive", "usdz", "reality"].contains(ext) { return true }
        guard let type = UTType(filenameExtension: ext) else { return false }
        return type.conforms(to: .audiovisualContent) || type.conforms(to: .image)
            || type.conforms(to: .presentation) || type.conforms(to: .spreadsheet)
    }
}
