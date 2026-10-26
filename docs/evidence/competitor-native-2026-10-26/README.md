# 其他 Quick Look 插件的原生路由调查

日期：2026-10-26。机器：macOS 26.6.2 (25G83)，Apple Silicon。

用户要求先提交，再调查其他插件如何处理剩余 11 种文件，优先 TS/MTS/DOT；继续限定为原生 Quick Look 扩展，并用 Finder 空格和调用日志确认。

## 本轮结论

- 已先提交此前工作：`cf2a2beecafbcfff0c3472fabbe9d25ce449dafa`。该提交包括精确 UTI 修复、测试及此前 Finder 审计证据，未推送。
- 阅读多款插件的官方源码、说明及平台限制，实际运行两款原生插件作对照：Pique 当前源码本地构建、dotViewer v1.5.8 官方签名发布版。两款均先用各自专属格式验证入口和正文，再各测全部 11 个原始后缀，合计 22 项目标测试。
- 两款在本机均未接管这 11 个样例；TS/MTS/DOT 仍只有系统基本信息，另外 8 项仍由系统显示正文。目标时间窗口内没有 Pique、dotViewer 或 OrangeLen 的预览请求入口。
- **本轮新增通过验收的原生修复：0 项。** 发现的实现均未提供此前缺少且能在本机绕过系统分派的方法，没有将无效声明补丁加入产品。

此结论只覆盖已读实现和本机实测，不是对所有未来 macOS 或一切原生方案的“不可能”证明。没有重跑全部 371 项；此前 360/8/3 仍是叠加后的推算，不是本轮全量结果。

## 其他插件实际采用什么办法

