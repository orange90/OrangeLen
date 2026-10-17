# Archive readers

The CArchive module links the macOS system `libarchive`; only the built-in 7-Zip,
RAR/RAR5 and TAR readers and none/XZ/BZIP2 filters are enabled. No extraction API,
external decompressor, password callback or additional volume is opened.
Vendored public headers are from libarchive 3.7.4; see
[license](../../docs/licenses/Libarchive-LICENSE.txt) and `provenance.json`.

CZstd contains the upstream Zstandard 1.5.7 single-file decoder generated with
`build/single_file_libs/create_single_file_decoder.sh`, followed by OrangeLen's
bounded wrapper. It is compiled for the app's target architecture; Homebrew and
command-line decompression tools are not runtime dependencies. The wrapper caps
the decoding window at 64 MiB and requires complete frames within the supplied
output budget. See [BSD license](../../docs/licenses/Zstandard-LICENSE.txt).

Expanded members are held in bounded memory, never written to disk. Existing
path/identity checks and entry, total-byte, expansion-ratio and cancellation
limits apply. The native readers validate all previewable members while loading;
large members, links, special and encrypted entries cannot be opened. Empty or
incomplete archives are rejected. Solid/compression variants depend on the system
libarchive decoder; password-protected and multi-volume archives are unsupported.
