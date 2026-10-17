# 2026-10-16 — Syntax Highlight 格式对齐验证

范围：本聊天用户要求支持 Syntax Highlight 所支持的文件后缀。固定参考 2.1.32 / `a8eb669d49c2d1a019b5dc7d11d1adb8ee34a162`，未安装竞品或重新克隆竞品源码。

## 已实现

- 新增 215 个明确后缀，总计 363 后缀 / 49 特殊文件名 / 7 前缀规则。对应竞品的 282 个候选后缀均有明确阅读路径，详见 [coverage.json](coverage.json)。
- 219 个集中维护的源码/配置别名（其中 4 个原来已有）；离线语言高亮及 18 组小型词法规则/模板别名。
- 二进制 plist 转 XML、Java class 声明/原始字节码、隔离 AppleScript 源码提取、编译 AutoIt 有界字节视图。具体边界见[支持说明](../../syntax-highlight-parity.md)。
- Workspace JSONC 及 Oracle SQL/Typst 同名后缀处理；语言对应样例、截断/取消/结构上限验证。

## 实际验证

- 最终 Xcode Debug 应用构建成功：`syntax-parity-build.log`。
- SwiftPM 相关测试：31 项，1 项因需要原生 XPC 宿主跳过，其余通过：`syntax-parity-tests.log`。循环实际读取 218 个文本后缀样例，Java 二进制另测；所有注册语言组逐别名验证高亮 token 与原文不变。
- 原生 test host：3 项通过，包括真正的 sandbox XPC 编译 AppleScript 源码提取：`syntax-parity-native-tests.log`。这包含与 SwiftPM 重复的阅读器/高亮测试，不将两套数字简单当作不同测试相加。
- 共享原生文档服务的 Word/媒体读取回归 1 项通过：`syntax-parity-office-regression.log`。
- README 中英文及格式清单均为 363 个去重后缀：[inventory-verification.json](inventory-verification.json)。`scripts/sync-source-formats.py --check` 通过。
- 本机 Apple Development 签名安装至 `~/Applications/OrangeLen.app` 和 `/Applications/OrangeLen.app`，两份 deep/strict 校验通过：[installed.json](installed.json)。旧版备份位置见 [install-backups.json](install-backups.json)。没有更新公开 Release。

## Finder 真实空格验收

CUA 在 Finder 选中文件并按空格，以下 7 个合成代表样例均观察到 OrangeLen 正文。结果及证据文件名见 [finder-results.json](finder-results.json)。

| 文件 | 实际观察 |
| --- | --- |
| `sample.jl` | Julia 函数、类型与关键字高亮 |
| `sample.gleam` | Gleam 函数及中文 emoji 字符串 |
| `sample.as` | ActionScript 类源码；本机该后缀关联 AppleSingle 归档，仍进入 OrangeLen |
| `sample.edn` | Clojure 语法源码文本；本机该后缀关联 Adobe 类型 |
| `sample.class` | JVM 版本、类/父类、构造方法描述符与字节码 |
| `compiled.scpt` | 隔离提取的 AppleScript 源码，含中文 emoji |
| `binary.plist` | 从二进制 plist 转出的 XML，字段值完整 |

本表不是全部 363 后缀或全部真实文件的 Finder 通过率。后续 PUB 等导航尝试受 Finder 窗口/定位状态变化影响，没有完成产品预览验证，不记为产品通过或失败。此前 TS/MTS、DOT、无后缀文件等入口限制不因新增清单自动解除。

## 过程中发现并修复的问题

- 损坏的 `bplist00...` 可能被 Foundation 当成 OpenStep 字符串接受：现在要求解析出的 plist format 必须为 binary，再进行 XML 转换。
- 首次 Finder Julia 预览失败：新注册表直接访问 `Bundle.module`，而正式应用会合并 SwiftPM 资源，日志报 unable to find bundle。已改用项目既有 `PackageResources.bundle(.core, fallback:)` 共享框架入口；重建、重装后，上述 7 个实际预览通过。
- 首次原生测试与应用构建误共用正在写入的 DerivedData，出现数据库锁：已顺序重跑成功。原失败日志保留在 `build/syntax-parity-native-concurrent-attempt.log`，不伪装成测试通过。
- 首次安装脚本在清理自身临时目录时报 Directory not empty；随后已完成最终安装及两份应用的严格签名复核，不将脚本尝试本身作为安装成功依据。

截图和原始日志为本地证据，按仓库规则忽略；结构化结果与测试夹具保留。无提交、推送、公证新版或对外发布。
