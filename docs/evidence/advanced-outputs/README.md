# 后续 AI 产出格式验收

日期：2026-10-12。本机 Apple Silicon、当前 macOS、Debug 开发签名应用。输入为 [合成夹具](../../../Tests/Fixtures/advanced-outputs/README.md)，范围见 [支持说明](../../advanced-output-previews.md)。

## 自动验证

- [完整 SwiftPM 回归](full-tests.log)：167 项登记，165 通过，2 项专用沙盒 XPC 宿主测试跳过，0 失败。包含真实 React/MDX 效果、Typst/LaTeX PDF、Parquet WASM 解码、SceneKit 网格，以及大权重有界读取、损坏输入、目录权限、取消和关闭释放。
- 完整回归后只调整节点连线端点，使箭头停在形状边界；[最终相关回归](final-advanced-tests.log) 16 项全部通过（9 Core、7 UI）。最终 [Xcode 构建](build.log) 成功。
- [安装](install.log) 至 `/Users/huangzhe/Applications/OrangeLen.app`，刷新扩展注册与 Quick Look；[deep/strict 签名校验](signature.log) 成功。已退出旧主应用并重新启动安装版本。
- [窗口布局修复前](layout-before.log) 可复现图像 intrinsic size 撑宽窗口；[修复后](layout-after.log) 760 / 900 / 1,120 pt 窗口保持目标宽度。最终相关回归也含此检查。
- [资源传输修复前](memory-before.log) 的整套运行在既有大文件 UI 测试触发 512 MiB 进程准入保护。这不是通过记录。改用渲染器私有资源 handler，避免 WASM/字体的 Base64 临时副本，保留原预算；之后完整单进程回归通过。未做 GPU、长时间运行或所有压力场景验收。
- 九个离线 HTML/WASM/字体文件的 SHA-256 已与 [清单](../../advanced-renderer-sha256.json) 核对一致。

日志复制时仅清除行尾空白，原始记录保留在 `/tmp/orangelen-advanced-*.log`。XCTest 统计以 suite 结果为准；尾部 Swift Testing 的“0 tests”不是本次 XCTest 数量。

## Finder 现场验收

以下均为最终安装版本的 **Finder 文件夹 Quick Look**，没有以主应用结果代替 Finder。每项保存截图及对应 AX 文本：

| 内容 | 观察到的结果 | 证据 |
| --- | --- | --- |
| Draw.io | 中文矩形/椭圆/标签/连线完整显示，未被窗口裁切 | [截图](finder-drawio.png)、[AX](finder-drawio.txt) |
| TSX | React 组件显示“React 预览”和数值 42，效果快照可见 | [截图](finder-tsx.png)、[AX](finder-tsx.txt) |
| Typst | PDF 中文标题/正文、数学公式与列表实际排版 | [截图](finder-typst.png)、[AX](finder-typst.txt) |
| Parquet | 三列类型、三行原生表格、筛选入口与样本概要 | [截图](finder-parquet.png)、[AX](finder-parquet.txt) |
| GLB | 三角网格可见，点击右旋后轮廓变化 | [初始](finder-glb.png)、[旋转后](finder-glb-rotated.png)、[AX](finder-glb-rotated.txt) |

其他新增格式由自动解析与 UI 集成回归覆盖，本轮没有对每一种单文件 UTType 的 Finder 分派作现场验收。JPEG/PNG 单文件仍可能由系统处理器接管，生成参数可通过主应用或 Finder 文件夹查看。

本轮没有验证 macOS 14 / Intel 实机、所有字体和第三方扩展、完整 Office 视觉保真、字幕关联播放或 C2PA 签名真实性。离线引擎随七个扩展重复打包，当前 Debug 安装约 616 MiB；未做分发体积优化。
