# Native Quick Look TypeScript / transport-stream routing reproduction

Tested 2026-10-13 on macOS 26.6.2 (25G83), Apple M3 Pro, Xcode 26.5.

The signed OrangeLen app is registered and its Code preview extension is explicitly enabled. Its `QLPreviewingController` implements `preparePreviewOfFile(at:completionHandler:)`. The view-based extension declares:

```text
public.mpeg-2-transport-stream
public.avchd-mpeg-2-transport-stream
com.microsoft.typescript
public.source-code
public.plain-text
local.orangelen.developer-source
```

The host exports `local.orangelen.developer-source` for CTS among its source suffixes. The actual file types for TS and MTS remain the system transport-stream identifiers.

1. Create three UTF-8 files with identical TypeScript source: `example.cts`, `example.ts`, `example.mts`.
2. Select one file at a time in Finder, then press Space.
3. CTS reaches the extension and displays code. TS and MTS display basic file information; the source preview callback does not receive those files.
4. Close the panel between files. Observe actual content, not just successful registration or completion callbacks.

Expected: a native way to let a source preview extension handle textual TypeScript while leaving real transport-stream media to video handling.

Actual: the built-in file-type/video path takes priority before the source extension is called. Giving the app Owner rank and suffix-opening preferences does not change the actual file type or Space result. Declaring parent movie types also fails to route textual TS/MTS into the extension.

Evidence and the exact attempted configurations are linked in [the research report](README.md). No global key interception, resident helper, input permissions, system-file modification or suffix renaming is part of the reproduction. CLI `qlmanage` with a forced content type is not an acceptance test for Finder's normal Space behavior.
