import XCTest
@testable import OrangeLenCore

final class SourceParityTests: XCTestCase {
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
    func testManifestIsUniqueAndEverySourceActuallyLoads() throws {
        XCTAssertEqual(SourceCodeFormats.extensions.count, 219)
        XCTAssertEqual(SourceCodeFormats.groups.values.flatMap { $0 }.count, SourceCodeFormats.extensions.count)
        for ext in SourceCodeFormats.extensions where ext != "class" {
            let url = fixtures.appendingPathComponent("sample." + ext)
            XCTAssertTrue(ReadableFormat.isText(url), ext)
            let source = try AccessBroker.read(url)
            XCTAssertFalse(source.text.isEmpty, ext)
            XCTAssertEqual(source.text, try String(contentsOf: url, encoding: .utf8), ext)
            XCTAssertTrue(ReadableFormat.isText(URL(fileURLWithPath: "/sample." + ext.uppercased())), ext)
        }
        for name in [".bashrc", ".bash_profile", ".profile", ".zshrc", ".zprofile", ".zshenv"] {
            XCTAssertTrue(ReadableFormat.isNamedText(URL(fileURLWithPath: "/" + name)))
        }
    }
    func testBinaryPlistVariantsConvertWithoutAcceptingArbitraryBinary() throws {
        for ext in SourceCodeFormats.propertyListExtensions {
            let data = try Data(contentsOf: fixtures.appendingPathComponent("binary." + ext))
            let result = try XCTUnwrap(BinarySourcePreview.text(data, extension: ext))
            XCTAssertTrue(result.text.contains("OrangeLen 中文🍊"), ext)
            XCTAssertTrue(result.text.contains("<plist"), ext)
            XCTAssertEqual(try PropertyListSerialization.propertyList(from: Data(result.text.utf8), format: nil) as? NSDictionary,
                           try PropertyListSerialization.propertyList(from: data, format: nil) as? NSDictionary)
        }
        XCTAssertNil(try BinarySourcePreview.text(Data([0, 255]), extension: "pl"))
        XCTAssertThrowsError(try BinarySourcePreview.text(Data("bplist00broken".utf8), extension: "plist"))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try BinarySourcePreview.text(Data(), extension: "plist", cancellation: token))
    }
    func testJavaClassDisplaysMembersAndCodeRejectsEveryTruncation() throws {
        let data = try Data(contentsOf: fixtures.appendingPathComponent("sample.class"))
        let text = try JavaClassPreview.parse(data)
        XCTAssertTrue(text.contains("OrangeParity extends java.lang.Object"))
        XCTAssertTrue(text.contains("method <init> : ()V"))
        XCTAssertTrue(text.contains("2a b7 00 08 b1"))
        for count in 0..<data.count { XCTAssertThrowsError(try JavaClassPreview.parse(Data(data.prefix(count))), "length=\(count)") }
        XCTAssertThrowsError(try JavaClassPreview.parse(data + Data([0])))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try JavaClassPreview.parse(data, cancellation: token))
    }
    func testJavaInterfaceNamesRespectOutputBudget() throws {
        var data = Data([0xca, 0xfe, 0xba, 0xbe, 0, 0, 0, 52])
        func u2(_ value: Int) { data.append(contentsOf: [UInt8(value >> 8), UInt8(value & 255)]) }
        u2(3) // Constant pool: one long name and one class reference.
        data.append(1); u2(16384); data.append(Data(repeating: 65, count: 16384))
        data.append(7); u2(1)
        u2(0x21); u2(2); u2(0); u2(128)
        for _ in 0..<128 { u2(2) }
        u2(0); u2(0); u2(0)
        XCTAssertThrowsError(try JavaClassPreview.parse(data)) { error in
            guard case PreviewError.limit = error else { return XCTFail("Expected output budget, got \(error)") }
        }
    }
    func testAmbiguousSuffixesAndBinaryAutoItRemainExplicit() throws {
        XCTAssertTrue(SourceCodeFormats.isSQLTypeDefinition("-- comment\nCREATE OR REPLACE TYPE OrangeLen AS OBJECT (value NUMBER);"))
        XCTAssertFalse(SourceCodeFormats.isSQLTypeDefinition("= OrangeLen\n#let value = 42\n"))
        let bytes = try Data(contentsOf: fixtures.appendingPathComponent("binary.a3x"))
        let result = try XCTUnwrap(BinarySourcePreview.text(bytes, extension: "a3x"))
        XCTAssertTrue(result.text.contains("decompilation is unavailable"))
        XCTAssertTrue(result.text.contains("41 55 33"))
    }
}
