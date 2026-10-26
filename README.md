# OrangeLen

**按下空格预览一切**

为开发者打造的 macOS 预览工具，支持整个文件夹、代码、文档、AI 工作流、数据与 3D 模型。在 Finder 选中文件或文件夹，按下空格就能查看。

中文 · [English](README.en.md)

[下载安装](#下载) · [快速开始](#快速开始) · [支持格式](#支持格式) · [与系统预览对比](#与系统预览对比) · [开源竞品对比](#与开源竞品对比) · [开发文档](docs/development-guide.md) · [更新日志](CHANGELOG.md)

## 产品演示（中文配音与字幕）


https://github.com/user-attachments/assets/149b5c5c-ffb8-4004-8fe2-f28fc2297252

![OrangeLen 文件夹概览：目录树、项目统计与 README 阅读](docs/images/folder-overview.jpg)

*Finder 空格预览实拍：目录树、文件统计与 README 概览。界面支持中英文。*

## 下载

**[下载 OrangeLen 安装包（DMG）](https://github.com/orange90/OrangeLen/releases/download/V1.0.1/OrangeLen-1.0.1-universal.dmg)** · [Release 说明与校验值](https://github.com/orange90/OrangeLen/releases/tag/V1.0.1)

适用于 **macOS 14 及以上**，通用安装包包含 Apple Silicon 与 Intel 架构。打开 DMG，将 `OrangeLen.app` 拖入 `Applications`，再启动应用。

当前为 **V1.0.1 正式版，已使用 Developer ID 签名并通过 Apple 公证**。应用与 DMG 均附有公证票据，并通过 Gatekeeper 校验。Intel 实机与其他 macOS 版本尚未完整验收。

## AI 时代最适合的预览工具

AI 写的代码、报告、网页和工作流，保存下来就能看。打开项目文件夹，在同一个窗口里读 README、翻代码、看页面效果，也能直接检查 Skill 和 MCP 包里的内容。

| 想看什么 | OrangeLen 怎么展示 |
| --- | --- |
| **整个项目** | 展开目录树，连续查看文件；概览里看 README、文件类型分布、数量和大小 |
| **代码与配置** | 离线语法高亮、行号、查找和原文复制；识别 Dockerfile、锁文件与常见配置文件名 |
| **报告与笔记** | Markdown 大纲、公式、Mermaid、脚注和代码块复制；Notebook 连续阅读已有输出；EPUB 按章节阅读 |
| **网页与组件** | HTML 页面效果与源码切换；JSX / TSX / MDX 单文件组件快照；基础 LaTeX 与单文件 Typst 排版预览 |
| **Skill 与开发包** | `.skill` 默认打开 `SKILL.md`；MCPB / DXT、wheel / VSIX 查看清单和包内文件，无需解压到磁盘 |
| **工作流与图表** | ComfyUI / n8n / Dify 节点与连线；Draw.io、Excalidraw、JSON Canvas、Mermaid 和 DOT 图形 |
| **思维导图** | XMind 多画布、FreeMind / Freeplane、OPML 与 MindManager 主题树，使用自动布局 |
| **数据与模型文件** | JSON 结构树、CSV / TSV 筛选排序、SQLite 分页；Parquet / Arrow / Feather V2 表格、NumPy 样本及 Safetensors / GGUF / ONNX 元数据 |
| **测试与接口报告** | JUnit 测试结果、SARIF 安全报告、OpenAPI 接口摘要；HAR 请求记录、字幕时间表与 diff 增删行 |
| **3D 与压缩包** | OBJ / STL / GLTF / GLB 静态模型旋转缩放；ZIP / 7z / RAR / TAR 及压缩 TAR 目录和成员浏览 |

支持简体中文与英文、浅色与深色外观。文件保存后自动刷新，可选记住阅读位置；大文本分页加载。图片、PDF、音视频和 Office 内容也能在文件夹里查看，具体范围见[系统格式说明](docs/system-preview.md)。

## 与系统预览对比

OrangeLen 扩展 macOS Quick Look，让空格预览更适合开发与 AI 文件检查。系统预览本身很适合 PDF、照片和音视频；OrangeLen 的增量在于目录浏览和文件内容的专用展示。

| 场景 | 系统 Quick Look（未安装相关第三方扩展） | OrangeLen 增加的能力 |
| --- | --- | --- |
| 整个项目目录 | 通常显示文件夹基本信息 | 可展开的目录树、项目概览、同窗阅读文件 |
| 源码与配置 | 可识别文本的基础预览，随类型而异 | 离线语法高亮、行号、查找、原文复制与配置文件名识别 |
| Markdown 报告 | 显示取决于系统版本和类型处理器 | 大纲、GFM 表格、公式、Mermaid 与源码切换 |
| JSON / CSV / SQLite | 文本或系统自带展示，缺少统一的结构浏览 | JSON 树与路径复制、表格筛选排序、SQLite 分页 |
| Skill / MCP / 工作流 | 没有这些格式的专用包清单或工作流节点视图 | 包内文件浏览、清单概览、ComfyUI / n8n / Dify 连线图 |
| React 组件 | 没有 JSX / TSX 组件效果运行环境 | 单文件离线效果快照与源码切换 |
| 科学数据与模型文件 | 文件基本信息或系统支持的内容，取决于类型 | 数据样本表格、数组形状、模型张量目录与 ONNX 图节点元数据 |
| 3D 文件 | 支持部分系统 3D 类型，依格式而定 | 明确提供 OBJ / STL / GLTF / GLB 静态场景预览 |
| PDF、照片、音视频 | 成熟的原生预览，部分格式可标记或剪辑 | 在文件夹阅读流程中整合原生查看；不以编辑为目标 |

系统基线参考 [Apple Quick Look 使用说明](https://support.apple.com/en-sg/guide/mac-help/-mh14119/mac)。具体展示受 macOS 版本、文件类型和已装扩展影响；本表不是对所有系统版本的逐格式测试。**Finder 单文件由系统决定调用哪个预览器；OrangeLen 主应用和文件夹预览是更完整的功能入口。**

## 与开源竞品对比

阅读器覆盖 **371 个明确后缀、49 个特殊文件名**，支持目录浏览、源码阅读、工作流连线、包内文件、数据样本和模型目录。

以下对比的核对日期为 **2026-10-17**。OrangeLen 列对应已发布的 **V1.0**，上方安装包包含本表列出的功能。

| 对比项 | OrangeLen（V1.0） | QLMarkdown 1.5.7 | Syntax Highlight 2.1.32 | Glance 1.6.0（chamburr 开源版） |
| --- | --- | --- | --- | --- |
| 价格 | **免费（当前版本）** | 免费 | 免费 | 免费 |
| 明确后缀 / 公开支持规模¹ | **371 个，另有 49 个特殊文件名** | 9+ 个文档后缀 | 200+ 个源码及配置后缀 | 未公布固定总数 |
| 文件夹与项目浏览 | **目录树、项目概览、同窗阅读成员** | 未列专门功能 | 未列专门功能 | 未列专门功能 |
| 源码高亮 | 离线高亮、行号、查找与复制 | 文档内代码块 | **广泛语言覆盖；可配 LSP、VCS 和预处理器** | 多语言源码高亮 |
| Markdown / Notebook | 公式、Mermaid；Notebook 单元格及已存输出 | **Markdown 专长，含公式、Mermaid、MDX 文档及 `.mdc`** | Notebook 按 JSON 源码 | Markdown、Notebook 渲染 |
| Skill / MCP / 开发包 | **`.skill` / `.mcpb` / `.dxt` / wheel / VSIX 清单与成员** | 未列专门解析 | 未列专门解析 | 通用归档；未列专门包清单 |
| ComfyUI / n8n / Dify | **工作流节点与连线** | 未列专门解析 | 通用 JSON/YAML 源码 | 通用 JSON/YAML 源码 |
| Parquet / Arrow / Feather V2 | **字段与预算内数据样本表格** | 未列专门解析 | 未列专门解析 | 未列专门解析 |
| NumPy / GGUF / Safetensors / ONNX | **数组样本、张量目录或图节点元数据** | 未列专门解析 | 未列专门解析 | 未列专门解析 |
| JUnit / SARIF / OpenAPI | **测试结果、安全报告、接口摘要** | 未列专门解析 | 通用 XML/JSON/YAML 源码 | 通用 XML/JSON/YAML 源码 |
| 组件 / 图表 / 3D | **JSX/TSX/MDX 单文件快照、导图、DOT、静态 3D** | Mermaid；MDX 不渲染 JSX | 对应源码高亮或文本 | 对应源码；未列专门渲染 |
| 通用归档 | ZIP / 7z / RAR / TAR；gzip、XZ、BZIP2、Zstandard TAR | TextBundle 文档包 | 未列归档目录浏览 | **7z / ZIP / TAR 等** |

¹ 后缀别名分别计数，不是语言数或完整格式数；竞品公开数字口径不同，不能据此判断谁“支持最多”。“未列专门功能/解析”指所核对版本的官方说明及此前实现核查未见对应专用入口，通用文本或系统兜底仍可能可用。四款均免费，价格不是 OrangeLen 的独有优势。

**实测依据：**新增 215 个后缀逐项 Finder 验收，213 项由 OrangeLen 展示；`.text` / `.wflow` 由系统接管，已验证原生正文及 OrangeLen 文件夹阅读入口。其他既有后缀不据此视为全量通过。模型只读元数据；组件、导图和 3D 有子集限制。详见 [完整对比、来源及边界](docs/competitor-comparison-public-2026-10-16.md)。

## 支持格式

**当前明确列出 371 个不重复的文件扩展名**，详见下表；这是后缀计数，不是 371 种编程语言，也不代表所有格式都完整渲染。`.md` / `.markdown` 等别名分别计数；同一个后缀的多个用途只计一次。

**2026-10-26 本机开发版分派审计：**371 项逐项 Finder 检查，350 项进入 OrangeLen，16 项由系统显示内容，5 项仅显示文件信息（`.ts`、`.mts`、`.dot`、`.txz`、`.tbz2`）。350 项均核对扩展回调日志；本机原有 Hydra 3D 扩展停用设置保留。审计时使用包含 SQL 修复的开发版，结果不等同新包的全量重跑或完整格式兼容性，见[逐项列表与测试配置](docs/evidence/all-formats-2026-10-26/file-list.md)。

**同日后续修复：**对上述剩余 21 项再次逐项 Finder 空格与调用日志验收，10 项已进入 OrangeLen（TXZ、TBZ2、ZSH、BASH、R、PROTO、LOG、DIFF、PATCH、WFLOW），11 项仍由系统处理，其中 TS/MTS/DOT 仍无正文。WFLOW 依赖可恢复的 Shortcuts 扩展偏好，会同时影响 `.shortcut` 系统动作卡片。SQL 与 9 项精确类型修复现已包含于 V1.0.1；WFLOW 偏好需主动启用，安装不自动应用。见[修复结果、逐项证据及恢复方法](docs/evidence/provider-fixes-2026-10-26/README.md)。

| 类别 | 数量 | 扩展名 | 预览内容 |
| --- | ---: | --- | --- |
| 代码与网页 | 75 | `.swift`, `.py`, `.js`, `.ts`, `.tsx`, `.jsx`, `.mjs`, `.cjs`, `.mts`, `.cts`, `.vue`, `.svelte`, `.astro`, `.c`, `.h`, `.cpp`, `.hpp`, `.rs`, `.go`, `.sh`, `.zsh`, `.bash`, `.rb`, `.java`, `.kt`, `.css`, `.scss`, `.sass`, `.less`, `.html`, `.htm`, `.xhtml`, `.sql`, `.cs`, `.php`, `.dart`, `.lua`, `.r`, `.scala`, `.ps1`, `.proto`, `.graphql`, `.gql`, `.tf`, `.tfvars`, `.hcl`, `.pyi`, `.pyx`, `.pxd`, `.pxi`, `.cu`, `.cuh`, `.cc`, `.cxx`, `.hh`, `.hxx`, `.ipp`, `.tpp`, `.inl`, `.kts`, `.gradle`, `.groovy`, `.cmake`, `.mk`, `.mdc`, `.http`, `.rest`, `.j2`, `.jinja`, `.jinja2`, `.tmpl`, `.tpl`, `.rst`, `.adoc`, `.asciidoc` | 源码高亮；HTML 页面；JSX/TSX 单文件组件快照 |
| 文本与配置 | 11 | `.txt`, `.log`, `.ini`, `.conf`, `.config`, `.properties`, `.plist`, `.yaml`, `.yml`, `.toml`, `.xml` | 原文阅读与查找 |
| 文档与排版 | 8 | `.md`, `.markdown`, `.mdx`, `.tex`, `.typ`, `.ipynb`, `.epub`, `.pdf` | Markdown 公式与图表、Notebook 已存输出、电子书、PDF；LaTeX 基础子集与单文件 Typst |
| 结构化数据 | 12 | `.json`, `.jsonc`, `.json5`, `.jsonl`, `.ndjson`, `.csv`, `.tsv`, `.sqlite`, `.sqlite3`, `.db`, `.har`, `.sarif` | 结构树、记录、表格或请求记录；不执行 SQL 或网络请求 |
| 图表与画布 | 12 | `.mmd`, `.mermaid`, `.excalidraw`, `.drawio`, `.canvas`, `.svg`, `.xmind`, `.mm`, `.opml`, `.mmap`, `.dot`, `.gv` | 图形与源码；复杂格式采用受支持的子集 |
| Skill、MCP 与归档 | 18 | `.skill`, `.mcpb`, `.dxt`, `.n8np`, `.zip`, `.tar`, `.tgz`, `.gz`, `.whl`, `.vsix`, `.7z`, `.rar`, `.xz`, `.bz2`, `.zst`, `.txz`, `.tbz2`, `.tzst` | 包清单、目录树、按需查看成员；不安装或执行 |
| 3D 模型 | 4 | `.obj`, `.stl`, `.gltf`, `.glb` | 静态网格与场景、旋转、缩放 |
| 科学数据与模型目录 | 10 | `.parquet`, `.npy`, `.npz`, `.safetensors`, `.gguf`, `.latent`, `.arrow`, `.ipc`, `.feather`, `.onnx` | 列信息、数组样本或张量元数据；不运行模型 |
| 字幕、差异与来源结构 | 6 | `.srt`, `.vtt`, `.diff`, `.patch`, `.xmp`, `.c2pa` | 字幕表、增删行、参数源码、未验证的 C2PA 结构 |
| 更多开发者源码、配置与编译文件 | 215 | `.a3x`, `.acf`, `.ada`, `.ado`, `.applescript`, `.as`, `.ascr`, `.asd`, `.asm`, `.asp`, `.aspx`, `.atl`, `.au3`, `.avt`, `.awk`, `.bas`, `.bashrc`, `.basic`, `.bat`, `.bb`, `.bezel`, `.bib`, `.c++`, `.cfc`, `.cfg`, `.cfm`, `.cfml`, `.class`, `.cli`, `.clj`, `.cljc`, `.cljs`, `.cls`, `.cmd`, `.code-workspace`, `.coffee`, `.command`, `.con`, `.cp`, `.cr`, `.csh`, `.cson`, `.csproj`, `.ctx`, `.d`, `.designspace`, `.do`, `.dockerfile`, `.dtd`, `.dylan`, `.e`, `.ecf`, `.ecore`, `.edn`, `.el`, `.entitlements`, `.env`, `.erb`, `.erl`, `.ex`, `.exs`, `.f`, `.f90`, `.f95`, `.fea`, `.fish`, `.flow`, `.fnc`, `.for`, `.fs`, `.fsx`, `.fxml`, `.gd`, `.gemfile`, `.gleam`, `.gpx`, `.haml`, `.heex`, `.hri`, `.hrl`, `.hs`, `.ily`, `.iml`, `.inf`, `.ino`, `.iss`, `.jav`, `.javascript`, `.jl`, `.jnlp`, `.jscript`, `.jsm`, `.jsp`, `.kml`, `.kmt`, `.ksh`, `.latex`, `.lay`, `.ld`, `.lhs`, `.lisp`, `.loctable`, `.lsp`, `.ltx`, `.ly`, `.m`, `.mak`, `.map`, `.mf`, `.mill`, `.ml`, `.mll`, `.mly`, `.mobileconfig`, `.mpd`, `.mq4`, `.mq5`, `.ms`, `.mvw`, `.mxml`, `.ncx`, `.nf`, `.nim`, `.nix`, `.opf`, `.otio`, `.pas`, `.pck`, `.pddl`, `.pde`, `.ph3`, `.ph4`, `.php3`, `.php4`, `.phtml`, `.pkb`, `.pks`, `.pl`, `.pm`, `.podspec`, `.pom`, `.prc`, `.pro`, `.psd1`, `.psjs`, `.psm1`, `.pub`, `.py3`, `.raml`, `.rbw`, `.rdf`, `.readme`, `.rex`, `.rexx`, `.rhtml`, `.rjs`, `.rkt`, `.robot`, `.s79`, `.sage`, `.sas`, `.sbt`, `.sc`, `.scad`, `.sch`, `.scl`, `.scm`, `.scpt`, `.sequ`, `.sld`, `.sls`, `.smali`, `.sol`, `.sps`, `.sqs`, `.ss`, `.storybard`, `.storyboard`, `.strings`, `.stringsdict`, `.sty`, `.t`, `.tab`, `.tcl`, `.tcsh`, `.texi`, `.text`, `.tfstate`, `.tpb`, `.tps`, `.trg`, `.ttx`, `.twig`, `.unity`, `.v`, `.vb`, `.vbs`, `.vhd`, `.vhdl`, `.vim`, `.vl`, `.vw`, `.wflow`, `.xaml`, `.xcscheme`, `.xib`, `.xm`, `.xq`, `.xquery`, `.xsd`, `.xu`, `.xul`, `.zig`, `.zon`, `.zshrc` | 更多语言源码；二进制 plist、Java class 与 AppleScript 内容检查，详见支持边界 |
| **合计** | **371** | **不重复后缀** | **源码、结构或效果预览，依格式而定** |

此外还支持：

- **49 个特殊文件名与 7 组前缀规则**：如 `Dockerfile`、`Makefile`、`.env`、`.gitignore`、`.editorconfig`、`Cargo.lock`、`yarn.lock` 等依赖锁文件，以及 `.env.local`、`Dockerfile.dev` 等。完整名单见 [统计口径](docs/format-count.md)。
- **整个文件夹 / 项目目录**：目录树、项目概览、按需阅读；不计入文件后缀总数。
- **AI 工作流内容识别**：ComfyUI / n8n JSON、Dify YAML、OpenAPI JSON，复用已有 JSON / YAML 后缀，不重复加数。
- **系统格式整合**：ImageIO 图片、AVKit 音视频、Word / RTF / ODT、XLSX / PPTX 内容预览。能力依赖系统和具体文件，未计入上述固定总数；详见 [系统格式范围](docs/system-preview.md)。

统计依据见 [可复核的格式清单](docs/format-count.md)。专用预览的限制见 [高级 AI 产出](docs/advanced-output-previews.md)；实际 Finder 验证见 [支持矩阵](docs/format-support.md)。

### 专用格式与 Finder 入口

- **思维导图**：XMind 支持新版 JSON / 旧版 XML 工作簿与多画布；FreeMind / OPML 支持主题层级；MindManager 读取 `.mmap` 中的主题和浮动主题。均使用自动布局，不完整还原原始样式、备注和附件。普通 Objective-C++ `.mm` 仍按源码显示，旧版 `.mmp` 不支持。详见 [XMind](docs/evidence/xmind-2026-10-15/README.md)、[FreeMind / OPML](docs/evidence/outline-2026-10-15/README.md) 与 [MindManager](docs/evidence/mmap-2026-10-15/README.md)。
- **归档**：支持 7z、RAR4/RAR5、ZIP、TAR，以及 gzip / XZ / BZIP2 / Zstandard 压缩 TAR。`.xz` / `.bz2` / `.zst` 在清单中代表压缩 TAR，不代表任意单文件压缩流；加密、分卷及超预算归档不支持。详见[归档范围](docs/archive-formats.md)。
- **编译文件**：支持二进制 plist 内容、Java class 声明与字节码、编译 AppleScript 源码读取；编译 AutoIt 仅显示有限字节。详见[源码及编译格式范围](docs/syntax-highlight-parity.md)。
- **Finder 分派**：由 macOS 决定调用哪个预览器。已记录的 `.ts` / `.mts`、`.dot`、`.cursorrules` 等单文件入口仍有限制；`.text` / `.wflow` 保留系统预览，可通过 OrangeLen 文件夹入口读取。支持清单不代表全部后缀都由 OrangeLen 直接接管。

<details>
<summary>查看按批次记录的 Finder 验证结果</summary>

新增 215 个源码及配置后缀已逐项实测，213 项由 OrangeLen 展示，`.text` / `.wflow` 由系统接管；两者的系统正文与 OrangeLen 文件夹入口均有验证。详见 [215 项结果](docs/evidence/source-parity-finder-2026-10-16/README.md)。

既有 106 后缀基线在启用可恢复的 STL/OBJ 原生设置后，104 项主样例可见内容，`.ts` / `.mts` 仍仅基本信息；开发者首批样例直接 Finder 通过 40/42 项，`.dot` / `.cursorrules` 使用文件夹入口。各批次口径不同，不合并为全量通过率。详见[原生入口记录](docs/evidence/single-file-dispatch-2026-10-13/README.md)、[开发者格式验收](docs/evidence/developer-batch1-2026-10-15/README.md)与[归档验收](docs/archive-formats.md)。

</details>

## 快速开始

可直接使用上方[安装包](#下载)，也可从源码构建。最低部署目标为 **macOS 14**，已记录的主要实测环境为 Apple M3 Pro / macOS 26.6.2，构建使用 Xcode 26.5。其他系统和 Intel 实机尚未完整验收。

在仓库根目录运行（需安装 Xcode）：

```sh
./scripts/install-dev.sh
open ~/Applications/OrangeLen.app
```

安装脚本会先构建，再安装到 `~/Applications`。首次构建需联网获取固定版本的 Swift 依赖。

1. 在 Finder 选中文件或文件夹，按 **空格**。
2. 预览文件夹时，展开左侧目录并点选文件，在右侧查看内容。
3. 也可在 OrangeLen 中按 **⌘O** 打开文件或目录，用 **⌘,** 调整设置。

未出现 OrangeLen 时，检查系统设置中的 Quick Look 扩展，并关闭后重新打开预览。部分类型仍由系统处理，可从主应用或文件夹入口查看。详细步骤见 [Finder 配置](docs/development-guide.md#finder)。

## 使用边界

- 组件效果是单文件快照；3D 为静态场景；Office 内容预览不保证版式保真。
- 预览不安装 Skill / MCP 包、不执行工作流、不启动 Notebook kernel、不加载模型推理。React 组件在隔离、禁网的 WebKit 环境中求值。
- 文件只读；大型文本按页加载，结构、归档和媒体各有资源上限。C2PA 只展示结构，不验证真实性。
- Markdown 本地图片及关联资源需要目录权限，远程图片点击后加载；HTML 预览允许脚本和网络资源。

详见 [当前入口与边界](docs/current-contract.md) 和 [安全与资源限制](docs/development-guide.md#safety-and-limits)。

## 开发与反馈

```sh
./scripts/build.sh
./scripts/test.sh
./scripts/test-native.sh
```

源码后缀测试样例会在测试前自动生成（需要 Python 3 和 macOS 自带的 `osacompile`），无需提交 `Tests/Fixtures/source-parity/`。直接运行 SwiftPM 或 Xcode 测试也会自动准备这些样例。

欢迎提供可复现的问题、合成示例和改进建议。报告问题时请注明 macOS、芯片架构、文件后缀，以及使用的是 Finder 单文件、文件夹还是主应用入口；请勿附带私人文件或签名材料。

[架构](docs/architecture.md) · [构建、签名与卸载](docs/development-guide.md) · [验证记录](docs/verification.md) · [依赖与许可证说明](docs/dependencies.md) · [更新日志](CHANGELOG.md)
