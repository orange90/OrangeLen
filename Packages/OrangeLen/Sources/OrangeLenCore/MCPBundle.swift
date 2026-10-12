import Foundation

public enum MCPBundle {
    public static func summary(_ archive: ArchiveDocument, name: String = "", cancellation: Cancellation = .init()) throws -> String {
        guard let entry = archive.entry("manifest.json"), !entry.directory else { throw PreviewError.malformed(L10n.text("MCP 包缺少根目录 manifest.json")) }
        let data = try archive.read(entry, cancellation: cancellation)
        guard data.count <= 1024 * 1024 else { throw PreviewError.limit(L10n.text("MCP 清单最多 1 MiB")) }
        let source = try AccessBroker.decode(data).0
        _ = try JSONParser.parse(source, cancellation: cancellation)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw PreviewError.malformed(L10n.text("MCP 清单必须是 JSON 对象")) }
        if name.lowercased().hasSuffix(".n8np") {
            guard object["packageFormatVersion"] as? String == "1" else { throw PreviewError.malformed("n8n packageFormatVersion") }
            let inventory = ["workflows","folders","projects","credentials","dataTables","variables","tags"].map { key in key + ": " + String((object[key] as? [Any])?.count ?? 0) }.joined(separator:"\n")
            return "n8n package\n\n" + inventory + "\n\nmanifest.json\n" + source
        }
        func value(_ key: String) -> String { (object[key] as? String) ?? "—" }
        let server = object["server"] as? [String: Any] ?? [:]
        var result = L10n.text("MCP 扩展包") + "\n\n"
        result += L10n.text("名称") + ": " + value("name") + "\n"
        result += L10n.text("版本") + ": " + value("version") + "\n"
        result += L10n.text("说明") + ": " + value("description") + "\n"
        result += L10n.text("运行类型") + ": " + ((server["type"] as? String) ?? "—") + "\n"
        result += L10n.text("入口") + ": " + ((server["entry_point"] as? String) ?? "—") + "\n\n"
        result += L10n.text("清单原文") + "\n" + source
        return result
    }
}
