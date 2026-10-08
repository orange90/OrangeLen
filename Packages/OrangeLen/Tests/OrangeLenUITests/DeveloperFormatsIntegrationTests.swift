import XCTest
import AppKit
@testable import OrangeLenUI
import OrangeLenCore

@MainActor final class DeveloperFormatsIntegrationTests: XCTestCase {
    func fixture(_ name:String) -> URL {
        URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/developer-formats/"+name)
    }
    func settled(_ condition:@escaping () -> Bool) async throws {
        for _ in 0..<250 { if condition() { return }; try await Task.sleep(nanoseconds:20_000_000) }
        XCTFail("Visible content did not settle")
    }
    func open(_ reader:ReaderController,_ name:String) async {
        let loaded = expectation(description:name)
        reader.open(fixture(name)) { error in XCTAssertNil(error); loaded.fulfill() }
        await fulfillment(of:[loaded],timeout:20)
    }
    func testTextAndJSONDialectsReachRealReaderAndCopyOriginalValues() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        for name in [".env.local","Dockerfile.dev","Component.vue","Component.svelte","Page.astro"] {
            await open(reader,name)
            XCTAssertEqual(reader.text.string,try String(contentsOf:fixture(name),encoding:.utf8))
        }
        await open(reader,"settings.jsonc")
        XCTAssertTrue(reader.currentContent === reader.json.view)
        let tree = try XCTUnwrap(reader.jsonTree)
        XCTAssertEqual((reader.source!.text as NSString).substring(with:tree.root.children[2].range),"9007199254740993")
        reader.mode.selectedSegment = 1; reader.present()
        XCTAssertTrue(reader.text.string.contains("// 保留注释"))
        await open(reader,"config.json5")
        XCTAssertTrue(reader.currentContent === reader.json.view)
        XCTAssertEqual(reader.jsonTree?.root.children[0].name,"name")
    }
    func testGzipLogCSVTSVAndJSONLDispatch() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        await open(reader,"app.log.gz")
        let collection = try XCTUnwrap(reader.collection)
        try await settled { collection.reader.source?.text.contains("中文日志") == true }
        XCTAssertTrue(collection.view.subviews.first?.isHidden == true)
        await open(reader,"table.csv.gz")
        try await settled { collection.reader.tableData?.rows.count == 3 }
        XCTAssertTrue(collection.reader.currentContent === collection.reader.table.view)
        await open(reader,"table.tsv.gz")
        try await settled { collection.reader.tableData?.rows.first?.count == 2 }
        XCTAssertEqual(collection.reader.format,.tsv)
        await open(reader,"config.json5.gz")
        try await settled { collection.reader.jsonTree?.root.children.first?.name == "name" }
        await open(reader,"records.jsonl.gz")
        try await settled { collection.reader.jsonTree?.root.children.first?.name == "id" }
        XCTAssertEqual(collection.titles.count,4); XCTAssertTrue(collection.titles[1].contains("损坏行"))
        collection.list.selectRowIndexes(IndexSet(integer:1),byExtendingSelection:false)
        try await settled { collection.reader.source?.text == "{bad}" }
        XCTAssertNil(collection.reader.jsonTree)
        XCTAssertEqual(collection.reader.parseWarning.components(separatedBy:"格式损坏").count,2)
        collection.list.selectRowIndexes(IndexSet(integer:3),byExtendingSelection:false)
        try await settled { collection.reader.source?.text.contains("9007199254740993") == true }
        XCTAssertEqual(collection.reader.format,.text)
    }
    func testSVGNativeImageSourceFallbackAndStaleLoad() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded()
        let window = NSWindow(contentRect:NSRect(x:0,y:0,width:900,height:700),styleMask:[.titled],backing:.buffered,defer:false)
        window.contentView = reader.view; window.orderBack(nil)
        defer { reader.close(); window.orderOut(nil) }
        await open(reader,"icon.svg")
        let image = try XCTUnwrap(reader.canvasImage,reader.parseWarning)
        XCTAssertEqual(image.size,NSSize(width:480,height:240)); XCTAssertEqual(reader.canvasLabel,"SVG")
        XCTAssertTrue(reader.currentContent === reader.picture)
        if let dir = ProcessInfo.processInfo.environment["ORANGELEN_EVIDENCE_DIR"], let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data:tiff), let png = bitmap.representation(using:.png,properties:[:]) {
            try png.write(to:URL(fileURLWithPath:dir).appendingPathComponent("developer-svg.png"))
        }
        reader.mode.selectedSegment = 1; reader.present()
        XCTAssertTrue(reader.text.string.contains("linearGradient"))
        await open(reader,"unsafe.svg")
        XCTAssertNotNil(reader.canvasImage); XCTAssertTrue(reader.parseWarning.contains("已省略"))
        reader.open(fixture("icon.svg")) { _ in }
        await open(reader,"Component.vue")
        XCTAssertNil(reader.canvasImage); XCTAssertTrue(reader.text.string.contains("中文 Vue"))
        let bad = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".svg")
        defer { try? FileManager.default.removeItem(at:bad) }
        try "<!DOCTYPE svg><svg/>".write(to:bad,atomically:true,encoding:.utf8)
        let fallback = expectation(description:"SVG source fallback")
        reader.open(bad) { error in XCTAssertNil(error); fallback.fulfill() }
        await fulfillment(of:[fallback],timeout:10)
        XCTAssertNil(reader.canvasImage); XCTAssertEqual(reader.text.string,"<!DOCTYPE svg><svg/>")
        XCTAssertTrue(reader.parseWarning.contains("已降级源码"))
    }
}
