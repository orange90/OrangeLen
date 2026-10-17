# Format inventory / 格式统计口径

2026-10-16 · [中文 README](../README.md) · [English README](../README.en.md)

## Count / 总数

**363 unique extensions + 49 exact filenames + 7 filename prefixes + folder browsing.**

后缀按小写去重；别名分别计数。同一后缀只计一次，不将 ComfyUI/n8n/OpenAPI 等内容识别、`.tar.gz` 组合后缀或文件夹重复加数。此计数覆盖明确的源码、结构与效果预览，不表示完整格式兼容或逐一 Finder 实测。

Extensions are lowercased and deduplicated; aliases count separately. Content-based workflow detection, compound `.tar.gz` names and folders add no extra extensions. The count covers explicit source, structure and rendered preview routes, not full specification compliance or per-extension Finder verification.

ImageIO, AVKit and system document integration are excluded from this fixed inventory because their capabilities depend on the host OS and document. PDF and filtered SVG have explicit reader routes and are included. See [system-format scope](system-preview.md).

## Inventory / 清单

| Category / 类别 | Count | Extensions |
| --- | ---: | --- |
| 代码与网页 / Code & web | 75 | `.swift`, `.py`, `.js`, `.ts`, `.tsx`, `.jsx`, `.mjs`, `.cjs`, `.mts`, `.cts`, `.vue`, `.svelte`, `.astro`, `.c`, `.h`, `.cpp`, `.hpp`, `.rs`, `.go`, `.sh`, `.zsh`, `.bash`, `.rb`, `.java`, `.kt`, `.css`, `.scss`, `.sass`, `.less`, `.html`, `.htm`, `.xhtml`, `.sql`, `.cs`, `.php`, `.dart`, `.lua`, `.r`, `.scala`, `.ps1`, `.proto`, `.graphql`, `.gql`, `.tf`, `.tfvars`, `.hcl`, `.pyi`, `.pyx`, `.pxd`, `.pxi`, `.cu`, `.cuh`, `.cc`, `.cxx`, `.hh`, `.hxx`, `.ipp`, `.tpp`, `.inl`, `.kts`, `.gradle`, `.groovy`, `.cmake`, `.mk`, `.mdc`, `.http`, `.rest`, `.j2`, `.jinja`, `.jinja2`, `.tmpl`, `.tpl`, `.rst`, `.adoc`, `.asciidoc` |
| 文本与配置 / Text & configuration | 11 | `.txt`, `.log`, `.ini`, `.conf`, `.config`, `.properties`, `.plist`, `.yaml`, `.yml`, `.toml`, `.xml` |
| 文档与排版 / Documents & typesetting | 8 | `.md`, `.markdown`, `.mdx`, `.tex`, `.typ`, `.ipynb`, `.epub`, `.pdf` |
| 结构化数据 / Structured data | 12 | `.json`, `.jsonc`, `.json5`, `.jsonl`, `.ndjson`, `.csv`, `.tsv`, `.sqlite`, `.sqlite3`, `.db`, `.har`, `.sarif` |
| 图表与画布 / Diagrams & canvases | 12 | `.mmd`, `.mermaid`, `.excalidraw`, `.drawio`, `.canvas`, `.svg`, `.xmind`, `.mm`, `.opml`, `.mmap`, `.dot`, `.gv` |
| Skill、MCP 与归档 / Skills, MCP & archives | 10 | `.skill`, `.mcpb`, `.dxt`, `.n8np`, `.zip`, `.tar`, `.tgz`, `.gz`, `.whl`, `.vsix` |
| 3D 模型 / 3D models | 4 | `.obj`, `.stl`, `.gltf`, `.glb` |
| 科学数据与模型目录 / Scientific data & model catalogs | 10 | `.parquet`, `.npy`, `.npz`, `.safetensors`, `.gguf`, `.latent`, `.arrow`, `.ipc`, `.feather`, `.onnx` |
| 字幕、差异与来源结构 / Subtitles, diffs & provenance | 6 | `.srt`, `.vtt`, `.diff`, `.patch`, `.xmp`, `.c2pa` |
| 新增开发者源码、配置与编译文件 / Additional developer sources, configs & compiled files | 215 | `.a3x`, `.acf`, `.ada`, `.ado`, `.applescript`, `.as`, `.ascr`, `.asd`, `.asm`, `.asp`, `.aspx`, `.atl`, `.au3`, `.avt`, `.awk`, `.bas`, `.bashrc`, `.basic`, `.bat`, `.bb`, `.bezel`, `.bib`, `.c++`, `.cfc`, `.cfg`, `.cfm`, `.cfml`, `.class`, `.cli`, `.clj`, `.cljc`, `.cljs`, `.cls`, `.cmd`, `.code-workspace`, `.coffee`, `.command`, `.con`, `.cp`, `.cr`, `.csh`, `.cson`, `.csproj`, `.ctx`, `.d`, `.designspace`, `.do`, `.dockerfile`, `.dtd`, `.dylan`, `.e`, `.ecf`, `.ecore`, `.edn`, `.el`, `.entitlements`, `.env`, `.erb`, `.erl`, `.ex`, `.exs`, `.f`, `.f90`, `.f95`, `.fea`, `.fish`, `.flow`, `.fnc`, `.for`, `.fs`, `.fsx`, `.fxml`, `.gd`, `.gemfile`, `.gleam`, `.gpx`, `.haml`, `.heex`, `.hri`, `.hrl`, `.hs`, `.ily`, `.iml`, `.inf`, `.ino`, `.iss`, `.jav`, `.javascript`, `.jl`, `.jnlp`, `.jscript`, `.jsm`, `.jsp`, `.kml`, `.kmt`, `.ksh`, `.latex`, `.lay`, `.ld`, `.lhs`, `.lisp`, `.loctable`, `.lsp`, `.ltx`, `.ly`, `.m`, `.mak`, `.map`, `.mf`, `.mill`, `.ml`, `.mll`, `.mly`, `.mobileconfig`, `.mpd`, `.mq4`, `.mq5`, `.ms`, `.mvw`, `.mxml`, `.ncx`, `.nf`, `.nim`, `.nix`, `.opf`, `.otio`, `.pas`, `.pck`, `.pddl`, `.pde`, `.ph3`, `.ph4`, `.php3`, `.php4`, `.phtml`, `.pkb`, `.pks`, `.pl`, `.pm`, `.podspec`, `.pom`, `.prc`, `.pro`, `.psd1`, `.psjs`, `.psm1`, `.pub`, `.py3`, `.raml`, `.rbw`, `.rdf`, `.readme`, `.rex`, `.rexx`, `.rhtml`, `.rjs`, `.rkt`, `.robot`, `.s79`, `.sage`, `.sas`, `.sbt`, `.sc`, `.scad`, `.sch`, `.scl`, `.scm`, `.scpt`, `.sequ`, `.sld`, `.sls`, `.smali`, `.sol`, `.sps`, `.sqs`, `.ss`, `.storybard`, `.storyboard`, `.strings`, `.stringsdict`, `.sty`, `.t`, `.tab`, `.tcl`, `.tcsh`, `.texi`, `.text`, `.tfstate`, `.tpb`, `.tps`, `.trg`, `.ttx`, `.twig`, `.unity`, `.v`, `.vb`, `.vbs`, `.vhd`, `.vhdl`, `.vim`, `.vl`, `.vw`, `.wflow`, `.xaml`, `.xcscheme`, `.xib`, `.xm`, `.xq`, `.xquery`, `.xsd`, `.xu`, `.xul`, `.zig`, `.zon`, `.zshrc` |
| Total / 合计 | **363** | |

