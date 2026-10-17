# Syntax Highlight 格式清单对齐

2026-10-16 · 当前本地开发版，公开 preview.2 尚未更新。

按 Syntax Highlight **2.1.32** 官方清单补齐后缀识别、语言映射、宿主类型声明及 Code Quick Look 候选类型。新增 **215** 个明确后缀，固定口径为 **363 个后缀、49 个特殊文件名、7 组前缀规则**。

## 对照范围

竞品 README 去重有 287 个后缀提及。剔除转介 QLMarkdown 的 `.md` / `.rmd` 和竞品注明系统不允许接管的 `.dart` / `.ts` / `.mts` 后，282 个候选后缀均有明确阅读路径。后三者仍保留 OrangeLen 已有源码阅读能力及直接 Finder 接管限制。

这不是 282 项 Finder 现场通过结论，也不表示全部语法、编码、渲染与对方相同。来源为[官方固定版本清单](https://github.com/sbarex/SourceCodeSyntaxHighlight/blob/2.1.32/README.md)，没有复制或嵌入其 GPL 实现。

- [逐后缀覆盖记录](evidence/source-parity-2026-10-16/coverage.json)
- [完整后缀清单](format-count.md)
- [运行时格式与语言映射](../Packages/OrangeLen/Sources/OrangeLenCore/Resources/SourceCodeFormats.json)

## 主要变化

| 类型 | 示例 | 本轮能力 |
| --- | --- | --- |
| 更多源码 | Perl、Julia、Haskell、Clojure、Scheme、Fortran、Ada、Erlang、Elixir、OCaml、Nim、Nix、Pascal、Zig、Gleam、Solidity | 语言规则高亮、行号、查找与复制 |
| 系统与构建 | Objective-C、汇编、AWK、Fish、DOS、Dylan、Eiffel、链接脚本 | 有界源码阅读与词法高亮 |
| 工程与配置 | `.csproj`、`.pom`、`.xib`、`.storyboard`、`.xcscheme`、`.mobileconfig`、`.code-workspace`、`.tfstate` | XML/YAML/JSON/源码阅读；Workspace 支持 JSONC 注释 |
| 科研与硬件 | SAS、Stata、Verilog、VHDL、IDL | 源码高亮 |
| 二进制 plist | `.plist`、`.loctable`、`.wflow`、`.strings`、`.stringsdict`、`.entitlements` | 内存转 XML，限制输入/结构/输出；不执行 workflow |
| Java `.class` | JVM class 文件 | 无外部 JDK，显示类/父类/接口、成员描述符及有限原始字节码；不重建 Java 源码，不启动 JVM |
| 编译 AppleScript | `.scpt`、`.ascr`、`.applescript` | 在有时间/内存上限的 sandbox XPC 服务内用 OSAKit 取回源码；不执行，不恢复 run-only 文件 |
| AutoIt `.a3x` | 文本或编译内容 | 文本高亮；二进制仅显示前 4096 字节和长度，**不反编译源码** |
| Shell 启动文件 | `.bashrc`、`.bash_profile`、`.profile`、`.zshrc`、`.zprofile`、`.zshenv` | 主应用/文件夹识别；Finder 入口取决于 UTI |

沿用离线 highlight.js 11.12.0，并补 18 组小型词法规则/模板别名，覆盖常见关键字、注释、字符串和数字，不等同语义分析或完整语法实现。纯文本类不要求产生彩色 token。

## 同名后缀与边界

- `.typ`：显式 Oracle SQL 声明按 SQL 阅读，其他保留既有 Typst 编译路径。
- `.mm`：保留既有 FreeMind XML 识别和 Objective-C++ 源码阅读。
- `.class`：验证 JVM magic 与有界结构；拒绝截断或尾随垃圾。
- `.as`、`.edn`、`.pub` 也可能对应归档、电子书或 Publisher。本轮支持其源码/文本用途，不强制解码其他二进制用途。
- 保留竞品文档中的 `.storybard` / `.hri`，并补 `.storyboard` / `.hrl`、`.clj`、`.xcscheme`。
- 文本沿用严格 UTF-8 与带 BOM 的 UTF-16；不能宣称任意历史编码均与竞品相同。

Code 扩展加入已核实的具体 UTI 及本产品源码声明，没有注册 `public.data` / `public.item` 来接管所有文件。其他应用提供的 UTI、系统保留类型和扩展选择仍影响 Finder 调用。

## 维护与复现

1. 编辑 `SourceCodeFormats.json` 的语言组和已核实 UTI。
2. 执行 `python3 scripts/sync-source-formats.py`、`xcodegen generate`；用前者的 `--check` 核对同步。
3. `python3 scripts/create-source-parity-fixtures.py` 生成对应语言的合成样例及二进制样例。AppleScript 仅编译，不执行。
4. 运行 SourceParity、SyntaxHighlighter、读取和 JSON 回归；原生 test host 验证 XPC AppleScript。

构建、测试和本机验收结果见[本轮证据](evidence/source-parity-2026-10-16/README.md)。

## 215 项真实 Finder 全量验收（2026-10-16 后续）

新增 215 后缀已逐项实测：默认设置下 213 项进入 OrangeLen；`.text` 与 `.wflow` 由系统接管，两者原生正文及 OrangeLen 文件夹入口均已验证。临时禁用 Shortcuts 提供器可使 `.wflow` 直接显示 OrangeLen XML，诊断后已恢复默认；没有默认停用系统快捷指令预览。完整逐项记录见 [全量实测报告](evidence/source-parity-finder-2026-10-16/README.md)。这不等于全部 363 后缀或所有真实文件均已验证。
