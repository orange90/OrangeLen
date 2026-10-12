# 离线高级格式引擎

这些资源由官方 npm 包构建，源代码/字体不来自用户文档。实际安装版本由 package-lock.json 固定；运行时不依赖 Node 或 Python。构建命令在此目录执行：

```sh
npm ci --ignore-scripts --no-audit --no-fund
npm run build
```

输出 ComponentRenderer.html（React 18.3.1、Babel 7.26.10、MDX 3.1.0）、ParquetRenderer.html / parquet.wasm（parquet-wasm 0.7.1、Arrow 19.0.0）、TypstCompiler.html / typst.wasm（Typst.ts/compiler 0.7.0）和 LaTeXRenderer.html（LaTeX.js 0.12.6）。esbuild 0.25.0 仅用于构建。所有输出放到 OrangeLenUI 的 SwiftPM Resources。

Typst 字体固定来自 typst-assets / typst-dev-assets v0.13.1 的 files/fonts：LibertinusSerif-Regular.otf、NewCMMath-Book.otf、NotoSerifCJKsc-Regular.otf（上游 CJK 子集）。字体副本已纳入仓库资源，无需预览时下载。对应 LICENSE/NOTICE，以及 LaTeX 字体 OFL，在 docs/licenses 中；资源 SHA-256 在 docs/advanced-renderer-sha256.json。

任何更新需重新检查完整依赖许可证、更新资源 hash、重跑真实渲染/解码及 Finder 验收。build 输出的顶部包许可摘要不能替代 docs/licenses/AdvancedRenderer-dependencies.txt 中完整的依赖许可记录。npm 工具不属于预览运行时；用户文件不会成为构建脚本输入。
