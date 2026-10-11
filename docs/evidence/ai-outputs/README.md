# AI 产出预览验证（2026-10-11）

环境：macOS 26.6.2 / Apple M3 Pro / Xcode 26.5，本机 Apple Development 签名安装至 `~/Applications/OrangeLen.app`。部署下限 macOS 14，不代表旧系统或 Intel 已现场验收。

构建日志仅清理行尾空白以通过 Git 空白检查，未更改命令与结果；原始日志保留在 `/tmp/orangelen-ai-build.log`。

## 自动验证

- [最终完整 SwiftPM 回归](tests.log)：151 项登记，149 通过，2 项专用 XPC 宿主测试按已有条件跳过，0 失败。包含新格式 7 项 Core + 5 项 UI 测试。
- [最终 Debug 构建](build.log)成功；[开发签名安装](install.log)包含 nested/deep/strict 验签及注册。Swift 编译无错误，AppIntents 无依赖提示为既有构建提示。
- [另一次完整回归](memory-admission-run.log)在既有大文件 UI 测试触发进程 RSS 512 MiB 准入保护，一项测试出现六个后续断言失败；没有提高或关闭预算。重新启动测试进程后最终完整回归通过；未把该失败隐去，也不据此宣称压力场景全部通过。

## 真实界面观察

通过 CUA 操作 Finder 空格预览和主应用文件选择器，检查辅助功能正文并实际查看截图。注册或组件通过不单独计作 Finder 验收。

| 入口 | 本次结果 | 证据 |
| --- | --- | --- |
| Finder 单文件 `.mmd` | 流程图及源码切换实际显示 | 本轮现场观察；补充时序图见下行 |
| Finder 文件夹 `.mermaid` | 中文时序图、缩放控件实际显示 | [图形](finder-mermaid.png)、[AX](finder-mermaid.txt) |
| Finder 单文件 SRT | 两条时间码/字幕表格实际显示 | [截图](finder-srt.png)，截图早于字幕列宽改进 |
| Finder 文件夹 VTT | 时间表格及第二行字幕完整可见 | [最终截图](finder-vtt.png)、[AX](finder-vtt.txt) |
| Finder 单文件 MCPB | 默认清单概览和目录树实际显示 | [截图](finder-mcpb.png) |
| Finder 文件夹 DXT | 清单概览及选择 `server/index.js` 后源码实际显示 | [概览截图](finder-dxt.png)、[概览 AX](finder-dxt.txt)；成员源码在本轮现场检查 |
| Finder 文件夹 PNG | 原图、A1111 参数、ComfyUI 概览及原始 JSON 同时显示 | [截图](finder-image-parameters.png)、[AX](finder-image-parameters.txt) |
| Finder 文件夹 WebP | 原图和 EXIF workflow 同时显示 | [截图](finder-webp-parameters.png)、[AX](finder-webp-parameters.txt) |
| 主应用 PNG | 打开单文件后原图和参数同时显示 | [截图](host-image-parameters.png)、[AX](host-image-parameters.txt) |
| Finder 单文件 PNG | 系统图片预览，无 OrangeLen 参数面板 | 本轮现场观察；参数入口使用主应用/文件夹 |

首轮图片面板实测曾只显示参数；已改为明确分配两块视图区域，新增实际窗口宽度 520/1100 pt 来回调整的布局回归并重新 Finder 核验。VTT 首轮长字幕换行后被旧行高裁切；已增加字幕专用列宽、换行高度计算及回归，最终截图显示第二行。

安装会重置 Quick Look，安装时仍打开的旧预览出现 extension failed；关闭后重新打开正常。未将安装过程中失效的预览计作新版本功能通过，也未修改系统首选处理器来强制 PNG 分派。

完整键盘操作、VoiceOver、真实第三方云目录、所有生成工具版本及大规模压力仍未逐项验收。当前预算和格式范围见 [AI 产出预览](../../ai-output-previews.md)。
