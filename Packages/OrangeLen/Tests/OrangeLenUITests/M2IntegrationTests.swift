import XCTest
import AppKit
@testable import OrangeLenUI
import OrangeLenCore

@MainActor final class M2IntegrationTests: XCTestCase {
    func fixture(_ name: String) -> URL {
        URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/m2/"+name)
    }
    func waitUntil(_ condition: @escaping () -> Bool) async throws {
        for _ in 0..<200 { if condition() { return }; try await Task.sleep(nanoseconds:20_000_000) }
        XCTFail("Reader did not reach expected visible state")
    }
    func testEPUBAndArchiveUseSharedReaderAndRealImages() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded()
        let ready = expectation(description:"EPUB")
        reader.open(fixture("sample.epub")) { error in XCTAssertNil(error); ready.fulfill() }
        await fulfillment(of:[ready],timeout:10)
        let collection = try XCTUnwrap(reader.collection)
        try await waitUntil { collection.reader.source?.text.contains("中文阅读") == true }
        XCTAssertFalse(collection.reader.source!.text.contains("shouldNeverExecute")); XCTAssertEqual(collection.reader.markdownAssets.images.count,1)
        XCTAssertTrue(collection.reader.virtualDocument); XCTAssertTrue(collection.reader.remoteBar.isHidden)
        collection.list.selectRowIndexes(IndexSet(integer:1),byExtendingSelection:false)
        try await waitUntil { collection.reader.source?.text.contains("另一章节") == true }
        XCTAssertFalse(collection.reader.text.string.contains("中文阅读"))
        reader.close()
    }
    func testContainerLateSelectionCannotReplaceLatestText() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded()
        let ready = expectation(description:"JSONL")
        reader.open(fixture("records.jsonl")) { error in XCTAssertNil(error); ready.fulfill() }
        await fulfillment(of:[ready],timeout:10)
        let collection = try XCTUnwrap(reader.collection)
        collection.list.selectRowIndexes(IndexSet(integer:1),byExtendingSelection:false)
        collection.list.selectRowIndexes(IndexSet(integer:2),byExtendingSelection:false)
        try await waitUntil { collection.reader.source?.text == "{\"value\":2}" }
        XCTAssertTrue(collection.reader.parseWarning.isEmpty)
        reader.close()
    }
    func testUnsupportedBinaryAndNarrowControlsRemainReachable() async throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:root) }
        let binary = root.appendingPathComponent("fixture.unknownbinary"); try Data([0,1,2,3]).write(to:binary)
        let reader = ReaderController(); reader.loadViewIfNeeded()
        let ready = expectation(description:"unsupported")
        reader.open(binary) { error in XCTAssertNil(error); ready.fulfill() }
        await fulfillment(of:[ready],timeout:10)
        XCTAssertTrue(reader.text.string.contains(L10n.text("暂不支持此格式：\(binary.pathExtension)\n\(ByteCountFormatter.string(fromByteCount: 4, countStyle: .file))\n可在“更多操作”中用默认应用打开或在 Finder 中显示。\n预览不会执行此文件或强制二进制解码。"))); XCTAssertNil(reader.source)
        reader.view.setFrameSize(NSSize(width:360,height:500)); reader.view.layoutSubtreeIfNeeded(); reader.viewDidLayout()
        XCTAssertEqual(reader.view.bounds.width, 360, accuracy: 1)
        XCTAssertTrue(reader.headings.isHidden); XCTAssertFalse(reader.overflow.isHidden); XCTAssertFalse(reader.search.isHidden)
        XCTAssertTrue(reader.overflow.itemTitles.contains(L10n.text("阅读/源码切换")))
        reader.close()
    }
    func testNotebookDisplaysAllCellsAndOutputsWithoutSidebar() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded()
        let ready = expectation(description:"Notebook")
        reader.open(fixture("sample.ipynb")) { error in XCTAssertNil(error); ready.fulfill() }
        await fulfillment(of:[ready],timeout:10)
        let collection = try XCTUnwrap(reader.collection)
        try await waitUntil { collection.reader.text.string.contains("HTML output blocked") }
        let content = collection.reader.text.string
        XCTAssertTrue(content.contains("Notebook 中文"))
        XCTAssertTrue(content.contains("print(\"do not execute\")"))
        XCTAssertTrue(content.contains("Already recorded output"))
        XCTAssertFalse(content.contains("<script>"))
        XCTAssertEqual(collection.list.selectedRow,-1)
        XCTAssertEqual((collection.view as? NSSplitView)?.arrangedSubviews.first?.isHidden,true)
        reader.close()
    }

    func testDrawingSurvivesShorterLoadingText() throws {
        _ = NSApplication.shared
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:400,pixelsHigh:200,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0))
        NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep:bitmap)
        defer { NSGraphicsContext.restoreGraphicsState() }
        let text = ReadingTextView(frame:NSRect(x:0,y:0,width:400,height:200))
        text.model = .plain(String(repeating:"中文句子。",count:100)); text.string = text.model.display
        text.setAnchor(at:200)
        text.drawBackground(in:text.bounds); text.draw(text.bounds)
        // Loading can shorten storage before a replacement model is ready.
        text.string = "读取中"
        text.drawBackground(in:text.bounds); text.draw(text.bounds)
        XCTAssertEqual(text.string,"读取中")
    }

}
