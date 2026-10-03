# Architecture and implementation decisions

Source of requirements: user request dated 2026-10-03 and supplied `OrangeLen-开发设计文档.md` v1.0. The worktree was empty, with no on-disk AGENTS.md in it or its inspected ancestors. Current chat instructions were applied. The design's implementation defaults were treated as defaults, not as permission to execute previewed content.

- `App/`: programmatic AppKit application lifecycle, native open panel; SwiftUI settings.
- `PreviewExtension/`: `NSViewController + QLPreviewingController`, exact installed SDK callback; hosts the shared reader; system completion is called once. Errors are visible in the reader, cancellation remains cancellation.
- `Packages/OrangeLen/OrangeLenCore`: bounded AccessBroker, format dispatch, strict encodings, source snapshots/revisions, cmark-backed Markdown AST projection, source/display spans, sentence segmentation, JSON parser, CSV state machine, lazy directory pages and settings/state.
- `OrangeLenUI`: native NSTextView/TextKit 1, NSOutlineView and NSTableView. TextKit 1 is a deliberate implementation choice: its UTF-16 layout manager APIs provide exact glyph/line rectangles for decoration and line labels. No height is inferred from font size or logical line number.

## Data and lifetime

Each `loadFile` cancels the previous token, completes any old preparation with cancellation, and generates a new UUID. Background results must match that UUID before touching the main thread UI. File descriptors and coordinated reads end before the preview is ready. Closing a preview cancels outstanding directory/file work and settings polling, then releases the root security scope. Completion-count/latest-selection behavior has a native integration test.

`AccessBroker` validates root boundaries and symlink policy, opens paths component-by-component with `openat + O_NOFOLLOW` (including parents), and reads bounded chunks. Only the protected macOS `/var`, `/tmp`, `/etc` aliases are expanded to `/private/...`; arbitrary project links are refused. Cloud downloading state and `SF_DATALESS` are checked before bytes. Identity/size/nanosecond revision checks catch replacement or changes during a read. This is not a cryptographic unchanged-content proof against adversarial same-metadata rewrites. Provider stalls and cmark's synchronous C parse cannot be preempted mid-call; cancelled results are discarded.

Markdown positions from cmark are UTF-8 byte columns. A bounded byte→UTF-16 index converts them; display spans carry exact or transformed source ranges. Escapes/entities use individual mapping spans. Search, selection-copy and focus consume this one model. Unknown transformations fall back to a whole AST-node range with a warning; arbitrary exact selection remains available in source mode. Raw document HTML is never reparsed or executed. Bundled, isolated KaTeX/Mermaid renderers accept source as data and return images. Link activation handles heading anchors and bounded local paths; explicit HTTP(S) clicks open the system browser, and other schemes are rejected. Native NSTextTable cells and NSTextBlock quote/code containers preserve display offsets. Inline image attachments occupy mapped U+FFFC characters; captions remain selectable. The ruler deduplicates actual TextKit fragments at the same baseline across table columns.

Decorations are drawn behind glyphs, never inserted into content. Long sentence highlighting and visual-line ruler are separate operations. Theme/size changes rebuild attributes while preserving the source anchor. Navigation redraws the previous/current sentence, not the whole parsed document. An actual defect found during screenshot inspection (ruler painting outside its view) was fixed with clipping plus reserved text inset; a regression asserts glyphs cannot lie under the ruler.

## Settings / signing

Default ad-hoc builds have independent app/extension settings, reported in the footer. The optional installer builds a macOS team-prefixed group identifier from an explicitly supplied team ID and signs all nested code consistently. Current-machine Apple Development group-container access and host→extension focus setting transfer were observed; Developer ID distribution remains untested.

Settings use shared UserDefaults, with active-preview refresh. Reading positions are optional, atomic JSON per salted file identity, with NSFileCoordinator around writes, revision checks and expiry/cap. First-run salt creation / cross-process stress and crash recovery require further tests. No source-body cache or project sidecar is written.

## Deliberate deviations and gaps

- One shared package contains separate Core/UI products rather than two sibling packages; this keeps dependency resolution consistent for app, extension and tests.
- Source highlighting is a bounded lexical highlighter, not a language-complete compiler grammar. M1 rendering fidelity limitations are listed separately.
- Markdown local inline images use AccessBroker and ImageIO: up to 8 attempts, 5 MiB each, 20 MiB total input, 8 million decoded pixels, 1200-pixel maximum edge. Paths stay inside the selected root (or document parent), symlinks/cloud placeholders are refused, and cancellation propagates. Adjacent-file sandbox permission is not assumed. Remote images start as placeholders and require an explicit click to download through the narrow image-only HTTPS/XPC path. Inaccessible/budget-exceeded images retain visible placeholders. Standalone folder images retain their separate 25 MiB/2048-pixel limits.
- Directory scanning is per expanded directory with continuation, not a recursive whole-project index. Packages and symlinks are represented without following them. Project summary reads bounded manifest declarations without executing them.
- System CSV preview is accepted under the user’s updated scope. Folder invocation/enumeration and selected Makefile reading have now been observed; broader remote-view input remains under verification. The host fallback is not counted as satisfying those Finder goals.
- M2 containers use a shared native CollectionController and lazy section snapshots. ZIP/TAR never extract to disk; EPUB XHTML is converted to safe Markdown; SQLite deserializes bounded bytes into a read-only memory database. Generation and cancellation guards apply to section changes. See m2-formats.md.

## Primary references checked

- [Apple QLPreviewingController](https://developer.apple.com/documentation/quicklookui/qlpreviewingcontroller) plus Xcode 26.5's installed `QLPreviewingController.h`.
- [Apple macOS app group containers](https://developer.apple.com/documentation/xcode/accessing-app-group-containers): team-prefixed macOS group IDs do not require provisioning profiles when they match the signing team.
- [swift-markdown 0.8.0](https://github.com/swiftlang/swift-markdown/releases/tag/0.8.0); APIs/source positions checked against the fetched pinned source.

## Rich content and explicit image network access

See [Markdown rich content](markdown-rich-content.md) for parsing syntax, shared source mapping, offline renderer isolation, budgets, DNS/IP/TLS rules and evidence. `ImageBroker/` is embedded inside the Quick Look extension; it remains sandboxed with network-client permission only. The extension cannot directly resolve DNS on this tested OS. Native NSXPC transfers bounded image bytes back into the same Finder preview; it never launches a supplementary host window.
