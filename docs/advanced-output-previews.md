# 扩展 AI 产出预览（2026-10-12）

用户已选定上一轮调研中剩余的全部格式。本轮接入下列专用只读预览，并补 JPEG/XMP、授权 sidecar 和 C2PA 结构。格式接入不表示实现该格式的所有编辑、运行和排版能力；具体范围如下。

| 格式 / 内容 | 当前预览 | 具体边界 |
| --- | --- | --- |
| Draw.io `.drawio`，可识别的图形 XML | 多页选择、常见形状/标签/连线、缩放和平移、原始源码；兼容 Base64 + raw DEFLATE + URI 编码页 | 自定义 stencil、图片、复杂样式/连线路由会简化；不是完整 Draw.io 编辑器 |
| JSON Canvas `.canvas` | 文本/链接/文件/分组卡片和边；Markdown 文字样式 | 文件卡片只读取已授权目录内的有界文本，链接仅作标签，不联网 |
| ComfyUI JSON | 编辑器节点/links 及 API prompt 两种结构；输入/seed 等概要和连线 | API 图自动网格排布；编辑器保留节点位置；完整参数保留源码，不执行节点 |
| n8n JSON | 节点位置、名称、参数键及 connections 连线 | 不连接服务、不运行工作流；原始 JSON 包含全部配置 |
| Dify YAML | workflow.graph 节点与边、名称/类型，源码切换 | 有界 YAML；不展开 anchors/aliases，不加载外部资源 |
| JSX / TSX / MDX | 内置 React、Babel、MDX 的离线组件效果快照，源码切换 | 单文件默认导出组件；React import 可用，其他模块依赖/本地文件/网络不可用。快照不能点击；不构建完整 Next/Vite 项目 |
| `.tex` | 基于 LaTeX.js 的标题、段落、列表、基础数学等排版，经 WebKit PDF 后用 PDFKit 阅读；原始源码 | 是 LaTeX 基础子集排版，不是完整 TeX 编译器。外部宏包/文件、参考文献工具链和所有自定义命令不承诺支持；不支持内容回退源码 |
| `.typ` | 内置 Typst WebAssembly 编译为 PDF，PDFKit 阅读；原始源码 | 单文件与内置字体；没有本地文件、Universe 包或网络读取能力；需要外部依赖的文档回退源码 |
| `.parquet` | schema/列类型、总行数/row groups，前 500 行原生表格、筛选/排序/复制 | 离线 Arrow/Parquet WASM；输入最多 25 MiB，footer 预检后累计声明展开最多 64 MiB；不是无限规模分析工具 |
| `.npy` | dtype、shape、C/Fortran 顺序、物理存储序号和值的样本 | 数字、布尔、定长字符串等基本标量；结构化 dtype 仅头部，其他未解码值显示字节；object 数组只看头部，绝不 unpickle。最多 5,000 值 / 1 MiB 显示文字 |
| `.npz` | 多数组 ZIP 目录，默认首个 NPY，成员 shape/dtype/样本 | 归档安全预算；成员当前是结构和样本文本，不执行嵌套容器 |
| OBJ / STL | 原生 SceneKit 网格快照、旋转和缩放 | OBJ 多边形扇形三角化、ASCII/二进制 STL；统一材质，不读 MTL/外部贴图 |
| GLTF / GLB | glTF 2.0 静态三角形场景、节点层级/变换、基础材质色、旋转/缩放 | 支持内嵌或授权目录内 buffer；纹理、动画、skin、morph、Draco/meshopt 等扩展未接入，必要扩展拒绝，不悄悄执行/下载依赖 |
| Safetensors / ComfyUI `.latent` | 元数据、张量名称/dtype/shape/字节长度 | 仅 Safetensors 型 latent；头部与目录有界读取，不加载/解释权重或 pickle 型 latent |
| GGUF | v2/v3 小端头部、模型属性、张量目录和偏移，长 metadata 数组仅展示概要 | 不加载权重；GGML dtype 以类型编号显示，不提供模型推理或权重可视化 |
| n8n `.n8np` | TAR/GZIP（兼容未压缩 TAR）、v1 根清单概览、目录与成员工作流图 | 格式本身仍在 Preview；不导入到 n8n，不执行工具或凭据；版本不符显示错误清单并保留目录 |
| JPEG / WebP XMP、`.xmp`、参数 sidecar | JPEG EXIF、JPEG/WebP XMP 中已有生成参数；独立 XMP 源码；图片旁 JSON/TXT/XMP 已知参数字段 | 不推断不存在的参数。sidecar 仅在已有目录权限内；PNG/JPEG 单文件 Finder 分派仍可能是系统 |
| `.c2pa`、授权 C2PA sidecar | JUMBF box 目录、label、有限 JSON/CBOR assertion 内容；图片旁明确标记未验证 | **不验证签名、证书链、内容绑定或图片真实性**；未知二进制 box 仅显示大小 |

