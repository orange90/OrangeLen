import XCTest
import AppKit
import OrangeLenCore
@testable import OrangeLenUI

@MainActor final class ExtendedArchivePreviewTests: XCTestCase {
    func testArchivesReachMemberReader() async throws {
        _ = NSApplication.shared
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        for (name, member, expected) in [
            ("sample.7z", "README.md", "中文🍊"),
            ("sample-rar4.rar", "test.txt", "test text document"),
            ("sample-rar5.rar", "helloworld.txt", "hello libarchive"),
            ("compressed-rar4.rar", "testdir/test.txt", "test text document"),
            ("sample.tar.xz", "README.md", "中文🍊"),
            ("sample.tar.bz2", "README.md", "中文🍊"),
            ("sample.tar.zst", "README.md", "中文🍊")
        ] {
            let reader = ReaderController(); reader.loadViewIfNeeded()
            let ready = expectation(description: name)
            reader.open(root.appendingPathComponent("Tests/Fixtures/archive-expansion/" + name)) { error in
                XCTAssertNil(error, name); ready.fulfill()
            }
            await fulfillment(of: [ready], timeout: 30)
            let archive = try XCTUnwrap(reader.archiveController, name)
            archive.outline.expandItem(nil, expandChildren: true)
            let row = try XCTUnwrap((0..<archive.outline.numberOfRows).first {
                (archive.outline.item(atRow: $0) as? ArchiveController.Node)?.path == member
            }, name)
            archive.outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            for _ in 0..<250 {
                if archive.reader.source?.text.contains(expected) == true { break }
                try await Task.sleep(nanoseconds: 20_000_000)
            }
            XCTAssertTrue(archive.reader.source?.text.contains(expected) == true, name)
            reader.close()
        }
    }
}
