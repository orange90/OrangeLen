# OrangeLen

**Quick Look for Developers**

Native macOS host app + modern view-controller Quick Look Preview Extension, with shared SwiftPM Core/UI modules. This is a working **M1 development build, not an M1 acceptance-complete release**.

On the tested M3 Pro / macOS 26.6.2 machine, Finder invokes OrangeLen for Swift, Markdown (with a competing extension isolated), JSON, YAML, TOML, XML, TSV and Makefile fixtures. **M0 native feasibility exit criteria are met; M1 is not fully accepted yet. Folder invocation, enumeration and selected Makefile reading have been observed. By the user’s updated scope, Finder keyboard search is optional and existing system previews may handle their formats.** Folder browsing in the host is a supplementary entry point, not fulfillment of Finder folder preview. See [support matrix](docs/format-support.md) and [verification](docs/verification.md) before relying on a format.

## Build and run

Requirements: Xcode 26.5 was used (macOS 26.5 SDK, Swift); deployment target macOS 14. Other versions are untested. The build selects Xcode through `DEVELOPER_DIR` without changing global `xcode-select`.

```sh
./scripts/build.sh
./scripts/test.sh
./scripts/install-dev.sh
```

The first build fetches pinned swift-markdown 0.8.0 / swift-cmark 0.9.0 dependencies. Runtime rendering is offline; remote images use the network only after an explicit user click. The committed Xcode project builds directly; XcodeGen is needed only after editing `project.yml`:

```sh
xcodegen generate
```

Open `~/Applications/OrangeLen.app`. Choose **Open… (⌘O)** for a file or a directory. Read and change host settings through **Settings… (⌘,)**. The current host and extension both use AppKit text, outline and table views; settings use SwiftUI.

Optional development signing and shared settings, using an existing matching certificate in your own keychain:

```sh
ORANGELEN_SIGN_IDENTITY='Apple Development' \
ORANGELEN_TEAM_ID='YOUR_TEAM_ID' ./scripts/install-dev.sh
```

The script signs nested libraries, the image XPC service and the extension before the app, enables Hardened Runtime for certificate builds, then verifies signatures. It uses Apple's macOS `<team ID>.<group name>` convention for a new app group. It never exports keys or creates certificates. Unsigned-team/ad-hoc builds explicitly fall back to independent settings containers.

## Finder

1. Install the app using the script above; registration and enablement use `pluginkit`.
2. If needed, check **System Settings → General → Login Items & Extensions → Quick Look** for OrangeLen. Exact labels vary by system; this settings path was not separately UI-tested; script registration was tested.
3. In Finder select a fixture under `Tests/Fixtures`, press Space, and check that the OrangeLen toolbar appears. Registration alone does not prove selection by Finder.
4. If another Markdown previewer wins, temporarily disable that previewer through its extension setting and retest. No installer disables another application's extension. Testing originally restored the machine's QLMarkdown selection state; the user subsequently reported uninstalling QLMarkdown.
5. Closing and reopening Quick Look is necessary after a new build; an already open preview may retain the old process.

Do not rename files, disable SIP, capture Space globally, or register `public.data` to force type matching. See `docs/evidence/content-types.tsv` for actual machine UTTypes.

## Reading

- Text/code: real selectable text, source-exact Copy, lexical coloring, line numbers, case-sensitive/insensitive search, previous/next result, source line navigation, wrapping, font size and light/dark/system appearance.
- Markdown: mature CommonMark/GFM parser, native styled text, heading menu, source/render switch, nested/ordered/task lists, quote and code blocks, safe links, and native wrapping/aligned tables. Authorized local inline images use bounded ImageIO decoding; remote images show placeholders until “加载远程图片” is clicked. KaTeX formulas and Mermaid fenced diagrams render offline into source-mapped native attachments. See [rich content and security](docs/markdown-rich-content.md).
- Focus: current sentence and 1/3/5 **visual** lines; independent highlight, ruler and dim controls. Click without dragging chooses a sentence; dragging preserves selection. Previous/next buttons and body-only Option+↑/↓ are implemented. Long sentences remain fully highlighted independently of ruler height.
- Rendered Markdown Copy maps selections back to original Markdown source. Entity selections copy original entity spelling; a selection spanning formatting may include Markdown delimiters. Source mode provides exact arbitrary source selection.
- Folder reader: expand on demand, select code/Markdown/data in the same right pane; 500 directory entries per batch, hidden/ignored toggle, filename filter for loaded items, continue-loading row. Symlinks and packages are not automatically descended in the tree. A persistent footer reports bounded recursive metadata totals (including hidden files), with partial totals clearly marked. File buttons preserve the native selected row.
- Standalone images: PNG/JPEG/GIF/TIFF/HEIC/WebP/BMP/ICO route to ImageIO + NSImageView instead of text decoding; PNG tested. Input 25 MiB, source at most 100 million pixels, decoded longest edge 2048, animated images use the first frame. Finder PNG selection keeps its existing system handler; this renderer is used in OrangeLen folder/host views.
- JSON: native collapsible tree and source view, raw numeric lexemes and duplicate keys retained; contextual Copy Path / Copy Value.
- CSV/TSV: native virtualized rows, quoted multiline fields, header toggle, 500-row display batches, first 5,000 parsed rows, contextual cell/row copying. Search covers parsed cells in table mode; source mode covers the bounded complete text.

