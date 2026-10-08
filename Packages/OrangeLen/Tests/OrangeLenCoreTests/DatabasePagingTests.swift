import XCTest
@testable import OrangeLenCore

final class DatabasePagingTests: XCTestCase {
    func database() throws -> DatabaseDocument {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try DatabaseDocument(data: Data(contentsOf: root.appendingPathComponent("Tests/Fixtures/improvements/paged.sqlite")))
    }
    func testPagesReachEveryRowWithoutDuplicatesAndExposeSchema() throws {
        let db = try database()
        let first = try db.page("records"), second = try db.page("records", offset: 500), last = try db.page("records", offset: 1000)
        XCTAssertEqual(first.rows.count, 500); XCTAssertTrue(first.hasNext)
        XCTAssertEqual(second.rows.count, 500); XCTAssertTrue(second.hasNext)
        XCTAssertEqual(last.rows.count, 2); XCTAssertFalse(last.hasNext)
        let ids = (first.rows + second.rows + last.rows).map { $0[0] }
        XCTAssertEqual(Set(ids).count, 1002); XCTAssertEqual(ids.first, "1"); XCTAssertEqual(ids.last, "1002")
        XCTAssertEqual(first.columns[0].primaryKey, 1); XCTAssertEqual(first.columns[1].declaredType, "INTEGER"); XCTAssertTrue(first.columns[1].notNull)
        XCTAssertEqual(first.rows[0][3], "[BLOB 2 bytes]")
    }
    func testNumericSortIsGlobalAcrossPagesAndDirectionWorks() throws {
        let db = try database()
        let first = try db.page("records", sortColumn: 1)
        let second = try db.page("records", offset: 500, sortColumn: 1)
        XCTAssertEqual(first.rows.first?[1], "0"); XCTAssertEqual(first.rows.last?[1], "499")
        XCTAssertEqual(second.rows.first?[1], "500")
        let descending = try db.page("records", sortColumn: 1, ascending: false)
        XCTAssertEqual(descending.rows.first?[1], "1001")
    }
    func testQuotedIdentifiersWithoutRowIDAndRejectedInputs() throws {
        let db = try database()
        XCTAssertEqual(try db.page("quoted\" table").rows.map { $0[0] }, ["1", "2"])
        XCTAssertThrowsError(try db.page("records; DROP TABLE records"))
        XCTAssertThrowsError(try db.page("records", offset: -1))
        XCTAssertThrowsError(try db.page("records", sortColumn: 4))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try db.page("records", cancellation: token))
    }
}
