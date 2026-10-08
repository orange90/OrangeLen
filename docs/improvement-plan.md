# OrangeLen 竞品补强交付清单

用户要求（2026-10-04，本次聊天）：落实上轮高、中、低优先级建议及发布前必补项；说明变化并附真实截图。2026-10-05 状态如下。全部目标仍保留；代码、组件、Finder 和发布验收分开，不将竞品官网描述等同实测。

| 要求 | 当前状态 | 证据 / 限制 |
|---|---|---|
| 按语言高亮、围栏语言识别、原文不变 | 已实现并测试 | 180+ 库语法、语言/源文校验测试；Finder Markdown/归档 Swift |
| 文件类型、扩展启用/冲突诊断及可用入口 | 已实现，宿主实际导入通过 | host-diagnostics.png；登记导入手动执行固定查询，候选不等于接管 |
| 可折叠 Markdown 目录、front matter、提示块、脚注、代码块复制 | 已实现，核心/集成测试通过 | finder-markdown.png；实际 NSEvent 菜单分派/粘贴板验证保留空行、CRLF、Unicode；完整 Finder 菜单交互仍需继续 |
| 单文件 Markdown 本地图片显式授权 | 宿主授权→Finder 读取/关闭撤销已实测 | finder-local-images-authorized/revoked.png；短期 bookmark 共享，30 秒心跳失效；原地选目录仍需宿主 |
| Excalidraw、SVG、Mermaid 缩放/平移/适合窗口 | 已实现并测试 | finder-mermaid-zoom.png；宿主 AX 的 + 按钮 128%→160%，fit 恢复；有界栅格 |
| 大文件部分预览/分页/按需读取与准确范围 | 已实现并测试 | UTF-8/UTF-16 无损重组测试；9.96 MB 宿主第二页；Finder Swift 分页已观察 |
| 压缩包目录树、排序、筛选 | 已实现，Finder 实测 | finder-archive-tree/filter.png；不落盘解压，既有格式/预算限制保留 |
| SQLite 分页、排序、列元数据；表格导航 | 已实现，Finder 实测 | 1002 行到第二/末页、数值列全表排序；finder-sqlite-page2/sorted.png |
| 文件保存后自动刷新、阅读位置保持 | 已实现，组件集成验证 | 原子替换、过期任务、表/页/排序、归档选中项恢复；目录树变化需重开 |
| 按格式类别启用与竞品共存 | 七扩展已安装；停用升级保留实测 | category-upgrade.txt：Data 明确停用后升级仍停用，已恢复原启用选择；纯文本基础回退仍可能存在 |
| Finder 冷启动、连续切换、大目录、窄窗及辅助功能 | 部分验收 | 85 测试含 20 次取消/切换、2101 项五批、360/1000 点；真实 Finder 已五批读完 2101 项、四格式 20 次切换；另有 20 个 6–8 MB 文件前进/快速返回、六个检查点一致；冷启动计时、VoiceOver/高对比/多屏未完成 |
| 安装/升级、Release、签名/公证/Gatekeeper | 本机开发安装与通用编译通过；发布未验收 | install.log / universal-build.txt；缺 Developer ID 和已配置公证 profile |
| 多系统/架构兼容 | CI 已准备；运行未验收 | macOS 15/26 × arm64/Intel 工作流未推送运行；14 需测试机；本机只有 26.6.2/M3 Pro |
| 实际截图、前后区别与有边界竞品对照 | 已整理 | [交付说明](improvement-report.md)；没有同机安装竞品性能结论 |

不能宣称：所有必补项已经全部验收、竞品全部性能领先、未实测系统已兼容、开发签名等同公证、宿主预览等同 Finder 调用。
