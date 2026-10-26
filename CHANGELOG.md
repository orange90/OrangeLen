# 变更日志

## V1.0.2 — 2026-10-26

- 将 `.sql` 加入源码格式注册表，随主应用导出的 `local.orangelen.developer-source` 登记后缀及 `public.source-code` 继承关系；Code 扩展已支持该类型，干净系统无需其他应用提供 `org.iso.sql` 注册。
- 保留 `org.iso.sql` 兼容声明，新增不依赖本机 UTType 注册状态的回归测试，检查主应用导出后缀与扩展支持类型的完整链路。支持格式总数仍为 371。
- 更正此前将本机 `org.iso.sql` 注册结果视为系统类型的表述；V1.0.1 的本机 Finder 验收不能证明干净系统可用。
- 扩展审计发现 `.ini`、`.config`、`.toml` 同样依赖 Xcode 提供登记；主应用补入 `com.microsoft.ini` 与 `public.toml` 声明。另为 `.md` / `.markdown` 补入 Markdown 类型声明，避免依赖 Notes 或其他编辑器提供登记。
- 新增仅基于应用声明与系统 CoreTypes 的 371 后缀检查，接入本地测试与 CI 构建产物检查；检查后缀、类型继承及预览扩展候选，不将声明通过视为 Finder 实测通过。见[审计明细](docs/evidence/type-registration-2026-10-26/README.md)。

## V1.0.1 — 2026-10-26

- 发布 SQL 精确类型与高亮修复，以及 ZSH/BASH/R/PROTO/LOG/DIFF/PATCH/TXZ/TBZ2 共 9 个后缀的 Finder 入口修复。
- 新增可恢复的 WFLOW 用户偏好脚本，需主动运行；不改变默认安装行为，并说明对 `.shortcut` 系统动作卡片的影响。
- 应用内部版本更新为 1.0.1（build 4），正式签名脚本支持稳定版版本号。构建新的通用包，应用和 DMG 分别公证并附票据后发布。
- 保留 TS/MTS/DOT 及另外 8 项系统预览限制，公开 371 项历史审计、21 项复测和竞品原生对照的真实范围。详见[版本说明](docs/releases/V1.0.1.md)。

## 未发布 — 剩余 21 后缀修复与复测（2026-10-26）

- 补充 Code 与 Archives 的精确 UTI：ZSH/BASH/R/PROTO/LOG/DIFF/PATCH/TXZ/TBZ2 已通过本机 Finder 空格、OrangeLen 接收与成功回调验证。TXZ/TBZ2 同时打开成员正文。
- 增加可恢复的 WFLOW 用户偏好脚本；启用后由 OrangeLen 显示 plist/XML，同时影响系统 `.shortcut` 动作卡片。已验证恢复及再次启用。
- 21 项最终复测为 10 项 OrangeLen、8 项系统正文、3 项系统文件信息；TS/MTS/DOT 仍无正文，另 8 项接管未解决。独立数据式原生扩展和系统桥接诊断未解决这些分派；临时诊断设置已清理。见[完整结果](docs/evidence/provider-fixes-2026-10-26/README.md)。公开包未更新。

## 2026-10-26 — 371 后缀本机 Finder 提供器审计

- 对当前开发版逐项检查 371 个后缀及 30 项独立补测，以专属界面和实际调用日志区分：350 项 OrangeLen、16 项系统内容、5 项系统文件信息。明确本机既有 Hydra 设置及未发布 SQL 修复的影响，不将结果外推到公开安装包。
- 记录 TXZ/TBZ2 的精确 UTI 声明遗漏及 TS/MTS/DOT 既有入口限制；提供完整 Markdown/CSV 列表、样例哈希和逐项日志索引。本轮未改产品分派设置，见[审计报告](docs/evidence/all-formats-2026-10-26/README.md)。

## 未发布 — SQL 单文件预览修复（2026-10-26）

