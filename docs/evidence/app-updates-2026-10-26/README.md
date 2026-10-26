# App 内更新接入验收 — 2026-10-26

## 本轮通过

- Sparkle 2.9.6 固定依赖；主 App 与七个 Quick Look 扩展 Debug 构建成功。
- 315 项 Swift 测试：4 项条件跳过，0 失败；16 项 Python 测试通过，其中新增 6 项更新清单测试。
- 实际包内更新源、公钥、手动检查设置、签名要求均核对；公钥匹配本机钥匙串。
  `otool -L` 确认只有主应用链接 Sparkle，七个扩展均不链接。
- 现有资源一致性校验通过；371 后缀类型声明审计为 339 产品 + 32 系统，0 缺口。
- 使用真实 Sparkle `sign_update` 对本地测试文件及 XML 签名并验证；修改字节或清单内容后均拒绝。
- 使用 Developer ID 对 Sparkle Installer、Downloader、Autoupdate、Updater.app 和 framework
  按依赖顺序签名，`codesign --verify --deep --strict` 通过。
- CUA 真实操作独立测试 App：应用菜单显示 Check for Updates；点击后显示 1.0.3 更新及 Markdown
  说明；Install Update 下载完成后显示 Install and Relaunch；点击后磁盘安装版本从 1.0.2/build 5
  变为 1.0.3/build 6，签名验证通过，新进程从测试安装路径启动。

## 测试范围

测试 App 使用独立标识 `local.OrangeLen.UpdaterSmoke`，移除所有 Quick Look 扩展和类型声明，
不覆盖日常安装。它使用本机 `127.0.0.1:18764` HTTP 源、签名清单和 ZIP 包；仅测试副本放宽
ATS 以访问本机 HTTP。生产配置仍是 GitHub HTTPS，并强制签名清单与解压前签名验证。
测试包有 Developer ID 签名，未进行公证，不作为发布包。

更新后工具第一次返回主窗口；后续尝试再次操作新版菜单时 CUA 超时，因此没有把“已是最新版”
分支记为 UI 实测通过。新版进程和磁盘版本、签名均另行核验。测试进程与本机 HTTP 服务已结束，
测试 App 已从 LaunchServices 注销。

GitHub 正式 feed 尚未发布；公证 DMG 的实际更新、真实 Quick Look 扩展从旧版切到新版、Intel
实机及跨 macOS 尚未验收。本轮没有发布或替换日常 App。首次带更新器的版本仍需手动安装。

## 证据

- 可提交摘要：[verification.json](verification.json)。
- 本机原始输出（不提交）：`build/updater-build.log`、`build/updater-tests.log`、
  `build/updater-signing-smoke.log`、`build/updater-e2e-prepare.log`、`build/updater-e2e-http.log`。
- 本机独立测试生成脚本：`build/updater-e2e-prepare.py`；安装前后副本及签名测试源：`build/updater-e2e/`。
- Sparkle SwiftPM ZIP 下载校验 SHA-256：`8d5fb41d960b43f4a68aa14126bf62b098544ec8d191cdcc73eb14e63a8e7606`，
  与 2.9.6 的 Package.swift 一致。首次 Xcode 下载停滞后，用官方 URL 下载并核验后填入 SwiftPM 缓存，
  重试解析成功；没有修改依赖 URL 或跳过校验。
