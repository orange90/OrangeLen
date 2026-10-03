import XCTest
import AppKit
@testable import OrangeLenUI
import OrangeLenCore

@MainActor final class LayoutTests: XCTestCase {
    func testFileButtonKeepsSelectionAndActivatesOnce() throws {
        _ = NSApplication.shared
        let folder = FolderController(); folder.loadViewIfNeeded()
        let root = FolderController.Node(URL(fileURLWithPath: "/fixture"), directory: true)
        root.loaded = true
        let first = FolderController.Node(root.url.appendingPathComponent("one.png"), directory: false)
        let second = FolderController.Node(root.url.appendingPathComponent("two.md"), directory: false)
        root.children = [first, second]; folder.root = root
        folder.outline.reloadData(); folder.outline.expandItem(root)
        var selected: [URL] = []; folder.onSelect = { selected.append($0) }
        let accessibleRow = try XCTUnwrap(folder.outlineView(folder.outline, rowViewForItem: first))
        XCTAssertTrue(accessibleRow.accessibilityPerformPress())
        XCTAssertEqual(folder.outline.item(atRow: folder.outline.selectedRow) as? FolderController.Node === first, true)
        folder.activate(second)
        XCTAssertEqual(folder.selectedURL, second.url)
        XCTAssertEqual(selected, [first.url, second.url])
    }
    func testPNGPreviewAndReturnToTextKeepFolderSummary() async throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 32, pixelsHigh: 16, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        for x in 0..<32 { for y in 0..<16 { bitmap.setColor(NSColor(deviceRed: 1, green: 0.5, blue: 0.1, alpha: 1), atX: x, y: y) } }
        let file = root.appendingPathComponent("test.png")
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: file)
        let image = try ImagePreview.load(file, root: root, cancellation: Cancellation())
        XCTAssertEqual(image.width, 32); XCTAssertEqual(image.height, 16)
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try ImagePreview.load(file, root: root, cancellation: token))
        let broken = root.appendingPathComponent("broken.png"); try Data("not a png".utf8).write(to: broken)
        XCTAssertThrowsError(try ImagePreview.load(broken, root: root, cancellation: Cancellation()))
        let reader = ReaderController(); reader.loadViewIfNeeded()
        reader.rootURL = root; reader.folderInfo.stringValue = "persistent folder total"
        let ready = expectation(description: "image")
        reader.loadFile(file) { error in XCTAssertNil(error); ready.fulfill() }
        await fulfillment(of: [ready], timeout: 10)
        XCTAssertTrue(reader.currentContent === reader.picture); XCTAssertNotNil(reader.picture.image)
        XCTAssertEqual(reader.folderInfo.stringValue, "persistent folder total")
        let text = root.appendingPathComponent("file.txt"); try Data("hello".utf8).write(to: text)
        let textReady = expectation(description: "text")
        reader.loadFile(text) { error in XCTAssertNil(error); textReady.fulfill() }
        await fulfillment(of: [textReady], timeout: 10)
        XCTAssertTrue(reader.currentContent === reader.scroll); XCTAssertEqual(reader.text.string, "hello")
        XCTAssertEqual(reader.folderInfo.stringValue, "persistent folder total"); reader.close()
    }
    func testMarkdownTablesHaveRealCellGeometryAndSafeLinks() throws {
        _ = NSApplication.shared
        let model = try MarkdownModel.parse("# 标题\n\n| Left | Right |\n| :--- | ---: |\n| 中文长内容以及 emoji 👩🏽‍💻 多次换行的文字内容 | 123 |\n\n***bold italic*** [safe](https://example.com)")
        let attributed = TextStyler.attributed(model, markdown: true, settings: ReaderSettings(), focus: false)
        XCTAssertEqual(attributed.string, model.display)
        let text = ReadingTextView(frame: NSRect(x: 0, y: 0, width: 640, height: 900))
        text.textContainer?.widthTracksTextView = false
        text.textStorage?.setAttributedString(attributed)
        let layout = try XCTUnwrap(text.layoutManager), container = try XCTUnwrap(text.textContainer)
        for width in [600.0, 360.0] {
            container.containerSize = NSSize(width: width, height: 100000)
            layout.ensureLayout(for: container)
            let a = layout.boundingRect(forGlyphRange: layout.glyphRange(forCharacterRange: model.cells[0].range, actualCharacterRange: nil), in: container)
            let b = layout.boundingRect(forGlyphRange: layout.glyphRange(forCharacterRange: model.cells[1].range, actualCharacterRange: nil), in: container)
            XCTAssertGreaterThan(b.minX, a.minX); XCTAssertEqual(a.minY, b.minY, accuracy: 2)
            XCTAssertLessThanOrEqual(b.maxX, width + 2)
        }
        let hit = try XCTUnwrap(model.search("bold italic").first)
        let font = try XCTUnwrap(attributed.attribute(.font, at: hit.location, effectiveRange: nil) as? NSFont)
        let traits = NSFontManager.shared.traits(of: font)
        XCTAssertTrue(traits.contains(.boldFontMask)); XCTAssertTrue(traits.contains(.italicFontMask))
        let root = URL(fileURLWithPath: "/authorized")
        let document = root.appendingPathComponent("README.md")
        XCTAssertNil(MarkdownNavigation.localURL("../private.png", document: document, root: root))
        XCTAssertNil(MarkdownNavigation.localURL("javascript:alert(1)", document: document, root: root))
        XCTAssertNil(MarkdownNavigation.localURL("//server/image.png", document: document, root: root))
        XCTAssertEqual(MarkdownNavigation.localURL("assets/a%20b.png", document: document, root: root)?.lastPathComponent, "a b.png")
        let reader = ReaderController(); reader.loadViewIfNeeded(); reader.text.model = model
        XCTAssertTrue(reader.textView(reader.text, clickedOnLink: "#标题", at: 0))
        XCTAssertEqual(reader.text.anchor, 0)
    }
    func testMarkdownLocalImageBudgetAndAttachmentPreserveText() throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 32, pixelsHigh: 16, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: root.appendingPathComponent("test.png"))
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("link.png"), withDestinationURL: root.appendingPathComponent("test.png"))
        let model = try MarkdownModel.parse("![本地](test.png)\n\n![网络](https://example.invalid/x.png)\n\n![越界](../x.png)\n\n![链接](link.png)")
        let assets = try MarkdownAssets.load(model, document: root.appendingPathComponent("README.md"), root: root, cancellation: Cancellation())
        XCTAssertEqual(assets.images.count, 1); XCTAssertEqual(assets.failures.count, 3)
        for width in [600.0, 200.0] {
            let result = TextStyler.attributed(model, markdown: true, settings: ReaderSettings(), focus: true, assets: assets, width: width)
            XCTAssertEqual(result.string, model.display)
            let attachment = try XCTUnwrap(result.attribute(.attachment, at: model.images[0].range.location, effectiveRange: nil) as? NSTextAttachment)
            XCTAssertNotNil(attachment.attachmentCell)
            XCTAssertEqual(model.copiedSource(model.images[0].range), "![本地](test.png)")
        }
    }
    func testMarkdownCodeAndQuotesDoNotCollapseToSingleGlyphColumns() throws {
        _ = NSApplication.shared
        let model = try MarkdownModel.parse("""
        > quoted text 中文

        ```swift
        let greeting = "你好 👋"
        print(greeting)
        ```
        """)
        let text = ReadingTextView(frame: NSRect(x: 0, y: 0, width: 700, height: 900))
        text.model = model; text.sentences = model.sentences()
        text.textContainer?.widthTracksTextView = false
        text.textContainer?.containerSize = NSSize(width: 640, height: 100000)
        text.textStorage?.setAttributedString(TextStyler.attributed(model, markdown: true, settings: ReaderSettings(), focus: false))
        let layout = try XCTUnwrap(text.layoutManager), container = try XCTUnwrap(text.textContainer)
        layout.ensureLayout(for: container)
        var lines = 0
        layout.enumerateLineFragments(forGlyphRange: NSRange(location: 0, length: layout.numberOfGlyphs)) { _, _, _, _, _ in lines += 1 }
        XCTAssertLessThan(lines, 10)
        for count in [1,3,5] {
            text.rulerLines = count; text.sentence(at: 0)
            let bands = text.visualRulerRects()
            XCTAssertLessThanOrEqual(bands.count, count)
            XCTAssertEqual(Set(bands.map { Int($0.minY) }).count, bands.count)
        }
    }
    func testRealTextKitReflowsWithoutChangingSourceMapping() throws {
        _ = NSApplication.shared
        let source = "# 你好 👩🏽‍💻\n\n" + String(repeating: "中英文 emoji 👋 e\u{301} and a long sentence，", count: 18) + "结束。下一句。"
        let model = try MarkdownModel.parse(source)
        let text = ReadingTextView(frame: NSRect(x: 0, y: 0, width: 340, height: 900))
        text.model = model; text.sentences = model.sentences(); text.focusEnabled = true
        text.textContainer?.widthTracksTextView = false
        let layout = try XCTUnwrap(text.layoutManager); let container = try XCTUnwrap(text.textContainer)
        var lineCounts: [Int] = []
        for (width, size) in [(300.0,18.0),(300.0,26.0),(700.0,18.0)] {
            var settings = ReaderSettings(); settings.documentSize = size
            text.textStorage?.setAttributedString(TextStyler.attributed(model, markdown: true, settings: settings, focus: true))
            container.containerSize = NSSize(width: width, height: 100000)
            layout.ensureLayout(for: container)
            var count = 0
            layout.enumerateLineFragments(forGlyphRange: NSRange(location: 0, length: layout.numberOfGlyphs)) { rect, _, _, _, _ in XCTAssertGreaterThan(rect.height, 0); count += 1 }
            lineCounts.append(count)
            for lines in [1,3,5] {
                text.rulerLines = lines; text.sentence(at: 12)
                let bitmap = try XCTUnwrap(text.bitmapImageRepForCachingDisplay(in: text.bounds))
                text.cacheDisplay(in: text.bounds, to: bitmap)
                XCTAssertEqual(text.string, model.display)
            }
        }
        XCTAssertGreaterThan(lineCounts[1], lineCounts[0]); XCTAssertLessThan(lineCounts[2], lineCounts[0])
        XCTAssertEqual(model.copiedSource(model.search("👩🏽‍💻")[0]), "👩🏽‍💻")
    }
    func testCodeViewportWithRulerHasVisibleGlyphs() async throws {
        _ = NSApplication.shared
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".swift")
        try Data("// 中文 👋\nlet greeting = \"Hello Finder\"\n".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let reader = ReaderController()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 720), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.contentViewController = reader
        window.orderFront(nil)
        let done = expectation(description: "loaded")
        reader.open(file) { error in XCTAssertNil(error); done.fulfill() }
        await fulfillment(of: [done], timeout: 10)
        reader.view.layoutSubtreeIfNeeded()
        let layout = try XCTUnwrap(reader.text.layoutManager), container = try XCTUnwrap(reader.text.textContainer)
        layout.ensureLayout(for: container)
        let glyph = layout.boundingRect(forGlyphRange: NSRange(location: 0, length: layout.numberOfGlyphs), in: container).offsetBy(dx: reader.text.textContainerOrigin.x, dy: reader.text.textContainerOrigin.y)
        print("VIEWPORT text=\(reader.text.frame) bounds=\(reader.text.bounds) visible=\(reader.text.visibleRect) glyphs=\(glyph) ruler=\(reader.lineRuler.frame)")
        XCTAssertGreaterThan(reader.text.visibleRect.intersection(glyph).height, 0)
        XCTAssertGreaterThan(glyph.minX, reader.lineRuler.ruleThickness)
        let bitmap = try XCTUnwrap(reader.view.bitmapImageRepForCachingDisplay(in: reader.view.bounds))
        reader.view.cacheDisplay(in: reader.view.bounds, to: bitmap)
        try bitmap.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: "/tmp/orangelen-code-regression.png"))
        reader.close(); window.orderOut(nil)
    }
    func testTwentyOneMiBPreviewsRecordWarmPreparation() async throws {
        _ = NSApplication.shared
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".swift")
        let line = "// Synthetic benchmark only: 中文 emoji 👋 no execution.\nlet value = 12345\n"
        var data = Data(); while data.count < 1024 * 1024 { data.append(Data(line.utf8)) }
        try data.write(to: file); defer { try? FileManager.default.removeItem(at: file) }
        let reader = ReaderController(); var times: [Double] = []
        for index in 0..<21 {
            let done = expectation(description: "preview \(index)"); let start = Date()
            reader.open(file) { error in XCTAssertNil(error); done.fulfill() }
            await fulfillment(of: [done], timeout: 20)
            reader.view.layoutSubtreeIfNeeded()
            if let container = reader.text.textContainer { reader.text.layoutManager?.ensureLayout(forBoundingRect: NSRect(x: 0, y: 0, width: 900, height: 600), in: container) }
            times.append(Date().timeIntervalSince(start) * 1000)
        }
        let warm = Array(times.dropFirst()).sorted(); let p95 = warm[18]
        print("BENCHMARK app-in-process, bytes=\(data.count), initialMs=\(times[0]), warm20Ms=\(Array(times.dropFirst())), warmP95Ms=\(p95), OS file cache not controlled; NOT Finder timing")
        XCTAssertEqual(reader.source?.byteCount, data.count)
        reader.close()
    }
    func testSupersededPreparationCompletesExactlyOnceAndLatestWins() async throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("first.txt"), second = root.appendingPathComponent("second.txt")
        try Data(String(repeating: "old", count: 200000).utf8).write(to: first)
        try Data("latest 中文 👋".utf8).write(to: second)
        let reader = ReaderController(); var counts = [0,0]
        reader.open(first) { _ in counts[0] += 1 }
        let completed = expectation(description: "latest result")
        reader.open(second) { error in counts[1] += 1; XCTAssertNil(error); completed.fulfill() }
        await fulfillment(of: [completed], timeout: 10)
        XCTAssertEqual(counts, [1,1]); XCTAssertEqual(reader.text.string, "latest 中文 👋")
        reader.close(); XCTAssertEqual(counts, [1,1])
    }
}
