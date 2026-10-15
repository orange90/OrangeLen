# OrangeLen Mac App Store 上架差距检查

检查日期：2026年10月14日。源码基线：`dbb2951`，同时检查当前工作树。当前应用可沿用原生主应用、Quick Look 扩展和沙盒 XPC 架构；上架主要差距在分发配置、共享权限、许可证打包、隐私入口和用户引导。

本次完成源码检查及独立的无签名通用 Archive。未登录 App Store Connect 核验应用记录、协议或证书，也未执行商店签名、上传验证、TestFlight 安装或新系统现场验收。因此“Archive 成功”仅说明归档结构和编译可行，不代表 Apple 已接受商店构建。

## 只需后台或工程配置

| 项目 | 当前情况 | 需要完成的工作 |
| --- | --- | --- |
| 商店签名 | `project.yml` 默认 Manual、签名身份为 `-`，没有团队和商店描述文件；公证脚本使用 Developer ID | 为主应用和七个扩展配置团队、显式 App ID、App Store 分发证书及相应描述文件；根据 Xcode 导出流程配置 Mac Installer Distribution。无需修改解析器 |
| Bundle ID | 主应用 `local.OrangeLen`，扩展使用其子标识 | 核验这些 ID 能否在团队注册并用于应用记录。`local.` 前缀本身不能据此判为非法；无需为了命名美观强制更换。若更换，须检查 XPC 服务名、脚本、资源校验和旧设置迁移，届时会涉及代码 |
| 商店记录与协议 | 本次没有后台状态证据 | 创建 macOS 应用记录；填写 SKU、名称、分类、年龄分级、地区和定价；付费时完成对应协议、税务及银行信息 |
| 商店资料 | 现有 README 和截图可作为素材，不是完整商店元数据 | 准备真实截图、中英文描述、关键词、支持 URL、隐私政策 URL、审核联系人和审核备注 |
| 版本号 | 普通 Archive 为 `0.1.0` / build `1`，现公证发布使用 preview.2 / build `2` | 明确首个稳定版本，并让主应用、七扩展和发布记录保持一致；build 按实际上传记录递增。两个 XPC 的 plist 当前写死 `1.0` / `1`，建议统一使用工程变量，避免版本管理混乱 |
| 更新渠道 | 未发现应用内自行下载安装更新的实现 | 商店版通过商店更新，保留 GitHub 独立下载渠道即可；当前无需新增更新代码 |
| ATS 例外 | 主应用与七扩展声明 `NSAllowsArbitraryLoadsInWebContent=true` | 为本地 HTML 预览加载用户文件中的 HTTP 外部资源提供具体审核理由。可保留并说明；不能直接判断必须删除。若决定仅允许 HTTPS，需要产品行为调整及回归 |

