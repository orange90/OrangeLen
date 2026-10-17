import XCTest
@testable import OrangeLenCore

final class MindManagerTests: XCTestCase {
    func testArchiveAndTopics() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let doc = try MindManagerDocument.parse(Data(contentsOf: root.appendingPathComponent("Tests/Fixtures/advanced-outputs/project.mmap")))
        XCTAssertEqual(doc.pages[0].boxes.count, 7)
        XCTAssertEqual(doc.pages[0].edges.count, 5)
        XCTAssertEqual(doc.pages[0].boxes[0].text, "MindManager 项目计划 🍊")
        XCTAssertEqual(doc.pages[0].boxes.last?.text, "待讨论事项")
    }
    func testDefaultNamespaceAndMissingIDs() throws {
        let doc = try MindManagerDocument.parseXML("<Map xmlns='http://schemas.mindjet.com/MindManager/Application/2003'><OneTopic><Topic><Text PlainText='A &amp; B'/><SubTopics><Topic><Text PlainText='子主题'/></Topic></SubTopics></Topic></OneTopic></Map>")
        XCTAssertEqual(doc.pages[0].boxes.map(\.text), ["A & B", "子主题"])
        XCTAssertEqual(doc.pages[0].edges.count, 1)
    }
    func testInvalidLimitsAndCancellation() throws {
        for xml in ["<Map/>", "<Other/>", "<!DOCTYPE Map><Map/>", "<Map><OneTopic><Topic OId='a'><SubTopics><Topic OId='a'/></SubTopics></Topic></OneTopic></Map>", "<Map><OneTopic>" + String(repeating: "<Topic/>", count: 2001) + "</OneTopic></Map>", "<Map><OneTopic>" + String(repeating: "<Topic><SubTopics>", count: 55) + String(repeating: "</SubTopics></Topic>", count: 55) + "</OneTopic></Map>"] { XCTAssertThrowsError(try MindManagerDocument.parseXML(xml)) }
        XCTAssertThrowsError(try MindManagerDocument.parse(Data("bad ZIP".utf8)))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try MindManagerDocument.parseXML("<Map/>", cancellation: token))
    }
}