- Code 扩展增加本机 `.sql` 对应的精确类型 `org.iso.sql`，修复本机 Finder 原先回退到系统纯文本预览的问题，复用已有 SQL 语法高亮；该类型并非所有系统均已注册，后续补全见 Issue #2。
- 更新 SQL 样例并验证关键字、中文字符串及注释高亮；本机开发版已用真实 Finder 空格和扩展日志确认。见[验收记录](docs/evidence/sql-preview-2026-10-26/README.md)。

## V1.0 — 2026-10-20

- 以 `V1.0` 正式发布标签重新发布现有已签名、公证的通用安装包，仅修改下载文件名；安装包内容及应用内部版本保持原样。
- 中英文 README 更新口号、功能介绍和下载入口，移除签名开发者姓名与 AI 图片参数宣传；更换为新的 Finder 实拍截图。

## 2026-10-18 — 0.1.0-preview.3 公证通用预览版

- 发布包含 371 个明确后缀/49 个特殊文件名的新安装包：源码扩展、AI/开发产物专用视图、导图及 7z/RAR/压缩 TAR 归档。
- Apple Silicon/Intel 通用构建；应用与 DMG 均使用 Developer ID 签名、通过 Apple 公证并附票据，Gatekeeper 验证通过。
- 更新中英文 README 下载链接与版本边界。Intel 实机及其他 macOS 版本尚未完整验收，既有入口/格式限制保留。

## 2026-10-17 — 归档格式扩展（开发版）

- 新增 7z、RAR4/RAR5、tar.xz/tar.bz2/tar.zst 及 txz/tbz2/tzst 归档目录与成员只读预览；系统 libarchive 与内置 Zstandard 解码器，无命令行运行时依赖。

## 2026-10-16 — 新增 215 后缀 Finder 全量验收

- 完成新增 215 个后缀的真实 Finder 选择与空格预览；默认 213 项进入 OrangeLen，`.text` / `.wflow` 由系统提供器处理。两者系统正文和 OrangeLen 文件夹入口均有补充验证。
- 定位 Shortcuts 提供器优先选择；临时停用诊断后已恢复系统默认。完善测试夹具与逐项报告，没有修改产品解析器或更新公开发行包。

## 未发布 — Syntax Highlight 格式清单对齐（2026-10-16）

- 新增 215 个源码、配置及编译文件后缀；固定口径为 363 后缀、49 特殊文件名、7 前缀规则。集中语言映射并同步 Quick Look 候选类型。
- 补充词法高亮、二进制 plist 转 XML、Java class 声明/字节码及隔离 AppleScript 源码读取。编译 AutoIt 仅提供有限字节视图。
- 处理 Oracle SQL/Typst 同名后缀，支持 Workspace JSONC；增加语言样例及二进制边界验证。
- 范围及实际测试见 [对齐说明](docs/syntax-highlight-parity.md)；公开发行包尚未更新。

## 未发布 — MindManager

- 新增 `.mmap` 的 ZIP/Document.xml 主题树与浮动主题预览，接入 Drawings 扩展；格式清单增至110。
- 自动布局，不还原原始样式、关系线、备注、任务与附件；加密及旧版.mmp不支持。

## 未发布 — FreeMind / OPML

- 新增 `.mm` / `.opml` 主题树预览及源码切换，支持 FreeMind 富文本标题与关系箭头、OPML 多根大纲。普通 Objective-C++ `.mm` 保持文本预览。
- 格式计数更新为 109，沿用 XML 声明、深度、数量与输入大小限制。

## 未发布 — XMind 预览

- 新增 `.xmind` 新版 JSON / 旧版 XML 工作簿读取，支持多画布切换、主题树、浮动主题与关系连线；使用自动树状布局。
- 接入 Drawings Quick Look 扩展及文件类型声明；格式清单增至 107 个后缀。
- 沿用 ZIP CRC、路径、展开预算与取消检查，限制画布、主题及深度；原始样式、图片、附件、备注及概要暂不渲染。
- 新增解析与阅读器测试夹具；未改变既有 106 项 Finder 实测结论。

## 2026-10-15 — 图标素材、分发检查与本地产物整理

