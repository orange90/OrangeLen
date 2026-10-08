# 边界修复执行与验收状态

2026-10-08，基于 `24a145d` 后的工作区修复。本轮审查列出的 **12 项 P1/P2 均已修复并纳入正式回归**，相关资源隔离、生命周期和产品契约已补齐。保留既有 Finder 分派/键盘取舍、Notebook 连续阅读及目录持续统计要求；未提交或推送。

## 12 项缺陷闭环

以下测试均位于 [BoundaryRegressionTests.swift](../Packages/OrangeLen/Tests/OrangeLenUITests/BoundaryRegressionTests.swift)，运行证据见 [正式测试日志](evidence/boundary-fixes-2026-10-08/tests.log)。断言检查修复后的正确行为；历史审查探针只作来源追溯，未计入本轮通过数。

| 原审查项 | 修复行为 | 正式回归 |
| --- | --- | --- |
| 1 P1 SQLite 生成列 | `table_xinfo` 纳入 VIRTUAL/STORED 列，显式选择列并校验返回字段数；排序/复制与列身份一致 | `testGeneratedColumnsStayAligned`、`testStoredVirtualGeneratedColumnsSortAndTypedCopy` |
| 2 P1 容器错误旧正文 | 请求开始立即清理旧阅读器；加载、错误、空 Notebook 均在可见正文呈现当前文件身份 | `testFailedNotebookClearsOldBody`、`testEmptyNotebookReplacesPreviousBodyAndParentActionsStayVisible` |
| 3 P1 SQLite 查询失败旧页 | 加载时清空已提交页，失败后禁用旧表、翻页和复制 | `testDatabaseFailureClearsPreviousTableData` |
| 4 P1 JSON 路径放大 | 共享父路径节点、按需生成路径；单路径及累计模型预算在创建前检查 | `testJSONPathsShareAncestors` |
| 5 P1 Office 输出预算 | 共享字符串池和正文分别累计计费；每次引用、追加及拼接前检查，跨部件共享正文预算 | `testOfficeSharedStringsObeyOutputBudget` |
| 6 P2 原生 Office 预检 | 拒绝 blocked 条目；所有 ZIP 文件实际展开并校验长度、CRC、路径和预算后才交系统导入 | `testNativeImportEnforcesEntryLimits` |
| 7 P2 分页历史 | 关闭先保存历史；历史窗口仍为 128，始终保留回到开头按钮 | `testClosePreservesSavedPageHistory`、`testHomeRemainsAvailableBeyondHistoryWindowAndEncodingChangesRecover` |
| 8 P2 截断/编码变更恢复 | 重载校验偏移、编码和修订；失效时回首页并说明恢复原因 | `testTruncateRecoversAtStart`、`testHomeRemainsAvailableBeyondHistoryWindowAndEncodingChangesRecover` |
| 9 P2 页内 BOM 保真 | 仅识别文件起始 BOM；避免 Foundation 解码再次隐式丢掉内容 U+FEFF | `testInteriorBOMSurvivesPages`；另有 UTF-16/BOM/代理对测试 |
| 10 P2 子任务取消 | 父取消覆盖容器、数据库、归档、文件夹和系统预览；关闭释放模型/视图/媒体并抑制过期结果 | `testCancelReachesContainerToken`；原生切换/关闭测试 |
| 11 P2 目录取消/重试 | 取消递归清除 loading；目录可重读，统计可独立停止/重启 | `testFolderCancelAllowsRetry`、`testFolderStatisticsStopIndependentlyOfDirectoryReading` |
| 12 P2 归档路径身份 | 规范化后检查重复路径、文件/目录冲突及文件父节点；拒绝静默覆盖 | `testArchivePathAliasesAreRejected` |

## 架构与产品契约闭环

实现说明统一维护于 [当前入口与边界契约](current-contract.md)。下列 Core 回归见 [BoundaryArchitectureTests.swift](../Packages/OrangeLen/Tests/OrangeLenCoreTests/BoundaryArchitectureTests.swift)。

