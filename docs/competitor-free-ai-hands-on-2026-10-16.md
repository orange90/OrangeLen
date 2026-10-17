# 免费竞品 AI 文件实测：OrangeLen 对照

日期：2026-10-16。环境：本机 macOS 26.6.2（25G83）。

## 本轮结论

在本轮小型合成样例中，OrangeLen 对技能包、MCPB、三种工作流、模型目录、数组和表格数据的结构化展示，明显多于 spacebar 和开源 Glance 的实际 Finder 结果。这个结论只适用于已测版本、样例和本机环境，不代表覆盖所有真实 AI 文件。

最值得补强的三项是：**Notebook 的单元格与输出分区、MDC 规则的语义展示、文件夹跨文件内容检索**。其中 Notebook 是截图直接体现的竞品体验优势；MDC 是双方共同缺口；内容检索已看到竞品控件，但检索结果未完成验证。

模型图仍值得评估，不过 Quicklook-Netron 本机入口未通过，不能把官方宣传当成本轮已验证的优势。AI 图片参数的单文件入口也是双方共同问题，OrangeLen 仍需把已有能力更清楚地呈现给用户。

## 实测范围与中断边界

| 产品 | 下载版本 / 包内版本 | 实际测试 |
|---|---|---|
| OrangeLen | 本机现有开发安装，0.1.0 | 17 项基线观察；MDC 在工具记录中，其他项有截图 |
| spacebar | 官方 GitHub v0.5.0 / 0.5.0 | 17 项 Finder 选择 + Space；额外补测侧栏中的 Notebook/MDC/skill/MCPB/PNG |
| Glance（chamburr） | v1.6.0 / 1.6.0 | 17 项 Finder 选择 + Space；不是另一个 glance.md 产品 |
| OmniPreview | release v0.3.6 / **包内 0.3.4** | 只完成前 6 项；免费状态实见 Markdown 排版和代码高亮的 Pro 提示 |
| Quicklook-Netron | quicklook-netron-1.0 / 1.0 | ONNX 样例和应用自带 sample.onnx 都显示系统文件卡片；未进入网络图 |

OmniPreview 第 6 项后，CUA 桌面自动化出现 `Sky Computer Use native pipe closed before response`。重试、重置会话后仍无法恢复。**OmniPreview 后 11 项、AI 图片参数专门面板、跨文件搜索结果、恢复后的 Finder 现场复查未完成**，不计为通过或不支持。没有以脚本猜测窗口结果。

下载、版本、签名检查见 [downloads.json](evidence/competitors-2026-10-16/downloads.json) 与 [installed.json](evidence/competitors-2026-10-16/installed.json)。所有应用来自对应项目官方 Release，没有购买、激活 Pro 或移除许可限制。

## 方法

1. 从 OrangeLen 仓库复制 17 份合成文件，同一份文件用于各产品。原始内容、来源、大小及 SHA-256 见 [samples.json](evidence/competitors-2026-10-16/samples.json)。没有将私人项目交给竞品。
2. 使用官方发布的二进制，安装到 `~/Applications`。按产品逐一启用其 Quick Look 扩展，暂时关闭 OrangeLen 和其他本轮竞品扩展，刷新 Quick Look 注册。
3. 用 CUA 操作 Finder 选择文件、按空格，保存窗口截图和可访问性文本。纯系统图片/文本兜底单独记录，不算竞品成功解析。
4. 同时记录本机实际 UTType 和扩展声明。关闭 OrangeLen 扩展并不会移除它已登记的类型；所以这是**实际共存环境**，不是干净系统实验。
5. 结束时已通过 pluginkit 恢复 OrangeLen 七个预览扩展，关闭本轮四款竞品的预览/缩略图扩展，并终止本轮启动的宿主进程；注册状态见 [恢复记录](evidence/competitors-2026-10-16/plugins-restored.txt)。CUA 中断后未能再以 Finder 窗口复核恢复结果。应用仍留在 `~/Applications`，便于后续复测；未启用 spacebar 的辅助功能 helper 或默认应用关联。

## 逐项结果

“卡片”指只有文件名、图标、大小等系统信息。“原文”指可读文本，可能是系统兜底；不等于产品专门理解该格式。“未测”不能解释为不支持。

