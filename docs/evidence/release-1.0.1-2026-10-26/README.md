# V1.0.1 公证包与 Finder 验收

2026-10-26，macOS 26.6.2 (25G83)，Apple Silicon。

## 发布包

- 版本 `1.0.1`，build `4`；应用及 7 个 Quick Look 扩展内部版本一致。
- 构建源码提交：`a5891200c822b0e675da14ade19f6206d0c35487`。后续验收文档提交不改变构建输入代码。
- Xcode Release 构建成功；所有 **24 个 Mach-O** 文件均包含 arm64 / x86_64，包括应用、扩展、XPC、框架和嵌套原生组件。
- 回归测试 **314 项，4 项跳过，零失败**。Intel 实机及其他 macOS 版本尚未完整验收。
- 签名 Team `C7J9CK5X87`，与此前公开版 Developer ID 一致。没有使用 Apple Development 身份发布。
- 应用公证 Accepted：`7c56ceac-ef03-4aa8-a471-dcfb889f1c01`。
- DMG 公证 Accepted：`260137b1-b6d3-46b1-8b50-f7c0cf97841f`。
- 应用及 DMG 的 staple/validate、Gatekeeper 校验通过；DMG 自身校验通过。
- 文件 `OrangeLen-1.0.1-universal.dmg`，115,055,437 bytes。
- SHA-256：`ad416ff08257d35fa7610e40acaf114fc86642c109a8005a3a91acbfad3c39b1`。

详见 [分发元数据](distribution.json) 和 [签名、票据及架构检查](distribution-checks.json)。

## 新公证包的真实 Finder 空格

将公证附票据后的 app 安装到 `/Applications` 与 `~/Applications`，备份旧版本，注册正式扩展后逐项选择 13 个原后缀文件并按空格。专属界面、真实 received/completed 日志同时检查；每个收到回调的进程，其 Mach-O UUID 也与新 Release 构建一致，排除旧开发版进程仍在工作的情况。

|后缀|结果|
|---|---|
|SQL|OrangeLen 正文、行号、关键词/注释/中文字符串高亮|
|ZSH/BASH/R/PROTO/LOG/DIFF/PATCH|7 项均为 OrangeLen 正文及成功回调|
|TXZ/TBZ2|2 项均为 OrangeLen 归档目录及成功回调，均实际选择 README.md 读到中文成员正文|
|TS/MTS/DOT|3 项均为系统基本信息，没有 OrangeLen received；既有原生分派限制仍存在|

共 **10 项修复通过 + 3 项限制复核**，不是对全部 371 项的重跑。WFLOW 可选偏好、本机既有 Hydra/Shortcuts 设置均未在本轮改动；不把 WFLOW 计入默认安装的接管修复。

此机器之前用 `JR39NPKJK6` 的开发签名运行过相同 bundle ID。首次切换到正式 `C7J9CK5X87` 时，macOS 等待旧开发版容器数据的访问确认，扩展停在沙盒初始化。只读采样和日志定位该原因后，由用户分别手动允许 Code 与 Archives 的系统提示；没有自动点击、修改 TCC、编辑容器 ACL、删除用户数据或绕过安全控制。之后新正式签名进程正常回调。本机迁移经历不外推为所有旧公开版升级都会提示。

## 证据

- [13 项结构化结果与截图/AX 索引](finder-results.json)
- [实际回调、显示器及进程 UUID](provider-events.json)
- [两种归档成员正文](members.json)
- [样例与 SHA-256](manifest.json)、[摘要](summary.json)
- [验证生成器](build-report.py)：使用本机保留的原始日志、AX、截图和安装元数据重新生成并断言。

原始日志、截图、AX、安装备份和钥匙串配置均不入 Git。公证仅使用已有配置，不保存凭据。最终公共下载验证结果另记录于 `public-download.json`。
