# 格式支持矩阵

更新于 2026-10-05；仅 macOS 26.6.2 / Apple M3 Pro / Xcode 26.5 SDK 26.5 实测。部署下限 14 不代表 14 已测试。下列 Finder“通过”仅表示调用与指定画面，不代表全部键盘交互验收。

| 格式 | 共享渲染器 | 真实 Finder 结果 | 限制 |
|---|---|---|---|
| Swift | 只读文本、高亮、行号、搜索、复制 | M0 调用和复制通过 | M1 任意拖选/快捷键仍需复核 |
| Makefile | 同上 | 原生正文、行号、搜索结果、按钮全选复制通过 | 搜索键盘输入未通过 |
| Markdown | AST、原生表格/列表/引用/代码、授权本地图片、安全链接、目录/源码 | 新版表格、代码块、目录跳转实际通过；单文件邻接图片权限不足时占位 | 本地图片成功画面来自宿主显式目录授权；Finder 仅提供授权说明；公式/Mermaid/点击远程图片已在 Finder 实测；完整 HTML 不执行 |
| JSON | 保留原始数字/重复键的树及源码 | 通过 | 深度/节点上限；树内任意操作未逐项实测 |
| YAML / TOML | 高亮源码 | 通过 | 不宣称语义校验或结构树 |
| XML | 高亮源码，不解析实体 | 通过 | 不执行 DTD、XSLT |
| TSV | 原生表格及源码 | 通过 | 最多解析 5,000 行、256 列 |
| CSV | 同 TSV；解析单测通过 | 系统表格接管，按用户最新取舍接受 | 宿主可打开，不等同 Finder 通过 |
| PNG 等独立图片 | ImageIO + NSImageView，25 MiB / 1 亿像素 / 2048 边长 | 宿主 PNG 与共享组件通过；Finder 文件夹 PNG 自动化点选未稳定通过 | 其余列举图片格式未逐项实测；动图首帧 |
| TXT | 严格编码、搜索/复制 | 初始 M0 系统接管；最新取舍允许沿用系统 | 未验收 |
| 文件夹 | 懒加载目录树，同窗共享阅读器 | 调用、根/src 枚举及选中 Makefile 同窗正文通过 | 完整鼠标/键盘/其他目录回归仍待继续 |
| Python | 高亮源码 | 宿主读写隔离/复制验证；Finder 未测试 | 不执行 |
| TypeScript `.ts` | 按扩展名识别源码 | 实测 UTType 为 MPEG-2 视频，未验收 | 不抢占视频 UTType；可用宿主 |
| JS/C/C++/Shell 等 | 离线 Highlight.js 语言语法与类型声明 | 未逐格式测试 | 语法着色有界；不提供语义解析/编译 |
| EPUB | 有界 ZIP/XML、章节列表、原生阅读、内嵌图片、位置记录 | 章节正文、图片与章节切换通过 | 不完整 CSS/固定版式；DRM 拒绝；见 M2 边界 |
| JSONL / NDJSON | 逐记录解析、坏记录隔离、原文 | JSONL 好/坏记录通过；NDJSON 未单独测试 | 5,000 记录 |
| IPYNB | 已存储 Markdown/代码/文本与 PNG 输出 | Markdown 与短文本输出切换通过 | 不启动 kernel；HTML/JS/SVG 输出拒绝 |
| SQLite | 只读内存快照、500 行分页、全表排序、列信息 | Finder 第二/末页与数字列升序通过 | WAL 拒绝；不读视图/虚表；不执行用户 SQL |
| ZIP | 目录树、路径筛选、排序、按需正文/图片 | Finder 目录树、Swift 成员与路径筛选通过 | 无 ZIP64、加密、多卷；路径/CRC/解压预算 |
| TAR / TGZ | USTAR、gzip、有界内存读取 | TAR 正文通过；TGZ 自动测试通过，Finder 未测 | PAX/GNU 特殊项不展开 |
| diff / patch | 原文、文件分段、增删行色彩 | diff 系统处理器接管，按用户取舍接受 | OrangeLen 渲染自动测试；patch Finder 未测 |
| HAR | 本地请求记录列表与 JSON | 本机系统元数据接管，未验收 OrangeLen Finder 渲染 | 不发送请求 |
| OpenAPI JSON | paths 列表与 JSON | openapi.json Finder 正文通过 | YAML 仍源码；无外部引用/请求 |
| PDF（目录/宿主） | PDFKit 有界只读 | 未实机测试 | 单文件 Finder 保留系统；25 MiB、2,000 页 |
| Dockerfile/Containerfile、Dockerfile.dev 等变体、.dockerignore | 明确完整文件名识别与源码阅读 | Dockerfile.dev 文件夹内正文通过；单文件 Quick Look 实测仅系统元数据 | 单文件为 public.data 或其动态子类型，未命中扩展；属于未支持入口 |
| 配置文件名/变体、Vue/Svelte/Astro 等新增源码 | 明确识别与有界原文阅读，按语言语法着色，Vue/Svelte/Astro 使用 XML 类语法 | Vue/Svelte 单文件、Dockerfile.dev 文件夹正文通过；其他未逐格式实测 | 不执行；无完整语言解析；无后缀/隐藏文件 Finder 分派仍取决于系统类型 |
| JSONC / JSON5 | 保留原文范围的结构树与源码 | JSONC/JSON5 单文件结构树及 JSONC 源码切换通过 | 5 MiB/64 层/20,000 节点；坏语法回退源码；非外部完整规范套件验收 |
| SVG | XML 允许名单、隔离离线快照与源码切换 | Finder 文件夹内图形与源码切换通过；单文件由系统 HTML 预览接管 | 静态子集；全局 CSS、资源图片、use/过滤器/动画等省略；坏文件回退源码 |
| 普通 gzip 文本流 | 内存解压后日志、表格、JSON 树或 JSONL 记录 | Finder 日志、CSV 表格、JSONL 好/坏记录通过；其他组件测试 | 展开 5 MiB/压缩比 100；拒绝拼接多流/二进制/不支持内层；`.tar.gz` 仍按 TAR |
| MOBI/AZW3、7z/RAR | 未实现候选 | 未测试 | 需要独立解析器与安全/许可评估 |

所有文件为合成夹具。UTF-8/UTF-16、中文、emoji、CRLF、引号多行字段、Markdown 实体/转义和源位置由自动测试覆盖。公共 HTTPS 图片已测；真实云占位符、外置盘、其他系统与 Intel 未测试。

## 2026-10-04 Excalidraw

标准 `.excalidraw`：宿主/目录复用共享 Reader，Finder 单文件画布与源码切换已实测。新增 `com.excalidraw.excalidraw` imported UTType（conforms to `public.json`），系统已有类型声明仍可能优先；不修改默认打开应用。测试夹具 `Tests/Fixtures/m2/sample.excalidraw` 包含中英文、形状、箭头、自由笔迹和内嵌 PNG。具体边界见 [Excalidraw](excalidraw.md)。

## 2026-10-08 目录内系统格式

新增 AVKit 音视频、Word/RTF/ODT 原生导入、ImageIO 图片类型识别，以及 XLSX/XLSM/PPTX/PPTM 内容预览。Finder 内嵌套 Quick Look 服务调用失败，其他系统格式仍需单文件预览，不能将宿主 QLPreviewView 成功等同 Finder 目录支持。逐项结果与限制见 [目录系统格式](system-preview.md)。
