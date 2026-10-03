# M2 与后续格式：实施范围（2026-10-03）

这是基础实现，M1/M2 尚未完整验收。实际 Finder 结果以格式矩阵、AX 和截图为准；组件测试不是 Finder 调用证据。全部夹具为自行生成的合成数据。

共享 CollectionController 左侧为章节/记录/表/成员列表，右侧复用 TextKit、源映射、复制提示、搜索与专注阅读。切换取消旧任务并检查 generation。容器成员只读内存快照，不写原始文件、不落盘解包。较窄窗口使用紧凑工具栏与“更多操作”。未知二进制明确提示不支持；用户可显式用默认应用打开。

| 格式 | 已实现 | 当前不完善与原因 |
|---|---|---|
| EPUB | container/OPF/spine、EPUB3 nav 标题、章节切换、归档内图片、章节 ID 与文本锚点记忆 | XHTML 转为安全 Markdown，复制对应转换文本而非原始 XHTML；忽略 CSS/嵌入字体、脚本，固定版式降为文本。EPUB2 NCX、正文内部超链接跳章未实现。不是完整浏览器排版引擎 |
| EPUB 保护 | 按 encryption.xml 资源路径拒绝受保护正文；已知字体混淆保留系统字体并提示 | 不绕过 DRM。不能仅凭存在 encryption.xml 就把整本书标为 DRM；已有分别测试 |
| ZIP | 中央目录索引、stored/deflate、CRC、按需代码/Markdown/图片 | 成员列表目前是路径列表，没有完整归档目录树/筛选。非 UTF-8 名称、ZIP64、多卷、加密不支持；危险路径/重复路径拒绝 |
| TAR/TGZ | USTAR 校验、普通成员、gzip 有界解压 | PAX/GNU 长名及链接等特殊项不展开；只读，不调用 tar/unzip 命令。TGZ Finder 调用尚未实测 |
| JSONL | 每个非空行单独解析、坏记录隔离、大整数保真、完整原文入口 | 上限 5,000 记录，不是无限日志流或尾随监控 |
| Notebook | v4 已存储 Markdown/code/raw、文本/stdout/error、PNG 输出 | 不运行 kernel，不执行 HTML/JS/SQL；HTML/SVG 等输出提示拒绝。Notebook 附件引用和交互 widget 未实现 |
| SQLite | 读取有界文件快照，deserialize 到只读内存库；真实表、字段、NULL/BLOB 提示 | 拒绝 WAL 模式，不能把缺少 WAL 的快照当作最新数据；不支持视图/虚表。每表最多 500 行，无分页排序或任意 SQL。活动数据库的多文件原子一致性未证明 |
| diff/patch | 文件分段、增删/块头色彩与前缀、完整原文 | 不是双栏合并工具；分段文本换行规范化，精确复制用完整原文入口。本机 diff 由系统接管 |
| HAR / OpenAPI JSON | 本地条目/路径列表、结构 JSON 与原文 | HAR 未通过 OrangeLen Finder 调用；OpenAPI JSON 已通过。仅命名 openapi.json/swagger.json；YAML 仍源码。不解析外部 $ref、不发送请求 |
| PDF | 目录/宿主 PDFKit，只读 | 25 MiB/2,000 页；尚未实机验收，不能据此宣称支持任意系统预览类型 |

预算：容器输入 64 MiB；归档 5,000 成员、单成员 5 MiB、声明/实际展开 64 MiB、压缩比 100；拒绝路径越界、符号链接、损坏 CRC。SQLite 最多 256 表、256 列、500 行，查询 2 秒软预算、字段长度限制；Notebook 最多 1,000 cells、每 cell 100 outputs。JSON/XML 深度 64、节点 20,000。EPUB XML 拒绝 DTD 与实体（含 UTF-16），禁止外部解析；归档图像复用有界 ImageIO。取消无法保证每个系统同步调用瞬时停止，但过期结果不会更新 UI。

阅读位置是用户可关闭的本地可清理记录：稳定章节 ID + 文本锚点，修订变化失效；不保存正文。隔离配置测试通过，跨进程并发/首启盐值竞争仍未压力测试。

M3：HAR/OpenAPI JSON 是已实施的基础项；MOBI/AZW3、7z/RAR 尚未实现，当前 ZIP/EPUB 解析器不能替代它们。下一步需要选取独立解析器、明确许可证与资源/权限边界，再逐格式验证，不是系统完全禁止这些格式。更完整归档树、EPUB CSS/NCX/跳链、SQLite 分页、稳定性与无障碍仍是剩余开发工作。
