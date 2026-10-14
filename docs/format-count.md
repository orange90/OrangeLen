# Format inventory / 格式统计口径

2026-10-13 · [中文 README](../README.md) · [English README](../README.en.md)

## Count / 总数

**106 unique extensions + 36 exact filenames + 7 filename prefixes + folder browsing.**

后缀按小写去重；别名分别计数。同一后缀只计一次，不将 ComfyUI/n8n/OpenAPI 等内容识别、`.tar.gz` 组合后缀或文件夹重复加数。此计数覆盖明确的源码、结构与效果预览，不表示完整格式兼容或逐一 Finder 实测。

Extensions are lowercased and deduplicated; aliases count separately. Content-based workflow detection, compound `.tar.gz` names and folders add no extra extensions. The count covers explicit source, structure and rendered preview routes, not full specification compliance or per-extension Finder verification.

ImageIO, AVKit and system document integration are excluded from this fixed inventory because their capabilities depend on the host OS and document. PDF and filtered SVG have explicit reader routes and are included. See [system-format scope](system-preview.md).

## Inventory / 清单

| Category / 类别 | Count | Extensions |
| --- | ---: | --- |
| 代码与网页 / Code & web | 46 | `.swift`, `.py`, `.js`, `.ts`, `.tsx`, `.jsx`, `.mjs`, `.cjs`, `.mts`, `.cts`, `.vue`, `.svelte`, `.astro`, `.c`, `.h`, `.cpp`, `.hpp`, `.rs`, `.go`, `.sh`, `.zsh`, `.bash`, `.rb`, `.java`, `.kt`, `.css`, `.scss`, `.sass`, `.less`, `.html`, `.htm`, `.xhtml`, `.sql`, `.cs`, `.php`, `.dart`, `.lua`, `.r`, `.scala`, `.ps1`, `.proto`, `.graphql`, `.gql`, `.tf`, `.tfvars`, `.hcl` |
| 文本与配置 / Text & configuration | 11 | `.txt`, `.log`, `.ini`, `.conf`, `.config`, `.properties`, `.plist`, `.yaml`, `.yml`, `.toml`, `.xml` |
| 文档与排版 / Documents & typesetting | 8 | `.md`, `.markdown`, `.mdx`, `.tex`, `.typ`, `.ipynb`, `.epub`, `.pdf` |
| 结构化数据 / Structured data | 11 | `.json`, `.jsonc`, `.json5`, `.jsonl`, `.ndjson`, `.csv`, `.tsv`, `.sqlite`, `.sqlite3`, `.db`, `.har` |
| 图表与画布 / Diagrams & canvases | 6 | `.mmd`, `.mermaid`, `.excalidraw`, `.drawio`, `.canvas`, `.svg` |
| Skill、MCP 与归档 / Skills, MCP & archives | 8 | `.skill`, `.mcpb`, `.dxt`, `.n8np`, `.zip`, `.tar`, `.tgz`, `.gz` |
| 3D 模型 / 3D models | 4 | `.obj`, `.stl`, `.gltf`, `.glb` |
| 科学数据与模型目录 / Scientific data & model catalogs | 6 | `.parquet`, `.npy`, `.npz`, `.safetensors`, `.gguf`, `.latent` |
| 字幕、差异与来源结构 / Subtitles, diffs & provenance | 6 | `.srt`, `.vtt`, `.diff`, `.patch`, `.xmp`, `.c2pa` |
| Total / 合计 | **106** | |

## Named files / 特殊文件名

`makefile`, `gnumakefile`, `dockerfile`, `containerfile`, `gemfile`, `rakefile`, `justfile`, `license`, `readme`, `.gitignore`, `.gitattributes`, `.gitmodules`, `.env`, `.dockerignore`, `.editorconfig`, `.npmrc`, `.yarnrc`, `.prettierrc`, `.eslintrc`, `.babelrc`, `.nvmrc`, `.python-version`, `.ruby-version`, `cargo.lock`, `yarn.lock`, `poetry.lock`, `uv.lock`, `pipfile`, `pipfile.lock`, `gemfile.lock`, `go.mod`, `go.sum`, `cmakelists.txt`, `procfile`, `brewfile`, `jenkinsfile`

Prefixes / 前缀：`.env.`、`dockerfile.`、`containerfile.`、`makefile.`、`.prettierrc.`、`.eslintrc.`、`.babelrc.`。匹配忽略大小写 / Matching is case-insensitive.

## Source of truth / 代码依据

- [ReadableFormat.swift](../Packages/OrangeLen/Sources/OrangeLenCore/ReadableFormat.swift): code, text, collections and named files.
- [ReaderController.swift](../Packages/OrangeLen/Sources/OrangeLenUI/ReaderController.swift): PDF, diagrams, subtitle, archive and database routing.
- [ReaderAdvanced.swift](../Packages/OrangeLen/Sources/OrangeLenUI/ReaderAdvanced.swift): advanced preview dispatch.
- [MeshDocument.swift](../Packages/OrangeLen/Sources/OrangeLenCore/MeshDocument.swift), [ScientificDocument.swift](../Packages/OrangeLen/Sources/OrangeLenCore/ScientificDocument.swift): 3D and scientific/model formats.
- [Advanced preview scope](advanced-output-previews.md), [developer formats](developer-formats.md), [Finder matrix](format-support.md): capabilities, limits and recorded verification.

Update both README tables and this inventory together when format support changes.
