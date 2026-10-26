# 剩余 21 种文件：修复与 Finder 验收

2026-10-26，本机开发版，macOS 26.6.2 (25G83) / Apple Silicon。

**10 种已由 OrangeLen 接管并显示正文或归档目录/成员；11 种尚未解决。原先没有正文的 5 种中修复了 TXZ、TBZ2，TS、MTS、DOT 仍只有系统文件卡片。不能称为 21 种全部修好。**

最终 21 项均逐个在 Finder 选中并按空格，核对实际窗口文件名、OrangeLen 专属控件、扩展接收及成功回调。10 项 OrangeLen 回调进程均来自 `/Applications/OrangeLen.app`，没有以系统正文冒充 OrangeLen 的项目。

## 实施的修复

- Code 扩展补充本机精确类型：`public.zsh-script`、`public.bash-script`、`com.apple.rez-source`、`public.protobuf-source`、`com.apple.log`、`public.patch-file`。覆盖 ZSH/BASH/R/PROTO/LOG/DIFF/PATCH；读取器按后缀选择语言，R 不按系统 Rez 类型渲染。
- Archives 补充 `org.tukaani.tar-xz-archive`、`public.tar-bzip2-archive`，覆盖 TXZ/TBZ2。两者都实际选择 README.md，正文含中文及表情，见本机成员截图/AX。
- 同步 `public.xhtml` 声明后本机仍走系统 Web2，未计作修复成功。
- WFLOW 通过可恢复的用户扩展偏好接管，显示二进制 plist 转 XML 的动作正文；不执行工作流。

## WFLOW 设置与恢复

当前已启用 OrangeLen 偏好。Apple 的同一扩展也处理 `.shortcut`，因此其系统动作卡片预览同时被停用。启用前的 `default` 已保存在 `~/Library/Application Support/OrangeLen/workflow-preview-election`。已实测启用 → OrangeLen、恢复 → 系统、再次启用 → OrangeLen。

```bash
./scripts/prefer-workflow-preview.sh status
./scripts/prefer-workflow-preview.sh restore
```

这项设置不是安装包自动修复；其他用户仍须自行选择。原有 Hydra 设置保持不变，临时系统桥接设置已恢复。

## 仍未解决的原生分派

- TS/MTS：实际 UTI 是 MPEG/AVCHD 传输流，Finder 选择 Movie，未调用 OrangeLen。DOT：与 Word 模板冲突，选择 PDFKit，仅文件信息。
- HTML/HTM/XHTML/CSV/SVG：选择系统 Web2；TXT/TEXT：选择系统 Text；PDF：选择系统 PDFKit。它们能显示系统正文，但没有本轮 OrangeLen 接收回调。
- 为排除扩展实现方式影响，独立构建 Apple `QLPreviewProvider` / `QLPreviewReply` 数据式扩展。控制后缀 `.orangeprobe` 出现专属诊断正文及接收/成功日志；12 个原阻塞后缀均没有调用此扩展。测试扩展随后注销，不计入正式修复。
- 临时停用系统 QLPreviewGenerationExtension 后，TS/TXT/CSV 仍不改变分派；已恢复原来的 default。现有公开原生路径下尚未找到经本机验证可接管这 11 项的方法；本报告不声称平台永久不可能。

## 逐项结果

事件编号见 [provider-events.json](provider-events.json)，详细字段/样例 SHA256 见 [final-results.json](final-results.json)。AX、原始日志及截图按仓库规则保留本机。

