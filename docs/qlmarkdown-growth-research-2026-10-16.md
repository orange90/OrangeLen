# QLMarkdown 的分发、运营与推广研究

核对日期：2026-10-16。研究对象为 **sbarex/QLMarkdown**，排除早期同名的 toland/qlmarkdown。依据为官方发行记录、Homebrew API 与 Cask、推荐列表、开发者讨论区，以及用户实际发布的社区帖子。未取得作者后台流量、渠道归因、独立用户或收入数据。

## 核心判断

可验证的增长基础是：明确的 Markdown 预览需求、接近六年的维护、Homebrew 分发、开发者推荐列表和持续的用户口碑。公开证据支持它拥有成熟的分发渠道；尚不足以证明作者执行过某套高强度营销计划，也不能量化各渠道贡献。

对 OrangeLen 最有价值的借鉴，是让一个具体问题的解决方案容易被发现、安装和推荐。支持后缀数量是补充证据，用户实际想解决的问题应成为传播入口。

## 一、先正确理解它的数据

| 指标 | 本次核对值 | 正确解释 |
| --- | ---: | --- |
| GitHub 历史公开安装包下载 | 401,718 次 | 本聊天当日 07:58 UTC 快照；包含历代更新、重复下载及自动化；不是独立用户 |
| GitHub Stars | 3,652 | 同一快照；不是安装或活跃人数 |
| 1.5.7 安装包下载 | 23,342 次 | 2026-10-02 发布版本的累计下载；不是两周新增用户 |
| 2026 年创建的版本资产累计下载 | 241,937 次，占总数约 60.2% | 按资产创建年份分组；不是完整的“2026 年下载量”，因为旧版本今年也可能被下载 |
| Homebrew 近 30 天安装 | 2,815 次 | API 的 install 事件统计，不是独立新增用户 |
| Homebrew 近 90 天安装 | 8,561 次 | 滚动窗口，不能与近 30 天相加 |
| Homebrew 近 365 天安装 | 33,363 次 | 自愿参与统计的 Homebrew 样本；不等于全部渠道总量 |

GitHub 数据来自保留的 [原始快照](evidence/competitors-2026-10-16/github-downloads.json)。Homebrew 及更新源的核对结果见 [本次快照](evidence/competitors-2026-10-16/qlmarkdown-growth-snapshot.json)。搜索缓存中的 Homebrew 1.5.2 和旧安装数已被排除；直连 API 当前为 1.5.7。

**计数重叠特别重要：** Homebrew 的下载地址和 Sparkle 更新源都指向 GitHub Release ZIP。同一 GitHub 计数已经涵盖经这些路径发生的资产下载，不能再把 Homebrew 安装数加上去。缓存、重试等又会使安装事件与下载事件无法逐次对应。自动更新具体贡献多少没有公开数据。

