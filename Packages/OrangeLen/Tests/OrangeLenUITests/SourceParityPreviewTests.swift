import AppKit
import XCTest
import OrangeLenCore
@testable import OrangeLenUI

@MainActor final class SourceParityPreviewTests: XCTestCase {
    // Also prepare fixtures for direct `swift test` and Xcode Test runs.
    override class func setUp() {
        super.setUp()
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python3", root.appendingPathComponent("scripts/create-source-parity-fixtures.py").path]
        do {
            try process.run()
            process.waitUntilExit()
            XCTAssertEqual(process.terminationStatus, 0, "Source parity fixture generation failed")
        } catch {
            XCTFail("Could not generate source parity fixtures: \(error)")
        }
    }

    private var fixtures: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/source-parity")
    }
    func testEveryRegisteredLanguageActuallyHighlightsItsSourceWithoutChangingText() throws {
        let samples = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: fixtures.appendingPathComponent("language-samples.json")))
        for (language, extensions) in SourceCodeFormats.groups {
            let source = try XCTUnwrap(samples[language])
            for ext in extensions {
                let detected = SyntaxHighlighter.language(url: URL(fileURLWithPath: "/sample." + ext), source: source)
                let tokens = SyntaxHighlighter.shared.tokens(source, language: detected)
                if language != "plaintext" { XCTAssertFalse(tokens.isEmpty, "Missing grammar: \(ext) → \(detected ?? "nil")") }
                let attributed = NSMutableAttributedString(string: source)
                SyntaxHighlighter.shared.apply(tokens, to: attributed)
                XCTAssertEqual(attributed.string, source, ext)
                XCTAssertTrue(tokens.allSatisfy { $0.range.location >= 0 && NSMaxRange($0.range) <= attributed.length }, ext)
            }
        }
    }
    func testSourcesAndBinaryConversionsReachTheRealReader() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        for name in ["sample.pl", "sample.jl", "sample.hs", "sample.nix", "sample.gleam", "sample.sol", "sample.zig", "sample.code-workspace", "sample.class", "binary.plist", "binary.loctable", "binary.wflow", "binary.strings", "binary.entitlements", "binary.a3x", "oracle.typ"] {
            let ready = expectation(description: name)
            reader.open(fixtures.appendingPathComponent(name)) { error in XCTAssertNil(error, name); ready.fulfill() }
            await fulfillment(of: [ready], timeout: 30)
            if name == "sample.code-workspace" { XCTAssertNotNil(reader.jsonTree); XCTAssertTrue(reader.currentContent === reader.json.view) }
            else { XCTAssertFalse(reader.text.string.isEmpty, name) }
            XCTAssertNotNil(reader.source, name)
            XCTAssertNil(reader.richRenderer, name)
            if name == "sample.class" { XCTAssertTrue(reader.text.string.contains("OrangeParity")) }
            if name.hasPrefix("binary."), name != "binary.a3x" { XCTAssertTrue(reader.text.string.contains("<plist"), name) }
            if name == "oracle.typ" { XCTAssertEqual(SyntaxHighlighter.language(url: fixtures.appendingPathComponent(name), source: reader.source!.text), "sql") }
        }
    }
    func testCompiledAppleScriptUsesIsolatedImporter() async throws {
        guard Bundle.main.bundleIdentifier == "local.OrangeLen.TestHost" else { throw XCTSkip("Requires the native test host with embedded XPC service") }
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        let ready = expectation(description: "compiled AppleScript")
        reader.open(fixtures.appendingPathComponent("compiled.scpt")) { error in XCTAssertNil(error); ready.fulfill() }
        await fulfillment(of: [ready], timeout: 40)
        XCTAssertTrue(reader.text.string.contains("OrangeLen compiled 中文🍊"))
        XCTAssertTrue(reader.source?.encoding.contains("decompiled") == true)
    }
}
