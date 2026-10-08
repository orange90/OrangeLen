# Markdown 公式、Mermaid 与图片

2026-10-03 用户新决定：公式/Mermaid 本轮实现；可访问的本地图片直接渲染；远程图片先占位，用户点“加载远程图片”才下载。这取代最初所有预览完全离线的默认值，仅放开显式点击的图片请求。

## 使用

- 公式：`$…$`、`$$…$$`、`\(…\)`、`\[…\]`，以及 math/latex/tex 围栏。反引号代码及转义美元不当公式。由 KaTeX 支持的 TeX 数学语法渲染，非完整 TeX 编译器。
- Mermaid：mermaid 围栏；本轮 Finder 实测中文流程图和时序图，自动化渲染测试还覆盖类图继承箭头。库支持其他图型，但未逐一验收。拒绝交互、危险 HTML 标签、外部资源和文档级配置指令；其他标签不作为可执行 HTML。
- 本地图片：打开文档时直接读取、解码；只允许选中目录边界内可读路径，禁止符号链接和未下载云占位符。单独 Finder 预览 Markdown 未必授予邻接图片权限；2026-10-05 已实现并实测宿主显式授权后经短期 app group bookmark 给同文档 Finder，关闭宿主后撤销。原地选目录仍需宿主；详见 improvement-report.md。
- 远程图片：正文占位及顶部“加载远程图片”按钮；按钮加载当前文档尚未加载的远程图片，单张占位的点击委托也已接入。失败显示原因，源文件不修改。重新打开不自动联网，也不继承前一文件的同意。
- 公式和图表为原生 TextKit 图像附件，选中后复制回对应 TeX/围栏源码；搜索公式/图表源码命中对应附件。不能逐个选择图像内的字形，精细选择使用源码模式。字号和宽度变化调整附件尺寸，阅读尺使用实际 TextKit 布局。

## 安全边界

- KaTeX 0.19.0 / Mermaid 12.1.0 及字体全部随应用打包，无 CDN。WKWebView 仅在独立 WebContent 进程内运行可信渲染库，正文仍为 NSTextView。非持久数据存储、CSP `default-src 'none'` 和内容拦截规则禁止联网；仅 data 字体与打包脚本/样式允许。
- 文档内容经结构化 `callAsyncJavaScript` 参数传入，不拼接可执行代码。KaTeX `trust:false`、`maxExpand:500`、`maxSize:20`；Mermaid `securityLevel:strict`、`htmlLabels:false`、最多 150 边。额外拒绝配置指令、危险 HTML 标签、外部资源/回调；移除可交互 SVG 元素。参考 [KaTeX 安全说明](https://katex.org/docs/security)、[Mermaid 安全级别](https://mermaid.js.org/config/schema-docs/config-properties-securitylevel.html)。
- 单段最多 16 KiB；公式检测最多 64 项，实际图像生成最多 32 项；每项 5 秒、启动 8 秒，文档循环 30 秒软预算；最多 800×1500 点/8 百万累计物理像素。取消时撤销待完成回调并移除渲染视图；复杂或无效内容保留源码入口。同步系统调用和 WebKit 进程回收的瞬时内存没有硬实时保证。
- 远程只接受 HTTPS、443、无 URL 账号；DNS 所有结果必须为公共地址，连接固定到验证后的 IP，TLS 使用原主机名。系统配置的代理可能承载连接，本机确有代理；不擅自修改系统网络设置。
- 远程不跟随任何重定向、不发送 Cookie/认证/Referer、不缓存到磁盘。拒绝 HTML/SVG 和压缩传输，仅接收限定 MIME 且由 ImageIO 识别的栅格格式。每张 5 MiB、15 秒；每文档最多 8 次、20 MiB 总输入；源像素最多 2500 万，最长边解码 1200，文档图片累计 800 万像素。代理 RPC 最多 20 秒。失败可重试，仍消耗本次尝试预算。
- Finder Quick Look 的额外沙盒实际阻止了 `/var/run/mDNSResponder`（EPERM），即使扩展具备 network.client。采用内嵌 `OrangeLenImageBroker.xpc` 分离下载职责：服务保持 App Sandbox，仅有网络客户端权限，没有用户文件读取权限；只提供一次性图片 URL → 有界 Data 接口。关闭/切文件使连接失效并取消下载。没有提权、关闭沙盒、运行预览项目脚本、启动外部命令或跳转宿主窗口。

## 验证范围

30 项 XCTest 通过，新增公式源映射（中文/emoji/转义/代码排除）、真实离线渲染、注入/循环宏拒绝、HTTP 分块/头/预算、私网 IP/IPv6 策略、取消及默认不联网。可选网络测试成功下载公开 W3C 栅格；私有地址被拒；坏证书站点在本机超时，不能把它当作证书故障分支已实测。

真实 Finder：公式字形完整、Mermaid 图像生成，点击按钮后 XPC 下载成功，公共 W3C 图片显示，同次私有地址被拒。证据 `evidence/rich-finder-math.png`、`rich-finder-remote.png` 与 AX。宿主授权目录中的本地图片及公式实际显示，见 `rich-host-math.png`，此前本地图片证据仍有效。Finder 文件夹自动化点击 rich-content.md 本轮落到 JSON 行，故没有新增本地内嵌图片的 Finder 成功结论。单张占位鼠标点击尚未独立验收；顶部按钮完整链路通过。

当前 macOS 26.6.2 / M3 Pro 已测；其他系统、Intel、全部 Mermaid 图型、完整 TeX 兼容性未测。开发签名构建可用，Developer ID/公证未执行。

最终复核：更新安装后再以 Finder 空格打开夹具，默认未联网，点击后显示“已加载 1 张 · 1 张未加载”，私网图片提示拦截。见 [最终 Finder AX 记录](evidence/rich-finder-final-ax.txt)、[测试日志](evidence/rich-tests.log)、[签名日志](evidence/rich-signing.log)。本地开发签名 ZIP 已刷新；Developer ID 发布和公证未执行。
