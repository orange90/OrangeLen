import XCTest
@testable import OrangeLenCore

final class XMindTests: XCTestCase {
    func data(_ name: String) throws -> Data {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: root.appendingPathComponent("Tests/Fixtures/advanced-outputs/\(name).xmind"))
    }
    func testModernSheetsTopicsAndRelationships() throws {
        let doc = try XMindDocument.parse(data("modern"))
        XCTAssertEqual(doc.pages.map(\.title), ["计划", "第二页"])
        XCTAssertEqual(doc.pages[0].boxes.count, 5)
        XCTAssertEqual(doc.pages[0].edges.count, 4)
        XCTAssertFalse(doc.pages[0].edges.contains { $0.to == "float" })
        XCTAssertEqual(doc.pages[1].boxes[0].text, "中文与 emoji 🍊")
        let boxes = doc.pages[0].boxes
        XCTAssertLessThan(boxes[0].x, boxes[1].x)
        XCTAssertEqual(Set(boxes.map { "\($0.x),\($0.y)" }).count, boxes.count)
    }
    func testLegacyXML() throws {
        let doc = try XMindDocument.parse(data("legacy"))
        XCTAssertEqual(doc.pages[0].title, "旧版")
        XCTAssertEqual(doc.pages[0].boxes.map(\.text), ["中心主题", "分支"])
        XCTAssertEqual(doc.pages[0].edges.count, 2)
    }
    func testInvalidAndCancelledWorkbooks() throws {
        for name in ["invalid", "unsafe", "missing"] { XCTAssertThrowsError(try XMindDocument.parse(data(name)), name) }
        XCTAssertThrowsError(try XMindDocument.parse(Data("not zip".utf8)))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try XMindDocument.parse(data("modern"), cancellation: token))
        XCTAssertEqual(PreviewCategory.detect(URL(fileURLWithPath: "/tmp/test.XMIND")), .drawings)
    }
}
