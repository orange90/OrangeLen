# 原生单文件预览续修：STL 与 TS/MTS

2026-10-13 · macOS 26.6.2 / Apple M3 Pro / Xcode 26.5。

**STL 已修复并完成 Finder 单选 Space 实测；当前合并清单为 104/106 项可见内容，TS/MTS 两项仍失败。** 用户明确选择“只接受原生 Quick Look 扩展”，本次未增加常驻键盘辅助功能或辅助功能权限。

## 已交付

- STL 的实际 UTI 已有 OrangeLen 候选，但 macOS 26 的 `com.apple.HydraQLPreviewExtension` 优先接管。只停用当前用户的 Hydra election 后，Finder 调用 OrangeLen Drawings 扩展，原先空白的单三角网格可见。
- [设置脚本](../../../scripts/prefer-mesh-preview.sh) 提供 `enable` / `restore` / `status`，首次修改保存原有 election，重复启用不覆盖备份，恢复会还原原有 `use` / `ignore` / `default`。
- 主应用“Quick Look 诊断”增加复制 STL/OBJ 修复、恢复命令。脚本随应用打包；应用沙盒不直接修改系统登记。命令按钮及英文说明已现场操作核验。
- 此 Mac 已启用修复；本机应用已更新至通用 Release、Apple Development 签名，deep/strict 验签通过。未公证、未提交、未推送或发布新 Release。

设置同时停用 Hydra 对 PLY、USD、MaterialX、Alembic 的预览，系统回退可能不同。这些类型不属于本次 106 后缀清单，未逐一验证；不能宣称完全没有影响。不会修改系统文件、源文件、后缀或默认打开应用。正常安装不自动替用户停用 Hydra。

本机恢复命令：

```sh
/bin/bash "$HOME/Applications/OrangeLen.app/Contents/Resources/prefer-mesh-preview.sh" restore
```

源码安装可在仓库运行 `./scripts/prefer-mesh-preview.sh enable`。其他机器通过应用诊断按钮复制其实际路径，避免假定安装目录。

## Finder 结果

| 样例 | 原生单文件 Space 结果 | 证据 |
| --- | --- | --- |
| audit.stl，1 个三角形 | OrangeLen 网格可见 | 截图（本机留档：`final-stl.png`）、[AX](final-stl.txt) |
| secondary-stl-cube.stl，二进制 | 12 三角立方体可见 | 截图（本机留档：`stl-binary-cube.png`）、[AX](stl-binary-cube.txt) |
| secondary-stl-ascii.stl，ASCII | 12 三角立方体可见，旋转有效 | 截图（本机留档：`stl-ascii-cube.png`）、旋转后（本机留档：`stl-ascii-rotated.png`） |
| audit.obj | OrangeLen 四面体可见 | 截图（本机留档：`final-obj.png`）、[AX](final-obj.txt) |
| audit.gltf | OrangeLen 三角网格可见 | 截图（本机留档：`final-gltf.png`）、[AX](final-gltf.txt) |
| audit.glb | OrangeLen 三角网格可见 | 截图（本机留档：`final-glb.png`）、[AX](final-glb.txt) |
| audit.ts | 系统仅基本信息，失败 | 截图（本机留档：`final-ts.png`）、[AX](final-ts.txt) |
| audit.mts | 系统仅基本信息，失败 | 截图（本机留档：`final-mts.png`）、[AX](final-mts.txt) |

[合并 106 项记录](finder-results.json) 含 82 项 OrangeLen 内容、22 项系统内容、2 项失败。六个后缀本轮复测，其余 100 项引用[前一阶段完整 Finder 实测](../single-file-audit-2026-10-13/README.md)，`evidence_source` 标明来源；没有把旧截图当作本轮全量复测。共享解析器和渲染器未在本轮修改。

## TS/MTS 原生尝试与阻塞

本机实际类型分别是 `public.mpeg-2-transport-stream` 与 `public.avchd-mpeg-2-transport-stream`。纯 TypeScript 样例也被归到视频类型。

1. 独立导出 TypeScript UTI，声明 `.ts` / `.mts`，增加宿主 Viewer 文档类型与扩展候选：实际文件类型仍是系统 MPEG/AVCHD，Space 仅基本信息。见 [声明](custom-types-app.plist)、[类型](custom-types-dispatch.tsv)、现场（本机留档：`custom-types-ts.png`）。
2. 使用 Apple 的数据式 `QLPreviewProvider` / `QLPreviewReply` API：控制样例 `.cts` 的请求进入原型 provider（运行日志（本机留档：`data-provider-runtime.log`））；`.ts` / `.mts` 未进入，仍仅基本信息，STL 仍被 Hydra 接管。控制样例首次截图仍为加载中，未将其记为内容通过。见 `data-provider-{ts,mts,stl}.{png,txt}`。
3. 临时将两种系统视频类型的 Viewer 默认应用设为 OrangeLen：两项 Space 仍失败。已恢复原应用关联，见 `default-viewer-{set,restore}.txt` 与 `default-viewer-final.txt`。清理时移除两条试验生成的 Viewer override，并重载当前用户 Launch Services；其他关联保留，最终查询与试验前一致（`default-viewer-cleanup.txt`）；现场见 `default-viewer-{ts,mts}.png`。

原型已经回退，最终安装包仍是 view-based 原生扩展，没有自定义冲突 UTI 或默认应用关联改动。CLI 强制 contentType、主应用读取、文件夹内读取不能替代用户要求的原后缀单文件 Space 通过。

这些结果说明本机尝试仍不能完成 TS/MTS 原生单文件入口，并非 Apple 官方对所有版本都无法实现的结论。相关[Apple API 文档](https://developer.apple.com/documentation/quicklookui/qlpreviewprovider)、[其他预览器开发者的同类报告](https://developer.apple.com/forums/thread/796988)及 [Syntax Highlight 作者记录](https://github.com/sbarex/SourceCodeSyntaxHighlight)可作背景；失败判断依据本机实测。STL 的 Hydra 设置方向参考 [Filament 作者说明](https://github.com/akshaymaloo/filament#stlobjply-previews-on-macos-26)，本机独立验证。

## 验证与边界

- 7 项相关回归（本机留档：`targeted-tests.log`）全部通过：TS/MTS/STL 三后缀两入口内容检查及 4 项本地化测试。完整 212 项阅读器检查沿用前一阶段记录，不重算为本轮测试。
- 设置脚本实际执行重复启用、状态检查、恢复再启用；原 default election 被恢复，最后再启用修复。见 `mesh-{enable,restore}.txt`、`hydra-final-election.txt`。未改动 SceneKit 或其他 Quick Look 扩展。
- 通用 Release 构建（本机留档：`final-build.log`）、安装（本机留档：`final-install.log`）、[106 实际类型候选检查](final-dispatch.tsv)通过，后者不代表内容通过。
- 调试安装替换过程中有一次旧扩展身份失效的基础信息画面，安装完成、重置 Quick Look、重新打开后完成上述最终验收；首次冷启动加载中截图也已用最终内容截图更新。
- 几何、纹理、动画及大模型抽样限制沿用[高级预览范围](../../advanced-output-previews.md)。其他 macOS 版本、Intel 实机、106 后缀的全部格式变体不在已完成验收范围。

后续已对照其他预览器源码，并追加四组原生类型/配置方向实测，TS/MTS 仍未解决；见 [原生研究记录](../ts-native-research-2026-10-13/README.md)。
