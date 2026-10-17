# 新增 215 个后缀：Finder 空格全量实测

2026-10-16 · 本机已安装的 Apple Development 开发版 · macOS 26.6.2 / Apple Silicon。

## 结果

**215/215 个新增后缀均完成真实 Finder 选择文件并按空格测试。默认设置下，213 项由 OrangeLen 显示正文，2 项由 macOS 内建提供器接管。** 后两项另有系统正文及 OrangeLen 文件夹入口实测，不能把它们算作 OrangeLen 单文件直接通过。

| 默认分派结果 | 数量 | 说明 |
| --- | ---: | --- |
| OrangeLen 单文件正文 | 213 | 包括文本/源码、JSON 结构、Java class、编译 AppleScript、二进制 plist 变体、AutoIt 字节视图 |
| 系统原生文本 | 1 | `.text`，正文正确；OrangeLen 的文件夹入口同样可读 |
| 系统 Shortcuts | 1 | `.wflow`；补充含一个文本动作的样例确认显示动作及正文。通用 plist 样例不含工作流动作，系统显示 No actions，不能据此断言它不支持有效工作流 |

## 发现、定位与处理

- `.as`、`.f` 的首次截图只有尚未加载完成的面板；重新选中并按空格后均看到完整 OrangeLen 正文。其他少数早期抓取也有等待后成功的记录，原始尝试未删除。最终逐项表取同一默认设置下的最新有效结果。
- `.text` 实际 UTI 为 `public.plain-text`；OrangeLen 已声明该类型并启用，但本机实际选择原生文本预览。原生正文正常，不以改后缀、篡改文件类型或覆盖关联来制造通过结果。
- `.wflow` 实际 UTI 为 `com.apple.shortcuts.workflow-file`，OrangeLen 同样有精确声明。临时 `pluginkit -e ignore -i com.apple.shortcuts.QuickLookExtension` 后，实际 Finder 预览进入 OrangeLen 并显示 XML，证明读取器正常。随后已执行 `-e default` 恢复，且用新工作流样例验证系统原生预览恢复。
- Apple 的同一个预览扩展还负责 `com.apple.shortcut`；因此没有默认长期停用它。用户于 2026-10-16 明确选择保留系统默认，通过 OrangeLen 文件夹预览查看 `.wflow` 源码；Shortcuts Quick Look 保持系统默认。诊断命令不属于必须安装的产品修复。
- 在 Finder 对 `source-parity-finder-fallback` 文件夹按空格，再分别选择 `plain.text` / `binary.wflow`，两者均由 OrangeLen 显示正文。该入口不依赖停用系统提供器。
- 没有发现需要修改产品解析器的持续可复现故障，本轮没有改产品代码、重新签名或更新公开发行包。改动为测试夹具、结果与支持说明，不能把测试流程调整宣传成解析器修复。

## 证据与复现

- [输入清单及 SHA-256](audit-manifest.json)：215 个后缀各一个编号样例，包含真实编译 AppleScript/class 结构、二进制 plist 变体、AutoIt 二进制字节样例。
- [原始尝试](finder-results.json)：包含早期未加载完成、等待、重开及临时禁用提供器的诊断记录，不能直接按最后一个诊断结果统计默认通过率。
- [默认分派最终结果](baseline-final-results.json)、[统计摘要](summary.json)。已核对 215 个文件名集合与清单一致、字节哈希一致，没有以重命名后缀替代验收。
- [系统提供器处理的类型](system-provider-types.json)、[诊断前状态](shortcuts-provider-before.txt)、[恢复状态](shortcuts-provider-restored.txt)。
- [`.text` 文件夹正文](fallback-text-ax.txt)、[`.wflow` 文件夹 XML](fallback-wflow-ax.txt)、[有效工作流的原生正文](fallback-native-workflow-valid-ax.txt)。这些文件有同名 PNG 现场截图。
- `python3 scripts/create-source-parity-finder-fixtures.py` 只准备样例，不操作 Finder、不声称完成 UI 测试。实际操作均由 CUA 执行。测试途中出现的截图服务/原生连接错误在恢复后补测；窗口焦点/文件名编辑状态变化不计为产品失败。

## 能说明和不能说明的范围

每个后缀使用合成代表样例，验证的是本机 Finder 分派及可见内容，不是所有真实文件、版本、编码和语法的完整兼容性。`.class` 是声明/有限原始字节码，`.a3x` 编译内容是有限字节视图，AppleScript 不执行且 run-only 无源码可恢复。既有 TS/MTS/DOT 等不在本次 215 个新增后缀集合内，历史限制未因此解除。没有把旧的 106 项与本轮跨版本结果相加为新的总通过率。

## 逐项结果