依据：[Apple 证书类型](https://developer.apple.com/help/account/certificates/certificates-overview/)、[App Store 描述文件](https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile)、[创建应用记录](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)、[Web 内容 ATS 例外](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowsarbitraryloadsinwebcontent)。

## 需要修改工程资源或代码

### 提交前应完成

| 项目 | 已核验的差距 | 最小改动 |
| --- | --- | --- |
| 应用内隐私政策入口 | `AppDelegate.swift` 和 `SettingsView.swift` 均没有隐私政策链接 | 在菜单或设置页加入可访问的隐私政策入口，同时提供公开网页。Apple 要求 App Store Connect 与应用内都可访问隐私政策 |
| 许可证进入商店归档 | 无签名 Archive 内没有第三方 LICENSE 文件；当前公证脚本通过 `ditto docs/licenses` 补入。`project.yml` 虽有 resources 配置，已提交 pbxproj 中没有对应许可证资源引用 | 修正工程生成配置和实际 Xcode 资源阶段，使 Archive 自身包含 `docs/licenses` 的许可证与 NOTICE；建议增加“第三方许可”查看入口。不能依赖公证打包脚本替商店包补文件 |
| 共享设置与目录授权配置 | Archive 的主应用 Info.plist 没有 `OrangeLenAppGroup`；源码 entitlement 无 App Groups；仅 `package-notarized.sh` 在签名阶段注入 | 将共享 group、主应用/扩展 entitlement 与 Info.plist 配置落实到商店构建。保留现有 SettingsStore/ImageDirectoryGrant 逻辑，复验应用与 Finder 设置同步、授权有效期和退出清理 |
| 商店构建可重复生成 | 现有发布脚本面向 Developer ID、公证和 DMG；没有商店导出配置 | 增加独立商店配置或 scheme/export 配置，直接由 Archive 导出商店签名产物。改动应同步 `project.yml` 与生成工程，避免下次生成覆盖 |

App Groups 支持 `<Team ID>.<group name>` 的 macOS 命名方式；不能机械要求现有 group 改成 `group.`。具体分发能力与最终 entitlement 应以商店签名验证为准。[Apple App Groups 文档](https://developer.apple.com/documentation/xcode/accessing-app-group-containers)

隐私政策至少说明：本地文件处理、本地设置及可选阅读记录、临时目录授权、主动加载 Markdown 远程图片，以及 HTML 页面执行脚本和加载网络资源。远程服务器可能获得 IP 地址和请求信息；非持久 WebKit 会话并不意味着完全离线。App Store 隐私标签应按最终数据流填写，不能仅凭“没有自建服务器”直接勾选全部不收集。[应用隐私管理](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)

### 建议修改以降低审核和使用摩擦

| 项目 | 当前情况 | 建议与边界 |
| --- | --- | --- |
| 系统 3D 预览修复入口 | `DiagnosticsController` 可复制命令，打包的 `prefer-mesh-preview.sh` 会停用 `com.apple.HydraQLPreviewExtension` 并刷新 Quick Look；应用没有自行执行它 | 商店版隐藏这两个修改系统预览选择的命令按钮，并排除对应脚本；保留类型诊断、扩展设置和应用内阅读。属于降低审核风险的建议，未发现 Apple 明文禁止这个特定按钮；不能说已确定会被拒 |
| 首次使用引导 | 默认空白阅读器提示 Cmd O；扩展设置入口藏在诊断页 | 增加简短欢迎页或设置说明，介绍 Finder Space、启用扩展、目录授权和可打开的示例文件。属于体验改进，不是必须做复杂 onboarding 的审核条款 |
| HTML 联网提示 | `HTMLPreview.swift` 开启 JavaScript，自动加载页面外部资源；README 有说明，应用入口未见同等清晰说明 | 在 HTML 预览入口提供简洁的脚本/联网说明或选择入口。维持已明确要求的动态 HTML 功能，不能在本次检查中擅自改成静态。没有原生文件/命令桥，使用非持久 WebKit 会话 |
| 隐私清单 | 源码与 Archive 均没有 `PrivacyInfo.xcprivacy`；代码使用 UserDefaults、systemUptime、文件时间戳等 API | 建议加入清单并核对每个包含相关代码的 bundle；属于资源及工程配置工作，不需要重写这些 API。Apple Required Reason API 当前文档的列举平台没有原生 macOS，所以本检查不将缺少清单直接判为原生 Mac 上架必然阻断。最终用导出、上传校验核验 |
| 文档准确性 | README 第95行仍称下载为 preview.1，不含未发布修复；`docs/dependencies.md` 留有旧版“不运行外部工具”和旧高亮描述 | 更新发布范围和依赖文档，商店文案基于当前版本实测写，避免把历史记录写成当前状态 |

依据：[审核规则 2.4.5 与 5.1.1](https://developer.apple.com/app-store/review/guidelines/)、[Required Reason API 适用范围](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)、[macOS 隐私清单放置位置](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk)。

## 应验证后再决定是否改代码

- **干净安装的 Finder 分派**：历史 104/106 结果包含停用 Hydra 的本机设置，并包含系统接管显示的格式。商店版必须在默认系统状态下重新记录 OrangeLen 显示、系统显示、无内容三类结果。TS/MTS 限制可通过准确标注支持范围处理，不能默认判定必须全部解决才能上架。
- **共享权限与沙盒行为**：从商店签名构建验证设置共享、目录选取、邻接图片/HTML 资源和主应用关闭后的授权终止；普通无签名 Archive 不能替代这个检查。
- **最低系统和 Intel**：部署目标 macOS14，通用二进制已生成。现有主要实测在 Apple Silicon/macOS26；应至少覆盖最低支持系统、当前系统和 Intel 实机，或据验证缩小声明范围。缺少 Intel 实测不等于构建失败。
- **网络路径与 ATS**：验证 HTML HTTP/HTTPS、本地资源、源码回退，以及 Markdown 主动 HTTPS 图片下载，准备审核备注解释二者不同的网络策略。
- **资源签名与商店导出**：当前去重脚本会在修改资源后重签嵌套 bundle。无签名 Archive 已通过资源验证，但描述文件、签名身份和 App Store 导出的兼容性还须实际验证。

## 本次归档结果

- Xcode `26.5`（17F42），通过独立 `build/AppStoreAudit` 构建目录执行 Release、`arm64 x86_64`、`CODE_SIGNING_ALLOWED=NO` 的 Archive。
- 日志结果：`ARCHIVE SUCCEEDED`。产物：`build/AppStoreAudit/OrangeLen.xcarchive`，单一 `Products/Applications/OrangeLen.app`，七个 Quick Look 扩展，主应用可执行文件为双架构。
- `scripts/deduplicate-resources.py --verify-only` 通过；资源共享 framework 已存在，重复 SwiftPM 资源 bundle 已移除。
- Archive 没有签名团队、描述文件、App Group Info.plist 配置、隐私清单及独立 LICENSE 文件；包含 Hydra 修复脚本。XPC 共15个嵌套实例，对应两个服务类型的多份嵌入，不是15种后台功能。
- 本次未改产品代码、系统预览设置、安装应用、创建证书、上传构建、提交或推送。已有 `.gitignore`、branding 和图标脚本工作树改动保持原样。

日志：`/tmp/orangelen-app-store-audit-archive.log`。源代码重点：`App/AppDelegate.swift`、`App/SettingsView.swift`、`App/DiagnosticsController.swift`、`project.yml`、`OrangeLen.xcodeproj/project.pbxproj`、`scripts/package-notarized.sh`、`scripts/deduplicate-resources.py`、`Packages/OrangeLen/Sources/OrangeLenCore/Settings.swift`、`ImageDirectoryGrant.swift`、`Packages/OrangeLen/Sources/OrangeLenUI/HTMLPreview.swift`。

## 推荐实施顺序

1. 建立商店构建配置，将许可证和共享权限纳入 Archive；锁定 Bundle ID、版本和 build。
2. 发布隐私政策，在应用内增加入口；完善首次使用及 HTML 联网说明；对商店版诊断命令入口作产品决策。
3. 配置商店证书与描述文件，导出并运行上传校验；必要时补充隐私清单。
4. 用 TestFlight/商店构建验证干净安装、Finder 分派、共享权限、最低系统及 Intel。
5. 基于验证结果准备截图、支持范围和审核备注，再提交稳定版本。仍在测试阶段的版本使用 TestFlight，不能只移除 preview 文案就视作稳定版本。
