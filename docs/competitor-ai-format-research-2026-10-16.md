# OrangeLen 竞品文件格式与 AI 产物支持调研

调研日期：2026-10-16。近两年窗口：2024-10-16 至 2026-10-16。

后续已进行免费竞品本机测试，见[实测报告](competitor-free-ai-hands-on-2026-10-16.md)。尤其注意 OmniPreview 下载包免费状态的 Pro 边界与在线清单不同；下文是公开资料口径，不能替代后续现场结果。

## 结论

竞品已经进入 AI 文件领域。Looq 明确增加 `.skill` 和 Claude Code/Codex 会话入口；Unfold 明确支持 `.mdc`；OmniPreview 涉及生成图片参数、模型与科学数据；Quicklook-Netron 专门提供神经网络可视化。OrangeLen 不宜宣传“只有我们支持 AI 文件”。

值得建立的差异是：对同一份 AI 工作成果，能否在 Finder 中直接看懂包、规则、工作流、生成参数、模型和数据，而不只是显示文件文本或压缩包目录。以下竞争判断属于基于公开资料的分析，不是竞品安装实测。

## 口径与证据边界

- 优先采用产品官网、官方更新日志、项目仓库和格式规范。支持列表为代表性覆盖，不冒充闭源产品完整清单。
- “明确支持”指官方声明；“未见说明”不等于不支持。是否被 Finder 分派、复杂真实文件是否成功，仍需安装测试。
- 区分四层：源码/文本可读、渲染效果、业务结构解析、Finder 单文件直接进入。四者不能互相替代。
- 200+ 编程语言、250+ 文件类型、148 个后缀不是同一统计单位，不用这些数字排功能强弱。
- 本轮没有安装竞品，也没有改变 OrangeLen 功能或安装包。

## 主要竞品支持什么

