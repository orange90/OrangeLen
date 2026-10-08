import XCTest
@testable import OrangeLenCore

final class FolderOverviewDataTests: XCTestCase {
    func testNameEnumerationPreservesPackagesUnicodeAndDanglingLinks() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Example.app"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data().write(to: root.appendingPathComponent("中文😀.txt"))
        try Data().write(to: root.appendingPathComponent(".hidden"))
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("dangling"), withDestinationURL: root.appendingPathComponent("missing"))
        let entries = try FolderLoader.page(root, root: root).entries
        XCTAssertEqual(entries.count, 3)
        XCTAssertTrue(try XCTUnwrap(entries.first { $0.url.lastPathComponent == "Example.app" }).package)
        XCTAssertTrue(try XCTUnwrap(entries.first { $0.url.lastPathComponent == "dangling" }).symbolicLink)
        XCTAssertTrue(entries.contains { $0.url.lastPathComponent == "中文😀.txt" })
        XCTAssertEqual(try FolderLoader.page(root, root: root, showIgnored: true).entries.count, 4)
    }

    func testCategoriesAndReadmeUseRealLocalFiles() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("nested"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertNil(try ProjectOverview.readme(root))
        let names = ["README.md", "nested/code.swift", ".env", "image.png", "song.mp3", "blob.xyz"]
        for name in names { try Data("# Real heading\n\nSample content".utf8).write(to: root.appendingPathComponent(name)) }
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("alias.swift"), withDestinationURL: root.appendingPathComponent("nested/code.swift"))
        let summary = try FolderSummary.scan(root)
        XCTAssertEqual(summary.categories.values.reduce(0, +), summary.files)
        XCTAssertEqual(summary.files, 6); XCTAssertEqual(summary.links, 1)
        for kind in FolderFileKind.allCases { XCTAssertEqual(summary.categories[kind], 1) }
        let readme = try XCTUnwrap(ProjectOverview.readme(root))
        XCTAssertTrue(readme.excerpt.contains("Real heading")); XCTAssertFalse(readme.excerpt.contains("# Real"))
        // A long multibyte README must end at a valid scalar boundary.
        try Data(String(repeating: "中文示例", count: 10000).utf8).write(to: root.appendingPathComponent("README.md"))
        XCTAssertLessThanOrEqual(try XCTUnwrap(ProjectOverview.readme(root)).excerpt.count, 501)
        try FileManager.default.removeItem(at: root.appendingPathComponent("README.md"))
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("README.md"), withDestinationURL: root.appendingPathComponent("nested/code.swift"))
        XCTAssertThrowsError(try ProjectOverview.readme(root))
    }
}