来源：[Homebrew API](https://formulae.brew.sh/api/cask/qlmarkdown.json)、[Cask 源码](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/q/qlmarkdown.rb)、[作者更新源](https://sbarex.github.io/QLMarkdown/appcast.xml)、[Homebrew 统计口径](https://docs.brew.sh/Analytics)。

## 二、能确认的渠道与运作方式

| 渠道/做法 | 查到的直接证据 | 对增长的解释及边界 |
| --- | --- | --- |
| Homebrew 主仓库分发 | 正式 Cask、一条安装命令、版本检查、卸载与残留清理配置，近 30 天 2,815 次 install | 已有实际安装规模的渠道；没有渠道贡献百分比 |
| 开发者推荐列表 | Sindre Sorhus 的 quick-look-plugins 约 18.8k Stars，QLMarkdown 条目直接链接 sbarex 仓库和安装命令 | 高度匹配目标人群的发现入口；列表 Stars 不等于浏览量或转化 |
| 社区用户推荐 | 2022 年 Reddit、2023 年 Hugo 论坛、2024 年 Quick Look 工具讨论、2026 年 Hacker News 均出现明确推荐 | 跨年份、跨社区的用户传播；并不能证明全部是作者安排的推广 |
| 安装与启用文档 | README 提供截图、安装命令、首次启动、扩展启用与故障排查说明 | 缩短从下载到成功预览的路径；未公开实际转化率 |
| 版本发布与应用内更新 | 2020 年底已有版本，当前 1.5.7；Sparkle 更新源使用 GitHub 安装包 | 持续维护给已有安装持续提供价值，也让累计下载包含升级 |
| 需求反馈与贡献者协作 | 2022 年用户请求 Quarto；2025 年增加 MDX/MDC；2026 年增加 Mermaid 等，日志多次感谢贡献者 | 围绕已有阅读场景扩展，帮助老用户继续使用并覆盖相邻人群；未能量化留存变化 |

推荐列表来源：[quick-look-plugins](https://github.com/sindresorhus/quick-look-plugins#qlmarkdown)。该仓库当前界面提示仅协作者可创建 PR，OrangeLen 不能预设随时可以提交收录 PR；应先确认维护者当前接受的联系或收录方式。

用户传播的代表案例：

- [2022 年 Reddit：寻找 Markdown 阅读器](https://www.reddit.com/r/MacOS/comments/t5hzap/any_suggestion_for_a_markdown_viewer_not_editor/)：有人直接推荐 sbarex/QLMarkdown，说明其 Finder 预览用途。老帖子仍有后续反馈，但其中一些新评论也是其他产品自荐，应分别辨认。
- [2023 年 Hugo 用户讨论](https://discourse.gohugo.io/t/guidance-sought-by-lapsed-hugo-user/44240/5)：用户谈自己写博客的流程时顺带推荐该工具，体现真实工作流中的传播。
- [2024 年 Quick Look 插件讨论](https://www.reddit.com/r/macapps/comments/1f00bbx/11_useful_plugins_for_quicklook/)：评论者明确区分新旧同名项目，偏爱 sbarex 版的主题与细致配置，同时也指出其他产品在目录导航方面的优势。不能把这条评论包装成全面胜出。
- [2026 年 Hacker News 问答](https://news.ycombinator.com/item?id=47891234)：有用户问如何在 Finder 预览 Markdown，其他用户贴出 QLMarkdown 并表达使用体验。这是问题驱动的推荐证据，不是已验证的官方 Show HN 首发活动。

## 三、它如何维护与转化用户

README 开头就说明用途，并提供截图和下载入口。用户可以迅速理解“装好后在 Finder 按空格看 Markdown”。这种明确用途便于用户在别人提问时用一句话推荐。对这一机制的判断是研究推断，不是作者公布的增长模型。

文档同时处理首次启动、系统扩展开关与多扩展冲突。Quick Look 工具下载后仍可能无法被系统调用，因此成功启用是转化路径中的实际环节。不能仅以安装包下载衡量产品是否被成功使用。

社区反馈确实进入过版本计划：[Quarto 请求 #104](https://github.com/sbarex/QLMarkdown/issues/104) 于 2022-04-01 提出，发行资产记录显示 1.0.15 于 04-04 发布，其日志列入初步 Quarto 支持；这支持一次具体的快速响应案例，不代表所有问题都有同样响应速度。[官方更新日志](https://github.com/sbarex/QLMarkdown/blob/main/CHANGELOG.md)也能核对后续格式与渲染改进。

免费、公开源代码及捐赠入口降低了尝试成本，构成其产品定位的一部分。未查到可验证的捐赠收入，不能推断作者靠此盈利。

来源：[官方 README](https://github.com/sbarex/QLMarkdown)、[用户讨论区](https://github.com/sbarex/QLMarkdown/discussions)。

## 四、值得研究的渠道风险

2025 年 8 月，Homebrew 曾因 Gatekeeper 检查问题将 Cask 标记为 deprecated，引发用户集中反馈；1.5.0 在 2026 年 4 月的发行说明中宣布应用完成签名和公证。2026-10-16 直连 Homebrew API 的 deprecated 与 disabled 均为 false。

这说明上架渠道还需要持续维护：签名、系统兼容、更新和启用失败都可能直接影响用户获取。某些现今搜索结果仍引用旧弃用提示，不能据此宣称它现在已停更。公证改善是否造成下载上升，缺少前后逐日和归因数据，不能作因果结论。

来源：[项目 Issue #165](https://github.com/sbarex/QLMarkdown/issues/165)、[Homebrew Issue #225747](https://github.com/Homebrew/homebrew-cask/issues/225747)、[1.5.0 发行说明](https://github.com/sbarex/QLMarkdown/releases/tag/1.5.0)、[当前 API](https://formulae.brew.sh/api/cask/qlmarkdown.json)。

## 五、OrangeLen 可以按什么顺序借鉴

以下为研究建议，不是用户已决定执行或授权对外发布的计划。

| 优先级 | 建议 | 具体交付物与衡量方式 |
| --- | --- | --- |
| 1 | 使宣传功能与公开安装包一致 | 为准备推广的版本列清支持范围与入口限制；用同一公开包验收演示中的典型样例 |
| 2 | 提供 Homebrew 安装渠道 | 可以先维护自己的 tap；主仓库收录需另外符合要求。提供安装、升级、卸载及扩展启用说明，观察安装反馈 |
| 3 | 制作三组可被搜索和转发的场景内容 | Skill/MCP 包、ComfyUI 等工作流、模型与数据文件；每组用一个问题、一张真实预览图、一份公开合成样例和安装入口说明价值 |
| 4 | 进入相关工具目录与问题讨论 | 优先开发者/macOS/AI 工作流人群；按各社区与目录的现行收录方式参与。公开作者身份，回答实际问题 |
| 5 | 把反馈处理变成维护节奏 | 发布说明展示具体文件的改善，收集可复现样例并公开处理结果；区分新增下载、版本升级和首次成功预览反馈 |

优先传播的内容示例：

- “Mac 怎么不解压就查看一个 `.skill` 或 `.mcpb` 包？”——展示说明文档、清单与成员，避免宣称完整安全审计。
- “ComfyUI / n8n 导出的 JSON 能不能在 Finder 里直接看图？”——展示有界支持的节点图及对应源码。
- “不启动模型或数据工具，能不能先看 GGUF / Safetensors / Parquet 内容？”——明确分别是张量目录、元数据或有限数据样本，避免让人误解为执行或完整载入。

OrangeLen 已有公开的 Developer ID 签名、公证版本 [preview.2](https://github.com/orange90/OrangeLen/releases/tag/v0.1.0-preview.2)，因此不应把“第一次完成公证”误列为当前待办。该包在 2026-10-14 发布，后续开发版格式变化仍需单独同步。当前 README 已有中英文、下载入口与演示，下一步应补强分发和具体场景的可发现性。

“免费（当前版本）”是用户已确认定价，但 QLMarkdown 也是免费，不能作为独占优势。OrangeLen 更有辨识度的定位是：**按下空格，检查 AI 生成的项目、包、工作流和数据。** 对外的每个演示需对应实际发布版本和已验证入口，不宣传所有后缀均能被 Finder 直接接管。

## 研究边界

未发现可核验的官方 Product Hunt 首发记录、付费投放预算、网站访问量或渠道转化后台，不能断言它从未投放，也不能给自然流量占比。没有证据把今年下载活跃全部归因为 AI 编程普及；这可以作为后续访谈验证的假设。同名旧项目的 2010 年代文章不能证明 sbarex 项目当时就在推广。

本轮仅研究并保存报告和公开统计，没有安装竞品、重新下载应用或源码仓库，没有对外发帖、提交收录申请或改动产品功能。