| 项目 | 已落实的边界 | 验证与适用范围 |
| --- | --- | --- |
| 媒体访问 | 经逐段 O_NOFOLLOW 打开的受控 FD 流式读取；拒绝 dataless/特殊文件；逐块核对身份、大小及时间；限制请求数/时间/总读取量；禁止外部媒体引用 | 替换文件/链接回归、原生媒体时长/关闭测试；Finder MP4 播放与切换到 M4A/Markdown 实测 |
| 系统导入隔离 | 独立无网络、无用户文件访问权的 App Sandbox XPC；输入/输出有界；服务导入 5s watchdog 和 RSS 水位；客户端分开控制冷启动握手和导入超时；取消可终止导入 | 原生宿主真实 XPC 测试、Finder DOCX 正文实测；安装包 8 份服务签名权限逐一核验；并非全格式网络抓包证明 |
| 高亮与并发资源 | UI 只应用已缓存 tokens；独立后台有界队列；取消释放待执行闭包；缓存及模型预算、进程 RSS 准入；可用共享目录中用 flock 协调进程 | 队列过载/取消释放、共享锁回收/不可写降级、完整回归及测试进程 RSS 采样；Quick Look 共享文件系统不可写时只能保证进程内上限 |
| 目录续页与负载 | 修订变化拒绝混合页，已加载项统一排序/去重；深度优先持续统计，节流、进度合并、独立停止与重启 | 目录续页变化、超 20,000 项、隐藏项/链接、停止/重启、进度合并回归；Finder 样例统计完成 |
| 设置与清除记录 | CFPrefs 字段级更新，支持共享文件系统不可写时的设置；可写记录存储使用稳定锁/原子身份；跨进程清除代次使活跃会话失效 | 独立设置合并、清除后不能重写、不同记录目录共享清除代次、不可写目录回归；Finder 主题切换成功 |
| 图片授权生命周期 | 文档/修订/目录/owner 绑定；墙钟、包含休眠的连续时钟及 boot UUID 校验；重复授权立即发布；旧 owner 不能撤销新 owner | 回拨、休眠超时、跨启动及重复续约回归；真实云盘/OS 权限撤销另属现场覆盖 |
| 目录/文件包与诊断 | 普通目录优先于扩展名；真实 package 保留系统路径；诊断结果以请求代次防止旧选择覆盖新选择 | 普通 `.png/.mp4` 目录回归；诊断 generation 代码核对 |
| 数据复制与 Office 说明 | SQLite typed cells，SQL 字面量区分 NULL/TEXT/BLOB；无效 UTF-8/NUL 保真；TSV 转义；REAL 保留精度；Office 明示内部顺序/隐藏部件/原始数值及公式缓存 | typed copy、生成列和 REAL/无穷值回归；当前契约和 UI 提示 |
| 状态、入口与无障碍 | 四入口格式矩阵；可见加载/失败/空态和恢复操作；完成/错误 AX 公告；父容器更多操作保留；原生阅读器绘制自身主题背景 | 空态/失败/窄窗/亮暗背景回归；Finder 深浅主题截图观察通过；完整 VoiceOver 听读及多屏未冒充通过 |

现场验收额外发现并修复三项环境相关问题：Quick Look app group URL 可取得但共享目录不可写、XPC 首次建立沙盒容器超过原导入总超时、深色阅读器控件背景透出 Finder 浅色底色。对应降级、冷启动握手和背景绘制均已补回归；最终 Finder 路径重新验证通过。

## 最终验证

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| SwiftPM 完整正式测试 | 123 项登记，121 项执行通过、2 项有说明跳过、0 失败；跳过的两项需要真实 XPC 宿主，已在下一行执行 | [tests.log](evidence/boundary-fixes-2026-10-08/tests.log) |
| 原生宿主测试 | `scripts/test-native.sh`：5 项执行通过、0 跳过、0 失败，含上述两项，夹具随测试包分发；不能与 123 简单相加为独立测试数 | [native-tests.log](evidence/boundary-fixes-2026-10-08/native-tests.log) |
| Xcode 最终构建 | BUILD SUCCEEDED | [build.log](evidence/boundary-fixes-2026-10-08/build.log) |
| 本机开发签名安装 | 已更新 `~/Applications/OrangeLen.app`，deep/strict 验签通过 | [install.log](evidence/boundary-fixes-2026-10-08/install.log) |
| 导入服务权限 | 宿主及 7 个扩展内共 8 份 DocumentBroker，均启用 App Sandbox、无网络/用户文件权限 | [installed-document-sandbox.json](evidence/boundary-fixes-2026-10-08/installed-document-sandbox.json) |
| Finder 现场 | 目录统计、DOCX 正文、MP4 播放进度、M4A 时长、切回 Markdown、深色/系统主题可读；测试后恢复跟随系统 | [现场观察说明](evidence/boundary-fixes-2026-10-08/runtime-observations.md) |
| RSS 采样 | 正式测试进程 111 个样本，观察最高约 401.1 MiB；不是全系统峰值、Finder 冷启动指标或硬上限证明 | [test-rss.json](evidence/boundary-fixes-2026-10-08/test-rss.json) |
| 静态交付检查 | `git diff --check`、脚本 bash 语法和文档本地链接通过 | 本轮命令输出 |

修复验收与发布认证分开：本机为 macOS/Apple Silicon 开发签名环境；第三方云盘、拔盘、完整 VoiceOver/高对比/多显示器、多个 Finder 进程的长期压力及全套编解码器尚无覆盖证据。Developer ID、公证、Gatekeeper 和 Intel/其他 macOS 实机验证未执行，不能用本机通过替代。这些限制已写入当前契约和已知限制，不再作为已支持能力宣传。
