# SQL 单文件预览修复

2026-10-26，macOS 26.6.2 / Apple Silicon，本机 Apple Development 开发构建。

## 问题与改动

本机 `.sql` 的实际 UTI 为 `org.iso.sql`，继承 `public.plain-text` 和 `public.source-code`。此前 Code 扩展只有这些上层类型，Finder 实测选择 Apple 文本预览；10:02:28 日志返回 `displayBundleID com.apple.qldisplay.Text`。

在源码格式注册表增加 `org.iso.sql`，通过 `scripts/sync-source-formats.py` 同步 `project.yml` 并用 XcodeGen 生成扩展 Info.plist。SQL 已有语言识别及语法库，无需改变解析器。未增加格式数量、改变默认打开应用或停用系统提供器。

## 验收

- `SyntaxHighlighterTests` 5 项及 `FormatInventoryAuditTests/test_sql` 1 项，共 6 项零失败。SQL 测试确认关键字和字符串区分、中文及注释保留，应用颜色后原文一致；阅读器覆盖单文件及文件夹两入口。
- Debug 应用构建通过；保留原 `JR39NPKJK6.local.OrangeLen.shared` 共享组，用已有 Apple Development 身份签名，更新 `~/Applications/OrangeLen.app` 与 `/Applications/OrangeLen.app`；两处 deep/strict 验签通过。旧安装备份在 `build/install-backups/sql-20261026/`。
- 在真实 Finder 对修复前同一个 `/tmp/OrangeLen-SQL-preview-test.sql` 按空格。看到 OrangeLen 工具栏、行号和完整正文；CREATE/INSERT/SELECT 等关键字蓝色，注释绿色，中文字符串红色。
- 10:08:00，`OrangeLenPreview` 进程 65073 明确记录 `prepare received extension=OrangeLen type=sql`、`prepare completed success=true`；其进程路径为 `/Applications/OrangeLen.app/Contents/PlugIns/OrangeLenPreview.appex/Contents/MacOS/OrangeLenPreview`。据此确认实际调用 OrangeLen，不能仅凭可见正文判断。

本机证据：`finder.png`、`finder-ax.txt`、`quicklook.log`、`tests.log`（按仓库规则忽略截图与原始日志）。构建和安装日志在 `/tmp/orangelen-sql-{build,install}.log`。测试样例仅预览，不执行 SQL。

本轮仅更新本机开发安装；未提交、推送或更新公开安装包。其他 macOS 版本与 Intel 机器未实测。