## Named files / 特殊文件名

`makefile`, `gnumakefile`, `dockerfile`, `containerfile`, `gemfile`, `rakefile`, `justfile`, `license`, `readme`, `.gitignore`, `.gitattributes`, `.gitmodules`, `.env`, `.dockerignore`, `.editorconfig`, `.npmrc`, `.yarnrc`, `.prettierrc`, `.eslintrc`, `.babelrc`, `.nvmrc`, `.python-version`, `.ruby-version`, `cargo.lock`, `yarn.lock`, `poetry.lock`, `uv.lock`, `pipfile`, `pipfile.lock`, `gemfile.lock`, `go.mod`, `go.sum`, `cmakelists.txt`, `procfile`, `brewfile`, `jenkinsfile`, `.cursorrules`, `.coveragerc`, `.flake8`, `.gitconfig`, `.gitmessage`, `.npmignore`, `.tool-versions`

Additional shell startup names / 新增 Shell 启动文件：`.bashrc`, `.bash_profile`, `.profile`, `.zshrc`, `.zprofile`, `.zshenv`。

Prefixes / 前缀：`.env.`、`dockerfile.`、`containerfile.`、`makefile.`、`.prettierrc.`、`.eslintrc.`、`.babelrc.`。匹配忽略大小写 / Matching is case-insensitive.

## Source of truth / 代码依据

- [ReadableFormat.swift](../Packages/OrangeLen/Sources/OrangeLenCore/ReadableFormat.swift): code, text, collections and named files.
- [ReaderController.swift](../Packages/OrangeLen/Sources/OrangeLenUI/ReaderController.swift): PDF, diagrams, subtitle, archive and database routing.
- [ReaderAdvanced.swift](../Packages/OrangeLen/Sources/OrangeLenUI/ReaderAdvanced.swift): advanced preview dispatch.
- [MeshDocument.swift](../Packages/OrangeLen/Sources/OrangeLenCore/MeshDocument.swift), [ScientificDocument.swift](../Packages/OrangeLen/Sources/OrangeLenCore/ScientificDocument.swift): 3D and scientific/model formats.
- [Advanced preview scope](advanced-output-previews.md), [developer formats](developer-formats.md), [Finder matrix](format-support.md): capabilities, limits and recorded verification.

Update both README tables and this inventory together when format support changes.

## Syntax Highlight parity / 对齐边界

新增 215 个后缀，固定对照 Syntax Highlight 2.1.32 文档中的 282 个候选后缀，均有明确阅读路径；这不是 282 项 Finder 现场通过声明。`.class` 显示声明与原始字节码，编译 AppleScript 在隔离服务中取回可用源码，二进制 plist 转 XML；编译 AutoIt `.a3x` 仅显示有限十六进制字节。后缀歧义及完整验证见 [本轮支持说明](syntax-highlight-parity.md)。

The 215 added suffixes cover the pinned competitor inventory together with existing readers. Compiled Java is inspected, not reconstructed into original source; compiled AutoIt has a bounded byte view only. Direct Finder dispatch remains host-dependent. The current public preview.2 package predates this development change.

## 新增后缀的 Finder 全量验收

2026-10-16 后续：本轮新增 215 个后缀全部完成真实 Finder 空格测试，213 个默认进入 OrangeLen，`.text` / `.wflow` 由系统接管，OrangeLen 文件夹入口也已验证。见 [逐项结果](evidence/source-parity-finder-2026-10-16/README.md)。未将此结果扩大为全部 363 个后缀通过。
