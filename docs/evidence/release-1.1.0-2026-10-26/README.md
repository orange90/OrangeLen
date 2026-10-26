# V1.1.0 公证发布验证

2026-10-26 · macOS 26.6.2 / Apple Silicon / Xcode 26.5。

## 构建与签名

- 产品源码提交 `07b6f4a`，版本 1.1.0 / build 6；应用和 7 个扩展版本一致。
- 29 个 Mach-O 全部含 arm64、x86_64；使用与上一公开版本相同的 Developer ID Team C7J9CK5X87。
- Sparkle 2.9.6 仅主应用链接；内嵌安装器与更新助手分别签名，deep/strict 验证通过。
- 资源一致性检查通过。371 后缀类型声明检查为 339 产品 + 32 CoreTypes，0 缺口。
- 同一更新实现此前完整 Swift 测试 315 项（4 条件跳过、0 失败）；版本号变更后 16 项 Python 检查通过。

见 [分发检查](distribution-checks.json)、[类型声明](type-registration.json)。

## 公证与更新清单

应用与 DMG 均获 Apple 公证 Accepted，票据、Gatekeeper、签名和 DMG 完整性检查通过。
提交 ID、体积和 SHA-256 见 [distribution.json](distribution.json)。

`appcast.xml` 使用更新钥匙串项生成签名，包含当前版本、最低系统、内嵌更新说明和版本化 DMG 链接。
发布前验证 feed 与安装包的 Ed25519 签名，公开固定源为：
`https://github.com/orange90/OrangeLen/releases/latest/download/appcast.xml`。

## 验证边界

独立标识测试 App 已实测签名清单发现、下载、安装和自动重启；详见[本地验收](../app-updates-2026-10-26/README.md)。
该测试使用本机 HTTP 与 ZIP、移除了 Quick Look 扩展，不等同于公证 DMG 的完整升级及真实扩展换版验收。
本次首发供旧用户手动安装，不宣称 V1.0.2 可自行升级到 V1.1.0。
Intel 实机、跨系统、真实 Finder 全量及扩展换版尚未完整验收，TS/MTS/DOT 限制保留。
未替换用户日常 Applications 安装。

## 公开发布后核验

[V1.1.0](https://github.com/orange90/OrangeLen/releases/tag/V1.1.0) 已发布并设为 latest 稳定版。无认证重新下载 116340140 字节 DMG，SHA-256 与本地、校验文件和 GitHub 资产摘要一致；固定 latest/download/appcast.xml 返回本版，feed 与 DMG 的 Ed25519 签名通过。公开包的票据、Gatekeeper 和完整性通过；只读挂载后，应用及七扩展版本、29 个通用 Mach-O、deep/strict 签名、应用公证票据和371后缀声明再次通过。详见 [public-download.json](public-download.json)。

发布后 GitHub API 首次回读遇到 TLS 超时，确认已发布后仅重试读取与下载，没有重复创建或发布。此记录为发布后的独立提交，不移动 V1.1.0 标签。
