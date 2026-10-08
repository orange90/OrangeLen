import XCTest
@testable import OrangeLenCore

final class LocalizationTests: XCTestCase {
    func testProcessUsesRequestedLanguage() {
        if let expected = ProcessInfo.processInfo.environment["ORANGELEN_TEST_LANGUAGE"] {
            XCTAssertEqual(L10n.currentLanguage, expected)
            XCTAssertEqual(L10n.text("文件夹概览"), expected == "en" ? "Folder Overview" : "文件夹概览")
        }
    }

    func testPreferredLanguageOrderAndFallback() {
        XCTAssertEqual(L10n.language(for: ["zh-Hans-CN", "en-US"]), "zh-Hans")
        XCTAssertEqual(L10n.language(for: ["zh-CN"]), "zh-Hans")
        XCTAssertEqual(L10n.language(for: ["en-GB", "zh-Hans"]), "en")
        XCTAssertEqual(L10n.language(for: ["fr-FR", "zh-Hans"]), "zh-Hans")
        XCTAssertEqual(L10n.language(for: ["ja-JP"]), "en")
        XCTAssertEqual(L10n.language(for: []), "en")
    }

    func testTranslationsAndInterpolatedUserContentArePreserved() {
        XCTAssertEqual(L10n.text("文件夹概览", language: "en"), "Folder Overview")
        XCTAssertEqual(L10n.text("文件夹概览", language: "zh-Hans"), "文件夹概览")
        XCTAssertEqual(L10n.text("文件夹概览", language: "fr"), "Folder Overview")
        let file = "中文 🍊 {1} %s %@ /path/file.md"
        let message: L10n.Message = "系统：\(file)"
        XCTAssertEqual(L10n.text(message, language: "en"), "System: " + file)
        XCTAssertEqual(L10n.text(message, language: "zh-Hans"), "系统：" + file)
        XCTAssertEqual(L10n.text("显示 \(1) / \(42) 行", language: "en"), "Showing 1 / 42 rows")
        XCTAssertEqual(L10n.text("显示 \(1) / \(42) 行", language: "zh-Hans"), "显示 1 / 42 行")
        XCTAssertEqual(L10n.text("显示 \(file) / \(42) 行", language: "en"), "Showing " + file + " / 42 rows")
    }

    func testEveryTranslationIsPackagedAndHasMatchingPlaceholders() throws {
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let resources = package.appendingPathComponent("Sources/OrangeLenCore/Resources")
        func read(_ language: String) throws -> [String: String] {
            let data = try Data(contentsOf: resources.appendingPathComponent("\(language).lproj/Localizable.strings"))
            return try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String])
        }
        let english = try read("en"), chinese = try read("zh-Hans")
        XCTAssertEqual(Set(english.keys), Set(chinese.keys))
        XCTAssertGreaterThan(english.count, 570)
        let placeholder = try NSRegularExpression(pattern: #"\{\d+\}"#)
        func slots(_ value: String) -> [String] {
            placeholder.matches(in: value, range: NSRange(value.startIndex..., in: value))
                .map { (value as NSString).substring(with: $0.range) }.sorted()
        }
        for (key, translation) in english {
            XCTAssertFalse(translation.isEmpty, key)
            XCTAssertEqual(slots(key), slots(translation), key)
            XCTAssertEqual(chinese[key], key)
            XCTAssertEqual(L10n.text(.init(stringLiteral: key), language: "en"), translation, key)
            XCTAssertEqual(L10n.text(.init(stringLiteral: key), language: "zh-Hans"), key)
        }
    }
}
