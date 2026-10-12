# 共享资源与 Release 包体

2026-10-12。用户要求先保存功能基线，再去掉重复资源；不得缩减任何已有格式、入口或能力。基线提交为 `d70f6a3`（`feat: add advanced AI output format previews`），未推送。

## 打包结构

主应用的 `Contents/Frameworks/OrangeLenResources.framework` 保留唯一一份渲染器、WASM、字体和中英文词条。主应用、七个 Quick Look 扩展和两种 XPC 服务通过标准动态链接和 Objective-C anchor 查找这个 framework。扩展和嵌套 XPC 分别保留正确的相对 rpath；不依赖固定安装路径，不要求先启动主应用，不创建额外资源缓存，不下载资源。

纯 SwiftPM 运行和测试仍保留原模块资源查找。格式分派、原始内容/源码、WebKit 私有资源白名单、文件授权、网络规则和解析预算保持既有范围。

构建结束后执行 [deduplicate-resources.py](../scripts/deduplicate-resources.py)：逐项核对 framework 和全部 SwiftPM 副本的资源清单及内容，全部一致后才移除副本，再重签受影响的 framework/XPC/扩展。引擎、字体按原字节 SHA-256 比较；编译过的 `.strings` 按完整键值字典比较，兼容编译编码和 `.lproj` 大小写差异。任何缺失、额外文件、内容不符或异常链接都会使构建失败。

旧结构包含 8 份 UI 资源包、23 份 Core 资源包。本轮移除全部 31 个 SwiftPM 包副本，保留一个资源 framework。framework 内的标准 `Versions` 链接只服务于 macOS framework 结构；没有用资源文件链接或硬链接伪装去重。

[install-dev.sh](../scripts/install-dev.sh) 先在临时目录完成签名和校验，再替换整包，避免 `ditto` 合并旧安装后复活已删除的副本。正式打包脚本也补齐 framework 的 Developer ID 签名顺序；本轮仅本机开发签名验收，没有发布或执行公证。

## 体积口径

按实际文件逻辑字节计，排除 framework 目录别名的重复计数；MiB = 1,048,576 字节。下载 ZIP 和 Finder 显示的十进制 MB 是不同口径。最终测量及原始日志见 [验收证据](evidence/resource-packaging/README.md)。

| 版本 | 包体 |
| --- | ---: |
| 原安装 Debug / Apple Silicon | 614.87 MiB |
| 去重前通用 Release / arm64 + x86_64 | 666.91 MiB |
| 去重后通用 Release / arm64 + x86_64 | 约 268.5 MiB |
| 去重后 Apple Silicon Release | 约 159.9 MiB |

通用 Release 同架构比较节省约 398 MiB。Apple Silicon 版相对原安装减少约 74%；通用版仍保留 Intel 架构，未通过删除架构冒充资源去重。原生二进制和 XPC 隔离结构没有在本轮改成共享实现，因此通用版并非“最小可能体积”。

## 验收中修复的既有问题

- Intel 不提供本轮使用的 Swift `Float16` 接口。改用等价 IEEE binary16 → binary32 位解析，保留 NPY/CBOR 半精度能力；Apple Silicon 测试逐一比较全部 65,536 个位模式，通用 Release 编译通过。
- 空 Notebook 异步生成空白正文。改为明确空内容提示；回归先打开有内容的 Notebook，再等待空文档的最终状态，避免把加载提示当成完成。
- LaTeX 数学字母在 PDF 中缺失：保留随包内嵌字体的数据 URL，并在生成 PDF 前强制布局、等待实际字体加载。增加 PDF 数学字母内容检查。修正后的 LaTeX HTML 为唯一主动更新的资源，版本不变，其余引擎和字体保持原字节；没有减少任何资源文件。

直接从父应用查找普通资源 bundle 的初稿在 Finder 中失败，曾触发默认 SwiftPM accessor 崩溃及源码降级；已恢复基线后改用标准嵌入 framework。失败记录保留，不把主应用成功或 SwiftPM 成功视为 Finder 验收。framework 设计依据 [Apple 共享嵌入 framework 指南](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html)。

## 重建与核验

```sh
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project OrangeLen.xcodeproj -scheme OrangeLen -configuration Release \
  -derivedDataPath build/Release ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY=- build
/usr/bin/python3 scripts/deduplicate-resources.py \
  build/Release/Build/Products/Release/OrangeLen.app --verify-only
```

Apple Silicon 单架构使用 `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES`。源资源仍在 SwiftPM `Resources` 中，由 Xcode framework 的资源阶段复用；没有删源文件、删语言、删引擎或删格式声明。SDK/Xcode 版本、签名和架构会影响二进制大小。
