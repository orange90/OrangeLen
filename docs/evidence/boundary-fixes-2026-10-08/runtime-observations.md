# Finder 现场验收观察（2026-10-08）

来源：本次 Codex 会话中 CUA 返回的真实 Finder AX 状态和截图，由助手整理。此文件是观察记录，不是原始截图；原图显示于本次聊天，未另存为本目录下的图片。验收对象为本地 Apple Development 签名的 `~/Applications/OrangeLen.app`，夹具为仓库 `Tests/Fixtures/system-preview`。

- 目录 Quick Look：列出 7 个文件；状态显示总大小 338 KB、7 文件/0 文件夹、含隐藏项且递归统计完成。重新读取目录、重新统计按钮可见。
- `sample.docx`：最终 Finder 显示 “OrangeLens System Preview” 与 “Rich text works.”，后者为粗体；状态说明隔离导入仅保留文字和基本字体。最终主题背景改动不涉及导入流程，之后又运行同代码原生宿主测试。
- `sample.mp4`：AVKit 时长 00:03；点击播放后控件为播放中，时间轴观察值 0.4135667396061269，随后到达 3 秒。
- `sample.m4a`：切换后显示音频控制和 00:02 时长，替换先前视频。
- `sample.md`：切回后显示 “Back to OrangeLens / Text after system preview.”，状态为 UTF-8、49 bytes、markdown、完整文件。
- 最终安装后再次打开目录与 Markdown，切换深色：工具栏、左右栏、正文及底部状态有深色背景，文字可读；恢复“跟随系统”后重新观察浅色正常。Finder 自身标题栏仍跟随系统外观，符合扩展无法改变宿主外框的范围。
- 验收后关闭 Quick Look，再执行最终原生测试，避免测试构建/注册扩展干扰活动预览。

## 本轮现场发现及处理

1. Quick Look 能取得 app group URL，但实际无法创建共享资源锁；先前直接返回过载，导致目录加载失败。现实现不可写时回退进程内并发限制；文档明确不保证此路径的跨进程总量控制，回归覆盖该失败模式。
2. 新 XPC 沙盒首次容器准备观察约 22 秒；原 6 秒总窗口会误报导入失败。现客户端先等最多 30 秒 prepare 握手，再启动 6 秒导入计时，服务实际导入仍有 5 秒 watchdog。最终 Finder Word 正文通过。
3. 深色模式正文已变暗，但透明根视图使外围白底透出，导致部分白字不可读。现根视图自行绘制 windowBackgroundColor 并随外观刷新；亮/暗窄窗位图测试及最终 Finder 截图观察均通过。

未将一次构建期间出现的扩展失败推断为已确定的崩溃根因；没有对应崩溃报告。最终避开预览期间构建后重复成功。没有执行真实第三方云 provider、断盘、多显示器、完整 VoiceOver、全系统网络抓包或长期多进程压力，不能从以上小样例推导这些条件全部通过。

## 原生测试宿主的夹具访问修正

最终复跑曾停在 `testOfficeContentAndImageFamilies` 的 `Data(contentsOf:)`。保留 [进程采样](native-stalled.sample) 与 [当时日志](native-stalled.log)：主线程位于系统 `open()`，未进入 Office 解析。采样只能证明阻塞位置，未确认具体 OS 权限根因。测试宿主此前通过编译时源码路径读取开发者 Documents 下的仓库；现把样例作为测试 bundle 的资源复制，原生测试直接读取自己的资源，不依赖开发目录授权。首次资源配置未生成 Copy Resources，测试明确报缺文件，随后改成 XcodeGen sources 的资源构建阶段。最终独立复跑日志为 `native-tests.log`；测试命令另设置 90 秒执行上限。此修正只影响测试宿主/夹具路径，未更改已安装产品的读取实现。
