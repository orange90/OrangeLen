import Foundation

public struct DocumentSection: Sendable {
    public let id: String
    public let title: String
    public let text: String
    public let markdown: Bool
    public let image: Data?
    public let warning: String
    public init(id: String, title: String, text: String, markdown: Bool = false, warning: String = "", image: Data? = nil) {
        self.id = id; self.title = title; self.text = text; self.markdown = markdown; self.warning = warning; self.image = image
    }
}
public enum EnhancedDocuments {
    public static func jsonLines(_ source: String, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> [DocumentSection] {
        var result: [DocumentSection] = []; var offset = 0
        for line in source.components(separatedBy: "\n") {
            try cancellation.check(); defer { offset += line.utf16.count + 1 }
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            guard result.count < limits.tableRows else { throw PreviewError.limit(L10n.text("JSONL 5,000 条记录")) }
            let warning: String
            do { _ = try JSONParser.parse(line, limits: limits, cancellation: cancellation); warning = "" }
            catch is CancellationError { throw CancellationError() }
            catch { warning = error.localizedDescription }
            result.append(.init(id: String(offset), title: L10n.text("记录 \(result.count+1)") + (warning.isEmpty ? "" : L10n.text(" · 损坏行")), text: line, warning: warning))
        }
        return result
    }
    public static func notebook(_ source: String, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> [DocumentSection] {
        // First bound depth/node count before Foundation creates nested objects.
        _ = try JSONParser.parse(source, limits: limits, cancellation: cancellation)
        guard let root = try JSONSerialization.jsonObject(with: Data(source.utf8)) as? [String:Any],
              (root["nbformat"] as? Int) == 4, let cells = root["cells"] as? [[String:Any]] else { throw PreviewError.malformed(L10n.text("仅支持 Notebook nbformat 4")) }
        guard cells.count <= limits.notebookCells else { throw PreviewError.limit("Notebook 1,000 cells") }
        func text(_ value: Any?) -> String { (value as? String) ?? (value as? [String])?.joined() ?? "" }
        var result: [DocumentSection] = []
        for (index, cell) in cells.enumerated() {
            try cancellation.check()
            let type = cell["cell_type"] as? String ?? "raw", body = text(cell["source"])
            result.append(.init(id:"cell-\(index)", title:"\(index+1) · \(type)", text:body, markdown:type == "markdown"))
            let outputs = cell["outputs"] as? [[String:Any]] ?? []
            guard outputs.count <= 100 else { throw PreviewError.limit(L10n.text("每 cell 输出数")) }
            for (n, output) in outputs.enumerated() {
                let data = output["data"] as? [String:Any] ?? [:]
                let value = text(output["text"]).isEmpty ? text(data["text/plain"]) : text(output["text"])
                let error = (output["traceback"] as? [String])?.joined(separator:"\n") ?? ""
                var png: Data?
                if let encoded = data["image/png"] {
                    let value = text(encoded)
                    guard value.utf8.count <= 7 * 1024 * 1024 else { throw PreviewError.limit(L10n.text("Notebook 图片输入")) }
                    png = Data(base64Encoded:value,options:.ignoreUnknownCharacters)
                }
                let omitted = data.keys.filter { $0 != "text/plain" && ($0 != "image/png" || png == nil) }.sorted()
                let detail = !value.isEmpty ? value : !error.isEmpty ? error : L10n.text("没有可安全显示的纯文本输出")
                result.append(.init(id:"cell-\(index)-output-\(n)",title:L10n.text("\(index+1) · 已有输出 \(n+1)"),text:png == nil ? detail : L10n.text("![已有 PNG 输出](output.png)\n\n") + detail,markdown:png != nil,warning:omitted.isEmpty ? L10n.text("已有输出，只读；不运行 kernel") : L10n.text("未执行/未渲染 MIME：") + omitted.joined(separator:", "),image:png))
            }
        }
        return result
    }
    public static func diff(_ source: String, cancellation: Cancellation = .init()) throws -> [DocumentSection] {
        var sections: [DocumentSection] = []; var current = ""; var title = L10n.text("补丁说明"); var number = 0
        for line in source.components(separatedBy:"\n") {
            try cancellation.check()
            if line.hasPrefix("diff --git ") || (line.hasPrefix("--- ") && !current.isEmpty && !current.contains("diff --git ")) {
                if !current.isEmpty { sections.append(.init(id:String(number),title:title,text:current)); number += 1 }
                current = ""; title = String(line.prefix(180))
            }
            current += line + "\n"
            guard sections.count < 1000 else { throw PreviewError.limit(L10n.text("补丁文件分块 1,000")) }
        }
        if !current.isEmpty { sections.append(.init(id:String(number),title:title,text:current)) }
        return sections
    }
}

extension EnhancedDocuments {
    public static func har(_ source: String, cancellation: Cancellation = .init()) throws -> [DocumentSection] {
        _ = try JSONParser.parse(source,cancellation:cancellation)
        guard let object = try JSONSerialization.jsonObject(with:Data(source.utf8)) as? [String:Any],
              let log = object["log"] as? [String:Any], let entries = log["entries"] as? [[String:Any]], entries.count <= 1000 else { throw PreviewError.malformed(L10n.text("HAR log.entries 缺失或超过 1,000")) }
        return try entries.enumerated().map { index, entry in
            try cancellation.check()
            let request = entry["request"] as? [String:Any] ?? [:], response = entry["response"] as? [String:Any] ?? [:]
            let method = request["method"] as? String ?? "?", url = String((request["url"] as? String ?? "?").prefix(300))
            let data = try JSONSerialization.data(withJSONObject:entry,options:[.prettyPrinted,.sortedKeys])
            return .init(id:"har-\(index).json",title:"\(response["status"] ?? "?") · \(method) \(url)",text:String(decoding:data,as:UTF8.self),warning:L10n.text("HAR 记录仅浏览；不重放请求，不获取 response 外链"))
        }
    }
    public static func openAPI(_ source: String, cancellation: Cancellation = .init()) throws -> [DocumentSection] {
        _ = try JSONParser.parse(source,cancellation:cancellation)
        guard let root = try JSONSerialization.jsonObject(with:Data(source.utf8)) as? [String:Any], root["openapi"] != nil || root["swagger"] != nil,
              let paths = root["paths"] as? [String:Any], paths.count <= 1000 else { throw PreviewError.malformed(L10n.text("OpenAPI/Swagger JSON paths 缺失或超预算")) }
        return try paths.keys.sorted().enumerated().map { index, path in
            try cancellation.check()
            let value = paths[path] ?? [:]
            let data = try JSONSerialization.data(withJSONObject:value,options:[.prettyPrinted,.sortedKeys,.fragmentsAllowed])
            return .init(id:"path-\(index).json",title:path,text:String(decoding:data,as:UTF8.self),warning:L10n.text("只读路径定义；不请求 API，不解析外部 $ref"))
        }
    }
}
