import XCTest
@testable import OrangeLenCore

final class ImageDirectoryGrantTests: XCTestCase {
    func testTransferIsDocumentRevisionBoundExpiresAndOnlyOwnerCanRevoke() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let document = root.appendingPathComponent("test.md")
        try Data("![image](image.png)".utf8).write(to: document)
        let store = ImageDirectoryGrant(directory: root.appendingPathComponent("ipc"), group: nil)
        let owner = UUID(), now = Date()
        try store.publish(root, document: document, revision: "a", owner: owner, now: now)
        let grant = try XCTUnwrap(store.resolve(document: document, revision: "a", now: now))
        XCTAssertEqual(grant.owner, owner); XCTAssertEqual(grant.directory.standardizedFileURL, root.standardizedFileURL)
        XCTAssertNil(store.resolve(document: document, revision: "b", now: now))
        XCTAssertNil(store.resolve(document: root.appendingPathComponent("other.md"), revision: "a", now: now))
        XCTAssertNil(store.resolve(document: document, revision: "a", now: now.addingTimeInterval(31)))
        store.remove(document: document, owner: UUID())
        XCTAssertNotNil(store.resolve(document: document, revision: "a", now: now))
        store.remove(document: document, owner: owner)
        XCTAssertNil(store.resolve(document: document, revision: "a", now: now))
    }
    func testGrantCannotExtendAboveDocumentDirectory() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let child = root.appendingPathComponent("child")
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let document = child.appendingPathComponent("test.md")
        try Data().write(to: document)
        let store = ImageDirectoryGrant(directory: root.appendingPathComponent("ipc"), group: nil)
        try store.publish(root, document: document, revision: "a", owner: UUID())
        XCTAssertNil(store.resolve(document: document, revision: "a"))
    }
}
