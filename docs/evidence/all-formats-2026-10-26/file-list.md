# 371 个后缀：Finder 实际提供器列表

2026-10-26，本机当前开发版（包含本轮 SQL 修复），macOS 26.6.2 / Apple Silicon。

**已对 371/371 个后缀进行真实 Finder 选择与 Quick Look 预览切换，并对 30 项进行独立关闭重开补测。350 项由 OrangeLen 接管，16 项由系统显示内容，5 项仅显示系统文件信息。**

350 项均同时具有 OrangeLen 专属界面、对应后缀的扩展接收日志和成功回调。21 个非 OrangeLen 项均有本轮 Finder 实际 displayBundleID 日志与界面证据。可见正文中的“OrangeLen”测试文字不作为提供器判断依据。

**本机原有设置：Hydra 3D 扩展已停用，本轮未改变它；OBJ/STL 结果适用于这一配置。公开 V1.0 安装包没有重新发布或逐项复测，不能把本机结果外推到所有用户。**

归属检查不等于完整格式兼容：源码可能只读原文；模型只读元数据；归档本轮验证目录入口，未对每个成员逐项读取；图形未进行全量像素或视觉正确性验收。每后缀一个小型合成样例，不覆盖任意文件、方言、损坏数据或大文件边界。

## 系统内容预览：16 项

`.zsh`, `.bash`, `.html`, `.htm`, `.xhtml`, `.r`, `.proto`, `.txt`, `.log`, `.pdf`, `.csv`, `.svg`, `.diff`, `.patch`, `.text`, `.wflow`

## 仅系统文件信息：5 项（不能算预览通过）

|后缀|实际类型|本轮观察|
|---|---|---|
|`.ts`|`public.mpeg-2-transport-stream`|源码被识别为 MPEG 传输流，系统 Movie 提供器只显示文件卡片|
|`.mts`|`public.avchd-mpeg-2-transport-stream`|源码被识别为 MPEG 传输流，系统 Movie 提供器只显示文件卡片|
|`.dot`|`com.microsoft.word.dot`|与 Word 模板后缀冲突，本次系统 PDFKit 路径未显示 DOT 图形|
|`.txz`|`org.tukaani.tar-xz-archive`|系统有具体的压缩 TAR 类型，OrangeLen 现有声明未精确覆盖；系统 Generic 仅显示文件卡片|
|`.tbz2`|`public.tar-bzip2-archive`|系统有具体的压缩 TAR 类型，OrangeLen 现有声明未精确覆盖；系统 Generic 仅显示文件卡片|

## 全部 371 项

每行“证据”为本机完整 Finder AX 记录；日志事件编号见 [provider-events.json](provider-events.json)，完整字段见 [final-results.json](final-results.json)。原始截图和 AX 按仓库规则仅保留本机。CSV 可用 Excel 打开：[file-list.csv](file-list.csv)。

