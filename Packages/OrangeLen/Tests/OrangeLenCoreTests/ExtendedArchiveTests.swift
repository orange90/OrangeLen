import XCTest
@testable import OrangeLenCore

final class ExtendedArchiveTests: XCTestCase {
    private func data(_ name: String) throws -> Data {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: root.appendingPathComponent("Tests/Fixtures/archive-expansion/" + name))
    }
    func test7zAndCompressedTARContents() throws {
        for name in ["sample.7z", "sample.tar.xz", "sample.tar.bz2", "sample.tar.zst"] {
            let archive = try ArchiveDocument.parse(data(name), name: name)
            XCTAssertEqual(archive.entries.count, 2, name)
            let member = try XCTUnwrap(archive.entry("README.md"), name)
            XCTAssertTrue(String(decoding: try archive.read(member), as: UTF8.self).contains("中文🍊"), name)
            let json = try archive.read(XCTUnwrap(archive.entry("config.json")))
            XCTAssertNoThrow(try JSONSerialization.jsonObject(with: json), name)
        }
    }
    func testRAR4AndRAR5ContentsAndBlockedLinks() throws {
        for (name, path, expected) in [("sample-rar4.rar", "test.txt", "test text document"),
                                        ("sample-rar5.rar", "helloworld.txt", "hello libarchive test suite!")] {
            let archive = try ArchiveDocument.parse(data(name), name: name)
            let member = try XCTUnwrap(archive.entry(path))
            XCTAssertTrue(String(decoding: try archive.read(member), as: UTF8.self).contains(expected))
            for entry in archive.entries where entry.path == "testlink" {
                XCTAssertNotNil(entry.blocked)
                XCTAssertThrowsError(try archive.read(entry))
            }
        }
    }
    func testCompressedRARPayloads() throws {
        let rar4 = try ArchiveDocument.parse(data("compressed-rar4.rar"), name: "compressed-rar4.rar")
        XCTAssertEqual(try rar4.read(XCTUnwrap(rar4.entry("LibarchiveAddingTest.html"))).count, 20111)
        let rar5 = try ArchiveDocument.parse(data("compressed-rar5.rar"), name: "compressed-rar5.rar")
        XCTAssertEqual(try rar5.read(XCTUnwrap(rar5.entry("test.bin"))).count, 1200)
    }
    func testLimitsCorruptionCancellationAndPaths() throws {
        for name in ["sample.7z", "sample-rar4.rar", "sample-rar5.rar", "sample.tar.xz", "sample.tar.bz2", "sample.tar.zst"] {
            let bytes = try data(name)
            var limits = PreviewLimits(); limits.archiveExpandedBytes = 8
            XCTAssertThrowsError(try ArchiveDocument.parse(bytes, name: name, limits: limits), name)
            XCTAssertThrowsError(try ArchiveDocument.parse(Data(bytes.prefix(12)), name: name), name)
            let token = Cancellation(); token.cancel()
            XCTAssertThrowsError(try ArchiveDocument.parse(bytes, name: name, cancellation: token), name)
        }
        XCTAssertThrowsError(try ArchiveDocument.parse(data("unsafe.tar.xz"), name: "unsafe.tar.xz"))
        let links = try ArchiveDocument.parse(data("link.tar.bz2"), name: "link.tar.bz2")
        XCTAssertNotNil(links.entries.first?.blocked)
        XCTAssertThrowsError(try links.read(XCTUnwrap(links.entries.first)))
    }
    func testCompressedTARAliases() throws {
        for (original, alias) in [("sample.tar.xz", "sample.txz"), ("sample.tar.bz2", "sample.tbz2"), ("sample.tar.zst", "sample.tzst")] {
            XCTAssertNotNil(try ArchiveDocument.parse(data(original), name: alias).entry("README.md"))
        }
    }
}
