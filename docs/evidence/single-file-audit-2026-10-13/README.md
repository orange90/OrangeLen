# 106 格式单文件预览修复与验收

2026-10-13 · 本机 macOS / Apple Silicon；本阶段记录：**106 个后缀的 Finder Space 全量操作已完成；80 项 OrangeLen 内容、23 项系统内容、2 项基础信息失败、1 项 STL 最小样例空白**。

**后续状态**：[原生续修](../single-file-dispatch-2026-10-13/README.md)已解决 STL，启用可恢复的 Hydra 设置后合并结果为 104/106 项可见内容，TS/MTS 仍失败。下文保留设置启用前的完整 106 项现场记录。

## 修复

- 补齐 GLB/glTF/OBJ/STL、NDJSON、INI、CSS、HTML、plist、PDF、TypeScript、TGZ 等实际 UTI 候选声明；Rust/Go/Kotlin/conf/properties 补入自定义源码后缀。
- `local.orangelen.*` 由 OrangeLen 定义，改为导出声明；Excalidraw 保留第三方导入声明。n8np 的类型增加 `public.data` 与 `public.content`，修复原类型仅继承 `public.archive` 而仍被识别为动态类型的问题。未登记泛用 `public.data` 作为 Quick Look 候选，未改其他应用默认关联。
- 移除阅读器按扩展类别关闭专用渲染的条件。系统可能把 glTF 交给 Data、Notebook 交给 Data 或 Code，收到后统一按文件格式选择渲染器。扩展分类继续控制候选登记，关闭某类扩展不保证其他重叠类别也停止该格式渲染。
- `.ts` / `.mts` 的二进制输入转 AVKit，文本继续源码路径；不保证系统可解码所有 MPEG 传输流。
- 大型 glTF/GLB 索引网格在读取索引时按完整三角形抽样，解码仍保持 600,000 索引 / 200,000 三角预算，未抬文件、顶点或渲染内存阈值。简化提示前置；失败时状态栏不再停在加载中。多部件/实例总量、超过 200k 的顶点、稀疏/压缩等限制仍可能拒绝，不保证任意大模型。

