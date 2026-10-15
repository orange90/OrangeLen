# UU 远程安装检查 · 2026-10-14

用户授权将现有安装包安装到已连接的远程机器并测试；操作通过 UU 远程的文件传输和终端功能完成。

## 环境与安装

- UU 设备显示名：hi’s MacBook Pro；远端用户目录：`/Users/hi`。
- 系统：macOS 12.7.4，build 21H1123，x86_64。
- CPU：Intel Core i7-6700HQ @ 2.60GHz。
- 安装包：OrangeLen-0.1.0-preview.2-universal.dmg，通过 UU 发送到远端 Downloads。
- SHA-256 实际输出：`56b5ae71a50667e6366d1919aa773ebc4181cfb1cbb044819fe401dfeca5a143`，与发布包相同。
- 安装前 `/Applications/OrangeLen.app` 和 `~/Applications/OrangeLen.app` 均不存在。
- 只读挂载 DMG，使用 `ditto` 复制到远端 `/Users/hi/Applications/OrangeLen.app`。
- 合成样例目录 `format-audit-106` 也通过 UU 发送到远端 Downloads。

## 验证结果

| 检查 | 远端实际结果 |
| --- | --- |
| DMG SHA-256 | 与发布包相同 |
| DMG Gatekeeper | accepted / Notarized Developer ID |
| 应用严格签名 | valid on disk / satisfies its Designated Requirement；嵌套扩展校验通过 |
| 应用 Gatekeeper | accepted / Notarized Developer ID |
| 最低系统要求 | 应用 Info.plist：LSMinimumSystemVersion = 14.0 |
| 正常启动 | 失败，open 返回 1，系统错误 -10825 / kLSIncompatibleSystemVersionErr |
| Finder / 阅读器功能 | 未验收：应用无法在 macOS 12.7.4 启动 |

启动错误明确说明：The app cannot run on the current OS version。此次结果证明发布包传输和签名校验通过，不代表 Intel 功能验收通过。

远端原始检查记录保存在 `/Users/hi/Downloads/OrangeLen-install-check.txt`。依据为本次 UU 终端命令输出及 CUA 现场截图；本文件为人工整理，不是自动测试日志。未修改最低系统声明、关闭 Gatekeeper 或升级远端系统。

## 对先前判断的纠正

UU 主界面的错误 2003 与已建立的远控会话同时存在；文件传输和远端终端实际可用。不能仅凭主界面错误判定现有远控会话已断开。

## 16:25–16:27 再次现场测试

用户再次要求在当前机器测试，已重新检查实时环境及入口：

- 当前会话仍为 hi’s MacBook Pro，`sw_vers` 再次返回 macOS 12.7.4 / 21H1123。
- 正常 `open ~/Applications/OrangeLen.app` 再次返回系统错误 -10825 / kLSIncompatibleSystemVersionErr，退出码 1。
- 使用 `open -R` 在远端 Finder 定位安装件，实际图标显示系统禁止标记；尝试双击和打开快捷键未观察到应用启动。不将此记录为已显示错误对话框。
- `pluginkit -m -A -D | grep -i orangelen` 无匹配，退出码 1；当前系统登记查询未找到 OrangeLen 扩展。
- 在远端调用 `qlmanage -p ~/Downloads/format-audit-106`，真实远控画面出现标记为 `[DEBUG]` 的系统 Quick Look，显示文件夹图标、80 KB / 110 个项目与修改时间，没有 OrangeLen 目录树或阅读器。这是 qlmanage 诊断入口，不冒充 Finder Space 键逐格式验收。
- 原始扩展查询与 Quick Look 输出分别写入远端 Downloads 下的 `OrangeLen-extension-recheck.txt` 和 `OrangeLen-quicklook-recheck.txt`。

当前发布版无法在此系统进行功能验收；没有修改签名、最低系统声明或远端系统。

## macOS 12 兼容性代码评估

用户询问改动与功能损失，未要求本轮发布兼容版。检查现有源码、Apple SDK/官方 API 元数据，并在临时源码副本做无签名 x86_64 Debug 编译。

确认需要适配：工程所有目标及 SwiftPM 的最低系统从 14.0 降至 12.0；10 处视图加载调用 `loadViewIfNeeded()`（macOS 14）；SettingsView 两参数 `onChange`（macOS 14）与分组 `formStyle`（macOS 13）；RemoteImageLoader 的 `URL.host()`（macOS 13）。视图加载可用读取 `view` 触发，设置回调可保留已有 baseline 合并逻辑；旧系统表单需回退，host 的解析与 DNS/TLS 安全行为需回归验证。

临时副本替换上述 API 后 x86_64/macOS 12.0 构建通过。主应用、7 类扩展及其 XPC 安装件的 Info.plist 和 Mach-O 最低系统均实际为 12.0。正式仓库源码未修改，未签名公证、未传输或安装此临时包。日志：`/tmp/orangelen-macos12-audit.log`、`/tmp/orangelen-macos12-adapted-audit-pass3.log`；临时源码路径记录于 `/tmp/orangelen-macos12-assessment-source-path.txt`。

此为编译可行性证据，不是旧系统功能验收。当前未发现必须删除代码、Markdown、数据、归档、工作流或3D预览的编译障碍。确定的界面差异是旧系统表单样式及普通背景：GlassSurface 已为 macOS 26 以下提供普通背景回退，14 上也没有玻璃效果。WebKit/JavaScript/WASM 渲染、旧GPU的3D、系统媒体/图片解码、Finder UTI分派、目录权限与XPC共享设置仍需在远端12.7.4复测；失败的富内容已有降级源码/错误提示机制，不能预先承诺106种均通过。

正式交付应做版本兼容分支、重新构建双架构、Developer ID 签名和公证，而不是仅修改已发布包的 Info.plist。