Office（DOCX/PPTX/XLSX 等）延续既有内容预览；完整 PPTX/XLSX 视觉保真和字幕关联播放不属于“增加这些格式”的本轮实现。

## 入口与资源预算

主应用和 Finder 文件夹使用同一实现。新类型分别登记到 Code、Markdown、Data、Archives、Drawings 扩展；Finder 单文件是否选中仍取决于实际 UTType 和其他处理器。归档中的 Draw.io/Canvas/工作流复用节点图；数组/模型成员为合成结构文本；React/MDX/排版成员保持源码，3D/Parquet 成员不启用解析器。

- 图形输入最多 1 MiB、2,000 节点、5,000 边、Draw.io 最多 50 页；节点源范围保留，DTD/entities 拒绝，父层级循环/重复 ID 拒绝。画布快照至 3,000 点边长。文件卡片单项读至 8 KiB、累计 128 KiB，不跟随链接。
- 模型头部读取最多 8 MiB，即使源权重文件为数 GiB；Safetensors JSON 头部最多 4 MiB、20,000 项，验证已知 dtype/shape 与 offset 及覆盖范围。GGUF 最多 20,000 metadata 项/张量、metadata 总访问 100 万项；头部超预算明确失败，不继续加载权重。
- 3D 输入/累计 buffer 25 MiB，至 200,000 顶点/三角形、2,000 节点、64 层；数值、索引、byte stride、仿射变换和世界坐标检查。关闭/切换清空 SceneKit 场景与快照。
- React/MDX/排版效果输入最多 64 KiB；组件快照至 780 × 1,450 点；Typst PDF 最多 25 MiB / 200 页；LaTeX HTML 至 20,000 点高度。WebKit 无持久存储、无本机 message bridge，资源规则阻断网络；组件只在 WebKit JavaScript 环境运行，不启动 shell、包管理器或系统编译器。失败、取消、旧请求不覆盖新文档。
- C2PA 结构最多 8 MiB / 1,000 boxes / 16 层；CBOR 至 32 层 / 20,000 项。图片参数延续 32 字段/累计 1 MiB，上游普通备注不自动标为 AI 参数。

WASM/字体通过每个渲染器私有的白名单资源 handler 读取，Parquet 输入也是该渲染器的独立字节快照，减少 Base64 临时副本；不是任意文件接口。

离线引擎和字体随应用打包，预览时不安装依赖或下载字体。格式接入时的 Debug 基线约 616 MiB；后续已用共享 framework 去掉资源副本，Apple Silicon Release 约 160 MiB、通用版约 268.5 MiB，见 [资源打包](resource-packaging.md)。未做 GPU/内存压力全覆盖。版本、许可证、构建脚本见 [renderer 构建说明](../scripts/advanced-renderers/README.md)，资源 SHA-256 在 [advanced-renderer-sha256.json](advanced-renderer-sha256.json)。

## 验证

合成文件在 [advanced-outputs](../Tests/Fixtures/advanced-outputs/README.md)。自动测试使用真实 WebKit 渲染/PDF、Arrow 解码、SceneKit 快照，覆盖所有列出格式类别；含坏长度/重复 ID/YAML alias 拒绝、4 GiB 稀疏权重只读头部、授权 sidecar 和本地卡片、坏图形源码降级与关闭释放。具体日志与 Finder 现场结果见 [验收记录](evidence/advanced-outputs/README.md)。

## 格式依据

- [Draw.io 官方文件结构/压缩](https://github.com/jgraph/drawio/wiki/File-Format)、[JSON Canvas 1.0](https://jsoncanvas.org/spec/1.0/)。
- [n8n 官方包结构](https://github.com/n8n-io/n8n-docs/blob/main/docs/build/manage-workflows/n8n-packages/package-format.md)：GZIP/TAR 与清单版本、依赖清单。
- [NumPy 官方 NPY/NPZ](https://numpy.org/doc/stable/reference/generated/numpy.lib.format.html)、[Safetensors 官方 schema](https://github.com/huggingface/safetensors/blob/main/docs/safetensors.schema.json)、[GGUF 官方格式](https://github.com/ggml-org/ggml/blob/master/docs/gguf.md)。
- [Parquet 官方 Thrift 结构](https://github.com/apache/parquet-format/blob/master/src/main/thrift/parquet.thrift)、[parquet-wasm 0.7.1 API](https://kylebarron.dev/parquet-wasm/modules/esm_parquet_wasm.html)。
- [Typst.ts](https://github.com/Myriad-Dreamin/typst.ts)、[LaTeX.js](https://github.com/michael-brade/latex.js)、[C2PA 官方内容凭证结构](https://spec.c2pa.org/specifications/specifications/2.3/specs/ContentCredentials.html)。
