import XCTest
@testable import OrangeLenCore

final class DeveloperFormatsTests: XCTestCase {
    func fixture(_ name: String) -> URL {
        URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/developer-formats/"+name)
    }
    func testConfigurationsAndSourceAreReadableWithoutSystemTypeFallback() {
        for name in [".env.local",".env.production",".editorconfig",".dockerignore",".npmrc",".prettierrc","Dockerfile.dev","Containerfile.test","Justfile","Cargo.lock","yarn.lock","poetry.lock","go.mod","go.sum","Component.vue","Component.svelte","Page.astro","module.mjs","module.cjs","module.mts","module.cts","style.scss","style.less","Main.cs","schema.proto","schema.graphql","main.tf"] {
            XCTAssertTrue(ReadableFormat.isText(URL(fileURLWithPath:name)),name)
        }
        XCTAssertFalse(ReadableFormat.isText(URL(fileURLWithPath:"binary.wasm")))
        XCTAssertEqual(PreviewFormat.detect(URL(fileURLWithPath:"Dockerfile.dev")),.code)
        XCTAssertEqual(PreviewFormat.detect(URL(fileURLWithPath:".prettierrc.json")),.json)
        XCTAssertEqual(JSONDialect.detect(URL(fileURLWithPath:"/project/.vscode/settings.json")),.jsonc)
        XCTAssertEqual(JSONDialect.detect(URL(fileURLWithPath:"tsconfig.build.json")),.jsonc)
        XCTAssertEqual(JSONDialect.detect(URL(fileURLWithPath:"settings.json")),.strict)
    }
    func testJSONCCommentsTrailingCommasAndSourceExactValues() throws {
        let source = try String(contentsOf:fixture("settings.jsonc"),encoding:.utf8)
        let tree = try JSONParser.parse(source,dialect:.jsonc)
        let ns = source as NSString
        XCTAssertEqual(tree.root.children.map(\.name),["url","editor.fontSize","large","items"])
        XCTAssertEqual(ns.substring(with:tree.root.children[2].range),"9007199254740993")
        XCTAssertEqual(ns.substring(with:tree.root.children[0].range),"\"https://example.invalid/a//b\"")
        XCTAssertThrowsError(try JSONParser.parse(source))
        for invalid in ["{/*missing}","{\"x\":1,,}","[1,,]","{'key':1}","{key:1}","{\"x\":NaN}"] {
            XCTAssertThrowsError(try JSONParser.parse(invalid,dialect:.jsonc),invalid)
        }
    }
    func testJSON5GrammarKeepsOriginalRangesAndDecodedPaths() throws {
        let source = #"{\u006eame:'中文\x21', name:'duplicate', 中文: '\uD83C\uDFBC', $value: +.5, _hex:-0xFf, list:[NaN,+Infinity,-Infinity,1.,1.e+2,],}"#
        let tree = try JSONParser.parse(source,dialect:.json5)
        XCTAssertTrue(tree.duplicateKeys)
        XCTAssertEqual(tree.root.children.map(\.name),["name","name","中文","$value","_hex","list"])
        XCTAssertEqual(tree.root.children[0].path,"$[\"name\"]")
        XCTAssertEqual((source as NSString).substring(with:tree.root.children[4].range),"-0xFf")
        XCTAssertEqual(tree.root.children.last?.children.count,5)
        _ = try JSONParser.parse("{a:'first\\\r\nsecond', b:'\\v\\0', c:'\\A'}",dialect:.json5)
        _ = try JSONParser.parse("\u{00A0}{a:1}\u{FEFF}",dialect:.json5)
        for invalid in ["{a:01}","{a:0x}","{a:.}","{a:'\\1'}","{a:'\\01'}","{a:'\\xzz'}","{a:'unescaped\nline'}","{1key:0}", #"{a\u000a:1}"#,"{a-b:1}","{\u{0301}a:1}","{a:1,,}","{a:(function(){})()}","{a:undefined}"] {
            XCTAssertThrowsError(try JSONParser.parse(invalid,dialect:.json5),invalid)
        }
    }
    func testJSONDialectsRespectLimitsAndCancellation() throws {
        var limits = PreviewLimits(); limits.structureDepth = 2
        XCTAssertThrowsError(try JSONParser.parse("[[[[]]]]",dialect:.json5,limits:limits))
        limits.structureDepth = 64; limits.structureNodes = 2
        XCTAssertThrowsError(try JSONParser.parse("[1,2]",dialect:.jsonc,limits:limits))
        limits.fileBytes = 3
        XCTAssertThrowsError(try JSONParser.parse("[123]",dialect:.json5,limits:limits))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try JSONParser.parse("/*comment*/ {}",dialect:.jsonc,cancellation:token))
        for invalid in ["{\"a\":1,}","[1,]","{\"a\":+1}","{\"a\":0x10}","{\"a\":'x'}","/*c*/{}","{\"a\":\"\\x41\"}"] { XCTAssertThrowsError(try JSONParser.parse(invalid),invalid) }
    }
    func testGzipStreamsAreNotMistakenForTar() throws {
        let stream = try GzipDocument.parse(Data(contentsOf:fixture("app.log.gz")),name:"app.log.gz")
        XCTAssertEqual(stream.name,"app.log"); XCTAssertTrue(stream.text.contains("中文日志"))
        XCTAssertTrue(GzipDocument.isPlainStream(fixture("app.log.gz")))
        XCTAssertFalse(GzipDocument.isPlainStream(fixture("archive.tar.gz")))
        XCTAssertFalse(GzipDocument.isPlainStream(fixture("archive.tgz")))
        let data = try Data(contentsOf:fixture("table.csv.gz"))
        let csv = try GzipDocument.parse(data,name:"table.csv.gz")
        XCTAssertEqual(try CSVParser.parse(csv.text).rows.count,3)
        XCTAssertThrowsError(try GzipDocument.parse(data,name:"binary.wasm.gz"))
        XCTAssertThrowsError(try GzipDocument.parse(data.dropLast(),name:"table.csv.gz"))
        var corrupt = data; corrupt[corrupt.count - 5] ^= 0xff
        XCTAssertThrowsError(try GzipDocument.parse(corrupt,name:"table.csv.gz"))
        XCTAssertThrowsError(try GzipDocument.parse(data+data,name:"table.csv.gz"))
        XCTAssertThrowsError(try GzipDocument.parse(Data(contentsOf:fixture("binary.log.gz")),name:"binary.log.gz"))
        XCTAssertThrowsError(try GzipDocument.parse(Data(contentsOf:fixture("bomb.log.gz")),name:"bomb.log.gz"))
        var limits = PreviewLimits(); limits.fileBytes = 4
        XCTAssertThrowsError(try GzipDocument.parse(data,name:"table.csv.gz",limits:limits))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try GzipDocument.parse(data,name:"table.csv.gz",cancellation:token))
    }
    func testSVGAllowlistRetainsShapesAndRemovesActiveContent() throws {
        let good = try SVGDocument.parse(String(contentsOf:fixture("icon.svg"),encoding:.utf8))
        XCTAssertEqual(good.omitted,0)
        XCTAssertTrue(good.xml.contains("linearGradient")); XCTAssertTrue(good.xml.contains("fill=\"#333\"")); XCTAssertTrue(good.xml.contains("SVG 中文预览"))
        let unsafe = try SVGDocument.parse(String(contentsOf:fixture("unsafe.svg"),encoding:.utf8))
        for denied in ["onload","<script","foreignObject","https://","<image","forbidden"] { XCTAssertFalse(unsafe.xml.contains(denied),denied) }
        XCTAssertGreaterThan(unsafe.omitted,0); XCTAssertTrue(unsafe.xml.contains("<rect"))
        let other = try SVGDocument.parse(##"<svg xmlns="http://www.w3.org/2000/svg"><style>@import 'https://example.invalid'</style><use href="#loop"/><rect style="fill:red;stroke:url(https://example.invalid);filter:url(#x)" onclick="alert(1)"/><g xmlns="http://example.invalid"><path d="M0 0"/></g><text><![CDATA[<script>literal</script>]]></text></svg>"##)
        XCTAssertFalse(other.xml.contains("<use")); XCTAssertFalse(other.xml.contains("example.invalid")); XCTAssertFalse(other.xml.contains("onclick"))
        XCTAssertTrue(other.xml.contains("&lt;script&gt;literal")); XCTAssertTrue(other.xml.contains("fill=\"red\""))
        for bad in ["<html/>","<svg>","<!DOCTYPE svg [<!ENTITY x 'boom'>]><svg>&x;</svg>","<!DOCTYPE svg SYSTEM 'file:///etc/passwd'><svg/>"] { XCTAssertThrowsError(try SVGDocument.parse(bad)) }
        var limits = PreviewLimits(); limits.structureDepth = 1
        XCTAssertThrowsError(try SVGDocument.parse("<svg><g/></svg>",limits:limits))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try SVGDocument.parse("<svg/>",cancellation:token))
    }
}