|序号|后缀|本轮实际提供器|实际 UTI|本轮文件|证据|
|---:|---|---|---|---|---|
|1|`.swift`|OrangeLen|`public.swift-source`|`001-swift.swift`|[Finder AX](001-swift-ax.txt) / 日志 2|
|2|`.py`|OrangeLen|`public.python-script`|`002-py.py`|[Finder AX](002-py-ax.txt) / 日志 5,8|
|3|`.js`|OrangeLen|`com.netscape.javascript-source`|`003-js.js`|[Finder AX](003-js-ax.txt) / 日志 11|
|4|`.ts`|系统仅基本信息|`public.mpeg-2-transport-stream`|`004-ts.ts`|[Finder AX](recheck-004-ts-ax.txt) / 日志 1217|
|5|`.tsx`|OrangeLen|`com.microsoft.typescript`|`005-tsx.tsx`|[Finder AX](settled-005-tsx-ax.txt) / 日志 15,1219|
|6|`.jsx`|OrangeLen|`local.orangelen.component`|`006-jsx.jsx`|[Finder AX](006-jsx-ax.txt) / 日志 18|
|7|`.mjs`|OrangeLen|`com.netscape.javascript-source`|`007-mjs.mjs`|[Finder AX](007-mjs-ax.txt) / 日志 21|
|8|`.cjs`|OrangeLen|`local.orangelen.developer-source`|`008-cjs.cjs`|[Finder AX](008-cjs-ax.txt) / 日志 24|
|9|`.mts`|系统仅基本信息|`public.avchd-mpeg-2-transport-stream`|`009-mts.mts`|[Finder AX](settled-009-mts-ax.txt) / 日志 1221|
|10|`.cts`|OrangeLen|`local.orangelen.developer-source`|`010-cts.cts`|[Finder AX](010-cts-ax.txt) / 日志 28|
|11|`.vue`|OrangeLen|`local.orangelen.developer-source`|`011-vue.vue`|[Finder AX](011-vue-ax.txt) / 日志 31|
|12|`.svelte`|OrangeLen|`local.orangelen.developer-source`|`012-svelte.svelte`|[Finder AX](012-svelte-ax.txt) / 日志 34|
|13|`.astro`|OrangeLen|`local.orangelen.developer-source`|`013-astro.astro`|[Finder AX](013-astro-ax.txt) / 日志 37|
|14|`.c`|OrangeLen|`public.c-source`|`014-c.c`|[Finder AX](014-c-ax.txt) / 日志 40|
|15|`.h`|OrangeLen|`public.c-header`|`015-h.h`|[Finder AX](015-h-ax.txt) / 日志 43|
|16|`.cpp`|OrangeLen|`public.c-plus-plus-source`|`016-cpp.cpp`|[Finder AX](016-cpp-ax.txt) / 日志 46|
|17|`.hpp`|OrangeLen|`public.c-plus-plus-header`|`017-hpp.hpp`|[Finder AX](017-hpp-ax.txt) / 日志 49|
|18|`.rs`|OrangeLen|`local.orangelen.developer-source`|`018-rs.rs`|[Finder AX](018-rs-ax.txt) / 日志 52|
|19|`.go`|OrangeLen|`local.orangelen.developer-source`|`019-go.go`|[Finder AX](019-go-ax.txt) / 日志 55|
|20|`.sh`|OrangeLen|`public.shell-script`|`020-sh.sh`|[Finder AX](020-sh-ax.txt) / 日志 58|
|21|`.zsh`|系统内容预览|`public.zsh-script`|`021-zsh.zsh`|[Finder AX](settled-021-zsh-ax.txt) / 日志 1222|
|22|`.bash`|系统内容预览|`public.bash-script`|`022-bash.bash`|[Finder AX](settled-022-bash-ax.txt) / 日志 1223|
|23|`.rb`|OrangeLen|`public.ruby-script`|`023-rb.rb`|[Finder AX](023-rb-ax.txt) / 日志 63|
|24|`.java`|OrangeLen|`com.sun.java-source`|`024-java.java`|[Finder AX](024-java-ax.txt) / 日志 66|
|25|`.kt`|OrangeLen|`local.orangelen.developer-source`|`025-kt.kt`|[Finder AX](025-kt-ax.txt) / 日志 69|
|26|`.css`|OrangeLen|`public.css`|`026-css.css`|[Finder AX](026-css-ax.txt) / 日志 72|
|27|`.scss`|OrangeLen|`local.orangelen.developer-source`|`027-scss.scss`|[Finder AX](027-scss-ax.txt) / 日志 75|
|28|`.sass`|OrangeLen|`local.orangelen.developer-source`|`028-sass.sass`|[Finder AX](028-sass-ax.txt) / 日志 78|
|29|`.less`|OrangeLen|`local.orangelen.developer-source`|`029-less.less`|[Finder AX](029-less-ax.txt) / 日志 81|
|30|`.html`|系统内容预览|`public.html`|`030-html.html`|[Finder AX](settled-030-html-ax.txt) / 日志 1224|
|31|`.htm`|系统内容预览|`public.html`|`031-htm.htm`|[Finder AX](settled-031-htm-ax.txt) / 日志 1225|
|32|`.xhtml`|系统内容预览|`public.xhtml`|`032-xhtml.xhtml`|[Finder AX](settled-032-xhtml-ax.txt) / 日志 1226|
|33|`.sql`|OrangeLen|`org.iso.sql`|`033-sql.sql`|[Finder AX](033-sql-ax.txt) / 日志 87|
|34|`.cs`|OrangeLen|`local.orangelen.developer-source`|`034-cs.cs`|[Finder AX](034-cs-ax.txt) / 日志 90|
|35|`.php`|OrangeLen|`public.php-script`|`035-php.php`|[Finder AX](035-php-ax.txt) / 日志 93|
|36|`.dart`|OrangeLen|`local.orangelen.developer-source`|`036-dart.dart`|[Finder AX](036-dart-ax.txt) / 日志 96|
|37|`.lua`|OrangeLen|`local.orangelen.developer-source`|`037-lua.lua`|[Finder AX](037-lua-ax.txt) / 日志 99|
|38|`.r`|系统内容预览|`com.apple.rez-source`|`038-r.r`|[Finder AX](settled-038-r-ax.txt) / 日志 1227|
|39|`.scala`|OrangeLen|`local.orangelen.developer-source`|`039-scala.scala`|[Finder AX](039-scala-ax.txt) / 日志 103|
|40|`.ps1`|OrangeLen|`local.orangelen.developer-source`|`040-ps1.ps1`|[Finder AX](040-ps1-ax.txt) / 日志 106|
|41|`.proto`|系统内容预览|`public.protobuf-source`|`041-proto.proto`|[Finder AX](settled-041-proto-ax.txt) / 日志 1228|
|42|`.graphql`|OrangeLen|`local.orangelen.developer-source`|`042-graphql.graphql`|[Finder AX](042-graphql-ax.txt) / 日志 110|
|43|`.gql`|OrangeLen|`local.orangelen.developer-source`|`043-gql.gql`|[Finder AX](043-gql-ax.txt) / 日志 113|
|44|`.tf`|OrangeLen|`local.orangelen.developer-source`|`044-tf.tf`|[Finder AX](044-tf-ax.txt) / 日志 116|
|45|`.tfvars`|OrangeLen|`local.orangelen.developer-source`|`045-tfvars.tfvars`|[Finder AX](045-tfvars-ax.txt) / 日志 119|
|46|`.hcl`|OrangeLen|`local.orangelen.developer-source`|`046-hcl.hcl`|[Finder AX](046-hcl-ax.txt) / 日志 122|
|47|`.pyi`|OrangeLen|`local.orangelen.developer-source`|`047-pyi.pyi`|[Finder AX](047-pyi-ax.txt) / 日志 125|
|48|`.pyx`|OrangeLen|`local.orangelen.developer-source`|`048-pyx.pyx`|[Finder AX](048-pyx-ax.txt) / 日志 128|
|49|`.pxd`|OrangeLen|`local.orangelen.developer-source`|`049-pxd.pxd`|[Finder AX](049-pxd-ax.txt) / 日志 131|
|50|`.pxi`|OrangeLen|`local.orangelen.developer-source`|`050-pxi.pxi`|[Finder AX](050-pxi-ax.txt) / 日志 134|
|51|`.cu`|OrangeLen|`local.orangelen.developer-source`|`051-cu.cu`|[Finder AX](051-cu-ax.txt) / 日志 137|
|52|`.cuh`|OrangeLen|`local.orangelen.developer-source`|`052-cuh.cuh`|[Finder AX](052-cuh-ax.txt) / 日志 140|
|53|`.cc`|OrangeLen|`public.c-plus-plus-source`|`053-cc.cc`|[Finder AX](053-cc-ax.txt) / 日志 143|
|54|`.cxx`|OrangeLen|`public.c-plus-plus-source`|`054-cxx.cxx`|[Finder AX](054-cxx-ax.txt) / 日志 146|
|55|`.hh`|OrangeLen|`public.c-plus-plus-header`|`055-hh.hh`|[Finder AX](055-hh-ax.txt) / 日志 149|
|56|`.hxx`|OrangeLen|`public.c-plus-plus-header`|`056-hxx.hxx`|[Finder AX](056-hxx-ax.txt) / 日志 152|
|57|`.ipp`|OrangeLen|`public.c-plus-plus-header`|`057-ipp.ipp`|[Finder AX](057-ipp-ax.txt) / 日志 155|
|58|`.tpp`|OrangeLen|`local.orangelen.developer-source`|`058-tpp.tpp`|[Finder AX](058-tpp-ax.txt) / 日志 158|
|59|`.inl`|OrangeLen|`public.c-plus-plus-inline-header`|`059-inl.inl`|[Finder AX](059-inl-ax.txt) / 日志 161|
|60|`.kts`|OrangeLen|`local.orangelen.developer-source`|`060-kts.kts`|[Finder AX](060-kts-ax.txt) / 日志 164|
|61|`.gradle`|OrangeLen|`local.orangelen.developer-source`|`061-gradle.gradle`|[Finder AX](061-gradle-ax.txt) / 日志 167|
|62|`.groovy`|OrangeLen|`local.orangelen.developer-source`|`062-groovy.groovy`|[Finder AX](062-groovy-ax.txt) / 日志 170|
|63|`.cmake`|OrangeLen|`local.orangelen.developer-source`|`063-cmake.cmake`|[Finder AX](063-cmake-ax.txt) / 日志 173|
|64|`.mk`|OrangeLen|`public.make-source`|`064-mk.mk`|[Finder AX](064-mk-ax.txt) / 日志 176|
|65|`.mdc`|OrangeLen|`local.orangelen.developer-source`|`065-mdc.mdc`|[Finder AX](065-mdc-ax.txt) / 日志 179|
|66|`.http`|OrangeLen|`local.orangelen.developer-source`|`066-http.http`|[Finder AX](066-http-ax.txt) / 日志 182|
|67|`.rest`|OrangeLen|`local.orangelen.developer-source`|`067-rest.rest`|[Finder AX](067-rest-ax.txt) / 日志 185|
|68|`.j2`|OrangeLen|`local.orangelen.developer-source`|`068-j2.j2`|[Finder AX](068-j2-ax.txt) / 日志 188|
|69|`.jinja`|OrangeLen|`local.orangelen.developer-source`|`069-jinja.jinja`|[Finder AX](069-jinja-ax.txt) / 日志 191|
|70|`.jinja2`|OrangeLen|`local.orangelen.developer-source`|`070-jinja2.jinja2`|[Finder AX](070-jinja2-ax.txt) / 日志 194|
|71|`.tmpl`|OrangeLen|`local.orangelen.developer-source`|`071-tmpl.tmpl`|[Finder AX](071-tmpl-ax.txt) / 日志 197|
|72|`.tpl`|OrangeLen|`local.orangelen.developer-source`|`072-tpl.tpl`|[Finder AX](072-tpl-ax.txt) / 日志 200|
|73|`.rst`|OrangeLen|`local.orangelen.developer-source`|`073-rst.rst`|[Finder AX](073-rst-ax.txt) / 日志 203|
|74|`.adoc`|OrangeLen|`local.orangelen.developer-source`|`074-adoc.adoc`|[Finder AX](074-adoc-ax.txt) / 日志 206|
|75|`.asciidoc`|OrangeLen|`local.orangelen.developer-source`|`075-asciidoc.asciidoc`|[Finder AX](075-asciidoc-ax.txt) / 日志 209|
|76|`.txt`|系统内容预览|`public.plain-text`|`076-txt.txt`|[Finder AX](settled-076-txt-ax.txt) / 日志 1229|
|77|`.log`|系统内容预览|`com.apple.log`|`077-log.log`|[Finder AX](settled-077-log-ax.txt) / 日志 1231|
|78|`.ini`|OrangeLen|`com.microsoft.ini`|`078-ini.ini`|[Finder AX](078-ini-ax.txt) / 日志 214|
|79|`.conf`|OrangeLen|`local.orangelen.developer-source`|`079-conf.conf`|[Finder AX](079-conf-ax.txt) / 日志 217|
|80|`.config`|OrangeLen|`public.toml`|`080-config.config`|[Finder AX](080-config-ax.txt) / 日志 220|
|81|`.properties`|OrangeLen|`local.orangelen.developer-source`|`081-properties.properties`|[Finder AX](081-properties-ax.txt) / 日志 223|
|82|`.plist`|OrangeLen|`com.apple.property-list`|`082-plist.plist`|[Finder AX](082-plist-ax.txt) / 日志 226|
|83|`.yaml`|OrangeLen|`public.yaml`|`083-yaml.yaml`|[Finder AX](settled-083-yaml-ax.txt) / 日志 229,1233|
|84|`.yml`|OrangeLen|`public.yaml`|`084-yml.yml`|[Finder AX](084-yml-ax.txt) / 日志 232|
|85|`.toml`|OrangeLen|`public.toml`|`085-toml.toml`|[Finder AX](085-toml-ax.txt) / 日志 235|
|86|`.xml`|OrangeLen|`public.xml`|`086-xml.xml`|[Finder AX](086-xml-ax.txt) / 日志 238|
|87|`.md`|OrangeLen|`net.daringfireball.markdown`|`087-md.md`|[Finder AX](settled-087-md-ax.txt) / 日志 241,1236|
|88|`.markdown`|OrangeLen|`net.daringfireball.markdown`|`088-markdown.markdown`|[Finder AX](088-markdown-ax.txt) / 日志 244|
|89|`.mdx`|OrangeLen|`local.orangelen.typesetting`|`089-mdx.mdx`|[Finder AX](settled-089-mdx-ax.txt) / 日志 247,1239|
|90|`.tex`|OrangeLen|`local.orangelen.typesetting`|`090-tex.tex`|[Finder AX](090-tex-ax.txt) / 日志 250|
|91|`.typ`|OrangeLen|`local.orangelen.typesetting`|`091-typ.typ`|[Finder AX](091-typ-ax.txt) / 日志 253|
|92|`.ipynb`|OrangeLen|`local.orangelen.notebook`|`092-ipynb.ipynb`|[Finder AX](092-ipynb-ax.txt) / 日志 256|
|93|`.epub`|OrangeLen|`org.idpf.epub-container`|`093-epub.epub`|[Finder AX](093-epub-ax.txt) / 日志 259|
|94|`.pdf`|系统内容预览|`com.adobe.pdf`|`094-pdf.pdf`|[Finder AX](settled-094-pdf-ax.txt) / 日志 1241|
|95|`.json`|OrangeLen|`public.json`|`095-json.json`|[Finder AX](095-json-ax.txt) / 日志 263|
|96|`.jsonc`|OrangeLen|`local.orangelen.jsonc`|`096-jsonc.jsonc`|[Finder AX](096-jsonc-ax.txt) / 日志 266|
|97|`.json5`|OrangeLen|`local.orangelen.json5`|`097-json5.json5`|[Finder AX](097-json5-ax.txt) / 日志 269|
|98|`.jsonl`|OrangeLen|`local.orangelen.jsonl`|`098-jsonl.jsonl`|[Finder AX](098-jsonl-ax.txt) / 日志 272|
|99|`.ndjson`|OrangeLen|`public.ndjson`|`099-ndjson.ndjson`|[Finder AX](099-ndjson-ax.txt) / 日志 275|
|100|`.csv`|系统内容预览|`public.comma-separated-values-text`|`100-csv.csv`|[Finder AX](settled-100-csv-ax.txt) / 日志 1242|
|101|`.tsv`|OrangeLen|`public.tab-separated-values-text`|`101-tsv.tsv`|[Finder AX](101-tsv-ax.txt) / 日志 279|
|102|`.sqlite`|OrangeLen|`local.orangelen.sqlite`|`102-sqlite.sqlite`|[Finder AX](102-sqlite-ax.txt) / 日志 282|
|103|`.sqlite3`|OrangeLen|`local.orangelen.sqlite`|`103-sqlite3.sqlite3`|[Finder AX](103-sqlite3-ax.txt) / 日志 285|
|104|`.db`|OrangeLen|`local.orangelen.sqlite`|`104-db.db`|[Finder AX](104-db-ax.txt) / 日志 288|
|105|`.har`|OrangeLen|`local.orangelen.har`|`105-har.har`|[Finder AX](105-har-ax.txt) / 日志 291|
|106|`.sarif`|OrangeLen|`local.orangelen.sarif`|`106-sarif.sarif`|[Finder AX](106-sarif-ax.txt) / 日志 294|
|107|`.mmd`|OrangeLen|`local.orangelen.mermaid`|`107-mmd.mmd`|[Finder AX](settled-107-mmd-ax.txt) / 日志 297,1244|
|108|`.mermaid`|OrangeLen|`local.orangelen.mermaid`|`108-mermaid.mermaid`|[Finder AX](108-mermaid-ax.txt) / 日志 299|
|109|`.excalidraw`|OrangeLen|`com.excalidraw.excalidraw`|`109-excalidraw.excalidraw`|[Finder AX](109-excalidraw-ax.txt) / 日志 303|
|110|`.drawio`|OrangeLen|`local.orangelen.diagram`|`110-drawio.drawio`|[Finder AX](110-drawio-ax.txt) / 日志 306|
|111|`.canvas`|OrangeLen|`local.orangelen.diagram`|`111-canvas.canvas`|[Finder AX](111-canvas-ax.txt) / 日志 309|
|112|`.svg`|系统内容预览|`public.svg-image`|`112-svg.svg`|[Finder AX](settled-112-svg-ax.txt) / 日志 1246|
|113|`.xmind`|OrangeLen|`org.xmind.openformat.xmind`|`113-xmind.xmind`|[Finder AX](113-xmind-ax.txt) / 日志 313|
|114|`.mm`|OrangeLen|`public.objective-c-plus-plus-source`|`114-mm.mm`|[Finder AX](114-mm-ax.txt) / 日志 316|
|115|`.opml`|OrangeLen|`org.opml.opml`|`115-opml.opml`|[Finder AX](115-opml-ax.txt) / 日志 319|
|116|`.mmap`|OrangeLen|`com.mindjet.mindmanager.mmap`|`116-mmap.mmap`|[Finder AX](116-mmap-ax.txt) / 日志 322|
|117|`.dot`|系统仅基本信息|`com.microsoft.word.dot`|`117-dot.dot`|[Finder AX](settled-117-dot-ax.txt) / 日志 1247|
|118|`.gv`|OrangeLen|`local.orangelen.diagram`|`118-gv.gv`|[Finder AX](118-gv-ax.txt) / 日志 326|
|119|`.skill`|OrangeLen|`local.orangelen.skill`|`119-skill.skill`|[Finder AX](settled-119-skill-ax.txt) / 日志 329,1249|
|120|`.mcpb`|OrangeLen|`local.orangelen.mcpb`|`120-mcpb.mcpb`|[Finder AX](120-mcpb-ax.txt) / 日志 332|
|121|`.dxt`|OrangeLen|`local.orangelen.mcpb`|`121-dxt.dxt`|[Finder AX](121-dxt-ax.txt) / 日志 335|
|122|`.n8np`|OrangeLen|`local.orangelen.n8n-package`|`122-n8np.n8np`|[Finder AX](122-n8np-ax.txt) / 日志 338|
|123|`.zip`|OrangeLen|`public.zip-archive`|`123-zip.zip`|[Finder AX](123-zip-ax.txt) / 日志 341|
|124|`.tar`|OrangeLen|`public.tar-archive`|`124-tar.tar`|[Finder AX](124-tar-ax.txt) / 日志 344|
|125|`.tgz`|OrangeLen|`org.gnu.gnu-zip-tar-archive`|`125-tgz.tgz`|[Finder AX](125-tgz-ax.txt) / 日志 347|
|126|`.gz`|OrangeLen|`org.gnu.gnu-zip-archive`|`126-gz.gz`|[Finder AX](126-gz-ax.txt) / 日志 350|
|127|`.whl`|OrangeLen|`local.orangelen.developer-package`|`127-whl.whl`|[Finder AX](127-whl-ax.txt) / 日志 353|
|128|`.vsix`|OrangeLen|`local.orangelen.developer-package`|`128-vsix.vsix`|[Finder AX](128-vsix-ax.txt) / 日志 356|
|129|`.7z`|OrangeLen|`org.7-zip.7-zip-archive`|`129-7z.7z`|[Finder AX](129-7z-ax.txt) / 日志 359|
|130|`.rar`|OrangeLen|`local.orangelen.extended-archive`|`130-rar.rar`|[Finder AX](130-rar-ax.txt) / 日志 362|
|131|`.xz`|OrangeLen|`org.tukaani.xz-archive`|`131-xz.tar.xz`|[Finder AX](settled-131-xz-ax.txt) / 日志 365,1252|
|132|`.bz2`|OrangeLen|`public.bzip2-archive`|`132-bz2.tar.bz2`|[Finder AX](settled-132-bz2-ax.txt) / 日志 368,1255|
|133|`.zst`|OrangeLen|`local.orangelen.extended-archive`|`133-zst.tar.zst`|[Finder AX](settled-133-zst-ax.txt) / 日志 371,1258|
|134|`.txz`|系统仅基本信息|`org.tukaani.tar-xz-archive`|`134-txz.txz`|[Finder AX](settled-134-txz-ax.txt) / 日志 1260|
|135|`.tbz2`|系统仅基本信息|`public.tar-bzip2-archive`|`135-tbz2.tbz2`|[Finder AX](settled-135-tbz2-ax.txt) / 日志 1261|
|136|`.tzst`|OrangeLen|`local.orangelen.extended-archive`|`136-tzst.tzst`|[Finder AX](136-tzst-ax.txt) / 日志 377|
|137|`.obj`|OrangeLen|`public.geometry-definition-format`|`137-obj.obj`|[Finder AX](137-obj-ax.txt) / 日志 380,383|
|138|`.stl`|OrangeLen|`public.standard-tesselated-geometry-format`|`138-stl.stl`|[Finder AX](138-stl-ax.txt) / 日志 386|
|139|`.gltf`|OrangeLen|`org.khronos.gltf`|`139-gltf.gltf`|[Finder AX](139-gltf-ax.txt) / 日志 389|
|140|`.glb`|OrangeLen|`org.khronos.glb`|`140-glb.glb`|[Finder AX](140-glb-ax.txt) / 日志 392|
|141|`.parquet`|OrangeLen|`local.orangelen.scientific`|`141-parquet.parquet`|[Finder AX](141-parquet-ax.txt) / 日志 395|
|142|`.npy`|OrangeLen|`local.orangelen.scientific`|`142-npy.npy`|[Finder AX](142-npy-ax.txt) / 日志 398|
|143|`.npz`|OrangeLen|`local.orangelen.numpy-archive`|`143-npz.npz`|[Finder AX](143-npz-ax.txt) / 日志 401|
|144|`.safetensors`|OrangeLen|`local.orangelen.scientific`|`144-safetensors.safetensors`|[Finder AX](144-safetensors-ax.txt) / 日志 404|
|145|`.gguf`|OrangeLen|`local.orangelen.scientific`|`145-gguf.gguf`|[Finder AX](145-gguf-ax.txt) / 日志 407|
|146|`.latent`|OrangeLen|`local.orangelen.scientific`|`146-latent.latent`|[Finder AX](146-latent-ax.txt) / 日志 410|
|147|`.arrow`|OrangeLen|`local.orangelen.scientific`|`147-arrow.arrow`|[Finder AX](147-arrow-ax.txt) / 日志 413|
|148|`.ipc`|OrangeLen|`local.orangelen.scientific`|`148-ipc.ipc`|[Finder AX](148-ipc-ax.txt) / 日志 416|
|149|`.feather`|OrangeLen|`local.orangelen.scientific`|`149-feather.feather`|[Finder AX](149-feather-ax.txt) / 日志 419|
|150|`.onnx`|OrangeLen|`local.orangelen.scientific`|`150-onnx.onnx`|[Finder AX](150-onnx-ax.txt) / 日志 422|
|151|`.srt`|OrangeLen|`local.orangelen.subtitle`|`151-srt.srt`|[Finder AX](151-srt-ax.txt) / 日志 425|
|152|`.vtt`|OrangeLen|`org.w3.webvtt`|`152-vtt.vtt`|[Finder AX](152-vtt-ax.txt) / 日志 428|
|153|`.diff`|系统内容预览|`public.patch-file`|`153-diff.diff`|[Finder AX](settled-153-diff-ax.txt) / 日志 1262|
|154|`.patch`|系统内容预览|`public.patch-file`|`154-patch.patch`|[Finder AX](settled-154-patch-ax.txt) / 日志 1263|
|155|`.xmp`|OrangeLen|`org.xmind.openformat.xmp`|`155-xmp.xmp`|[Finder AX](155-xmp-ax.txt) / 日志 433|
|156|`.c2pa`|OrangeLen|`local.orangelen.scientific`|`156-c2pa.c2pa`|[Finder AX](156-c2pa-ax.txt) / 日志 436|
|157|`.a3x`|OrangeLen|`local.orangelen.developer-source`|`157-a3x.a3x`|[Finder AX](157-a3x-ax.txt) / 日志 439|
|158|`.acf`|OrangeLen|`local.orangelen.developer-source`|`158-acf.acf`|[Finder AX](158-acf-ax.txt) / 日志 442|
|159|`.ada`|OrangeLen|`public.ada-source`|`159-ada.ada`|[Finder AX](159-ada-ax.txt) / 日志 445|
|160|`.ado`|OrangeLen|`local.orangelen.developer-source`|`160-ado.ado`|[Finder AX](160-ado-ax.txt) / 日志 448|
|161|`.applescript`|OrangeLen|`com.apple.applescript.text`|`161-applescript.applescript`|[Finder AX](161-applescript-ax.txt) / 日志 451|
|162|`.as`|OrangeLen|`com.apple.applesingle-archive`|`162-as.as`|[Finder AX](162-as-ax.txt) / 日志 454|
|163|`.ascr`|OrangeLen|`local.orangelen.developer-source`|`163-ascr.ascr`|[Finder AX](163-ascr-ax.txt) / 日志 457|
|164|`.asd`|OrangeLen|`local.orangelen.developer-source`|`164-asd.asd`|[Finder AX](164-asd-ax.txt) / 日志 460|
|165|`.asm`|OrangeLen|`local.orangelen.developer-source`|`165-asm.asm`|[Finder AX](165-asm-ax.txt) / 日志 463|
|166|`.asp`|OrangeLen|`local.orangelen.developer-source`|`166-asp.asp`|[Finder AX](166-asp-ax.txt) / 日志 466|
|167|`.aspx`|OrangeLen|`local.orangelen.developer-source`|`167-aspx.aspx`|[Finder AX](167-aspx-ax.txt) / 日志 469|
|168|`.atl`|OrangeLen|`local.orangelen.developer-source`|`168-atl.atl`|[Finder AX](168-atl-ax.txt) / 日志 472|
|169|`.au3`|OrangeLen|`local.orangelen.developer-source`|`169-au3.au3`|[Finder AX](169-au3-ax.txt) / 日志 475|
|170|`.avt`|OrangeLen|`local.orangelen.developer-source`|`170-avt.avt`|[Finder AX](170-avt-ax.txt) / 日志 478|
|171|`.awk`|OrangeLen|`local.orangelen.developer-source`|`171-awk.awk`|[Finder AX](171-awk-ax.txt) / 日志 481|
|172|`.bas`|OrangeLen|`local.orangelen.developer-source`|`172-bas.bas`|[Finder AX](172-bas-ax.txt) / 日志 484|
|173|`.bashrc`|OrangeLen|`local.orangelen.developer-source`|`173-bashrc.bashrc`|[Finder AX](173-bashrc-ax.txt) / 日志 487|
|174|`.basic`|OrangeLen|`local.orangelen.developer-source`|`174-basic.basic`|[Finder AX](174-basic-ax.txt) / 日志 490|
|175|`.bat`|OrangeLen|`local.orangelen.developer-source`|`175-bat.bat`|[Finder AX](175-bat-ax.txt) / 日志 493|
|176|`.bb`|OrangeLen|`local.orangelen.developer-source`|`176-bb.bb`|[Finder AX](176-bb-ax.txt) / 日志 496|
|177|`.bezel`|OrangeLen|`local.orangelen.developer-source`|`177-bezel.bezel`|[Finder AX](177-bezel-ax.txt) / 日志 499|
|178|`.bib`|OrangeLen|`local.orangelen.developer-source`|`178-bib.bib`|[Finder AX](178-bib-ax.txt) / 日志 502|
|179|`.c++`|OrangeLen|`public.c-plus-plus-source`|`179-c++.c++`|[Finder AX](179-c++-ax.txt) / 日志 505|
|180|`.cfc`|OrangeLen|`local.orangelen.developer-source`|`180-cfc.cfc`|[Finder AX](180-cfc-ax.txt) / 日志 508|
|181|`.cfg`|OrangeLen|`public.toml`|`181-cfg.cfg`|[Finder AX](181-cfg-ax.txt) / 日志 511|
|182|`.cfm`|OrangeLen|`local.orangelen.developer-source`|`182-cfm.cfm`|[Finder AX](182-cfm-ax.txt) / 日志 514|
|183|`.cfml`|OrangeLen|`local.orangelen.developer-source`|`183-cfml.cfml`|[Finder AX](183-cfml-ax.txt) / 日志 517|
|184|`.class`|OrangeLen|`com.sun.java-class`|`184-class.class`|[Finder AX](184-class-ax.txt) / 日志 520|
|185|`.cli`|OrangeLen|`local.orangelen.developer-source`|`185-cli.cli`|[Finder AX](185-cli-ax.txt) / 日志 523|
|186|`.clj`|OrangeLen|`local.orangelen.developer-source`|`186-clj.clj`|[Finder AX](186-clj-ax.txt) / 日志 526|
|187|`.cljc`|OrangeLen|`local.orangelen.developer-source`|`187-cljc.cljc`|[Finder AX](187-cljc-ax.txt) / 日志 529|
|188|`.cljs`|OrangeLen|`local.orangelen.developer-source`|`188-cljs.cljs`|[Finder AX](188-cljs-ax.txt) / 日志 532|
|189|`.cls`|OrangeLen|`local.orangelen.developer-source`|`189-cls.cls`|[Finder AX](189-cls-ax.txt) / 日志 535|
|190|`.cmd`|OrangeLen|`local.orangelen.developer-source`|`190-cmd.cmd`|[Finder AX](190-cmd-ax.txt) / 日志 538|
|191|`.code-workspace`|OrangeLen|`local.orangelen.developer-source`|`191-code-workspace.code-workspace`|[Finder AX](191-code-workspace-ax.txt) / 日志 541|
|192|`.coffee`|OrangeLen|`local.orangelen.developer-source`|`192-coffee.coffee`|[Finder AX](192-coffee-ax.txt) / 日志 544|
|193|`.command`|OrangeLen|`com.apple.terminal.shell-script`|`193-command.command`|[Finder AX](193-command-ax.txt) / 日志 547|
|194|`.con`|OrangeLen|`local.orangelen.developer-source`|`194-con.con`|[Finder AX](194-con-ax.txt) / 日志 550|
|195|`.cp`|OrangeLen|`public.c-plus-plus-source`|`195-cp.cp`|[Finder AX](195-cp-ax.txt) / 日志 553|
|196|`.cr`|OrangeLen|`local.orangelen.developer-source`|`196-cr.cr`|[Finder AX](196-cr-ax.txt) / 日志 556|
|197|`.csh`|OrangeLen|`public.csh-script`|`197-csh.csh`|[Finder AX](197-csh-ax.txt) / 日志 559|
|198|`.cson`|OrangeLen|`local.orangelen.developer-source`|`198-cson.cson`|[Finder AX](198-cson-ax.txt) / 日志 562|
|199|`.csproj`|OrangeLen|`local.orangelen.developer-source`|`199-csproj.csproj`|[Finder AX](199-csproj-ax.txt) / 日志 565|
|200|`.ctx`|OrangeLen|`local.orangelen.developer-source`|`200-ctx.ctx`|[Finder AX](200-ctx-ax.txt) / 日志 568|
|201|`.d`|OrangeLen|`local.orangelen.developer-source`|`201-d.d`|[Finder AX](201-d-ax.txt) / 日志 571|
|202|`.designspace`|OrangeLen|`local.orangelen.developer-source`|`202-designspace.designspace`|[Finder AX](202-designspace-ax.txt) / 日志 574|
|203|`.do`|OrangeLen|`local.orangelen.developer-source`|`203-do.do`|[Finder AX](203-do-ax.txt) / 日志 577|
|204|`.dockerfile`|OrangeLen|`local.orangelen.developer-source`|`204-dockerfile.dockerfile`|[Finder AX](204-dockerfile-ax.txt) / 日志 580|
|205|`.dtd`|OrangeLen|`local.orangelen.developer-source`|`205-dtd.dtd`|[Finder AX](205-dtd-ax.txt) / 日志 583|
|206|`.dylan`|OrangeLen|`local.orangelen.developer-source`|`206-dylan.dylan`|[Finder AX](206-dylan-ax.txt) / 日志 586|
|207|`.e`|OrangeLen|`local.orangelen.developer-source`|`207-e.e`|[Finder AX](207-e-ax.txt) / 日志 589|
|208|`.ecf`|OrangeLen|`local.orangelen.developer-source`|`208-ecf.ecf`|[Finder AX](208-ecf-ax.txt) / 日志 592|
|209|`.ecore`|OrangeLen|`local.orangelen.developer-source`|`209-ecore.ecore`|[Finder AX](209-ecore-ax.txt) / 日志 595|
|210|`.edn`|OrangeLen|`com.adobe.edn`|`210-edn.edn`|[Finder AX](210-edn-ax.txt) / 日志 598|
|211|`.el`|OrangeLen|`local.orangelen.developer-source`|`211-el.el`|[Finder AX](211-el-ax.txt) / 日志 601|
|212|`.entitlements`|OrangeLen|`com.apple.xcode.entitlements-property-list`|`212-entitlements.entitlements`|[Finder AX](212-entitlements-ax.txt) / 日志 604|
|213|`.env`|OrangeLen|`local.orangelen.developer-source`|`213-env.env`|[Finder AX](213-env-ax.txt) / 日志 607|
|214|`.erb`|OrangeLen|`local.orangelen.developer-source`|`214-erb.erb`|[Finder AX](214-erb-ax.txt) / 日志 610|
|215|`.erl`|OrangeLen|`local.orangelen.developer-source`|`215-erl.erl`|[Finder AX](215-erl-ax.txt) / 日志 613|
|216|`.ex`|OrangeLen|`local.orangelen.developer-source`|`216-ex.ex`|[Finder AX](216-ex-ax.txt) / 日志 616|
|217|`.exs`|OrangeLen|`local.orangelen.developer-source`|`217-exs.exs`|[Finder AX](217-exs-ax.txt) / 日志 619|
|218|`.f`|OrangeLen|`public.fortran-source`|`218-f.f`|[Finder AX](218-f-ax.txt) / 日志 622|
|219|`.f90`|OrangeLen|`public.fortran-90-source`|`219-f90.f90`|[Finder AX](219-f90-ax.txt) / 日志 625|
|220|`.f95`|OrangeLen|`public.fortran-95-source`|`220-f95.f95`|[Finder AX](220-f95-ax.txt) / 日志 628|
|221|`.fea`|OrangeLen|`local.orangelen.developer-source`|`221-fea.fea`|[Finder AX](221-fea-ax.txt) / 日志 631|
|222|`.fish`|OrangeLen|`local.orangelen.developer-source`|`222-fish.fish`|[Finder AX](222-fish-ax.txt) / 日志 634|
|223|`.flow`|OrangeLen|`local.orangelen.developer-source`|`223-flow.flow`|[Finder AX](223-flow-ax.txt) / 日志 637|
|224|`.fnc`|OrangeLen|`local.orangelen.developer-source`|`224-fnc.fnc`|[Finder AX](224-fnc-ax.txt) / 日志 640|
|225|`.for`|OrangeLen|`public.fortran-source`|`225-for.for`|[Finder AX](225-for-ax.txt) / 日志 643|
|226|`.fs`|OrangeLen|`org.khronos.glsl.fragment-shader`|`226-fs.fs`|[Finder AX](226-fs-ax.txt) / 日志 646|
|227|`.fsx`|OrangeLen|`local.orangelen.developer-source`|`227-fsx.fsx`|[Finder AX](227-fsx-ax.txt) / 日志 649|
|228|`.fxml`|OrangeLen|`local.orangelen.developer-source`|`228-fxml.fxml`|[Finder AX](228-fxml-ax.txt) / 日志 652|
|229|`.gd`|OrangeLen|`local.orangelen.developer-source`|`229-gd.gd`|[Finder AX](229-gd-ax.txt) / 日志 655|
|230|`.gemfile`|OrangeLen|`local.orangelen.developer-source`|`230-gemfile.gemfile`|[Finder AX](230-gemfile-ax.txt) / 日志 658|
|231|`.gleam`|OrangeLen|`local.orangelen.developer-source`|`231-gleam.gleam`|[Finder AX](231-gleam-ax.txt) / 日志 661|
|232|`.gpx`|OrangeLen|`com.topografix.gpx`|`232-gpx.gpx`|[Finder AX](232-gpx-ax.txt) / 日志 664|
|233|`.haml`|OrangeLen|`local.orangelen.developer-source`|`233-haml.haml`|[Finder AX](233-haml-ax.txt) / 日志 667|
|234|`.heex`|OrangeLen|`local.orangelen.developer-source`|`234-heex.heex`|[Finder AX](234-heex-ax.txt) / 日志 670|
|235|`.hri`|OrangeLen|`local.orangelen.developer-source`|`235-hri.hri`|[Finder AX](235-hri-ax.txt) / 日志 673|
|236|`.hrl`|OrangeLen|`local.orangelen.developer-source`|`236-hrl.hrl`|[Finder AX](236-hrl-ax.txt) / 日志 676|
|237|`.hs`|OrangeLen|`local.orangelen.developer-source`|`237-hs.hs`|[Finder AX](237-hs-ax.txt) / 日志 679|
|238|`.ily`|OrangeLen|`local.orangelen.developer-source`|`238-ily.ily`|[Finder AX](238-ily-ax.txt) / 日志 682|
|239|`.iml`|OrangeLen|`local.orangelen.developer-source`|`239-iml.iml`|[Finder AX](239-iml-ax.txt) / 日志 685|
|240|`.inf`|OrangeLen|`local.orangelen.developer-source`|`240-inf.inf`|[Finder AX](240-inf-ax.txt) / 日志 688|
|241|`.ino`|OrangeLen|`local.orangelen.developer-source`|`241-ino.ino`|[Finder AX](241-ino-ax.txt) / 日志 691|
|242|`.iss`|OrangeLen|`local.orangelen.developer-source`|`242-iss.iss`|[Finder AX](242-iss-ax.txt) / 日志 694|
|243|`.jav`|OrangeLen|`com.sun.java-source`|`243-jav.jav`|[Finder AX](243-jav-ax.txt) / 日志 697|
|244|`.javascript`|OrangeLen|`com.netscape.javascript-source`|`244-javascript.javascript`|[Finder AX](244-javascript-ax.txt) / 日志 700|
|245|`.jl`|OrangeLen|`local.orangelen.developer-source`|`245-jl.jl`|[Finder AX](245-jl-ax.txt) / 日志 703|
|246|`.jnlp`|OrangeLen|`com.sun.java-web-start`|`246-jnlp.jnlp`|[Finder AX](246-jnlp-ax.txt) / 日志 706|
|247|`.jscript`|OrangeLen|`com.netscape.javascript-source`|`247-jscript.jscript`|[Finder AX](247-jscript-ax.txt) / 日志 709|
|248|`.jsm`|OrangeLen|`local.orangelen.developer-source`|`248-jsm.jsm`|[Finder AX](248-jsm-ax.txt) / 日志 712|
|249|`.jsp`|OrangeLen|`local.orangelen.developer-source`|`249-jsp.jsp`|[Finder AX](249-jsp-ax.txt) / 日志 715|
|250|`.kml`|OrangeLen|`local.orangelen.developer-source`|`250-kml.kml`|[Finder AX](250-kml-ax.txt) / 日志 718|
|251|`.kmt`|OrangeLen|`local.orangelen.developer-source`|`251-kmt.kmt`|[Finder AX](251-kmt-ax.txt) / 日志 721|
|252|`.ksh`|OrangeLen|`public.ksh-script`|`252-ksh.ksh`|[Finder AX](252-ksh-ax.txt) / 日志 724|
|253|`.latex`|OrangeLen|`local.orangelen.developer-source`|`253-latex.latex`|[Finder AX](253-latex-ax.txt) / 日志 727|
|254|`.lay`|OrangeLen|`local.orangelen.developer-source`|`254-lay.lay`|[Finder AX](254-lay-ax.txt) / 日志 730|
|255|`.ld`|OrangeLen|`local.orangelen.developer-source`|`255-ld.ld`|[Finder AX](255-ld-ax.txt) / 日志 733|
|256|`.lhs`|OrangeLen|`local.orangelen.developer-source`|`256-lhs.lhs`|[Finder AX](256-lhs-ax.txt) / 日志 736|
|257|`.lisp`|OrangeLen|`local.orangelen.developer-source`|`257-lisp.lisp`|[Finder AX](257-lisp-ax.txt) / 日志 739,743|
|258|`.loctable`|OrangeLen|`local.orangelen.developer-source`|`258-loctable.loctable`|[Finder AX](258-loctable-ax.txt) / 日志 745|
|259|`.lsp`|OrangeLen|`local.orangelen.developer-source`|`259-lsp.lsp`|[Finder AX](259-lsp-ax.txt) / 日志 748,751|
|260|`.ltx`|OrangeLen|`local.orangelen.developer-source`|`260-ltx.ltx`|[Finder AX](260-ltx-ax.txt) / 日志 754,757|
|261|`.ly`|OrangeLen|`local.orangelen.developer-source`|`261-ly.ly`|[Finder AX](261-ly-ax.txt) / 日志 760,763|
|262|`.m`|OrangeLen|`public.objective-c-source`|`262-m.m`|[Finder AX](262-m-ax.txt) / 日志 766|
|263|`.mak`|OrangeLen|`public.make-source`|`263-mak.mak`|[Finder AX](263-mak-ax.txt) / 日志 769|
|264|`.map`|OrangeLen|`local.orangelen.developer-source`|`264-map.map`|[Finder AX](264-map-ax.txt) / 日志 772,775|
|265|`.mf`|OrangeLen|`local.orangelen.developer-source`|`265-mf.mf`|[Finder AX](265-mf-ax.txt) / 日志 778,782|
|266|`.mill`|OrangeLen|`local.orangelen.developer-source`|`266-mill.mill`|[Finder AX](266-mill-ax.txt) / 日志 783|
|267|`.ml`|OrangeLen|`local.orangelen.developer-source`|`267-ml.ml`|[Finder AX](267-ml-ax.txt) / 日志 787,790|
|268|`.mll`|OrangeLen|`local.orangelen.developer-source`|`268-mll.mll`|[Finder AX](268-mll-ax.txt) / 日志 793,797|
|269|`.mly`|OrangeLen|`local.orangelen.developer-source`|`269-mly.mly`|[Finder AX](269-mly-ax.txt) / 日志 799,802|
|270|`.mobileconfig`|OrangeLen|`com.apple.mobileconfig`|`270-mobileconfig.mobileconfig`|[Finder AX](270-mobileconfig-ax.txt) / 日志 805|
|271|`.mpd`|OrangeLen|`local.orangelen.developer-source`|`271-mpd.mpd`|[Finder AX](271-mpd-ax.txt) / 日志 808,811|
|272|`.mq4`|OrangeLen|`local.orangelen.developer-source`|`272-mq4.mq4`|[Finder AX](272-mq4-ax.txt) / 日志 814|
|273|`.mq5`|OrangeLen|`local.orangelen.developer-source`|`273-mq5.mq5`|[Finder AX](273-mq5-ax.txt) / 日志 817,820|
|274|`.ms`|OrangeLen|`local.orangelen.developer-source`|`274-ms.ms`|[Finder AX](274-ms-ax.txt) / 日志 823,826|
|275|`.mvw`|OrangeLen|`local.orangelen.developer-source`|`275-mvw.mvw`|[Finder AX](275-mvw-ax.txt) / 日志 829,832|
|276|`.mxml`|OrangeLen|`local.orangelen.developer-source`|`276-mxml.mxml`|[Finder AX](276-mxml-ax.txt) / 日志 835|
|277|`.ncx`|OrangeLen|`local.orangelen.developer-source`|`277-ncx.ncx`|[Finder AX](277-ncx-ax.txt) / 日志 838|
|278|`.nf`|OrangeLen|`local.orangelen.developer-source`|`278-nf.nf`|[Finder AX](278-nf-ax.txt) / 日志 841|
|279|`.nim`|OrangeLen|`local.orangelen.developer-source`|`279-nim.nim`|[Finder AX](279-nim-ax.txt) / 日志 844|
|280|`.nix`|OrangeLen|`local.orangelen.developer-source`|`280-nix.nix`|[Finder AX](280-nix-ax.txt) / 日志 847,850|
|281|`.opf`|OrangeLen|`local.orangelen.developer-source`|`281-opf.opf`|[Finder AX](281-opf-ax.txt) / 日志 853|
|282|`.otio`|OrangeLen|`local.orangelen.developer-source`|`282-otio.otio`|[Finder AX](282-otio-ax.txt) / 日志 856,859|
|283|`.pas`|OrangeLen|`public.pascal-source`|`283-pas.pas`|[Finder AX](283-pas-ax.txt) / 日志 862|
|284|`.pck`|OrangeLen|`local.orangelen.developer-source`|`284-pck.pck`|[Finder AX](284-pck-ax.txt) / 日志 865|
|285|`.pddl`|OrangeLen|`local.orangelen.developer-source`|`285-pddl.pddl`|[Finder AX](285-pddl-ax.txt) / 日志 868,871|
|286|`.pde`|OrangeLen|`local.orangelen.developer-source`|`286-pde.pde`|[Finder AX](286-pde-ax.txt) / 日志 874|
|287|`.ph3`|OrangeLen|`public.php-script`|`287-ph3.ph3`|[Finder AX](287-ph3-ax.txt) / 日志 877|
|288|`.ph4`|OrangeLen|`public.php-script`|`288-ph4.ph4`|[Finder AX](288-ph4-ax.txt) / 日志 880|
|289|`.php3`|OrangeLen|`public.php-script`|`289-php3.php3`|[Finder AX](289-php3-ax.txt) / 日志 883|
|290|`.php4`|OrangeLen|`public.php-script`|`290-php4.php4`|[Finder AX](290-php4-ax.txt) / 日志 886,889|
|291|`.phtml`|OrangeLen|`public.php-script`|`291-phtml.phtml`|[Finder AX](291-phtml-ax.txt) / 日志 892|
|292|`.pkb`|OrangeLen|`local.orangelen.developer-source`|`292-pkb.pkb`|[Finder AX](292-pkb-ax.txt) / 日志 895,898,901|
|293|`.pks`|OrangeLen|`local.orangelen.developer-source`|`293-pks.pks`|[Finder AX](293-pks-ax.txt) / 日志 904,907|
|294|`.pl`|OrangeLen|`public.perl-script`|`294-pl.pl`|[Finder AX](294-pl-ax.txt) / 日志 910|
|295|`.pm`|OrangeLen|`public.perl-script`|`295-pm.pm`|[Finder AX](295-pm-ax.txt) / 日志 913|
|296|`.podspec`|OrangeLen|`local.orangelen.developer-source`|`296-podspec.podspec`|[Finder AX](296-podspec-ax.txt) / 日志 916,919|
|297|`.pom`|OrangeLen|`local.orangelen.developer-source`|`297-pom.pom`|[Finder AX](297-pom-ax.txt) / 日志 922,925|
|298|`.prc`|OrangeLen|`local.orangelen.developer-source`|`298-prc.prc`|[Finder AX](298-prc-ax.txt) / 日志 928|
|299|`.pro`|OrangeLen|`local.orangelen.developer-source`|`299-pro.pro`|[Finder AX](299-pro-ax.txt) / 日志 931|
|300|`.psd1`|OrangeLen|`local.orangelen.developer-source`|`300-psd1.psd1`|[Finder AX](300-psd1-ax.txt) / 日志 934|
|301|`.psjs`|OrangeLen|`local.orangelen.developer-source`|`301-psjs.psjs`|[Finder AX](301-psjs-ax.txt) / 日志 937|
|302|`.psm1`|OrangeLen|`local.orangelen.developer-source`|`302-psm1.psm1`|[Finder AX](302-psm1-ax.txt) / 日志 940,943|
|303|`.pub`|OrangeLen|`local.orangelen.developer-source`|`303-pub.pub`|[Finder AX](303-pub-ax.txt) / 日志 946|
|304|`.py3`|OrangeLen|`local.orangelen.developer-source`|`304-py3.py3`|[Finder AX](304-py3-ax.txt) / 日志 949,952|
|305|`.raml`|OrangeLen|`local.orangelen.developer-source`|`305-raml.raml`|[Finder AX](305-raml-ax.txt) / 日志 955,958|
|306|`.rbw`|OrangeLen|`public.ruby-script`|`306-rbw.rbw`|[Finder AX](306-rbw-ax.txt) / 日志 961,964|
|307|`.rdf`|OrangeLen|`local.orangelen.developer-source`|`307-rdf.rdf`|[Finder AX](307-rdf-ax.txt) / 日志 967,970|
|308|`.readme`|OrangeLen|`local.orangelen.developer-source`|`308-readme.readme`|[Finder AX](308-readme-ax.txt) / 日志 973,976|
|309|`.rex`|OrangeLen|`local.orangelen.developer-source`|`309-rex.rex`|[Finder AX](309-rex-ax.txt) / 日志 979,982|
|310|`.rexx`|OrangeLen|`local.orangelen.developer-source`|`310-rexx.rexx`|[Finder AX](310-rexx-ax.txt) / 日志 985|
|311|`.rhtml`|OrangeLen|`local.orangelen.developer-source`|`311-rhtml.rhtml`|[Finder AX](311-rhtml-ax.txt) / 日志 988,991|
|312|`.rjs`|OrangeLen|`local.orangelen.developer-source`|`312-rjs.rjs`|[Finder AX](312-rjs-ax.txt) / 日志 994|
|313|`.rkt`|OrangeLen|`local.orangelen.developer-source`|`313-rkt.rkt`|[Finder AX](313-rkt-ax.txt) / 日志 997,1000|
|314|`.robot`|OrangeLen|`local.orangelen.developer-source`|`314-robot.robot`|[Finder AX](314-robot-ax.txt) / 日志 1003|
|315|`.s79`|OrangeLen|`local.orangelen.developer-source`|`315-s79.s79`|[Finder AX](315-s79-ax.txt) / 日志 1006,1009|
|316|`.sage`|OrangeLen|`local.orangelen.developer-source`|`316-sage.sage`|[Finder AX](316-sage-ax.txt) / 日志 1012|
|317|`.sas`|OrangeLen|`local.orangelen.developer-source`|`317-sas.sas`|[Finder AX](317-sas-ax.txt) / 日志 1015,1018|
|318|`.sbt`|OrangeLen|`local.orangelen.developer-source`|`318-sbt.sbt`|[Finder AX](318-sbt-ax.txt) / 日志 1021|
|319|`.sc`|OrangeLen|`local.orangelen.developer-source`|`319-sc.sc`|[Finder AX](319-sc-ax.txt) / 日志 1024|
|320|`.scad`|OrangeLen|`local.orangelen.developer-source`|`320-scad.scad`|[Finder AX](320-scad-ax.txt) / 日志 1027|
|321|`.sch`|OrangeLen|`local.orangelen.developer-source`|`321-sch.sch`|[Finder AX](321-sch-ax.txt) / 日志 1030|
|322|`.scl`|OrangeLen|`local.orangelen.developer-source`|`322-scl.scl`|[Finder AX](322-scl-ax.txt) / 日志 1033|
|323|`.scm`|OrangeLen|`local.orangelen.developer-source`|`323-scm.scm`|[Finder AX](323-scm-ax.txt) / 日志 1036,1039|
|324|`.scpt`|OrangeLen|`com.apple.applescript.script`|`324-scpt.scpt`|[Finder AX](324-scpt-ax.txt) / 日志 1042|
|325|`.sequ`|OrangeLen|`local.orangelen.developer-source`|`325-sequ.sequ`|[Finder AX](325-sequ-ax.txt) / 日志 1045|
|326|`.sld`|OrangeLen|`local.orangelen.developer-source`|`326-sld.sld`|[Finder AX](326-sld-ax.txt) / 日志 1048|
|327|`.sls`|OrangeLen|`local.orangelen.developer-source`|`327-sls.sls`|[Finder AX](327-sls-ax.txt) / 日志 1051,1054|
|328|`.smali`|OrangeLen|`local.orangelen.developer-source`|`328-smali.smali`|[Finder AX](328-smali-ax.txt) / 日志 1057|
|329|`.sol`|OrangeLen|`local.orangelen.developer-source`|`329-sol.sol`|[Finder AX](329-sol-ax.txt) / 日志 1060|
|330|`.sps`|OrangeLen|`local.orangelen.developer-source`|`330-sps.sps`|[Finder AX](330-sps-ax.txt) / 日志 1063,1066|
|331|`.sqs`|OrangeLen|`local.orangelen.developer-source`|`331-sqs.sqs`|[Finder AX](331-sqs-ax.txt) / 日志 1069|
|332|`.ss`|OrangeLen|`local.orangelen.developer-source`|`332-ss.ss`|[Finder AX](332-ss-ax.txt) / 日志 1072,1075|
|333|`.storybard`|OrangeLen|`local.orangelen.developer-source`|`333-storybard.storybard`|[Finder AX](333-storybard-ax.txt) / 日志 1078,1081|
|334|`.storyboard`|OrangeLen|`com.apple.dt.interfacebuilder.document.storyboard`|`334-storyboard.storyboard`|[Finder AX](334-storyboard-ax.txt) / 日志 1084|
|335|`.strings`|OrangeLen|`com.apple.xcode.strings-text`|`335-strings.strings`|[Finder AX](335-strings-ax.txt) / 日志 1087|
|336|`.stringsdict`|OrangeLen|`com.apple.xcode.strings-dictionary`|`336-stringsdict.stringsdict`|[Finder AX](336-stringsdict-ax.txt) / 日志 1090|
|337|`.sty`|OrangeLen|`local.orangelen.developer-source`|`337-sty.sty`|[Finder AX](337-sty-ax.txt) / 日志 1093,1096|
|338|`.t`|OrangeLen|`local.orangelen.developer-source`|`338-t.t`|[Finder AX](338-t-ax.txt) / 日志 1099|
|339|`.tab`|OrangeLen|`local.orangelen.developer-source`|`339-tab.tab`|[Finder AX](339-tab-ax.txt) / 日志 1102|
|340|`.tcl`|OrangeLen|`local.orangelen.developer-source`|`340-tcl.tcl`|[Finder AX](340-tcl-ax.txt) / 日志 1105|
|341|`.tcsh`|OrangeLen|`public.tcsh-script`|`341-tcsh.tcsh`|[Finder AX](341-tcsh-ax.txt) / 日志 1108|
|342|`.texi`|OrangeLen|`local.orangelen.developer-source`|`342-texi.texi`|[Finder AX](342-texi-ax.txt) / 日志 1111|
|343|`.text`|系统内容预览|`public.plain-text`|`343-text.text`|[Finder AX](settled-343-text-ax.txt) / 日志 1264|
|344|`.tfstate`|OrangeLen|`local.orangelen.developer-source`|`344-tfstate.tfstate`|[Finder AX](344-tfstate-ax.txt) / 日志 1115|
|345|`.tpb`|OrangeLen|`local.orangelen.developer-source`|`345-tpb.tpb`|[Finder AX](345-tpb-ax.txt) / 日志 1118|
|346|`.tps`|OrangeLen|`local.orangelen.developer-source`|`346-tps.tps`|[Finder AX](346-tps-ax.txt) / 日志 1121|
|347|`.trg`|OrangeLen|`local.orangelen.developer-source`|`347-trg.trg`|[Finder AX](347-trg-ax.txt) / 日志 1124|
|348|`.ttx`|OrangeLen|`local.orangelen.developer-source`|`348-ttx.ttx`|[Finder AX](348-ttx-ax.txt) / 日志 1127|
|349|`.twig`|OrangeLen|`local.orangelen.developer-source`|`349-twig.twig`|[Finder AX](349-twig-ax.txt) / 日志 1130|
|350|`.unity`|OrangeLen|`local.orangelen.developer-source`|`350-unity.unity`|[Finder AX](350-unity-ax.txt) / 日志 1133|
|351|`.v`|OrangeLen|`local.orangelen.developer-source`|`351-v.v`|[Finder AX](351-v-ax.txt) / 日志 1136|
|352|`.vb`|OrangeLen|`local.orangelen.developer-source`|`352-vb.vb`|[Finder AX](352-vb-ax.txt) / 日志 1139|
|353|`.vbs`|OrangeLen|`local.orangelen.developer-source`|`353-vbs.vbs`|[Finder AX](353-vbs-ax.txt) / 日志 1142|
|354|`.vhd`|OrangeLen|`local.orangelen.developer-source`|`354-vhd.vhd`|[Finder AX](354-vhd-ax.txt) / 日志 1145|
|355|`.vhdl`|OrangeLen|`local.orangelen.developer-source`|`355-vhdl.vhdl`|[Finder AX](355-vhdl-ax.txt) / 日志 1148|
|356|`.vim`|OrangeLen|`local.orangelen.developer-source`|`356-vim.vim`|[Finder AX](356-vim-ax.txt) / 日志 1151|
|357|`.vl`|OrangeLen|`local.orangelen.developer-source`|`357-vl.vl`|[Finder AX](357-vl-ax.txt) / 日志 1154|
|358|`.vw`|OrangeLen|`local.orangelen.developer-source`|`358-vw.vw`|[Finder AX](358-vw-ax.txt) / 日志 1157|
|359|`.wflow`|系统内容预览|`com.apple.shortcuts.workflow-file`|`359-wflow.wflow`|[Finder AX](settled-359-wflow-ax.txt) / 日志 1265|
|360|`.xaml`|OrangeLen|`local.orangelen.developer-source`|`360-xaml.xaml`|[Finder AX](360-xaml-ax.txt) / 日志 1161|
|361|`.xcscheme`|OrangeLen|`com.apple.dt.document.scheme`|`361-xcscheme.xcscheme`|[Finder AX](361-xcscheme-ax.txt) / 日志 1164|
|362|`.xib`|OrangeLen|`com.apple.interfacebuilder.document.cocoa`|`362-xib.xib`|[Finder AX](362-xib-ax.txt) / 日志 1167|
|363|`.xm`|OrangeLen|`local.orangelen.developer-source`|`363-xm.xm`|[Finder AX](363-xm-ax.txt) / 日志 1170,1173|
|364|`.xq`|OrangeLen|`local.orangelen.developer-source`|`364-xq.xq`|[Finder AX](364-xq-ax.txt) / 日志 1176,1179|
|365|`.xquery`|OrangeLen|`local.orangelen.developer-source`|`365-xquery.xquery`|[Finder AX](365-xquery-ax.txt) / 日志 1182,1186|
|366|`.xsd`|OrangeLen|`local.orangelen.developer-source`|`366-xsd.xsd`|[Finder AX](366-xsd-ax.txt) / 日志 1188,1191|
|367|`.xu`|OrangeLen|`local.orangelen.developer-source`|`367-xu.xu`|[Finder AX](367-xu-ax.txt) / 日志 1194|
|368|`.xul`|OrangeLen|`local.orangelen.developer-source`|`368-xul.xul`|[Finder AX](368-xul-ax.txt) / 日志 1197,1200|
|369|`.zig`|OrangeLen|`local.orangelen.developer-source`|`369-zig.zig`|[Finder AX](369-zig-ax.txt) / 日志 1203|
|370|`.zon`|OrangeLen|`local.orangelen.developer-source`|`370-zon.zon`|[Finder AX](370-zon-ax.txt) / 日志 1206,1209|
|371|`.zshrc`|OrangeLen|`local.orangelen.developer-source`|`371-zshrc.zshrc`|[Finder AX](371-zshrc-ax.txt) / 日志 1212,1215|

