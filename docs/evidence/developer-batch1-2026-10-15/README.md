# 开发者格式首批实现与本机验收

2026-10-15。用户要求按调研优先级实现首批格式、安装本机并实际测试 Finder 空格预览。测试为本仓库生成的合成样例，不等于任意真实文件或完整规范兼容。未提交、推送或发布新版本。

## 交付范围

| 类别 | 实现 |
| --- | --- |
| 源码与规则 | 29 个明确后缀：pyi/pyx/pxd/pxi、cu/cuh、cc/cxx/hh/hxx/ipp/tpp/inl、kts/gradle/groovy/cmake/mk、mdc/http/rest、j2/jinja/jinja2/tmpl/tpl、rst/adoc/asciidoc；只读源码，部分语言复用现有高亮。RST/AsciiDoc 不做排版渲染。 |
| 特殊文件名 | 新增 .cursorrules/.coveragerc/.flake8/.gitconfig/.gitmessage/.npmignore/.tool-versions 的明确文本识别；不代表这些无后缀文件均有独立 Finder 分发。 |
| Arrow | .arrow/.ipc 文件及流；Feather V2，未压缩/LZ4/ZSTD；schema、类型、最多前 500 行。输入 25 MiB，展开缓冲 64 MiB；256 字段、32 层嵌套等预算。Feather V1 不支持，会明确提示导出 V2。 |
| Python/VS Code 包 | .whl/.vsix 目录、wheel METADATA/WHEEL、VS Code package.json 元信息、成员按需读取；不安装、不执行。沿用 ZIP 64 MiB、成员 5 MiB 等预算，不支持 ZIP64。元信息读取上限 1 MiB。 |
| 报告与 API | JUnit XML 的用例状态/耗时/错误堆栈；SARIF 2.x 结果/级别/规则/第一物理位置；OpenAPI JSON/YAML 的方法/路径/摘要/响应代码。保留原文。报告 1 MiB、JUnit/SARIF 最多 5000 条，表格初始显示最多 500 行，可筛选已解析数据。外部引用不解析。 |
| ONNX | IR、producer、opset、图节点、输入输出类型/维度、initializer 与 external_data 标签；跳读权重，不推理、不读外部权重文件。16 MiB 实际访问预算、200000 字段、10000 输出行。不展开属性和嵌套子图。 |
| Graphviz | .dot/.gv 离线 Graphviz WASM 图形快照、缩放、原文切换。64 KiB 源码，外部图片和链接不加载。 |

明确清单从 110 后缀/36 特殊文件名变为 **148 后缀/43 特殊文件名**，7 组前缀保持原有口径。JUnit/OpenAPI 为既有 XML/JSON/YAML 的内容识别，不重复计数。

## 构建、测试与安装

- Xcode Debug 构建成功；使用本机已有 Apple Development 身份签名。安装位置 `/Applications/OrangeLen.app` 与 `~/Applications/OrangeLen.app`；deep/strict 签名验证通过，Quick Look 扩展重新注册及缓存刷新。
- 旧安装已保存在仓库 `build/install-backups/OrangeLen-before-developer-batch1-20261015.app.backup`，不改公开发行包。
- 最终分进程覆盖 299 项：287 项运行中 3 项按既有条件跳过、零失败；其余 12 项 ImprovementIntegrationTests 单独运行通过。最终改动又通过 31 项相关测试和最后 3 项 UI 测试。
- 初次整套单进程运行时，大文件 integration 测试触发累计进程 512 MiB 预算而失败；没有降低产品预算。原始失败日志保留在 `tests-initial-full.log`，成功分组日志为 `tests-287.log`、`tests-focused-31.log`，最后 UI 检查为 `tests-final-ui.log`。不能将分组通过描述为初次整套零失败。
- 新测试覆盖压缩 Arrow、原文切换、包摘要、恶意 XML/YAML、取消、损坏 Protobuf，以及 256 MiB 稀疏 ONNX 权重跳读。

## 实际 Finder Space 验收

用 CUA 操作 Finder 选择文件并按空格，观察内容和控件，不用 qlmanage 的缩略图生成代替验收。**42 个正常样例：40 个直接入口通过，2 个受系统分发限制；另有 2 个负例。**逐项见 [finder-results.json](finder-results.json) 和各 `finder-*.txt`；截图是实际 Quick Look 窗口。

- 29 个新增源码后缀逐一通过。首次 C++ 头文件落入系统文本预览，补齐 public.c-plus-plus-header / inline-header 声明后，hh/hxx/ipp/inl 均复测为 OrangeLen。
- dataset.arrow、stream.ipc、compressed.feather（LZ4）、zstd.feather 显示 3 行样本和中文 emoji；model.onnx 显示 batch × 3 输入输出及 Relu 节点。
- junit.xml 显示 3 个用例、1 个失败、1 个跳过。实测发现多行错误堆栈被 TSV 往返拆行，改为直接构建结构化单元格，增加回归断言后复测显示正确 3 行。
- scan.sarif 显示 ORANGE001 / src/reader.py / 42 / 中文消息；api.yaml 显示 GET /models，并实际切换 Source 确认原文。
- wheel 和 VSIX 显示真实包目录及元信息；architecture.gv 显示 Input → ONNX model → Preview 图形。
- **architecture.dot 直接入口未通过**：本机 UTType 为 com.microsoft.word.dot，补充类型声明并刷新缓存后仍显示系统文件卡片。对其所在文件夹按空格，再选 architecture.dot，图形正常，见 [文件夹 DOT 截图](finder-folder-dot.png)。未修改用户 Word 默认关联。
- **.cursorrules 直接入口未通过**：无后缀文件显示系统文件卡片。在文件夹预览勾选 Show hidden & ignored 后选择它，规则原文正常，见 [规则文件截图](finder-folder-cursorrules.png)。其他新增特殊文件名没有逐一进行直接 Finder 验收。
- broken.onnx 明确显示 Invalid format: ONNX varint；legacy.feather 最终复测明确提示不支持 V1、可导出 Feather V2 / Arrow IPC。均未显示上个文件的表格数据。

截图：[Arrow](finder-arrow.png) · [Feather](finder-feather.png) · [ONNX](finder-onnx.png) · [JUnit](finder-junit.png) · [SARIF](finder-sarif.png) · [wheel](finder-wheel.png) · [VSIX](finder-vsix.png) · [Graphviz](finder-gv.png) · [Feather V1 提示](finder-feather-v1.png)。

## 复现

测试文件在 `Tests/Fixtures/developer-batch1`；生成器 `scripts/create-developer-fixtures.py` 使用 pyarrow/onnx，仅用于合成测试数据。渲染器通过 `cd scripts/advanced-renderers && npm ci && node developer.mjs` 重建，运行时离线。依赖与许可证见 `docs/licenses/DeveloperRenderer-dependencies.txt`、Graphviz/Zstandard LICENSE 文件。

与历史 104/106 Finder 测试属于不同样本集合，不合并成全量 148 格式通过率。