In Finder, prefer the visible **查找 / 全选 / 复制选择** controls. Shortcut forwarding is system/focus dependent; see the recorded results. The app supports ⌘F/⌘C normally. Neither interface intercepts Space or Escape globally.

## Safety and limits

Source files are read locally and read-only. Previewed code never runs. No shell, compiler, package manager, notebook kernel or SQL engine is invoked. A private, network-blocked WebKit renderer runs bundled KaTeX/Mermaid only, using document text as structured data. XML is styled source, so entities are never resolved. Remote images are fetched only after an explicit user click through a bounded HTTPS raster-image client. Local inline images are loaded only within the authorized root and resource budgets; single-file Finder access may not authorize adjacent images. Standalone images selected in the folder tree use bounded ImageIO decoding. The sandbox has only user-selected **read-only** file access and an optional private app group; network-client permission for the offline WebKit infrastructure and explicit image requests. The Finder download broker is separately sandboxed and has no user-file entitlement.

Limits live in `PreviewLimits`: 5 MiB complete file, 64 structure depth, 20,000 structure nodes, 5,000 CSV rows, 256 columns, 500 directory entries/batch, 20,000 scanned entries and 3 seconds per directory traversal round. Syntax coloring is bounded to the first 250,000 UTF-16 units; source remains complete. Unsupported encodings and oversized input are refused without unsafe byte truncation.

Reading records are opt-in, local, revision-checked, salted identifiers, capped at 200 entries/30 days, and clearable. No body text is persisted. App Group settings refresh while a preview is active. No fixture comes from a private project.

## 当前不完善之处、原因与影响（2026-10-03）

**M0 原生可行性验证完成，M1 已开发但未完整验收。** 以下区分系统边界、主动取舍、实现缺口和未测试项；未测试不等于故障，也不等于已支持。当前实测环境仅为 macOS 26.6.2 / Apple M3 Pro / Xcode 26.5。本节是当前状态；[验证记录](docs/verification.md) 中较早的失败或缺口须结合后续修复阅读。

### Finder 与文件访问

| 不完善之处 | 原因或限制 | 当前影响与后续方向 |
|---|---|---|
| 单独预览 Markdown 时，邻接本地图片可能不显示 | **权限边界，仍未完成**：系统授予所选文件的权限不等于授予其所在目录。本机已出现不可读占位；不能通过拼接路径自行扩大授权 | 有权限的本地图片直接渲染；宿主授权目录已通过。宿主入口只是补充，不能替代 Finder 验收。仍需验证 Finder 目录授权链路及合适的显式授权方案 |
| Finder 中查找输入、⌘F/⌘C、部分导航键不可靠 | **系统事件传递 + 未完整验证**：外层 Quick Look 窗口由系统管理，测试中键入流向 Finder，⌘F 可打开 Finder 搜索。AX 注入查询成功只证明搜索算法 | 可用查找结果按钮、全选和复制按钮；正常键盘搜索仍未解决。按用户决定不再阻塞验收，不使用全局监听或私有 API 强抢键盘 |
| 类型分派不完全由 OrangeLen 决定 | **系统选择与缓存**：按 UTType 匹配，其他扩展、系统处理器及旧进程可影响选择；本机 `.ts` 被识别为视频，CSV/TXT 可由系统接管 | 按用户决定保留系统原生预览，不抢占通用类型。QLMarkdown 已卸载为用户报告，过去竞争不再算当前故障；跨机器注册可靠性尚未证明 |
| 文件夹里不是所有系统可预览格式都能显示 | **实现缺口**：目前共享阅读器支持代码、Markdown、数据和指定栅格图片，未实现目录内 PDF/视频等系统预览转交；未知文件仍可能进入文本读取并报编码错误 | Finder 单独打开这些格式可沿用系统，但不代表 OrangeLen 目录右侧支持它们。需补充明确格式提示和合适的原生预览路径 |
| 文件夹阅读的实机回归仍不充分 | **验证缺口**：Finder 文件夹调用、枚举、Makefile 同窗正文及选中背景已通过；PNG 共享组件和宿主已通过，Finder 自动化点选 PNG/Markdown 未稳定命中目标 | 不能把自动化未命中直接判定为功能失败，也不能宣称通过。还需两种代码与 Markdown 连续切换、PNG、“已复制”提示、任意拖选与阅读尺组合的 Finder 回归 |
| 窄窗口工具栏拥挤、部分控件可能被裁切 | **布局尚未完善**：控件较多，当前工具栏自适应不足；Finder 窗口大小由系统与用户共同决定 | 后续应分组、折叠或调整工具栏布局，不能仅依赖较大的首选窗口尺寸 |

