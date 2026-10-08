import XCTest
import AppKit
@testable import OrangeLenUI
import OrangeLenCore

@MainActor final class FolderOverviewTests: XCTestCase {
    func testDirectoryChildrenLoadWhileParsingAndStatisticsAreOccupied() async throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("hello".utf8).write(to: root.appendingPathComponent("readme.txt"))
        let gate = DispatchSemaphore(value: 0), started = DispatchSemaphore(value: 0)
        let finished = expectation(description: "background jobs released")
        finished.expectedFulfillmentCount = 3
        for queue in [PreviewWorkQueue.parsing, PreviewWorkQueue.parsing, PreviewWorkQueue.directories] {
            queue.submit(cancellation: Cancellation(), work: {
                started.signal(); _ = gate.wait(timeout: .now() + 10)
            }, completion: { _ in finished.fulfill() })
        }
        defer { for _ in 0..<3 { gate.signal() } }
        for _ in 0..<3 { XCTAssertEqual(started.wait(timeout: .now() + 2), .success) }
        let controller = FolderController(); controller.open(root)
        defer { controller.cancel() }
        for _ in 0..<100 where controller.root?.loaded != true { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertEqual(controller.root?.loaded, true)
        XCTAssertEqual(controller.root?.children.map { $0.url.lastPathComponent }, ["readme.txt"])
        XCTAssertNil(controller.lastSummary)
        for _ in 0..<3 { gate.signal() }
        await fulfillment(of: [finished], timeout: 3)
    }

    func testOverviewNavigationKeepsLiveSummaryOutOfFileContent() async throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("README.md")
        try Data("# Example\n\nActual README content".utf8).write(to: file)
        let reader = ReaderController(); reader.loadViewIfNeeded()
        reader.open(root) { XCTAssertNil($0) }
        defer { reader.close() }
        for _ in 0..<100 where reader.folderOverview.readmeText.stringValue.isEmpty { try await Task.sleep(for: .milliseconds(20)) }
        XCTAssertTrue(reader.currentContent === reader.folderOverview)
        XCTAssertEqual(reader.folderOverview.count.stringValue, "1")
        XCTAssertTrue(reader.folderOverview.readmeText.stringValue.contains("Actual README content"))
        XCTAssertTrue(reader.toolbarViews[1].isHidden)
        XCTAssertTrue(reader.folderInfo.stringValue.isEmpty)
        let ready = expectation(description: "readme opens")
        reader.loadFile(file) { error in XCTAssertNil(error); ready.fulfill() }
        await fulfillment(of: [ready], timeout: 5)
        XCTAssertFalse(reader.currentContent === reader.folderOverview)
        XCTAssertFalse(reader.toolbarViews[1].isHidden)
        reader.folder.summarize(root)
        reader.returnToFolderOverview()
        XCTAssertTrue(reader.currentContent === reader.folderOverview)
        XCTAssertNil(reader.currentURL)
        reader.view.setFrameSize(NSSize(width: 600, height: 500)); reader.view.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(reader.folderOverview.scroll.documentView!.bounds.height, 0)
        XCTAssertFalse(reader.folderOverview.hasAmbiguousLayout)
        XCTAssertEqual(reader.folderOverview.scroll.documentView!.bounds.width, reader.folderOverview.scroll.contentSize.width, accuracy: 1)
    }
}