## OrangeLen 350 项按类别列出

### 代码与网页（66 项）

`.swift`, `.py`, `.js`, `.tsx`, `.jsx`, `.mjs`, `.cjs`, `.cts`, `.vue`, `.svelte`, `.astro`, `.c`, `.h`, `.cpp`, `.hpp`, `.rs`, `.go`, `.sh`, `.rb`, `.java`, `.kt`, `.css`, `.scss`, `.sass`, `.less`, `.sql`, `.cs`, `.php`, `.dart`, `.lua`, `.scala`, `.ps1`, `.graphql`, `.gql`, `.tf`, `.tfvars`, `.hcl`, `.pyi`, `.pyx`, `.pxd`, `.pxi`, `.cu`, `.cuh`, `.cc`, `.cxx`, `.hh`, `.hxx`, `.ipp`, `.tpp`, `.inl`, `.kts`, `.gradle`, `.groovy`, `.cmake`, `.mk`, `.mdc`, `.http`, `.rest`, `.j2`, `.jinja`, `.jinja2`, `.tmpl`, `.tpl`, `.rst`, `.adoc`, `.asciidoc`

### 文本与配置（9 项）

`.ini`, `.conf`, `.config`, `.properties`, `.plist`, `.yaml`, `.yml`, `.toml`, `.xml`

