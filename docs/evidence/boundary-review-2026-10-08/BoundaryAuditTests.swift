import XCTest
import AppKit
@testable import OrangeLenUI
import OrangeLenCore

// Review probes: assert the observed defects, not the desired contract.
@MainActor final class BoundaryAuditTests: XCTestCase {
    func fixture(_ name: String) -> URL { URL(fileURLWithPath: ProcessInfo.processInfo.environment["ORANGELEN_AUDIT_FIXTURES"] ?? "/tmp/orangelen-boundary-audit").appendingPathComponent(name) }
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
    func testObservedGeneratedColumnMisalignment() throws {
        let db = try DatabaseDocument(data: Data(contentsOf: fixture("generated.sqlite")))
        let page = try db.page("sample")
        XCTAssertEqual(page.columns.map(\.name), ["a", "label"])
        XCTAssertEqual(page.rows, [["7", "14", "orange"]])
        print("AUDIT generated columns:", page.columns.map(\.name), "values:", page.rows)
    }
    func testObservedInteriorBOMIsLostAcrossPages() throws {
        let url = try temporary("bom.txt")
        let original = String(repeating: "a", count: 16) + "\u{feff}second-page-data"
        try original.write(to: url, atomically: true, encoding: .utf8)
        let first = try AccessBroker.readPreview(url, pageBytes: 16, fullReadThreshold: 0)
        let second = try AccessBroker.readPreview(url, byteOffset: 16, pageBytes: 64, fullReadThreshold: 0)
        XCTAssertNotEqual(first.text + second.text, original)
        XCTAssertFalse(second.text.hasPrefix("\u{feff}"))
        print("AUDIT page-start U+FEFF silently removed")
    }
    func testObservedCloseLosesSavedPageHistory() async throws {
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
        XCTAssertEqual(saved.byteOffset, 65536); XCTAssertEqual(saved.history, [])
        let reopened = await open(reader, url); XCTAssertNil(reopened)
        XCTAssertEqual(reader.source?.byteOffset, 65536); XCTAssertFalse(reader.previousPageButton.isEnabled)
        print("AUDIT reopen page 2: previous page disabled")
    }
    func testObservedTruncateLeavesNoReadablePage() async throws {
        _ = NSApplication.shared
        let url = try temporary("truncate.log")
        try String(repeating: "orange\n", count: 200000).write(to: url, atomically: true, encoding: .utf8)
        let reader = ReaderController(); defer { reader.close() }
        let error = await open(reader, url); XCTAssertNil(error)
        reader.nextTextPage(); try await settle { reader.source?.byteOffset == 65536 }
        try "short replacement".write(to: url, atomically: true, encoding: .utf8)
        reader.settings.liveReload = true; reader.checkForFileChanges()
        try await settle { !reader.autoReload }
        XCTAssertNil(reader.source); XCTAssertTrue(reader.text.string.contains("分页位置"))
        XCTAssertTrue(reader.pageBar.isHidden)
        print("AUDIT truncation: old byte offset prevents reload", reader.text.string)
    }
    func testObservedCancelDoesNotReachContainerToken() throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        let collection = CollectionController(), token = Cancellation()
        collection.token = token; reader.collection = collection
        reader.cancelLoad()
        XCTAssertNoThrow(try token.check())
        print("AUDIT parent cancel leaves container token active")
    }
    func testObservedFolderCancelLeavesLoadingLatch() async throws {
        _ = NSApplication.shared
        let file = try temporary("a.txt"); try "x".write(to: file, atomically: true, encoding: .utf8)
        let folder = FolderController(); folder.open(file.deletingLastPathComponent())
        let root = try XCTUnwrap(folder.root)
        folder.cancel()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(root.loading); XCTAssertFalse(root.loaded)
        folder.load(root)
        XCTAssertTrue(folder.tasks.isEmpty)
        print("AUDIT cancelled directory remains loading and cannot retry")
    }
    func testObservedFailedNotebookKeepsOldBody() async throws {
        _ = NSApplication.shared
        let first = try temporary("first.ipynb"), second = try temporary("bad.ipynb")
        try #"{"cells":[{"cell_type":"markdown","source":["OLD PRIVATE CONTENT"]}],"nbformat":4}"#.write(to: first, atomically: true, encoding: .utf8)
        try "broken".write(to: second, atomically: true, encoding: .utf8)
        let reader = ReaderController(); defer { reader.close() }
        let good = await open(reader, first); XCTAssertNil(good)
        try await settle { reader.collection?.reader.text.string.contains("OLD PRIVATE CONTENT") == true }
        let bad = await open(reader, second); XCTAssertNotNil(bad)
        XCTAssertTrue(reader.currentContent === reader.collection?.view)
        XCTAssertTrue(reader.collection?.reader.text.string.contains("OLD PRIVATE CONTENT") == true)
        XCTAssertTrue((reader.collection?.view as? NSSplitView)?.arrangedSubviews.first?.isHidden == true)
        print("AUDIT failed notebook retains previous body; error sidebar hidden")
    }
    func testObservedArchiveMetadataSuccessDoesNotEnforceEntryLimit() throws {
        let data = try Data(contentsOf: fixture("blocked.docx"))
        let archive = try ArchiveDocument.parse(data, name: "document.zip")
        let entry = try XCTUnwrap(archive.entries.first)
        XCTAssertNotNil(entry.blocked)
        XCTAssertThrowsError(try archive.read(entry))
        print("AUDIT native-import preflight returns success with blocked entry:", entry.size, entry.blocked ?? "")
    }
    func testObservedArchivePathAliasesOverwriteVisibleMember() throws {
        let data = try Data(contentsOf: fixture("aliases.zip"))
        let archive = try ArchiveDocument.parse(data, name: "aliases.zip")
        let tree = try ArchiveController.tree(archive.entries)
        XCTAssertEqual(archive.entries.count, 2)
        XCTAssertEqual(tree.first?.children.count, 1)
        XCTAssertEqual(tree.first?.children.first?.entry?.path, "folder//a.txt")
        print("AUDIT two archive paths collapse into one visible member")
    }
    func testObservedJSONPathMaterializationAmplifiesInput() throws {
        let source = "{\"" + String(repeating: "k", count: 32768) + "\":[" + Array(repeating: "0", count: 100).joined(separator: ",") + "]}"
        let tree = try JSONParser.parse(source)
        let pathBytes = tree.root.children[0].children.reduce(0) { $0 + $1.path.utf8.count }
        XCTAssertGreaterThan(pathBytes, source.utf8.count * 90)
        print("AUDIT JSON input bytes", source.utf8.count, "leaf path bytes", pathBytes)
    }
    func testObservedOfficeSharedStringsAmplifyDisplay() throws {
        let data = try Data(contentsOf: fixture("shared.xlsx"))
        let output = try OfficeContentPreview.text(data)
        XCTAssertGreaterThan(output.utf8.count, data.count * 20)
        print("AUDIT Office input bytes", data.count, "output bytes", output.utf8.count)
    }
    func testObservedDatabaseFailureLeavesPreviousTableData() async throws {
        _ = NSApplication.shared
        let data = try Data(contentsOf: fixture("generated.sqlite"))
        let db = try DatabaseDocument(data: data), controller = DatabaseController()
        defer { controller.cancel() }
        controller.open(db, selected: "sample")
        try await settle { controller.page?.rows.first?.first == "7" }
        controller.selector.selectItem(withTitle: "oversized"); controller.selectTable()
        try await settle { controller.status.stringValue != "读取中…" }
        XCTAssertTrue(controller.status.stringValue.contains("SQLite"))
        XCTAssertEqual(controller.selector.titleOfSelectedItem, "oversized")
        XCTAssertEqual(controller.page?.rows.first?.first, "7")
        XCTAssertTrue(controller.table.isEnabled)
        print("AUDIT failed table switch keeps previous rows enabled under new table selector")
    }
}
