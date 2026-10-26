# 371 后缀 Finder 提供器归属审计

2026-10-26，本机 macOS 26.6.2 (25G83) / arm64，当前 Apple Development 开发版，包含当天的 SQL 精确 UTI 修复。

## 结果与完整列表

| 实际结果 | 后缀数 | 判据 |
| --- | ---: | --- |
| OrangeLen 接管 | 350 | 文件名匹配的 OrangeLen 专属控件，同时存在该后缀的扩展接收日志和成功回调 |
| 系统显示内容 | 16 | 非 OrangeLen 的内容界面，同时有该次打开对应的 Finder 系统 displayBundleID 日志 |
| 系统仅文件信息 | 5 | 只有文件名、大小、修改时间，没有正文；无 OrangeLen 回调，不计为预览通过 |
| 合计 | 371 | README 的 371 个不重复后缀全部覆盖 |

完整列表：[Markdown](file-list.md) · [CSV](file-list.csv) · [逐项结构化结果](final-results.json) · [统计](summary.json)。CSV 保留历史归属和本轮归属两列。

系统显示内容的 16 项：`.zsh`, `.bash`, `.html`, `.htm`, `.xhtml`, `.r`, `.proto`, `.txt`, `.log`, `.pdf`, `.csv`, `.svg`, `.diff`, `.patch`, `.text`, `.wflow`。

仅文件信息的 5 项：`.ts`, `.mts`, `.dot`, `.txz`, `.tbz2`。其中 TS/MTS 被识别为 MPEG 传输流并走 Movie 提供器；DOT 与 Word 模板后缀冲突，走系统 PDFKit 路径但未显示图形；TXZ/TBZ2 的实际类型分别为 `org.tukaani.tar-xz-archive` / `public.tar-bzip2-archive`，现有扩展声明未精确覆盖，系统 Generic 只显示文件卡片。

## 方法与证据边界

- 对统一的 371 个编号样例，在真实 Finder 选择文件、按空格打开 Quick Look，并在面板中逐项切换。不是 `qlmanage` 缩略图生成或阅读器单元测试。每项记录完整 AX、实际文件名和时间，不能仅凭正文里出现合成标记“OrangeLen”判定提供器。
- 对 30 个非 OrangeLen 初始界面、加载中画面或测试输入有疑问的项目，独立关闭重开补测，并保留截图。加载中和文件未正确定位的中间状态不作为最终结果。首轮及补测分别保留在 `finder-attempts.jsonl` / `finder-rechecks.jsonl`。
- 同时捕获系统日志，保留 OrangeLen 的 `prepare received extension=OrangeLen type=...` / `prepare completed success=true`，以及 Finder 的 `got displayBundleID ...`。350 项 OrangeLen 界面均有对应后缀的真实回调，未发现本轮将系统界面误判为 OrangeLen 的项目。所有 OrangeLen 进程路径均位于 `/Applications/OrangeLen.app/Contents/PlugIns/`。
- 原始 `runtime.log`、逐项 `*-ax.txt` 和 `screenshots/` 按仓库规则保留本机；精简后的 [provider-events.json](provider-events.json) 保留日志原文、时间、PID、进程路径及事件编号，逐项结果引用编号。系统 Shortcuts 还观察到 Shortcut Editor 界面，进程为系统 Shortcuts.app 的 QuickLookExtension。
- [manifest.json](manifest.json) 给出每项实际样例、来源和 SHA-256；[content-types.tsv](content-types.tsv) 为对真实样例读取的本机 UTI，类型匹配本身不作为实际接管证据。`build-report.py` 校验 371 项不重复、所有文件哈希、所有 AX 文件名，以及 UI 与调用日志一致性后生成报告；它不操作 Finder，也不能替代实测。

**本机原有 Hydra 3D 扩展处于停用状态（`pluginkit` 为 `-`），本轮没有修改该设置。OBJ/STL 的结果适用于这一既有配置，不能宣传成 macOS 默认配置下均由 OrangeLen 接管。** 本轮也没有停用系统文本、Office、Web、PDF 或 Shortcuts 提供器，没有改变默认打开应用。

这是提供器归属审计：源码可只读原文；模型可只显示元数据；归档本轮核对目录入口，不逐一读取所有成员；图形未逐项进行像素或视觉正确性验收。每后缀一个小型合成样例，不是所有方言、版本、损坏文件、大文件或真实项目的兼容性保证。特殊文件名和目录入口不在 371 后缀口径中。

## 发现的历史缺口与测试输入修正

以前的记录来自不同日期和构建，没有同一次 371 项的提供器双重验证。初始清单明确分出 341 项历史 OrangeLen、24 项历史系统预览、3 项仅基本信息和 3 项无独立 Finder 记录：[initial-inventory.md](initial-inventory.md)。旧的 106 项记录本身就把 `.sql` 等列为系统预览，不能把阅读器通过率或类型匹配率当作 OrangeLen 的 Finder 接管率。

本轮 8 项旧系统预览（JS/MJS/H/HPP/Java/PHP/Ruby/SQL）已实测进入 OrangeLen；3 个此前没有独立 Finder 记录的归档别名中，TZST 进入 OrangeLen，TXZ/TBZ2 暴露分派遗漏。历史状态仍保留，未用本轮结果改写旧记录。

首轮复用的 XHTML 是通用纯文本，不是有效 XHTML；补测改用有效 XHTML。首轮压缩 TAR 样例被统一命名为 `.xz` / `.bz2` / `.zst`，没有保留产品约定的 `.tar.xz` / `.tar.bz2` / `.tar.zst`，触发解析报错；补测恢复完整名称后均由 OrangeLen 正常打开。原始失败、原始清单和修正原因分别保留在首轮 AX、[first-pass-manifest.json](first-pass-manifest.json) 和 [fixture-corrections.json](fixture-corrections.json)，不把测试输入问题冒充为产品修复。

本轮没有修改产品分派或解析器；没有提交、推送或更新公开 V1.0 安装包。当前本机已含 SQL 修复，因此不能将本表直接当作公开下载包的实测结果。Intel 和其他 macOS 版本未在本轮测试。
