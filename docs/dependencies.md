# Dependencies

Runtime is native Swift / AppKit / SwiftUI / Foundation / NaturalLanguage / CryptoKit / Quartz / UniformTypeIdentifiers. No Node, Python, shell or previewed project scripts run during previews. WebKit runs bundled KaTeX/Mermaid in an ephemeral isolated render surface; the native document reader embeds the resulting images. An embedded sandboxed XPC service performs explicit remote-image requests. The build uses SwiftPM; network is required only for the initial dependency fetch.

| Dependency | Resolved version | Purpose | License |
|---|---|---|---|
| [swift-markdown](https://github.com/swiftlang/swift-markdown/releases/tag/0.8.0) | 0.8.0 | CommonMark / GFM AST and UTF-8 source positions | Apache 2.0 with Swift exception, see `licenses/` |
| [swift-cmark](https://github.com/swiftlang/swift-cmark) | 0.9.0 | swift-markdown's C parser | BSD-style + bundled notices, see `licenses/swift-cmark-COPYING.txt` |
| [KaTeX](https://katex.org/) | 0.19.0 | Offline TeX math layout | MIT; bundled license collection |
| [Mermaid](https://mermaid.js.org/) | 12.1.0 | Offline diagram layout | MIT; transitive notices in `licenses/MarkdownRenderer-dependencies.txt` |
| esbuild | 0.28.2 (build-time only) | Produce committed offline renderer HTML | MIT; not executed during previews |
| XcodeGen | Build-time only; generated project committed | Regenerate `OrangeLen.xcodeproj` from `project.yml` | MIT; not bundled |

Exact revisions are pinned in `Packages/OrangeLen/Package.resolved` and the Xcode workspace's `Package.resolved`. Dependency license files are copied into the app Resources during packaging. The lexical source highlighter is local code, not a compiler or syntax-execution engine.

Renderer dependency integrity is pinned in `Vendor/MarkdownRenderer/package-lock.json`; normal Xcode builds use the committed resource. `npm audit` on 2026-10-03 reported 0 known vulnerabilities (not a guarantee of absence), see `Vendor/MarkdownRenderer/audit.json`.