- 补齐应用图标原始 PNG、生成提示词和 `scripts/build-app-icon.sh`，支持从源图重新生成原生 ICNS。
- 记录 Mac App Store 上架差距，包括商店签名、共享权限、许可证打包、隐私入口及后续验收；本次仅整理检查报告，未实施或提交商店上架。
- 补充远端 Intel / macOS 12.7.4 安装复测：现有公证包签名与校验通过，但最低要求 macOS 14，无法启动；临时副本的 macOS 12 编译可行性不代表正式版本已兼容或功能已验收。
- 忽略本地测试截图、原始执行日志、UI 采集文件、xcresult 及整个 `videos/` 工作目录；保留报告、结构化结果与所需测试夹具，已跟踪文件不受忽略规则影响。
- 本次为文档、素材及辅助脚本整理，未修改应用功能，也未重新执行应用构建或 Finder 功能验收。

## 0.1.0-preview.2 — 2026-10-14

- 主应用、Quick Look 扩展、XPC 与共享框架使用 Developer ID 签名；应用和 DMG 均通过 Apple 公证、附加票据并通过 Gatekeeper 校验。
- 更新中英文 README 安装包链接，提供通用 DMG 与 SHA-256 校验值。

- 补齐真实系统 UTI 候选与缺失后缀声明，修复 GLB/TGZ 单文件未进入扩展、n8np 类型仍为动态类型等问题。
- 大型索引 glTF/GLB 在原有 200k 三角预算内进行完整三角抽样；真实 9.8 MB 猫模型已显示简化网格并验证旋转/缩放，纹理和动画仍省略。
- 收到文件后统一按格式选择渲染器，避免重叠类别将 glTF、Notebook、图表等降级；二进制 TS/MTS 转 AVKit。
- 106 个后缀的单文件/文件夹共 212 次内容回归通过；106 项实际 UTI 均有候选。106 项 Finder 实测完成；启用 STL/OBJ 原生设置后合并记录为 104 项主样例可见内容，TS/MTS 冲突仍未解决。详见 [完整清单](docs/evidence/single-file-audit-2026-10-13/README.md)和 [原生续修](docs/evidence/single-file-dispatch-2026-10-13/README.md)。
- 新增可恢复的当前用户 Hydra 扩展设置脚本与诊断复制命令入口；STL 单三角、二进制/ASCII 立方体、旋转及 OBJ/glTF/GLB 单文件回归已现场通过。正常安装不自动停用系统扩展；设置对 PLY/USD/MaterialX/Alembic 的影响已说明。

## 0.1.0-preview.1 — 2026-10-13

- 首个 GitHub 预览版安装包：macOS 14+，Apple Silicon / Intel 通用 Release 构建，DMG 拖入 Applications 安装。
- 包含应用图标、完整共享预览资源与第三方许可证；提供 SHA-256 校验值。
- 使用 ad-hoc 签名，未完成 Developer ID 发布签名与 Apple 公证；Intel 实机和其他 macOS 版本尚未完整验收。
- 中英文 README 在产品演示后提供安装包下载与安装说明。

## 2026-10-12 — README 产品定位

- 突出“为开发者设计，面向 AI 时代各种产出”，增加按产出分类的能力概览和检查交付、浏览项目、查看包、整理实验场景。
- 保留具体格式、Finder 分派与开发版本验收边界，并澄清 HTML 网络资源和 Markdown 远程图片的不同加载行为。

## 2026-10-12 — 共享资源与 Release 包体

- 先提交完整格式基线 `d70f6a3`，再将全部渲染器、WASM、字体和中英文词条放到唯一的嵌入资源 framework；移除主应用、七个扩展和 XPC 中全部 31 个 SwiftPM 资源包副本，保持格式和入口范围。
- 构建前后核对资源清单/字节哈希及完整翻译字典；只有全部一致才删除副本，再重签嵌套组件。安装改为验证后替换整包，避免旧资源残留；发行签名脚本补齐 framework。
- 保留 Intel/Apple Silicon 通用 Release，另提供 Apple Silicon 版本；包体口径、比较与实测见 [资源打包](docs/resource-packaging.md)。
- 验收中修复 Intel 半精度解析编译、空 Notebook 最终状态及 LaTeX 离线字体/PDF 截取时序；没有删功能、删字体、放宽网络/文件授权或提高内存保护阈值。

