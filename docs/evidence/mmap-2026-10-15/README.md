# MindManager MMAP preview — 2026-10-15

ZIP `Document.xml` topic tree reader, automatic layout and floating topics. Original styles, cross-topic relationships, notes, task metadata and attachments are omitted. Links are never fetched. Encrypted workbooks and legacy `.mmp` are unsupported. Existing ZIP CRC/path/expansion limits and bounded XML parsing apply; 2,000 topics and depth 48 are additional bounds (the XML nesting limit may be reached sooner).

References: [MindManager file overview](https://www.mindmanager.com/en/pages/mmap-file/), [mm2md parser source](https://github.com/memoryblade/mm2md/blob/master/mm2md.py). `com.mindjet.mindmanager.mmap` is also declared by the installed Xmind application. XML element prefixes are independent of parsing, supporting default and explicit namespace prefixes.

Verification:

- 38 tests passed: `scripts/test.sh --filter 'MindManagerTests|OutlineDiagramTests|XMindTests|AdvancedPreviewTests|AdvancedOutputTests|M2Tests'`.
- New cases: ZIP fixture with Chinese/emoji, hierarchy/floating topics, namespace prefixes, default namespace, missing/duplicate topic IDs, invalid XML/ZIP, depth/topic budgets and cancellation. Native UI test opens `.mmap`, creates a canvas and switches to another file.
- `scripts/build.sh`: Xcode Debug build succeeded.
- `Tests/Fixtures/advanced-outputs/project.mmap` is synthetic. No claim of full MindManager format fidelity or arbitrary real-world file compatibility.

Installation and actual Finder verification:

- Apple Development signed build installed to `~/Applications/OrangeLen.app` and `/Applications/OrangeLen.app`. Deep/strict signature verification passed. Old active app backed up at `build/install-backups/OrangeLen-before-mmap-20261015.app.backup`.
- File UTI observed as `com.mindjet.mindmanager.mmap`; Drawings extension registered for this type. Quick Look caches refreshed after installation.
- Actual Finder selection + Space through CUA showed `project.mmap` in OrangeLen: Chinese/emoji titles, seven topics, five hierarchy edges and the detached floating topic. AX identified MindManager and zoom controls; screenshot visually confirmed the diagram. Evidence: `finder-mmap.png`.
- Public release unchanged; this verifies the synthetic sample on this Mac, not every MindManager version.
