# SQL 单文件预览修复

2026-10-26，macOS 26.6.2 / Apple Silicon，本机 Apple Development 开发构建。

## 问题与改动

本机 `.sql` 的实际 UTI 为 `org.iso.sql`，继承 `public.plain-text` 和 `public.source-code`。这只是本机注册表的结果，未核实注册来源，不代表系统内置类型或干净系统也有该注册。此前 Code 扩展只有这些上层类型，Finder 实测选择 Apple 文本预览；10:02:28 日志返回 `displayBundleID com.apple.qldisplay.Text`。

在源码格式注册表增加 `org.iso.sql`，通过 `scripts/sync-source-formats.py` 同步 `project.yml` 并用 XcodeGen 生成扩展 Info.plist。SQL 已有语言识别及语法库，无需改变解析器。未增加格式数量、改变默认打开应用或停用系统提供器。

## 验收

- `SyntaxHighlighterTests` 5 项及 `FormatInventoryAuditTests/test_sql` 1 项，共 6 项零失败。SQL 测试确认关键字和字符串区分、中文及注释保留，应用颜色后原文一致；阅读器覆盖单文件及文件夹两入口。
- Debug 应用构建通过；保留原 `JR39NPKJK6.local.OrangeLen.shared` 共享组，用已有 Apple Development 身份签名，更新 `~/Applications/OrangeLen.app` 与 `/Applications/OrangeLen.app`；两处 deep/strict 验签通过。旧安装备份在 `build/install-backups/sql-20261026/`。
- 在真实 Finder 对修复前同一个 `/tmp/OrangeLen-SQL-preview-test.sql` 按空格。看到 OrangeLen 工具栏、行号和完整正文；CREATE/INSERT/SELECT 等关键字蓝色，注释绿色，中文字符串红色。
- 10:08:00，`OrangeLenPreview` 进程 65073 明确记录 `prepare received extension=OrangeLen type=sql`、`prepare completed success=true`；其进程路径为 `/Applications/OrangeLen.app/Contents/PlugIns/OrangeLenPreview.appex/Contents/MacOS/OrangeLenPreview`。据此确认实际调用 OrangeLen，不能仅凭可见正文判断。

本机证据：`finder.png`、`finder-ax.txt`、`quicklook.log`、`tests.log`（按仓库规则忽略截图与原始日志）。构建和安装日志在 `/tmp/orangelen-sql-{build,install}.log`。测试样例仅预览，不执行 SQL。

本轮仅更新本机开发安装；未提交、推送或更新公开安装包。其他 macOS 版本与 Intel 机器未实测。

## Issue #2：干净系统的注册缺口

[Issue #2](https://github.com/orange90/OrangeLen/issues/2) 报告 macOS 27.0.1 上 `UTType("org.iso.sql")` 为 nil、`.sql` 仍解析成动态类型。核对源码确认 V1.0.1 只有 Code 扩展声明 `org.iso.sql`，主应用没有导出任何包含 `.sql` 后缀的类型。上面的本机 Finder 记录仍成立，但不足以证明安装包在干净系统可用。

后续现场溯源确认：本机 `lsregister -dump` 中 `org.iso.sql` 的有效类型声明标记为 `bundle: Xcode`、`active`、`imported`；`/Applications/Xcode.app/Contents/Info.plist` 的 `UTImportedTypeDeclarations` 确实将 `.sql` 映射至 `org.iso.sql`，继承 `public.source-code`。因此本机安装的 Xcode 提供了 OrangeLen 遗漏的类型登记，掩盖了安装包的独立注册缺陷。双方系统版本不同，但尚无证据证明该缺陷由系统版本变化导致；也未核实报告者的 Xcode 安装情况。

本次将 `sql` 加入 `SourceCodeFormats.json` 的 `groups.sql`，再运行同步脚本及 XcodeGen，使主应用导出的 `local.orangelen.developer-source` 包含 `.sql`，并继承 `public.source-code`。Code 扩展已有该类型，同时保留 `org.iso.sql` 兼容已注册此别名的机器。读取和高亮逻辑无需改动，支持格式总数仍为 371。

回归测试直接检查生成的主应用与 Code 扩展 Info.plist、SQL 语言映射，不读取本机 UTType 注册表，避免其他软件掩盖缺失声明。修复前该测试因 SQL 映射及导出后缀缺失而失败。干净 macOS 27 的 Finder 实机验收仍需在对应环境执行；此前本机结果不替代该验证。

本次验证：

- `scripts/sync-source-formats.py --check` 通过；主应用及扩展 plist 格式检查通过。
- `./scripts/test.sh --filter 'SourceParityTests|SourceParityPreviewTests|SyntaxHighlighterTests|FormatInventoryAuditTests.test_sql$'`：14 项通过，1 项需原生宿主的编译 AppleScript 测试按条件跳过，零失败。覆盖注册链路、全部 220 个注册表后缀读取、语言高亮及 SQL 两种阅读入口。
- `./scripts/build.sh CODE_SIGNING_ALLOWED=NO` 成功；核对实际 Debug `.app` 的导出后缀、源码继承、Code 扩展支持类型及共享资源框架内的 SQL 注册表均通过。本地记录为 `build/issue-2-{regression-before,tests,build}.log` 和 `build/issue-2-product-check.json`。
- 本次未安装到日常应用目录、发布新安装包或执行干净 macOS 27 Finder 验收。