## 2026-10-12 — 后续 AI 产出格式

- Draw.io 多页/压缩页、JSON Canvas 与 ComfyUI/n8n/Dify 工作流节点图，源码保留，目录内有界文件卡片。
- React/TSX/MDX 离线组件快照，LaTeX 基础排版 PDF 与 Typst 单文件 WASM 编译 PDF。
- Parquet 原生样本表格、NumPy dtype/shape/存储样本与 NPZ 多数组；Safetensors/GGUF/latent 仅读头部和张量目录。
- OBJ/STL/GLTF/GLB 静态 SceneKit 旋转预览，n8np TAR/GZIP 清单及成员阅读。
- JPEG EXIF、JPEG/WebP XMP、授权 sidecar、归档图片参数，C2PA JUMBF/JSON/CBOR 结构明确标为未验证。
- 补齐类型声明、离线依赖及许可证、合成夹具、畸形输入/授权/资源释放及真实渲染测试。详细支持边界见 [扩展预览](docs/advanced-output-previews.md)。
- 完整回归 167 登记、165 通过、2 专用 XPC 宿主跳过；最终连线调整后相关 16 项通过。Debug 构建、开发签名安装与 deep/strict 验签通过；Finder 文件夹实测 Draw.io、TSX、Typst、Parquet 和 GLB。修复图像撑宽窗口与 Base64 资源临时副本问题，保留原内存预算；日志及现场截图见 [验收记录](docs/evidence/advanced-outputs/README.md)。

## 2026-10-11 — AI 产出文件预览

- ZIP 型 `.skill` 增加目录与成员预览，默认打开最浅层 `SKILL.md`，补齐实际系统类型和归档扩展声明。
- 独立 `.mmd` / `.mermaid` 离线图形与源码切换，损坏或超预算保留源码。
- `.mcpb` / `.dxt` 默认清单概览、归档目录及成员只读阅读，不安装或执行包内脚本。
- SRT/VTT 原生时间表格、筛选/排序/复制及完整源码；字幕列宽和行高适配换行。
- PNG A1111/ComfyUI 参数、压缩文本与 workflow/prompt，WebP EXIF 参数；原图与可选中参数并排，窄窗上下显示。PNG 单文件本机仍由系统接管，参数入口为主应用或 Finder 文件夹。
- 新增合成示例、预算/损坏/取消/切换/窗口布局回归。最终完整测试151登记、149通过、2专用XPC宿主跳过；Debug构建、开发签名安装通过。入口和实测记录见 [AI 产出预览](docs/ai-output-previews.md)。

## 2026-10-10 · HTML 效果与代码外观

- HTML/HTM/XHTML 增加默认页面效果及源码切换；按用户追加要求启用 JavaScript、外置 CSS/图片/字体及网络请求，真实文件保留相对资源路径，并复用临时目录授权。大文件/失败回退源码。
- Finder 使用随 DOM/资源变化更新的原生页面快照；主应用保留 WebKit 页面交互并提供默认浏览器打开入口，归档内相对资源仍不支持。
- 代码采用 VS Code 风格明暗语法色板、四空格制表位、优化行距与右对齐行号，保留原文复制、查找及高亮预算。
- 新增真实 WebKit 资源加载、模块脚本、fetch、动态快照、源码保真、文件切换和大文件回退回归，以及本地 HTML 示例。

## 2026-10-08 — 国际化与预览界面提交

- 汇总以下国际化、原生玻璃、侧栏排版与长标题布局修复，更新相关资源、工程配置、文档及回归测试。
- 提交前重新运行完整 SwiftPM 测试：133 项登记，131 通过，2 项专用 XPC 宿主测试跳过，0 失败；`git diff --check` 通过。本次未重新进行 Finder 人工验收。

## 2026-10-08 — 中英文界面国际化

