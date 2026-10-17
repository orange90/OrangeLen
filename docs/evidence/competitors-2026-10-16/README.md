# 免费竞品实测证据

2026-10-16，macOS 26.6.2。结论与限制见 [完整报告](../../competitor-free-ai-hands-on-2026-10-16.md)。

- samples.json / samples/：17 份合成样例及来源、大小、SHA-256。01 Markdown 是普通卡片内容，非 AGENTS.md 作用域测试。
- spacebar/：17 次直接 Finder Space 截图和 AX 文本；folder-* 为 Markdown 预览的侧栏入口补测，Quick Look 标题可能仍为初始 Markdown，内部路径和正文为实际成员。
- glance/：17 次直接 Finder Space 截图和 AX 文本。
- orangelen/：基线。早期文件编号偏移，必须按 capture-index.json 查实际文件；原始截图内的文件名是判定依据。MDC 本轮已在 CUA 输出观察，但没有单独保存截图，不冒充已有证据文件。
- omni/：仅前 6 项。第 7 项开始前桌面自动化 native pipe 中断，重试/会话重置未恢复。后 11 项未测。
- netron/：ONNX 直接 Finder 与宿主自带模型的卡片结果；没有网络图通过结论。
- runtime-content-types.tsv / extension-manifests.json：本机实际类型与原始扩展声明。
- plugins-before.txt / plugins-restored.txt：开始和恢复后的注册状态。OrangeLen 七类保持 use，新竞品扩展为 ignore。恢复后未能再次进行 CUA Finder 现场核验。
- installed.json / downloads.json：官方二进制来源、Release 版本、包内版本、签名和系统评估输出。没有绕过许可、购买或修改安全设置。

下载包和安装应用不纳入代码交付；当前保留在 build/competitor-audit-20261016 与 ~/Applications，后者扩展已关闭。未改变 OrangeLen 产品代码，没有构建、提交、推送或发布。

## 2026-10-16 用户要求卸载

已移除本轮四款应用、下载包、解包副本、调研源码副本和可直接删除的偏好/缓存/支持文件；扩展及LaunchServices注册已注销，OrangeLen扩展保持启用。九个受保护沙盒容器已由Finder移入废纸篓，永久删除依桌面工具规则等待用户现场确认。报告、截图、合成样例保留。见 uninstall-verification.json。上文保留应用/下载包的说明是此前测试结束时的历史状态，现已更新。

用户随后明确确认永久删除九个竞品容器。CUA Finder执行所选九项的立即删除，最终Bin显示0 items，见uninstall-trash-empty.txt/png。永久删除已完成。
