# Extended archive fixtures

Synthetic 7z/TAR archives contain `README.md` (OrangeLen Chinese/emoji sample)
and `config.json`. 7z was written with the macOS libarchive writer. TAR uses
Python USTAR, compressed with XZ/BZIP2 and Zstandard 1.5.7. Unsafe traversal and
symlink samples are synthetic and are never extracted.

RAR fixtures are decoded from uuencoded inputs in the BSD-licensed
[libarchive v3.7.4 test suite](https://github.com/libarchive/libarchive/tree/v3.7.4/libarchive/test):

- sample-rar4.rar: test_read_format_rar.rar.uu
- sample-rar5.rar: test_read_format_rar5_stored.rar.uu
- compressed-rar4.rar: test_read_format_rar_compress_normal.rar.uu
- compressed-rar5.rar: test_read_format_rar5_compressed.rar.uu

No WinRAR executable or commercial code is included. Test content is upstream
reference material; fixture provenance does not imply support for every variant.
See [libarchive notice](../../../docs/licenses/Libarchive-LICENSE.txt).

SHA-256:

```
7d32e2ef511d0ade372345440838165df828197eff4d7816880dafde690cce03  compressed-rar4.rar
68f9d7e2662cd5bc5607ba9c6bf1edbf121cf3b08011a7d8643091791750a7c8  compressed-rar5.rar
3bffe2a82fdf538ded67fa3ef1365051a81c73d623327515775508c51e7d04f9  link.tar.bz2
d421b86f6290aefad61b2a36737253b2b30fe27c156bd95abfc230f24fe0307e  sample-rar4.rar
35d75e315d164d2e329afc28f7d844f013271b4fcffd4ddd78efcdd114a383a7  sample-rar5.rar
2c61d1cbea05f9f8d80ced406bdfff082f0d7fc71941a8bfd3e11b98e44df136  sample.7z
8ba22f0151d904602473e4f36db1bc5f0774a1a04841c7bbfb6fab1592772177  sample.tar.bz2
1551f31708692f82cab19de28e0b251cb388f73f1d83368af9eb9339aec59b4d  sample.tar.xz
32c3e18e802eeaf0c2365e2a88d8b48a453841d01ba76423bf042817e207cd62  sample.tar.zst
eaa037e25ca50041ea2d52c21f6e307508823ec306beb90b3097676bbde4f7aa  unsafe.tar.xz
```
