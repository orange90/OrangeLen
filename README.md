# OrangeLen

**按下空格，看懂整个项目与 AI 产出。**

为开发者设计的 macOS 快速预览工具。**106 种明确支持的文件后缀、36 个特殊文件名、整个文件夹预览**，覆盖代码、Markdown、Skill / MCP 包、AI 工作流、数据集与 3D 模型。

中文 · [English](README.en.md)

[下载安装](#下载) · [快速开始](#快速开始) · [支持格式](#支持格式) · [与系统预览对比](#与系统预览对比) · [开发文档](docs/development-guide.md) · [更新日志](CHANGELOG.md)

## 产品演示（中文配音与字幕）

https://github.com/user-attachments/assets/3421e382-f677-4088-9150-1a6428989489

![OrangeLen 文件夹概览：目录树、项目统计与 README 阅读](docs/evidence/folder-redesign/overview-light.png)

*真实应用截图：选中整个文件夹，从项目概览进入代码、文档和数据。*

## 下载

**[下载 OrangeLen 安装包（DMG）](https://github.com/orange90/OrangeLen/releases/download/v0.1.0-preview.1/OrangeLen-0.1.0-preview.1-universal.dmg)** · [Release 说明与校验值](https://github.com/orange90/OrangeLen/releases/tag/v0.1.0-preview.1)

适用于 **macOS 14 及以上**，通用安装包包含 Apple Silicon 与 Intel 架构。打开 DMG，将 `OrangeLen.app` 拖入 `Applications`，再启动应用。

当前为 **0.1.0 预览版，使用 ad-hoc 签名，尚未通过 Apple 公证**。若系统阻止打开，先尝试启动一次，再到“系统设置 → 隐私与安全性”选择“仍要打开”（若系统提供此选项）。Intel 实机与其他 macOS 版本尚未完整验收。

## AI 写完了，先看一眼

一轮 AI 协作，可能留下一个项目目录、一份研究报告、一个 Skill、一张工作流图和一个 3D 模型。OrangeLen 把检查这些文件的过程放进熟悉的空格预览：展开目录，点选文件，看效果，再切回源码核对。

| 亮点 | 你可以直接做什么 |
| --- | --- |
| **整个文件夹都能预览** | 展开多层目录，在同一窗口连续查看文件；看 README、项目声明线索、文件数量与大小 |
| **代码与文档一起读** | 源码高亮、行号、查找与复制；Markdown 大纲、公式、Mermaid 图；JSON 可展开结构 |
| **Skill / MCP 包先看后用** | `.skill` 优先打开 `SKILL.md`；MCPB / DXT 查看清单与成员；无需解压到磁盘 |
| **AI 工作流直接看连线** | 查看 ComfyUI、n8n、Dify 的节点图，以及 Draw.io、Excalidraw 和 JSON Canvas |
| **组件与模型看得到效果** | JSX / TSX / MDX 单文件组件快照；OBJ / STL / GLTF / GLB 静态 3D 预览、旋转与缩放 |
| **生成结果连同参数一起看** | 图片里已有的 prompt、seed、模型参数；Parquet / NumPy 样本；Safetensors / GGUF 张量目录 |

原生 macOS 界面，支持简体中文与英文、浅色与深色外观。专用渲染引擎随应用打包；HTML 允许脚本与网络资源，Markdown 远程图片点击后加载。

<details>
<summary>查看 AI 图片参数预览截图</summary>

![Finder 文件夹内查看图片与已有的 AI 生成参数](docs/evidence/ai-outputs/finder-image-parameters.png)

*合成测试图片，用于展示参数面板。只读取文件已有的参数，不推断缺失信息。*

</details>

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
| AI 图片与模型文件 | 图片画面或文件基本信息，取决于类型 | 已保存的生成参数、模型张量目录与数组样本 |
| 3D 文件 | 支持部分系统 3D 类型，依格式而定 | 明确提供 OBJ / STL / GLTF / GLB 静态场景预览 |
| PDF、照片、音视频 | 成熟的原生预览，部分格式可标记或剪辑 | 在文件夹阅读流程中整合原生查看；不以编辑为目标 |

系统基线参考 [Apple Quick Look 使用说明](https://support.apple.com/en-sg/guide/mac-help/-mh14119/mac)。具体展示受 macOS 版本、文件类型和已装扩展影响；本表不是对所有系统版本的逐格式测试。**Finder 单文件由系统决定调用哪个预览器；OrangeLen 主应用和文件夹预览是更完整的功能入口。**

## 支持格式

**当前明确列出 106 个不重复的文件扩展名**，详见下表；这是后缀计数，不是 106 种编程语言，也不代表所有格式都完整渲染。`.md` / `.markdown` 等别名分别计数；同一个后缀的多个用途只计一次。

| 类别 | 数量 | 扩展名 | 预览内容 |
| --- | ---: | --- | --- |
| 代码与网页 | 46 | `.swift`, `.py`, `.js`, `.ts`, `.tsx`, `.jsx`, `.mjs`, `.cjs`, `.mts`, `.cts`, `.vue`, `.svelte`, `.astro`, `.c`, `.h`, `.cpp`, `.hpp`, `.rs`, `.go`, `.sh`, `.zsh`, `.bash`, `.rb`, `.java`, `.kt`, `.css`, `.scss`, `.sass`, `.less`, `.html`, `.htm`, `.xhtml`, `.sql`, `.cs`, `.php`, `.dart`, `.lua`, `.r`, `.scala`, `.ps1`, `.proto`, `.graphql`, `.gql`, `.tf`, `.tfvars`, `.hcl` | 源码高亮；HTML 页面；JSX/TSX 单文件组件快照 |
| 文本与配置 | 11 | `.txt`, `.log`, `.ini`, `.conf`, `.config`, `.properties`, `.plist`, `.yaml`, `.yml`, `.toml`, `.xml` | 原文阅读与查找 |
| 文档与排版 | 8 | `.md`, `.markdown`, `.mdx`, `.tex`, `.typ`, `.ipynb`, `.epub`, `.pdf` | Markdown 公式与图表、Notebook 已存输出、电子书、PDF；LaTeX 基础子集与单文件 Typst |
| 结构化数据 | 11 | `.json`, `.jsonc`, `.json5`, `.jsonl`, `.ndjson`, `.csv`, `.tsv`, `.sqlite`, `.sqlite3`, `.db`, `.har` | 结构树、记录、表格或请求记录；不执行 SQL 或网络请求 |
| 图表与画布 | 6 | `.mmd`, `.mermaid`, `.excalidraw`, `.drawio`, `.canvas`, `.svg` | 图形与源码；复杂格式采用受支持的子集 |
| Skill、MCP 与归档 | 8 | `.skill`, `.mcpb`, `.dxt`, `.n8np`, `.zip`, `.tar`, `.tgz`, `.gz` | 包清单、目录树、按需查看成员；不安装或执行 |
| 3D 模型 | 4 | `.obj`, `.stl`, `.gltf`, `.glb` | 静态网格与场景、旋转、缩放 |
| 科学数据与模型目录 | 6 | `.parquet`, `.npy`, `.npz`, `.safetensors`, `.gguf`, `.latent` | 列信息、数组样本或张量元数据；不运行模型 |
| 字幕、差异与来源结构 | 6 | `.srt`, `.vtt`, `.diff`, `.patch`, `.xmp`, `.c2pa` | 字幕表、增删行、参数源码、未验证的 C2PA 结构 |
| **合计** | **106** | **不重复后缀** | **源码、结构或效果预览，依格式而定** |

此外还支持：

- **36 个特殊文件名与 7 组前缀规则**：如 `Dockerfile`、`Makefile`、`.env`、`.gitignore`、`.editorconfig`、`Cargo.lock`、`yarn.lock` 等依赖锁文件，以及 `.env.local`、`Dockerfile.dev` 等。完整名单见 [统计口径](docs/format-count.md)。
- **整个文件夹 / 项目目录**：目录树、项目概览、按需阅读；不计入文件后缀总数。
- **AI 工作流内容识别**：ComfyUI / n8n JSON、Dify YAML、OpenAPI JSON，复用已有 JSON / YAML 后缀，不重复加数。
- **系统格式整合**：ImageIO 图片、AVKit 音视频、Word / RTF / ODT、XLSX / PPTX 内容预览。能力依赖系统和具体文件，未计入上述固定总数；详见 [系统格式范围](docs/system-preview.md)。

统计依据见 [可复核的格式清单](docs/format-count.md)。专用预览的限制见 [高级 AI 产出](docs/advanced-output-previews.md)；实际 Finder 验证见 [支持矩阵](docs/format-support.md)。

## 快速开始

可直接使用上方[安装包](#下载)，也可从源码构建。最低部署目标为 **macOS 14**，已记录的主要实测环境为 Apple M3 Pro / macOS 26.6.2，构建使用 Xcode 26.5。其他系统和 Intel 实机尚未完整验收；正式分发签名与公证尚未完成。

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
- Markdown 本地图片及关联资源需要目录权限；HTML 预览允许脚本和网络资源。

详见 [当前入口与边界](docs/current-contract.md) 和 [安全与资源限制](docs/development-guide.md#safety-and-limits)。

## 开发与反馈

```sh
./scripts/build.sh
./scripts/test.sh
./scripts/test-native.sh
```

欢迎提供可复现的问题、合成示例和改进建议。报告问题时请注明 macOS、芯片架构、文件后缀，以及使用的是 Finder 单文件、文件夹还是主应用入口；请勿附带私人文件或签名材料。

[架构](docs/architecture.md) · [构建、签名与卸载](docs/development-guide.md) · [验证记录](docs/verification.md) · [依赖与许可证说明](docs/dependencies.md) · [更新日志](CHANGELOG.md)
