# 开发者常见格式补充（2026-10-04）

本轮补充配置文件识别、前端及常见开发源码、JSONC/JSON5、静态 SVG 和普通 gzip 文本流。格式识别、共享阅读器、Finder 类型声明是不同层面的能力；Finder 仍由系统根据 UTType 选择处理器。

## 文件名与源码

明确识别 `.env` 及 `.env.*`、`.dockerignore`、`.editorconfig`、`.npmrc`、`.yarnrc`、`.prettierrc`、`.eslintrc`、`.babelrc` 及其带后缀变体、版本声明文件、Git 配置、Dockerfile/Containerfile/Makefile 及其变体、Justfile/Jenkinsfile/Procfile/Brewfile、Cargo/yarn/poetry/uv/Gemfile 锁文件、go.mod/go.sum、CMakeLists.txt 等。

源码扩展增加 Vue/Svelte/Astro、mjs/cjs/mts/cts、SCSS/Sass/Less、C#/PHP/Dart/Lua/R/Scala/PowerShell、Proto/GraphQL/Terraform/HCL。支持有界源码显示、行号、搜索和原文复制；高亮仍为共享通用词法着色，不宣称这些语言的完整语法解析，也不执行组件或配置。

对有扩展名的新增源码、JSONC/JSON5 声明专用导入类型。`.env.production` 等完整文件名在宿主和目录阅读器中可确定识别；Finder 单文件是否调用扩展仍取决于系统类型。没有为 `production`/`local` 等泛用后缀抢占类型，也没有注册 `public.data`。原有 `.ts` 视频类型冲突保留。

### Docker 文件的实际入口差异（2026-10-04 纠正）

用户报告 `dockerfile.dev` 测试未通过。本机复现 Finder 单文件 Quick Look：只有文件图标、大小和修改时间，OrangeLen 没有被调用。`Dockerfile.dev` 的 UTType 是 `dyn.ah62d4rv4ge80k3p0`，仅继承 `public.data`/`public.item`；`Dockerfile`、`Containerfile`、`.dockerignore` 也为 `public.data`。`compose.yaml` 为 `public.yaml`。查询结果见 `evidence/docker-content-types.tsv`。

完整文件名规则在 OrangeLen 阅读器收到文件后才生效，不负责 Finder 调用前的类型匹配。此前“Docker 已支持”的聊天说明过宽；Dockerfile.dev 仅有宿主/文件夹内读取证据，Finder 单文件入口当前未支持，不能将这次复现归为用户操作问题或仅建议清缓存。

可用入口：Finder 选中所在文件夹后打开 Quick Look，再在目录树点 Dockerfile.dev；或 OrangeLen 的 Open… 直接选择文件。已有文件夹内正文证据。本轮继续遵循不注册通用 `public.data`、不抢占 `dev`/`prod` 等泛用后缀的边界，未修改分派配置。

## JSONC / JSON5

- `.jsonc` 允许行/块注释和尾逗号；`.json5` 另支持无引号 Unicode 标识符键、单引号、续行、扩展转义、十六进制数、正号、首尾小数点、Infinity/NaN。
- `tsconfig.json` / `tsconfig.*.json`、`jsconfig.json` / `jsconfig.*.json`，以及 `.vscode` 中的 settings/tasks/launch/extensions.json 自动采用 JSONC；普通 `.json` 继续严格解析。
- 结构树直接记录原文 UTF-16 范围，保留数字写法、重复键与顺序。复制原始值不转换成浮点数，也不把 JSON5 规范化成严格 JSON。路径里的键按解码后的字符串生成。
- 不执行 JavaScript 表达式；解析失败显示原文和原因。沿用 5 MiB、64 层、20,000 节点预算及取消。
- 语法依据：[JSON5 规范](https://spec.json5.org/) 和 [VS Code JSON 文档](https://code.visualstudio.com/docs/languages/json)。尚未运行外部完整规范一致性套件。

## SVG

通过 XML 允许名单重建静态 SVG，在断网、临时 WebKit 中由打包代码生成图像，实际阅读界面仍为原生图片与源码切换。支持基本形状、路径、文字、组、渐变、裁剪路径、变换和受限的内联表现样式。

拒绝 DTD/实体声明；过滤脚本、事件处理器、foreignObject、动画、image、递归 use、外部 URL、全局样式表、过滤器等。内联 `style` 中认可的表现属性转成属性值，其他声明忽略。不读取邻接资源，不联网，不加载文档字体。局部渐变与裁剪引用可保留。

复杂 SVG 可能显示简化结果，省略项会有提示；不承诺浏览器完整兼容。白色背景、系统字体、适合窗口图像，渲染尺寸最多 780 × 1400 点、2 倍快照；5 MiB 输入、64 层、20,000 元素，沿用 WebKit 5 秒渲染软预算。损坏/超限/失败回退完整源码；图内文字不能逐字选择，可用源码搜索和复制。SVG 位于 ZIP/TAR 等归档内时目前显示源码。

## 普通 gzip

`.tar.gz` 和 `.tgz` 继续进入 TAR 阅读器。其余 `.gz` 只解压单个 gzip 流，以外层文件名移除 `.gz` 后识别内容；不信任 gzip 头里的文件名，不写解压文件。

`.log.gz`/`.txt.gz` 显示正文；`.csv.gz`/`.tsv.gz` 使用表格；`.json.gz`/`.jsonc.gz`/`.json5.gz` 使用结构树；`.jsonl.gz`/`.ndjson.gz` 保留逐记录浏览、坏行隔离及完整解压源文。Markdown 可显示不依赖外部资源的正文；其他已认可的源码按原文显示。不会加载压缩 Markdown 的邻接图片。

输入最多 64 MiB，展开文本最多 5 MiB、压缩比最多 100；zlib 校验流/CRC，拒绝截断、尾部额外数据和拼接多流、二进制或不支持的内层格式。高压缩比的合法日志也可能触发预算。未知无后缀内容仍须通过严格文本编码及空字符检查。

## 验证

合成夹具在 `Tests/Fixtures/developer-formats`。新增 Core 和 UI 集成测试涵盖识别、结构树源范围、转义/非法语法/预算、gzip CRC/截断/拼接/二进制/展开预算、SVG 过滤、实际 WebKit 图片、源码切换和取消旧加载。

连续预览行数不同的 CSV/TSV 暴露了原有表格刷新越界：AppKit 替换列时可能询问旧行。已对行高、单元格和复制回调增加有效范围检查，并用真实连续切换回归。

测试结果、构建和实际 Finder 验证见 [验证记录](verification.md)。未测试的格式或环境不由组件测试代替 Finder 验收。