### 渲染完整性与阅读体验

| 不完善之处 | 原因或限制 | 当前影响与后续方向 |
|---|---|---|
| Markdown 不等同完整网页或 Obsidian | **安全取舍 + 实现范围**：CommonMark/GFM 原生排版已实现；不执行原始 HTML、脚本或文档样式，Obsidian 扩展语法未实现 | 原始 HTML 作为文本；布局不承诺与浏览器逐像素一致。可逐项补充安全的静态语法，而非执行文档 HTML |
| 渲染态复制含 Markdown 符号，个别范围映射较粗 | **原文复制设计 + 映射限制**：选区映射回源文；少量 AST 转换只能采用整节点映射 | 粗体、实体、表格等复制可能带原始标记；需要精细选择时切源码。不能宣称所有富文本子选区都精确一一对应 |
| 公式与 Mermaid 是图像附件 | **当前架构取舍**：离线库在隔离 WebKit 中渲染后转入 TextKit，保持正文原生选择和布局 | 可选整个附件复制 TeX/围栏源码，搜索源文定位附件；无法逐字选择图内文字，图内句子与阅读尺也不逐字逐行定位。放大是图像缩放；细节和无障碍仍可改进 |
| 数学与图表并非无限兼容 | **库能力 + 安全预算**：KaTeX 不是完整 TeX；Mermaid 禁止交互、外部资源、危险 HTML 和文档配置。Finder 测过流程图、时序图；类图继承有自动测试，其他图型未逐一验收 | 单段 16 KiB、最多生成 32 项、每项 5 秒、文档循环 30 秒软预算、累计 800 万物理像素；复杂内容会降级占位并保留源码入口。可调预算，不应直接取消边界 |
| 高亮及结构视图有限 | **当前实现范围**：高亮为有界词法规则；YAML/TOML/XML 目前仅源码，JSON 有树，CSV/TSV 有表格 | 不提供完整语言解析、语义校验或 YAML/TOML/XML 树；EPUB、归档、Notebook、SQLite、MOBI/AZW3 尚未实现，保持后续阶段 |
| 链接与部分鼠标交互尚未完整验收 | **验证缺口**：文内导航委托有测试，但外部浏览器真实点击、单张远程图片占位的鼠标链路尚未独立验证 | 顶部“加载远程图片”按钮已在 Finder 走通；不能据此宣称所有链接交互已通过 |

### 图片、安全和资源预算