|后缀|修复前|最终实际提供器|正文检查|调用日志事件|Finder 证据|
|---|---|---|---|---|---|
|`.ts`|系统仅基本信息|系统 Movie|仍无正文，未修复|69|[AX](final-01-ts-ax.txt) / [截图](screenshots/final-01-ts.png)|
|`.mts`|系统仅基本信息|系统 Movie|仍无正文，未修复|70|[AX](final-02-mts-ax.txt) / [截图](screenshots/final-02-mts.png)|
|`.dot`|系统仅基本信息|系统 PDFKit|仍无正文，未修复|71|[AX](final-03-dot-ax.txt) / [截图](screenshots/final-03-dot.png)|
|`.txz`|系统仅基本信息|OrangeLen|目录及 README.md 成员正文均已实际打开|73, 74|[AX](final-04-txz-ax.txt) / [截图](screenshots/final-04-txz.png)|
|`.tbz2`|系统仅基本信息|OrangeLen|目录及 README.md 成员正文均已实际打开|76, 77|[AX](final-05-tbz2-ax.txt) / [截图](screenshots/final-05-tbz2.png)|
|`.zsh`|系统内容预览|OrangeLen|OrangeLen 正文区域包含样例源码/日志/差异内容|79, 80|[AX](final-06-zsh-ax.txt) / [截图](screenshots/final-06-zsh.png)|
|`.bash`|系统内容预览|OrangeLen|OrangeLen 正文区域包含样例源码/日志/差异内容|82, 83|[AX](final-07-bash-ax.txt) / [截图](screenshots/final-07-bash.png)|
|`.html`|系统内容预览|系统 Web2|正文由系统提供，OrangeLen 接管未解决|84|[AX](final-08-html-ax.txt) / [截图](screenshots/final-08-html.png)|
|`.htm`|系统内容预览|系统 Web2|正文由系统提供，OrangeLen 接管未解决|85|[AX](final-09-htm-ax.txt) / [截图](screenshots/final-09-htm.png)|
|`.xhtml`|系统内容预览|系统 Web2|正文由系统提供，OrangeLen 接管未解决|86|[AX](final-10-xhtml-ax.txt) / [截图](screenshots/final-10-xhtml.png)|
|`.r`|系统内容预览|OrangeLen|OrangeLen 正文区域包含样例源码/日志/差异内容|88, 89|[AX](final-11-r-ax.txt) / [截图](screenshots/final-11-r.png)|
|`.proto`|系统内容预览|OrangeLen|OrangeLen 正文区域包含样例源码/日志/差异内容|91, 92|[AX](final-12-proto-ax.txt) / [截图](screenshots/final-12-proto.png)|
|`.txt`|系统内容预览|系统 Text|正文由系统提供，OrangeLen 接管未解决|93|[AX](final-13-txt-ax.txt) / [截图](screenshots/final-13-txt.png)|
|`.log`|系统内容预览|OrangeLen|OrangeLen 正文区域包含样例源码/日志/差异内容|95, 96|[AX](final-14-log-ax.txt) / [截图](screenshots/final-14-log.png)|
|`.pdf`|系统内容预览|系统 PDFKit|正文由系统提供，OrangeLen 接管未解决|97|[AX](final-15-pdf-ax.txt) / [截图](screenshots/final-15-pdf.png)|
|`.csv`|系统内容预览|系统 Web2|正文由系统提供，OrangeLen 接管未解决|99|[AX](final-16-csv-ax.txt) / [截图](screenshots/final-16-csv.png)|
|`.svg`|系统内容预览|系统 Web2|正文由系统提供，OrangeLen 接管未解决|100|[AX](final-17-svg-ax.txt) / [截图](screenshots/final-17-svg.png)|
|`.diff`|系统内容预览|OrangeLen|OrangeLen 正文区域包含样例源码/日志/差异内容|102, 103|[AX](final-18-diff-ax.txt) / [截图](screenshots/final-18-diff.png)|
|`.patch`|系统内容预览|OrangeLen|OrangeLen 正文区域包含样例源码/日志/差异内容|105, 106|[AX](final-19-patch-ax.txt) / [截图](screenshots/final-19-patch.png)|
|`.text`|系统内容预览|系统 Text|正文由系统提供，OrangeLen 接管未解决|107|[AX](final-20-text-ax.txt) / [截图](screenshots/final-20-text.png)|
|`.wflow`|系统内容预览|OrangeLen|二进制 plist 转 XML，动作及中文正文可读；依赖 Shortcuts 偏好设置|109, 110|[AX](final-21-wflow-ax.txt) / [截图](screenshots/final-21-wflow.png)|

## 验证范围

相关 21 项内部测试通过，Debug 构建成功；`~/Applications` 与 `/Applications` 两处安装均通过 deep/strict 签名检查。内部测试仅证明读取器，不替代上表 Finder 证明。
本轮重新检查的是剩余 21 项。与先前 350 项记录叠加得到 360 / 8 / 3；这不是新版本全部 371 项重新运行的结果。公开 V1.0 安装包未更新，Intel、其他 macOS、任意文件及完整格式规范未在本轮验收。
原始 371 审计报告保留当时 350 / 16 / 5 快照，不改写历史结果。
