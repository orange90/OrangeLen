import Foundation
public struct FolderReadme: Sendable {
    public let url: URL
    public let excerpt: String
}
public enum ProjectOverview {
    /// A bounded, local-only excerpt. No image resolution or rich-content rendering.
    public static func readme(_ root: URL, cancellation: Cancellation = .init()) throws -> FolderReadme? {
        let scope = root.startAccessingSecurityScopedResource()
        defer { if scope { root.stopAccessingSecurityScopedResource() } }
        try AccessBroker.validate(root)
        for name in ["README.md", "readme.md", "Readme.md", "README.markdown", "README.txt", "README"] {
            try cancellation.check()
            let url = root.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let raw = try AccessBroker.readPreview(url, root: root, pageBytes: 32 * 1024, fullReadThreshold: 0, cancellation: cancellation)
            let decoded = raw.text
            let model = try MarkdownModel.parse(decoded, cancellation: cancellation)
            let excerpt = model.display.trimmingCharacters(in: .whitespacesAndNewlines)
            return FolderReadme(url: url, excerpt: String(excerpt.prefix(500)) + (excerpt.count > 500 || raw.partial ? "…" : ""))
        }
        return nil
    }

    public static func read(_ root: URL, cancellation: Cancellation = .init()) throws -> String {
        try AccessBroker.validate(root)
        var text = "# \(root.lastPathComponent)\n\n选择左侧文件，在同一窗口阅读。项目线索来自声明文件，不表示依赖已安装或项目可以运行。\n\n"
        var limits = PreviewLimits(); limits.fileBytes = 200 * 1024
        for name in ["README.md","README.markdown","package.json","pyproject.toml","Cargo.toml","go.mod"] {
            try cancellation.check()
            let url = root.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath:url.path) else { continue }
            let encoded = name.addingPercentEncoding(withAllowedCharacters:.urlPathAllowed) ?? name
            text += "- [\(name)](\(encoded))"
            if name.hasPrefix("README") { text += " · 文档入口\n"; continue }
            do {
                let source = try AccessBroker.read(url,root:root,limits:limits,cancellation:cancellation)
                if name == "package.json" {
                    _ = try JSONParser.parse(source.text,cancellation:cancellation)
                    let json = try JSONSerialization.jsonObject(with:Data(source.text.utf8)) as? [String:Any]
                    let keys = ["name","version","description","type"]
                    text += " · JavaScript/Node 声明"
                    for key in keys { if let value = json?[key] as? String { text += "\n  - \(key)：" + safe(value) } }
                } else {
                    text += " · " + (name == "go.mod" ? "Go" : name == "Cargo.toml" ? "Rust/Cargo" : "Python") + " 声明"
                    for line in source.text.components(separatedBy:"\n").prefix(80) where line.hasPrefix("name") || line.hasPrefix("version") || line.hasPrefix("module ") || line.hasPrefix("go ") || line.hasPrefix("requires-python") {
                        text += "\n  - " + safe(line)
                    }
                }
                text += "\n"
            } catch is CancellationError { throw CancellationError() }
            catch { text += " · 未能读取：" + safe(error.localizedDescription) + "\n" }
        }
        return text + "\n不会执行脚本或安装依赖。大小为文件逻辑大小之和；包含隐藏项及子文件夹，不跟随符号链接。统计期间数字持续更新，无法读取的项目会标记为部分结果。"
    }
    private static func safe(_ value: String) -> String {
        String(value.prefix(200)).replacingOccurrences(of:"\n",with:" ").replacingOccurrences(of:"[",with:"\\[").replacingOccurrences(of:"*",with:"\\*").replacingOccurrences(of:"<",with:"\\<")
    }
}
