import Foundation
public enum ProjectOverview {
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
        return text + "\n不会执行脚本、安装依赖或扫描依赖目录。目录计数是有界元数据快照。"
    }
    private static func safe(_ value: String) -> String {
        String(value.prefix(200)).replacingOccurrences(of:"\n",with:" ").replacingOccurrences(of:"[",with:"\\[").replacingOccurrences(of:"*",with:"\\*").replacingOccurrences(of:"<",with:"\\<")
    }
}
