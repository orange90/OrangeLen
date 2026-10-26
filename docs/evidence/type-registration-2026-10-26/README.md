# 文件类型登记独立性审计

2026-10-26 · macOS 26.6.2 / Xcode 26.5 / Apple Silicon。

## 结论

对 [371 个明确后缀](../../format-count.md) 逐项对照应用包声明、系统 CoreTypes 与 Xcode 声明，发现除 SQL 外还有 **INI、CONFIG、TOML 三个同类登记缺口**。这里确认的是安装包缺少独立登记，不宣称已在干净系统复现所有后缀的 Finder 行为。

| 后缀 | 本机对应类型 | V1.0.1 应用声明 | 本机提供登记的来源 | 处理 |
|---|---|---|---|---|
| `.sql` | `org.iso.sql` | 无后缀登记 | Xcode，有效 imported 声明 | 上轮已加入自有源码类型 |
| `.ini` | `com.microsoft.ini` | 无后缀登记 | Xcode，有效 imported 声明 | 本轮补入 imported 声明 |
| `.config`、`.toml` | `public.toml` | 无后缀登记 | Xcode，有效 imported 声明 | 本轮补入 imported 声明，兼容既有 `.cfg` 别名 |
| `.md`、`.markdown` | `net.daringfireball.markdown` | 无后缀登记 | 当前有效声明为 MacDown；系统 Notes、Xcode 等也有声明 | 本轮补入 imported 声明，提高独立性；不归类为仅依赖 Xcode |

本机系统 Notes 的 plist 已提供 Markdown 登记，因此不能认定这两个后缀在当前系统缺少 Xcode 就会失败。其他系统版本是否有同一声明，本轮未验证。

371 项中有 54 项也被 Xcode 声明。不能把这 54 项全部判为问题：其余后缀已有 OrangeLen 后备声明或系统 CoreTypes 登记，例如 Swift、C/C++、Python、Shell、JSON、YAML。

## 依据与方法

- 旧包基线：`/Applications/OrangeLen.app`，版本 1.0.1/build 4；其 Info.plist SHA256 与本地公证阶段保留的 `build/notarized-1.0.1/OrangeLen.app` 完全一致。摘要见 [summary.json](summary.json)。
- 本机来源：修复前读取 `lsregister -dump`，并核对 Xcode 与 Notes 的实际 Info.plist。所关注的类型与来源见 [type-providers.json](type-providers.json)。完整注册表仅保留在本地 `build/type-registration-audit/launchservices.txt`。
- 独立性检查只读取主应用、七个扩展的 plist，以及 `/System/Library/CoreServices/CoreTypes.bundle` 下的类型声明；不调用本机 `UTType`，不使用 Xcode、编辑器、Notes 的登记填补缺口。
- 同时检查主应用类型的递归父类型是否齐全，以及后缀对应类型是否存在匹配的预览扩展候选。候选资格不等于系统最终选择该扩展。
- 完整逐项结果见 [all-371.csv](all-371.csv)，含旧包声明、系统类型、Xcode 类型、修复后声明与预览候选。

| 检查对象 | 应用自行登记 | 仅由 CoreTypes 提供 | 严格基线下缺少登记 |
|---|---:|---:|---:|
| V1.0.1 原包 | 333 | 32 | 6 |
| 仅补 SQL 的源码 | 334 | 32 | 5 |
| 本轮修复后的源码与实际 Debug 包 | 339 | 32 | 0 |

旧包的 6 项中，4 项由本机 Xcode 补足；另 2 项 Markdown 也有系统 Notes 声明。本轮采用更严格的“应用 + CoreTypes”基线，一并消除对其他应用声明的依赖。

## 修复与验证

主应用新增三个 imported 类型声明：INI、TOML、Markdown。沿用现有类型标识与对应扩展支持列表，不修改读取和渲染逻辑。

- 新增注册检查在修复前检出 5 项剩余缺口，修复后通过。
- 5 项注册检查与 5 项已有资源打包测试通过；INI、CONFIG、TOML、MD、MARKDOWN 的 5 项阅读器测试通过，均覆盖单文件及文件夹入口。
- Debug 构建首次因增量资源合并校验失败；串行重试构建成功，随后资源完整性检查通过。失败和重试日志均保留，没有绕过资源校验。
- 对实际 `.app` 再次执行 371 项检查：缺少登记 0、缺少预览候选 0、缺少父类型 0；源码与包内结果一致。
- 本地 `scripts/test.sh` 已包含注册检查；GitHub Actions 增加构建后检查最终 `.app` 的步骤。远程 CI 本轮尚未运行。

复核命令：

```sh
python3 scripts/audit-type-registration.py
python3 scripts/audit-type-registration.py --app build/DerivedData/Build/Products/Debug/OrangeLen.app --output build/type-registration.json
python3 -m unittest discover -s scripts/tests
./scripts/test.sh --filter 'FormatInventoryAuditTests.test_(ini|config|toml|md|markdown)$'
```

本地日志在 `build/type-registration-audit/`：`tests-before.log`、`reader-tests.log`、`build.log`、`build-retry.log`、`product-after.json`。

## 边界

本轮是 371 后缀的声明及继承关系审计，不是新一轮 371 项 Finder 实测，也不是干净 macOS 虚拟机验证。CoreTypes 基线来自当前 macOS 26.6.2，不据此声称所有支持系统版本均验证通过；CI 将在各运行环境检查各自的系统基线。

49 个特殊文件名及 7 组前缀规则不属于本轮后缀登记统计；内容读取支持不能替代其 Finder 入口验证。TS/MTS/DOT 的系统类型冲突和既有预览优先级问题仍然存在，不能由本次“登记缺口为零”推出它们已修好。

本轮未替换日常安装、提交或推送代码、发布新安装包。旧 V1.0.1 下载包仍包含原有缺口。
