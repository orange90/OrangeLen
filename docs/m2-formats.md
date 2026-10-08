# M2 与后续格式：实施范围（更新于 2026-10-05）

这是基础实现，M1/M2 尚未完整验收。实际 Finder 结果以格式矩阵、AX 和截图为准；组件测试不是 Finder 调用证据。全部夹具为自行生成的合成数据。

EPUB/JSONL 共享 CollectionController；SQLite 使用分页表格，归档使用目录树，左侧为章节/记录/表/成员导航，右侧复用 TextKit、源映射、复制提示、搜索。切换取消旧任务并检查 generation。容器成员只读内存快照，不写原始文件、不落盘解包。较窄窗口使用紧凑工具栏与“更多操作”。未知二进制明确提示不支持；用户可显式用默认应用打开。

| 格式 | 已实现 | 当前不完善与原因 |
|---|---|---|
| EPUB | container/OPF/spine、EPUB3 nav 标题、章节切换、归档内图片、章节 ID 与文本锚点记忆 | XHTML 转为安全 Markdown，复制对应转换文本而非原始 XHTML；忽略 CSS/嵌入字体、脚本，固定版式降为文本。EPUB2 NCX、正文内部超链接跳章未实现。不是完整浏览器排版引擎 |
| EPUB 保护 | 按 encryption.xml 资源路径拒绝受保护正文；已知字体混淆保留系统字体并提示 | 不绕过 DRM。不能仅凭存在 encryption.xml 就把整本书标为 DRM；已有分别测试 |
| ZIP | 中央目录索引、stored/deflate、CRC、按需代码/Markdown/图片 | 目录树、完整路径筛选、名称/展开大小排序；非 UTF-8 名称、ZIP64、多卷、加密不支持；危险路径/重复路径拒绝 |
| TAR/TGZ | USTAR 校验、普通成员、gzip 有界解压 | PAX/GNU 长名及链接等特殊项不展开；只读，不调用 tar/unzip 命令。TGZ Finder 调用尚未实测 |
| 普通 `.gz` 文本 | 按压缩前文件名进入文本、CSV/TSV、JSON/JSONC/JSON5、JSONL；`.tar.gz`/`.tgz` 仍为 TAR | 单流、展开最多 5 MiB/压缩比 100；无磁盘解压；见 [开发者格式](developer-formats.md) |
| JSONL | 每个非空行单独解析、坏记录隔离、大整数保真、完整原文入口 | 上限 5,000 记录，不是无限日志流或尾随监控 |
| Notebook | v4 Markdown/code/raw 与已有文本/stdout/error、PNG 输出按原顺序整篇连续滚动，无 Cell 分页 | 不运行 kernel，不执行 HTML/JS/SQL；HTML/SVG 等输出提示拒绝。Notebook 附件引用和交互 widget 未实现 |
| SQLite | 读取有界文件快照，deserialize 到只读内存库；真实表、字段、NULL/BLOB 提示 | 拒绝 WAL 模式，不能把缺少 WAL 的快照当作最新数据；不支持视图/虚表。UI 每页 500 行，可连续翻页；点击列标题以 SQLite 原始类型对全表排序，并显示字段类型/主键/非空/默认值。不提供任意 SQL。活动数据库的多文件原子一致性未证明 |
| diff/patch | 文件分段、增删/块头色彩与前缀、完整原文 | 不是双栏合并工具；分段文本换行规范化，精确复制用完整原文入口。本机 diff 由系统接管 |
| HAR / OpenAPI JSON | 本地条目/路径列表、结构 JSON 与原文 | HAR 未通过 OrangeLen Finder 调用；OpenAPI JSON 已通过。仅命名 openapi.json/swagger.json；YAML 仍源码。不解析外部 $ref、不发送请求 |
| PDF | 目录/宿主 PDFKit，只读 | 25 MiB/2,000 页；尚未实机验收，不能据此宣称支持任意系统预览类型 |

预算：容器输入 64 MiB；归档 5,000 成员、单成员 5 MiB、声明/实际展开 64 MiB、压缩比 100；拒绝路径越界、符号链接、损坏 CRC。SQLite 最多 256 表、256 列，UI 每页 500 行、API 每页最多 1,000 行，查询 2 秒软预算、字段长度限制；Notebook 最多 1,000 cells、每 cell 100 outputs。JSON/XML 深度 64、节点 20,000。EPUB XML 拒绝 DTD 与实体（含 UTF-16），禁止外部解析；归档图像复用有界 ImageIO。取消无法保证每个系统同步调用瞬时停止，但过期结果不会更新 UI。

阅读位置是用户可关闭的本地可清理记录：稳定章节 ID + 文本锚点，修订变化失效；不保存正文。隔离配置测试通过，跨进程并发/首启盐值竞争仍未压力测试。

M3：HAR/OpenAPI JSON 是已实施的基础项；MOBI/AZW3、7z/RAR 尚未实现，当前 ZIP/EPUB 解析器不能替代它们。下一步需要选取独立解析器、明确许可证与资源/权限边界，再逐格式验证，不是系统完全禁止这些格式。归档树与 SQLite 分页/排序已补齐；EPUB CSS/NCX/跳链、跨系统稳定性与完整 VoiceOver 验收仍未完成。
