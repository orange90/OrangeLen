import XCTest
import AppKit
@testable import OrangeLenUI
import OrangeLenCore

// Regression contracts for the 2026-10-08 review. All assertions describe corrected behavior.
@MainActor final class BoundaryRegressionTests: XCTestCase {
    func fixture(_ name: String) -> URL { URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/boundaries/" + name) }
    func settle(_ predicate: @escaping () -> Bool) async throws {
        for _ in 0..<300 { if predicate() { return }; try await Task.sleep(nanoseconds: 20_000_000) }
        XCTFail("Probe did not settle")
    }
    func open(_ reader: ReaderController, _ url: URL) async -> Error? {
        await withCheckedContinuation { continuation in reader.open(url) { continuation.resume(returning: $0) } }
    }
    func temporary(_ name: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir.appendingPathComponent(name)
    }
    func testGeneratedColumnsStayAligned() throws {
        let db = try DatabaseDocument(data: Data(contentsOf: fixture("generated.sqlite")))
        let page = try db.page("sample")
        XCTAssertEqual(page.columns.map(\.name), ["a", "doubled", "label"])
        XCTAssertEqual(page.rows, [["7", "14", "orange"]])
    }
    func testInteriorBOMSurvivesPages() throws {
        let url = try temporary("bom.txt")
        let original = String(repeating: "a", count: 16) + "\u{feff}second-page-data"
        try original.write(to: url, atomically: true, encoding: .utf8)
        let first = try AccessBroker.readPreview(url, pageBytes: 16, fullReadThreshold: 0)
        let second = try AccessBroker.readPreview(url, byteOffset: 16, pageBytes: 64, fullReadThreshold: 0)
        XCTAssertEqual(first.text + second.text, original)
        XCTAssertTrue(second.text.hasPrefix("\u{feff}"))
    }
    func testClosePreservesSavedPageHistory() async throws {
        _ = NSApplication.shared
        let store = SettingsStore.shared, old = SettingsStore.shared.load()
        let oldFiles = Set((try? FileManager.default.contentsOfDirectory(at: store.directory, includingPropertiesForKeys: nil)) ?? [])
        var settings = old; settings.remember = true; store.save(settings)
        defer {
            store.save(old)
            for url in ((try? FileManager.default.contentsOfDirectory(at: store.directory, includingPropertiesForKeys: nil)) ?? []) where !oldFiles.contains(url) { try? FileManager.default.removeItem(at: url) }
        }
        let url = try temporary("large.log")
        try String(repeating: "orange\n", count: 200000).write(to: url, atomically: true, encoding: .utf8)
        let reader = ReaderController(); defer { reader.close() }
        let error = await open(reader, url); XCTAssertNil(error)
        reader.nextTextPage(); try await settle { reader.source?.byteOffset == 65536 }
        XCTAssertEqual(reader.pageHistory, [0])
        let revision = try XCTUnwrap(reader.source?.revision)
        reader.close()
        let saved = try XCTUnwrap(store.restorePage(url, revision: revision))
        XCTAssertEqual(saved.byteOffset, 65536); XCTAssertEqual(saved.history, [0])
        let reopened = await open(reader, url); XCTAssertNil(reopened)
        XCTAssertEqual(reader.source?.byteOffset, 65536); XCTAssertTrue(reader.previousPageButton.isEnabled)
    }
    func testTruncateRecoversAtStart() async throws {
        _ = NSApplication.shared
        let url = try temporary("truncate.log")
        try String(repeating: "orange\n", count: 200000).write(to: url, atomically: true, encoding: .utf8)
        let reader = ReaderController(); defer { reader.close() }
        let error = await open(reader, url); XCTAssertNil(error)
        reader.nextTextPage(); try await settle { reader.source?.byteOffset == 65536 }
        try "short replacement".write(to: url, atomically: true, encoding: .utf8)
        reader.settings.liveReload = true; reader.checkForFileChanges()
        try await settle { !reader.autoReload }
        XCTAssertEqual(reader.source?.text, "short replacement"); XCTAssertEqual(reader.source?.byteOffset, 0)
        XCTAssertTrue(reader.status.stringValue.contains(L10n.text("文件已变化，旧分页位置失效，已返回开头。")))
        XCTAssertTrue(reader.pageBar.isHidden)
    }
    func testCancelReachesContainerToken() throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        let collection = CollectionController(), token = Cancellation()
        collection.token = token; reader.collection = collection
        reader.cancelLoad()
        XCTAssertThrowsError(try token.check())
    }
    func testFolderCancelAllowsRetry() async throws {
        _ = NSApplication.shared
        let file = try temporary("a.txt"); try "x".write(to: file, atomically: true, encoding: .utf8)
        let folder = FolderController(); folder.open(file.deletingLastPathComponent())
        let root = try XCTUnwrap(folder.root)
        folder.cancel()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(root.loading); XCTAssertFalse(root.loaded)
        folder.load(root)
        try await settle { root.loaded }
        XCTAssertEqual(root.children.count, 1)
        folder.cancel()
    }
    func testFailedNotebookClearsOldBody() async throws {
        _ = NSApplication.shared
        let first = try temporary("first.ipynb"), second = try temporary("bad.ipynb")
        try #"{"cells":[{"cell_type":"markdown","source":["OLD PRIVATE CONTENT"]}],"nbformat":4}"#.write(to: first, atomically: true, encoding: .utf8)
        try "broken".write(to: second, atomically: true, encoding: .utf8)
        let reader = ReaderController(); defer { reader.close() }
        let good = await open(reader, first); XCTAssertNil(good)
        try await settle { reader.collection?.reader.text.string.contains("OLD PRIVATE CONTENT") == true }
        let bad = await open(reader, second); XCTAssertNotNil(bad)
        XCTAssertTrue(reader.currentContent === reader.collection?.view)
        XCTAssertFalse(reader.collection?.reader.text.string.contains("OLD PRIVATE CONTENT") == true)
        XCTAssertTrue(reader.collection?.reader.text.string.contains("bad.ipynb") == true)
        XCTAssertTrue((reader.collection?.view as? NSSplitView)?.arrangedSubviews.first?.isHidden == true)
    }
    func testNativeImportEnforcesEntryLimits() throws {
        let data = try Data(contentsOf: fixture("blocked.docx"))
        let archive = try ArchiveDocument.parse(data, name: "document.zip")
        let entry = try XCTUnwrap(archive.entries.first)
        XCTAssertNotNil(entry.blocked)
        XCTAssertThrowsError(try archive.read(entry))
        XCTAssertThrowsError(try archive.validateForNativeImport())
    }
    func testArchivePathAliasesAreRejected() throws {
        let data = try Data(contentsOf: fixture("aliases.zip"))
        XCTAssertThrowsError(try ArchiveDocument.parse(data, name: "aliases.zip"))
    }
    func testJSONPathsShareAncestors() throws {
        let source = "{\"" + String(repeating: "k", count: 32768) + "\":[" + Array(repeating: "0", count: 100).joined(separator: ",") + "]}"
        let tree = try JSONParser.parse(source)
        let pathBytes = tree.root.children[0].children.reduce(0) { $0 + $1.storedPathBytes }
        XCTAssertLessThan(pathBytes, 1024)
        XCTAssertTrue(tree.root.children[0].children[99].path.hasSuffix("[99]"))
    }
    func testOfficeSharedStringsObeyOutputBudget() throws {
        let data = try Data(contentsOf: fixture("shared.xlsx"))
        let output = try OfficeContentPreview.text(data)
        XCTAssertTrue(output.contains("A99"))
        var limits = PreviewLimits(); limits.officeTextBytes = 32000
        XCTAssertThrowsError(try OfficeContentPreview.text(data, limits: limits))
    }
    func testDatabaseFailureClearsPreviousTableData() async throws {
        _ = NSApplication.shared
        let data = try Data(contentsOf: fixture("generated.sqlite"))
        let db = try DatabaseDocument(data: data), controller = DatabaseController()
        defer { controller.cancel() }
        controller.open(db, selected: "sample")
        try await settle { controller.page?.rows.first?.first == "7" }
        controller.selector.selectItem(withTitle: "oversized"); controller.selectTable()
        try await settle { controller.status.stringValue != L10n.text("读取中…") }
        XCTAssertTrue(controller.status.stringValue.contains("SQLite"))
        XCTAssertEqual(controller.selector.titleOfSelectedItem, "oversized")
        XCTAssertNil(controller.page)
        XCTAssertFalse(controller.table.isEnabled)
        XCTAssertEqual(controller.numberOfRows(in: controller.table), 0)
    }
    func testStoredVirtualGeneratedColumnsSortAndTypedCopy() throws {
        let db = try DatabaseDocument(data: Data(contentsOf: fixture("types.sqlite")))
        let page = try db.page("cases", sortColumn: 2)
        XCTAssertEqual(page.columns.map(\.name), ["first", "value", "middle", "label", "last"])
        XCTAssertEqual(page.rows, [["2", "1", "2", "b", "b1"], ["4", "3", "6", "a", "a3"]])
        let row = try XCTUnwrap(db.page("typed").cells.first)
        XCTAssertEqual(row[0], .null); XCTAssertEqual(row[1], .text("NULL"))
        XCTAssertEqual(row[2], .blob(Data([0, 255]))); XCTAssertEqual(row[3], .text("[BLOB 2 bytes]"))
        XCTAssertEqual(row[5], .invalidText(Data([255]))); XCTAssertEqual(row[6], .text("x\0y"))
        XCTAssertEqual(try db.page("reals").cells.map { $0[0].sqlLiteral }, ["1.2345678901234567", "9e999"])
    }
    func testOrdinaryDirectoriesWithMediaSuffixRemainDirectories() async throws {
        for name in ["folder.mp4", "folder.png"] {
            let url = try temporary(name); try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            let reader = ReaderController(); let error = await open(reader, url)
            XCTAssertNil(error); XCTAssertEqual(reader.rootURL, url); XCTAssertFalse(reader.folder.view.isHidden)
            reader.close()
        }
    }
    func testEmptyNotebookReplacesPreviousBodyAndParentActionsStayVisible() async throws {
        let url = try temporary("empty.ipynb")
        try #"{"cells":[],"nbformat":4}"#.write(to: url, atomically: true, encoding: .utf8)
        let reader = ReaderController(); defer { reader.close() }
        let error = await open(reader, url); XCTAssertNil(error)
        try await settle { reader.collection?.reader.text.string != "" }
        XCTAssertFalse(reader.status.isHidden)
        XCTAssertNil(reader.collection?.reader.source)
    }
    func testFolderStatisticsStopIndependentlyOfDirectoryReading() async throws {
        let url = try temporary("file.txt"); try Data([1]).write(to: url)
        let folder = FolderController(); folder.open(url.deletingLastPathComponent()); defer { folder.cancel() }
        let root = try XCTUnwrap(folder.root)
        folder.stopSummary(); XCTAssertNil(folder.summaryToken)
        try await settle { root.loaded }; XCTAssertEqual(root.children.count, 1)
        folder.toggleSummary(); try await settle { folder.summaryToken == nil && folder.lastSummary?.complete == true }
        XCTAssertEqual(folder.lastSummary?.files, 1)
    }

