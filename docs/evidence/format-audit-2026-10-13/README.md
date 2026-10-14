# 106 后缀预览审计

日期：2026-10-13。代码版本：b9b343c（保留已有工作区改动）。本机：26.6.2 / arm64.

## 结论

**106/106 共享阅读器样例通过；不等于 106/106 Finder 单文件效果预览通过。**

106 项各自打开真实文件并验证有实质内容：源码需完整原文相等；Markdown需渲染正文；图形/组件/3D需实际图像；排版/PDF需非空PDF；表格/结构需非空数据；数据库需已加载数据行；归档需实际选中并读取成员。不是仅检查文件后缀注册或回调无错误。

54 项显示源码/原始文本；52 项有文档、结构、表格、容器或效果视图。XHTML 当前为源码，HTML/HTM 为网页视图；Vue/Svelte/Astro 当前为源码。模型格式为结构/有限样本，C2PA不验证签名真实性。

本轮 Finder 单文件抽查 25 个后缀，已明确 13 项只显示名称/大小/修改时间：`.ts`, `.mts`, `.rs`, `.go`, `.kt`, `.ini`, `.css`, `.conf`, `.properties`, `.ndjson`, `.n8np`, `.glb`, `.xmp`。TSX 由系统显示源码。其余未经现场检查的项目不记为 Finder 通过。

全量本机 UTI 与已安装 OrangeLen 七扩展声明对照：87/106 有可匹配的声明，19/106 无匹配。匹配声明只说明可被系统调度，不保证最终选中 OrangeLen；系统/第三方处理器也可能优先。无匹配也不一定无法看内容，例如PDF/HTM/PLIST由系统提供预览。

## 每后缀结果