- 主应用、七类 Finder Quick Look 扩展及辅助服务支持简体中文/英文，按系统首选语言选择，无匹配时回退英文；更改语言后重新打开应用及预览生效。
- 574 条共享文案与七类扩展名称本地化，覆盖设置、菜单、工具栏、无障碍、状态及错误提示；保留文档原文与稳定标识。
- 修复翻译后的 Markdown 元数据标题复制映射、正文分句受界面语言影响，以及英文隐藏工具栏撑宽窄窗口的问题。
- 中英文测试进程各 133 项登记（131 通过、2 专用 XPC 宿主测试跳过）；5 项专用原生/XPC 测试通过；Debug 构建、开发签名安装与 deep/strict 校验通过；真实 Finder 英文概览及 README 阅读通过。实现与验证边界见 [国际化说明](docs/localization.md)。

## 2026-10-08 — Markdown 长标题撑宽预览修复

- 限制“目录”和“更多操作”弹出按钮宽度，完整标题仍保留在菜单中，避免最长菜单项把整个预览窗口撑宽；布局结束时同步正文文本容器宽度。
- 新增长标题、中文正文、长路径及目录/大纲同时显示的多宽度回归。去掉按钮限制可复现窗口被撑至 4,454.5 pt；修复后 760–1,200 pt 保持目标尺寸。
- 14 项相关测试通过，用户指定的 5h-4f05430/初次整理证据.md 内容在原生窗口回归通过；Debug 构建、开发签名安装及 deep/strict 验证通过。Finder 自动点击未能完成正文视觉验收，不将组件结果记为 Finder 验收。

## 2026-10-08 — 文件夹侧栏排版

- 统一文件按钮与目录标签的图标尺寸、文字起点和垂直居中；文件行使用 30 pt 高度、2 pt 行距、14 pt 层级缩进。
- 搜索/概览、文件树、底部操作分区，统一 12 pt 内边距；刷新靠左，辅助状态置底并限制两行，保留原生玻璃效果。
- Debug 构建、13 项相关回归、开发签名安装及 deep/strict 校验通过；真实 Finder 浅色排版、文件打开和返回概览通过。

## 2026-10-08 — 轻量原生玻璃效果

- macOS 26 及以上使用 NSGlassEffectView，为目录侧栏和两个顶部按钮提供原生玻璃效果；正文与统计卡片保留清晰底色。
- 降低透明度、提高对比度或旧系统使用普通背景；不添加自定义动画定时器或逐行玻璃图层。
- 14 项布局/概览回归及 1 项玻璃回退测试通过；Debug 构建、开发签名安装、宿主与 Finder 浅色实测通过。未量化 GPU/能耗增量，不宣称零开销。

## 2026-10-08 — 玻璃效果前基线提交

- 汇总当前边界修复、文件夹概览、持续统计与目录浏览队列优化。
- 目录树只保留系统展开箭头，根目录及子目录使用缓存的 macOS 原生文件夹图标，并统一垂直对齐。
- 最近完整回归 127 项登记、125 通过、2 专用 XPC 宿主跳过；图标调整后 10 项布局回归、Debug 构建和本机开发签名安装通过。

## 2026-10-08 — 统计期间的目录展开优化

- 子项改为名称枚举，仅读取当前页可见项元数据；续页跳过已有项时不再预取元数据，文件包识别仅用于目录。保留分页预算、修订校验、取消和不跟随链接。
- 目录展开使用独立有界队列，避免等待文件解析；递归统计改为 utility 优先级并移除未使用的云状态批量预取，仍持续更新直到完成。
- 全套 127 项测试：125 通过、2 专用宿主 XPC 测试跳过、0 失败；新增解析/统计占满时的真实目录加载回归及 Unicode/文件包/悬空链接回归。Debug 构建、开发签名安装及 deep/strict 验签通过。
- 本机截图目录的单次组件探针为 57 ms → 3 ms（同为 32 个可见子项）；未控制系统缓存、未复现 Finder 长等待，不能作为稳定加速倍数或 Finder 验收。日志：`/tmp/orangelen-directory-{before,after,tests,build,install}.log`。

## 2026-10-08 — 文件夹概览重新设计