### 文档与排版（7 项）

`.md`, `.markdown`, `.mdx`, `.tex`, `.typ`, `.ipynb`, `.epub`

### 结构化数据（11 项）

`.json`, `.jsonc`, `.json5`, `.jsonl`, `.ndjson`, `.tsv`, `.sqlite`, `.sqlite3`, `.db`, `.har`, `.sarif`

### 图表与画布（10 项）

`.mmd`, `.mermaid`, `.excalidraw`, `.drawio`, `.canvas`, `.xmind`, `.mm`, `.opml`, `.mmap`, `.gv`

### Skill、MCP 与归档（16 项）

`.skill`, `.mcpb`, `.dxt`, `.n8np`, `.zip`, `.tar`, `.tgz`, `.gz`, `.whl`, `.vsix`, `.7z`, `.rar`, `.xz`, `.bz2`, `.zst`, `.tzst`

### 3D 模型（4 项）

`.obj`, `.stl`, `.gltf`, `.glb`

### 科学数据与模型目录（10 项）

`.parquet`, `.npy`, `.npz`, `.safetensors`, `.gguf`, `.latent`, `.arrow`, `.ipc`, `.feather`, `.onnx`

### 字幕、差异与来源结构（4 项）

`.srt`, `.vtt`, `.xmp`, `.c2pa`

