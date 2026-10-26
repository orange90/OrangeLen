# V1.0.2 公证发布验证

2026-10-26 · macOS 26.6.2 / Apple Silicon / Xcode 26.5。

## 构建与测试

- 构建源码提交：`3827fa5d34a1887ed8240770a0a31f1a6a5e2d49`；后续发布说明及验证记录不改变产品构建输入。
- 应用与 7 个 Quick Look 扩展均为 `1.0.2` / build `5`。
- 24 个 Mach-O 文件均包含 arm64 与 x86_64，包括应用、扩展、XPC、框架及原生组件。
- 完整 Swift 回归 315 项，4 项按环境跳过，零失败；10 项 Python 类型登记与资源测试通过。
- 正式签名 Team 为 `C7J9CK5X87`，与前一公开版本一致；deep/strict 验签通过。

具体文件与架构见 [distribution-checks.json](distribution-checks.json)。

## 类型声明与资源

对实际正式签名应用执行 [类型登记检查](../../../scripts/audit-type-registration.py)，仅使用产品声明与当前系统 CoreTypes：339 个后缀由应用自行登记、32 个由 CoreTypes 提供，合计 371；缺少后缀登记、缺少父类型、缺少预览候选均为 0。完整包内结果见 [type-registration.json](type-registration.json)。

签名前的资源完整性检查发现构建末尾重新复制的两个 SwiftPM 资源包；在确认内容完全相同后运行既有去重工具，再次验证只有一个共享资源框架。没有绕过资源校验，最终安装包不包含重复资源包。初次拒绝、去重及签名重试日志均保留在本地。

## 公证与分发

应用和 DMG 均获 Apple 公证 `Accepted`，均附加并验证票据，Gatekeeper 返回 `Notarized Developer ID`；DMG 内部校验通过。文件大小、SHA-256 与两次提交 ID 见 [distribution.json](distribution.json)。

发布资产：`OrangeLen-1.0.2-universal.dmg` 和 `OrangeLen-1.0.2-SHA256SUMS.txt`。公开下载验证在发布后另行记录，不以本地产物校验替代。

## 范围

这是类型登记完整性修复。上述 371 项检查证明声明资格，不证明 Finder 一定选择 OrangeLen。本轮未重新进行全量 Finder 验收、干净 macOS 27 或 Intel 实机验证；TS/MTS/DOT 及已有格式子集限制保留。旧本机 Finder 成功不再作为干净环境可用的证明。

构建、测试、公证和签名日志在本机 `build/release-1.0.2/`；公证阶段产物在 `build/notarized-1.0.2/`，不将签名材料或钥匙串配置入 Git。本轮发布流程未替换日常 Applications 安装。
