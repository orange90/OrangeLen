import XCTest
@testable import OrangeLenCore

final class M2Tests: XCTestCase {
    func fixture(_ name: String) throws -> Data {
        let root = URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf:root.appendingPathComponent("Tests/Fixtures/m2/"+name))
    }
    func testJSONLBadLineDoesNotDiscardGoodRecords() throws {
        let source = try AccessBroker.decode(fixture("records.jsonl")).0
        let lines = try EnhancedDocuments.jsonLines(source)
        XCTAssertEqual(lines.count,3); XCTAssertTrue(lines[0].warning.isEmpty); XCTAssertFalse(lines[1].warning.isEmpty); XCTAssertTrue(lines[2].warning.isEmpty)
        XCTAssertTrue(lines[0].text.contains("9007199254740993"))
    }
    func testArchiveLazyReadCRCAndPathBudgets() throws {
        let data = try fixture("sample.zip"), archive = try ArchiveDocument.parse(data,name:"sample.zip")
        XCTAssertEqual(archive.entries.count,3)
        let entry = try XCTUnwrap(archive.entry("src/demo.swift")); XCTAssertTrue(String(decoding:try archive.read(entry),as:UTF8.self).contains("中文"))
        XCTAssertThrowsError(try ArchiveDocument.parse(fixture("unsafe-path.zip"),name:"bad.zip"))
        XCTAssertFalse(ArchiveDocument.safePath("/absolute")); XCTAssertFalse(ArchiveDocument.safePath("a/../escape")); XCTAssertFalse(ArchiveDocument.safePath("a\\b"))
        var tiny = PreviewLimits(); tiny.archiveEntryBytes = 5
        let limited = try ArchiveDocument.parse(data,name:"sample.zip",limits:tiny)
        XCTAssertNotNil(limited.entries.first?.blocked); XCTAssertThrowsError(try limited.read(limited.entries[0]))
        var corrupt = data; corrupt[40] ^= 0xff
        XCTAssertThrowsError(try { let doc = try ArchiveDocument.parse(corrupt,name:"sample.zip"); _ = try doc.read(doc.entries[0]) }())
        let token = Cancellation(); token.cancel(); XCTAssertThrowsError(try archive.read(entry,cancellation:token))
    }
    func testTARAndGzipReadWithoutExtraction() throws {
        for name in ["sample.tar","sample.tgz"] {
            let archive = try ArchiveDocument.parse(fixture(name),name:name)
            XCTAssertEqual(archive.entries.count,1); XCTAssertTrue(String(decoding:try archive.read(archive.entries[0]),as:UTF8.self).contains("Read only"))
        }
        var damaged = try fixture("sample.tar"); damaged[0] ^= 1
        XCTAssertThrowsError(try ArchiveDocument.parse(damaged,name:"bad.tar"))
    }
    func testEPUBSpineNavigationImagesAndScriptIsolation() throws {
        let book = try EPUBDocument.parse(fixture("sample.epub"))
        XCTAssertEqual(book.chapters.count,2); XCTAssertEqual(book.chapters[0].title,"第一章")
        let chapter = try book.chapter(book.chapters[0])
        XCTAssertTrue(chapter.text.contains("中文阅读")); XCTAssertTrue(chapter.text.contains("OPS/sample.png")); XCTAssertFalse(chapter.text.contains("shouldNeverExecute"))
        XCTAssertNotNil(book.archive.entry("OPS/sample.png"))
        XCTAssertNil(EPUBDocument.resolve("../../escape",base:"OPS/one.xhtml")); XCTAssertNil(EPUBDocument.resolve("https://example.com/x",base:"OPS/one.xhtml"))
    }
    func testSQLiteMemorySnapshotDoesNotModifySourceAndRefusesWAL() throws {
        let data = try fixture("sample.sqlite"), database = try DatabaseDocument(data:data)
        XCTAssertEqual(database.tableNames,["demo table"])
        let rows = try database.rows("demo table")
        XCTAssertEqual(rows[1][0],"中文 👩🏽‍💻"); XCTAssertEqual(rows[1][1],"9007199254740993"); XCTAssertEqual(rows[1][2],"[BLOB 3 bytes]")
        XCTAssertThrowsError(try database.rows("demo table\"; DROP TABLE x; --"))
        XCTAssertEqual(data,try fixture("sample.sqlite"))
        var wal = data; wal[18] = 2; XCTAssertThrowsError(try DatabaseDocument(data:wal))
        let token = Cancellation(); token.cancel(); XCTAssertThrowsError(try database.rows("demo table",cancellation:token))
    }
    func testNotebookAndDiffDoNotExecuteOrApply() throws {
        let source = try AccessBroker.decode(fixture("sample.ipynb")).0
        let cells = try EnhancedDocuments.notebook(source)
        XCTAssertTrue(cells[0].markdown); XCTAssertTrue(cells.contains { $0.text.contains("print") })
        XCTAssertFalse(cells.contains { $0.text.contains("<script>") }); XCTAssertTrue(cells.contains { $0.warning.contains("text/html") })
        let diff = try AccessBroker.decode(fixture("changes.diff")).0
        let sections = try EnhancedDocuments.diff(diff); XCTAssertEqual(sections.count,1); XCTAssertTrue(sections[0].text.contains("+let value"))
    }
    func testHARAndOpenAPINeverResolveExternalResources() throws {
        let har = try EnhancedDocuments.har(AccessBroker.decode(fixture("sample.har")).0)
        XCTAssertEqual(har.count,1); XCTAssertTrue(har[0].title.contains("example.invalid")); XCTAssertTrue(har[0].warning.contains(L10n.text("HAR 记录仅浏览；不重放请求，不获取 response 外链")))
        let api = try EnhancedDocuments.openAPI(AccessBroker.decode(fixture("openapi.json")).0)
        XCTAssertEqual(api[0].title,"/read"); XCTAssertTrue(api[0].warning.contains(L10n.text("只读路径定义；不请求 API，不解析外部 $ref")))
    }

    func testEPUBEncryptionIsNotConfusedWithFontObfuscationAndDTDIsRefused() throws {
        let protected = try EPUBDocument.parse(fixture("protected.epub"))
        XCTAssertThrowsError(try protected.chapter(protected.chapters[0]))
        XCTAssertTrue(try protected.chapter(protected.chapters[1]).text.contains("另一章节"))
        let fonts = try EPUBDocument.parse(fixture("font-obfuscation.epub"))
        XCTAssertTrue(fonts.warning.contains(L10n.text("字体混淆资源不加载，采用系统字体。 "))); XCTAssertTrue(try fonts.chapter(fonts.chapters[0]).text.contains("中文阅读"))
        let entities = try EPUBDocument.parse(fixture("entity.epub"))
        XCTAssertThrowsError(try entities.chapter(entities.chapters[0]))
    }

    func testContainerChapterAndAnchorRestoreInvalidatesOnRevision() throws {
        let suite = "OrangeLenTest-" + UUID().uuidString, defaults = try XCTUnwrap(UserDefaults(suiteName:suite))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { defaults.removePersistentDomain(forName:suite); try? FileManager.default.removeItem(at:directory) }
        let store = SettingsStore(group:nil,defaults:defaults,directory:directory)
        var settings = ReaderSettings(); settings.remember = true; store.save(settings)
        let book = URL(fileURLWithPath:"/synthetic/book.epub"), chapter = book.appendingPathComponent("second")
        store.remember(book,revision:"revision-1",offset:0,section:"second")
        store.remember(chapter,revision:"revision-1:second",offset:17)
        XCTAssertEqual(store.restoreSection(book,revision:"revision-1"),"second")
        XCTAssertEqual(store.restore(chapter,revision:"revision-1:second"),17)
        XCTAssertNil(store.restoreSection(book,revision:"revision-2"))
        settings.remember = false; store.save(settings); XCTAssertNil(store.restoreSection(book,revision:"revision-1"))
    }

}
