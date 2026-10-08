# 运行与发布验收

构建下限 macOS 14，不代表已经在 14 运行。2026-10-04 的本机证据只有 macOS 26.6.2 / M3 Pro；通用 Release 交叉编译不等于 Intel 实测。

## 自动化矩阵

`.github/workflows/compatibility.yml` 准备了 macOS 15 / 26 的 Apple Silicon 与 Intel 原生测试及七扩展构建，保留成功/失败日志。目前尚未提交或运行，不能算通过。工作流采用当前选中的 Xcode；swift-markdown 0.8.0 需要 Swift 6.2，因此旧 Xcode 会明确构建失败。

Runner 标签按 [GitHub 官方说明](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) 选用。macOS 14 托管镜像处于退役流程，不把即将退役的 CI 镜像当作长期 14 验收；14 需要测试机或用户提供的虚拟机运行已构建应用。

## 每个真实桌面环境

1. 使用同一份开发或正式签名应用。记录 OS/架构、签名身份类型、应用版本和七扩展的实际登记路径。
2. Finder 冷启动分别预览 Swift、Markdown、JSON、TSV、SQLite、ZIP、EPUB、Excalidraw。记录系统实际接管者，不能用登记成功代替打开成功。
3. Markdown 点大纲、脚注、复制代码块、切换源码；点击 Mermaid 放大/平移/返回。图形来源仍是有界栅格，不承诺任意倍率无损。
4. SQLite 切换表、前后翻页到末尾、点击数字列升降序、检查列元数据与 BLOB 提示。ZIP 点子目录正文、筛选完整路径、切换大小排序，确认不解压。
5. 项目目录连续切换 Markdown/Swift/PNG/JSON；快速切换 20 次，旧异步结果不能覆盖当前文件。超过 500 项的目录继续加载并检查部分统计。
6. 大文本翻页、复制中文/emoji、查找本页；保存及原子替换后检查刷新、页码/源码模式/位置保持；删除文件时明确显示旧快照。
7. 缩小到 360/600 点，确保正文可读且“更多操作”可到达；检查大纲收起、画布按钮辅助功能标签。VoiceOver 的实际朗读、系统高对比、多屏仍须各环境单独记录，AX 标签存在不等于全流程已通过。
8. 明确停用一个类别，再升级应用，确保安装器不重新启用；重新打开 Quick Look 验证系统接管结果。恢复测试前的个人设置。

## 正式发布

`scripts/package.sh release` 需要已有 Developer ID Application 身份、匹配 Team ID 和已有 notarytool keychain profile。脚本编译两架构，检查所有 Mach-O，签名嵌套组件，验证签名；提交公证后 staple、validate 和 Gatekeeper assess 全部成功才输出正式 ZIP。

本机仅 Apple Development；Developer ID / 公证 / Gatekeeper 尚未执行。无需提供私钥或密码，环境准备好后用已有身份与 profile 执行脚本即可。独立下载并带 quarantine 的副本仍需另机验收。

## 单文件本地图片

宿主显式选择当前文档目录或图片子目录，保持宿主文档打开；同一文档 Finder 预览自动采用短期共享授权，关闭/换宿主文档后撤销。已在本机真实 Finder 观察加载与撤销，见 authorized/revoked 截图与 AX。

通过正确签名 app group 交换 Apple 进程间隐式 scope bookmark，不使用长期 .withSecurityScope 授权；记录匹配文档路径哈希和文件修订，每 5 秒心跳、30 秒失效。关闭后删除自身记录，崩溃遗留记录失效后不可再用，后续发布清理过期文件。接收端关闭/失效停止 scope。图片仍受 AccessBroker 边界和预算限制。没有 group 的构建不能使用此共享。

Finder 原地目录面板在本机不能输入，直接宿主启动被系统拒绝；当前说明面板可打开/关闭，引导用户在宿主用 ⌘O 打开文档并选目录。不能将共享链路称为一键原地授权。

## 竞品对照

按原文复制、大整数/重复键、目录连续阅读、SQLite 数值排序/全表分页、归档路径筛选、Markdown 大纲、离线图表和安全边界逐项同夹具核对。性能比较须使用同一机器、同一夹具、相同冷/热缓存和一致计时起止，至少 20 次，并记录软件版本。当前只有官网能力对照和 OrangeLen 自身测试，尚无“整体快于或强于所有竞品”的实测结论。

## 2026-10-05 大文件快速切换补验

实际 Finder 的 20 个 6–8 MB Swift/Markdown/JSON 合成文件，前进 19 次（5/5/5/4）及一轮连续 19 次返回。六个检查点标题和正文标记匹配，无最终旧结果覆盖，未观察到崩溃。只支持此次批量切换恢复结论；不支持每个中间文件完整渲染、冷启动、内存峰值或长期压力结论。完整数据和截图在 improvement-report.md。
