# 资源打包优化验收（2026-10-12）

用户要求先提交完整功能基线，再去掉重复资源、测量 Release，并保留全部既有能力。基线为 `d70f6a3`，实现见 [共享资源说明](../../resource-packaging.md)。本机 Apple Silicon 验收，未推送或发布。

## 最终结果

| 产品 | 逻辑包体 | 证据 |
| --- | ---: | --- |
| 去重前通用 Release | 666.913 MiB | [同架构对比](universal-size.json) |
| 去重后通用 Release（arm64 + x86_64） | 268.478 MiB | [构建](universal-build.log)、[体积/资源清单](universal-size.json) |
| 去重后 Apple Silicon Release | 159.896 MiB | [构建](arm64-build.log)、[体积/资源清单](arm64-size.json) |
| 最终开发签名安装 | 159.907 MiB | [安装](install.log)、[签名](signature.log)、[安装后再核对](installed-size.json) |

安装位于 `/Users/huangzhe/Applications/OrangeLen.app`，已启动最终版本。通用产品保存在仓库 `build/artifacts/OrangeLen-resource-universal.app`，支持两种架构，但没有在 Intel 实机运行。MiB 为 1,048,576 字节；不以 ZIP 压缩或目录别名重复计数解释包体。

最终包包含 **1 个资源 framework，0 个 Core/UI SwiftPM 资源包副本**。旧通用包中 UI 8 份、Core 23 份，全数移除。资源文件清单没有缺失；12 个渲染器/WASM/字体文件与基线原字节一致，中英文完整词条字典一致。唯一主动更新的是 LaTeX HTML：在 PDF 截取前强制布局、等待字体实际加载，以修复数学字母缺失；[更新后的 SHA-256](../../advanced-renderer-sha256.json) 已核对。

## 自动回归

- Release 分进程覆盖整套 170 项：Core [83 项全部通过](core-tests.log)，UI [87 项登记、84 通过、3 专用宿主跳过](ui-tests.log)，0 失败。包含原有 HTML/Notebook/归档/数据库/高亮/布局，以及所有新增格式、授权/损坏/取消/释放等回归。
- [真实链接共享 framework 的原生宿主测试](native-tests.log)：13 项全部通过，覆盖 React/TSX/MDX、Typst/LaTeX PDF（含数学字母检查）、Parquet、图形、数组/模型/容器，以及 Word/媒体沙盒 XPC、全部 renderer/font 读取、中英文词条和高亮语言。涵盖 SwiftPM 跳过的 3 项。
- [打包校验](packaging-tests.log)：5 项全部通过，覆盖内容保留、幂等、缺失/多余资源、异常链接、验证模式不修改和拒绝其他应用。
- [deep/strict 签名校验](signature.log) 通过；所有消费者包含共享 framework 链接及相对 rpath，唯一 framework 由现有开发身份签名。

没有把早期整套单进程结果报告为成功：[空 Notebook 失败](notebook-before.log) 已修复并强化最终状态断言；[512 MiB 准入保护失败](memory-before.log) 保留，最终按套件分进程通过，未提高保护阈值。不宣称所有长时间/GPU/内存压力场景通过。

## 最终 Finder 现场

以下截图均来自最终安装版本。七类扩展各有代表入口，不用主应用成功替代 Finder：

| 入口 / 内容 | 实际结果 | 截图与 AX |
| --- | --- | --- |
| Code · Swift 单文件 | 中文/emoji 源码、行号和彩色高亮 | [图](finder-swift-single.png)、[AX](finder-swift-single.txt) |
| Markdown · Mermaid 单文件 | 中文节点图与缩放控件 | [图](finder-mermaid-single.png)、[AX](finder-mermaid-single.txt) |
| Data · SQLite 单文件 | 只读表格、整数/BLOB/列类型 | [图](finder-sqlite-single.png)、[AX](finder-sqlite-single.txt) |
| Archives · MCPB 单文件 | 清单概览、成员目录/原清单 | [图](finder-mcpb-single.png)、[AX](finder-mcpb-single.txt) |
| Books · EPUB 单文件 | 章节、中文/英文/emoji 正文及内嵌图片 | [图](finder-epub-single.png)、[AX](finder-epub-single.txt) |
| Drawings · Excalidraw 单文件 | 图形、中文/英文、连线、手绘线及内嵌图 | [图](finder-excalidraw-single.png)、[AX](finder-excalidraw-single.txt) |
| Folders · SVG | 共享 SVG renderer 的图形、渐变和文字 | [图](finder-svg.png)、[AX](finder-svg.txt) |
| Folders · TSX | React 组件效果，数值 42 | [图](finder-tsx.png)、[AX](finder-tsx.txt) |
| Folders · LaTeX | 标题、列表、完整 E = mc² 数学字母与公式 | [图](finder-latex.png)、[AX](finder-latex.txt) |
| Folders · Typst | 中文标题/正文、公式与列表 PDF | [图](finder-typst.png)、[AX](finder-typst.txt) |
| Folders · Parquet | 三列类型、三行样本、筛选入口 | [图](finder-parquet.png)、[AX](finder-parquet.txt) |
| Folders · GLB | 网格和旋转/缩放控件 | [图](finder-glb.png)、[AX](finder-glb.txt) |
| Folders · Draw.io | 中文形状、标签与连线完整显示 | [图](finder-drawio.png)、[AX](finder-drawio.txt) |

TSX 单文件在本机仍由系统文本处理器接管，效果通过主应用/文件夹入口提供；没有改系统默认应用或扩大 UTType 抢占。其他格式由自动解析、UI 和原生 framework 回归覆盖，本轮未逐一点击每种后缀的单文件入口。格式原有范围见 [扩展预览](../../advanced-output-previews.md)。

## 失败记录与范围

普通父应用 bundle 查找初稿在 Finder 中失败，曾触发 [SwiftPM accessor 崩溃日志](resource-lookup-before.log) 和 [源码降级](finder-resources-before.txt)、[画面](finder-resources-before.png)；已恢复基线后采用标准共享 framework，最终通过上述现场验收。[LaTeX 字体加载前](latex-font-before.log) 与 [修复后](latex-font-after.log) 的针对回归也保留。[磁盘满构建](disk-full-before.log) 后仅清理本轮可重建缓存，再构建成功。

日志复制仅清理行尾空白和末尾空行；原始日志在 `/tmp/orangelen-resource-*.log`。尾部 Swift Testing 的“0 tests”不代替 XCTest suite 数量。没有做公证/正式分发、Intel/macOS 14 实机、所有云盘与辅助功能验收；现有格式限制保持原契约。