### 更多开发者源码、配置与编译文件（213 项）

`.a3x`, `.acf`, `.ada`, `.ado`, `.applescript`, `.as`, `.ascr`, `.asd`, `.asm`, `.asp`, `.aspx`, `.atl`, `.au3`, `.avt`, `.awk`, `.bas`, `.bashrc`, `.basic`, `.bat`, `.bb`, `.bezel`, `.bib`, `.c++`, `.cfc`, `.cfg`, `.cfm`, `.cfml`, `.class`, `.cli`, `.clj`, `.cljc`, `.cljs`, `.cls`, `.cmd`, `.code-workspace`, `.coffee`, `.command`, `.con`, `.cp`, `.cr`, `.csh`, `.cson`, `.csproj`, `.ctx`, `.d`, `.designspace`, `.do`, `.dockerfile`, `.dtd`, `.dylan`, `.e`, `.ecf`, `.ecore`, `.edn`, `.el`, `.entitlements`, `.env`, `.erb`, `.erl`, `.ex`, `.exs`, `.f`, `.f90`, `.f95`, `.fea`, `.fish`, `.flow`, `.fnc`, `.for`, `.fs`, `.fsx`, `.fxml`, `.gd`, `.gemfile`, `.gleam`, `.gpx`, `.haml`, `.heex`, `.hri`, `.hrl`, `.hs`, `.ily`, `.iml`, `.inf`, `.ino`, `.iss`, `.jav`, `.javascript`, `.jl`, `.jnlp`, `.jscript`, `.jsm`, `.jsp`, `.kml`, `.kmt`, `.ksh`, `.latex`, `.lay`, `.ld`, `.lhs`, `.lisp`, `.loctable`, `.lsp`, `.ltx`, `.ly`, `.m`, `.mak`, `.map`, `.mf`, `.mill`, `.ml`, `.mll`, `.mly`, `.mobileconfig`, `.mpd`, `.mq4`, `.mq5`, `.ms`, `.mvw`, `.mxml`, `.ncx`, `.nf`, `.nim`, `.nix`, `.opf`, `.otio`, `.pas`, `.pck`, `.pddl`, `.pde`, `.ph3`, `.ph4`, `.php3`, `.php4`, `.phtml`, `.pkb`, `.pks`, `.pl`, `.pm`, `.podspec`, `.pom`, `.prc`, `.pro`, `.psd1`, `.psjs`, `.psm1`, `.pub`, `.py3`, `.raml`, `.rbw`, `.rdf`, `.readme`, `.rex`, `.rexx`, `.rhtml`, `.rjs`, `.rkt`, `.robot`, `.s79`, `.sage`, `.sas`, `.sbt`, `.sc`, `.scad`, `.sch`, `.scl`, `.scm`, `.scpt`, `.sequ`, `.sld`, `.sls`, `.smali`, `.sol`, `.sps`, `.sqs`, `.ss`, `.storybard`, `.storyboard`, `.strings`, `.stringsdict`, `.sty`, `.t`, `.tab`, `.tcl`, `.tcsh`, `.texi`, `.tfstate`, `.tpb`, `.tps`, `.trg`, `.ttx`, `.twig`, `.unity`, `.v`, `.vb`, `.vbs`, `.vhd`, `.vhdl`, `.vim`, `.vl`, `.vw`, `.xaml`, `.xcscheme`, `.xib`, `.xm`, `.xq`, `.xquery`, `.xsd`, `.xu`, `.xul`, `.zig`, `.zon`, `.zshrc`