|项目与一手资料|观察到的办法与限制|对 OrangeLen 的意义|
|---|---|---|
|[SourceCodeSyntaxHighlight](https://github.com/sbarex/SourceCodeSyntaxHighlight)|使用精确 UTI 和别名处理不同应用的注册差异；官方明确标注 TS/MTS 的系统保留冲突。|精确注册已经解决我们此前 9 项；不能从它的语言列表推断 TS/MTS Finder 接管成功。|
|[dotViewer 已知问题](https://github.com/Stianlars1/dotViewer/blob/ee1ac83ea031917ed598ea863f0b0e0aabc14b6e/KNOWN_ISSUES.md)|承认 TS、HTML 系统优先；同时声称 MTS 可用。发布版声明 AVCHD、MPEG、Word DOT 等精确类型，并在收到请求后识别真实二进制传输流。|MTS 是需要实测的差异；本机官方签名版仍走系统 Movie。内容识别没有机会在请求到来前执行。|
|[Pique](https://github.com/macadmins/pique/blob/8931c8a4f6fa94e1e1cff2e5e5a7b5e761141b0c/README.md)|当前源码新增 TypeScript 支持，声明自有 TypeScript 和 Apple 开发工具 UTI；视图式原生扩展。|本地对照格式调用成功；原始 TS 未收到请求。它没有宣称 MTS/DOT 或这些所有系统格式均可接管。|
|[Syntax Look 官方帮助](https://www.tentstudios.com/syntaxlook/help/ts-files-preview-as-video)|解释 TS/MTS 与视频后缀冲突；文本/二进制识别也只发生在系统把文件交给扩展之后。|与本机入口日志的观察相符，没有额外公开的原生优先级接口。|
|[QLOmni 设计记录](https://github.com/j-256/qlomni/blob/main/DESIGN.md)|结合类型声明让很多格式进入系统文本预览，另用原生扩展补充；明确记录系统显示器先处理 TS 等类型的问题。|“安装后能看正文”仍可能是系统文本提供器，不能算该插件真实回调。|
|[QLStephenSwift](https://github.com/MyCometG3/QLStephenSwift/blob/main/README.md)、[Glance](https://github.com/chamburr/glance/blob/main/README.md)|分别侧重无后缀补充、代码预览；公开说明系统类型的优先限制。Glance 的 TSV 支持不能当成 CSV 支持。|没有找到这些原始后缀在当前系统上的优先级修复。未安装这两款，不宣称作过二进制实测。|
|[QuicklookDot 声明](https://github.com/besi/quicklook-dot/blob/master/Info.plist)与[生成入口](https://github.com/besi/quicklook-dot/blob/master/GeneratePreviewForURL.m)|旧 `.qlgenerator` 同时声明 Graphviz 与 `com.microsoft.word.dot`，入口收到文件后生成 PDF。|不是只差 Word DOT 声明；OrangeLen 已测过该精确类型。旧架构源码不证明当前 macOS 原生 `.appex` 能抢回 DOT，未安装旧插件。|
|[QuickLookCSV](https://github.com/p2/quicklook-csv/blob/master/README.md)|旧 `.qlgenerator` 架构。|不能将旧系统成功案例直接外推到 macOS 26。|
|[QuickLookVideo](https://github.com/Marginal/QuickLookVideo/blob/master/README.md)|当前媒体处理采用 Spotlight/Media Extension 等路径。|视频解码能力不等于把源码 TS/MTS 交给代码预览扩展。|
|[spacebar](https://spacebar.patebryant.com/)|对部分系统优先类型提供可选辅助功能组件。|属于用户明确拒绝的辅助路线，未安装、未运行或授权。|

Apple 当前[文档](https://developer.apple.com/documentation/quicklook/)公开了视图式和数据式扩展及 `QLSupportedContentTypes`，未给出让第三方强制覆盖系统显示路径的优先级开关。两种扩展形态我们均有真实成功对照；不能把缺少请求误判为阅读器或高亮器未实现。

## TS、MTS、DOT 的重点核对

### TS / MTS

dotViewer 的实际发布包声明包含 `public.mpeg-2-transport-stream` 和 `public.avchd-mpeg-2-transport-stream`。其源码还导出 TypeScript 类型，并在 `PreviewContentBuilder.build` 中记录 `Preview request` 后才检查内容。这与此前尝试过的“精确媒体 UTI + 自有源码类型 + 内容检测”没有分派层面的新增机制。

真实 Finder 空格中，TS 和 MTS 均先返回 `com.apple.qldisplay.Movie`，随后退到信息卡；两款插件都没有对应入口日志。dotViewer 已知问题中“MTS 可用”的文字与这台 Mac 的结果不一致，记录为机器/版本条件下的失败，未据此声称对方项目全面失效。

### DOT

本机 DOT 仍由 Word 模板类型对应的系统 PDFKit 路径处理。旧 QuicklookDot 已声明 Word DOT 类型，收到请求以后才调用 Graphviz；现代 dotViewer 发布包也声明了 `com.microsoft.word.dot`，但本机仍没有收到该样例的预览请求。再增加同一个声明或替换图形引擎，都没有本轮证据支持其能解决分派。

## Finder 空格逐项结果

Pique 与 dotViewer 分别注册、启用并单独测试；OrangeLen 既有扩展保持原状。Pique 测完已注销，才注册 dotViewer。未启动 dotViewer 宿主应用或其可选键盘辅助功能。

|原后缀|两次目标测试中的系统显示 bundle|两次最终界面|两款插件目标请求|
|---|---|---|---|
|`.ts`|`com.apple.qldisplay.Movie`|仅基本信息|均无|
|`.mts`|`com.apple.qldisplay.Movie`|仅基本信息|均无|
|`.dot`|`com.apple.qldisplay.PDFKit`|仅基本信息|均无|
|`.html`|`com.apple.qldisplay.Web2`|系统网页正文|均无|
|`.htm`|`com.apple.qldisplay.Web2`|系统网页正文|均无|
|`.xhtml`|`com.apple.qldisplay.Web2`|系统网页正文|均无|
|`.txt`|`com.apple.qldisplay.Text`|系统文本正文|均无|
|`.pdf`|`com.apple.qldisplay.PDFKit`|系统 PDF 正文|均无|
|`.csv`|`com.apple.qldisplay.Web2`|系统表格正文|均无|
|`.svg`|`com.apple.qldisplay.Web2`|系统图形正文|均无|
|`.text`|`com.apple.qldisplay.Text`|系统文本正文|均无|

Pique 没有宣称所有这些类型都属于其支持范围，dotViewer 发布包也未直接声明 PDF；这些测试是查找替代原生路线，不把未宣称的格式记为产品缺陷。

**不能仅凭 Web2 判定是谁生成了预览。** dotViewer 的 MUD 对照同样最终使用系统 Web2 显示，但同时有它自己的 `Preview request`、高亮成功及 `HTML built`；因此确认是 dotViewer 生成正文。原始 11 项则缺少两款插件和 OrangeLen 的入口日志，且显示内容与系统预览一致。Pique 的 VPP Token 对照也有入口和成功回调，证明不是插件未运行导致的假阴性。

## 构建与版本边界

- Pique：源码 `8931c8a4f6fa94e1e1cff2e5e5a7b5e761141b0c`，2026-10-16。Xcode Debug 本地构建，保留渲染与类型声明，仅加入口/完成日志；[补丁](pique-logging-only.patch)。使用本机开发签名，签名权限为 sandbox 与用户选中文件只读，去除不属于本开发者的 App Group。**不是官方发布二进制实测**。专属 `.vpptoken` 正文及成功回调通过，降低签名或启动失败造成误判的风险。
- dotViewer：官方 v1.5.8 DMG，2026-09-23 发布；SHA-256 为 `1e3dbc6314036a1eaff4cebfd659335251b6041f55efca96e9147837352bdaa3`，与发布资产摘要一致。官方 Developer ID Team `7F5ZSQFCQ4`，deep/strict 验签通过，未重签或改二进制。源码分析的 main 为 `ee1ac83ea031917ed598ea863f0b0e0aabc14b6e`；发布包类型声明另从实际 Info.plist 提取，未将 main 当成发布包的精确源码。
- 两款都只读取新建的合成测试文件；目标 11 项副本与前轮样例字节一致并记录 SHA-256，保留原始后缀。对照文件不是通过改后缀来冒充目标修复。

## 清理和生产回归

两款对照扩展和宿主均已注销，可执行包移出可发现的 `.app` 路径；只读 DMG 已卸载。比较前后所有 26 个原生预览扩展的标识、UUID 和 election 完全一致，既有 Hydra/Shortcuts ignore 和系统桥接 default 均未改。未加入辅助组件或申请辅助功能权限。

清理后再次用 Foundation 查询三个测试文件的实际类型，分别恢复/保持为 MPEG、AVCHD 和 Word DOT，见 [类型记录](restored-file-types.tsv)。没有遗留本轮竞品测试进程。

清理后 SQL 在真实 Finder 空格显示 OrangeLen 工具栏、行号、蓝色 SQL 关键词、绿色注释、红色中文字符串；11:56:39 日志确认 `/Applications/OrangeLen.app` 的 Code 扩展收到 `type=sql` 并成功完成。两处生产安装均通过 deep/strict 验签。本轮未修改产品代码或公开安装包。

## 可复核证据

- [22 项逐项列表及 AX/截图索引](file-list.md)
- [结构化结果](results.json)、[两个竞品和 SQL 正反对照](controls.json)、[摘要](summary.json)
- [带进程路径的日志事件索引](provider-events.json)
- [样例路径与 SHA-256](manifest.json)、[实验构建元数据](experiment.json)
- [Pique 实际声明](pique-declarations.json)、[dotViewer 实际声明](dotviewer-declarations.json)
- [生成与断言脚本](build-report.py)：校验每个样例哈希、真实 Quick Look 窗口、目标窗口内零入口、两个竞品成功对照、SQL 成功回调和 26 项注册表恢复。

执行 `python3 docs/evidence/competitor-native-2026-10-26/build-report.py` 可从本机原始日志、AX 和截图索引重建。原始日志、AX、截图、下载包及构建产物按仓库规则不入 Git；表格和 JSON 结果保留供代码审阅。
