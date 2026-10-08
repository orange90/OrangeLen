# Offline Excalidraw renderer

Run `npm ci --ignore-scripts && npm run build` here to regenerate the committed
`ExcalidrawRenderer.html`. No Node/npm dependency is required at runtime.

Pinned Excalidraw 0.18.1 uses `restoreElements` and `exportToSvg` from its public
API: https://docs.excalidraw.com/docs/@excalidraw/excalidraw/api/utils/export
Only the generated static SVG is snapshotted; no editor is mounted.

Input crosses WebKit as a structured argument. Swift validates JSON and geometry,
removes links/custom data, and normalizes accepted embedded raster images to PNG.
The renderer strips links, event attributes and foreign content. CSP, a WebKit
content blocker, an ephemeral data store and navigation rejection prohibit network
and file loading. SVG images, web embeds and external image URLs are not loaded.
Virgil, Excalifont and Cascadia are embedded; other fonts use local fallback.
Licenses are in `docs/licenses/`; the Excalifont notice is extracted from its
upstream font source. All bundled font bytes retain their original names.

`nanoid`, `lodash-es`, and build-time `sass` overrides pin patched dependencies;
the Mermaid converter's nanoid is overridden explicitly as well. `audit.json`
records the final npm audit (0 vulnerabilities on 2026-10-04). Audit results do
not establish that the renderer has no vulnerabilities.