| 序号 | 后缀 | 默认单文件结果 | 实际样例 | 正文证据 |
| ---: | --- | --- | --- | --- |
| 1 | `.a3x` | OrangeLen 正文 | `001-a3x.a3x` | [AX](001-a3x-initial-ax.txt) / [截图](001-a3x-initial.png) |
| 2 | `.acf` | OrangeLen 正文 | `002-acf.acf` | [AX](002-acf-initial-ax.txt) / [截图](002-acf-initial.png) |
| 3 | `.ada` | OrangeLen 正文 | `003-ada.ada` | [AX](003-ada-initial-ax.txt) / [截图](003-ada-initial.png) |
| 4 | `.ado` | OrangeLen 正文 | `004-ado.ado` | [AX](004-ado-initial-ax.txt) / [截图](004-ado-initial.png) |
| 5 | `.applescript` | OrangeLen 正文 | `005-applescript.applescript` | [AX](005-applescript-initial-ax.txt) / [截图](005-applescript-initial.png) |
| 6 | `.as` | OrangeLen 正文 | `006-as.as` | [AX](006-as-reopen-ax.txt) / [截图](006-as-reopen.png) |
| 7 | `.ascr` | OrangeLen 正文 | `007-ascr.ascr` | [AX](007-ascr-initial-ax.txt) / [截图](007-ascr-initial.png) |
| 8 | `.asd` | OrangeLen 正文 | `008-asd.asd` | [AX](008-asd-initial-ax.txt) / [截图](008-asd-initial.png) |
| 9 | `.asm` | OrangeLen 正文 | `009-asm.asm` | [AX](009-asm-initial-ax.txt) / [截图](009-asm-initial.png) |
| 10 | `.asp` | OrangeLen 正文 | `010-asp.asp` | [AX](010-asp-initial-ax.txt) / [截图](010-asp-initial.png) |
| 11 | `.aspx` | OrangeLen 正文 | `011-aspx.aspx` | [AX](011-aspx-initial-ax.txt) / [截图](011-aspx-initial.png) |
| 12 | `.atl` | OrangeLen 正文 | `012-atl.atl` | [AX](012-atl-initial-ax.txt) / [截图](012-atl-initial.png) |
| 13 | `.au3` | OrangeLen 正文 | `013-au3.au3` | [AX](013-au3-initial-ax.txt) / [截图](013-au3-initial.png) |
| 14 | `.avt` | OrangeLen 正文 | `014-avt.avt` | [AX](014-avt-initial-ax.txt) / [截图](014-avt-initial.png) |
| 15 | `.awk` | OrangeLen 正文 | `015-awk.awk` | [AX](015-awk-initial-ax.txt) / [截图](015-awk-initial.png) |
| 16 | `.bas` | OrangeLen 正文 | `016-bas.bas` | [AX](016-bas-initial-ax.txt) / [截图](016-bas-initial.png) |
| 17 | `.bashrc` | OrangeLen 正文 | `017-bashrc.bashrc` | [AX](017-bashrc-initial-ax.txt) / [截图](017-bashrc-initial.png) |
| 18 | `.basic` | OrangeLen 正文 | `018-basic.basic` | [AX](018-basic-initial-ax.txt) / [截图](018-basic-initial.png) |
| 19 | `.bat` | OrangeLen 正文 | `019-bat.bat` | [AX](019-bat-initial-ax.txt) / [截图](019-bat-initial.png) |
| 20 | `.bb` | OrangeLen 正文 | `020-bb.bb` | [AX](020-bb-initial-ax.txt) / [截图](020-bb-initial.png) |
| 21 | `.bezel` | OrangeLen 正文 | `021-bezel.bezel` | [AX](021-bezel-initial-ax.txt) / [截图](021-bezel-initial.png) |
| 22 | `.bib` | OrangeLen 正文 | `022-bib.bib` | [AX](022-bib-initial-ax.txt) / [截图](022-bib-initial.png) |
| 23 | `.c++` | OrangeLen 正文 | `023-c++.c++` | [AX](023-c++-initial-ax.txt) / [截图](023-c++-initial.png) |
| 24 | `.cfc` | OrangeLen 正文 | `024-cfc.cfc` | [AX](024-cfc-initial-ax.txt) / [截图](024-cfc-initial.png) |
| 25 | `.cfg` | OrangeLen 正文 | `025-cfg.cfg` | [AX](025-cfg-initial-ax.txt) / [截图](025-cfg-initial.png) |
| 26 | `.cfm` | OrangeLen 正文 | `026-cfm.cfm` | [AX](026-cfm-initial-ax.txt) / [截图](026-cfm-initial.png) |
| 27 | `.cfml` | OrangeLen 正文 | `027-cfml.cfml` | [AX](027-cfml-initial-ax.txt) / [截图](027-cfml-initial.png) |
| 28 | `.class` | OrangeLen 正文 | `028-class.class` | [AX](028-class-initial-ax.txt) / [截图](028-class-initial.png) |
| 29 | `.cli` | OrangeLen 正文 | `029-cli.cli` | [AX](029-cli-initial-ax.txt) / [截图](029-cli-initial.png) |
| 30 | `.clj` | OrangeLen 正文 | `030-clj.clj` | [AX](030-clj-initial-ax.txt) / [截图](030-clj-initial.png) |
| 31 | `.cljc` | OrangeLen 正文 | `031-cljc.cljc` | [AX](031-cljc-initial-ax.txt) / [截图](031-cljc-initial.png) |
| 32 | `.cljs` | OrangeLen 正文 | `032-cljs.cljs` | [AX](032-cljs-initial-ax.txt) / [截图](032-cljs-initial.png) |
| 33 | `.cls` | OrangeLen 正文 | `033-cls.cls` | [AX](033-cls-initial-ax.txt) / [截图](033-cls-initial.png) |
| 34 | `.cmd` | OrangeLen 正文 | `034-cmd.cmd` | [AX](034-cmd-initial-ax.txt) / [截图](034-cmd-initial.png) |
| 35 | `.code-workspace` | OrangeLen 正文 | `035-code-workspace.code-workspace` | [AX](035-code-workspace-initial-ax.txt) / [截图](035-code-workspace-initial.png) |
| 36 | `.coffee` | OrangeLen 正文 | `036-coffee.coffee` | [AX](036-coffee-initial-ax.txt) / [截图](036-coffee-initial.png) |
| 37 | `.command` | OrangeLen 正文 | `037-command.command` | [AX](037-command-initial-ax.txt) / [截图](037-command-initial.png) |
| 38 | `.con` | OrangeLen 正文 | `038-con.con` | [AX](038-con-initial-ax.txt) / [截图](038-con-initial.png) |
| 39 | `.cp` | OrangeLen 正文 | `039-cp.cp` | [AX](039-cp-initial-ax.txt) / [截图](039-cp-initial.png) |
| 40 | `.cr` | OrangeLen 正文 | `040-cr.cr` | [AX](040-cr-initial-ax.txt) / [截图](040-cr-initial.png) |
| 41 | `.csh` | OrangeLen 正文 | `041-csh.csh` | [AX](041-csh-initial-ax.txt) / [截图](041-csh-initial.png) |
| 42 | `.cson` | OrangeLen 正文 | `042-cson.cson` | [AX](042-cson-initial-ax.txt) / [截图](042-cson-initial.png) |
| 43 | `.csproj` | OrangeLen 正文 | `043-csproj.csproj` | [AX](043-csproj-initial-ax.txt) / [截图](043-csproj-initial.png) |
| 44 | `.ctx` | OrangeLen 正文 | `044-ctx.ctx` | [AX](044-ctx-initial-ax.txt) / [截图](044-ctx-initial.png) |
| 45 | `.d` | OrangeLen 正文 | `045-d.d` | [AX](045-d-initial-ax.txt) / [截图](045-d-initial.png) |
| 46 | `.designspace` | OrangeLen 正文 | `046-designspace.designspace` | [AX](046-designspace-initial-ax.txt) / [截图](046-designspace-initial.png) |
| 47 | `.do` | OrangeLen 正文 | `047-do.do` | [AX](047-do-initial-ax.txt) / [截图](047-do-initial.png) |
| 48 | `.dockerfile` | OrangeLen 正文 | `048-dockerfile.dockerfile` | [AX](048-dockerfile-initial-ax.txt) / [截图](048-dockerfile-initial.png) |
| 49 | `.dtd` | OrangeLen 正文 | `049-dtd.dtd` | [AX](049-dtd-initial-ax.txt) / [截图](049-dtd-initial.png) |
| 50 | `.dylan` | OrangeLen 正文 | `050-dylan.dylan` | [AX](050-dylan-initial-ax.txt) / [截图](050-dylan-initial.png) |
| 51 | `.e` | OrangeLen 正文 | `051-e.e` | [AX](051-e-initial-ax.txt) / [截图](051-e-initial.png) |
| 52 | `.ecf` | OrangeLen 正文 | `052-ecf.ecf` | [AX](052-ecf-initial-ax.txt) / [截图](052-ecf-initial.png) |
| 53 | `.ecore` | OrangeLen 正文 | `053-ecore.ecore` | [AX](053-ecore-initial-ax.txt) / [截图](053-ecore-initial.png) |
| 54 | `.edn` | OrangeLen 正文 | `054-edn.edn` | [AX](054-edn-initial-ax.txt) / [截图](054-edn-initial.png) |
| 55 | `.el` | OrangeLen 正文 | `055-el.el` | [AX](055-el-initial-ax.txt) / [截图](055-el-initial.png) |
| 56 | `.entitlements` | OrangeLen 正文 | `056-entitlements.entitlements` | [AX](056-entitlements-initial-ax.txt) / [截图](056-entitlements-initial.png) |
| 57 | `.env` | OrangeLen 正文 | `057-env.env` | [AX](057-env-initial-ax.txt) / [截图](057-env-initial.png) |
| 58 | `.erb` | OrangeLen 正文 | `058-erb.erb` | [AX](058-erb-initial-ax.txt) / [截图](058-erb-initial.png) |
| 59 | `.erl` | OrangeLen 正文 | `059-erl.erl` | [AX](059-erl-initial-ax.txt) / [截图](059-erl-initial.png) |
| 60 | `.ex` | OrangeLen 正文 | `060-ex.ex` | [AX](060-ex-initial-ax.txt) / [截图](060-ex-initial.png) |
| 61 | `.exs` | OrangeLen 正文 | `061-exs.exs` | [AX](061-exs-settled-ax.txt) / [截图](061-exs-settled.png) |
| 62 | `.f` | OrangeLen 正文 | `062-f.f` | [AX](062-f-reopen-ax.txt) / [截图](062-f-reopen.png) |
| 63 | `.f90` | OrangeLen 正文 | `063-f90.f90` | [AX](063-f90-initial-ax.txt) / [截图](063-f90-initial.png) |
| 64 | `.f95` | OrangeLen 正文 | `064-f95.f95` | [AX](064-f95-initial-ax.txt) / [截图](064-f95-initial.png) |
| 65 | `.fea` | OrangeLen 正文 | `065-fea.fea` | [AX](065-fea-initial-ax.txt) / [截图](065-fea-initial.png) |
| 66 | `.fish` | OrangeLen 正文 | `066-fish.fish` | [AX](066-fish-initial-ax.txt) / [截图](066-fish-initial.png) |
| 67 | `.flow` | OrangeLen 正文 | `067-flow.flow` | [AX](067-flow-initial-ax.txt) / [截图](067-flow-initial.png) |
| 68 | `.fnc` | OrangeLen 正文 | `068-fnc.fnc` | [AX](068-fnc-initial-ax.txt) / [截图](068-fnc-initial.png) |
| 69 | `.for` | OrangeLen 正文 | `069-for.for` | [AX](069-for-initial-ax.txt) / [截图](069-for-initial.png) |
| 70 | `.fs` | OrangeLen 正文 | `070-fs.fs` | [AX](070-fs-initial-ax.txt) / [截图](070-fs-initial.png) |
| 71 | `.fsx` | OrangeLen 正文 | `071-fsx.fsx` | [AX](071-fsx-initial-ax.txt) / [截图](071-fsx-initial.png) |
| 72 | `.fxml` | OrangeLen 正文 | `072-fxml.fxml` | [AX](072-fxml-initial-ax.txt) / [截图](072-fxml-initial.png) |
| 73 | `.gd` | OrangeLen 正文 | `073-gd.gd` | [AX](073-gd-initial-ax.txt) / [截图](073-gd-initial.png) |
| 74 | `.gemfile` | OrangeLen 正文 | `074-gemfile.gemfile` | [AX](074-gemfile-initial-ax.txt) / [截图](074-gemfile-initial.png) |
| 75 | `.gleam` | OrangeLen 正文 | `075-gleam.gleam` | [AX](075-gleam-initial-ax.txt) / [截图](075-gleam-initial.png) |
| 76 | `.gpx` | OrangeLen 正文 | `076-gpx.gpx` | [AX](076-gpx-initial-ax.txt) / [截图](076-gpx-initial.png) |
| 77 | `.haml` | OrangeLen 正文 | `077-haml.haml` | [AX](077-haml-initial-ax.txt) / [截图](077-haml-initial.png) |
| 78 | `.heex` | OrangeLen 正文 | `078-heex.heex` | [AX](078-heex-initial-ax.txt) / [截图](078-heex-initial.png) |
| 79 | `.hri` | OrangeLen 正文 | `079-hri.hri` | [AX](079-hri-initial-ax.txt) / [截图](079-hri-initial.png) |
| 80 | `.hrl` | OrangeLen 正文 | `080-hrl.hrl` | [AX](080-hrl-initial-ax.txt) / [截图](080-hrl-initial.png) |
| 81 | `.hs` | OrangeLen 正文 | `081-hs.hs` | [AX](081-hs-initial-ax.txt) / [截图](081-hs-initial.png) |
| 82 | `.ily` | OrangeLen 正文 | `082-ily.ily` | [AX](082-ily-initial-ax.txt) / [截图](082-ily-initial.png) |
| 83 | `.iml` | OrangeLen 正文 | `083-iml.iml` | [AX](083-iml-initial-ax.txt) / [截图](083-iml-initial.png) |
| 84 | `.inf` | OrangeLen 正文 | `084-inf.inf` | [AX](084-inf-initial-ax.txt) / [截图](084-inf-initial.png) |
| 85 | `.ino` | OrangeLen 正文 | `085-ino.ino` | [AX](085-ino-initial-ax.txt) / [截图](085-ino-initial.png) |
| 86 | `.iss` | OrangeLen 正文 | `086-iss.iss` | [AX](086-iss-initial-ax.txt) / [截图](086-iss-initial.png) |
| 87 | `.jav` | OrangeLen 正文 | `087-jav.jav` | [AX](087-jav-initial-ax.txt) / [截图](087-jav-initial.png) |
| 88 | `.javascript` | OrangeLen 正文 | `088-javascript.javascript` | [AX](088-javascript-initial-ax.txt) / [截图](088-javascript-initial.png) |
| 89 | `.jl` | OrangeLen 正文 | `089-jl.jl` | [AX](089-jl-initial-ax.txt) / [截图](089-jl-initial.png) |
| 90 | `.jnlp` | OrangeLen 正文 | `090-jnlp.jnlp` | [AX](090-jnlp-initial-ax.txt) / [截图](090-jnlp-initial.png) |
| 91 | `.jscript` | OrangeLen 正文 | `091-jscript.jscript` | [AX](091-jscript-initial-ax.txt) / [截图](091-jscript-initial.png) |
| 92 | `.jsm` | OrangeLen 正文 | `092-jsm.jsm` | [AX](092-jsm-initial-ax.txt) / [截图](092-jsm-initial.png) |
| 93 | `.jsp` | OrangeLen 正文 | `093-jsp.jsp` | [AX](093-jsp-initial-ax.txt) / [截图](093-jsp-initial.png) |
| 94 | `.kml` | OrangeLen 正文 | `094-kml.kml` | [AX](094-kml-initial-ax.txt) / [截图](094-kml-initial.png) |
| 95 | `.kmt` | OrangeLen 正文 | `095-kmt.kmt` | [AX](095-kmt-initial-ax.txt) / [截图](095-kmt-initial.png) |
| 96 | `.ksh` | OrangeLen 正文 | `096-ksh.ksh` | [AX](096-ksh-initial-ax.txt) / [截图](096-ksh-initial.png) |
| 97 | `.latex` | OrangeLen 正文 | `097-latex.latex` | [AX](097-latex-initial-ax.txt) / [截图](097-latex-initial.png) |
| 98 | `.lay` | OrangeLen 正文 | `098-lay.lay` | [AX](098-lay-initial-ax.txt) / [截图](098-lay-initial.png) |
| 99 | `.ld` | OrangeLen 正文 | `099-ld.ld` | [AX](099-ld-initial-ax.txt) / [截图](099-ld-initial.png) |
| 100 | `.lhs` | OrangeLen 正文 | `100-lhs.lhs` | [AX](100-lhs-initial-ax.txt) / [截图](100-lhs-initial.png) |
| 101 | `.lisp` | OrangeLen 正文 | `101-lisp.lisp` | [AX](101-lisp-initial-ax.txt) / [截图](101-lisp-initial.png) |
| 102 | `.loctable` | OrangeLen 正文 | `102-loctable.loctable` | [AX](102-loctable-initial-ax.txt) / [截图](102-loctable-initial.png) |
| 103 | `.lsp` | OrangeLen 正文 | `103-lsp.lsp` | [AX](103-lsp-initial-ax.txt) / [截图](103-lsp-initial.png) |
| 104 | `.ltx` | OrangeLen 正文 | `104-ltx.ltx` | [AX](104-ltx-initial-ax.txt) / [截图](104-ltx-initial.png) |
| 105 | `.ly` | OrangeLen 正文 | `105-ly.ly` | [AX](105-ly-initial-ax.txt) / [截图](105-ly-initial.png) |
| 106 | `.m` | OrangeLen 正文 | `106-m.m` | [AX](106-m-initial-ax.txt) / [截图](106-m-initial.png) |
| 107 | `.mak` | OrangeLen 正文 | `107-mak.mak` | [AX](107-mak-initial-ax.txt) / [截图](107-mak-initial.png) |
| 108 | `.map` | OrangeLen 正文 | `108-map.map` | [AX](108-map-initial-ax.txt) / [截图](108-map-initial.png) |
| 109 | `.mf` | OrangeLen 正文 | `109-mf.mf` | [AX](109-mf-initial-ax.txt) / [截图](109-mf-initial.png) |
| 110 | `.mill` | OrangeLen 正文 | `110-mill.mill` | [AX](110-mill-initial-ax.txt) / [截图](110-mill-initial.png) |
| 111 | `.ml` | OrangeLen 正文 | `111-ml.ml` | [AX](111-ml-initial-ax.txt) / [截图](111-ml-initial.png) |
| 112 | `.mll` | OrangeLen 正文 | `112-mll.mll` | [AX](112-mll-initial-ax.txt) / [截图](112-mll-initial.png) |
| 113 | `.mly` | OrangeLen 正文 | `113-mly.mly` | [AX](113-mly-initial-ax.txt) / [截图](113-mly-initial.png) |
| 114 | `.mobileconfig` | OrangeLen 正文 | `114-mobileconfig.mobileconfig` | [AX](114-mobileconfig-initial-ax.txt) / [截图](114-mobileconfig-initial.png) |
| 115 | `.mpd` | OrangeLen 正文 | `115-mpd.mpd` | [AX](115-mpd-initial-ax.txt) / [截图](115-mpd-initial.png) |
| 116 | `.mq4` | OrangeLen 正文 | `116-mq4.mq4` | [AX](116-mq4-initial-ax.txt) / [截图](116-mq4-initial.png) |
| 117 | `.mq5` | OrangeLen 正文 | `117-mq5.mq5` | [AX](117-mq5-initial-ax.txt) / [截图](117-mq5-initial.png) |
| 118 | `.ms` | OrangeLen 正文 | `118-ms.ms` | [AX](118-ms-initial-ax.txt) / [截图](118-ms-initial.png) |
| 119 | `.mvw` | OrangeLen 正文 | `119-mvw.mvw` | [AX](119-mvw-initial-ax.txt) / [截图](119-mvw-initial.png) |
| 120 | `.mxml` | OrangeLen 正文 | `120-mxml.mxml` | [AX](120-mxml-initial-ax.txt) / [截图](120-mxml-initial.png) |
| 121 | `.ncx` | OrangeLen 正文 | `121-ncx.ncx` | [AX](121-ncx-initial-ax.txt) / [截图](121-ncx-initial.png) |
| 122 | `.nf` | OrangeLen 正文 | `122-nf.nf` | [AX](122-nf-initial-ax.txt) / [截图](122-nf-initial.png) |
| 123 | `.nim` | OrangeLen 正文 | `123-nim.nim` | [AX](123-nim-initial-ax.txt) / [截图](123-nim-initial.png) |
| 124 | `.nix` | OrangeLen 正文 | `124-nix.nix` | [AX](124-nix-initial-ax.txt) / [截图](124-nix-initial.png) |
| 125 | `.opf` | OrangeLen 正文 | `125-opf.opf` | [AX](125-opf-initial-ax.txt) / [截图](125-opf-initial.png) |
| 126 | `.otio` | OrangeLen 正文 | `126-otio.otio` | [AX](126-otio-initial-ax.txt) / [截图](126-otio-initial.png) |
| 127 | `.pas` | OrangeLen 正文 | `127-pas.pas` | [AX](127-pas-initial-ax.txt) / [截图](127-pas-initial.png) |
| 128 | `.pck` | OrangeLen 正文 | `128-pck.pck` | [AX](128-pck-initial-ax.txt) / [截图](128-pck-initial.png) |
| 129 | `.pddl` | OrangeLen 正文 | `129-pddl.pddl` | [AX](129-pddl-initial-ax.txt) / [截图](129-pddl-initial.png) |
| 130 | `.pde` | OrangeLen 正文 | `130-pde.pde` | [AX](130-pde-initial-ax.txt) / [截图](130-pde-initial.png) |
| 131 | `.ph3` | OrangeLen 正文 | `131-ph3.ph3` | [AX](131-ph3-initial-ax.txt) / [截图](131-ph3-initial.png) |
| 132 | `.ph4` | OrangeLen 正文 | `132-ph4.ph4` | [AX](132-ph4-initial-ax.txt) / [截图](132-ph4-initial.png) |
| 133 | `.php3` | OrangeLen 正文 | `133-php3.php3` | [AX](133-php3-initial-ax.txt) / [截图](133-php3-initial.png) |
| 134 | `.php4` | OrangeLen 正文 | `134-php4.php4` | [AX](134-php4-initial-ax.txt) / [截图](134-php4-initial.png) |
| 135 | `.phtml` | OrangeLen 正文 | `135-phtml.phtml` | [AX](135-phtml-initial-ax.txt) / [截图](135-phtml-initial.png) |
| 136 | `.pkb` | OrangeLen 正文 | `136-pkb.pkb` | [AX](136-pkb-initial-ax.txt) / [截图](136-pkb-initial.png) |
| 137 | `.pks` | OrangeLen 正文 | `137-pks.pks` | [AX](137-pks-initial-ax.txt) / [截图](137-pks-initial.png) |
| 138 | `.pl` | OrangeLen 正文 | `138-pl.pl` | [AX](138-pl-initial-ax.txt) / [截图](138-pl-initial.png) |
| 139 | `.pm` | OrangeLen 正文 | `139-pm.pm` | [AX](139-pm-initial-ax.txt) / [截图](139-pm-initial.png) |
| 140 | `.podspec` | OrangeLen 正文 | `140-podspec.podspec` | [AX](140-podspec-initial-ax.txt) / [截图](140-podspec-initial.png) |
| 141 | `.pom` | OrangeLen 正文 | `141-pom.pom` | [AX](141-pom-initial-ax.txt) / [截图](141-pom-initial.png) |
| 142 | `.prc` | OrangeLen 正文 | `142-prc.prc` | [AX](142-prc-initial-ax.txt) / [截图](142-prc-initial.png) |
| 143 | `.pro` | OrangeLen 正文 | `143-pro.pro` | [AX](143-pro-initial-ax.txt) / [截图](143-pro-initial.png) |
| 144 | `.psd1` | OrangeLen 正文 | `144-psd1.psd1` | [AX](144-psd1-initial-ax.txt) / [截图](144-psd1-initial.png) |
| 145 | `.psjs` | OrangeLen 正文 | `145-psjs.psjs` | [AX](145-psjs-initial-ax.txt) / [截图](145-psjs-initial.png) |
| 146 | `.psm1` | OrangeLen 正文 | `146-psm1.psm1` | [AX](146-psm1-initial-ax.txt) / [截图](146-psm1-initial.png) |
| 147 | `.pub` | OrangeLen 正文 | `147-pub.pub` | [AX](147-pub-initial-ax.txt) / [截图](147-pub-initial.png) |
| 148 | `.py3` | OrangeLen 正文 | `148-py3.py3` | [AX](148-py3-initial-ax.txt) / [截图](148-py3-initial.png) |
| 149 | `.raml` | OrangeLen 正文 | `149-raml.raml` | [AX](149-raml-initial-ax.txt) / [截图](149-raml-initial.png) |
| 150 | `.rbw` | OrangeLen 正文 | `150-rbw.rbw` | [AX](150-rbw-settled-ax.txt) / [截图](150-rbw-settled.png) |
| 151 | `.rdf` | OrangeLen 正文 | `151-rdf.rdf` | [AX](151-rdf-initial-ax.txt) / [截图](151-rdf-initial.png) |
| 152 | `.readme` | OrangeLen 正文 | `152-readme.readme` | [AX](152-readme-initial-ax.txt) / [截图](152-readme-initial.png) |
| 153 | `.rex` | OrangeLen 正文 | `153-rex.rex` | [AX](153-rex-settled-ax.txt) / [截图](153-rex-settled.png) |
| 154 | `.rexx` | OrangeLen 正文 | `154-rexx.rexx` | [AX](154-rexx-initial-ax.txt) / [截图](154-rexx-initial.png) |
| 155 | `.rhtml` | OrangeLen 正文 | `155-rhtml.rhtml` | [AX](155-rhtml-initial-ax.txt) / [截图](155-rhtml-initial.png) |
| 156 | `.rjs` | OrangeLen 正文 | `156-rjs.rjs` | [AX](156-rjs-initial-ax.txt) / [截图](156-rjs-initial.png) |
| 157 | `.rkt` | OrangeLen 正文 | `157-rkt.rkt` | [AX](157-rkt-initial-ax.txt) / [截图](157-rkt-initial.png) |
| 158 | `.robot` | OrangeLen 正文 | `158-robot.robot` | [AX](158-robot-initial-ax.txt) / [截图](158-robot-initial.png) |
| 159 | `.s79` | OrangeLen 正文 | `159-s79.s79` | [AX](159-s79-initial-ax.txt) / [截图](159-s79-initial.png) |
| 160 | `.sage` | OrangeLen 正文 | `160-sage.sage` | [AX](160-sage-initial-ax.txt) / [截图](160-sage-initial.png) |
| 161 | `.sas` | OrangeLen 正文 | `161-sas.sas` | [AX](161-sas-settled-ax.txt) / [截图](161-sas-settled.png) |
| 162 | `.sbt` | OrangeLen 正文 | `162-sbt.sbt` | [AX](162-sbt-initial-ax.txt) / [截图](162-sbt-initial.png) |
| 163 | `.sc` | OrangeLen 正文 | `163-sc.sc` | [AX](163-sc-initial-ax.txt) / [截图](163-sc-initial.png) |
| 164 | `.scad` | OrangeLen 正文 | `164-scad.scad` | [AX](164-scad-initial-ax.txt) / [截图](164-scad-initial.png) |
| 165 | `.sch` | OrangeLen 正文 | `165-sch.sch` | [AX](165-sch-initial-ax.txt) / [截图](165-sch-initial.png) |
| 166 | `.scl` | OrangeLen 正文 | `166-scl.scl` | [AX](166-scl-initial-ax.txt) / [截图](166-scl-initial.png) |
| 167 | `.scm` | OrangeLen 正文 | `167-scm.scm` | [AX](167-scm-initial-ax.txt) / [截图](167-scm-initial.png) |
| 168 | `.scpt` | OrangeLen 正文 | `168-scpt.scpt` | [AX](168-scpt-initial-ax.txt) / [截图](168-scpt-initial.png) |
| 169 | `.sequ` | OrangeLen 正文 | `169-sequ.sequ` | [AX](169-sequ-initial-ax.txt) / [截图](169-sequ-initial.png) |
| 170 | `.sld` | OrangeLen 正文 | `170-sld.sld` | [AX](170-sld-initial-ax.txt) / [截图](170-sld-initial.png) |
| 171 | `.sls` | OrangeLen 正文 | `171-sls.sls` | [AX](171-sls-settled-ax.txt) / [截图](171-sls-settled.png) |
| 172 | `.smali` | OrangeLen 正文 | `172-smali.smali` | [AX](172-smali-initial-ax.txt) / [截图](172-smali-initial.png) |
| 173 | `.sol` | OrangeLen 正文 | `173-sol.sol` | [AX](173-sol-initial-ax.txt) / [截图](173-sol-initial.png) |
| 174 | `.sps` | OrangeLen 正文 | `174-sps.sps` | [AX](174-sps-initial-ax.txt) / [截图](174-sps-initial.png) |
| 175 | `.sqs` | OrangeLen 正文 | `175-sqs.sqs` | [AX](175-sqs-settled-ax.txt) / [截图](175-sqs-settled.png) |
| 176 | `.ss` | OrangeLen 正文 | `176-ss.ss` | [AX](176-ss-initial-ax.txt) / [截图](176-ss-initial.png) |
| 177 | `.storybard` | OrangeLen 正文 | `177-storybard.storybard` | [AX](177-storybard-initial-ax.txt) / [截图](177-storybard-initial.png) |
| 178 | `.storyboard` | OrangeLen 正文 | `178-storyboard.storyboard` | [AX](178-storyboard-initial-ax.txt) / [截图](178-storyboard-initial.png) |
| 179 | `.strings` | OrangeLen 正文 | `179-strings.strings` | [AX](179-strings-initial-ax.txt) / [截图](179-strings-initial.png) |
| 180 | `.stringsdict` | OrangeLen 正文 | `180-stringsdict.stringsdict` | [AX](180-stringsdict-settled-ax.txt) / [截图](180-stringsdict-settled.png) |
| 181 | `.sty` | OrangeLen 正文 | `181-sty.sty` | [AX](181-sty-initial-ax.txt) / [截图](181-sty-initial.png) |
| 182 | `.t` | OrangeLen 正文 | `182-t.t` | [AX](182-t-initial-ax.txt) / [截图](182-t-initial.png) |
| 183 | `.tab` | OrangeLen 正文 | `183-tab.tab` | [AX](183-tab-initial-ax.txt) / [截图](183-tab-initial.png) |
| 184 | `.tcl` | OrangeLen 正文 | `184-tcl.tcl` | [AX](184-tcl-initial-ax.txt) / [截图](184-tcl-initial.png) |
| 185 | `.tcsh` | OrangeLen 正文 | `185-tcsh.tcsh` | [AX](185-tcsh-settled-ax.txt) / [截图](185-tcsh-settled.png) |
| 186 | `.texi` | OrangeLen 正文 | `186-texi.texi` | [AX](186-texi-initial-ax.txt) / [截图](186-texi-initial.png) |
| 187 | `.text` | 系统原生正文；文件夹入口可用 | `187-text.text` | [AX](187-text-settled-ax.txt) / [截图](187-text-settled.png) |
| 188 | `.tfstate` | OrangeLen 正文 | `188-tfstate.tfstate` | [AX](188-tfstate-initial-ax.txt) / [截图](188-tfstate-initial.png) |
| 189 | `.tpb` | OrangeLen 正文 | `189-tpb.tpb` | [AX](189-tpb-initial-ax.txt) / [截图](189-tpb-initial.png) |
| 190 | `.tps` | OrangeLen 正文 | `190-tps.tps` | [AX](190-tps-initial-ax.txt) / [截图](190-tps-initial.png) |
| 191 | `.trg` | OrangeLen 正文 | `191-trg.trg` | [AX](191-trg-settled-ax.txt) / [截图](191-trg-settled.png) |
| 192 | `.ttx` | OrangeLen 正文 | `192-ttx.ttx` | [AX](192-ttx-initial-ax.txt) / [截图](192-ttx-initial.png) |
| 193 | `.twig` | OrangeLen 正文 | `193-twig.twig` | [AX](193-twig-settled-ax.txt) / [截图](193-twig-settled.png) |
| 194 | `.unity` | OrangeLen 正文 | `194-unity.unity` | [AX](194-unity-initial-ax.txt) / [截图](194-unity-initial.png) |
| 195 | `.v` | OrangeLen 正文 | `195-v.v` | [AX](195-v-initial-ax.txt) / [截图](195-v-initial.png) |
| 196 | `.vb` | OrangeLen 正文 | `196-vb.vb` | [AX](196-vb-initial-ax.txt) / [截图](196-vb-initial.png) |
| 197 | `.vbs` | OrangeLen 正文 | `197-vbs.vbs` | [AX](197-vbs-initial-ax.txt) / [截图](197-vbs-initial.png) |
| 198 | `.vhd` | OrangeLen 正文 | `198-vhd.vhd` | [AX](198-vhd-initial-ax.txt) / [截图](198-vhd-initial.png) |
| 199 | `.vhdl` | OrangeLen 正文 | `199-vhdl.vhdl` | [AX](199-vhdl-settled-ax.txt) / [截图](199-vhdl-settled.png) |
| 200 | `.vim` | OrangeLen 正文 | `200-vim.vim` | [AX](200-vim-initial-ax.txt) / [截图](200-vim-initial.png) |
| 201 | `.vl` | OrangeLen 正文 | `201-vl.vl` | [AX](201-vl-initial-ax.txt) / [截图](201-vl-initial.png) |
| 202 | `.vw` | OrangeLen 正文 | `202-vw.vw` | [AX](202-vw-initial-ax.txt) / [截图](202-vw-initial.png) |
| 203 | `.wflow` | 系统 Shortcuts；文件夹入口可用 | `203-wflow.wflow` | [AX](203-wflow-settled-ax.txt) / [截图](203-wflow-settled.png) |
| 204 | `.xaml` | OrangeLen 正文 | `204-xaml.xaml` | [AX](204-xaml-settled-ax.txt) / [截图](204-xaml-settled.png) |
| 205 | `.xcscheme` | OrangeLen 正文 | `205-xcscheme.xcscheme` | [AX](205-xcscheme-initial-ax.txt) / [截图](205-xcscheme-initial.png) |
| 206 | `.xib` | OrangeLen 正文 | `206-xib.xib` | [AX](206-xib-settled-ax.txt) / [截图](206-xib-settled.png) |
| 207 | `.xm` | OrangeLen 正文 | `207-xm.xm` | [AX](207-xm-settled-ax.txt) / [截图](207-xm-settled.png) |
| 208 | `.xq` | OrangeLen 正文 | `208-xq.xq` | [AX](208-xq-initial-ax.txt) / [截图](208-xq-initial.png) |
| 209 | `.xquery` | OrangeLen 正文 | `209-xquery.xquery` | [AX](209-xquery-initial-ax.txt) / [截图](209-xquery-initial.png) |
| 210 | `.xsd` | OrangeLen 正文 | `210-xsd.xsd` | [AX](210-xsd-initial-ax.txt) / [截图](210-xsd-initial.png) |
| 211 | `.xu` | OrangeLen 正文 | `211-xu.xu` | [AX](211-xu-initial-ax.txt) / [截图](211-xu-initial.png) |
| 212 | `.xul` | OrangeLen 正文 | `212-xul.xul` | [AX](212-xul-initial-ax.txt) / [截图](212-xul-initial.png) |
| 213 | `.zig` | OrangeLen 正文 | `213-zig.zig` | [AX](213-zig-initial-ax.txt) / [截图](213-zig-initial.png) |
| 214 | `.zon` | OrangeLen 正文 | `214-zon.zon` | [AX](214-zon-initial-ax.txt) / [截图](214-zon-initial.png) |
| 215 | `.zshrc` | OrangeLen 正文 | `215-zshrc.zshrc` | [AX](215-zshrc-initial-ax.txt) / [截图](215-zshrc-initial.png) |
