# App 内更新

V1.1.0 已接入 Sparkle 2.9.6，仅主 App 链接更新器，Quick Look 扩展不检查更新。
V1.0.2 及更早的公开版本不包含此功能，需要手动安装一次带更新器的新版本。

## 用户操作

启动 OrangeLen，在应用菜单点击「检查更新…」。Sparkle 显示版本和说明，用户确认后
下载、验证并替换整个 App，再重新启动。安装期间应关闭正在查看的 Quick Look 预览，
更新完成后重新按空格打开。当前版本不启用自动检查、后台自动安装或系统信息上报。
网络失败或下载校验失败由 Sparkle 显示错误，不能把失败显示为“已是最新版”。

启动新版有助于系统发现内嵌扩展，但不承诺已经运行的 Finder 扩展立即刷新；
真实升级验收必须检查扩展进程来自新版，并重新预览文件。

## GitHub 托管

- 固定清单：`https://github.com/orange90/OrangeLen/releases/latest/download/appcast.xml`
- 包地址：`https://github.com/orange90/OrangeLen/releases/download/V<VERSION>/OrangeLen-<VERSION>-universal.dmg`
- 每个稳定版 Release 都必须上传 `appcast.xml` 和对应 DMG，再将该 Release 设为 latest。
  不要把不含清单的 Release 设为 latest。预发布版不参与此稳定更新渠道。
- 清单含构建号、显示版本、最低 macOS、内嵌更新说明、下载地址、长度和 Ed25519 签名。
  清单本身也签名，App 强制验证清单和安装包，下载包在解压前校验。
  App 不抓取 GitHub 页面，也不使用需要访问令牌的 GitHub API。

## 构建与签名

`project.yml` 固定 Sparkle 版本，XcodeGen 生成工程与 Info.plist。仅 App 启用安装器 XPC
及 Sparkle 要求的两个 Mach lookup 名称；原网络权限用于下载，不启用 Downloader 服务。
`scripts/sign-sparkle.sh` 按官方顺序签署两个 XPC、Autoupdate、Updater.app 和 framework。
开发安装与公证打包都调用该脚本，不给 Sparkle 服务套用 OrangeLen broker 的沙盒权限。

使用 Xcode 的 Apple Development 签名或现有开发安装脚本运行调试版；未签名构建仅用于
编译验证，不能代替 Hardened Runtime 下的签名验收。

更新私钥由 Sparkle `generate_keys --account local.OrangeLen` 保存到登录钥匙串，公钥写入
`project.yml` 的 `SUPublicEDKey`。不得把私钥提交到仓库或日志。后续发布使用同一钥匙串项，
不能每次生成不同的密钥。换机器时通过受控方式迁移钥匙串密钥。

## 发布

1. 增加 `MARKETING_VERSION` 和递增的 `CURRENT_PROJECT_VERSION`，准备 `docs/releases/V<VERSION>.md`。
2. `xcodegen generate`，构建、测试，并按现有流程签名、公证及 staple。
3. `package-notarized.sh notarize` 完成后自动生成 `build/artifacts/appcast.xml`。
   如需重试清单步骤，运行 `bash scripts/generate-update-feed.sh <VERSION>`。
   默认 Sparkle 工具目录为 `build/SourcePackages/artifacts/sparkle/Sparkle/bin`，
   找不到时尝试 `build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin`；
   可用 `ORANGELEN_SPARKLE_BIN` 指向同版本 SwiftPM 工具目录。
4. 脚本比对钥匙串公钥与包内公钥，使用官方 `generate_appcast` 对最终 DMG 签名，
   嵌入 Markdown 说明并验证包地址、长度、版本和系统要求。暂不生成增量包。
5. 将 DMG、校验文件及 `appcast.xml` 一起上传到 GitHub Release 草稿，检查完整后发布。
   脚本本身不上传或发布。发布后从固定 URL 下载清单，确认指向该版本的公开 DMG。
6. 在隔离测试安装上实测旧版 → 新版，包括下载、安装、重启、版本和 Finder 扩展。
   仅构建成功或 XML 检查成功不能替代完整升级验收。

V1.1.0 开始随稳定版发布签名更新清单。首次发布后及每次升级发布后，都应核对固定清单 URL 返回的是当前稳定版。

本轮本机独立更新及构建测试结果见[验收记录](evidence/app-updates-2026-10-26/README.md)。

参考：[Sparkle 集成](https://sparkle-project.org/documentation/)、
[沙盒与签名](https://sparkle-project.org/documentation/sandboxing/)、
[发布更新](https://sparkle-project.org/documentation/publishing/)。
