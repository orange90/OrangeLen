import XCTest
@testable import OrangeLenCore

final class CoreTests: XCTestCase {
    func testFolderSummaryIncludesHiddenItemsAndNeverFollowsLinks() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("nested"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data([1,2,3]).write(to: root.appendingPathComponent(".hidden"))
        try Data([4,5]).write(to: root.appendingPathComponent("nested/file"))
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("cycle"), withDestinationURL: root)
        let result = try FolderSummary.scan(root)
        XCTAssertTrue(result.complete); XCTAssertEqual(result.bytes, 5)
        XCTAssertEqual(result.files, 2); XCTAssertEqual(result.folders, 1); XCTAssertEqual(result.links, 1)
        var limits = PreviewLimits(); limits.directoryScanItems = 1
        XCTAssertFalse(try FolderSummary.scan(root, limits: limits).complete)
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try FolderSummary.scan(root, cancellation: token))
    }
    func testMarkdownStructureRetainsNumberingTablesLinksAndImageMapping() throws {
        let source = "3. One\n4. Two\n   - nested\n\n| 名称 | 数量 |\n| :--- | ---: |\n| 中文 **👋** | 123 |\n\n[go](#heading) ![alt](image.png)\n\nsoft\nbreak"
        let model = try MarkdownModel.parse(source)
        XCTAssertTrue(model.display.contains("3.\tOne")); XCTAssertTrue(model.display.contains("4.\tTwo"))
        XCTAssertTrue(model.paragraphs.contains { $0.listDepth == 2 })
        XCTAssertEqual(model.cells.count, 4); XCTAssertEqual(model.cells.last?.alignment, 2)
        XCTAssertEqual(model.links.first?.destination, "#heading")
        let image = try XCTUnwrap(model.images.first)
        XCTAssertEqual(model.copiedSource(image.range), "![alt](image.png)")
        XCTAssertEqual(model.copiedSource(try XCTUnwrap(model.search("👋").first)), "👋")
        XCTAssertTrue(model.display.contains("soft break"))
        XCTAssertEqual(model.copiedSource(try XCTUnwrap(model.search("soft break").first)), "soft\nbreak")
        for cell in model.cells { XCTAssertLessThanOrEqual(NSMaxRange(cell.range), model.display.utf16.count) }
    }
    func testStrictEncodingsAndBOM() throws {
        let text = "中文 👩🏽‍💻\r\ne\u{301}"
        XCTAssertEqual(try AccessBroker.decode(Data(text.utf8)).0, text)
        XCTAssertEqual(try AccessBroker.decode(Data([0xEF,0xBB,0xBF]) + Data(text.utf8)).0, text)
        XCTAssertEqual(try AccessBroker.decode(Data([0xFF,0xFE]) + text.data(using: .utf16LittleEndian)!).0, text)
        XCTAssertEqual(try AccessBroker.decode(Data([0xFE,0xFF]) + text.data(using: .utf16BigEndian)!).0, text)
        XCTAssertThrowsError(try AccessBroker.decode(Data([0xC3,0x28])))
        XCTAssertThrowsError(try AccessBroker.decode(Data([0,1,2])))
    }
    func testUTF16MappingSearchAndCopy() {
        let text = "甲👩🏽‍💻e\u{301}\r\nHello 甲"
        let model = TextModel.plain(text)
        let hits = model.search("甲")
        XCTAssertEqual(hits.count, 2)
        XCTAssertEqual(model.copiedSource(hits[1]), "甲")
        let emoji = (text as NSString).range(of: "👩🏽‍💻")
        XCTAssertEqual(model.copiedSource(emoji), "👩🏽‍💻")
        XCTAssertEqual(model.search("hello").count, 1)
        XCTAssertEqual(model.search("hello", caseSensitive: true).count, 0)
    }
    func testCommonMarkStructureAndMapping() throws {
        let source = "# 标题 👋\n\n你好 **世界**。第二句！\n\n- [x] 项目\n\n```swift\nlet x = 42\n```\n\n|A|B|\n|-|-|\n|中|👋|\n"
        let model = try MarkdownModel.parse(source)
        XCTAssertTrue(model.display.contains("你好 世界。第二句！"))
        XCTAssertTrue(model.display.contains("☑"))
        XCTAssertTrue(model.blocks.contains { if case .heading = $0.kind { return true }; return false })
        XCTAssertTrue(model.blocks.contains { if case .cell = $0.kind { return true }; return false })
        for query in ["世界", "👋", "let x = 42"] {
            for hit in model.search(query) { XCTAssertTrue(model.copiedSource(hit).contains(query), "\(query): \(model.copiedSource(hit))") }
        }
        for span in model.mapping {
            XCTAssertLessThanOrEqual(NSMaxRange(span.display), model.display.utf16.count)
            XCTAssertLessThanOrEqual(NSMaxRange(span.source), source.utf16.count)
        }
    }
    func testMarkdownEntitiesEscapesAndUnsafeHTMLRemainText() throws {
        let model = try MarkdownModel.parse("A &amp; B \\*x\\* **👩🏽‍💻**\n\n<script>alert('never')</script>\n\n![alt](https://example.invalid/image.png)")
        XCTAssertTrue(model.display.contains("A & B"))
        XCTAssertEqual(model.copiedSource(model.search("A")[0]), "A")
        XCTAssertEqual(model.copiedSource(model.search("&")[0]), "&amp;")
        XCTAssertTrue(model.display.contains("<script>"))
        XCTAssertFalse(model.warnings.isEmpty)
        let hit = try XCTUnwrap(model.search("👩🏽‍💻").first)
        XCTAssertTrue(model.copiedSource(hit).contains("👩🏽‍💻"))
    }
    func testSentencesDoNotCrossBlocksOrSplitDecimals() throws {
        let model = try MarkdownModel.parse("Dr. Lee reads 3.14. Visit https://example.invalid/docs. 你好！下一句。\n\n# Heading\n\n```swift\nlet a = 1.2\nlet b = 3\n```")
        let sentences = model.sentences().map { (model.display as NSString).substring(with: $0) }
        XCTAssertTrue(sentences.contains { $0.contains("Dr. Lee") })
        XCTAssertTrue(sentences.contains { $0.contains("3.14") })
        XCTAssertTrue(sentences.contains { $0.contains("https://example.invalid/docs") })
        XCTAssertFalse(sentences.contains { $0.contains("Heading") && $0.contains("let") })
        XCTAssertTrue(sentences.contains { $0.contains("let a = 1.2") && !$0.contains("let b") })
    }
    func testCSVQuotedMultilineAndEscapedFields() throws {
        let text = "name,value\r\n\"中,文\",\"line1\nline2 \"\"quote\"\"\"\r\n👋,3\r\n"
        let result = try CSVParser.parse(text)
        XCTAssertEqual(result.rows.count, 3)
        XCTAssertEqual(result.rows[1][0].value, "中,文")
        XCTAssertEqual(result.rows[1][1].value, "line1\nline2 \"quote\"")
        XCTAssertEqual((text as NSString).substring(with: result.rows[1][0].sourceRange), "\"中,文\"")
        XCTAssertEqual(try CSVParser.parse("a\tb\n1\t2", separator: 9).rows[1][1].value, "2")
    }
    func testMalformedCSVAndBudget() throws {
        XCTAssertThrowsError(try CSVParser.parse("\"not closed"))
        XCTAssertThrowsError(try CSVParser.parse("\"ok\"junk,2"))
        var limits = PreviewLimits(); limits.tableRows = 2
        let table = try CSVParser.parse("a\n1\n2\n3", limits: limits)
        XCTAssertTrue(table.partial); XCTAssertEqual(table.rows.count, 2)
    }
    func testJSONPreservesDuplicateKeysLargeNumbersAndPaths() throws {
        let text = "{\"a\":90071992547409931234567890,\"a\":2,\"x.y\":[true,null,\"👋\"]}"
        let tree = try JSONParser.parse(text)
        XCTAssertTrue(tree.duplicateKeys); XCTAssertEqual(tree.root.children.count, 3)
        XCTAssertEqual((text as NSString).substring(with: tree.root.children[0].range), "90071992547409931234567890")
        XCTAssertEqual(tree.root.children[2].children[2].path, "$[\"x.y\"][2]")
    }
    func testJSONStrictSyntaxAndDepthBudget() throws {
        for text in ["[1,]", "{\"a\":}", "01", "NaN", "1e", "\"\\q\"", "true false"] { XCTAssertThrowsError(try JSONParser.parse(text), text) }
        var limits = PreviewLimits(); limits.structureDepth = 4
        XCTAssertThrowsError(try JSONParser.parse("[[[[[[0]]]]]]", limits: limits))
    }
    func testCancellationAllParsers() throws {
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try MarkdownModel.parse("hello", cancellation: token))
        XCTAssertThrowsError(try JSONParser.parse("{}", cancellation: token))
        XCTAssertThrowsError(try CSVParser.parse("a,b", cancellation: token))
    }
    func testReadOnlyBoundedFilesAndSymlinks() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("source.swift")
        let bytes = Data("let value = \"中文 👋\"".utf8); try bytes.write(to: file)
        XCTAssertEqual(try AccessBroker.read(file).text, String(decoding: bytes, as: UTF8.self))
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        var limits = PreviewLimits(); limits.fileBytes = 2
        XCTAssertThrowsError(try AccessBroker.read(file, limits: limits))
        let link = root.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: file)
        XCTAssertThrowsError(try AccessBroker.read(link))
        XCTAssertThrowsError(try AccessBroker.read(file, root: root.appendingPathComponent("other")))
        try FileManager.default.removeItem(at: file)
        XCTAssertThrowsError(try AccessBroker.read(file))
    }
    func testFolderPaginationIgnoreAndCycle() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for name in ["a.swift", "b.py", "README.md", ".hidden"] { try Data(name.utf8).write(to: root.appendingPathComponent(name)) }
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("loop"), withDestinationURL: root)
        var limits = PreviewLimits(); limits.directoryBatch = 2
        var offset = 0; var all: [FolderEntry] = []
        repeat {
            let page = try FolderLoader.page(root, root: root, offset: offset, limits: limits)
            all += page.entries
            guard let next = page.nextOffset else { break }; offset = next
        } while true
        XCTAssertEqual(all.count, 4)
        XCTAssertTrue(all.contains { $0.symbolicLink })
        XCTAssertFalse(all.contains { $0.url.lastPathComponent == ".hidden" })
    }
    func testXMLIsNeverParsedOrResolved() throws {
        let text = "<!DOCTYPE x [<!ENTITY external SYSTEM 'file:///etc/passwd'>]><x>&external;</x>"
        XCTAssertEqual(TextModel.plain(text).display, text)
        XCTAssertEqual(PreviewFormat.detect(URL(fileURLWithPath: "a.xml")), .code)
    }
    func testLargeDirectoryBatchesKeepEveryEntryAndCancellation() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for i in 0..<2101 { try Data().write(to: root.appendingPathComponent("item-\(i).swift")) }
        var offset = 0, all = Set<String>(), pages = 0
        repeat {
            let page = try FolderLoader.page(root, root: root, offset: offset)
            XCTAssertLessThanOrEqual(page.entries.count, 500)
            for entry in page.entries { XCTAssertTrue(all.insert(entry.url.lastPathComponent).inserted) }
            pages += 1
            guard let next = page.nextOffset else { break }; offset = next
        } while true
        XCTAssertEqual(all.count, 2101); XCTAssertEqual(pages, 5)
        let cancelled = Cancellation(); cancelled.cancel()
        XCTAssertThrowsError(try FolderLoader.page(root, root: root, cancellation: cancelled))
    }
}