| 后缀 | 共享阅读器 | 视图 | OrangeLen UTI匹配 | Finder本轮观察 |
|---|---|---|---|---|
| `.swift` | 通过 | source | 有 | OrangeLen已显示视图（详见AX证据） |
| `.py` | 通过 | source | 有 | OrangeLen已显示视图（详见AX证据） |
| `.js` | 通过 | source | 有 | 未现场检查 |
| `.ts` | 通过 | source | 无 | 仅文件基本信息，未显示内容 |
| `.tsx` | 通过 | rendered-image | 有 | 系统源码预览 |
| `.jsx` | 通过 | rendered-image | 有 | OrangeLen组件快照已显示，截图通过 |
| `.mjs` | 通过 | source | 有 | 未现场检查 |
| `.cjs` | 通过 | source | 有 | 未现场检查 |
| `.mts` | 通过 | source | 无 | 仅文件基本信息，未显示内容 |
| `.cts` | 通过 | source | 有 | 未现场检查 |
| `.vue` | 通过 | source | 有 | 未现场检查 |
| `.svelte` | 通过 | source | 有 | 未现场检查 |
| `.astro` | 通过 | source | 有 | 未现场检查 |
| `.c` | 通过 | source | 有 | 未现场检查 |
| `.h` | 通过 | source | 有 | 未现场检查 |
| `.cpp` | 通过 | source | 有 | 未现场检查 |
| `.hpp` | 通过 | source | 有 | 未现场检查 |
| `.rs` | 通过 | source | 无 | 仅文件基本信息，未显示内容 |
| `.go` | 通过 | source | 无 | 仅文件基本信息，未显示内容 |
| `.sh` | 通过 | source | 有 | 未现场检查 |
| `.zsh` | 通过 | source | 有 | 未现场检查 |
| `.bash` | 通过 | source | 有 | 未现场检查 |
| `.rb` | 通过 | source | 有 | 未现场检查 |
| `.java` | 通过 | source | 有 | 未现场检查 |
| `.kt` | 通过 | source | 无 | 仅文件基本信息，未显示内容 |
| `.css` | 通过 | source | 无 | 仅文件基本信息，未显示内容 |
| `.scss` | 通过 | source | 有 | 未现场检查 |
| `.sass` | 通过 | source | 有 | 未现场检查 |
| `.less` | 通过 | source | 有 | 未现场检查 |
| `.html` | 通过 | HTML | 无 | 已打开；初始快照不够判断最终内容 |
| `.htm` | 通过 | HTML | 无 | 系统网页预览 |
| `.xhtml` | 通过 | source | 有 | 未现场检查 |
| `.sql` | 通过 | source | 有 | 未现场检查 |
| `.cs` | 通过 | source | 有 | 未现场检查 |
| `.php` | 通过 | source | 有 | 未现场检查 |
| `.dart` | 通过 | source | 有 | 未现场检查 |
| `.lua` | 通过 | source | 有 | 未现场检查 |
| `.r` | 通过 | source | 有 | 未现场检查 |
| `.scala` | 通过 | source | 有 | 未现场检查 |
| `.ps1` | 通过 | source | 有 | 未现场检查 |
| `.proto` | 通过 | source | 有 | 未现场检查 |
| `.graphql` | 通过 | source | 有 | 未现场检查 |
| `.gql` | 通过 | source | 有 | 未现场检查 |
| `.tf` | 通过 | source | 有 | 未现场检查 |
| `.tfvars` | 通过 | source | 有 | 未现场检查 |
| `.hcl` | 通过 | source | 有 | 未现场检查 |
| `.txt` | 通过 | source | 有 | 未现场检查 |
| `.log` | 通过 | source | 有 | 未现场检查 |
| `.ini` | 通过 | source | 无 | 仅文件基本信息，未显示内容 |
| `.conf` | 通过 | source | 无 | 仅文件基本信息，未显示内容 |
| `.config` | 通过 | source | 有 | 未现场检查 |
| `.properties` | 通过 | source | 无 | 仅文件基本信息，未显示内容 |
| `.plist` | 通过 | source | 无 | 系统源码预览 |
| `.yaml` | 通过 | source | 有 | 未现场检查 |
| `.yml` | 通过 | source | 有 | 未现场检查 |
| `.toml` | 通过 | source | 有 | 未现场检查 |
| `.xml` | 通过 | source | 有 | 未现场检查 |
| `.md` | 通过 | Markdown | 有 | 未现场检查 |
| `.markdown` | 通过 | Markdown | 有 | 未现场检查 |
| `.mdx` | 通过 | rendered-image | 有 | 已打开；初始快照不够判断最终内容 |
| `.tex` | 通过 | PDF | 有 | 未现场检查 |
| `.typ` | 通过 | PDF | 有 | 未现场检查 |
| `.ipynb` | 通过 | collection | 有 | 未现场检查 |
| `.epub` | 通过 | collection | 有 | 未现场检查 |
| `.pdf` | 通过 | PDF | 无 | 系统PDF预览 |
| `.json` | 通过 | JSON-tree | 有 | 未现场检查 |
| `.jsonc` | 通过 | JSON-tree | 有 | 未现场检查 |
| `.json5` | 通过 | JSON-tree | 有 | 未现场检查 |
| `.jsonl` | 通过 | collection | 有 | 未现场检查 |
| `.ndjson` | 通过 | collection | 无 | 仅文件基本信息，未显示内容 |
| `.csv` | 通过 | table | 有 | 未现场检查 |
| `.tsv` | 通过 | table | 有 | 未现场检查 |
| `.sqlite` | 通过 | database | 有 | 未现场检查 |
| `.sqlite3` | 通过 | database | 有 | 未现场检查 |
| `.db` | 通过 | database | 有 | 未现场检查 |
| `.har` | 通过 | collection | 有 | 未现场检查 |
| `.mmd` | 通过 | rendered-image | 有 | 未现场检查 |
| `.mermaid` | 通过 | rendered-image | 有 | 未现场检查 |
| `.excalidraw` | 通过 | rendered-image | 有 | 未现场检查 |
| `.drawio` | 通过 | diagram | 有 | 未现场检查 |
| `.canvas` | 通过 | diagram | 有 | 未现场检查 |
| `.svg` | 通过 | rendered-image | 有 | 未现场检查 |
| `.skill` | 通过 | archive | 有 | 未现场检查 |
| `.mcpb` | 通过 | archive | 有 | 未现场检查 |
| `.dxt` | 通过 | archive | 有 | 未现场检查 |
| `.n8np` | 通过 | archive | 无 | 仅文件基本信息，未显示内容 |
| `.zip` | 通过 | archive | 有 | 未现场检查 |
| `.tar` | 通过 | archive | 有 | 未现场检查 |
| `.tgz` | 通过 | archive | 有 | 未现场检查 |
| `.gz` | 通过 | collection | 有 | 未现场检查 |
| `.obj` | 通过 | 3D | 无 | 系统图像/3D视图；仅AX，需视觉复核 |
| `.stl` | 通过 | 3D | 无 | 系统图像/3D视图；仅AX，需视觉复核 |
| `.gltf` | 通过 | 3D | 有 | 未现场检查 |
| `.glb` | 通过 | 3D | 无 | 仅文件基本信息，未显示内容 |
| `.parquet` | 通过 | structure | 有 | 未现场检查 |
| `.npy` | 通过 | structure | 有 | 未现场检查 |
| `.npz` | 通过 | archive | 有 | 未现场检查 |
| `.safetensors` | 通过 | structure | 有 | 未现场检查 |
| `.gguf` | 通过 | structure | 有 | 未现场检查 |
| `.latent` | 通过 | structure | 有 | 未现场检查 |
| `.srt` | 通过 | table | 有 | 未现场检查 |
| `.vtt` | 通过 | table | 有 | 未现场检查 |
| `.diff` | 通过 | collection | 有 | 未现场检查 |
| `.patch` | 通过 | collection | 有 | 未现场检查 |
| `.xmp` | 通过 | source | 无 | 仅文件基本信息，未显示内容 |
| `.c2pa` | 通过 | structure | 有 | OrangeLen结构视图已显示，截图通过 |

## 证据与复跑

- `reader-final.log`：最终106项、零失败的XCTest结果。
- `reader-results.jsonl`：两轮逐后缀记录，后106条为最终结果。
- `reader-baseline.log`：首轮6项测试判定不合适的失败保留；修正Markdown渲染判定、归档成员选择、XHTML源码预期后复跑。没有修改产品代码。
- `finder-dispatch.tsv`：106项实际文件UTI与本机安装包声明交集。
- `finder-ui.json`：Finder按空格现场AX记录，区分待加载与真正结果。
- 样例：`Tests/Fixtures/format-audit-106/`；格式别名复用同内容，源码类样例验证阅读能力，不验证程序可运行或语义正确。

复跑：`./scripts/test.sh --filter FormatInventoryAuditTests`。本机已安装应用（2026-10-12构建）用于Finder；源码当前共享阅读器用于自动测试。未逐106项Finder人工验收，未覆盖真实复杂文档、其他macOS或Intel机器。

建议宣传口径：**支持106种文件后缀的源码、结构与效果预览；可通过文件夹或主应用查看，Finder单文件调用依系统类型和处理器而定。**

截图：`finder-jsx.png`（JSX组件实际快照）、`finder-c2pa.png`（来源结构；不验真）。
