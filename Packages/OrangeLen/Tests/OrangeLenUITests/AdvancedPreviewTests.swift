import XCTest
import AppKit
import PDFKit
import OrangeLenCore
@testable import OrangeLenUI

@MainActor final class AdvancedPreviewTests: XCTestCase {
    func fixture(_ name: String) -> URL {
        #if SWIFT_PACKAGE
        return URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/advanced-outputs/" + name)
        #else
        return Bundle(for:AdvancedPreviewTests.self).resourceURL!.appendingPathComponent("advanced-outputs/" + name)
        #endif
    }
    func open(_ reader: ReaderController,_ name: String) async {
        let ready = expectation(description:name); reader.open(fixture(name)) { error in XCTAssertNil(error,name); ready.fulfill() }; await fulfillment(of:[ready],timeout:40)
    }
    func testGraphPagesWorkflowsAndSource() async throws {
        _ = NSApplication.shared; let reader = ReaderController(); reader.loadViewIfNeeded(); defer {reader.close()}
        for file in ["diagram.drawio","board.canvas","comfy.json","comfy-api.json","n8n.json","dify.yml"] {
            await open(reader,file); let graph = try XCTUnwrap(reader.advancedView as? DiagramPreview,file); XCTAssertNotNil(graph.canvas.image)
            reader.mode.selectedSegment = 1; reader.present(); XCTAssertEqual(reader.text.string,try String(contentsOf:fixture(file),encoding:.utf8))
        }
    }
    func testModelAndArrayNativeViewsAndSwitch() async throws {
        _ = NSApplication.shared; let reader = ReaderController(); reader.loadViewIfNeeded(); defer {reader.close()}
        for file in ["array.npy","model.gguf","weights.safetensors","sample.latent"] { await open(reader,file); XCTAssertNotNil(reader.advancedView as? ScientificPreview) }
        await open(reader,"mesh.glb"); XCTAssertNotNil((reader.advancedView as? MeshPreview)?.canvas.image)
        await open(reader,"card.md"); XCTAssertNil(reader.advancedView)
    }
    func testParquetArrowDecoderAndNpzN8nContainers() async throws {
        _ = NSApplication.shared; let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        await open(reader,"table.parquet")
        let preview = try XCTUnwrap(reader.advancedView as? ScientificPreview)
        XCTAssertEqual(preview.table.data.rows.count,4)
        XCTAssertTrue(preview.summary.string.contains("3 rows"))
        XCTAssertTrue(preview.table.data.rows[1][0].value.contains("Orange"))
        await open(reader,"arrays.npz")
        try await Task.sleep(nanoseconds:100_000_000)
        XCTAssertTrue(reader.archiveController?.reader.text.string.contains("dtype:") == true)
        await open(reader,"workflows.n8np")
        try await Task.sleep(nanoseconds:100_000_000)
        XCTAssertTrue(reader.archiveController?.reader.text.string.contains("workflows: 1") == true)
    }
    func testImageAuthorizedSidecarsAndCanvasFileCards() throws {
        let root = fixture("generation.jpg").deletingLastPathComponent()
        let image = try ImagePreview.load(fixture("generation.jpg"),root:root,cancellation:.init())
        XCTAssertTrue(image.metadata.text.contains("Seed: 99"))
        let single = try ImagePreview.load(fixture("generation.jpg"),root:nil,cancellation:.init())
        XCTAssertFalse(single.metadata.text.contains("Seed: 99"))
        let graph = try XCTUnwrap(DiagramDocument.parseIfKnown(String(contentsOf:fixture("board.canvas")),name:"board.canvas"))
        XCTAssertTrue(try graph.resolvingCards(document:fixture("board.canvas"),root:root,cancellation:.init()).pages[0].boxes[1].text.contains("这段内容"))
    }
    func testMalformedGraphRetainsSourceAndCloseReleasesMesh() async throws {
        _ = NSApplication.shared; let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        let file = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString + ".drawio")
        defer { try? FileManager.default.removeItem(at:file) }
        try "<mxfile>broken".write(to:file,atomically:true,encoding:.utf8)
        let ready = expectation(description:"fallback"); reader.open(file) { error in XCTAssertNil(error); ready.fulfill() }; await fulfillment(of:[ready],timeout:10)
        XCTAssertEqual(reader.text.string,"<mxfile>broken"); XCTAssertTrue(reader.parseWarning.contains("source") || reader.parseWarning.contains("源码"))
        await open(reader,"mesh.glb"); weak var mesh = reader.advancedView as? MeshPreview; reader.close(); XCTAssertNil(mesh?.renderer.scene); try await Task.sleep(nanoseconds:50_000_000); XCTAssertNil(mesh)
    }
    func testAdvancedViewsFitFolderWindowAfterResize() async throws {
        _ = NSApplication.shared; let reader = ReaderController()
        let window = NSWindow(contentRect:NSRect(x:0,y:0,width:1120,height:720),styleMask:[.titled,.resizable],backing:.buffered,defer:false)
        let host = NSViewController(); host.addChild(reader); host.view = reader.view; window.contentViewController = host
        defer { reader.close(); window.contentViewController = nil }
        let ready = expectation(description:"folder"); reader.open(fixture("array.npy").deletingLastPathComponent()) { error in XCTAssertNil(error); ready.fulfill() }; await fulfillment(of:[ready],timeout:10)
        for file in ["diagram.drawio","mesh.glb","array.npy"] {
            let loaded = expectation(description:file); reader.loadFile(fixture(file)) { error in XCTAssertNil(error); loaded.fulfill() }; await fulfillment(of:[loaded],timeout:20)
            for width in [1120.0,760.0,900.0] {
                window.setContentSize(NSSize(width:width,height:720)); reader.view.layoutSubtreeIfNeeded()
                XCTAssertEqual(reader.view.bounds.width,width,accuracy:1,file)
                let surface = try XCTUnwrap(reader.advancedView)
                XCTAssertLessThanOrEqual(surface.convert(surface.bounds,to:reader.view).maxX,reader.view.bounds.maxX + 1,file)
            }
        }
    }
    func testReactMDXAndTypesetDocumentsActuallyRender() async throws {
        _ = NSApplication.shared; let reader = ReaderController(); reader.loadViewIfNeeded(); defer {reader.close()}
        for file in ["component.jsx","component.tsx","document.mdx"] { await open(reader,file); XCTAssertNotNil(reader.canvasImage,reader.parseWarning) }
        for file in ["document.tex","document.typ"] {
            await open(reader,file); XCTAssertNotNil(reader.pdf.document,reader.parseWarning); XCTAssertTrue(reader.advancedView === reader.pdf,reader.parseWarning)
            if file == "document.tex" {
                let text = try XCTUnwrap(reader.pdf.document?.string)
                XCTAssertTrue(text.contains("E"),text)
                XCTAssertTrue(text.contains("m") && text.contains("c"),text)
            }
        }
    }
}