| 产品 | 公开支持的代表性文件 | AI 相关证据与判断 |
|---|---|---|
| **Looq** | Markdown/公式/Mermaid、源码、JSON/XML/plist/SQL、TSV、SQLite、diff/patch、ZIP/TAR/GZ/BZ2、文件夹；应用与安装包元数据，APK、SVG/SVGZ、Org | 更新日志 1.7.3 明确列出 `.skill`，但没有解释包内解析深度；1.7.0 增加 Claude Code/Codex 会话入口。不能据此认定有完整 JSONL 对话回放。[官网](https://parcse.com/looq)、[更新日志](https://parcse.com/changelog/looq) |
| **Unfold** | 源码/配置、Markdown/MDX/Mermaid、Jupyter、LaTeX/BibTeX、TAB/TSV、ZIP/7z/RAR/TAR/XZ、EPUB/FB2/CBZ/CBR、字幕、网页归档、torrent、app；新增 STEP/3MF | 2.7.1 明确加入 `.mdc`；通用 JSON/YAML/JSONL 可读，不代表理解工作流或会话结构。MDX 在列表中不代表运行 React 组件。[格式清单](https://unfold.tools/)、[更新日志](https://unfold.tools/changelog) |
| **spacebar** | Markdown、源码/配置、JSON 树、plist、diff、Notebook、压缩包；图片/音视频/PDF/HTML/CSV，部分格式借助 Apple 预览 | 专门面向 Claude Code 的 Markdown 场景。可选辅助功能权限下的 Space helper 使用应用窗口，需和原生 Quick Look 扩展区分；“几乎任何文件”也包括系统预览与兜底。[格式说明](https://spacebar.patebryant.com/file-types/)、[产品说明](https://spacebar.patebryant.com/)、[Claude Code 页面](https://spacebar.patebryant.com/claude-code-markdown/) |
| **Glance（glance.md）** | Markdown、公式/图表；JSON/YAML 格式化；独立应用提供编辑 | 专页明确面向 `AGENTS.md`、`CLAUDE.md`、`SKILL.md`。这是 Markdown 文件支持，不等于 `.skill` 包解析；Quick Look 只读，编辑在应用中。[专页](https://glance.md/preview-agents-md-claude-md/)、[官网](https://glance.md/) |
| **Glance（chamburr/glance）** | 代码、Markdown、7z/TAR/ZIP、ipynb、TSV/TAB | 开源综合预览基线，公开 README 未见 AI 包/工作流专门解析。它与 glance.md 是不同产品。[仓库](https://github.com/chamburr/glance) |
| **Syntax Highlight** | 大量源码与配置；例如 CUDA、CMake、Groovy、Astro；glTF 按 JSON、Unity 按 YAML；二进制可十六进制查看 | 强项是代码可读性；glTF 文本高亮不是 3D 预览，JSON 高亮不是模型/工作流解析。Markdown 另用 QLMarkdown。[仓库](https://github.com/sbarex/SourceCodeSyntaxHighlight) |
| **Peek** | 主要是源码/文本高亮、搜索、跳转等 | 官方页面搜索索引仍可核实源码预览定位，但本轮页面正文抓取不稳定，未充分确认当前完整列表与 AI 专项能力，不引用其他竞品替它统计的后缀数。[官网](https://www.bigzlabs.com/peek.html) |
| **OmniPreview / QuickLookWithSteroids** | 图像、媒体、模型与科学数据等广泛类型 | README 明确涉及 ComfyUI/A1111 图片参数、GGUF、Safetensors、NumPy；部分 ONNX/科学数据能力标注 WIP。属于需要重点关注的 AI 专项竞争者。[仓库](https://github.com/Invernomut0/QuickLookWithSteroids) |
| **Quicklook-Netron** | ONNX、PB、TFLite、Core ML、PT/PTH、H5/Keras、Safetensors 等项目列出的模型类型 | 使用 Netron 提供网络结构可视化；不能把上游 Netron 的全部能力直接算成这个封装已通过 Finder 验收。[仓库](https://github.com/Oil3/Quicklook-Netron) |

## 最近两年的“新 AI 文件”应怎样判断

| 类别 | 是否属于近两年新格式 | 竞品覆盖结论 |
|---|---|---|
| `.mcpb` / `.dxt` | **明确的新打包约定。** DXT 于 2025-06-26 公布，2025-09-11 改称 MCPB；容器仍是 ZIP，核心为 manifest 与 server | 本轮所查主流综合竞品公开资料中，未见明确的 MCPB manifest 专门视图；不能排除通用归档打开能力。[Anthropic 官方说明](https://www.anthropic.com/engineering/desktop-extensions) |
| Agent Skills / `SKILL.md` / `.skill` | **新生态与目录约定，三者不可等同。** Agent Skills 规范定义 SKILL.md 及可选脚本、资源目录，不意味着所有技能都采用 `.skill` 后缀 | Looq 已声明 `.skill`；glance.md 明确 SKILL.md。对比必须验证“压缩包目录、说明渲染、脚本资源导航”各层。[规范](https://agentskills.io/specification)、[Skills 发布说明](https://claude.com/resources/articles/skills) |
| Cursor `.mdc` / `.cursor/rules` | **近两年的规则约定。** Cursor 2025-01-23 发布项目规则目录；属于 Markdown 及元数据体系，不是全新二进制编码 | Unfold 已明确加入 `.mdc`。仍应测试是否把作用范围等元数据单独显示。[Cursor 更新日志](https://cursor.com/changelog/0-45-x)、[规则文档](https://cursor.com/docs/rules) |
| `AGENTS.md` / `CLAUDE.md` | 新工具生态中的命名和使用约定；底层 Markdown 很早就存在。通常属于 AI 输入/配置，未必是生成产物 | spacebar、glance.md 已主动面向这一用途；其他 Markdown 阅读器也可能直接渲染，但未必理解目录作用域。[AGENTS.md](https://agents.md/)、[Glance 专页](https://glance.md/preview-agents-md-claude-md/) |
| ComfyUI / n8n JSON、Dify YAML | 工具专属结构，不能把 JSON/YAML 自身称为近两年新格式；不同 schema 持续变化 | “能看 JSON”不能算节点图支持。所查综合竞品未见三者结构图统一支持的明确说明；OmniPreview 涉及 ComfyUI 图片元数据。[ComfyUI 文档](https://docs.comfy.org/development/api-development/workflow-metadata) |
| n8n `.n8np` | 官方已有 Preview 包格式；本轮未核实首次发布日期，**不强行归入两年内首创** | 未见所查竞品明确支持；值得跟踪版本变化。[n8n 文档](https://docs.n8n.io/build/manage-workflows/n8n-packages/) |
| GGUF / Safetensors / ONNX / NumPy / Parquet / Arrow | 不应整体列为近两年新文件；多数是 AI 工作流重新放大的既有格式。例如 Safetensors 在 2023 年已完成公开安全审计 | 模型类已有专项竞争者；数据预览要区分识别容器、列 schema、显示实际数据。[Safetensors 2023 审计](https://huggingface.co/blog/safetensors-security-audit) |
| AI 图片 PNG/WebP、生成 HTML/JSX/TSX/MDX、PDF/视频 | 大多使用既有格式；新增价值在内嵌参数、来源信息或可运行组件的解释方式 | 能显示图片不等于能读 prompt/seed/model；源码高亮不等于组件效果预览。不能以扩展名支持数量代替这一差异 |

## AI 能力矩阵

“—”表示本轮未找到明确的专门能力声明，不表示确定不支持。文本可读不算专门解析。证据链接见上表对应产品行。

| 场景 | Looq | Unfold | spacebar / glance.md | OmniPreview | Quicklook-Netron |
|---|---|---|---|---|---|
| Agent 指令 Markdown | Markdown 渲染 | Markdown 渲染 | 明确面向此用途 | — | — |
| Cursor MDC | — | 明确列出 | — | — | — |
| 打包 `.skill` | 明确列出，深度未知 | — | SKILL.md 不能替代 | — | — |
| MCPB/DXT 清单解析 | — | — | — | — | — |
| Agent 最近产物/会话入口 | 明确有入口，回放深度未知 | — | Markdown 文件场景 | — | — |
| AI 图片生成参数 | — | — | — | 明确列出 | — |
| 模型头部/张量信息 | — | — | — | 明确列出部分类型 | 模型可视化方向 |
| 神经网络图 | — | — | — | ONNX 相关标 WIP | 核心用途 |
| ComfyUI/n8n/Dify 工作流结构图 | — | — | — | 图片元数据不等于完整工作流编辑图 | — |
| Parquet/Arrow 实际数据表 | — | — | — | 文档列 footer/容器识别，不能算完整表格 | — |

## 对 OrangeLen 的实际意义

本地能力以当前源码和项目文档为基准，不能把历史规划当成已实现。主要依据：[高级产物预览](advanced-output-previews.md)、[首批开发者格式验收](evidence/developer-batch1-2026-10-15/README.md)。

### 已有能力应当怎样呈现

1. **AI 交付包。** `.skill`、MCPB/DXT、n8np 应展示“用途、清单、目录、成员内容”而非只展示图标。Looq 已有 `.skill` 声明，所以技能包不再是可直接宣称独占的卖点。
2. **工作流与生成来源。** ComfyUI/n8n/Dify 节点图、AI 图片参数是更具体的演示场景。OmniPreview 已覆盖部分图片参数，应比较字段完整性、异常数据和进入路径。
3. **数据与模型。** OrangeLen 已有 Parquet/Arrow 样本表格、NPY/NPZ、GGUF/Safetensors、ONNX 概览。对模型要诚实注明：ONNX 当前为顶层图与张量目录，不是 Netron 那样的完整交互网络图；GGUF/Safetensors 不运行模型。
4. **AI 生成前端。** 单文件 React/MDX 效果预览可与竞品的源码高亮明确区分，但现有离线依赖与单文件边界必须写清楚，不能宣称任意 AI 项目都能运行。

### 建议优先级（本轮为建议，尚未实施）

| 优先级 | 建议 | 理由与验收方式 |
|---|---|---|
| P0 | 用同一组样例实测 Looq、Unfold、OmniPreview、Quicklook-Netron | 先确认 `.skill` 包解析、MDC 元数据、AI 图片参数、ONNX 图实际深度；分别记录 Finder 单文件、文件夹内、独立应用入口 |
| P1 | 打磨已有 AI 结构视图与入口稳定性 | 比继续累计冷门源码别名更能形成可见价值；固定截图展示“普通文本→结构概览”，同时测试真实大文件及损坏样例 |
| P2 | 评估 Agent 会话 JSONL 专门预览 | 显示消息轮次、工具调用、修改文件；必须区分 Claude Code/Codex 不同 schema。Looq 已有入口，值得比较，但公开资料不足以认定其已提供完整回放 |
| P2 | 评估 ONNX 交互图、模型兼容性说明 | 回应 Netron 专项竞争；先确认大图预算和交互收益，避免把权重执行引入预览 |
| P3 | 按用户需求补通用长尾 | Unfold 的 7z/RAR、字幕、STEP/3MF，Looq 的安装包/签名信息等是可研究方向；与当前源码逐项核对后再定缺口，不凭本表直接宣布 OrangeLen 全部缺失 |

### 宣传与测试边界

可使用的方向：“在 Finder 里检查 AI 工作成果的内容、结构和生成信息”。应避免“唯一支持 AI 文件”“支持所有模型”“148 种文件都已直接 Finder 验证”。

本地现有首批验收为 42 个正常样例中 40 个直接 Finder 成功；DOT 与 `.cursorrules` 在该机器通过文件夹预览入口。这个已知差异也应成为竞品实测表的必填项。竞品网站声明不能与本机实测混为同一证据级别。


## 2026-10-16 公开下载量补充

通过 GitHub REST API 逐页汇总当前公开 Releases 的安装包附件（DMG/ZIP 等），排除校验和文件。不是独立用户、销量或全部分发渠道；包含升级、重复下载、自动化及本轮竞品实测下载。删除过的发布资产也不在统计内。原始记录见 [github-downloads.json](evidence/competitors-2026-10-16/github-downloads.json)。

| 项目 | 当前公开历史安装包累计下载次数 |
|---|---:|
| [patebry/spacebar](https://github.com/patebry/spacebar/releases) | 66 |
| [chamburr/glance](https://github.com/chamburr/glance/releases) | 36,503 |
| [Oil3/Quicklook-Netron](https://github.com/Oil3/Quicklook-Netron/releases) | 41 |
| [Invernomut0/QuickLookWithSteroids](https://github.com/Invernomut0/QuickLookWithSteroids/releases) | 35 |
| [sbarex/SourceCodeSyntaxHighlight](https://github.com/sbarex/SourceCodeSyntaxHighlight/releases) | 175,796 |
| [sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown/releases) | 401,718 |

Looq 官网的 1,000+ 是 Parcse 多款应用合计用户文案，不是 Looq 单独下载量；Quick Looks summoned 是预览调用数，亦不是下载量。[官方页面](https://parcse.com/looq)。本轮未找到 Looq/Peek 可核验的完整下载或销量。

Unfold 作者在 2026-04-02 的发布帖自报首月 30 位付费用户、114 次试用。这是历史、未经独立审计的作者自报，不能当作当前累计量。[原帖](https://www.reddit.com/r/macapps/comments/1sa7u6t/macos_unfold_v20_quick_look_a_variety_of_files_on/)。搜索中的 Squarespace Unfold 移动端数据与本产品无关。
