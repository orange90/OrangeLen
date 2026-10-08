import Foundation

/// Bounded content fallback for Office sheets/slides inside a Finder extension.
/// Does not evaluate formulas, load relationships, run macros, or fetch resources.
public enum OfficeContentPreview {
    public static func supports(_ url: URL) -> Bool {
        ["xlsx", "xlsm", "pptx", "pptm"].contains(url.pathExtension.lowercased())
    }

    public static func text(_ data: Data, cancellation: Cancellation = .init()) throws -> String {
        let archive = try ArchiveDocument.parse(data, name: "office.zip", cancellation: cancellation)
        var shared: [String] = []
        if let entry = archive.entry("xl/sharedStrings.xml") {
            shared = try parse(archive.read(entry, cancellation: cancellation), kind: .shared, shared: [], token: cancellation).parts
        }
        let sheets = archive.entries.filter { $0.path.hasPrefix("xl/worksheets/sheet") && $0.path.hasSuffix(".xml") && !$0.directory }
        let slides = archive.entries.filter { $0.path.hasPrefix("ppt/slides/slide") && $0.path.hasSuffix(".xml") && !$0.directory }
        let entries = (sheets.isEmpty ? slides : sheets).sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        guard !entries.isEmpty else { throw PreviewError.malformed("没有可读取的工作表或幻灯片") }
        guard entries.count <= 200 else { throw PreviewError.limit("Office 内容预览最多 200 个工作表/幻灯片") }
        var result = "内容预览（按内部文件名排列）\n表格显示单元格地址及已保存值；不计算公式，不还原图表、图片或幻灯片版式。\n"
        for entry in entries {
            try cancellation.check()
            let content = try parse(archive.read(entry, cancellation: cancellation), kind: sheets.isEmpty ? .slide : .sheet, shared: shared, token: cancellation)
            result += "\n—— \(entry.path) ——\n" + content.parts.joined(separator: "\n") + "\n"
            guard result.utf8.count <= 5 * 1024 * 1024 else { throw PreviewError.limit("Office 正文 5 MiB") }
        }
        return result
    }

    private static func parse(_ data: Data, kind: XMLContent.Kind, shared: [String], token: Cancellation) throws -> XMLContent {
        let delegate = XMLContent(kind: kind, shared: shared, token: token)
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate
        guard parser.parse(), !delegate.rejected else {
            try token.check()
            throw PreviewError.malformed("Office XML 损坏或包含不支持的实体声明")
        }
        return delegate
    }

    private final class XMLContent: NSObject, XMLParserDelegate {
        enum Kind { case shared, sheet, slide }
        let kind: Kind, shared: [String], token: Cancellation
        var parts: [String] = [], buffer = "", cellType = "", address = "", value = "", formula = ""
        var capture: String?, rejected = false
        init(kind: Kind, shared: [String], token: Cancellation) { self.kind = kind; self.shared = shared; self.token = token }
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
            do { try token.check() } catch { parser.abortParsing(); return }
            if elementName == "si" { buffer = "" }
            if elementName == "c" { cellType = attributes["t"] ?? ""; address = attributes["r"] ?? "?"; value = ""; formula = "" }
            if ["t", "v", "f"].contains(elementName) { capture = elementName }
        }
        func parser(_ parser: XMLParser, foundCharacters string: String) {
            guard let capture else { return }
            switch kind {
            case .shared, .slide: if capture == "t" { buffer += string }
            case .sheet: if capture == "f" { formula += string } else { value += string }
            }
        }
        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
            if elementName == capture { capture = nil }
            if kind == .shared && elementName == "si" { parts.append(buffer); buffer = "" }
            if kind == .slide && elementName == "p" { if !buffer.isEmpty { parts.append(buffer) }; buffer = "" }
            if kind == .sheet && elementName == "c" {
                if cellType == "s", let index = Int(value), shared.indices.contains(index) { value = shared[index] }
                if cellType == "b" { value = value == "1" ? "TRUE" : "FALSE" }
                if !formula.isEmpty { value += "  [公式：\(formula)；仅已保存结果]" }
                parts.append("\(address)\t\(value)")
            }
        }
        func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) { rejected = true; parser.abortParsing() }
        func parser(_ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) { rejected = true; parser.abortParsing() }
        func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data? { rejected = true; parser.abortParsing(); return nil }
    }
}
