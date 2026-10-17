# OrangeLen

**Press Space. Explore your project and AI-generated files.**

A macOS Quick Look tool for developers. **The reader covers 363 file extensions, 49 special filenames, and whole-folder previews**, spanning source code, Markdown, Skill / MCP packages, AI workflows, datasets and 3D models. All **215 newly added suffixes have been tested through Finder Space: 213 show OrangeLen content, while `.text` / `.wflow` use system providers**; both are also readable inside OrangeLen folder previews. See the [per-suffix audit](docs/evidence/source-parity-finder-2026-10-16/README.md) and the [earlier native-format limitations](docs/evidence/single-file-dispatch-2026-10-13/README.md).

[中文](README.md) · English

[Download](#download) · [Quick start](#quick-start) · [Supported formats](#supported-formats) · [Compared with system Quick Look](#compared-with-system-quick-look) · [Developer guide](docs/development-guide.md) · [Changelog](CHANGELOG.md)

## Product demo (English voiceover and subtitles)

https://github.com/user-attachments/assets/e0b0a87d-d08c-440a-b9d5-6f73a69ddd96

![OrangeLen folder overview with a file tree, project statistics and README preview](docs/evidence/folder-redesign/overview-light.png)

*Actual app screenshot: open a whole folder, then explore its code, documents and data. The interface also supports English.*

## Download

**[Download OrangeLen installer (DMG)](https://github.com/orange90/OrangeLen/releases/download/v0.1.0-preview.2/OrangeLen-0.1.0-preview.2-universal.dmg)** · [Release notes and checksum](https://github.com/orange90/OrangeLen/releases/tag/v0.1.0-preview.2)

Requires **macOS 14 or later**. The universal installer includes Apple Silicon and Intel architectures. Open the DMG, drag `OrangeLen.app` into `Applications`, then launch it.

This **0.1.0-preview.2 preview is Developer ID signed and Apple notarized**. Both the app and DMG have stapled notarization tickets and pass Gatekeeper verification. The signing developer is **Zhe Huang**. Intel hardware and other macOS versions have not been fully verified.

## AI finished writing. Take a look.

One AI session can leave behind a project directory, a research report, a Skill, a workflow and a 3D model. OrangeLen brings inspection into the familiar Space-bar preview: expand a folder, select a file, inspect the result and switch back to source.

| Highlight | What you can do |
| --- | --- |
| **Preview entire folders** | Expand nested directories and read files in one window; inspect README content, project declarations, file counts and sizes |
| **Read code and documents together** | Syntax highlighting, line numbers, search and copy; Markdown outlines, math and Mermaid; expandable JSON |
| **Inspect Skill / MCP packages** | Open `SKILL.md` first in `.skill` packages; browse MCPB / DXT manifests and members without extracting to disk |
| **See AI workflow connections** | Inspect ComfyUI, n8n and Dify node graphs, plus Draw.io, Excalidraw and JSON Canvas |
| **Preview components and 3D models** | Offline single-file JSX / TSX / MDX snapshots; static OBJ / STL / GLTF / GLB scenes with rotation and zoom |
| **Read the context behind generated files** | Existing image prompts, seeds and model parameters; Parquet / NumPy samples; Safetensors / GGUF tensor catalogs |

Native macOS UI with English, Simplified Chinese, light and dark appearances. Specialist rendering engines are bundled. HTML allows scripts and network resources; remote Markdown images load after a click.

<details>
<summary>See the AI image metadata preview</summary>

![AI image and stored generation parameters inside a Finder folder preview](docs/evidence/ai-outputs/finder-image-parameters.png)

*Synthetic fixture demonstrating the metadata panel. Only existing parameters are shown; missing information is not inferred.*

</details>

## Compared with system Quick Look

OrangeLen extends Quick Look for development and AI file inspection. macOS already provides useful PDF, photo and media previews; OrangeLen adds directory browsing and specialized content views.

| Scenario | System Quick Look, without relevant third-party extensions | What OrangeLen adds |
| --- | --- | --- |
| Project folder | Usually basic folder information | Expandable file tree, project overview and in-window reading |
| Code and configuration | Basic previews for recognized text types; behavior varies | Offline highlighting, line numbers, search, exact source copy and named configuration recognition |
| Markdown reports | Depends on OS version and type handler | Outline, GFM tables, math, Mermaid and source switching |
| JSON / CSV / SQLite | Text or built-in views, without a unified structured browser | JSON trees and path copying, table filtering/sorting and SQLite pagination |
| Skills, MCP and workflows | No dedicated manifests or workflow node views for these formats | Package browsing, manifest summaries and ComfyUI / n8n / Dify graphs |
| React components | No JSX / TSX component execution environment | Offline single-file component snapshots and source views |
| AI images and model files | Image or basic file information, depending on type | Saved generation parameters, tensor catalogs and array samples |
| 3D files | Some system 3D types; support depends on format | Explicit static OBJ / STL / GLTF / GLB previews |
| PDFs, photos and media | Mature native previews; markup or trimming for some types | Native viewing integrated into folder browsing; focused on inspection |

Baseline: [Apple’s Quick Look guide](https://support.apple.com/en-sg/guide/mac-help/-mh14119/mac). Behavior varies with macOS, file types and installed extensions; this is not an exhaustive cross-version test. **macOS selects the handler for individual Finder files. OrangeLen’s app and folder previews provide the more complete entry points.**

## Supported formats

**363 distinct file extensions are explicitly listed below.** This counts extensions, not programming languages or fully implemented format specifications. Aliases such as `.md` and `.markdown` count separately; multiple uses of one extension count once.

| Category | Count | Extensions | Preview |
| --- | ---: | --- | --- |
| Code & web | 75 | `.swift`, `.py`, `.js`, `.ts`, `.tsx`, `.jsx`, `.mjs`, `.cjs`, `.mts`, `.cts`, `.vue`, `.svelte`, `.astro`, `.c`, `.h`, `.cpp`, `.hpp`, `.rs`, `.go`, `.sh`, `.zsh`, `.bash`, `.rb`, `.java`, `.kt`, `.css`, `.scss`, `.sass`, `.less`, `.html`, `.htm`, `.xhtml`, `.sql`, `.cs`, `.php`, `.dart`, `.lua`, `.r`, `.scala`, `.ps1`, `.proto`, `.graphql`, `.gql`, `.tf`, `.tfvars`, `.hcl`, `.pyi`, `.pyx`, `.pxd`, `.pxi`, `.cu`, `.cuh`, `.cc`, `.cxx`, `.hh`, `.hxx`, `.ipp`, `.tpp`, `.inl`, `.kts`, `.gradle`, `.groovy`, `.cmake`, `.mk`, `.mdc`, `.http`, `.rest`, `.j2`, `.jinja`, `.jinja2`, `.tmpl`, `.tpl`, `.rst`, `.adoc`, `.asciidoc` | Highlighted source; HTML pages; single-file JSX/TSX snapshots |
| Text & configuration | 11 | `.txt`, `.log`, `.ini`, `.conf`, `.config`, `.properties`, `.plist`, `.yaml`, `.yml`, `.toml`, `.xml` | Source reading and search |
| Documents & typesetting | 8 | `.md`, `.markdown`, `.mdx`, `.tex`, `.typ`, `.ipynb`, `.epub`, `.pdf` | Markdown math and diagrams, saved notebook outputs, books and PDFs; basic LaTeX and single-file Typst |
| Structured data | 12 | `.json`, `.jsonc`, `.json5`, `.jsonl`, `.ndjson`, `.csv`, `.tsv`, `.sqlite`, `.sqlite3`, `.db`, `.har`, `.sarif` | Trees, records, tables or request logs; no user SQL or network requests |
| Diagrams & canvases | 12 | `.mmd`, `.mermaid`, `.excalidraw`, `.drawio`, `.canvas`, `.svg`, `.xmind`, `.mm`, `.opml`, `.mmap`, `.dot`, `.gv` | Visual and source views; supported subsets for complex formats |
| Skills, MCP & archives | 10 | `.skill`, `.mcpb`, `.dxt`, `.n8np`, `.zip`, `.tar`, `.tgz`, `.gz`, `.whl`, `.vsix` | Manifests, file trees and on-demand member previews; no installation or execution |
| 3D models | 4 | `.obj`, `.stl`, `.gltf`, `.glb` | Static meshes and scenes, rotation and zoom |
| Scientific data & model catalogs | 10 | `.parquet`, `.npy`, `.npz`, `.safetensors`, `.gguf`, `.latent`, `.arrow`, `.ipc`, `.feather`, `.onnx` | Schemas, array samples or tensor metadata; no model inference |
| Subtitles, diffs & provenance | 6 | `.srt`, `.vtt`, `.diff`, `.patch`, `.xmp`, `.c2pa` | Subtitle tables, changed lines, metadata source and unverified C2PA structure |
| Additional developer sources, configs & compiled files | 215 | `.a3x`, `.acf`, `.ada`, `.ado`, `.applescript`, `.as`, `.ascr`, `.asd`, `.asm`, `.asp`, `.aspx`, `.atl`, `.au3`, `.avt`, `.awk`, `.bas`, `.bashrc`, `.basic`, `.bat`, `.bb`, `.bezel`, `.bib`, `.c++`, `.cfc`, `.cfg`, `.cfm`, `.cfml`, `.class`, `.cli`, `.clj`, `.cljc`, `.cljs`, `.cls`, `.cmd`, `.code-workspace`, `.coffee`, `.command`, `.con`, `.cp`, `.cr`, `.csh`, `.cson`, `.csproj`, `.ctx`, `.d`, `.designspace`, `.do`, `.dockerfile`, `.dtd`, `.dylan`, `.e`, `.ecf`, `.ecore`, `.edn`, `.el`, `.entitlements`, `.env`, `.erb`, `.erl`, `.ex`, `.exs`, `.f`, `.f90`, `.f95`, `.fea`, `.fish`, `.flow`, `.fnc`, `.for`, `.fs`, `.fsx`, `.fxml`, `.gd`, `.gemfile`, `.gleam`, `.gpx`, `.haml`, `.heex`, `.hri`, `.hrl`, `.hs`, `.ily`, `.iml`, `.inf`, `.ino`, `.iss`, `.jav`, `.javascript`, `.jl`, `.jnlp`, `.jscript`, `.jsm`, `.jsp`, `.kml`, `.kmt`, `.ksh`, `.latex`, `.lay`, `.ld`, `.lhs`, `.lisp`, `.loctable`, `.lsp`, `.ltx`, `.ly`, `.m`, `.mak`, `.map`, `.mf`, `.mill`, `.ml`, `.mll`, `.mly`, `.mobileconfig`, `.mpd`, `.mq4`, `.mq5`, `.ms`, `.mvw`, `.mxml`, `.ncx`, `.nf`, `.nim`, `.nix`, `.opf`, `.otio`, `.pas`, `.pck`, `.pddl`, `.pde`, `.ph3`, `.ph4`, `.php3`, `.php4`, `.phtml`, `.pkb`, `.pks`, `.pl`, `.pm`, `.podspec`, `.pom`, `.prc`, `.pro`, `.psd1`, `.psjs`, `.psm1`, `.pub`, `.py3`, `.raml`, `.rbw`, `.rdf`, `.readme`, `.rex`, `.rexx`, `.rhtml`, `.rjs`, `.rkt`, `.robot`, `.s79`, `.sage`, `.sas`, `.sbt`, `.sc`, `.scad`, `.sch`, `.scl`, `.scm`, `.scpt`, `.sequ`, `.sld`, `.sls`, `.smali`, `.sol`, `.sps`, `.sqs`, `.ss`, `.storybard`, `.storyboard`, `.strings`, `.stringsdict`, `.sty`, `.t`, `.tab`, `.tcl`, `.tcsh`, `.texi`, `.text`, `.tfstate`, `.tpb`, `.tps`, `.trg`, `.ttx`, `.twig`, `.unity`, `.v`, `.vb`, `.vbs`, `.vhd`, `.vhdl`, `.vim`, `.vl`, `.vw`, `.wflow`, `.xaml`, `.xcscheme`, `.xib`, `.xm`, `.xq`, `.xquery`, `.xsd`, `.xu`, `.xul`, `.zig`, `.zon`, `.zshrc` | More source grammars; binary plist, Java class and AppleScript inspection; see scope below |
| **Total** | **363** | **Distinct extensions** | **Source, structure or rendered views, depending on format** |

XMind: modern `content.json` and legacy `content.xml` workbooks, sheet selection, topic trees and relationships. Automatic tree layout; original styles, images, attachments, notes and summaries are not rendered. Up to 50 sheets and 2,000 topics in total, subject to archive safety limits.

Also supported:

- **49 special filenames and 7 prefix rules**, including `Dockerfile`, `Makefile`, `.env`, `.gitignore`, `.editorconfig`, ecosystem lockfiles, `.env.local` and `Dockerfile.dev`. See the [full counting inventory](docs/format-count.md).
- **Whole folders / project directories** with a file tree, overview and on-demand reading; excluded from the extension count.
- **Content-aware workflow detection** for ComfyUI / n8n JSON, Dify YAML and OpenAPI JSON; these reuse JSON / YAML extensions and are not counted again.
- **System-format integration** for ImageIO images, AVKit media, Word / RTF / ODT and XLSX / PPTX content. Availability depends on the OS and file; these are excluded from the fixed count. See [system-format scope](docs/system-preview.md).

See the [auditable inventory](docs/format-count.md), [advanced preview limits](docs/advanced-output-previews.md) and [Finder verification matrix](docs/format-support.md). Detailed engineering documents currently include Chinese content.

The local development fix passes 212 reader checks across all 106 extensions in standalone and folder paths. All 106 Finder Space checks have been performed: 104 primary samples show content with the reversible STL/OBJ native preview setting enabled; `.ts` / `.mts` still show basic information only. Minimal, binary and ASCII STL samples pass. See the [latest native fix and limits](docs/evidence/single-file-dispatch-2026-10-13/README.md) and [full per-format audit](docs/evidence/single-file-audit-2026-10-13/README.md). The downloadable `preview.1` does not include this unpublished fix.

## Quick start

Use the [installer above](#download), or build from source. Deployment target: **macOS 14**. Recorded testing primarily uses Apple M3 Pro / macOS 26.6.2; builds use Xcode 26.5. Other OS versions and Intel hardware are not fully verified.

From the repository root, with Xcode installed:

```sh
./scripts/install-dev.sh
open ~/Applications/OrangeLen.app
```

The installer builds the app and installs it into `~/Applications`. The first build downloads pinned Swift dependencies.

1. Select a file or folder in Finder and press **Space**.
2. In a folder preview, expand the sidebar and select a file to read it on the right.
3. Alternatively, use **⌘O** in OrangeLen to open a file or folder, and **⌘,** for settings.

If OrangeLen does not appear, check Quick Look extensions in System Settings, then close and reopen the preview. Some individual files remain system-handled; use the app or folder entry point. See [Finder setup](docs/development-guide.md#finder).

## Scope and limits

- Components are single-file snapshots; 3D scenes are static; Office content previews do not promise layout fidelity.
- Previews do not install Skill / MCP packages, execute workflows, start notebook kernels or run model inference. React components evaluate in an isolated, network-blocked WebKit environment.
- Files are read-only. Large text uses pages; structures, archives and media have resource limits. C2PA views show structure without verifying authenticity.
- Local Markdown images and related resources require directory access. HTML previews allow scripts and network resources.

See the [current entry-point contract](docs/current-contract.md) and [security and resource limits](docs/development-guide.md#safety-and-limits).

## Development and feedback

```sh
./scripts/build.sh
./scripts/test.sh
./scripts/test-native.sh
```

Source suffix fixtures are generated before testing (requires Python 3 and macOS’s `osacompile`); `Tests/Fixtures/source-parity/` is not versioned. Direct SwiftPM and Xcode test runs also prepare these fixtures automatically.

Reproducible issues, synthetic fixtures and improvement suggestions are welcome. Include your macOS version, architecture, file extension and entry point: individual Finder file, folder preview or app. Do not attach private files or signing material.

[Architecture](docs/architecture.md) · [Build, signing and uninstall](docs/development-guide.md) · [Verification](docs/verification.md) · [Dependencies and license notes](docs/dependencies.md) · [Changelog](CHANGELOG.md)

FreeMind / Freeplane `.mm` and OPML `.opml`: automatic topic trees, FreeMind relationship arrows and plain text from rich titles, with source switching. Styles, notes and attachments are omitted; links are never fetched. Up to 2,000 topics and 1 MiB input. Objective-C++ `.mm` files remain source text.

MindManager `.mmap`: reads ZIP `Document.xml` topic trees and floating topics with automatic layout. Original styles, relationships, notes, tasks and attachments are omitted; encrypted maps and legacy `.mmp` are unsupported. Up to 2,000 topics, subject to shared ZIP/XML budgets.

Developer batch 1 adds Python/Cython, CUDA/C++, build/template/rule source extensions; Arrow IPC/Feather V2 tables (LZ4/ZSTD), wheel/VSIX metadata and trees, JUnit/SARIF/OpenAPI summaries, ONNX graph/tensor catalogs, and offline DOT diagrams. See [scope and Finder verification](docs/evidence/developer-batch1-2026-10-15/README.md).

Batch 1 direct Finder verification passed 40/42 valid samples; `.dot` and `.cursorrules` require the folder-preview route on the tested Mac. This is not a claim that all 363 extensions pass direct Finder dispatch.

The current development build expands the Syntax Highlight suffix inventory. See [scope and verification](docs/syntax-highlight-parity.md) for compiled formats and Finder routing. The public preview.2 package predates these additions.
