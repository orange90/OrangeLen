# M1 补强与 M2 开发验证（2026-10-03，当前）

- **应用内渲染**：43 项 XCTest 全部通过；新增 ZIP/TAR/gzip/路径/CRC/取消、EPUB 章节/内图/保护资源/UTF-16 DTD、SQLite 内存只读/WAL/大整数、JSONL 坏记录、Notebook 输出隔离、HAR/OpenAPI、章节状态修订失效、连续选择与窄窗测试。真实 Finder Notebook 长正文切短输出曾触发 TextKit 装饰 NSRange 越界；已清除旧装饰并约束绘制范围，回归及 Finder 再测通过。日志 m2-tests.log。
- **Finder 调用**：EPUB 正文、内图与第二章切换；JSONL 好/坏记录；Notebook 文本输出与 HTML 拒绝提示；SQLite 表格；ZIP 代码/Markdown/内图；TAR 正文；OpenAPI JSON paths/JSON 正文已观察。各 m2-finder-* AX/PNG 位于 evidence。diff 由系统处理器接管（用户接受）；HAR 初测系统元数据处理，OrangeLen Finder 未通过。TGZ、PDF、受保护 EPUB Finder 未测试。
- **Finder 文件夹**：新版目录摘要和总计已显示。自动化目录行点击未稳定命中，无法据此判定普通鼠标失败，也不能标为完整点选回归通过；早期 Makefile 同窗正文证据仍有效。两种代码/Markdown/PNG 连续切换、“已复制”与任意拖选/阅读尺组合保持待验收。
- **签名构建**：Xcode Debug 构建和 Apple Development 安装完成；最终 deep/strict 验签和开发包见 evidence/package 日志。Developer ID、公证、staple 未执行；其他 macOS 与 Intel 未测试。

此前记录是历史证据；当前范围同时参见 m2-formats.md 与 format-support.md，不将宿主测试算作 Finder 支持。

# 公式、Mermaid 与显式图片加载（2026-10-03，最新）

用户本轮要求实际实现公式/Mermaid、本地图片直接渲染、远程图片点击后加载并防注入。已完成实现、开发构建、安装与测试；详见 [功能与安全边界](markdown-rich-content.md)。

- **应用内渲染**：公式、中文流程图/时序图、本地图片直接读取、显式远程图片下载。发现并修复首次公式缺字（插入后先强制布局再等待字体就绪）。证据 `rich-host-math.png`。
- **Finder 调用**：真实空格预览显示完整公式和 Mermaid；系统拒绝扩展直接 DNS，日志为 mDNSResponder EPERM。内嵌沙盒 XPC 图片服务解决此链路，顶部按钮点击后公共图片显示、私网地址拒绝，仍在原 Finder 窗口。见 `rich-finder-math.png`、`rich-finder-remote.png` 及 AX。单独 Markdown 的本地邻接图片权限仍不足，保持未完成；本轮文件夹自动化点选未稳定落到目标，不冒称本地内嵌图片 Finder 已验收。
- **签名构建**：30 项 XCTest 通过，Xcode 构建/开发打包成功；内嵌 XPC、扩展和应用分别 Apple Development 签名并验签。新增渲染依赖随包离线分发，许可证与锁文件已收录。Developer ID 和公证未执行。
- **未测边界**：所有 Mermaid 图型/TeX 命令、其他系统、单张占位的真实鼠标链路、全部 Finder 阅读交互组合。坏证书站点请求超时，不冒称已测试证书错误分支。保留 M1 尚未完整验收状态。

以下是历史记录，涉及公式、Mermaid、远程图片的旧缺口以本节为准。

# Markdown 渲染补强（2026-10-03，最新）

用户指出 Markdown 渲染不完整。本轮采用原生 TextKit 布局补齐，不使用网页替代预览。

- **应用内渲染**：原生三列表格换行/对齐、嵌套和从 3 开始编号的列表、任务项、引用边线、代码块、组合粗斜体、本地图片。`evidence/markdown-native-table.png` 为宿主；`markdown-native-image.png` 与同名 AX 为宿主授权 demo-project 目录后内嵌 sample.png 成功。远程图片保持占位。
- **Finder 调用**：真实 Finder 选中合成 `render-lab.md` 按空格，新版扩展显示表格、代码块、列表，点击目录的“代码与图片”后滚动定位成功。见 `evidence/markdown-finder-table.png` 和 `markdown-finder-code.png`。单文件预览未获得邻接图片读取权限，AX 明确显示本地图片不可读占位；不宣称 Finder 图片已通过。宿主图片证据不替代 Finder。
- **测试与签名构建**：24 项 XCTest 全部通过；新增覆盖表格原生坐标/窄宽度、组合字体、源映射、内嵌图片及路径拒绝、代码块宽度、表格视觉行去重。见 `evidence/markdown-tests.log`。当前 Apple Development 构建已安装 `~/Applications/OrangeLen.app`；开发 ZIP 已刷新。无 Developer ID 公证，其他系统仍未测试。
- **保留边界**：文内链接委托导航经测试；真实鼠标链接激活、外部浏览器打开及全部 Finder 拖选/字号/阅读尺组合未验完。远程图片不加载；没有数学、Mermaid 或完整 HTML。复制渲染选区仍按共享映射返回 Markdown 源文。

