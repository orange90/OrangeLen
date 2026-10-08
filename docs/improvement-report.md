# OrangeLen 竞品补强：变化与真实截图

2026-10-05。当前改动已安装在 `~/Applications/OrangeLen.app`，保留工作区此前改动，未提交或推送。85 项测试通过，Debug 与 arm64/x86_64 通用 Release 编译通过；本机开发签名严格校验通过。此份为已实现内容的阶段交付，整个必补清单尚未全部验收。

## 具体变化

| 以前 | 现在 | 实际作用 |
|---|---|---|
| 通用关键字着色 | 离线 Highlight.js 库语法、文件名/围栏语言识别，原文重建后才采用 token | Python、TypeScript 等按各自语法着色，字符串/注释更准确；180+ 库语言不等于逐语言全规范验收 |
| Markdown 主要靠顶部标题菜单 | 可收起大纲、front matter、提示块、脚注、代码块原文复制 | 长文更易跳转；渲染与原文保持分开，脚注重排仍有源映射 |
| 图像按窗口固定显示 | +/−、适合窗口、100%、拖动/滚轮平移、捏合缩放、返回正文 | Mermaid/SVG/Excalidraw 共用；有界栅格快照，放大过多会模糊 |
| 文本超过 5 MiB 拒绝 | 512 KiB 按需页，UTF-8/UTF-16 字符边界，准确字节范围 | 可以继续阅读，查找/复制/行号仅针对本页；大结构文件降为源码片段 |
| 压缩包平面路径列表 | 目录树、完整路径筛选、名称/展开大小排序、按需读取成员 | 大包更容易定位，仍不在磁盘解压 |
| SQLite 最多前 500 行 | 500 行分页直到末尾、原生类型全表排序、字段元数据、表选择 | 数字列按数值而非字符串排序，1002 行夹具能读取第 1001–1002 行 |
| 需要手动刷新 | 默认保存后刷新，识别原子替换，保留正文模式/位置和容器选中项/页/排序 | 不必关窗重开已选文件；根目录树变化仍需重新打开 |
| 单一预览扩展 | 代码、Markdown、数据、目录、归档、电子书、绘图七类 | 可按类别与其他工具搭配；实测停用 Data 后升级不会重启它，已恢复个人原选项 |
| 接管失败难判断 | 真实 UTI/声明匹配诊断、固定系统查询复制/导入、宿主入口 | 区分“文件名能识别”和“Finder 是否会调用”；不会把候选写成已接管 |
| 单文件邻图无授权入口 | 宿主显式目录授权，用短期 bookmark 共享给同文档 Finder | 真实 Finder 加载成功，宿主关闭后回到未授权占位；不保存长期授权，原地选目录仍需宿主 |

代码块复制补验发现并修复语言名误匹配及首尾空行丢失。实际右键 NSEvent 生成菜单、派发 action、核对粘贴板；中文/emoji、CRLF 和空行均保持。此为原生组件动作测试，未当作完整 Finder 菜单实测。

原有 JSON 大整数数字写法、重复键和原文复制，以及项目目录连续阅读保持。CSV 的过滤/排序限已解析/显示数据，不能当作 SQLite 全表原生数值查询。

## 实际运行画面

以下全部为本机应用或 Finder 的真实截图、合成夹具，未经拼贴替换内容。Finder 和宿主分开标明。归档/数据库截图来自同轮功能实现；最终分页截图含最新页内范围提示。

### Finder：Markdown 大纲、元数据、提示块和语言高亮

![Finder Markdown](evidence/improvements/finder-markdown.png)

目录侧栏可以收起。短窗口会隐藏侧栏/部分控件，保留“更多操作”。公式和 Mermaid 离线渲染；嵌入图形内部字形仍不可直接拖选，核对原文用源码。

### Finder：SQLite 第二页与全表数值排序

![Finder SQLite 501–1000](evidence/improvements/finder-sqlite-page2.png)

![Finder SQLite 数值升序](evidence/improvements/finder-sqlite-sorted.png)

实际到末页看到第 1001–1002 行，下一页禁用；点击 score 列后从全表的 0、1、2 开始。只读内存快照、拒绝 WAL 的边界保留，不执行用户 SQL。

### Finder：归档目录与路径筛选

![Finder 归档目录](evidence/improvements/finder-archive-tree.png)

![Finder 归档路径筛选](evidence/improvements/finder-archive-filter.png)

点击嵌套 `src/demo.swift` 读到中文/emoji；输入完整路径后保留祖先目录与匹配成员。排序依据声明展开大小，不代表磁盘实际占用。

### Finder：9.96 MB 源码第二页

![Finder 大文件第二页](evidence/improvements/finder-large-source-page2.png)

字节 524289–1048574 / 9960000；下一页与上一页可用，中文/emoji 完整。每页可从一行中间开始，这是字节分页，页内行号重新计数。同内容 `.txt` 本机由系统预览接管，未改动系统选择。

### Finder 图表与宿主辅助功能按钮

![Finder Mermaid 缩放](evidence/improvements/finder-mermaid-zoom.png)

![宿主可访问缩放控件](evidence/improvements/host-mermaid-accessible-zoom.png)

最终控件进入 AX 树，实际点击 + 从 128% 变 160%，fit 恢复 128%。这证明按钮能操作，完整 VoiceOver 朗读仍需实测。

### Finder：2101 项目录与跨格式连续切换

![Finder 2101 项目录与 PNG](evidence/improvements/finder-directory-2101.png)

