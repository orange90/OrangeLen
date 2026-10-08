import AppKit
import OrangeLenCore
import UniformTypeIdentifiers

final class DiagnosticsController: NSViewController {
    let report = NSTextView(), fileLabel = NSTextField(labelWithString: "选择一个文件，检查 Finder 类型匹配与可用入口。")
    var selectedURL: URL?
    var systemListing: String?
    var openFile: ((URL) -> Void)?
    override func loadView() {
        let root = NSStackView(); root.orientation = .vertical; root.alignment = .leading; root.spacing = 12
        root.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let controls = NSStackView(); controls.spacing = 8
        for (title, action) in [("选择文件检查", #selector(choose)), ("重新检查", #selector(refresh)), ("复制系统查询", #selector(readSystemRegistration)), ("导入登记结果…", #selector(importReport)), ("打开扩展设置", #selector(settings)), ("在 OrangeLen 阅读", #selector(read))] {
            controls.addArrangedSubview(NSButton(title: title, target: self, action: action))
        }
        fileLabel.lineBreakMode = .byTruncatingMiddle
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.documentView = report
        report.isEditable = false; report.isSelectable = true; report.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        report.isVerticallyResizable = true; report.autoresizingMask = [.width]; report.textContainer?.widthTracksTextView = true
        report.textContainerInset = NSSize(width: 12, height: 12)
        report.setAccessibilityLabel("Quick Look 诊断结果")
        for child in [controls, fileLabel, scroll] { root.addArrangedSubview(child); child.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -32).isActive = true }
        root.frame = NSRect(x: 0, y: 0, width: 880, height: 600); view = root; refresh()
    }
    @objc func choose() {
        let panel = NSOpenPanel()
        if panel.runModal() == .OK { selectedURL = panel.url; refresh() }
    }
    @objc func read() { if let selectedURL { openFile?(selectedURL) } }
    @objc func settings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") { NSWorkspace.shared.open(url) }
    }
    @objc func readSystemRegistration() {
        let command = #"/usr/bin/pluginkit -m -A -D -v -p com.apple.quicklook.preview > "$HOME/Desktop/OrangeLen-diagnostics.txt""#
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(command, forType: .string)
        report.string = "已复制固定的系统登记查询。\n\n在终端运行后，点击“导入登记结果…”选择桌面的 OrangeLen-diagnostics.txt。\n此查询只读取扩展元数据，不修改启用状态。应用沙盒不能自行读取系统登记，也不能保证能启动 Terminal。"
    }
    @objc func importReport() {
        let panel = NSOpenPanel(); panel.message = "选择固定 pluginkit 查询产生的纯文本结果；最多 1 MiB。"
        if panel.runModal() == .OK, let url = panel.url { importSystemReport(url) }
    }
    func importSystemReport(_ url: URL) {
        do {
            var limits = PreviewLimits(); limits.fileBytes = 1024 * 1024
            systemListing = try AccessBroker.read(url, limits: limits).text
            refresh()
        } catch { report.string = "系统报告不可读取：" + error.localizedDescription }
    }
    @objc func refresh() {
        fileLabel.stringValue = selectedURL?.path ?? "选择一个文件，检查 Finder 类型匹配与可用入口。"
        report.string = "正在读取本机扩展登记…"
        let url = selectedURL, knownListing = systemListing
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let listing = knownListing ?? "尚未读取系统登记。点击“复制系统查询”，在终端运行后，通过“导入登记结果…”读取结果。"
            var lines = ["OrangeLen · 本机 Quick Look 诊断", "", "系统：\(ProcessInfo.processInfo.operatingSystemVersionString)", "应用：\(Bundle.main.bundleURL.path)", ""]
            if let url {
                let scope = url.startAccessingSecurityScopedResource(); defer { if scope { url.stopAccessingSecurityScopedResource() } }
                let type = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType) ?? UTType(filenameExtension: url.pathExtension)
                lines += ["文件：\(url.lastPathComponent)", "系统识别类型：\(type?.identifier ?? "未知")", "阅读器识别：\(ReadableFormat.isText(url) || ReadableFormat.isCollection(url) ? "可读取" : ["svg", "excalidraw", "pdf"].contains(url.pathExtension.lowercased()) ? "专用预览" : "需实际读取检查")", ""]
                let plugins = Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns")
                let ownTypes = ((try? FileManager.default.contentsOfDirectory(at: plugins, includingPropertiesForKeys: nil)) ?? []).filter { $0.pathExtension == "appex" }.flatMap { Self.types($0) }
                let matched = type.map { actual in ownTypes.filter { UTType($0).map { actual.conforms(to: $0) } ?? (actual.identifier == $0) } } ?? []
                if matched.isEmpty {
                    lines += ["Finder 单文件入口：未匹配已声明的类型。", "文件名识别发生在阅读器收到文件之后，因此不能保证 Finder 会调用。", "可用入口：上方“在 OrangeLen 阅读”；也可预览所在文件夹后点选文件。", ""]
                } else {
                    lines += ["Finder 类型声明匹配：\(matched.joined(separator: ", "))", "类型匹配表示具备候选资格，最终选择仍由系统决定。", ""]
                }
                if let type {
                    let candidates = listing.split(separator: "\n").compactMap { line -> String? in
                        let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
                        guard let path = fields.last, path.hasSuffix(".appex") else { return nil }
                        let plugin = URL(fileURLWithPath: String(path))
                        guard Self.types(plugin).contains(where: { UTType($0).map { type.conforms(to: $0) } ?? (type.identifier == $0) }) else { return nil }
                        return String(fields[0]).trimmingCharacters(in: .whitespaces) + "\n  " + path
                    }
                    lines += ["匹配该类型的登记项（可能重叠，不代表正在接管）：", candidates.isEmpty ? "未读到匹配登记项；沙盒可能限制查询或其他应用信息读取。" : candidates.joined(separator: "\n"), ""]
                }
            }
            lines += ["扩展登记原始结果：", listing, "", "+ 表示用户选择启用，- 表示用户选择停用；空白表示未显式选择。", "同一标识有多条路径可能来自开发构建登记。诊断不会更改其他工具。", "关闭当前 Quick Look 再打开，才能检查新版本实际效果。"]
            let output = lines.joined(separator: "\n")
            DispatchQueue.main.async { self?.report.string = output }
        }
    }
    private static func types(_ url: URL) -> [String] {
        guard let data = try? Data(contentsOf: url.appendingPathComponent("Contents/Info.plist")), let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any], let ext = plist["NSExtension"] as? [String: Any], let attributes = ext["NSExtensionAttributes"] as? [String: Any] else { return [] }
        return attributes["QLSupportedContentTypes"] as? [String] ?? []
    }
}
