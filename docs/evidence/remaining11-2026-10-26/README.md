# 剩余 11 项：原生分派续查与可选辅助原型

2026-10-26，macOS 26.6.2 (25G83)，Apple Silicon。**本轮新增原生修复 0 项；剩余 11 项仍未解决。** 用户明确限定只接受原生 Quick Look 扩展。

## 优先检查 TS / MTS / DOT

在独立测试副本上尝试设置 `NSURLContentTypeKey`：API 返回成功，但新 URL 查询的实际类型仍分别为 `public.mpeg-2-transport-stream`、`public.avchd-mpeg-2-transport-stream`、`com.microsoft.word.dot`。该返回值不能作为改型成功证据，见 [resource-type-probe.tsv](resource-type-probe.tsv) 与 [探测源码](type-resource-probe.swift)。CoreFoundation SDK 也将旧 TypeIdentifier 资源键标为只读。

随后仅对这三个测试副本写入 Spotlight 的 `kMDItemContentType` / `kMDItemContentTypeTree` 扩展元数据，重新查询的实际类型依旧不变，见 [metadata-type-probe.tsv](metadata-type-probe.tsv)。再次 Finder 单选空格，三者仍只有系统文件信息；接收日志没有进入 OrangeLen。实际回调和窗口证据索引见 [metadata-override.jsonl](metadata-override.jsonl)，日志事件见 provider-events.json。原始用户文件及已安装应用没有改动。

只读检查本机 QuickLook 框架发现：类型→显示提供器的映射在框架初始化时建立；`QLDeactivatedGenerators` 对 Apple 内置生成器有跳过分支，不能照搬 WFLOW 的 PluginKit election 方式。此项仅用作定位线索，没有调用私有 API 修改 Finder、注入系统进程、改写系统文件或写入未验证偏好。原始反汇编只保留本机 build 目录。

