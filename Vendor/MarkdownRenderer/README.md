# Offline renderer bundle

KaTeX and Mermaid are pinned in package-lock.json. Committed HTML contains all scripts,
styles and fonts; normal Swift/Xcode builds need no Node or network to render documents.

To deliberately refresh the bundle: `npm ci --ignore-scripts && node build.mjs` here.
This executes only checked-in renderer tooling and registry packages, never previewed
project scripts. Recheck licenses and security tests before upgrading dependencies.

The hidden WKWebView is an ephemeral image renderer, not the document reader. Input is
passed using callAsyncJavaScript structured arguments. CSP and content rules prohibit
network loads. Mermaid strict mode disables clicks; configuration directives, markup,
external references and actionable SVG elements are refused/removed. KaTeX uses
trust:false with macro/size limits. Failed content remains source-copyable in TextKit.
