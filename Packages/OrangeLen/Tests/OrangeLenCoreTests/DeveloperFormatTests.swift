import XCTest
@testable import OrangeLenCore

final class DeveloperFormatTests: XCTestCase {
    func fixture(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/developer-batch1/" + name)
    }
    func testNamedFilesAndSourceAliases() {
        for ext in ["pyi","pyx","pxd","pxi","cu","cuh","cc","cxx","hh","hxx","ipp","tpp","inl","kts","gradle","groovy","cmake","mk","mdc","http","rest","j2","jinja","jinja2","tmpl","tpl","rst","adoc","asciidoc","sarif","dot","gv"] { XCTAssertTrue(ReadableFormat.isText(fixture("sample." + ext)),ext) }
        XCTAssertTrue(ReadableFormat.isNamedText(fixture(".cursorrules")))
    }
    func testJUnitCountsAndStack() throws {
        let value = try XCTUnwrap(DeveloperReports.parse(String(contentsOf: fixture("junit.xml")), name: "junit.xml"))
        XCTAssertEqual(value.rows.count,3); XCTAssertTrue(value.summary.contains("1 failures")); XCTAssertEqual(value.rows[1][0],"failure"); XCTAssertTrue(value.rows[1][4].contains("preview.swift:42"))
    }
    func testSARIFAndOpenAPIYAML() throws {
        let sarif = try XCTUnwrap(DeveloperReports.parse(String(contentsOf: fixture("scan.sarif")), name: "scan.sarif"))
        XCTAssertEqual(sarif.rows[0][3],"42"); XCTAssertTrue(sarif.rows[0][4].contains("🍊"))
        let api = try XCTUnwrap(DeveloperReports.parse(String(contentsOf: fixture("api.yaml")), name: "api.yaml"))
        XCTAssertEqual(api.rows[0][0],"GET"); XCTAssertEqual(api.rows[0][1],"/models")
        XCTAssertNil(try DeveloperReports.parse("{\"runs\":[]}",name:"data.json"))
        XCTAssertNil(try DeveloperReports.parse("<document>plain XML</document>",name:"data.xml"))
    }
    func testReportBudgetsUnsafeXMLAndCancellation() throws {
        XCTAssertThrowsError(try DeveloperReports.parse("<!DOCTYPE testsuite [<!ENTITY a 'x'>]><testsuite><testcase name='&a;'/></testsuite>",name:"junit.xml"))
        XCTAssertThrowsError(try DeveloperReports.parse("openapi: 3.0.0\nx: &a [1]\ny: *a",name:"api.yaml"))
        XCTAssertThrowsError(try DeveloperReports.parse(String(repeating:"x",count:1024*1024+1),name:"x.xml"))
        let token=Cancellation();token.cancel();XCTAssertThrowsError(try DeveloperReports.parse("{}",name:"scan.sarif",cancellation:token))
    }
    func testPackageSummariesAndMembers() throws {
        for (name,expected) in [("orange_demo-1.0-py3-none-any.whl","Requires-Dist: numpy"),("orange-demo.vsix","publisher: fixture")] {
            let archive=try ArchiveDocument.parse(Data(contentsOf:fixture(name)),name:name)
            XCTAssertTrue(try DeveloperPackage.summary(archive,name:name).contains(expected));XCTAssertGreaterThan(archive.entries.count,2)
            XCTAssertThrowsError(try DeveloperPackage.summary(archive,name:name.hasSuffix("whl") ? "wrong.vsix" : "wrong.whl"))
        }
    }
    func testONNXInputsNodesAndMalformedWire() throws {
        let data=try Data(contentsOf:fixture("model.onnx")),value=try ONNXDocument.parse(data)
        XCTAssertTrue(value.summary.contains("1 nodes"));XCTAssertTrue(value.rows.contains { $0[0]=="Input" && $0[3]=="batch × 3" });XCTAssertTrue(value.rows.contains { $0[2]=="Relu" })
        XCTAssertEqual(try ONNXDocument.load(fixture("model.onnx"),root:nil).rows,value.rows)
        XCTAssertThrowsError(try ONNXDocument.parse(Data([8,255,255])))
        XCTAssertThrowsError(try ONNXDocument.parse(Data([0])))
        XCTAssertThrowsError(try ONNXDocument.parse(Data([8,1,58,255,255,255,255,127])))
        let token=Cancellation();token.cancel();XCTAssertThrowsError(try ONNXDocument.parse(data,cancellation:token))
    }
    func testONNXLargeSparseWeightsAreSkipped() throws {
        func varint(_ n: UInt64) -> Data { var n=n,result=Data();while n>127 {result.append(UInt8(n&127)|128);n >>= 7};result.append(UInt8(n));return result }
        func message(_ field:UInt64,_ length:UInt64)->Data {varint(field<<3|2)+varint(length)}
        let bytes:UInt64=256*1024*1024
        let tensorHeader=Data([16,1])+message(9,bytes), graphHeader=message(5,UInt64(tensorHeader.count)+bytes)
        let header=Data([8,9])+message(7,UInt64(graphHeader.count+tensorHeader.count)+bytes)+graphHeader+tensorHeader
        let url=FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString+".onnx")
        defer {try? FileManager.default.removeItem(at:url)}
        try header.write(to:url);let handle=try FileHandle(forWritingTo:url);try handle.truncate(atOffset:UInt64(header.count)+bytes);try handle.close()
        let result=try ONNXDocument.load(url,root:nil);XCTAssertTrue(result.summary.contains("1 initializers"));XCTAssertTrue(result.text.contains("payload skipped"))
    }
}