- **远程图片有意限制兼容性**：仅点击后加载公共 HTTPS/443 栅格图片，拒绝私网、URL 账号、任何重定向、HTML/SVG、压缩传输，不发送 Cookie/认证/Referer。因此部分 CDN 跳转、内网图床和登录图片不会显示。这样限制是为了减小注入、内网探测及资源耗尽风险；不是“系统完全无法加载”。系统配置的代理可能承载请求，不能承诺绕过代理。服务器仍会看到用户主动发起的图片请求。
- **远程下载有上限**：每张 5 MiB/15 秒，每文档最多 8 次尝试、20 MiB 输入；源图最多 2500 万像素，解码最长边 1200，图片累计 800 万像素。失败重试也消耗尝试预算，重新打开不自动联网、不复用此前同意，不缓存到磁盘。
- **Finder 直接 DNS 曾被沙盒拒绝，但该链路已解决**：内嵌、独立沙盒的窄接口 XPC 图片服务已在真实 Finder 验证成功；此历史问题不再列为当前远程加载阻塞。服务没有用户文件权限。
- **本地独立图片不是无损全功能看图器**：输入 25 MiB、源图 1 亿像素、最长边 2048，动图只显示首帧。PNG 已测，其余列举格式未逐一实测；不自动读取越界路径、符号链接或未下载的云内容。
- **文本与结构有界**：完整文本文件最多 5 MiB，仅接受严格 UTF-8 或带 BOM 的 UTF-16；其他编码或过大文件拒绝，不做乱码猜测或不安全截断。高亮仅前 250,000 UTF-16 单元；结构深度 64、节点 20,000；CSV/TSV 前 5,000 行、256 列。极长正文的全部焦点导航未覆盖，表格可切源码查看大小界限内完整文本。
- **目录统计不是磁盘占用或实时监控**：每批 500 项、扫描最多 20,000 项/每轮 3 秒；显示逻辑文件大小，包含隐藏项，遇预算、权限、云占位会标为部分统计。符号链接单列不跟随，包不自动展开；内容变化后需重新打开根目录。过滤只针对已加载文件名，没有全项目内容搜索；项目摘要尚无 manifest 解析。
- **取消不是所有底层调用都能瞬时中断**：协调读取、cmark C 调用及系统 DNS 等同步操作可能先完成，再丢弃已取消结果；WebKit 进程回收和瞬时内存也没有硬实时保证。当前预算和取消测试不能代替恶意输入压力测试。
- **安全措施不是无漏洞保证**：有注入、循环宏、私网地址、HTTP 解析和预算测试；坏证书测试站点在本机超时，证书错误分支尚未实测。未来仍需跟踪第三方库安全更新并扩充边界测试。

### 稳定性、兼容与发布尚欠的验证

30 项 XCTest 已通过；应用内渲染、真实 Finder 调用、签名构建的证据分别保存。仍未完整测试：真实云提供商“不下载”行为、外置盘、权限变化/删除、大目录与快速切换压力、阅读位置恢复和修订失效全流程、跨进程设置并发、首启盐值竞争、崩溃恢复、VoiceOver/高对比/多屏，以及 macOS 14/15/其他 26 版本和 Intel。测试中的约 1 MiB/20 次热加载指标是进程内数据，不能当作 Finder 冷启动或稳定内存承诺。

现有 Apple Development 签名仅确认本机开发版可运行；**Developer ID 发布签名、公证、staple 和发布版 Gatekeeper 验收未执行**。没有对应外部条件时保留未执行状态，不把开发 ZIP 当作已公证发行版。无 Team 的 ad-hoc 构建使用独立设置容器，不能保证宿主与扩展共享设置。

详细证据见 [格式矩阵](docs/format-support.md)、[验证记录](docs/verification.md)、[富内容安全边界](docs/markdown-rich-content.md)。后续优先补齐 Finder 目录内阅读回归、本地图片授权、窄窗布局与稳定性；用户已接受的键盘搜索和系统格式接管不重新列为阻塞。

## Package

```sh
./scripts/package.sh dev
# Only with your existing Developer ID certificate:
ORANGELEN_SIGN_IDENTITY='Developer ID Application: …' \
ORANGELEN_TEAM_ID='YOUR_TEAM_ID' ./scripts/package.sh release
# Add ORANGELEN_NOTARY_PROFILE only after configuring a keychain profile yourself.
```

Outputs go to `build/artifacts/`. **Developer ID signing, notarization and stapling have not been executed in this environment.** Apple Development signing is not a distribution approval. Build and test logs are in `build/`; selected reproducible evidence is in `docs/evidence/`.

## Uninstall

Quit OrangeLen and close its Finder previews. Unregister with `pluginkit -r "$HOME/Applications/OrangeLen.app/Contents/PlugIns/OrangeLenPreview.appex"`, then move `~/Applications/OrangeLen.app` to Trash. Optional settings/read-position data remains in the app containers and your configured OrangeLen group container; clear reading records in Settings first if desired. Do not remove other applications' containers or reset their extensions.

For an issue report include macOS, Xcode, architecture, build/signing mode, actual UTType and a synthetic fixture. Do not attach private source content or signing material.
