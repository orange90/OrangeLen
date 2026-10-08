# Excalidraw preview

Standard `.excalidraw` JSON routes through the shared Reader before generic text
loading. Finder imports `com.excalidraw.excalidraw`; existing type declarations
may take precedence. The default opening application is not changed.

The offline Excalidraw 0.18.1 exporter renders a static SVG inside the existing
private, ephemeral WebKit renderer, then snapshots it into an NSImageView. The
original JSON remains searchable/copyable in source mode; finding a source match
switches to source. A malformed scene or export failure falls back to source.
Switching files cancels the renderer, with a generation check on async results.

Supported: rectangles, diamonds, ellipses, lines/arrows, freehand strokes, text,
frames, embedded PNG/JPEG/GIF/WebP images (first frame only). Deleted elements
are omitted. Virgil, Excalifont and Cascadia fonts are bundled; Chinese and other
font families use installed fallback fonts, so typography may differ from the
editor. Unknown elements and web embeds are skipped with a warning. Embedded SVG,
remote images and filesystem image references are not loaded. Missing images
remain exporter placeholders and produce a warning. Obsidian `.excalidraw.md`,
compressed drawing blocks, libraries, editing, links and free zoom are unsupported.

Budgets: 5 MiB source; shared JSON depth 64 / 20,000 nodes; at most 1,000 elements
and 10,000 path points (JSON limits may be reached earlier). Coordinates are
finite and bounded to magnitude 1,000,000. Embedded source images are limited to
25 million pixels each, decoded longest edge 1,600, total 8 million decoded
pixels. Export is fit to at most 800 × 1,500 logical points, then scaled to the
window. WebKit boot timeout is 8 seconds, export/snapshot timeout 5 seconds.
Large diagrams therefore lose detail; source remains available within file limits.

Swift passes JSON as a structured JavaScript argument, never interpolated HTML.
Links/custom data are removed before export; SVG foreign content, event handlers,
and external href values are removed afterward. Only normalized PNG data URLs are
passed as images. CSP disallows connections, frames, objects and file resources;
a WebKit blocker and navigation delegate provide additional isolation. Previewed
scripts do not execute. Cancellation is best effort; these checks are not a
claim of exhaustive malicious-input resistance.

Rebuild instructions and dependency/license provenance:
[Vendor/ExcalidrawRenderer](../Vendor/ExcalidrawRenderer/README.md).