| 同一测试文件 | OrangeLen | spacebar 0.5.0 | Glance 1.6.0 | OmniPreview 免费状态 |
|---|---|---|---|---|
| Markdown（01） | 排版 | 排版 + 同目录侧栏 | 排版 | 原文，提示排版需 Pro |
| Cursor MDC（02） | 源码，frontmatter 原样 | 直接入口为原文；侧栏也为 Plain text | 原文 | 原文 |
| `.skill`（03） | 目录 + 自动选中 SKILL.md 并排版 | 直接入口卡片；侧栏仅基本信息 | 卡片 | 卡片 |
| `.mcpb`（04） | 清单概览 + 目录 | 直接入口卡片；侧栏仅基本信息 | 卡片 | 卡片 |
| ComfyUI JSON（05） | 节点和连线图 | JSON 树 | JSON 源码高亮 | 原文，提示高亮需 Pro |
| n8n JSON（06） | 节点和连线图 | JSON 树 | JSON 源码高亮 | 原文，提示高亮需 Pro |
| Dify YAML（07） | 节点和连线图 | YAML 源码 | YAML 源码高亮 | 未测 |
| AI PNG（08） | 直接入口为系统图片 | 直接入口为系统图片；侧栏为图片、尺寸，无生成参数 | 系统图片 | 未测 |
| Safetensors（09） | metadata、张量名/dtype/shape/字节数 | 卡片 | 卡片 | 未测，官方列 Pro |
| GGUF（10） | 模型 metadata + 张量目录 | 卡片 | 卡片 | 未测，官方列 Pro |
| ONNX（11） | 顶层算子、输入输出及 shape 表格 | 卡片 | 卡片 | 未测，官方列 Pro |
| NPY（12） | dtype、shape、存储顺序、6 个值 | 卡片 | 卡片 | 未测，官方列 Pro |
| Parquet（13） | 实际 3 行、3 列与类型 | 卡片 | 卡片 | 未测，官方列 Pro |
| Arrow（14） | 实际 3 行、3 列，含中文/NULL | 卡片 | 卡片 | 未测，官方列 Pro |
| TSX（15） | 单文件组件效果快照 | TypeScript 源码高亮 | 本机为原文 | 未测 |
| Notebook（16） | Markdown、代码和保存输出可读 | 直接入口 JSON 原文；**侧栏入口正常单元格排版** | 本机直接入口 JSON 原文 | 未测 |
| n8np（17） | 包摘要、目录 | 卡片 | 卡片 | 未测 |

17 个文件并不等于 17 个独立格式标准；本轮也没有针对每个解析器测试大文件、完整规范或所有畸形输入，不计算虚假的“总支持率”。01 为重命名的简单 Markdown 卡片，只验证 Markdown 阅读，不验证 AGENTS.md 目录作用域。

原始截图及文本见 [证据目录](evidence/competitors-2026-10-16/README.md)。OrangeLen 早期录制文件名存在一位偏移，保留原始文件并在 [capture-index.json](evidence/competitors-2026-10-16/capture-index.json) 中明确对应关系；判定使用窗口内实际文件名。

## 可以直接看到的差异

### 工作流：OrangeLen 已有可见优势

同一份 ComfyUI 文件，spacebar 展开的是 `nodes/links` JSON 树，Glance 显示源码；OrangeLen 显示两个节点及带标签的连线。n8n/Dify 也有同样的结构差异。这比“都支持 JSON/YAML”更能说明产品价值。

[OrangeLen 工作流截图](evidence/competitors-2026-10-16/orangelen/04.png) · [spacebar JSON 树](evidence/competitors-2026-10-16/spacebar/05.png) · [Glance 源码](evidence/competitors-2026-10-16/glance/05.png)

### Notebook：应该补单元格视图

spacebar 侧栏入口实际渲染了 Markdown、`[1]` 执行序号、带行号的代码块，以及独立输出区域。OrangeLen 能读内容，但代码与输出的层次较弱，且内外重复工具栏占据更多空间。

建议补：按单元格分区、代码/输出独立折叠、执行序号、逐单元格复制，收紧重复工具栏。PNG/表格富输出可在后续用独立样例评估；本轮只测到文本输出，不宣称竞品图片输出已通过。两者都显示了样例预置的安全文本回退，没有弹出样例脚本的 alert。

[spacebar Notebook](evidence/competitors-2026-10-16/spacebar/folder-16-notebook.ipynb.png) · [OrangeLen Notebook](evidence/competitors-2026-10-16/orangelen/16-full.png)

