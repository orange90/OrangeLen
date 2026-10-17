# FreeMind / OPML preview — 2026-10-15

Implemented `.mm` FreeMind/Freeplane topic trees and `.opml` outline forests, with automatic layout and source switching. FreeMind rich topic labels are reduced to plain text in reading order; arrowlink relations are included. Styles, notes and attachments are not rendered. OPML subscription/link URLs never trigger requests. XML declarations/entities are rejected; shared XML budgets, 1 MiB input, 2,000 topics and depth 48 apply.

The `.mm` extension collides with Objective-C++ on macOS. A `<map>` content marker enables diagram parsing; other `.mm` content remains source. The Drawings extension declares the observed `public.objective-c-plus-plus-source` UTI as well as `net.sourceforge.freemind.mm`; OPML imports `org.opml.opml`.

References: [FreeMind format documentation](https://freemind.sourceforge.io/wiki/index.php/File_format), [OPML specification](https://opml.org/spec2.opml).

Validation:

- `scripts/test.sh --filter 'OutlineDiagramTests|XMindTests|AdvancedPreviewTests|AdvancedOutputTests'`: 25 tests passed, zero failures after correcting empty `<map/>` detection. Tests cover rich text order, relationship IDs, OPML forests/Unicode, invalid input, node/depth budgets, cancellation, native diagram/source switching and Objective-C++ fallback, plus XMind/diagram regressions.
- `scripts/build.sh`: Debug build succeeded.
- Fixtures: `Tests/Fixtures/advanced-outputs/mindmap.mm`, `outline.opml`, `objective.mm`. These are synthetic samples, not a full real-world compatibility corpus.

Installation and Finder verification:

- Apple Development signed build installed to `/Users/huangzhe/Applications/OrangeLen.app` and `/Applications/OrangeLen.app`; deep/strict signature verification passed. Previous active build preserved at `build/install-backups/OrangeLen-before-outline-20261015.app.backup`.
- Finder Space: `mindmap.mm` displays Chinese/emoji topic tree, plain rich title and cross-topic arrow. Source button displays original XML. Screenshot: `finder-mm.png`.
- Finder Space: `outline.opml` displays two root trees and hierarchy. Source button displays original XML. First attempt was metadata-only; `qlmanage -r cache`, `qlmanage -r` and touching the fixture refreshed the stale type/preview cache. Reopening with Space then passed. Screenshot: `finder-opml.png`.
- Finder Space: `objective.mm` displays original Objective-C++ code, no diagram. File metadata reports `.mm` as `public.objective-c-plus-plus-source`, `.opml` as `org.opml.opml`.
- These checks used actual Finder selection and Space via CUA, with AX/screenshot inspection. Existing published release and historical 106-format audit are unchanged.
