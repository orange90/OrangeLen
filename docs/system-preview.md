> 当前实现请先看 [入口与边界契约](current-contract.md) 和 [修复验收状态](boundary-fix-status.md)。以下保留原日期的功能/现场证据；旧数字、旧导入路径及旧限制不自动代表最新版。

# 目录内系统格式预览（2026-10-08）

## 原因

目录内点击文件调用 `ReaderController.loadFile`，不是 Finder 的单文件分派。原逻辑对内置阅读器以外的二进制直接显示“不支持”，因此系统能够预览 DOCX/MP4，并不意味着目录右侧能预览。

本次实机尝试在 Finder 扩展内嵌入 QLPreviewView，DOCX 仅显示图标，日志有 Quick Look XPC bootstrap/ThumbnailsAgent 失败。最终使用扩展内可工作的原生组件，宿主才保留 QLPreviewView；没有增加沙箱例外或注册泛用系统类型。

## 当前范围

| 类型 | 目录中的路径 | 限制 |
| --- | --- | --- |
| MP4/MOV/M4V、MP3/M4A/WAV/AIFF 等系统音视频类型 | AVPlayerView，原文件流式播放，默认暂停 | 实际编解码器由 AVFoundation 决定，损坏/不兼容文件提示默认应用；不把视频读入文本缓冲区 |
| DOC/DOCX/DOCM/DOT/DOTX、RTF、ODT | NSAttributedString 系统导入 + 只读 NSTextView | 25 MiB 输入；Office ZIP 按现有 64 MiB 展开预算检查；复杂版式可能简化，不保证分页与 Word 一致 |
| XLSX/XLSM/PPTX/PPTM | ZIP/XML 内容预览 | 仅文字、单元格地址和已保存值；不计算公式、不执行宏、不还原图片/图表/样式；按内部文件名排列，不承诺幻灯片自定义顺序/工作表显示名；最多 200 个部件、正文 5 MiB |
| PNG/JPEG/HEIC/TIFF/PSD/AVIF/RAW 等 | 根据本机 ImageIO 实际注册能力选择原生解码 | 不是承诺所有 RAW 机型；仍限 25 MiB、1 亿源像素、最长边 2048；动图仍为首帧 |
| PDF / SVG / Markdown / 源码 / 既有容器 | 保留原有路径 | 不新增这些入口的能力承诺；`.ts` 保留 TypeScript，不因系统 UTI 的视频歧义误入播放器 |
| 旧 XLS/PPT、iWork、RTFD、3D、其他系统格式 | Finder 扩展中明确提示单文件预览；宿主可交给 Quick Look | 目录内尚未完整支持；不能将图标当作预览成功 |

切换、取消、关闭时销毁预览视图，停止播放器并清除 item，释放 security scope；文档异步结果通过 generation/token 避免覆盖新选择。路径边界、符号链接和云占位符沿用 AccessBroker 验证。原生文档提供全选/复制，隐藏不适用的源码与文本搜索控件。

## 验证

- 92 项 XCTest 通过：含格式分流、`.ts` 避免误判、DOCX 正文、MP4 时长、切换停止播放器、RTF→Markdown→关闭取消、Office 内容与公式缓存值、ImageIO 类型、逃逸符号链接拒绝。
- Debug Xcode 构建成功；安装到 `~/Applications/OrangeLen.app`，Apple Development deep/strict 签名验证通过。
- 真实 Finder 目录窗口已观察 DOCX 正文与粗体、MP4 播放控件/3 秒时长/播放进度、M4A 的 2 秒时长和播放控件、XLSX 的 A1/C3/公式缓存值、PPTX 正文。自动化点选后部分 AX/截图在窗口全屏切换后才刷新；不能据此断言所有窗口下点选刷新时序均已验收。
- 证据：`docs/evidence/system-preview/`；夹具：`Tests/Fixtures/system-preview/`。XLSX/PPTX 由 xlsxwriter/python-pptx 生成，DOCX 由 textutil 生成，音视频由 ffmpeg 生成。
- 本机 macOS 验证，不代表每种扩展名/编解码器、其他 OS 或完整 Office 文档保真验收。未提交或推送。

API 依据：[QLPreviewView](https://developer.apple.com/documentation/quicklookui/qlpreviewview)、[NSAttributedString.DocumentType](https://developer.apple.com/documentation/foundation/nsattributedstring/documenttype)。
