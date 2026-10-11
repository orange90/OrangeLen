import XCTest
import AppKit
@testable import OrangeLenUI
import OrangeLenCore

@MainActor final class AIOutputPreviewTests: XCTestCase {
    func fixture(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/ai-outputs/" + name)
    }
    func open(_ reader: ReaderController, _ name: String) async {
        let loaded = expectation(description: name)
        reader.open(fixture(name)) { error in XCTAssertNil(error); loaded.fulfill() }
        await fulfillment(of: [loaded], timeout: 15)
    }
    func settle(_ check: @escaping () -> Bool) async throws {
        for _ in 0..<150 { if check() { return }; try await Task.sleep(nanoseconds: 30_000_000) }
        XCTFail("Preview did not settle")
    }
    func testMermaidCanvasSourceAndStaleSwitch() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        await open(reader, "diagram.mmd")
        XCTAssertNotNil(reader.canvasImage); XCTAssertTrue(reader.currentContent === reader.picture)
        XCTAssertEqual(reader.canvasLabel, "Mermaid")
        reader.mode.selectedSegment = 1; reader.present()
        XCTAssertTrue(reader.text.string.contains("flowchart LR")); XCTAssertTrue(reader.currentContent === reader.scroll)
        reader.open(fixture("diagram.mermaid")) { _ in }
        await open(reader, "captions.srt")
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertNil(reader.canvasImage); XCTAssertTrue(reader.currentContent === reader.table.view)
    }
    func testSubtitleTableSearchAndExactSource() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        await open(reader, "captions.srt")
        XCTAssertEqual(reader.tableData?.rows.count, 3); XCTAssertTrue(reader.currentContent === reader.table.view)
        reader.table.filter.stringValue = "生成参数"; reader.table.rebuildOrder()
        XCTAssertEqual(reader.table.rowOrder.count, 1)
        reader.mode.selectedSegment = 1; reader.present()
        XCTAssertEqual(reader.text.string, try String(contentsOf: fixture("captions.srt"), encoding: .utf8))
        await open(reader, "captions.vtt")
        XCTAssertEqual(reader.tableData?.rows.count, 3)
        XCTAssertEqual(reader.table.table.tableColumns[2].width, 420)
        reader.table.table.tableColumns[2].width = 100
        XCTAssertGreaterThan(reader.table.tableView(reader.table.table, heightOfRow: 0), 45)
    }
    func testMCPDefaultSummaryAndCodeSelection() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        await open(reader, "sample.mcpb")
        let archive = try XCTUnwrap(reader.archiveController)
        try await settle { archive.reader.text.string.contains("preview-example") }
        XCTAssertFalse(archive.summaryButton.isHidden)
        let row = try XCTUnwrap((0..<archive.outline.numberOfRows).first { (archive.outline.item(atRow: $0) as? ArchiveController.Node)?.path == "server/index.js" })
        archive.outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        try await settle { archive.reader.text.string.contains("console.log") }
        archive.showBundleSummary(); try await settle { archive.reader.text.string.contains("user_config") }
        await open(reader, "sample.dxt")
        try await settle { reader.archiveController?.reader.text.string.contains("preview-example") == true }
    }
    func testImageMetadataPanelClearsOnSwitchAndClose() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 800), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.contentViewController = reader
        defer { window.contentViewController = nil }
        for file in ["generation.png", "generation.webp"] {
            await open(reader, file)
            XCTAssertNotNil(reader.picture.image); XCTAssertNotNil(reader.imageDetails)
            XCTAssertTrue(reader.currentContent === reader.imageDetails)
            for width in [1100.0, 520.0, 1100.0] {
                window.setContentSize(NSSize(width: width, height: 700))
                reader.view.layoutSubtreeIfNeeded()
                let panel = try XCTUnwrap(reader.imageDetails?.subviews.first)
                let details = try XCTUnwrap(panel.subviews.first { $0 is NSScrollView })
                XCTAssertGreaterThan(reader.picture.frame.width, 150)
                XCTAssertGreaterThan(reader.picture.frame.height, 150)
                XCTAssertGreaterThan(details.frame.width, 150)
                XCTAssertGreaterThan(details.frame.height, 150)
                XCTAssertFalse(reader.picture.frame.intersects(details.frame))
                XCTAssertTrue(panel.bounds.contains(reader.picture.frame))
                XCTAssertTrue(panel.bounds.contains(details.frame))
            }
        }
        await open(reader, "captions.srt")
        XCTAssertNil(reader.imageDetails); XCTAssertTrue(reader.currentContent === reader.table.view)
        reader.close(); XCTAssertNil(reader.imageDetails)
    }
    func testMalformedMermaidAndMetadataRetainUsableSourceAndImage() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mmd")
        defer { try? FileManager.default.removeItem(at: file) }
        try "bad syntax {{".write(to: file, atomically: true, encoding: .utf8)
        let ready = expectation(description: "fallback")
        reader.open(file) { error in XCTAssertNil(error); ready.fulfill() }
        await fulfillment(of: [ready], timeout: 15)
        XCTAssertNil(reader.canvasImage); XCTAssertEqual(reader.text.string, "bad syntax {{")
        var data = try Data(contentsOf: fixture("generation.png"))
        let range = try XCTUnwrap(data.range(of: Data("parameters".utf8))); data[range.lowerBound + 1] ^= 1
        let image = try ImagePreview.decode(data, cancellation: .init())
        XCTAssertGreaterThan(image.width, 0); XCTAssertFalse(image.metadata.warnings.isEmpty)
    }
}
