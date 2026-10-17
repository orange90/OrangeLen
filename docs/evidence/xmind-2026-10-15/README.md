# XMind preview — 2026-10-15

Implemented modern ZIP/content.json and legacy ZIP/content.xml reading, sheet selection, auto-layout topic trees (including detached topics) and relationships. Drawings extension declares `org.xmind.openformat.xmind`; the host imports the same type. Styles, images, attachments, notes and summaries are not rendered. No members are extracted or external resources fetched.

Format references: [XMind official SDK functional tests](https://github.com/xmindltd/xmind-sdk-js/blob/master/test/functional/index.test.ts), plus the installed Xmind.app exported UTI declarations. Fixtures in `Tests/Fixtures/advanced-outputs/*.xmind` are synthetic, not representative real-world compatibility certification.

Verification:

- `scripts/build.sh`: Xcode Debug build succeeded. Built host and Drawings extension plists both contain the expected XMind UTI.

- `scripts/test.sh --filter 'XMindTests|AdvancedPreviewTests|AdvancedOutputTests|M2Tests'`: 31 tests passed, zero failures. Includes native AppKit canvas creation, sheet switching and switching away to Markdown, as well as archive/parser regressions.
- New cases cover modern/legacy content, Unicode, multiple sheets, detached topics, relationship edges, duplicate topic IDs, unsafe XML declarations, missing content, invalid ZIP and cancellation.
- Limits: 50 sheets, 2,000 total topics, depth 48 (also subject to shared JSON/XML parser depth), shared container/member/expansion/CRC checks.
- Follow-up installation: Apple Development signed build installed in `/Users/huangzhe/Applications/OrangeLen.app` and `/Applications/OrangeLen.app`; deep/strict signature verification passed. The former `/Applications` copy was backed up at `build/install-backups/OrangeLen-before-xmind-20261015.app.backup`. The public release is unchanged.
- Actual Finder Space test initially showed metadata while the older `/Applications` extension remained selected. Replacing that copy and refreshing registration resolved dispatch.
- Actual Finder Space passed for `modern.xmind` (topic tree, floating topic, relationship), its second sheet (Chinese + emoji), and `legacy.xmind` (topics and labeled relationship). Verified via CUA keyboard input, AX state and screenshots, not qlmanage-generated previews. Local screenshots: `finder-modern.png`, `finder-modern-page2.png`, `finder-legacy.png`.
- These are synthetic fixtures on this Mac; they do not certify all real-world XMind files. Historical 104/106 results remain unchanged.
