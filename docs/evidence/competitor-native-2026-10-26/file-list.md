# 两款插件的 Finder 空格逐项对照

归属结合真实入口日志与界面判断。Web2 也能显示第三方生成的 HTML，不能单凭显示 bundle 判断生成者。

|插件|后缀|真实入口事件|显示 bundle|最终界面|证据|
|---|---|---|---|---|---|
|pique|`.vpptoken`|2|`com.apple.qldisplay.Extensions`|Pique native preview extension|[AX](pique-00-vpptoken-ax.txt) / [截图](screenshots/pique-00-vpptoken.png)|
|dotviewer|`.mud`|15|`com.apple.qldisplay.Web2`|dotViewer native preview extension|[AX](dotviewer-00-mud-ax.txt) / [截图](screenshots/dotviewer-00-mud.png)|
|pique|`.ts`|无|`com.apple.qldisplay.Movie`|system metadata only|[AX](pique-01-ts-ax.txt) / [截图](screenshots/pique-01-ts.png)|
|pique|`.mts`|无|`com.apple.qldisplay.Movie`|system metadata only|[AX](pique-02-mts-ax.txt) / [截图](screenshots/pique-02-mts.png)|
|pique|`.dot`|无|`com.apple.qldisplay.PDFKit`|system metadata only|[AX](pique-03-dot-ax.txt) / [截图](screenshots/pique-03-dot.png)|
|pique|`.html`|无|`com.apple.qldisplay.Web2`|system content preview|[AX](pique-08-html-ax.txt) / [截图](screenshots/pique-08-html.png)|
|pique|`.htm`|无|`com.apple.qldisplay.Web2`|system content preview|[AX](pique-09-htm-ax.txt) / [截图](screenshots/pique-09-htm.png)|
|pique|`.xhtml`|无|`com.apple.qldisplay.Web2`|system content preview|[AX](pique-10-xhtml-ax.txt) / [截图](screenshots/pique-10-xhtml.png)|
|pique|`.txt`|无|`com.apple.qldisplay.Text`|system content preview|[AX](pique-13-txt-ax.txt) / [截图](screenshots/pique-13-txt.png)|
|pique|`.pdf`|无|`com.apple.qldisplay.PDFKit`|system content preview|[AX](pique-15-pdf-ax.txt) / [截图](screenshots/pique-15-pdf.png)|
|pique|`.csv`|无|`com.apple.qldisplay.Web2`|system content preview|[AX](pique-16-csv-ax.txt) / [截图](screenshots/pique-16-csv.png)|
|pique|`.svg`|无|`com.apple.qldisplay.Web2`|system content preview|[AX](pique-17-svg-ax.txt) / [截图](screenshots/pique-17-svg.png)|
|pique|`.text`|无|`com.apple.qldisplay.Text`|system content preview|[AX](pique-20-text-ax.txt) / [截图](screenshots/pique-20-text.png)|
|dotviewer|`.ts`|无|`com.apple.qldisplay.Movie`|system metadata only|[AX](dotviewer-01-ts-ax.txt) / [截图](screenshots/dotviewer-01-ts.png)|
|dotviewer|`.mts`|无|`com.apple.qldisplay.Movie`|system metadata only|[AX](dotviewer-02-mts-ax.txt) / [截图](screenshots/dotviewer-02-mts.png)|
|dotviewer|`.dot`|无|`com.apple.qldisplay.PDFKit`|system metadata only|[AX](dotviewer-03-dot-ax.txt) / [截图](screenshots/dotviewer-03-dot.png)|
|dotviewer|`.html`|无|`com.apple.qldisplay.Web2`|system content preview|[AX](dotviewer-08-html-ax.txt) / [截图](screenshots/dotviewer-08-html.png)|
|dotviewer|`.htm`|无|`com.apple.qldisplay.Web2`|system content preview|[AX](dotviewer-09-htm-ax.txt) / [截图](screenshots/dotviewer-09-htm.png)|
|dotviewer|`.xhtml`|无|`com.apple.qldisplay.Web2`|system content preview|[AX](dotviewer-10-xhtml-ax.txt) / [截图](screenshots/dotviewer-10-xhtml.png)|
|dotviewer|`.txt`|无|`com.apple.qldisplay.Text`|system content preview|[AX](dotviewer-13-txt-ax.txt) / [截图](screenshots/dotviewer-13-txt.png)|
|dotviewer|`.pdf`|无|`com.apple.qldisplay.PDFKit`|system content preview|[AX](dotviewer-15-pdf-ax.txt) / [截图](screenshots/dotviewer-15-pdf.png)|
|dotviewer|`.csv`|无|`com.apple.qldisplay.Web2`|system content preview|[AX](dotviewer-16-csv-ax.txt) / [截图](screenshots/dotviewer-16-csv.png)|
|dotviewer|`.svg`|无|`com.apple.qldisplay.Web2`|system content preview|[AX](dotviewer-17-svg-ax.txt) / [截图](screenshots/dotviewer-17-svg.png)|
|dotviewer|`.text`|无|`com.apple.qldisplay.Text`|system content preview|[AX](dotviewer-20-text-ax.txt) / [截图](screenshots/dotviewer-20-text.png)|
