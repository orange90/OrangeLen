# AI 开发者与软件工程师文件格式缺口研究

研究日期：2026-10-15。基线：本地 `9b01efc` 加当前未提交工作区，包括 XMind、FreeMind、OPML、MindManager。此次只做代码审计与官方资料研究，没有新增解析器、安装应用或逐格式 Finder 实测。

## 结论与判断口径

OrangeLen 当前明确清单为 **110 个去重后缀、36 个特殊文件名、7 个文件名前缀**。不能把上一轮已做完的 Parquet、NPY/NPZ、Safetensors、GGUF、独立 Mermaid、Draw.io、Canvas、工作流、MDX、TeX、Typst 再列为完全未支持。

本轮最值得补的方向是：

1. **低成本入口补齐**：Python 类型/扩展源码、CUDA、C/C++ 别名、构建脚本、Cursor `.mdc`、HTTP 请求文本和开发文档。
2. **AI 数据与模型**：Arrow/Feather、ONNX、训练事件；随后 DuckDB、HDF5/Keras、TFRecord。PyTorch checkpoint 使用频繁的判断来自生态用途，并非用户占比调查；实现复杂，单独立项。
3. **工程产物可读化**：JUnit、SARIF、覆盖率、性能 trace、软件包清单。它们往往已有 JSON/XML 原文入口，缺的是直接回答“哪里失败、哪里慢、包里有什么”。

“常见”表示进入主流工具的正式工作流，不表示所有开发者都会遇到。下列优先级是按目标人群、快速预览价值、现有组件复用与成本作出的产品判断，没有下载量、市场份额或用户文件遥测支撑。

状态定义：**A**＝没有专用二进制/容器解析入口；**B**＝缺明确文本识别，可能经 macOS UTType 回退显示原文，不能断言所有机器都打不开；**C**＝已有通用文本/结构入口，缺语义视图；**D**＝已有能力，但入口/规模/兼容范围不足。成本只表示相对工程复杂度，不是工期承诺。

## 本地证据

| 文件 | 本次核验结果 |
| --- | --- |
| `Packages/OrangeLen/Sources/OrangeLenCore/ReadableFormat.swift` | 46 个明确代码后缀；文本名单及特殊文件名之外，依赖 `UTType(...).conforms(to: .text)`；并非任意未知文件都自动嗅探文本 |
| `Packages/OrangeLen/Sources/OrangeLenCore/PreviewCategory.swift` | 当前类别路由中无 Arrow、ONNX、DuckDB、训练事件等专门入口 |
| `Packages/OrangeLen/Sources/OrangeLenUI/ReaderAdvanced.swift` | 科学数据分派、Parquet、组件/排版及图形入口明确；Parquet 输入限 25 MiB，显示前 500 行 |
| `Packages/OrangeLen/Sources/OrangeLenCore/ScientificDocument.swift` | 专门接受 C2PA、NPY、Safetensors、GGUF、latent；latent 仅 Safetensors 型 |
| `Packages/OrangeLen/Sources/OrangeLenCore/ArchiveDocument.swift` | ZIP/TAR/gzip 家族；明确拒绝 ZIP64，容器整体有 64 MiB 上限；不能把任意 ZIP 衍生格式都视为已支持 |
| `Packages/OrangeLen/Sources/OrangeLenUI/CollectionController.swift` | OpenAPI 专门入口依赖 `openapi.json` / `swagger.json`；YAML 及任意命名 JSON 不自动等同 API 文档视图 |
| `scripts/advanced-renderers/package.json` | 已含 `apache-arrow` 19.0.0 与 `parquet-wasm` 0.7.1；Arrow 复用有基础，但不证明压缩 IPC 与 Feather V1 已可读取 |
| `docs/format-count.md`、`docs/advanced-output-previews.md` | 当前明确格式及能力边界；格式清单不是逐项 Finder 验收清单 |

## 第一组：源码、规则、配置与文档

这些是覆盖面补齐，通常先做文本、行号、搜索、复制和语言映射；排版与结构能力另算。

