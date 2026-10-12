# AI 产出文件预览缺口调研

日期：2026-10-11。以下保留调研时的源码缺口、入口契约与官方格式依据；建议排序为工程判断，没有用户使用频率统计。

后续用户已选定第一批全部四类，已实现独立 Mermaid、MCPB/DXT、SRT/VTT 及 AI PNG/WebP 参数。当前范围与 Finder 实测结果见 [AI 产出预览](ai-output-previews.md)。2026-10-12 用户进一步要求其余所有格式接入；实现范围见 [扩展预览](advanced-output-previews.md)，下表的缺口保留为调研时状态。

## 已覆盖与判断标准

当前支持 Markdown（含围栏 Mermaid/公式）、HTML 页面、SVG 静态子集、Excalidraw、常见源码、JSON/JSONL、CSV/TSV、Notebook、SQLite、ZIP/TAR/gzip、EPUB、ZIP 型 `.skill`。图片、音视频、PDF 及 Office 有内置或系统交接路径。

缺口分为：未显式接入格式、只有源码/通用结构、已显示内容但效果不完整。UTType 的文本回退可能使部分未知后缀显示原文，不能据此宣称有专用格式支持。Finder 单文件、Finder 目录、宿主与归档成员须分别验收。

## 建议优先级

| 优先级 | 产出 | 当前缺口 | 推荐预览 | 相对投入（推断） |
|---|---|---|---|---|
| 第一批 | Mermaid `.mmd`，兼容常用 `.mermaid` | 仅 Markdown 围栏有图形；无独立入口 | 图形/源码切换，复用现有 Mermaid | 低 |
| 第一批 | MCP `.mcpb`、旧 `.dxt` | 无容器后缀识别或类型声明 | 目录、manifest 概览、入口/配置与代码 | 低至中；实际依赖包可能超现有归档预算 |
| 第一批 | 字幕 `.srt`、`.vtt` | 无专用字幕模型/时间轴 | 时间码、正文、搜索、时长与可选关联媒体 | 低至中 |
| 第一批 | AI PNG/WebP 的生成元数据 | 当前图片显示图像/尺寸，不呈现生成配方 | 图像旁显示已有 prompt、模型、seed、工作流；字段缺失明确展示 | 中 |
| 第二批 | Draw.io `.drawio` / 图形 XML | 无画布；普通 XML 仅源码 | 多页图形、缩放、源码 | 中至高 |
| 第二批 | Obsidian `.canvas` | 无 JSON Canvas 模型/画布 | 节点、连线、Markdown 卡片；文件节点受目录权限约束 | 中 |
| 第二批 | ComfyUI/n8n JSON、Dify YAML | JSON 树/YAML 源码可读，无工作流视图 | 按内容识别 schema，节点图、参数与依赖概览 | 中至高，须按工具适配 |
| 第二批 | React `.jsx`/`.tsx`、MDX `.mdx` | JSX/TSX 有源码，无应用效果；MDX 未显式接入 | 先补 MDX 源码；再支持约定依赖的单文件组件效果 | 高；编译、依赖、运行隔离与 Finder 快照交互限制 |
| 第三批 | LaTeX `.tex`、Typst `.typ` | 无完整文档排版；Markdown 公式不等于 TeX 编译 | 源码、大纲，后续选择性生成 PDF | 中至高；外部字体/包/多文件依赖 |
| 第三批 | Parquet、NumPy `.npy`/`.npz` | 无二进制表格/数组解析 | schema、shape、dtype、样本及分页 | 中至高 |
| 第三批 | AI 3D `.glb`/`.gltf`/`.obj`/`.stl` | 无独立 OrangeLen 3D 渲染；宿主系统交接不保证能看见模型 | 旋转模型、材质、边界尺寸、网格概览 | 高；几何、纹理和关联文件 |
| 专业用户 | `.safetensors`、`.gguf`，ComfyUI `.latent` | 无模型/张量元数据预览 | 仅读头部、张量数量/形状/数据类型和已有元数据 | 中；要改变现有整文件/64 MiB 思路，避免加载权重 |

Office 效果也值得补强：PPTX 当前仅内部 XML 文字，XLSX 仅地址/缓存值；不能等同幻灯片视觉布局、Excel 格式/图表。PDF/PNG/MP4/MP3/DOCX 本身不属于完全未支持格式。

## 同类新容器观察

n8n 官方现有 `.n8np` 可移植包说明，状态为 Preview。应先确认版本、容器结构和真实样本，不能直接按 ZIP 别名接入。Claude 插件的目录/manifest 也不能凭名称假设存在统一 `.plugin` 格式。

## 依据

- [MCPB 规范与 DXT 改名](https://github.com/modelcontextprotocol/mcpb/blob/main/README.md)：ZIP、manifest.json、本地 server；最接近本次 `.skill` 扩展。
- [Mermaid CLI](https://github.com/mermaid-js/mermaid-cli)：官方 `.mmd` 输入示例。
- [OpenAI 转录返回格式](https://developers.openai.com/api/reference/cli/resources/audio/subresources/transcriptions/methods/create)：包含 SRT/VTT；具体模型支持需独立核对。
- [ComfyUI 工作流元数据](https://docs.comfy.org/development/api-development/workflow-metadata)：workflow/prompt、PNG/WebP/视频/latent 等；是否存在取决于保存节点与处理链。
- [Draw.io 文件规范](https://github.com/jgraph/drawio/wiki/File-Format)：XML、多页、压缩页、图片内嵌图形。
- [JSON Canvas](https://jsoncanvas.org/spec/1.0/)：节点、连线、文件、文本、链接和分组。
- [n8n 导出](https://docs.n8n.io/workflows/export-import/)及 [n8n packages](https://docs.n8n.io/build/manage-workflows/n8n-packages/)：JSON 工作流及 Preview 包。
- [Dify 应用管理](https://docs.dify.ai/en/cloud/use-dify/workspace/app-management)：DSL/YAML 应用配置。
- [Claude Artifacts](https://www.anthropic.com/news/artifacts)：代码、图形、网站和交互仪表盘；具体下载能力随产品变化。
- [Typst 排版](https://typst.app/docs/tutorial/writing-in-typst/)及 [导出](https://typst.app/docs/web-app/export-and-preview/)。
- [Parquet](https://parquet.apache.org/docs/file-format/)与 [NumPy 文件格式](https://numpy.org/doc/stable/reference/generated/numpy.lib.format.html)。
- [Tripo 转换](https://docs.tripo3d.ai/export/conversion.html)：GLB 及转换输出。
- [Safetensors 元数据](https://huggingface.co/docs/safetensors/metadata_parsing)、[GGUF 规范](https://github.com/ggml-org/ggml/blob/master/docs/gguf.md)。

推荐先做 Mermaid 独立文件、MCPB/DXT、字幕，再做 AI 图片元数据与工作流语义识别。此排序依据用户可见收益、现有组件复用和工程投入，尚非基于实际市场份额。
