import XCTest
@testable import OrangeLenCore

final class TextPagingTests: XCTestCase {
    func testFastPreviewThresholdPagesMediumFilesWithoutLosingUnicode() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".txt")
        defer { try? FileManager.default.removeItem(at: url) }
        let text = String(repeating: "中文🍊\n", count: 100000)
        try Data(text.utf8).write(to: url)
        XCTAssertFalse(try AccessBroker.readPreview(url).partial)
        var offset = 0, combined = ""
        repeat {
            let page = try AccessBroker.readPreview(url, byteOffset: offset, pageBytes: 65536, fullReadThreshold: 1024 * 1024)
            XCTAssertLessThanOrEqual(page.byteCount, 65536)
            combined += page.text
            guard let next = page.nextByteOffset else { break }
            offset = next
        } while true
        XCTAssertEqual(combined, text)
    }
    func testOptInPositionRestoresPageAndRejectsDifferentRevisionOrPage() throws {
        let suite = "OrangeLenPaging-" + UUID().uuidString, defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: root) }
        let store = SettingsStore(group: nil, defaults: defaults, directory: root)
        var settings = ReaderSettings(); settings.remember = true; store.save(settings)
        let url = URL(fileURLWithPath: "/synthetic/large.log")
        store.remember(url, revision: "v1", offset: 73, byteOffset: 1048576, pageHistory: [0, 524288, 1048576])
        XCTAssertEqual(store.restorePage(url, revision: "v1")?.byteOffset, 1048576)
        XCTAssertEqual(store.restorePage(url, revision: "v1")?.history, [0, 524288])
        XCTAssertNil(store.restore(url, revision: "v1"))
        XCTAssertEqual(store.restore(url, revision: "v1", byteOffset: 1048576), 73)
        XCTAssertNil(store.restorePage(url, revision: "v2"))
        settings.remember = false; store.save(settings); XCTAssertNil(store.restorePage(url, revision: "v1"))
    }
    func testUTF8PagesReassembleWithoutLostOrDuplicatedScalars() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".log")
        defer { try? FileManager.default.removeItem(at: url) }
        let text = String(repeating: "中文🍊 line\n", count: 360000)
        try Data(text.utf8).write(to: url)
        var offset = 0, combined = "", pages = 0
        repeat {
            let page = try AccessBroker.readPreview(url, byteOffset: offset, pageBytes: 100003)
            XCTAssertTrue(page.partial); XCTAssertEqual(page.byteOffset, offset)
            combined += page.text; pages += 1
            if let next = page.nextByteOffset { XCTAssertGreaterThan(next, offset); offset = next }
            else { break }
        } while pages < 100
        XCTAssertGreaterThan(pages, 1); XCTAssertTrue(combined == text, "Every scalar must survive page boundaries")
    }
    func testUTF16PagesUseOriginalBOMAndKeepSurrogatePairs() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".txt")
        defer { try? FileManager.default.removeItem(at: url) }
        let text = String(repeating: "中文🍊\n", count: 600000)
        try (Data([0xff, 0xfe]) + text.data(using: .utf16LittleEndian)!).write(to: url)
        var offset = 0, combined = ""
        for _ in 0..<100 {
            let page = try AccessBroker.readPreview(url, byteOffset: offset, pageBytes: 100003)
            combined += page.text
            if let next = page.nextByteOffset { offset = next } else { break }
        }
        XCTAssertTrue(combined == text, "Every scalar must survive page boundaries")
    }
    func testMalformedAndBinaryPageRemainErrorsAndSmallFilesRemainComplete() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".txt")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("small 中文".utf8).write(to: url)
        XCTAssertFalse(try AccessBroker.readPreview(url).partial)
        let bad = Data(repeating: 0xff, count: 6 * 1024 * 1024)
        try bad.write(to: url); XCTAssertThrowsError(try AccessBroker.readPreview(url))
        try Data(repeating: 0, count: 6 * 1024 * 1024).write(to: url)
        XCTAssertThrowsError(try AccessBroker.readPreview(url))
        XCTAssertThrowsError(try AccessBroker.readPreview(url, byteOffset: -1))
    }
}
