import XCTest
import AppKit
@testable import OrangeLenUI
import OrangeLenCore

@MainActor final class ImprovementIntegrationTests: XCTestCase {
    func testLargePreviewCompletesBeforeHighlightAndStaleHighlightCannotReplaceNextFile() async throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let large = directory.appendingPathComponent("large.swift"), small = directory.appendingPathComponent("small.txt")
        try String(repeating: "let orange = \"中文🍊\"\n", count: 300000).write(to: large, atomically: true, encoding: .utf8)
        try "new document".write(to: small, atomically: true, encoding: .utf8)
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        let ready = expectation(description: "plain first presentation")
        let started = ProcessInfo.processInfo.systemUptime
        reader.open(large) { error in
            XCTAssertNil(error)
            XCTAssertTrue(reader.source?.partial == true)
            XCTAssertLessThanOrEqual(reader.source?.byteCount ?? Int.max, 65536)
            XCTAssertEqual(reader.text.textStorage?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor, NSColor.textColor)
            print("FAST_PREVIEW_READY_MS", (ProcessInfo.processInfo.systemUptime - started) * 1000)
            ready.fulfill()
        }
        await fulfillment(of: [ready], timeout: 10)
        try await settle { reader.text.textStorage?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor == NSColor.systemPurple }
        let selected = NSRange(location: 4, length: 6)
        reader.text.setSelectedRange(selected)
        reader.schedulePageHighlight(try XCTUnwrap(reader.source))
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(reader.text.selectedRange(), selected)
        reader.schedulePageHighlight(try XCTUnwrap(reader.source))
        await open(reader, small)
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(reader.text.string, "new document")
    }
    func testCodeContextMenuDispatchesExactOriginalPayload() throws {
        _ = NSApplication.shared
        let source = "# 标题\n\n```swift\n\nlet orange = \"中文🍊\"\n\n```\n"
        let model = try MarkdownModel.parse(source)
        let text = ReadingTextView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        text.model = model; text.string = model.display
        let window = NSWindow(contentRect: text.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = text; defer { window.orderOut(nil) }
        let range = (model.display as NSString).range(of: "let orange")
        let layout = try XCTUnwrap(text.layoutManager), container = try XCTUnwrap(text.textContainer)
        layout.ensureLayout(for: container)
        let glyphs = layout.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let rect = layout.boundingRect(forGlyphRange: glyphs, in: container)
        let point = text.convert(NSPoint(x: rect.minX + 2 + text.textContainerOrigin.x, y: rect.midY + text.textContainerOrigin.y), to: nil)
        let event = try XCTUnwrap(NSEvent.mouseEvent(with: .rightMouseDown, location: point, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
        let menu = try XCTUnwrap(text.menu(for: event))
        let item = try XCTUnwrap(menu.items.first { $0.title == "复制代码块原文" })
        var feedback: String?; text.copyFeedback = { feedback = $0 }
        XCTAssertTrue(NSApplication.shared.sendAction(try XCTUnwrap(item.action), to: item.target, from: item))
        XCTAssertEqual(feedback, "已复制")
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "\nlet orange = \"中文🍊\"\n\n")
    }
    func fixture(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/" + name)
    }
    func settle(_ condition: @escaping () -> Bool) async throws {
        for _ in 0..<300 { if condition() { return }; try await Task.sleep(nanoseconds: 20_000_000) }
        XCTFail("Visible reader state did not settle")
    }
    func open(_ reader: ReaderController, _ url: URL) async {
        let ready = expectation(description: url.lastPathComponent)
        reader.open(url) { error in XCTAssertNil(error); ready.fulfill() }
        await fulfillment(of: [ready], timeout: 15)
    }
    func testSQLitePagesAndGlobalColumnSortReachNativeTable() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        await open(reader, fixture("improvements/paged.sqlite"))
        let database = try XCTUnwrap(reader.databaseController)
        database.selector.selectItem(withTitle: "records"); database.selectTable()
        try await settle { database.page?.rows.count == 500 }
        XCTAssertEqual(database.page?.rows.first?[0], "1")
        database.nextPage(); try await settle { database.page?.offset == 500 }
        XCTAssertEqual(database.page?.rows.first?[0], "501")
        database.nextPage(); try await settle { database.page?.offset == 1000 }
        XCTAssertEqual(database.page?.rows.count, 2); XCTAssertFalse(database.next.isEnabled)
        database.table.sortDescriptors = [NSSortDescriptor(key: "1", ascending: true)]
        try await settle { database.page?.rows.first?[1] == "0" }
        XCTAssertEqual(database.offset, 0); XCTAssertTrue(database.metadata.stringValue.contains("INTEGER"))
    }
    func testArchiveTreeFiltersFullPathAndReadsNestedFile() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        await open(reader, fixture("m2/sample.zip"))
        let archive = try XCTUnwrap(reader.archiveController)
        XCTAssertTrue(archive.roots.contains { $0.path == "src" && !$0.children.isEmpty })
        archive.filter.stringValue = "src/demo.swift"; archive.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification))
        XCTAssertEqual(archive.visible(archive.roots).count, 1)
        let item = try XCTUnwrap((0..<archive.outline.numberOfRows).first { (archive.outline.item(atRow: $0) as? ArchiveController.Node)?.path == "src/demo.swift" })
        archive.outline.selectRowIndexes(IndexSet(integer: item), byExtendingSelection: false)
        try await settle { archive.reader.text.string.contains("中文") }
        XCTAssertEqual(archive.reader.format, .code)
    }
    func testLiveReloadAtomicReplacementPreservesSourceModeAndStaleWorkCannotWin() async throws {
        _ = NSApplication.shared
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".md")
        defer { try? FileManager.default.removeItem(at: url) }
        try "# Before\n\noriginal".write(to: url, atomically: true, encoding: .utf8)
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        await open(reader, url)
        reader.mode.selectedSegment = 1; reader.present(); reader.settings.liveReload = true
        try "# After\n\nchanged".write(to: url, atomically: true, encoding: .utf8)
        reader.checkForFileChanges()
        try await settle { reader.source?.text.contains("changed") == true && !reader.autoReload }
        XCTAssertEqual(reader.mode.selectedSegment, 1)
        XCTAssertEqual(reader.text.string, "# After\n\nchanged")
        await open(reader, fixture("demo-project/src/main.swift"))
        XCTAssertEqual(reader.text.string, try String(contentsOf: fixture("demo-project/src/main.swift"), encoding: .utf8)); XCTAssertFalse(reader.text.string.contains("changed"))
    }
    func testLargeTextNextPreviousPagesAndZoomControls() async throws {
        _ = NSApplication.shared
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".log")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data(String(repeating: "中文🍊 log\n", count: 500000).utf8).write(to: url)
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        await open(reader, url)
        XCTAssertTrue(reader.source?.partial == true); XCTAssertFalse(reader.pageBar.isHidden)
        let first = try XCTUnwrap(reader.source)
        reader.nextTextPage(); try await settle { reader.source?.byteOffset == first.nextByteOffset }
        XCTAssertTrue(reader.previousPageButton.isEnabled)
        reader.previousTextPage(); try await settle { reader.source?.byteOffset == 0 }
        XCTAssertEqual(reader.source?.text, first.text)
        let canvas = ZoomCanvasView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        canvas.image = NSImage(size: NSSize(width: 200, height: 100))
        canvas.larger(); XCTAssertGreaterThan(canvas.zoom, 1)
        canvas.fit(); XCTAssertEqual(canvas.zoom, 1); XCTAssertEqual(canvas.pan, .zero)
    }
    func testNewSettingsDoNotDiscardExistingPreferences() throws {
        let data = Data(#"{"codeSize":21,"documentSize":25,"wrapCode":false,"lineNumbers":false,"theme":"Dark","remember":true,"ignored":["vendor"]}"#.utf8)
        let settings = try JSONDecoder().decode(ReaderSettings.self, from: data)
        XCTAssertEqual(settings.codeSize, 21); XCTAssertEqual(settings.theme, "Dark"); XCTAssertEqual(settings.ignored, ["vendor"])
        XCTAssertTrue(settings.liveReload); XCTAssertTrue(settings.markdownOutline)
    }
    func testReloadKeepsDatabasePageSortAndArchiveSelection() async throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let dbURL = root.appendingPathComponent("data.sqlite"), archiveURL = root.appendingPathComponent("sample.zip")
        let dbData = try Data(contentsOf: fixture("improvements/paged.sqlite")), zipData = try Data(contentsOf: fixture("m2/sample.zip"))
        try dbData.write(to: dbURL); try zipData.write(to: archiveURL)
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        await open(reader, dbURL)
        let db = try XCTUnwrap(reader.databaseController)
        db.selector.selectItem(withTitle: "records"); db.selectTable()
        try await settle { db.page?.rows.count == 500 }
        db.table.sortDescriptors = [NSSortDescriptor(key: "1", ascending: false)]
        try await settle { db.page?.rows.first?[1] == "1001" }
        db.nextPage(); try await settle { db.page?.offset == 500 }
        let expected = db.page?.rows.first
        reader.settings.liveReload = true; try dbData.write(to: dbURL, options: .atomic); reader.checkForFileChanges()
        try await settle { !reader.autoReload && db.page?.offset == 500 && db.page?.rows.first == expected }
        XCTAssertEqual(db.sortColumn, 1); XCTAssertFalse(db.ascending)
        await open(reader, archiveURL)
        let archive = try XCTUnwrap(reader.archiveController)
        archive.filter.stringValue = "src/demo.swift"; archive.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification))
        let row = try XCTUnwrap((0..<archive.outline.numberOfRows).first { (archive.outline.item(atRow: $0) as? ArchiveController.Node)?.path == "src/demo.swift" })
        archive.outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        try await settle { archive.reader.text.string.contains("中文") }
        reader.settings.liveReload = true; try zipData.write(to: archiveURL, options: .atomic); reader.checkForFileChanges()
        try await settle { !reader.autoReload && archive.reader.text.string.contains("中文") }
        XCTAssertEqual(archive.filter.stringValue, "src/demo.swift")
        XCTAssertEqual(archive.readingState.path, "src/demo.swift")
    }
    func testCategoryFallbackAndNarrowOutlineKeepSourceReadable() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        reader.previewCategory = PreviewCategory.code.rawValue
        await open(reader, fixture("improvements/reading.md"))
        XCTAssertNil(reader.rendered); XCTAssertFalse(reader.mode.isEnabled)
        XCTAssertEqual(reader.text.string, reader.source?.text)
        reader.previewCategory = nil
        await open(reader, fixture("improvements/reading.md"))
        reader.settings.markdownOutline = true; reader.present()
        reader.view.setFrameSize(NSSize(width: 360, height: 600)); reader.view.layoutSubtreeIfNeeded()
        XCTAssertTrue(reader.outlineSidebar.view.isHidden); XCTAssertTrue(reader.outlineToggle.isHidden)
        XCTAssertFalse(reader.search.isHidden); XCTAssertFalse(reader.overflow.isHidden)
        reader.view.setFrameSize(NSSize(width: 1000, height: 720)); reader.view.layoutSubtreeIfNeeded()
        reader.updateToolbars(1000)
        XCTAssertFalse(reader.outlineToggle.isHidden)
    }
    func testAttachmentMouseHitOpensZoomAndBackKeepsDocument() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 720), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentViewController = reader; defer { window.orderOut(nil) }
        await open(reader, fixture("improvements/reading.md")); reader.richTask?.cancel()
        let item = try XCTUnwrap(reader.rendered?.richContent.first)
        reader.markdownAssets.rich[item.range.location] = NSImage(size: NSSize(width: 100, height: 80))
        reader.present(); reader.view.layoutSubtreeIfNeeded(); reader.text.scrollRangeToVisible(item.range)
        let layout = try XCTUnwrap(reader.text.layoutManager), container = try XCTUnwrap(reader.text.textContainer)
        layout.ensureLayout(for: container)
        let glyphs = layout.glyphRange(forCharacterRange: item.range, actualCharacterRange: nil)
        let rect = layout.boundingRect(forGlyphRange: glyphs, in: container)
        let point = reader.text.convert(NSPoint(x: rect.midX + reader.text.textContainerOrigin.x, y: rect.midY + reader.text.textContainerOrigin.y), to: nil)
        let event = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
        reader.text.mouseDown(with: event)
        XCTAssertTrue(reader.currentContent === reader.picture)
        XCTAssertNotNil(reader.picture.onDismiss)
        reader.picture.larger(); XCTAssertGreaterThan(reader.picture.zoom, 1)
        reader.picture.dismiss(); XCTAssertTrue(reader.currentContent === reader.scroll)
        XCTAssertEqual(reader.source?.text, try String(contentsOf: fixture("improvements/reading.md"), encoding: .utf8))
    }
    func testTwentyRapidFileSwitchesNeverPresentStaleText() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        let last = expectation(description: "last of 20 requests")
        var completed = 0
        for i in 0..<20 {
            let url = fixture(i == 19 || i % 2 == 0 ? "improvements/reading.md" : "demo-project/src/main.swift")
            reader.loadFile(url) { error in
                completed += 1
                if i == 19 { XCTAssertNil(error); last.fulfill() }
                else { XCTAssertTrue(error is CancellationError) }
            }
        }
        await fulfillment(of: [last], timeout: 15)
        XCTAssertEqual(completed, 20)
        XCTAssertEqual(reader.currentURL, fixture("improvements/reading.md"))
        XCTAssertEqual(reader.source?.text, try String(contentsOf: fixture("improvements/reading.md"), encoding: .utf8))
    }
}
