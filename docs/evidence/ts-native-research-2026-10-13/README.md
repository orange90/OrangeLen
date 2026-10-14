# TS/MTS 原生 Quick Look 研究与实测

2026-10-13 · macOS 26.6.2（25G83）/ Apple M3 Pro。

**本轮没有找到让原始 `.ts` / `.mts` 在 Finder 单选 Space 显示源码的有效方案。106 项目标仍未完成；已验证状态保持 104/106。** 仅研究原生扩展和可恢复的类型/登记配置，没有增加常驻辅助功能或辅助功能权限。不会把改后缀、目录入口、主应用读取或 CLI 强制类型算作通过。

## 其他工具实际怎样处理

| 工具 | 作者说明或源码 | 能否作为本机已解决的证据 |
| --- | --- | --- |
| [Syntax Highlight](https://github.com/sbarex/SourceCodeSyntaxHighlight) | 明确列出 `.ts` / `.mts` 被系统保留，扩展收到文件后才判断文本/二进制 | 不能；作者承认入口限制 |
| [Glance](https://github.com/chamburr/glance#faq) | FAQ 将 `.ts` 列为系统不允许接管的类型 | 不能；该 FAQ 的 plist/XML 描述也带旧系统背景，不能一概套用当前 macOS |
| [Syntax Look](https://www.tentstudios.com/syntaxlook/help/ts-files-preview-as-video) | 2026-09-04 说明 TS/MTS 两用途冲突；系统路由后才有内容检测机会 | 不能；建议 TSX/CTS，不是原始后缀的解决方案 |
| [dotViewer](https://github.com/Stianlars1/dotViewer/blob/ee1ac83ea031917ed598ea863f0b0e0aabc14b6e/KNOWN_ISSUES.md#ki-001--ts-files-routed-as-mpeg-2-transport-stream) | 将 TS 标为平台限制；自定义 UTI、默认打开应用与 PluginKits 都未改变路由 | 不能；其 MTS 可用说法和本机结果不同，不能替代实测 |
| [Pique](https://github.com/macadmins/pique/blob/d46b1ee42245a9b24c5cca61bef7b1126849aebe/PiquePreview/Info.plist) | 列 TS 支持；宿主与扩展导入源码 UTI，扩展列 `com.apple.dt.typescript`、自定义类型和 `QLFileExtensions`。没有声明本机实际 MPEG/AVCHD 类型 | 只能证明作者列出格式；未发现针对系统视频优先级的处理代码或单文件验收证据 |
| [PluginKits](https://github.com/Oil3/PluginKits/blob/9e9cd52a410833c8668b744d93c1d73941cbd546/PluginKits/ConflictResolution.swift) | 调用 pluginkit 调整 election、清理重复扩展和重新登记 | 解决可登记扩展之间的冲突；未发现改变系统内置视频类型判定的接口 |
| [QuickLookVideo](https://github.com/Marginal/QuickLookVideo) | 当前主线使用 Spotlight importer 和 MediaExtension 为视频容器/编解码器增加支持 | 视频解码能力不能直接证明 TypeScript 源码路由已解决 |

Pique、dotViewer、PluginKits 的源码只下载和阅读，未运行其脚本、安装其二进制或执行仓库指令。源码版本见 [source-revisions.tsv](source-revisions.tsv)。对 Pique 的本地实验是在 OrangeLen 中尝试其相关声明方式，不是对 Pique 产品的完整运行测试。

## 本轮新增的原生尝试

| 尝试 | 实际类型与 Finder 结果 | 证据 |
| --- | --- | --- |
| 参考 Pique：在扩展导入 TypeScript UTI、补 Apple TypeScript 类型和 `QLFileExtensions` | TS/MTS 仍是 MPEG/AVCHD，Space 仅基本信息 | [配置](pique-attributes-extension.plist)、[类型](pique-and-tags-types.txt)、TS（本机留档：`pique-attributes-ts.png`）、MTS（本机留档：`pique-attributes-mts.png`） |
| 将 Code 扩展候选扩大到 `public.movie` / `public.audiovisual-content` | TS/MTS 仍基本信息，MP4 仍显示系统 Movie preview | [配置](broad-movie-extension.plist)、TS（本机留档：`broad-movie-ts.png`）、MTS（本机留档：`broad-movie-mts.png`）、MP4（本机留档：`broad-movie-mp4.png`） |
| 在两个新建源码副本设置传统 `TEXT` 文件类型标签 | 原后缀仍判定为 MPEG/AVCHD，Space 仍基本信息 | [类型](pique-and-tags-types.txt)、TS（本机留档：`text-tag-ts.png`）、MTS（本机留档：`text-tag-mts.png`） |
| 宿主导出独立源码类型、文档类型 `LSHandlerRank=Owner`，设置 TS/MTS 后缀的默认应用偏好并重载当前用户 Launch Services | 类型未改变；TS/MTS 仍基本信息。同一稳定安装的 CTS 控制文件可见 OrangeLen 源码 | [配置](owner-tag-app.plist)、[类型](owner-tag-types.txt)、[设置](owner-tag-set.txt)、TS（本机留档：`owner-tag-ts.png`）、MTS（本机留档：`owner-tag-mts.png`）、CTS（本机留档：`owner-tag-control-cts.png`） |

CTS 第一次打开处于冷启动加载中；一次安装替换打断了旧预览连接，出现扩展失败画面（`control-cts.png`）。该画面保留为原始记录，不计为通过。安装稳定后重新打开并等待，`owner-tag-control-cts.{png,txt}` 显示实际源码；随后再复测 TS/MTS，两者仍失败。这能区分“所有扩展都没运行”和“只有视频类型入口未进入”的情况。运行日志见 trial-runtime.log（本机留档：`trial-runtime.log`）。

TEXT 标签只写入 `build/ts-native-research/fixtures/` 中新建的副本；106 项原始样例及用户文件未改写。按后缀的偏好实验保存原记录，清理时仅还原 TS/MTS 的这两项偏好；未把整个 Launch Services 设置重置。

## 旧方案与其他扩展路线

网上旧 QLColorCode 建议向 `.qlgenerator` 添加 MPEG 类型。这与现代 `.appex` 的类型声明是两条实现路线；[Apple macOS 15 发布说明](https://developer.apple.com/documentation/macos-release-notes/macos-15-release-notes)要求迁移已弃用的生成器插件，不能把旧系统的成功报告作为当前 macOS 可交付方案。

[Apple 的 Spotlight 调试文档](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/MDImporters/Concepts/Troubleshooting.html)说明 importer 在系统确定类型后被选择；本机 [mdimport 诊断](spotlight-ts-type.txt)也先将 TS 判定成 MPEG。这没有提供让 Quick Look 在每次 Space 前将源码重新定型的公开接口；本轮没有实现或声称验证一个能覆盖类型的 importer。

[Apple MediaExtension 示例](https://developer.apple.com/documentation/mediaextension/supporting-custom-media-formats-and-decoders)提供的是容器 reader 和视频 decoder，并要求专用 capability / provisioning profile。将源码伪装成视频画面的设想未验证，不能算源码 Quick Look 修复；本轮未注册新 App ID 或授予新的媒体能力。QuickLookVideo 改用 MediaExtension 的事实，也不能推出其解决了 TypeScript 的系统类型冲突。

以上是当前找到的证据与推断，不是对所有 macOS 版本的“永远无法实现”证明，也不是 Apple 对此个案的正式答复。[PreviewCode 作者的同类问题](https://developer.apple.com/forums/thread/796988)仍没有可用于本机的已验证解法。

## 回退与最终状态

- 试验前保存完整签名应用；已恢复 `~/Applications/OrangeLen.app`，[105 个普通文件逐字节与备份一致](restore-file-verification.txt)，deep/strict 验签通过。三个试验应用已取消登记并移入废纸篓，避免以后再次被发现。
- 试验追加的源码 UTI、`QLFileExtensions` 和泛用 movie 候选不在最终包中；[106 类型候选检查](restored-dispatch-106.tsv)仍通过，但不计为内容成功。
- TS/MTS 默认打开关联已恢复，[最终查询](restored-default-apps.txt)与此前一致；[后缀偏好恢复](owner-tag-restore.txt)保留其他用户设置。
- [Hydra election](restored-hydra-state.txt)仍为 ignore，保留前一轮已验证的 STL 原生修复与恢复备份。清理试验副本后有一次登记身份失效；重新登记最终安装路径下的七个扩展后，STL 网格（本机留档：`restored-stl.png`）及 CTS 源码（本机留档：`restored-cts.png`）均重新通过，TS（本机留档：`restored-ts.png`） / MTS（本机留档：`restored-mts.png`）仍仅基础信息。登记状态见 [final-registry.txt](final-registry.txt)，故障日志见 `restore-runtime.log`。
- 本轮没有修改解析器或发布安装包的新功能，不重复运行同一代码的 212 项阅读器测试；前轮 [104/106 合并清单](../single-file-dispatch-2026-10-13/README.md)仍适用。没有把本轮研究计作 106 项全量复测或 TS/MTS 通过。

后续可按[复现记录](reproduction.md)检查同一失败；本轮没有向 Apple 或竞品作者发送消息。
