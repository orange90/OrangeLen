import XCTest
@testable import OrangeLenCore

final class OutlineDiagramTests: XCTestCase {
    func parse(_ source: String, _ ext: String = "mm") throws -> DiagramDocument? { try DiagramDocument.parseIfKnown(source, name: "test." + ext) }
    func testFreeMindRichTitleAndLinks() throws {
        let doc = try XCTUnwrap(parse("<map><node ID='r' TEXT='根'><node ID='a'><richcontent TYPE='NODE'><html><body><p>前<b>中</b>后</p></body></html></richcontent></node><arrowlink DESTINATION='a'/></node></map>"))
        XCTAssertEqual(doc.pages[0].boxes.map(\.text), ["根", "前中后"])
        XCTAssertEqual(doc.pages[0].edges.count, 2)
    }
    func testOPMLForestAndEscapedText() throws {
        let doc = try XCTUnwrap(parse("<opml version='2.0'><head><title>计划</title></head><body><outline text='A &amp; B'><outline text='🍊' xmlUrl='https://example.invalid'/></outline><outline text='C'/></body></opml>", "opml"))
        XCTAssertEqual(doc.pages[0].title, "计划")
        XCTAssertEqual(doc.pages[0].boxes.map(\.text), ["A & B", "🍊", "C"])
        XCTAssertEqual(doc.pages[0].edges.count, 1)
        XCTAssertLessThan(doc.pages[0].boxes[0].y, doc.pages[0].boxes[2].y)
    }
    func testInvalidAndLimits() throws {
        XCTAssertNil(try parse("#import <Foundation/Foundation.h>\nint main() {}"))
        for xml in ["<map/>", "<map><node ID='a'><node ID='a'/></node></map>", "<!DOCTYPE map><map><node/></map>", "<map><node>", "<map>" + String(repeating: "<node>", count: 55) + String(repeating: "</node>", count: 55) + "</map>", "<map><node>" + String(repeating: "<node/>", count: 2000) + "</node></map>"] { XCTAssertThrowsError(try parse(xml)) }
        XCTAssertThrowsError(try parse("<opml><body><outline/></body></opml>", "opml"))
        XCTAssertThrowsError(try parse("<opml/>", "opml"))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try DiagramDocument.parseIfKnown("<map><node/></map>", name: "test.mm", cancellation: token))
    }
}
