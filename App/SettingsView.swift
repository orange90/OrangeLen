import SwiftUI
import OrangeLenCore
struct SettingsView: View {
    @State var settings = SettingsStore.shared.load()
    @State private var baseline = SettingsStore.shared.load()
    private let refresh = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        Form {
            Text("OrangeLen").font(.largeTitle.bold())
            Text("Quick Look for Developers").foregroundStyle(.secondary)
            Text("在 Finder 中阅读项目代码、文档和数据。")
            Section("阅读") {
                Slider(value: $settings.documentSize, in: 10...36, step: 1) { Text("文档字号 \(Int(settings.documentSize))") }
                Slider(value: $settings.codeSize, in: 10...32, step: 1) { Text("代码字号 \(Int(settings.codeSize))") }
                Picker("外观", selection: $settings.theme) { Text("系统").tag("System"); Text("浅色").tag("Light"); Text("深色").tag("Dark") }
                Toggle("代码换行", isOn: $settings.wrapCode)
                Toggle("行号", isOn: $settings.lineNumbers)
                Toggle("文件保存后自动刷新", isOn: $settings.liveReload)
                Toggle("Markdown 目录侧栏", isOn: $settings.markdownOutline)
            }
            Section("本机阅读记录") {
                Toggle("记住位置（最多 200 项、30 天）", isOn: $settings.remember)
                Button("清除阅读记录（含当前会话）") { SettingsStore.shared.clear() }
                Text("清除后，已打开文档不会重新写入记录；重新打开文档后恢复记忆。").font(.caption)
            }
            Text(SettingsStore.shared.sharedAvailable ? "阅读设置用于应用与 Finder 预览。" : "此构建的应用与 Finder 设置分别保存。")
                .font(.caption).foregroundStyle(.secondary)
            Text("文件没有显示预期内容时，可从应用菜单打开“Quick Look 诊断”。")
                .font(.caption)
        }
        .formStyle(.grouped).frame(width: 600, height: 720)
        .onChange(of: settings) { _, value in
            guard value != baseline else { return }
            let merged = SettingsStore.shared.update(from: baseline, to: value)
            baseline = merged; settings = merged
        }
        .onReceive(refresh) { _ in
            let latest = SettingsStore.shared.load(); baseline = latest; settings = latest
        }
    }
}
