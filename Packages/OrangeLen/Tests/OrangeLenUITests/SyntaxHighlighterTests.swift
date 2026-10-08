import XCTest
import AppKit
@testable import OrangeLenUI
import OrangeLenCore

final class SyntaxHighlighterTests: XCTestCase {
    func testLanguageGrammarsDoNotColorKeywordsInsideStringsAsKeywords() throws {
        XCTAssertGreaterThan(SyntaxHighlighter.shared.languageCount, 180)
        let source = "let value = \"class return 42 中文🍊\" // func\n"
        let tokens = SyntaxHighlighter.shared.tokens(source, language: "swift")
        let keyword = tokens.filter { $0.scope.contains("keyword") }.map { (source as NSString).substring(with: $0.range) }.joined()
        XCTAssertTrue(keyword.contains("let")); XCTAssertFalse(keyword.contains("class")); XCTAssertFalse(keyword.contains("return"))
        XCTAssertTrue(tokens.contains { $0.scope.contains("string") })
        XCTAssertTrue(tokens.contains { $0.scope.contains("comment") })
    }
    func testHostileMarkupIsOnlyColoredTextAndSourceRemainsExact() {
        let source = "<script>alert('do not execute')</script>\n<div>中文🍊 &amp;</div>"
        let attributed = NSMutableAttributedString(string: source)
        SyntaxHighlighter.shared.apply(attributed, range: NSRange(location: 0, length: attributed.length), language: "xml")
        XCTAssertEqual(attributed.string, source)
        XCTAssertFalse(SyntaxHighlighter.shared.tokens(source, language: "xml").isEmpty)
        XCTAssertTrue(SyntaxHighlighter.shared.tokens(source, language: "made-up-language").isEmpty)
    }
    func testMarkdownFenceLanguagesSurviveMathOffsetProjection() throws {
        let model = try MarkdownModel.parse("$x$\n\n```python\ndef value():\n    return 'let'\n```\n")
        let span = try XCTUnwrap(model.codeLanguages.first)
        XCTAssertEqual(span.language, "python")
        XCTAssertTrue((model.display as NSString).substring(with: span.range).hasPrefix("def value"))
        XCTAssertFalse(SyntaxHighlighter.shared.tokens((model.display as NSString).substring(with: span.range), language: span.language).isEmpty)
    }
    func testLanguageDetectionUsesNamedFilesAndShebang() {
        XCTAssertEqual(SyntaxHighlighter.language(url: URL(fileURLWithPath: "/Dockerfile.dev"), source: ""), "dockerfile")
        XCTAssertEqual(SyntaxHighlighter.language(url: URL(fileURLWithPath: "/script"), source: "#!/usr/bin/env python3\n"), "python")
    }
}
