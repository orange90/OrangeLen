# Archive expansion: Finder Space verification

Date: 2026-10-17, local macOS Apple Silicon. This is the current development build;
the public preview.2 release has not been replaced.

## Result

All five requested archive families reached OrangeLen's archive tree and a real
member's content in Finder Quick Look. Seven representative files were selected
in Finder, opened with Space, and their member rows clicked through CUA:

| Family / variant | File | Member content actually observed | Result |
| --- | --- | --- | --- |
| 7z | sample.7z | README.md: `Archive preview 中文🍊` | Pass |
| RAR4 | sample-rar4.rar | test.txt: `test text document` | Pass |
| RAR5 | sample-rar5.rar | helloworld.txt: `hello libarchive test suite!` | Pass |
| TAR/XZ | sample.tar.xz | README.md: Chinese/emoji body | Pass |
| TAR/BZIP2 | sample.tar.bz2 | README.md: Chinese/emoji body | Pass |
| TAR/Zstandard | sample.tar.zst | README.md: Chinese/emoji body | Pass after UTI fix |
| Compressed RAR4 | compressed-rar4.rar | testdir/test.txt; full archive decoded including compressed HTML members | Pass |

The RAR link entry is visibly marked Restricted; selecting it shows the refusal
message and does not follow the link. RAR5 compressed binary payload is covered
by parser tests (1,200 bytes), not claimed as a Finder text preview.

Machine-readable cases, fixture hashes and local screenshot/AX filenames:
[finder-results.json](finder-results.json). Screenshots and raw AX captures are
kept locally and ignored by Git. The checked-in cases preserve the observed result.

## Fix discovered by real Finder testing

Initially `.tar.zst` only showed native file information, although parser and reader
tests passed. Its exported archive UTI inherited `public.archive` but lacked
`public.data`. Added both parents, regenerated Xcode/Info.plist files, rebuilt,
signed and installed the updated app. The system now resolves zst/tzst to
`local.orangelen.extended-archive`; reopening the same file with Space displays the
OrangeLen tree and Chinese/emoji member body. No catch-all public.data preview
registration or system Shortcuts-provider preference was added.

## Build, installation and automated checks

- `./scripts/test.sh`: 313 tests, 4 environment-dependent skips, zero failures.
- Focused archive/parser/reader selection: 13 tests, zero failures (overlaps above).
- Native Xcode host: ExtendedArchivePreviewTests, one test with seven archive/member
  cases, zero failures. Initial/retry hosts stalled before tests started; moving
  the old build-only test host aside and rebuilding resolved startup. No product
  security settings were disabled; exact initial loader cause was not proven.
- Main app and preview extensions: Debug builds passed, including the UTI correction.
- Installed Apple Development-signed copies in `~/Applications/OrangeLen.app` and
  `/Applications/OrangeLen.app`; deep/strict signature verification passed, and
  the prior app-group identity was preserved. Runtime links contain no Homebrew
  library path. Installation details are local `installed.json` (Git-ignored).
- Previous copies: `build/install-backups/archive-expansion-20261017/`.
- Format registry consistency passed; explicit final-suffix/alias count is now 371.

## Scope

These are small synthetic or upstream reference fixtures, not every RAR/7z
compression method, solid variant, filename encoding or large-file combination.
Aliases txz/tbz2/tzst are parser-tested; no separate Finder result is asserted for
those three aliases. Encrypted/multi-volume archives and arbitrary standalone
xz/bz2/zst streams are outside this batch. Limits and decoding paths are in
[archive-formats.md](../../archive-formats.md).

This report accompanies the archive expansion source changes. The public release
has not been updated; installation and Finder verification were local.