实际点击继续加载，计数依次 500、1000、1500、2000、2101（完成）。四个小夹具 Markdown/Swift/JSON/PNG 连续切换 20 次，每次状态匹配所选文件，未崩溃；这是可重复的基础压力检查，不等于任意大文件并发与长期稳定性结论。[逐次结果](evidence/improvements/finder-directory-switches.json)。最终搜索栏布局收紧，取消按钮不会被挤到边缘；项目概览隐藏多余大纲。

![Finder 最终项目概览](evidence/improvements/finder-project-summary-final.png)

### Finder：大文件快速切换

![Finder 大文件切换到第 20 个 Markdown](evidence/improvements/finder-large-switch-final.png)

![连续 19 次返回后恢复第一个 Swift](evidence/improvements/finder-large-switch-return.png)

20 个合成 Swift/Markdown/JSON 文件，每个 5,980,019–8,320,037 字节，合计 137,105,488 字节。前进按 5/5/5/4 次分组，返回是一轮连续 19 次 Up 输入。00、05、10、15、19 及返回 00 共六个检查点，窗口标题、页内标记及格式一致，最终正文未被旧结果覆盖，本轮未观察到崩溃。只验证这些最终检查点，不能声称每个中间文件均完整渲染或长期内存稳定。CUA 输入分派时间不是文件加载耗时，未控制系统文件缓存。清单和结果见 [fixtures](evidence/improvements/finder-large-switch-fixtures.json)、[checks](evidence/improvements/finder-large-switch-checks.json)。

### Finder：宿主授权后显示图片，关闭后撤销

![Finder 本地图片已授权](evidence/improvements/finder-local-images-authorized.png)

![Finder 本次授权已结束](evidence/improvements/finder-local-images-revoked.png)

实际使用 Apple 支持的进程间隐式 scope bookmark，经 app group 共享。仅匹配当前文档及修订，宿主每 5 秒刷新、30 秒失效；关闭/换文件删除自身记录。Finder 定期检查并重新读取，保留正文模式和位置。不会保存长期 security-scoped bookmark。授权目录仍受路径、符号链接、云占位和图片预算限制。依据：[Apple 沙箱文件访问文档](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)。

### 宿主：本地图片授权与诊断

![宿主本地图片已授权](evidence/improvements/host-local-images.png)

![宿主 Quick Look 诊断](evidence/improvements/host-diagnostics.png)

目录授权只用于当前文档。诊断实际导入系统登记后显示 Markdown 的 `net.daringfireball.markdown` 及自己的匹配候选；不声称它知道当前 Finder 正在使用哪个处理器。

## 相比竞品，哪些已经补齐、哪些值得继续学习

官网能力对照和本机实现对照分开。没有在同一机器安装全部竞品做匹配测试，不能称整体更快、更稳定或全面领先。

- [Syntax Highlight 官方项目](https://github.com/sbarex/SourceCodeSyntaxHighlight) 的成熟语言覆盖是本次高亮的参照：OrangeLen 已从通用着色提升到离线语言语法。竞品主题/设置丰富度仍值得学习。
- [QLMarkdown 官方项目](https://github.com/sbarex/QLMarkdown) 的文档阅读完善度是参照：大纲、元数据、提示块、脚注和代码复制已补齐；HTML/CSS 和 EPUB 复杂版式目前仍是边界。
- [Peek 官方页面](https://www.bigzlabs.com/peek.html) 提供搜索、复制和阅读状态恢复。OrangeLen 已有这些路径，但 Finder 键盘事件与完整辅助功能验收仍需要实机验证，不能用组件测试代替。
- [BetterZip 官方 Quick Look 说明](https://macitbetter.com/library/betterzip/docs/quick-look-extension/) 是归档导航的参照：树、路径筛选、大小排序已实现；7z/RAR/ZIP64 等广泛格式仍未补齐。
- [Looq 官方 App Store 页面](https://apps.apple.com/us/app/looq-preview-files/id6760281430) 覆盖高亮、目录、缩放、分页、SQLite、刷新、诊断和类别选择。本轮已逐项实现对应基础体验，因此不能再把 SQLite/多格式本身作为独有优势；真正差异要用同夹具的原文保真、目录连续阅读与操作体验证明。

OrangeLen 当前最明确的产品价值：项目目录里跨代码、Markdown、数据和图形连续阅读；JSON 数字词面/重复键可核对；以只读、有界、离线默认组织预览。它们是已验证的自身能力，并非“所有竞品均做不到”的结论。

## 未完成项与后续条件

1. 本地图片已打通“宿主手动授权→同文档 Finder 读取→宿主关闭撤销”。Finder 原地选目录和自动启动宿主仍受系统限制，需用户用 ⌘O 打开文档。共享须有正确签名的 app group。
2. Developer ID、公证、staple、Gatekeeper 尚未执行。本机只有 Apple Development；发布脚本在缺少正式身份/profile 时直接失败，全部检查成功才生成正式 ZIP。
3. 多系统/Intel CI 已准备但未推送运行；macOS 14 需要实际测试机。通用 Mach-O slice 验证是编译证据。
4. 真实 Finder 的大型内容/并发切换全压力、冷启动量化、VoiceOver/高对比/多屏，以及同机竞品性能对照尚未完整验收。
5. 7z/RAR、MOBI/AZW3、完整 EPUB CSS/NCX/正文跳章尚未实现，不把本轮必补基础体验等同无限格式支持。

测试与证据：[85 项测试](evidence/improvements/tests-85.log)、[升级保留停用状态](evidence/improvements/category-upgrade.txt)、[通用 slice](evidence/improvements/universal-build.txt)、[清单](improvement-plan.md)、[运行验收方法](runtime-acceptance.md)。