| 候选 | 场景与缺口 | 状态 | 建议 / 成本 |
| --- | --- | --- | --- |
| `.pyi`、`.pyx`、`.pxd`、`.pxi` | Python 类型桩、Cython 源码/声明；现有 `.py` 不覆盖它们 | B | 第一批 / 低；分别映射 Python/Cython，不能只加后缀就声称完整语法支持 |
| `.cu`、`.cuh` | CUDA kernel 和头文件，AI 算子开发直接相关 | B | 第一批 / 低；源码预览即可，不需要 GPU 或 nvcc |
| `.cc`、`.cxx`、`.hh`、`.hxx`、`.ipp`、`.tpp`、`.inl` | C/C++ 工程常见变体，当前仅明确 c/h/cpp/hpp | B | 第一批 / 低；注意模板实现文件和同名扩展歧义 |
| `.m`、`.metal` | Objective-C、Metal shader；`.m` 同时可能为 MATLAB/Octave | B | 第二批 / 低；`.mm` 已有 FreeMind/Objective-C++ 路径，不重复计缺失 |
| `.kts`、`.gradle`、`.groovy`、`.cmake`、`.mk` | Kotlin/Gradle/CMake 构建脚本；已有 Kotlin 和 Makefile 不覆盖全部变体 | B | 第一批 / 低；保持只读，不运行构建系统 |
| `.bzl`、`BUILD`、`BUILD.bazel`、`WORKSPACE`、`WORKSPACE.bazel` | Bazel/Starlark 工程 | B | 第二批 / 低；`MODULE.bazel` 也须考虑，完整文件名比泛用后缀更准确 |
| `.mdc`、`.cursorrules` | Cursor 项目规则及旧式规则文件 | B | 第一批 / 低；front matter 与 Markdown 分开展示，规则内容只作数据 |
| `.http`、`.rest` | API 调试请求文件，含 method、URL、headers、body | B | 第一批 / 低至中；请求列表与源码，不发请求 |
| `.j2`、`.jinja`、`.jinja2`、`.tmpl`、`.tpl` | 提示词模板、部署模板、代码生成模板 | B | 第一批源码 / 低；不执行模板，不默认解析 include |
| `.rst`、`.adoc`、`.asciidoc` | Python/Sphinx 文档、技术手册 | B | 第一批源码，第二批排版 / 低→中；Sphinx 指令和 AsciiDoc include 不宜直接执行 |
| `.rmd`、`.qmd`、`.bib` | R/Quarto 分析文档、文献库 | B | 第二批 / 低→中；只能先看源码，不能执行分析代码 |
| `.fish`、`.psm1`、`.psd1`、`.bat`、`.cmd` | shell 与跨平台自动化脚本 | B | 第二批 / 低；现有 sh/ps1 不是完整覆盖 |
| `.jl`、`.ex`、`.exs`、`.erl`、`.hrl`、`.hs`、`.clj`、`.cljs`、`.cljc`、`.edn`、`.zig`、`.nix` | Julia、Elixir/Erlang、Haskell、Clojure、Zig、Nix 等人群 | B | 按用户需求补齐 / 低；不能据后缀多少宣称语言生态覆盖率 |
| `.ruff.toml`、`.coveragerc`、`.flake8`、`.gitconfig`、`.gitmessage`、`.npmignore`、`.tool-versions`、`.yarnrc.yml` | 开发工具配置 | B/C | 第一批精确文件名审计 / 低；`.ruff.toml` 和 `.yarnrc.yml` 已因 toml/yml 可读，不应再计新格式；其余未在明确文件名名单中 |
| `.code-workspace`、`.code-snippets` | VS Code 工作区与代码片段 | B | 第二批 / 低；需 JSONC 路由，不能按普通 JSON 拒绝注释 |