Apple 要求预览扩展在 `QLSupportedContentTypes` 中声明支持类型，并区分自有导出类型与第三方导入类型。参见 [Quick Look UI](https://developer.apple.com/documentation/quicklookui/) 与 [类型声明](https://developer.apple.com/documentation/uniformtypeidentifiers/defining-file-and-data-types-for-your-app)。

## 已完成的检查

- **106/106 单文件阅读器 + 106/106 文件夹阅读器**：212 次实质内容检查通过；单文件故意设置为 Code 类别，覆盖跨类别被派发后的专用渲染。覆盖图像、PDF 页、3D 网格、表格记录、结构树、归档成员等，不只检查完成回调。
- **106/106 实际文件 UTI 均有安装包匹配候选**。这是候选资格，不能证明 macOS 最终选择 OrangeLen。
- 入口一致性和原有布局回归 124 项：121 通过 / 3 专用 XPC 宿主测试跳过 / 0 失败。另 19 项高级图形、AI 产出、开发者格式及 HTML 回归全通过。媒体路由 7 项：4 通过 / 3 专用宿主跳过。5 项资源打包测试通过。另大网格、原有高级解析与 UI 回归 21 项全部通过（含四种网格两入口复跑）；越界索引区间、残缺三角形与取消仍被拒绝。
- Debug 与 arm64/x86_64 通用 Release 构建通过；本机 `~/Applications/OrangeLen.app` 更新为最终开发签名 Release。ZIP 为本次开发验证包，未公证、未发布新的 GitHub Release。

## Finder 实测状态

已对 **106 个不同后缀全部实际选中文件并按 Space**。80 项显示 OrangeLen 内容；23 项显示系统内容（包括通过截图确认网格的 OBJ 与有正文的 PDF）；2 项 TS/MTS 仍仅显示基本信息；STL 的原始单三角样例显示系统空白。**103 项主样例可见内容，3 项失败/限制，不能称 106 项单文件全部通过。**

TGZ 在全量测试中发现只有基本信息，增加具体 `org.gnu.gnu-zip-tar-archive` 候选声明后重新打开，归档目录与成员内容已显示。SQLite `.db` 和 EPUB 重新打开后均已显示 OrangeLen 内容，首次图像视图记录不是最终结果。

STL 二进制与 ASCII 封闭立方体补测可见正面网格，但原单三角样例为空白，系统处理器仍接管。保留原失败样例，不以新立方体替换测试用例。对应 `secondary-stl-{cube,ascii}.{png,txt}`；本结论不代表已解决 STL 的系统分派或任意模型可见性问题。

`.ts` / `.mts` 的文件实际 UTI 分别为 MPEG 与 AVCHD 视频类型。即使扩展声明这些候选，本机仍未调用 OrangeLen 源码预览；本轮没有修改系统内置类型、用户文件后缀或其他编辑器关联。可用目录预览或主应用读取原文件。Apple 开发者论坛有[其他预览器作者对同类冲突的直接报告](https://developer.apple.com/forums/thread/796988)，但它不是 Apple 对“无法修复”的官方结论；此处失败结论依据本机实际测试。

用户的原始 9.8 MB 猫模型额外复核：修复分派后发现其有 163,684 顶点 / 296,304 三角形，原解析器拒绝超过预算的索引。加入有界抽样后，**单文件 Space 实际显示 148,152 三角猫网格，旋转与缩放均已观察**。纹理/动画依然省略，抽样会造成孔隙和外观差异，不能用于精确几何审查。原文件未改写。`real-cat-glb-final.{png,txt}` 与 `real-cat-glb-rotated.png` 保存证据；修复前超预算报错也保留。

截图路径优先 `finder-final-<ext>.png`，未重新测的早期项用 `finder-<ext>.png`；对应构建阶段记录在 JSON。原生 XPC 测试宿主在解锁后再次尝试仍停留在启动阶段，已中止，无运行结果，不计为通过。共享阅读器自动回归与真实 Finder 结果分列记录。18 项组件、图表、排版、3D 和科学数据截图另已视觉复核，见 `visual-review-{1,2,3}.jpg`。

以下为全部 106 项清单；“阅读器”是自动化内容检查，“Finder”是现场结果。

| 后缀 | 单文件阅读器 | 文件夹阅读器 | 实际 UTI | 候选类别 | Finder 现场 |
| --- | --- | --- | --- | --- | --- |
| `.astro` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.bash` | 通过 | 通过 | `public.bash-script` | Code | 系统内容可见 |
| `.c` | 通过 | 通过 | `public.c-source` | Code | OrangeLen 内容可见 |
| `.c2pa` | 通过 | 通过 | `local.orangelen.scientific` | Data | OrangeLen 内容可见 |
| `.canvas` | 通过 | 通过 | `local.orangelen.diagram` | Code,Drawings | OrangeLen 内容可见 |
| `.cjs` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.conf` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.config` | 通过 | 通过 | `public.toml` | Data | OrangeLen 内容可见 |
| `.cpp` | 通过 | 通过 | `public.c-plus-plus-source` | Code | OrangeLen 内容可见 |
| `.cs` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.css` | 通过 | 通过 | `public.css` | Code | OrangeLen 内容可见 |
| `.csv` | 通过 | 通过 | `public.comma-separated-values-text` | Code,Data | 系统内容可见 |
| `.cts` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.dart` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.db` | 通过 | 通过 | `local.orangelen.sqlite` | Data | OrangeLen 内容可见 |
| `.diff` | 通过 | 通过 | `public.patch-file` | Code | 系统内容可见 |
| `.drawio` | 通过 | 通过 | `local.orangelen.diagram` | Code,Drawings | OrangeLen 内容可见 |
| `.dxt` | 通过 | 通过 | `local.orangelen.mcpb` | Archives | OrangeLen 内容可见 |
| `.epub` | 通过 | 通过 | `org.idpf.epub-container` | Books | OrangeLen 内容可见 |
| `.excalidraw` | 通过 | 通过 | `com.excalidraw.excalidraw` | Data,Drawings | OrangeLen 内容可见 |
| `.gguf` | 通过 | 通过 | `local.orangelen.scientific` | Data | OrangeLen 内容可见 |
| `.glb` | 通过 | 通过 | `org.khronos.glb` | Drawings | OrangeLen 内容可见 |
| `.gltf` | 通过 | 通过 | `org.khronos.gltf` | Data,Drawings | OrangeLen 内容可见 |
| `.go` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.gql` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.graphql` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.gz` | 通过 | 通过 | `org.gnu.gnu-zip-archive` | Archives | OrangeLen 内容可见 |
| `.h` | 通过 | 通过 | `public.c-header` | Code | 系统内容可见 |
| `.har` | 通过 | 通过 | `local.orangelen.har` | Data | OrangeLen 内容可见 |
| `.hcl` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.hpp` | 通过 | 通过 | `public.c-plus-plus-header` | Code | 系统内容可见 |
| `.htm` | 通过 | 通过 | `public.html` | Code | 系统内容可见 |
| `.html` | 通过 | 通过 | `public.html` | Code | 系统内容可见 |
| `.ini` | 通过 | 通过 | `com.microsoft.ini` | Code | OrangeLen 内容可见 |
| `.ipynb` | 通过 | 通过 | `local.orangelen.notebook` | Data,Markdown | OrangeLen 内容可见 |
| `.java` | 通过 | 通过 | `com.sun.java-source` | Code | 系统内容可见 |
| `.js` | 通过 | 通过 | `com.netscape.javascript-source` | Code | 系统内容可见 |
| `.json` | 通过 | 通过 | `public.json` | Data | OrangeLen 内容可见 |
| `.json5` | 通过 | 通过 | `local.orangelen.json5` | Code,Data | OrangeLen 内容可见 |
| `.jsonc` | 通过 | 通过 | `local.orangelen.jsonc` | Code,Data | OrangeLen 内容可见 |
| `.jsonl` | 通过 | 通过 | `local.orangelen.jsonl` | Code,Data | OrangeLen 内容可见 |
| `.jsx` | 通过 | 通过 | `local.orangelen.component` | Code | OrangeLen 内容可见 |
| `.kt` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.latent` | 通过 | 通过 | `local.orangelen.scientific` | Data | OrangeLen 内容可见 |
| `.less` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.log` | 通过 | 通过 | `com.apple.log` | Code | 系统内容可见 |
| `.lua` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.markdown` | 通过 | 通过 | `net.daringfireball.markdown` | Markdown | OrangeLen 内容可见 |
| `.mcpb` | 通过 | 通过 | `local.orangelen.mcpb` | Archives | OrangeLen 内容可见 |
| `.md` | 通过 | 通过 | `net.daringfireball.markdown` | Markdown | OrangeLen 内容可见 |
| `.mdx` | 通过 | 通过 | `local.orangelen.typesetting` | Code,Markdown | OrangeLen 内容可见 |
| `.mermaid` | 通过 | 通过 | `local.orangelen.mermaid` | Code,Drawings | OrangeLen 内容可见 |
| `.mjs` | 通过 | 通过 | `com.netscape.javascript-source` | Code | 系统内容可见 |
| `.mmd` | 通过 | 通过 | `local.orangelen.mermaid` | Code,Drawings | OrangeLen 内容可见 |
| `.mts` | 通过 | 通过 | `public.avchd-mpeg-2-transport-stream` | Code | 失败：仅基本信息 |
| `.n8np` | 通过 | 通过 | `local.orangelen.n8n-package` | Archives | OrangeLen 内容可见 |
| `.ndjson` | 通过 | 通过 | `public.ndjson` | Data | OrangeLen 内容可见 |
| `.npy` | 通过 | 通过 | `local.orangelen.scientific` | Data | OrangeLen 内容可见 |
| `.npz` | 通过 | 通过 | `local.orangelen.numpy-archive` | Archives | OrangeLen 内容可见 |
| `.obj` | 通过 | 通过 | `public.geometry-definition-format` | Drawings | 系统内容可见 |
| `.parquet` | 通过 | 通过 | `local.orangelen.scientific` | Data | OrangeLen 内容可见 |
| `.patch` | 通过 | 通过 | `public.patch-file` | Code | 系统内容可见 |
| `.pdf` | 通过 | 通过 | `com.adobe.pdf` | Books | 系统内容可见 |
| `.php` | 通过 | 通过 | `public.php-script` | Code | 系统内容可见 |
| `.plist` | 通过 | 通过 | `com.apple.property-list` | Code | OrangeLen 内容可见 |
| `.properties` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.proto` | 通过 | 通过 | `public.protobuf-source` | Code | 系统内容可见 |
| `.ps1` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.py` | 通过 | 通过 | `public.python-script` | Code | OrangeLen 内容可见 |
| `.r` | 通过 | 通过 | `com.apple.rez-source` | Code | 系统内容可见 |
| `.rb` | 通过 | 通过 | `public.ruby-script` | Code | 系统内容可见 |
| `.rs` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.safetensors` | 通过 | 通过 | `local.orangelen.scientific` | Data | OrangeLen 内容可见 |
| `.sass` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.scala` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.scss` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.sh` | 通过 | 通过 | `public.shell-script` | Code | OrangeLen 内容可见 |
| `.skill` | 通过 | 通过 | `com.openai.codex.skill` | Archives | OrangeLen 内容可见 |
| `.sql` | 通过 | 通过 | `org.iso.sql` | Code | 系统内容可见 |
| `.sqlite` | 通过 | 通过 | `local.orangelen.sqlite` | Data | OrangeLen 内容可见 |
| `.sqlite3` | 通过 | 通过 | `local.orangelen.sqlite` | Data | OrangeLen 内容可见 |
| `.srt` | 通过 | 通过 | `local.orangelen.subtitle` | Code,Data | OrangeLen 内容可见 |
| `.stl` | 通过 | 通过 | `public.standard-tesselated-geometry-format` | Drawings | 限制：系统空白；封闭立方体补测可见 |
| `.svelte` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.svg` | 通过 | 通过 | `public.svg-image` | Data,Drawings | 系统内容可见 |
| `.swift` | 通过 | 通过 | `public.swift-source` | Code | OrangeLen 内容可见 |
| `.tar` | 通过 | 通过 | `public.tar-archive` | Archives | OrangeLen 内容可见 |
| `.tex` | 通过 | 通过 | `local.orangelen.typesetting` | Code,Markdown | OrangeLen 内容可见 |
| `.tf` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.tfvars` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.tgz` | 通过 | 通过 | `org.gnu.gnu-zip-tar-archive` | Archives | OrangeLen 内容可见 |
| `.toml` | 通过 | 通过 | `public.toml` | Data | OrangeLen 内容可见 |
| `.ts` | 通过 | 通过 | `public.mpeg-2-transport-stream` | Code | 失败：仅基本信息 |
| `.tsv` | 通过 | 通过 | `public.tab-separated-values-text` | Code,Data | OrangeLen 内容可见 |
| `.tsx` | 通过 | 通过 | `com.microsoft.typescript` | Code | OrangeLen 内容可见 |
| `.txt` | 通过 | 通过 | `public.plain-text` | Code | 系统内容可见 |
| `.typ` | 通过 | 通过 | `local.orangelen.typesetting` | Code,Markdown | OrangeLen 内容可见 |
| `.vtt` | 通过 | 通过 | `org.w3.webvtt` | Data | OrangeLen 内容可见 |
| `.vue` | 通过 | 通过 | `local.orangelen.developer-source` | Code | OrangeLen 内容可见 |
| `.xhtml` | 通过 | 通过 | `public.xhtml` | Data | 系统内容可见 |
| `.xml` | 通过 | 通过 | `public.xml` | Data | OrangeLen 内容可见 |
| `.xmp` | 通过 | 通过 | `org.xmind.openformat.xmp` | Data | OrangeLen 内容可见 |
| `.yaml` | 通过 | 通过 | `public.yaml` | Data | OrangeLen 内容可见 |
| `.yml` | 通过 | 通过 | `public.yaml` | Data | OrangeLen 内容可见 |
| `.zip` | 通过 | 通过 | `public.zip-archive` | Archives | OrangeLen 内容可见 |
| `.zsh` | 通过 | 通过 | `public.zsh-script` | Code | 系统内容可见 |

## 复跑

```sh
ORANGELEN_FORMAT_AUDIT_EVIDENCE_DIR="$PWD/docs/evidence/single-file-audit-2026-10-13" \
  ./scripts/test.sh --filter FormatInventoryAuditTests
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun swift scripts/audit-format-dispatch.swift \
  "$HOME/Applications/OrangeLen.app" Tests/Fixtures/format-audit-106 docs/format-count.md
```

自动测试结果追加到 JSONL，应按最近一轮的 extension/entry 取值。UTI 脚本无匹配候选时返回非零状态；它不会操作 Finder、改变关联或声称内容已渲染。

## 验证范围

样例来自 `Tests/Fixtures/format-audit-106/`，别名复用内容，只覆盖合法小样例与现有渲染子集，不代表完整格式规范、复杂真实文件、跨系统或 Intel 实机。额外真实猫模型已验收简化静态网格；最小 STL 与两个 TypeScript 后缀的失败仍明确保留。