### 文件夹内容检索：有价值，验证尚不完整

spacebar 每份受支持文档旁边都有同目录侧栏，实际看到 Names/Contents 切换和过滤控件。OrangeLen 的 FolderController 当前按已加载节点的文件名筛选，没有相应的跨文件正文搜索实现。

可以做有界的文本内容检索，给出匹配片段、文件位置和扫描范围。**本轮没有成功完成 spacebar 查询结果验证，不能写成已验证搜索准确率、递归范围或性能。** 也不把整个磁盘索引纳入建议。

### MDC：双方都停留在原文层

OrangeLen 已登记 `.mdc`，但本轮看到的是源码及原始 `description/alwaysApply`。spacebar 侧栏也显示 Plain text。可以把 description、globs、alwaysApply 转为规则信息栏，正文走 Markdown，另保留源码入口。这个建议来源于本机共同缺口，不是复制某个已验证竞品功能。

### 模型：不能忽略入口共存问题

本机 ONNX 的实际类型是 `local.orangelen.scientific`，Quicklook-Netron 1.0 扩展主要登记动态 `dyn.*` 类型和 Core ML 类型，没有声明这个类型及通用 `public.data`。Finder 与它自带 sample.onnx 的 Quick Look 都只出现文件卡片。

类型声明不匹配与观察结果一致，是目前有证据支持的入口原因；没有把全部潜在原因都排除。**本轮无法判断网络图的质量、与当前 ONNX IR 的兼容性或完整格式覆盖。** OrangeLen 自己的 `.scientific` 把多个后缀归为一个 UTType，这也提醒我们要评估与其他预览器的共存，不宜靠排他抢占制造“领先”。

[Netron 本机结果](evidence/competitors-2026-10-16/netron/onnx-finder.png) · [类型记录](evidence/competitors-2026-10-16/runtime-content-types.tsv) · [扩展原始声明](evidence/competitors-2026-10-16/extension-manifests.json)

### AI 图片：已有解析能力仍需要清楚的进入路径

本轮 OrangeLen 和两款免费综合竞品的 PNG 单文件都进入系统图片预览。spacebar 侧栏图片没有生成参数。OrangeLen 已有参数解析不能据此宣传为这次单文件已通过；后续应单独验证文件夹/应用中的参数面板，并让用户能发现这一入口。

OmniPreview 的生成图片参数本轮未测到，不能判定免费可用性或解析完整性。

## 建议补强顺序

| 优先级 | 建议 | 此次依据 |
|---|---|---|
| P1 | Notebook 单元格、独立输出、复制和折叠；减少工具栏重复 | 有竞品实际截图对照，改善日常 AI 实验结果阅读 |
| P1 | MDC 元数据卡 + Markdown 正文 | 当前已支持后缀但没有语义展示；范围相对清楚 |
| P2 | 文件夹内有界正文搜索，显示匹配片段 | 竞品控件现场可见；OrangeLen 源码确认目前按文件名过滤，竞品查询结果仍待补测 |
| P2 | AI 图片参数的可发现入口与共存诊断 | 本轮共同遇到系统预览优先；应把解析能力与实际到达路径同时说明 |
| 待补测后决定 | ONNX 交互图、更多模型格式 | Netron 本机入口未通过，尚无实际图形体验对比证据 |

技能包、MCPB、工作流、Parquet/Arrow 的优先事项是兼容性和真实样例打磨，当前没有来自本轮免费竞品实测的证据，要求我们立即重做这些已有视图。

## 一手来源

本轮实际结果以上述本地截图为依据。以下链接用于下载来源和官方声明，不替代实测：

- [spacebar 官方发布](https://github.com/patebry/spacebar/releases/tag/v0.5.0)
- [Glance 官方发布](https://github.com/chamburr/glance/releases/tag/v1.6.0)
- [Quicklook-Netron 官方发布](https://github.com/Oil3/Quicklook-Netron/releases/tag/quicklook-netron-1.0)
- [OmniPreview 官方发布](https://github.com/Invernomut0/QuickLookWithSteroids/releases/tag/v0.3.6)及[格式/免费付费清单](https://github.com/Invernomut0/QuickLookWithSteroids/blob/main/SUPPORTED_FORMATS.md)

OmniPreview 在线清单与下载包的版本、付费边界并不完全一致。本轮免费状态实见的 Pro 文案优先于泛化的“免费源码预览”描述。
