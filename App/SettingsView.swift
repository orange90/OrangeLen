import SwiftUI
import OrangeLenCore
struct SettingsView: View {
    @State var settings = SettingsStore.shared.load()
    var body: some View {
        Form {
            Text("OrangeLen").font(.largeTitle.bold())
            Text("Quick Look for Developers").foregroundStyle(.secondary)
            Text("本地、只读的开发者预览。Finder 调用与应用内预览的验证状态请见仓库 docs/verification.md。")
            Section("阅读") {
                Slider(value: $settings.documentSize, in: 10...36, step: 1) { Text("文档字号 \(Int(settings.documentSize))") }
                Slider(value: $settings.codeSize, in: 10...32, step: 1) { Text("代码字号 \(Int(settings.codeSize))") }
                Picker("外观", selection: $settings.theme) { Text("系统").tag("System"); Text("浅色").tag("Light"); Text("深色").tag("Dark") }
                Toggle("代码换行", isOn: $settings.wrapCode)
                Toggle("行号", isOn: $settings.lineNumbers)
                Toggle("当前句高亮", isOn: $settings.highlight)
                Toggle("正文变淡", isOn: $settings.dim)
                Picker("阅读尺", selection: $settings.rulerLines) { Text("关闭").tag(0); Text("1 行").tag(1); Text("3 行").tag(3); Text("5 行").tag(5) }
            }
            Section("本机阅读记录") {
                Toggle("记住位置（最多 200 项、30 天）", isOn: $settings.remember)
                Button("清除阅读记录") { SettingsStore.shared.clear() }
            }
            Text(SettingsStore.shared.sharedAvailable ? "App Group 容器可用；跨进程同步须另行验证。" : "当前开发构建未配置 App Group，设置与记录限各自容器。可在 Finder 预览工具栏调整扩展设置。")
                .font(.caption).foregroundStyle(.secondary)
            Text("启用扩展：系统设置 → 通用 → 登录项与扩展 → Quick Look → OrangeLen。若格式仍由系统或其他扩展接管，请查看支持矩阵。")
                .font(.caption)
        }
        .formStyle(.grouped).frame(width: 600, height: 720)
        .onChange(of: settings) { _, value in SettingsStore.shared.save(value) }
    }
}