- 文件夹入口改为原生分区概览：文件夹图标、名称/路径、三列关键指标、真实文件类型分布、README 摘要和位置/统计范围。
- 使用分层字号、灰色辅助文字、蓝色操作入口、浅色卡片及深色适配；窄窗口自动改为纵向布局，内容可滚动。
- 文件夹模式精简工具栏，侧栏增加返回概览入口；统计持续更新并可停止/重启。README 仅有界读取本地正文，不加载图片或执行内容。
- 验证与设计规格见 [文件夹概览设计](docs/design/folder-preview-redesign.md)。

## 2026-10-08 — 产品与架构边界修复

- 修复 12 项审查问题：生成列错位、失败旧正文/旧表、JSON 路径与 Office 展开预算、原生 ZIP 预检、分页历史与截断恢复、BOM 保真、子任务取消、目录重试、归档路径别名。
- 增加无网络文档 XPC、受控 FD 媒体流、有界任务队列与跨进程 lease、异步高亮、独立目录统计控制、字段级设置合并、清除当前阅读会话和授权时钟保护。
- SQLite 类型与复制保真、TSV 转义、Office 内容说明及当前入口矩阵统一；验证结果和环境限制见 [修复状态](docs/boundary-fix-status.md)。

## 2026-10-08 — 文件夹持续统计

- 递归大小及数量统计不再因 3 秒或 20,000 项预算停止，后台持续扫描并约每 0.2 秒更新进度，结束后显示完成状态。
- 切换或关闭目录取消旧任务；权限、云占位等跳过项保留部分结果说明，符号链接仍不跟随。
- 当前工作区 106 项测试通过（含超过 20,000 项、进度及取消回归），Debug 构建与本机开发签名安装通过；本轮未重新验收 Finder 视觉效果。

## 2026-10-08 — 汇总提交当前开发改动

- 汇总自上一提交以来的阅读器、格式支持、目录浏览、设置、七类扩展、诊断、打包脚本、CI 配置，以及相应测试、夹具、第三方资源/许可证和验收证据。
- 包含 Notebook 整篇连续阅读、Excalidraw 画布、开发者格式、Markdown 高亮与大纲、归档树、SQLite 分页排序、本地图片短期授权、大文件首屏优先和目录内系统格式预览。
- 当前代码最近一次验证为 92 项 XCTest 全部通过、Xcode Debug 构建成功、本机开发签名安装和 deep/strict 验签通过。本次仅整理日志与本地提交，沿用该验证结果。
- 未完成项仍按各功能文档记录；正式公证、外部 CI、其他系统/Intel 实机及全部系统格式的完整目录预览尚未验收。

## 2026-10-08 — 目录内系统格式预览

- 修复 MP4、MOV、音频和 Word/RTF/ODT 在目录阅读器中被直接判为不支持；使用 AVKit 和原生文档导入器，切换/关闭停止播放器并释放文件授权。
- 图片从固定后缀列表改为系统 ImageIO 支持类型；保留字节、像素与缩略解码预算。
- XLSX/XLSM/PPTX/PPTM 增加有界文字/单元格内容预览，不计算公式、不还原图表和版式。
- Finder 扩展无法嵌套 Quick Look 的格式明确提示使用单文件预览；宿主可调用系统 Quick Look。支持范围与验收见 [目录系统格式](docs/system-preview.md)。

## 2026-10-07 — 大文件首屏优先第一阶段

- 普通阅读入口超过 1 MiB 后按 64 KiB 分页，正文准备先完成，后台补充每页前 16,384 UTF-16 单元的语法高亮。
- 保留 Unicode 边界、字节范围与阅读位置，通过取消和任务标识防止旧结果覆盖新文件；新增读取、正文准备和高亮耗时日志。
- 87 项测试、Debug 构建和本机开发签名安装通过；Finder 大文件与翻页已有观察。仍为按钮分页，未实现连续滚动和跨页词法状态，详情见 [大文件首屏优先](docs/fast-preview.md)。

## 2026-10-05 — Quick Look 竞品补强

