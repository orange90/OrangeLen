import XCTest
@testable import OrangeLenCore

final class MarkdownExtrasTests: XCTestCase {
    func testFencedCodeCopyKeepsBlankLinesCRLFAndDoesNotMatchLanguageLabel() throws {
        for (source, expected) in [
            ("```swift\nswift\n```\n", "swift\n"),
            ("```text\n\n中文🍊\n\n```\n", "\n中文🍊\n\n"),
            ("~~~text\r\n\r\n中文🍊\r\n\r\n~~~\r\n", "\r\n中文🍊\r\n\r\n"),
            ("```text\nlast", "last")
        ] {
            let model = try MarkdownModel.parse(source)
            let block = try XCTUnwrap(model.blocks.first { if case .code = $0.kind { return true }; return false })
            let range = try XCTUnwrap(model.sourceRange(for: block.range))
            XCTAssertEqual((source as NSString).substring(with: range), expected)
        }
    }
    func testFrontMatterDoesNotBecomeRulesOrHeadingsAndKeepsUnicodeCopy() throws {
        let source = "---\ntitle: 中文🍊\ntags: [preview, code]\n---\n# 正文\n\n普通内容"
        let model = try MarkdownModel.parse(source)
        XCTAssertTrue(model.display.hasPrefix(L10n.text("文档信息\n") + "title: 中文🍊"))
        XCTAssertTrue(model.display.contains("正文")); XCTAssertFalse(model.display.contains("────────"))
        let body = (model.display as NSString).range(of: "普通内容")
        XCTAssertEqual(model.copiedSource(body), "普通内容")
        XCTAssertEqual(model.copiedSource((model.display as NSString).range(of: "中文🍊")), "中文🍊")
        XCTAssertEqual(model.source, source)
    }
    func testFootnotesRelocateRenderInlineFormattingAndJumpBackToOriginal() throws {
        let source = "# Notes\n\n先读这段[^b]，然后[^a]。\n\n[^a]: 第一条 **粗体**\n    中文🍊延续\n[^b]: 第二条 [链接](https://example.com)\n"
        let model = try MarkdownModel.parse(source)
        XCTAssertTrue(model.display.contains("先读这段[1]，然后[2]"))
        XCTAssertTrue(model.display.contains("粗体")); XCTAssertFalse(model.display.contains("**粗体**"))
        XCTAssertEqual(model.anchors.map(\.name), ["b", "a"])
        XCTAssertTrue(model.links.contains { $0.destination == "orangelen-footnote:b" })
        let range = (model.display as NSString).range(of: "粗体")
        XCTAssertEqual(model.copiedSource(range), "粗体")
        XCTAssertEqual(model.copiedSource((model.display as NSString).range(of: "中文🍊延续")), "中文🍊延续")
        XCTAssertEqual(model.copiedSource((model.display as NSString).range(of: "[1]")), "[^b]")
        XCTAssertEqual(model.copiedSource(NSRange(location: 0, length: model.display.utf16.count)).trimmingCharacters(in: .newlines), source.trimmingCharacters(in: .newlines))
    }
    func testCodeAndEscapedFootnoteSyntaxRemainLiteralAndCalloutsAreStyled() throws {
        let source = "> [!WARNING]\n> 不会运行脚本。\n\n```python\n# [^x]\n```\n\n\\[^x] 与真正引用[^x]\n\n[^x]: 注释 $x$\n"
        let model = try MarkdownModel.parse(source)
        XCTAssertTrue(model.display.contains(L10n.text("警告"))); XCTAssertTrue(model.styles.contains { $0.style.contains(.callout) })
        XCTAssertTrue(model.display.contains("# [^x]")); XCTAssertEqual(model.codeLanguages.first?.language, "python")
        XCTAssertTrue(model.richContent.contains { $0.content == "x" })
        XCTAssertEqual(model.copiedSource((model.display as NSString).range(of: L10n.text("警告"))), "[!WARNING]")
        XCTAssertEqual(model.source, source)
    }
    func testDefinitionsInsideFencesAreNotMovedAndUnclosedFrontMatterStaysSource() throws {
        let source = "```\n[^fake]: still code\n```\n\n正文"
        let model = try MarkdownModel.parse(source)
        XCTAssertTrue(model.anchors.isEmpty); XCTAssertTrue(model.display.contains("[^fake]: still code"))
        XCTAssertFalse(try MarkdownModel.parse("---\ntitle: no closing").display.contains(L10n.text("文档信息")))
    }
}