以下为先前验收与历史记录；涉及 Markdown 缺口的状态以本节为准。

## 当前验收口径（2026-10-03 用户调整）

来源：当前用户明确表示 QLMarkdown 已卸载；Quick Look 无需复杂键盘搜索操作；系统能渲染的格式沿用系统即可。卸载状态为用户报告，本轮未重新检查本机注册表。键盘搜索/快捷键传递与系统 CSV/TXT 等预览接管不再作为 M0/M1 阻塞，也不伪记为技术问题已修复。历史 QLMarkdown 冲突保留为过去记录，不再作为当前故障。

重新对照设计文档第 16 节：M0 退出条件是至少一个真实类型由 Finder 调用、关键限制有证据。已有实测满足，**M0 原生可行性验证完成；M1 已实施，尚未完整验收**。此前把全部 M1 交互缺口当作 M0 退出阻塞的说法予以更正。

仍需处理/验证：
- 已知实现缺口：Markdown 本轮已补齐表格、本地图片和安全链接实现，权限/交互验证边界见最新记录；文件夹内 PDF/视频等缺少系统预览转交路径，未知类型仍可能尝试按文本读取。单文件让系统接管，不等于目录内的处理已完成。
- 核心实机回归不足：Finder 内至少两种代码及 Markdown 连续切换；PNG 修复和“已复制”提示；专注句点选、1/3/5 行尺、字号/宽度变化、拖选复制。已有共享组件测试和部分截图，不能把余项记为故障，也不能视为全部通过。
- 状态与稳定性：阅读位置恢复/清除/修订失效、跨进程设置并发；实际无权限/删除/云占位、大目录分页/取消/快速切换；连续预览内存及 Finder 首屏性能。已有部分 Core/UI 测试，真实系统压力验证仍不足。
- 发布质量：VoiceOver/对比度、其他 macOS/Intel 未验证；正式 Developer ID 公证未执行。这些与本机开发版可用性分开记录。

本轮是按原文、当前代码和既有证据进行审计，没有新做 Finder 功能实测。没有新增失败的确证。EPUB 等 M2 功能保持后续范围。

## 2026-10-03 复制反馈补充

正文复制按钮、正文 ⌘C/菜单，以及 JSON/表格的复制动作统一接入非模态反馈。写入剪贴板成功后，阅读区右上角显示“已复制”2 秒；重复复制重新计时，换文件或关闭清除提示，不覆盖目录统计。正文无选区提示“请先选择要复制的内容”，写入失败不误报成功。

本次 Xcode 构建及开发验签通过。已在安装后的宿主实测：全选 Makefile→复制选择→出现“已复制”→自动消失，剪贴板逐字比对原文通过。证据 `evidence/copy-feedback-*`。共享 UI 同时编入 Finder 扩展；本次未独立复测 Finder 提示。小型反馈修改未新增或重跑全套测试。

## 2026-10-03 文件夹阅读修复补充

用户截图纠正了早期测试范围：真实 Finder 文件点击可以进入读取流程，原问题是选中态未同步、PNG 被当成文本。现在文件按钮与目录行共享激活逻辑，显式同步原生选中行；辅助功能行也有激活动作。`folder-fixes-finder-code.png` / AX 记录已观察到 Finder 内 Makefile **selected**、同窗正文及持续目录统计。

PNG 使用 Apple ImageIO 有界解码 + NSImageView，复用只读 AccessBroker；25 MiB 输入、1 亿源像素、最长边 2048 像素缩略解码，动图首帧。不使用递归嵌入 Quick Look，也不抢占 Finder 的 PNG 类型。`folder-fixes-app-png.png` / AX 记录验证安装后的共享阅读器：sample.png 被选中、640×360 图像正确显示、底部目录信息保持。PNG 在真实 Finder 中的自动化点击复测未取得稳定结果，因此图片画面证据只记为宿主通过，不将其改写为 Finder PNG 验收通过。

底部独立信息栏显示根目录名、逻辑文件字节总和、递归文件/目录数，包含隐藏项；符号链接单列不跟随，未下载目录不进入。统计只读元数据，最多 20,000 项/3 秒；预算、权限或未下载子目录导致“部分统计”，不伪称完整大小。目录内容后续变化需重新打开根目录统计，当前值是本次扫描快照而非实时监控。