- 离线 Highlight.js 语言高亮，识别 Markdown 围栏语言；输出重建校验保留原文，着色范围有界。
- Markdown 增加可收起的大纲、front matter、提示块、脚注导航、代码块原文复制；单文件本地图片在宿主显式目录授权，宿主以短期 app group bookmark 给同文档 Finder，加载/关闭撤销实测通过，原地选目录仍需宿主。
- 图形与 Mermaid 附件增加缩放、拖动平移、适合窗口、100% 与返回正文；按钮进入辅助功能树。
- 大文本以 512 KiB 分页，保持 UTF 字符边界，显示准确字节范围；开启阅读记录后保存页码与位置。
- 归档目录树、完整路径筛选、名称/大小排序；SQLite 每页 500 行、全表类型排序、列元数据；CSV 已加载单元格过滤与排序。
- 保存/原子替换后自动刷新，保留文本模式/位置与容器条目；七类独立扩展及安装时停用选择保留。
- 宿主诊断真实 UTType、类型声明匹配和导入系统登记；准备两架构 Release、公证/Gatekeeper 阻断发布流程与多系统 CI。
- 85 项测试通过，真实 Finder/宿主截图见 [交付说明](docs/improvement-report.md)。本机只验证 macOS 26.6.2 / M3 Pro；未公证、未运行外部 CI，Finder 原地本地图片授权未完成。不能据此宣称全面超过竞品。

## 2026-10-04 — 开发者常见格式

- 补齐配置文件名/变体、前端源码及常见语言/接口/基础设施源码扩展识别与类型声明。
- 增加 JSONC/JSON5 原文结构树、重复键与数字写法保留、部分 TypeScript/VS Code 配置自动识别。
- 增加有界静态 SVG 离线图像/源码切换，过滤活动内容及外部资源，失败回退源码。
- 修复普通 gzip 文本被误当作 TAR；新增日志、CSV/TSV、JSON/JSONC/JSON5、JSONL 的内存解压预览。
- 修复连续切换不同大小表格时旧行回调越界崩溃；新增格式/错误边界及真实渲染集成测试。
- 具体限制及验证见 `docs/developer-formats.md` 和 `docs/verification.md`。

## 2026-10-04 — 移除专注阅读

- 移除专注开关、上下句导航、阅读尺、当前句高亮和正文变淡，包括紧凑工具栏中的入口。
- 旧专注设置不再参与渲染；保留搜索、目录、字号调整、阅读位置记忆和代码行号。

## 2026-10-04 — Notebook 连续阅读与 Excalidraw

- Notebook 改为同一正文连续显示 Markdown、代码和已保存输出，隐藏逐 Cell 条目侧栏；不运行 kernel 或 widget。
- 标准 `.excalidraw` 增加离线画布与源码切换、类型声明和打包资源；坏场景或超预算时降级源码。
- 47 项测试、Debug 构建及本机开发签名安装通过；Excalidraw 真实 Finder 图形/源码已有证据。Obsidian `.excalidraw.md` 尚未支持，详情见 [Excalidraw](docs/excalidraw.md)。

## 2026-10-03 — M1 补强与 M2 基础格式

- 新增 EPUB 章节/内图/位置记忆、JSONL、diff、Notebook 已存储输出、SQLite 内存只读表格、ZIP/TAR/TGZ；HAR/OpenAPI JSON 本地结构预览。
- 共享原生容器阅读器、紧凑工具栏、明确二进制提示、目录声明概览、PDFKit 基础入口。
- 修复真实 Finder Notebook 长短正文切换时旧高亮范围越界崩溃，增加绘制回归。
- 43 项测试通过；EPUB、JSONL、Notebook、SQLite、ZIP、TAR、OpenAPI JSON Finder 正文有证据。diff 系统接管，HAR 调用/PDF/TGZ 实机和完整目录交互尚未通过；MOBI/AZW3、7z/RAR 未实现。
- 更新 README、格式矩阵、安全预算与未测试状态；保留未完整验收及未公证状态。

## 2026-10-03 — 首次 M1 开发快照

工作名称 OrangeLen，副标题 Quick Look for Developers。M0 原生可行性验证完成，M1 已实施但尚未完整验收；不是正式发布版。

### 实现

