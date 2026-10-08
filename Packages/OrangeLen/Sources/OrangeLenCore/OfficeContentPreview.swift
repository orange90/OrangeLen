import Foundation

/// Bounded content fallback. Never evaluates formulas, relationships or macros.
public enum OfficeContentPreview {
    public static func supports(_ url: URL) -> Bool {
        ["xlsx", "xlsm", "pptx", "pptm"].contains(url.pathExtension.lowercased())
    }
    private final class Budget {
        let limits: PreviewLimits
        var bytes = 0, nodes = 0
        init(_ limits: PreviewLimits) { self.limits = limits }
        func charge(_ count: Int) throws {
            guard count >= 0, count <= limits.officeTextBytes - bytes else { throw PreviewError.limit("Office 正文/共享字符串字节预算") }
            bytes += count
        }
    }
    public static func text(_ data: Data, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> String {
        let archive = try ArchiveDocument.parse(data, name: "office.zip", limits: limits, cancellation: cancellation)
        let output = Budget(limits), sharedBudget = Budget(limits)
        var shared: [String] = []
        if let entry = archive.entry("xl/sharedStrings.xml") {
            shared = try parse(archive.read(entry, cancellation: cancellation), kind: .shared, shared: [], token: cancellation, budget: sharedBudget).parts
        }
        let sheets = archive.entries.filter { $0.path.hasPrefix("xl/worksheets/sheet") && $0.path.hasSuffix(".xml") && !$0.directory }
        let slides = archive.entries.filter { $0.path.hasPrefix("ppt/slides/slide") && $0.path.hasSuffix(".xml") && !$0.directory }
        let entries = (sheets.isEmpty ? slides : sheets).sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        guard !entries.isEmpty else { throw PreviewError.malformed("没有可读取的工作表或幻灯片") }
        guard entries.count <= 200 else { throw PreviewError.limit("Office 内容预览最多 200 个工作表/幻灯片") }
        var result = "内容预览（按内部文件名排列，可能包含隐藏工作表/幻灯片）\n单元格为未格式化的已保存值：日期可能是序列数，公式缓存可能过期；不计算公式，不还原图表、图片、显示名、样式或自定义顺序。\n"
        try output.charge(result.utf8.count)
        for entry in entries {
            try cancellation.check()
            let heading = "\n—— \(entry.path) ——\n"
            try output.charge(heading.utf8.count)
            let content = try parse(archive.read(entry, cancellation: cancellation), kind: sheets.isEmpty ? .slide : .sheet, shared: shared, token: cancellation, budget: output)
            // Every part and its newline have already been charged before allocation.
            result += heading
            for part in content.parts { result += part; result += "\n" }
        }
        return result
    }
    private static func parse(_ data: Data, kind: XMLContent.Kind, shared: [String], token: Cancellation, budget: Budget) throws -> XMLContent {
        let delegate = XMLContent(kind: kind, shared: shared, token: token, budget: budget)
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true; parser.shouldResolveExternalEntities = false; parser.delegate = delegate
        guard parser.parse(), delegate.failure == nil else {
            try token.check()
            throw delegate.failure ?? PreviewError.malformed("Office XML 损坏或包含不支持的实体声明")
        }
        return delegate
    }
    private final class XMLContent: NSObject, XMLParserDelegate {
        enum Kind { case shared, sheet, slide }
        let kind: Kind, shared: [String], token: Cancellation, budget: Budget
        var parts: [String] = [], buffer = "", cellType = "", address = "", value = "", formula = ""
        var capture: String?, failure: Error?, depth = 0, scratchBytes = 0
        init(kind: Kind, shared: [String], token: Cancellation, budget: Budget) { self.kind = kind; self.shared = shared; self.token = token; self.budget = budget }
        func checked(_ parser: XMLParser, _ action: () throws -> Void) {
            guard failure == nil else { return }
            do { try token.check(); try action() } catch { failure = error; parser.abortParsing() }
        }
        func appendPart(_ pieces: [String]) throws {
            let count = pieces.reduce(1) { $0 + $1.utf8.count }
            try budget.charge(count)
            guard parts.count < budget.limits.structureNodes else { throw PreviewError.limit("Office 单元格/段落数") }
            parts.append(pieces.joined())
        }
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
            checked(parser) {
                depth += 1; budget.nodes += 1
                guard depth <= budget.limits.structureDepth, budget.nodes <= budget.limits.structureNodes else { throw PreviewError.limit("Office XML 深度/节点数") }
                if elementName == "si" || (kind == .slide && elementName == "p") { buffer = ""; scratchBytes = 0 }
                if elementName == "c" {
                    cellType = attributes["t"] ?? ""; address = attributes["r"] ?? "?"; value = ""; formula = ""; scratchBytes = address.utf8.count
                    guard scratchBytes <= budget.limits.officeTextBytes else { throw PreviewError.limit("Office 单元格地址") }
                }
                if ["t", "v", "f"].contains(elementName) { capture = elementName }
            }
        }
        func parser(_ parser: XMLParser, foundCharacters string: String) {
            guard let capture else { return }
            checked(parser) {
                let count = string.utf8.count
                guard count <= budget.limits.officeTextBytes - scratchBytes else { throw PreviewError.limit("Office 单个文本缓冲区") }
                scratchBytes += count
                switch kind {
                case .shared, .slide: if capture == "t" { buffer += string }
                case .sheet: if capture == "f" { formula += string } else { value += string }
                }
            }
        }
        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
            checked(parser) {
                if elementName == capture { capture = nil }
                if kind == .shared && elementName == "si" { try appendPart([buffer]); buffer = ""; scratchBytes = 0 }
                if kind == .slide && elementName == "p" { if !buffer.isEmpty { try appendPart([buffer]) }; buffer = ""; scratchBytes = 0 }
                if kind == .sheet && elementName == "c" {
                    if cellType == "s" {
                        guard let index = Int(value), shared.indices.contains(index) else { throw PreviewError.malformed("Office 共享字符串索引无效") }
                        value = shared[index]
                    }
                    if cellType == "b" { value = value == "1" ? "TRUE" : "FALSE" }
                    var pieces = [address, "\t", value]
                    if !formula.isEmpty { pieces += ["  [公式：", formula, "；仅已保存结果]"] }
                    try appendPart(pieces); value = ""; formula = ""; scratchBytes = 0
                }
                depth -= 1
            }
        }
        func reject(_ parser: XMLParser) { failure = PreviewError.malformed("Office XML 不支持实体声明"); parser.abortParsing() }
        func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) { reject(parser) }
        func parser(_ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) { reject(parser) }
        func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data? { reject(parser); return nil }
    }
}