新增测试涵盖按钮选中与单次激活、辅助功能激活、PNG 解码/取消/损坏、图文切换保留总计、隐藏文件/递归/符号链接/预算。当前共 **20 项测试通过**，日志 `evidence/folder-fixes-tests.log`。以下为此前 M0/M1 历史记录，后续状态以上述补充为准。

# 验证记录

日期：2026-10-03。环境：macOS 26.6.2 (25G83)，M3 Pro arm64，Xcode 26.5，macOS SDK 26.5。初始工作区无代码及磁盘 AGENTS.md；已读取用户记忆入口与相关项目摘要。

## 应用内渲染

17 个 XCTest（13 Core、4 UI）通过：严格编码/BOM、二进制拒绝、预算、取消、符号链接/根边界、目录分页、CSV 多行/CRLF/转义、JSON 大数字/重复键/深度、Markdown AST 源映射、中文/emoji/缩写/网址/小数、TextKit 实际行矩形、字号/宽度变化、1/3/5 行尺、最新请求获胜与完成回调一次。见 `evidence/tests.log`。

`app-folder-code.png` 是最终安装版真实宿主目录+Makefile 同窗画面；`app-markdown-focus.png` 为专注阅读；`app-copy.txt` 为 Swift 原文复制比对。早期行号尺绘制越界曾遮住全部正文，已修复裁剪/文本留白并加入可见字形回归测试，不将早期空白截图视为通过。

约 1 MiB 合成源文件：测试包含初次及 20 次热加载，P95 见测试日志 BENCHMARK。进程内指标包含读取/解析/呈现调用；OS 文件缓存未控制，**不是 Finder 冷启动、真实显示完成或跨系统性能承诺**。

## Finder 调用

真实 Finder 选择夹具后按空格，查看 OrangeLen 原生工具栏，配合内容无关统一日志。未将 qlmanage 注册或宿主窗口算作 Finder 成功。

- `m0-finder-swift.png` / `m0-finder.log`：最小扩展调用、UTF-8 中文/emoji、复制验证。
- `finder-code-search.png`：Makefile 正文/行号与查询结果；查询由 AX setValue 输入，不算键盘输入通过。
- `finder-markdown-focus.png`：原生 Markdown 渲染、当前句和三行尺。
- `finder-data-json.png`：原始大整数与重复键；`finder-config-yaml.png`、`finder-config-toml.png`、`finder-sample-xml.png`、`finder-data-tsv.png`：实际分派与渲染。
- `finder-data-csv.png`：系统预览，OrangeLen 未赢得分派。
- `m0-finder-folder-system.png`：早期失败；**最终** `finder-folder-tree.png` 与 AX 记录证明文件夹调用、枚举成功。但子文件点击未触发正文，不能标记完整目录浏览通过。
- `finder-copy-result.txt`：最终可见全选/复制按钮与 Makefile 原文逐字一致。
- `finder-m1.log` / `finder-final.log`：prepare、completed、close/cancel 生命周期。跨文件显示、关闭重开观察到；快速请求竞争由 UI 集成测试补充，非 Finder 压力测试。

键盘输入流向 Finder 的问题保持未解决；宿主 ⌘F/⌘C 已验证。未截获 Space/Escape 或全局键盘。签名安装后曾复用旧扩展进程；关闭预览并终止仅 OrangeLenPreview 进程后重测。系统选择存在缓存，未归因为某一个设置。

Markdown 测试曾临时将已安装 QLMarkdown 设置 ignore 以隔离竞争，完成后恢复 default，见 `evidence/plugin-restoration.txt`。安装脚本本身不改变其他扩展。系统设置 Quick Look 开关的具体 UI 路径未单独点击验证，使用 pluginkit 注册启用。

## 签名构建

`evidence/build.log` / `evidence/signing.log`：Xcode Debug BUILD SUCCEEDED；安装到 `~/Applications/OrangeLen.app`，已有 Apple Development 身份签名，嵌套 dylib→appex→app 顺序，严格 deep 验签通过。未导出密钥。Team 前缀 App Group 在本机可用，宿主 focus 设置传到 Finder；多进程并发/恢复尚未压力测试。

`build/artifacts/OrangeLen-dev.zip` 是可重新构建的 ad-hoc 开发包；`OrangeLen-local-development.zip` 为本机证书签名快照，不是分发许可。打包脚本支持有证书条件下的 Developer ID/公证流程，但 **release、公证、staple 未执行**。

其他系统/架构与真实云目录：未测试。M1 核心阻塞和下一步见 [已知限制](known-limitations.md)，格式逐项见 [支持矩阵](format-support.md)。