- 原生 macOS 宿主、现代 Quick Look Preview Extension、共享 Swift Core/UI、设置与可选阅读记录；加入可重复构建、安装、签名和打包脚本。
- 代码/文本选择复制、搜索、行号定位；Markdown CommonMark/GFM 渲染、目录、源码切换、当前句高亮和 1/3/5 视觉行阅读尺，复用源映射与真实 TextKit 布局。
- 文件夹懒加载树、同窗正文预览、有界目录大小和文件/目录统计；JSON 树及 CSV/TSV 表格，YAML/TOML/XML 源码预览。
- Markdown 原生表格、嵌套列表、引用、代码块、安全链接和已授权本地图片；离线 KaTeX 公式、Mermaid 图表，保留源码复制和搜索定位。
- 远程图片默认占位，点击后由有界 HTTPS 客户端加载；Finder 使用内嵌沙盒 XPC 图片服务。加入私网/重定向/内容类型拒绝、TLS 验证、预算及取消。
- 收录合成测试夹具、格式支持矩阵、三类验证证据、依赖锁文件及许可证。

### 修复

- 文件夹点选文件后同步原生选中行；PNG 等指定图片不再误走文本解码。
- 复制成功显示“已复制”，无选区或失败不误报成功；不覆盖目录统计。
- 修复行号尺遮挡正文、首次公式字体未就绪导致缺字、离屏渲染等待动画帧卡住、附件占位视觉空白等问题。
- 修复 Finder 扩展直接 DNS 被系统沙盒拒绝导致远程图片失败，以窄接口 XPC 服务完成同窗加载。

### 验证与边界

- 30 项 XCTest 通过；Xcode 构建及 Apple Development deep/strict 验签通过。
- macOS 26.6.2 / M3 Pro 的真实 Finder 已验证指定代码/数据分派、文件夹 Makefile 同窗阅读、Markdown 公式/Mermaid，以及点击加载公共远程图片和拒绝私网地址。
- 单文件 Markdown 的邻接本地图片权限仍未解决；Finder 全部拖选/键盘/目录切换及 PNG 路径未完整验收。公式和图表为图像附件，不能逐字选择其内部字形。
- 键盘搜索和系统原生格式接管按用户决定不阻塞；不将其写作已经技术修复。其他系统/Intel、真实云目录、压力及无障碍等未完成验证。
- Developer ID 发布签名与公证未执行。全部当前缺口、原因、影响及取舍见 [README](README.md#当前不完善之处原因与影响2026-10-03)；详细证据见 [验证记录](docs/verification.md)。

本次为仓库首次提交，包含此前在本工作区实施的工程与修复。本次整理阶段仅更新说明和日志，沿用同一代码快照最近一次 30 项测试及构建证据，没有将文档检查计作新的功能实测。

## 2026-10-04 Notebook 连续阅读
- `.ipynb` 改为 Markdown、代码与已有输出按顺序连续滚动，移除 Cell/输出条目侧栏。PNG 输出共享整篇像素预算；不运行 kernel。

## 2026-10-04 — Excalidraw 只读预览

- 新增标准 `.excalidraw` 离线画布、原始 JSON 源码切换和 Quick Look 类型注册。使用 Excalidraw 0.18.1；内嵌栅格图片经本地解码，网页/外部图片不联网。
- 增加有界解析、超时/取消、损坏场景源码降级及对应测试、合成夹具和依赖许可证。
- 47 项 XCTest、Debug 构建、本机开发签名安装通过；Finder 实测画布和源码切换通过。Obsidian `.excalidraw.md`、编辑和自由缩放不在本次范围。

## 2026-10-15 Developer formats batch 1

- Added 38 explicit extensions and 7 exact filenames (148 / 43 total); source aliases and Finder type declarations.
- Arrow IPC file/stream + Feather V2 including LZ4/ZSTD; wheel/VSIX manifests and package trees; bounded JUnit/SARIF/OpenAPI summaries; ONNX metadata without inference; offline Graphviz DOT/GV.
- Preserve multiline structured cells; retain source views for reports and diagrams.
- Details, limits and actual Finder Space evidence: `docs/evidence/developer-batch1-2026-10-15/README.md`.
