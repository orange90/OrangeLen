# OrangeLen 与三款开源 Quick Look 工具对比

核对日期：2026-10-16。竞品选择范围是本聊天此前统计的开源项目，按其当前公开历史 Release 安装包累计下载次数选择前三：QLMarkdown、Syntax Highlight、chamburr/glance；不宣称这是所有 macOS Quick Look 产品的市场前三。

OrangeLen 价格由用户于本聊天明确确认为“当前版本免费”。下面能力对应当前本地开发版；公开下载包仍为旧版本，正式对外投放前需使安装包与此表一致。

## 可用于宣传的对比表

**OrangeLen：从代码文档到 AI 工作成果，预览文件的内容与结构。**

| 对比项 | OrangeLen（当前开发版） | QLMarkdown 1.5.7 | Syntax Highlight 2.1.32 | Glance 1.6.0（开源版） |
|---|---|---|---|---|
| 价格 | **免费（当前版本）** | 免费 | 免费 | 免费 |
| 主要覆盖 | **代码、文档、AI 包、工作流、模型、数据、图表与 3D** | Markdown 及相关文档 | 源码与配置文件高亮 | 源码、Markdown、归档、Notebook、TSV |
| 明确后缀数量 / 公开规模¹ | **363 个，另有 49 个特殊文件名** | **9+ 个明确后缀** | **200+ 个，主要为源码/配置** | 官方未公布固定总数 |
| Markdown 排版 | 支持，含公式和 Mermaid | 支持，含公式和 Mermaid | Markdown 请配合 QLMarkdown | 支持 Markdown |
| 独立源码文件高亮 | 支持常用语言 | 主要为文档内代码块 | **广泛覆盖，强项** | 支持多种语言 |
| Cursor `.mdc` | 源码阅读 | **明确支持** | 未见专门说明 | 未见专门说明 |
| Notebook | 读取单元格及已保存输出 | 未见专门支持 | JSON 源码 | 支持渲染² |
| Skill / MCP 包 | **`.skill`、`.mcpb`、`.dxt` 内容及目录** | 未见专门解析 | 未见专门解析 | 未见专门解析 |
| ComfyUI / n8n / Dify | **工作流节点与连线预览** | 未见专门解析 | 通用 JSON/YAML 源码 | 通用 JSON/YAML 源码 |
| Parquet / Arrow / Feather | **字段与数据样本表格** | 未见专门解析 | 未见专门解析 | 未见专门解析 |
| NumPy / GGUF / Safetensors / ONNX | **数组样本、模型或张量目录³** | 未见专门解析 | 未见专门解析 | 未见专门解析 |
| JSX / TSX / MDX 组件效果 | **受支持的单文件离线快照** | MDX 文档，不渲染 JSX | 源码高亮 | 源码预览 |
| 思维导图、画布 | **XMind、FreeMind、OPML、MindManager、Draw.io、Canvas 等子集** | Mermaid 图表 | 部分 XML/JSON 源码 | 部分 XML/JSON 源码 |
| 3D 网格与场景 | **OBJ / STL / GLTF / GLB 静态预览** | 未见专门支持 | glTF 按 JSON 源码 | 未见专门支持 |
| 归档目录 | ZIP / TAR / gzip 系列及 AI/开发包 | TextBundle 文档包 | 未见归档目录预览 | **7z / ZIP / TAR 等** |
| 文件夹 / 项目目录 | **目录树、概览与成员阅读** | 未见此类浏览 | 未见此类浏览 | 未见此类浏览 |

¹ 后缀按小写去重，别名分别计数；不是编程语言数或完整格式规范数。OrangeLen 有固定清单；竞品以锁定版本的 README/类型声明为依据，数字口径不完全相同，不据此宣传“后缀最多”。QLMarkdown 的 9+ 是可核实的明确后缀下界，不排除其他类型别名。Glance 的 UTI 数不冒充后缀数。

² Glance 官方列出 Notebook 渲染；此前本机直接 Finder 入口只显示 JSON，属于类型分派/环境限制，不改写成它没有 Notebook 能力。

³ ONNX 目前是顶层节点/输入输出/张量目录，不是完整交互网络图；模型不执行。Parquet/Arrow 只显示预算内样本；组件限受支持的单文件与内置依赖；导图、3D、TeX 等有明确子集边界。

“未见专门支持/解析”指所核对版本未找到对应专门功能的公开说明或实现入口，不否认系统预览、源码兜底或未来版本可能支持。表内支持同时涵盖主应用、文件夹成员和适用的 Finder 入口，不能解读为所有后缀都已逐一通过单文件空格实测。

## 推荐宣传文字

> OrangeLen 是一款面向开发者与 AI 创作者的免费 macOS 预览工具。当前开发版覆盖 363 个明确文件后缀和 49 个特殊文件名，可预览 Skill/MCP 包、AI 工作流、模型元数据与数据集样本，也能阅读代码、Markdown、Notebook、图表和受支持的 3D 文件。

公开安装包更新后，可把上文“当前开发版”改成对应正式版本名称。现有下载包不含全部 363 后缀的新功能，当前不能省略版本边界。

## 如何突出优势

- **重点展示 AI 文件的结构视图**：技能包清单、工作流节点、张量目录和数据样本，配真实截图比单列后缀数更有说服力。
- **展示多种产物在一个阅读器中浏览**：同一项目里的说明、代码、包、图、数据和模型。
- **承认其他产品的强项**：QLMarkdown 的 Markdown 生态、Syntax Highlight 的语言覆盖、Glance 的 7z/Notebook 支持。
- 四款当前均可免费使用，“免费”是价格信息，不能包装成 OrangeLen 相对这三款独有的优势。

## 来源与核对记录

- OrangeLen：[格式清单](format-count.md)、[高级能力及限制](advanced-output-previews.md)、[开发者首批实测](evidence/developer-batch1-2026-10-15/README.md)、[免费竞品实测](competitor-free-ai-hands-on-2026-10-16.md)。
- [QLMarkdown 1.5.7 官方 README](https://github.com/sbarex/QLMarkdown/blob/1.5.7/README.md)与[扩展声明](https://github.com/sbarex/QLMarkdown/blob/1.5.7/QLExtension/Info.plist)。其 `.mdc`、MDX 文档、公式和 Mermaid 均有明确说明，不能标为缺失。
- [Syntax Highlight 2.1.32 官方 README](https://github.com/sbarex/SourceCodeSyntaxHighlight/blob/2.1.32/README.md)。支持清单正则去重有 287 个后缀提及；剔除明确转介 QLMarkdown 的 md/rmd 和标为不可处理的 dart/ts/mts 后为 282 个提及。由于其中仍涉及文件名习惯、平台和类型分派差异，宣传表保守用 200+，不把它当逐一 Finder 验证总数。
- [Glance 1.6.0 官方 README](https://github.com/chamburr/glance/blob/v1.6.0/README.md)与[类型分派源码](https://github.com/chamburr/glance/blob/v1.6.0/QLPlugin/Views/PreviewVCFactory.swift)。它是 chamburr 维护的免费开源版，不是 glance.md 的商业应用。
- OrangeLen 本轮新增后缀与编译文件边界：[对齐说明](syntax-highlight-parity.md)、[逐项覆盖](evidence/source-parity-2026-10-16/coverage.json)。
- [机器可读的数量核对与源码 commit](evidence/competitors-2026-10-16/comparison-inventory.json)。
