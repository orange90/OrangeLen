# Archive support

Development tree, 2026-10-17. The public preview.2 installer predates this change.

| Input | Reading path |
| --- | --- |
| ZIP; ZIP-based Skill/MCP/wheel/VSIX and other supported containers | Existing bounded ZIP reader, stored/Deflate members |
| TAR, tar.gz, tgz | Existing TAR/gzip readers |
| gz text stream | Existing bounded text-stream reader |
| 7z | System libarchive 7-Zip reader |
| RAR4 / RAR5 | System libarchive RAR and RAR5 readers |
| tar.xz / txz | Built-in libarchive XZ + TAR |
| tar.bz2 / tbz2 | Built-in libarchive BZIP2 + TAR |
| tar.zst / tzst | Bundled Zstandard 1.5.7 decoder + TAR |

No runtime Homebrew, `7z`, `unrar`, shell process, password prompt, extraction to
disk or additional volume is used. Members retain the existing tree, filtering,
sorting, source/text and supported image/data reading paths. Native readers stage
previewable bytes in memory, then members are read from that bounded snapshot.

Limits: input 64 MiB; at most 5,000 entries; declared expanded bytes at most 64 MiB;
ratio at most 100; individual previewable member at most 5 MiB; Zstandard window
at most 64 MiB. Paths/identity conflicts are checked; links and special entries
cannot be read. Over-budget data, encrypted members, multi-volume, empty/incomplete
archives and unsupported compression variants return a visible failure or blocked
member. A listed suffix does not imply every historical variant is supported.
Standalone xz/bz2/zst streams are outside this batch.

Fixtures: `Tests/Fixtures/archive-expansion`. RAR fixtures originate in the
[libarchive 3.7.4 test suite](https://github.com/libarchive/libarchive/tree/v3.7.4/libarchive/test)
under its BSD test license; original fixture basenames and checksums are recorded
in the fixture README. Synthetic 7z/TAR fixtures contain only OrangeLen sample text.
Dependencies: [provenance](../Vendor/ArchiveReader/provenance.json),
[libarchive license](licenses/Libarchive-LICENSE.txt),
[Zstandard license](licenses/Zstandard-LICENSE.txt).

Verification results are recorded in
[the local Finder audit](evidence/archive-expansion-2026-10-17/README.md).