核实依据：[CUDA 输入文件类型](https://docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/index.html)、[Cursor Rules](https://cursor.com/docs/rules)、[REST Client](https://github.com/Huachao/vscode-restclient)、[Sphinx reStructuredText](https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html)、[AsciiDoc](https://docs.asciidoctor.org/asciidoc/latest/)、[Ruff 配置](https://docs.astral.sh/ruff/configuration/)。源码别名清单来自本地白名单差集与语言文件惯例；未对每一种后缀做系统分派实测。

**不要误报**：`AGENTS.md`、`CLAUDE.md`、`SKILL.md` 已走 Markdown；`mcp.json`、`package.json`、`tokenizer.json` 已走 JSON；`pyproject.toml` 已走 TOML；GitHub Actions、Compose、Kubernetes、Helm values 等 YAML 已有原文。Triton kernel 常写在 `.py`，无需发明独立 Triton 后缀。

## 第二组：AI 数据、模型与实验产物

| 格式族 | 为什么值得关注 | 当前缺口 | 推荐最小预览 | 顺序 / 成本 |
| --- | --- | --- | --- | --- |
| Arrow IPC `.arrow` / `.ipc`、Feather `.feather` | Hugging Face Datasets 本地缓存、Python/R 表格交换 | A；Parquet 已有不代表 Arrow 文件已接入 | schema、record batches、类型、前若干行；file/stream 分开处理 | 第一批 / 中 |
| ONNX `.onnx` | 模型导出与跨运行时交付 | A | producer/opset、输入输出 shape/dtype、节点/算子摘要；大图按需展开 | 第一批 / 中至高 |
| TensorBoard `events.out.tfevents.*` | 查看训练 loss、学习率、指标是否收敛 | A；不是简单 `.tfevents` 后缀匹配 | tags、step、时间范围、标量曲线；区分单文件和完整 run | 第二批靠前 / 中至高 |
| DuckDB `.duckdb`，也可能命名 `.db` | 本地分析数据库、数据科学交付 | A；`.db` 目前直接进入 SQLite，不代表兼容 DuckDB | 表/列/类型、只读分页样本；行数避免默认全表精确扫描 | 第二批 / 中至高 |
| HDF5 `.h5` / `.hdf5` | 科学数组、模型权重、大型层级数据 | A | group/dataset 树、shape/dtype、属性和有限样本 | 第二批 / 高 |
| Keras `.keras` | 模型配置、元数据及权重交付 | A；ZIP 容器没明确接入该扩展 | config/metadata 概览先行，H5 权重层级后续 | 第二批 / 中；完整权重依赖 HDF5 |
| PyTorch `.pt` / `.pth`，部分 `.ckpt` / `.bin` | 训练 checkpoint、state_dict、历史模型权重 | A；后缀不足以确定真实格式 | 先识别版本/容器/成员；张量目录需要受限的静态解码方案 | 第二批专项 / 高 |
| Pickle `.pkl` / `.pickle`、Joblib `.joblib` | sklearn 模型、Python 缓存和数据产物 | A | 类型识别、大小、受限静态结构；明确无法完整重建对象 | 后置 / 高；不调用 pickle.load/joblib.load |
| TFRecord `.tfrecord` / `.tfrecords` | TensorFlow 数据输入管线 | A | 记录边界/CRC、有限样本；确认 Example schema 后展示 feature | 第二批 / 中；任意 bytes 不保证能解释成 Example |
| TensorFlow SavedModel 目录、`.pb` / `.pbtxt` | 服务端模型交付及图定义 | A/B；普通目录浏览不等于模型概览 | signature、输入输出、资源文件说明 | 后置 / 高；`.pb` 是通用 Protobuf，不应统一当 TF 模型 |
| TFLite `.tflite` | 端侧模型交付 | A | 子图、输入输出、量化参数、算子统计 | 第二批 / 中至高 |
| SentencePiece `tokenizer.model` / `*.model` | 大模型 tokenizer 配套 | A；JSON tokenizer 已能读 | 模型类型、词表大小、特殊 token、有限词表 | 后置 / 中；仅内容确认后识别，不能抢占所有 `.model` |
| Faiss `.faiss` / `.index` 等 | RAG 向量索引交付 | A；没有统一强制后缀 | index 类型、维数、向量数量；需版本识别 | 后置 / 高；不要直接对未知输入调用完整加载器 |

关键实现区别：

- **Arrow**：当前依赖可复用是工程推断。Feather V2 使用 IPC file，V1 不同；LZ4/ZSTD 压缩也需验证现有 JS/WASM 的实际能力。IPC stream 没有文件 footer，不能把读尾部当通用方案。[Arrow IPC](https://arrow.apache.org/docs/python/ipc.html)、[Feather](https://arrow.apache.org/docs/python/feather.html)、[HF 缓存](https://huggingface.co/docs/datasets/about_arrow)。
- **ONNX**：Protobuf 消息里可能直接内嵌大量权重，不能照搬 Safetensors“固定头部”策略；需跳过大型 payload。外部数据默认仅展示引用，读取关联文件必须遵循已有目录权限。[ONNX 外部数据](https://onnx.ai/onnx/repo-docs/ExternalData)。
- **PyTorch**：官方说明现代 torch.save 默认采用 ZIP64 容器并含 data.pkl，旧式序列化仍可能出现。当前归档限制与之冲突；`.pth` 还是 Python 路径配置的常见文件名后缀。不能一律改名 ZIP，也不能为预览调用完整 torch.load。[PyTorch serialization](https://docs.pytorch.org/docs/2.14/notes/serialization.html)、[Python pickle](https://docs.python.org/3/library/pickle.html)。
- **训练事件**：日志可能还在追加，单个文件不是完整训练历史；先按已完整写入的记录显示，再明确截断/缺失，不把坏尾部变成整文件失败。[TensorBoard event files](https://github.com/tensorflow/tensorboard/blob/master/README.md)。
- **HDF5/Keras**：Keras 的配置摘要比完整 HDF5 数据支持更容易交付，可拆开实现；不实例化自定义 layer。[HDF5 基础结构](https://docs.h5py.org/en/stable/quick.html)、[Keras 保存格式](https://keras.io/guides/serialization_and_saving/)。
- **DuckDB**：需要独立数据库引擎和只读访问；不能复用 SQLite 解码器。禁用自动扩展安装、外部访问并限定内部查询是建议设计，不是当前功能。[DuckDB Python API](https://duckdb.org/docs/current/clients/python/overview)。
- **TFRecord / TFLite / tokenizer / index**：分别依据 [TFRecord](https://www.tensorflow.org/tutorials/load_data/tfrecord)、[LiteRT](https://developers.google.com/edge/litert/conversion/tensorflow/convert_tf)、[SentencePiece](https://github.com/google/sentencepiece)、[Faiss IO](https://github.com/facebookresearch/faiss/wiki/Index-IO,-cloning-and-hyper-parameter-tuning)。Faiss 官方特别说明读取时不校验所有输入正确性，快速预览不能直接把未知文件交给完整反序列化路径。

## 第三组：测试、排障、架构与接口

| 格式 / 产物 | 当前状态 | 用户真正需要看到什么 | 建议 / 成本 |
| --- | --- | --- | --- |
| JUnit XML `junit.xml`、`TEST-*.xml` | C：XML 原文已能读，缺测试报告 | 总数、通过/失败/跳过、失败堆栈、慢测试 | 第一批 / 中 |
| SARIF `.sarif` / `.sarif.json` | B/C：sarif 无专门入口，json 有通用树 | 规则、严重级别、文件/行号、消息、结果筛选 | 第一批 / 中 |
| LCOV `.lcov` / `lcov.info`；Cobertura `coverage.xml` | B/C：info/lcov 未明确；XML 可读 | 文件覆盖率、未覆盖行、分支覆盖率 | 第二批 / 中；没有关联源码时只展示行号 |
| Chrome trace `*.json`、V8 `.cpuprofile` / `.heapprofile` | C/B：JSON 原文不等于性能分析 | 时间轴、最耗时事件/函数、调用层级 | 第二批 / 中至高；不同 schema 不混用 |
| Perfetto `.perfetto-trace` / `.pftrace`、pprof profile | A | 线程/事件/采样摘要；后续火焰图 | 后置 / 高；不把所有 `.trace` / `.pb.gz` 当同一种格式 |
| Graphviz `.dot` / `.gv` | B，无 DOT 图形引擎 | 图形、节点/边、源码 | 第一批 / 中；`.dot` 也可为 Word 模板，必须鉴别内容 |
| PlantUML `.puml` / `.plantuml` / `.pu` | B，无 UML 渲染 | 时序图、类图、源码 | 第二批 / 中至高；评估离线引擎体积及 include 行为 |
| OpenAPI YAML、任意命名 OpenAPI JSON | C：特定 JSON 文件名有专用摘要，其余通用原文 | 路径、方法、参数、响应及 schema 导航 | 第一批 / 中；是现有功能扩展，不是整个 OpenAPI 未支持 |
| Postman collection/environment JSON | C | 请求目录、method/URL、变量和 body | 第二批 / 中；展示内容不发请求 |
| Protobuf `.pb` / `.bin`、TextFormat `.pbtxt` / `.textproto` | A/B；`.proto` 源码已有 | 有 descriptor 时字段名称/类型，缺 schema 时仅 wire 字段 | 后置；先补文本 / 低，二进制 / 中至高 |
| WebAssembly `.wasm` / `.wat` | A/B | imports/exports、section、内存声明、WAT 源码 | 第二批 / 中；不实例化/执行模块 |
| SBOM 的 CycloneDX/SPDX JSON/XML | C | 组件、版本、许可证与依赖关系 | 后置 / 中；不能仅凭清单声称漏洞或许可证审核已完成 |

依据：[GitLab JUnit](https://docs.gitlab.com/ci/testing/unit_test_reports/)、[GitHub SARIF](https://docs.github.com/en/enterprise-cloud%40latest/code-security/reference/code-scanning/sarif-files/sarif-support)、[LLVM coverage](https://github.com/llvm/llvm-project/blob/main/llvm/docs/CommandGuide/llvm-cov.rst)、[Perfetto 格式](https://perfetto.dev/docs/getting-started/other-formats)、[DOT](https://graphviz.org/doc/info/lang.html)、[PlantUML](https://plantuml.com/starting)、[Protobuf 编码](https://protobuf.dev/programming-guides/encoding/)、[WebAssembly 二进制](https://webassembly.github.io/spec/core/binary/index.html)。Postman/SBOM 在本轮仅列产品候选，未深入核验各版本 schema，排期前需补正式规范与样本。

## 第四组：软件包与压缩变体

| 候选 | 缺口与建议 | 优先级 |
| --- | --- | --- |
| `.whl` | A；ZIP 型 Python wheel：目录、METADATA、WHEEL、依赖与平台标签。源码可以读，原生扩展不执行 | 第一批，低至中 |
| `.vsix` | A；扩展分发包：manifest、名称、版本、入口和目录。需检验 ZIP 成员结构而非仅后缀 | 第一批，低至中 |
| `.jar` / `.war` / `.ear` | A；ZIP 家族 Java 包：manifest、资源、依赖；反编译 class 是独立需求 | 第二批，低至中 |
| `.nupkg`、`.crx`、`.apk` | A；包清单预览候选。CRX 有额外头，APK manifest 可能是二进制 XML，不可笼统按 ZIP 文本包支持 | 后置，需分别研究 |
| `.zst`、`.xz`、`.bz2`、`.lz4` 与 `.tar.*` | A；只支持 gzip 不覆盖这些压缩流。先单流日志/表格，再 TAR 目录，压缩与内层格式分两层识别 | 第二批，中；优先 zst/xz |
| `.7z`、`.rar` | A；跨团队文件交换有需求，当前明确未实现 | 第二批至后置，中至高；独立库、许可、加密和多卷边界 |
| ZIP64、超 64 MiB 包 | D；即便后缀 zip 已支持，真实大型包仍会触及限制 | 应作为容器底座专项，与模型/大型包一起设计 |

依据：[Wheel](https://packaging.python.org/en/latest/specifications/binary-distribution-format/)、[VSIX 发布](https://code.visualstudio.com/api/working-with-extensions/publishing-extension)、[JAR 规范](https://docs.oracle.com/en/java/javase/25/docs/specs/jar/jar.html)、[Zstandard](https://facebook.github.io/zstd/)、[XZ](https://tukaani.org/xz/format.html)。其余包格式是后续候选，不把本轮未深入研究的细节当验收承诺。

## 现有支持仍应补强的部分

- **Finder 单文件入口**：历史 `.ts` / `.mts` 被系统视频处理器接管、Dockerfile/.env 变体的 UTType 分派问题，不能因共享 Reader 能读就标成全部完成。本轮不重复现场测试，历史证据只代表当时设备。
- **真实 AI 数据规模**：Parquet 25 MiB/前 500 行，JSON 超大文件降级源码，普通 gzip 展开预算，均可能比缺一个小众后缀更影响日常使用。建议先实现有界分块/抽样，不一味提高整文件加载上限。
- **文件夹语义**：模型分片目录、SavedModel、训练 run、WebDataset TAR 等需要“这组文件构成什么”的概览；支持目录树或 TAR 不能等同支持整个数据集协议。
- **Notebook**：当前不执行 kernel，复杂 HTML/widget 输出不完整。补已有输出的兼容性，比增加一个 Notebook 别名更有价值。
- **HTML/React、图形与 3D**：单文件组件快照、简化 SVG/Draw.io、静态 GLTF 网格都有既定边界；多依赖项目与完整材质动画应单独立项。

## 推荐实施顺序

**第一批：直接提高日常命中率。** 补 `.pyi/.pyx/.pxd/.pxi`、`.cu/.cuh`、C/C++ 别名、构建脚本、`.mdc`、HTTP/模板/文档源码；同时做 Arrow IPC/Feather V2、wheel/VSIX 清单、JUnit/SARIF、OpenAPI YAML。可视化方向首选 DOT；模型方向首选 ONNX 元数据。这一批不是要求一次全做，而是供选择的首要池。

**第二批：加强 AI 与排障特色。** TensorBoard 标量曲线、DuckDB、Keras/HDF5、TFRecord、TFLite、覆盖率与 Chrome trace；扩展 zst/xz；PlantUML 按引擎方案成本确定顺序。

**单独专项：PyTorch/checkpoint 与大型容器。** 先解决随机访问、ZIP64 与静态元数据读取，再决定支持哪些版本；不要为了“支持 pt”引入完整 Python/PyTorch 运行环境。

**暂不优先**：Faiss 完整索引、任意 pickle 对象、TensorRT engine、通用二进制反编译、全量 profiler、全套科学格式。它们有专业用户价值，但一次性兼容成本高。Core ML、Avro/ORC、Zarr、MAT/NetCDF、PCAP、证书、字体也可进入后续候选池；本轮没有足够场景证据把它们排在上述主线之前。

## 验收建议

每个新增格式都独立记录四个入口：宿主打开、Finder 文件夹内、Finder 单文件 Space、归档成员。文本“能读”、语言“有高亮”、内容“有结构”、视觉“能渲染”分别记录，不合并成一个支持勾。

优先夹具包括：IPC file/stream/压缩 Feather/V1、ONNX 内嵌/外部权重、ZIP64 checkpoint/旧 pickle/文本 `.pth`、追加中的事件文件、JUnit 方言、SARIF 非 ASCII 路径、Word `.dot` 与 Graphviz `.dot`、损坏和超预算软件包。对未知版本明确降级；没有现场证据就标“待验收”。

本轮结论来自源码和官方文档，未生成这些候选的功能实现或验收结果；也未改变现有 110 后缀支持统计。
