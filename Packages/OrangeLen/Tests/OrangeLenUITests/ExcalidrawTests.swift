import XCTest
import AppKit
@testable import OrangeLenUI
import OrangeLenCore

@MainActor final class ExcalidrawTests: XCTestCase {
    var fixture: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/m2/sample.excalidraw")
    }
    func testInputLimitsAndResourceIsolation() throws {
        let source = try String(contentsOf: fixture)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(source.utf8)) as? [String: Any])
        var elements = try XCTUnwrap(object["elements"] as? [[String: Any]])
        elements[0]["link"] = "javascript:alert(1)"
        elements[0]["backgroundColor"] = "url(https://example.com/leak)"
        object["elements"] = elements
        object["files"] = ["png": ["dataURL": "https://example.com/leak"]]
        func encoded() throws -> String { String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self) }
        let safe = try ExcalidrawPreview.parse(encoded())
        XCTAssertFalse(safe.json.contains("javascript:")); XCTAssertFalse(safe.json.contains("https://"))
        XCTAssertTrue(safe.warning.contains("图片缺失"))
        object["elements"] = [["id": "web", "type": "embeddable"]]
        XCTAssertTrue(try ExcalidrawPreview.parse(encoded()).warning.contains("未渲染"))
        object["elements"] = [elements[0], elements[0]]
        XCTAssertThrowsError(try ExcalidrawPreview.parse(encoded()))
        elements[0]["x"] = 1e100; object["elements"] = [elements[0]]
        XCTAssertThrowsError(try ExcalidrawPreview.parse(encoded()))
        XCTAssertThrowsError(try ExcalidrawPreview.parse("{\"type\":\"other\",\"elements\":[]}"))
        XCTAssertThrowsError(try ExcalidrawPreview.parse(String(repeating: "x", count: 5 * 1024 * 1024 + 1)))
        let cancellation = Cancellation(); cancellation.cancel()
        XCTAssertThrowsError(try ExcalidrawPreview.parse(source, cancellation: cancellation))
    }
    func testOfflineCanvasSourceSwitchAndStaleLoad() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded()
        let window = NSWindow(contentRect: NSRect(x:0,y:0,width:900,height:700),styleMask:[.titled],backing:.buffered,defer:false)
        window.contentView = reader.view; window.orderBack(nil)
        defer { reader.close(); window.orderOut(nil) }
        let loaded = expectation(description: "Excalidraw rendered")
        reader.open(fixture) { error in XCTAssertNil(error); loaded.fulfill() }
        await fulfillment(of: [loaded], timeout: 20)
        let image = try XCTUnwrap(reader.canvasImage, reader.parseWarning)
        XCTAssertGreaterThan(image.size.width, 400)
        XCTAssertTrue(reader.currentContent === reader.picture)
        XCTAssertTrue(reader.mode.isEnabled)
        if let dir = ProcessInfo.processInfo.environment["ORANGELEN_EVIDENCE_DIR"], let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data:tiff), let png = bitmap.representation(using:.png,properties:[:]) {
            try png.write(to:URL(fileURLWithPath:dir).appendingPathComponent("excalidraw-canvas.png"))
        }
        reader.mode.selectedSegment = 1; reader.present()
        XCTAssertTrue(reader.currentContent === reader.scroll)
        XCTAssertTrue(reader.text.string.contains("OrangeLen 画布"))
        reader.mode.selectedSegment = 0; reader.present()
        XCTAssertTrue(reader.currentContent === reader.picture)
        reader.open(fixture) { _ in }
        let next = expectation(description: "Latest file")
        reader.open(fixture.deletingLastPathComponent().appendingPathComponent("records.jsonl")) { error in XCTAssertNil(error); next.fulfill() }
        await fulfillment(of: [next], timeout: 10)
        XCTAssertNil(reader.canvasImage)
        XCTAssertFalse(reader.currentContent === reader.picture)
    }
    func testMalformedCanvasFallsBackToSourceAndEmptyCanvasRenders() async throws {
        _ = NSApplication.shared
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".excalidraw")
        defer { try? FileManager.default.removeItem(at: file) }
        let reader = ReaderController(); reader.loadViewIfNeeded()
        defer { reader.close() }
        try "{bad json".write(to:file,atomically:true,encoding:.utf8)
        let loaded = expectation(description:"Source fallback")
        reader.open(file) { error in XCTAssertNil(error); loaded.fulfill() }
        await fulfillment(of:[loaded],timeout:10)
        XCTAssertEqual(reader.text.string,"{bad json")
        XCTAssertTrue(reader.parseWarning.contains("已降级源码"))
        let scene = try ExcalidrawPreview.parse("{\"type\":\"excalidraw\",\"elements\":[]}")
        let renderer = RichContentRenderer(resourceName:"ExcalidrawRenderer")
        defer { renderer.cancel() }
        let image = try await renderer.renderExcalidraw(scene,in:reader.view)
        XCTAssertGreaterThan(image.size.width,0)
    }
}