Apple 的[原生架构说明](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/Quicklook_Programming_Guide/Articles/QLArchitecture.html)区分内置显示提供器与扩展生成器；它属于历史文档，当前结论以本机实际 Finder 和日志为准。[当前 API](https://developer.apple.com/documentation/quicklook/)支持的 view / data 两种实现均已尝试，不能以候选声明代替真正的接收回调。

## 已放弃的辅助原型

独立构建了 [FinderSpaceHelper 原型源码](prototype/Helper.swift)，复用 OrangeLen 读取器，不改变正式产品或已安装的七个 Quick Look 扩展。构建成功。

- 手动点击演示入口已看到 TS / MTS 源码正文、DOT 的 Input → ONNX model → Preview 图形；日志标为 `source=FinderSpaceHelper trigger=manual-demo`，都有成功回调。
- 这只证明辅助原型的渲染能力，**不是 Finder 空格验收，也不是原生 Quick Look 扩展接管**。
- 设计范围是 Finder 前台、单选目标 11 后缀、无修饰键空格。独立预览窗口明确标注“非系统 Quick Look”；源码中的键盘监听尚未启用。
- 需要用户手动授予辅助功能权限才能读取 Finder 选中项、监听并处理空格。系统权限能力范围大于代码限定范围，必须先明确接受方案；未自动授权、修改 TCC 或添加登录项。
- 关闭辅助程序即可停止，正式启用后仍需验证 Finder 空格、事件来源、三项优先格式与另外八项、关闭/多选/重命名/非 Finder 等行为。当前不承诺该未启用分支已经正常工作。

辅助原型未安装到 Applications 或发布，已退出并注销；可执行 app 已归档，不再处于可发现的 `.app` 路径。

用户明确回复“仍只接受原生 Quick Look 扩展”。辅助原型已退出并注销，未授予或请求辅助功能权限，未启用空格监听。可执行 app 已移出 .app 路径，仅保留本机归档和研究源码；正式应用未加入该组件。后续继续原生研究。

## 专用 OSType 标签原生实测

独立构建签名的原生 `.appex`，宿主导出 `local.orangelen.native-source-label`，仅绑定独有四字符文件类型 `OLSc`，不抢占 TS/MTS 等后缀。所有写标签操作仅发生在新建测试副本。

无后缀控制文件被正确识别为该新类型，Finder 空格出现专属诊断正文，且有 `label-probe received` / `completed success=true`。同样的标签加到其余 11 个原后缀，实际 UTI 均不变；Finder 空格仍由系统提供内容或文件卡片。这排除了“通用 TEXT 标签过于宽泛”的解释。

见 [类型查询](unique-label-types.tsv)、[样例哈希](label-manifest.json)、[逐项结果](native-label-results.json)、[原生扩展源码](native-label-probe/Provider.swift) 及 [宿主/扩展声明](native-label-probe/project.yml)。该扩展用于验证标签选型，不把诊断正文计作正式 OrangeLen 产品修复。

|后缀|Finder 实际显示提供器|最终界面|日志事件|证据|
|---|---|---|---|---|
|`无后缀对照`|`com.apple.qldisplay.Text`|原生标签测试扩展（对照）|21|[AX](unique-label-00-control-ax.txt) / [截图](screenshots/unique-label-00-control.png)|
|`.ts`|`com.apple.qldisplay.Movie`|系统文件信息，未修复|22|[AX](unique-label-01-ts-ax.txt) / [截图](screenshots/unique-label-01-ts.png)|
|`.mts`|`com.apple.qldisplay.Movie`|系统文件信息，未修复|23|[AX](unique-label-02-mts-ax.txt) / [截图](screenshots/unique-label-02-mts.png)|
|`.dot`|`com.apple.qldisplay.PDFKit`|系统文件信息，未修复|24|[AX](unique-label-03-dot-ax.txt) / [截图](screenshots/unique-label-03-dot.png)|
|`.html`|`com.apple.qldisplay.Web2`|系统正文，接管未解决|25|[AX](unique-label-08-html-ax.txt) / [截图](screenshots/unique-label-08-html.png)|
|`.htm`|`com.apple.qldisplay.Web2`|系统正文，接管未解决|26|[AX](unique-label-09-htm-ax.txt) / [截图](screenshots/unique-label-09-htm.png)|
|`.xhtml`|`com.apple.qldisplay.Web2`|系统正文，接管未解决|27|[AX](unique-label-10-xhtml-ax.txt) / [截图](screenshots/unique-label-10-xhtml.png)|
|`.txt`|`com.apple.qldisplay.Text`|系统正文，接管未解决|28|[AX](unique-label-13-txt-ax.txt) / [截图](screenshots/unique-label-13-txt.png)|
|`.pdf`|`com.apple.qldisplay.PDFKit`|系统正文，接管未解决|29|[AX](unique-label-15-pdf-ax.txt) / [截图](screenshots/unique-label-15-pdf.png)|
|`.csv`|`com.apple.qldisplay.Web2`|系统正文，接管未解决|30|[AX](unique-label-16-csv-ax.txt) / [截图](screenshots/unique-label-16-csv.png)|
|`.svg`|`com.apple.qldisplay.Web2`|系统正文，接管未解决|31|[AX](unique-label-17-svg-ax.txt) / [截图](screenshots/unique-label-17-svg.png)|
|`.text`|`com.apple.qldisplay.Text`|系统正文，接管未解决|32|[AX](unique-label-20-text-ax.txt) / [截图](screenshots/unique-label-20-text.png)|

## 清理与恢复检查

原生标签测试扩展已从 PluginKit 注销，测试宿主已从 Launch Services 注销并移出 `.app` 路径；辅助原型同样已退出并注销，始终未启用空格监听或请求辅助功能授权。生产应用及系统文件均未改动。
两处生产 OrangeLen 安装的 deep/strict 签名检查通过。既有 Hydra / Shortcuts 为 ignore、系统桥接为 default，本轮未修改这些偏好。清理后 SQL 再次 Finder 空格显示正式 OrangeLen 控件与正文，`/Applications/OrangeLen.app` 的 Code 扩展接收并成功回调；日志索引见 [provider-events.json](provider-events.json)。
本机生成器按时间窗口复核真实 Finder 提供器和正反例，运行 `python3 docs/evidence/remaining11-2026-10-26/build-report.py` 可重建结构化结果。原始日志、AX、截图仅保留本机。
当前结论仅为这些已测试原生路径在本机失败，不声称所有未来系统或一切可能方案均不可能。没有可交付且符合“原始后缀 + 原生 Quick Look 扩展”要求的新修复。
