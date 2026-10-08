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
            Text(L10n.text("在 Finder 中阅读项目代码、文档和数据。"))
            Text(L10n.text("界面语言跟随 macOS 的首选语言。支持简体中文与英文；更改后请重新打开应用和 Finder 预览。")).font(.caption).foregroundStyle(.secondary)
            Section(L10n.text("阅读")) {
                Slider(value: $settings.documentSize, in: 10...36, step: 1) { Text(L10n.text("文档字号 \(Int(settings.documentSize))")) }
                Slider(value: $settings.codeSize, in: 10...32, step: 1) { Text(L10n.text("代码字号 \(Int(settings.codeSize))")) }
                Picker(L10n.text("外观"), selection: $settings.theme) { Text(L10n.text("系统")).tag("System"); Text(L10n.text("浅色")).tag("Light"); Text(L10n.text("深色")).tag("Dark") }
                Toggle(L10n.text("代码换行"), isOn: $settings.wrapCode)
                Toggle(L10n.text("行号"), isOn: $settings.lineNumbers)
                Toggle(L10n.text("文件保存后自动刷新"), isOn: $settings.liveReload)
                Toggle(L10n.text("Markdown 目录侧栏"), isOn: $settings.markdownOutline)
            }
            Section(L10n.text("本机阅读记录")) {
                Toggle(L10n.text("记住位置（最多 200 项、30 天）"), isOn: $settings.remember)
                Button(L10n.text("清除阅读记录（含当前会话）")) { SettingsStore.shared.clear() }
                Text(L10n.text("清除后，已打开文档不会重新写入记录；重新打开文档后恢复记忆。")).font(.caption)
            }
            Text(SettingsStore.shared.sharedAvailable ? L10n.text("阅读设置用于应用与 Finder 预览。") : L10n.text("此构建的应用与 Finder 设置分别保存。"))
                .font(.caption).foregroundStyle(.secondary)
            Text(L10n.text("文件没有显示预期内容时，可从应用菜单打开“Quick Look 诊断”。"))
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