    func testHomeRemainsAvailableBeyondHistoryWindowAndEncodingChangesRecover() async throws {
        let url = try temporary("many-pages.log"); try Data(repeating: 97, count: 9 * 1024 * 1024).write(to: url)
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        let error: Error? = await withCheckedContinuation { continuation in
            reader.loadFile(url, byteOffset: 128 * 65536, pageOffsets: (0..<128).map { $0 * 65536 }) { continuation.resume(returning: $0) }
        }
        XCTAssertNil(error)
        reader.nextTextPage(); try await settle { reader.source?.byteOffset == 129 * 65536 }
        XCTAssertEqual(reader.pageHistory.count, 128); XCTAssertEqual(reader.pageHistory.first, 65536)
        XCTAssertTrue(reader.firstPageButton.isEnabled)
        reader.firstTextPage(); try await settle { reader.source?.byteOffset == 0 }
        XCTAssertTrue(reader.pageHistory.isEmpty)
        reader.nextTextPage(); try await settle { reader.source?.byteOffset == 65536 }
        var changed = Data([0xFF, 0xFE]); changed.append(String(repeating: "b", count: 100000).data(using: .utf16LittleEndian)!)
        try changed.write(to: url, options: .atomic)
        reader.reloadPreservingPosition(url, notice: "测试编码变化")
        try await settle { !reader.autoReload }
        XCTAssertEqual(reader.source?.byteOffset, 0); XCTAssertEqual(reader.source?.encoding, "UTF-16 LE")
    }

    func testReaderPaintsItsOwnBackgroundForDarkAndLightChrome() throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        XCTAssertTrue(reader.view is ReaderBackgroundView)
        reader.view.frame = NSRect(x: 0, y: 0, width: 360, height: 640)
        for theme in ["Dark", "Light"] {
            reader.settings.theme = theme; reader.applySettings(); reader.view.layoutSubtreeIfNeeded()
            let image = try XCTUnwrap(reader.view.bitmapImageRepForCachingDisplay(in: reader.view.bounds))
            reader.view.cacheDisplay(in: reader.view.bounds, to: image)
            let color = try XCTUnwrap(image.colorAt(x: 1, y: 1)?.usingColorSpace(.deviceRGB))
            if theme == "Dark" { XCTAssertLessThan(color.redComponent, 0.4) }
            else { XCTAssertGreaterThan(color.redComponent, 0.7) }
            XCTAssertGreaterThan(color.alphaComponent, 0.99)
        }
    }

}
