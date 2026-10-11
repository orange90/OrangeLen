import XCTest
@testable import OrangeLenCore

final class AIOutputFormatsTests: XCTestCase {
    func fixture(_ name: String) throws -> Data {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: root.appendingPathComponent("Tests/Fixtures/ai-outputs/" + name))
    }
    func testSubtitlesPreserveCRLFMultilineRangesAndSkipInvalidCue() throws {
        let source = "1\r\n00:00:01,200 --> 00:00:02,500\r\n中文🍊\r\nsecond line\r\n\r\n2\r\n00:00:03,000 --> 00:00:02,000\r\nbad\r\n"
        let document = try SubtitleDocument.parse(source, webVTT: false)
        XCTAssertEqual(document.cues.count, 1); XCTAssertEqual(document.rejected, 1)
        XCTAssertEqual(document.duration, 2500)
        XCTAssertEqual(document.cues[0].text, "中文🍊\nsecond line")
        XCTAssertEqual((source as NSString).substring(with: document.cues[0].textRange), "中文🍊\r\nsecond line")
        XCTAssertEqual(document.table.rows[1][0].value, "00:00:01.200")
        _ = document.table.textModel(source: source) // All generated cells have valid original ranges.
    }
    func testVTTHeadersSettingsNotesAndLiteralMarkup() throws {
        let document = try SubtitleDocument.parse(String(decoding: fixture("captions.vtt"), as: UTF8.self), webVTT: true)
        XCTAssertEqual(document.cues.count, 2); XCTAssertEqual(document.rejected, 0)
        XCTAssertTrue(document.cues[0].text.contains("<v Orange>"))
        XCTAssertThrowsError(try SubtitleDocument.parse("00:00.000 --> 00:02.000\nx", webVTT: true))
        XCTAssertThrowsError(try SubtitleDocument.parse("1\n00:99:00,000 --> 01:00:00,000\nx", webVTT: false))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try SubtitleDocument.parse("WEBVTT", webVTT: true, cancellation: token))
    }
    func testSubtitleCueBudgetAndOverlaps() throws {
        let cue = "00:00.000 --> 00:02.000\nx\n\n"
        XCTAssertEqual(try SubtitleDocument.parse("WEBVTT\n\n" + cue + cue, webVTT: true).cues.count, 2)
        XCTAssertThrowsError(try SubtitleDocument.parse("WEBVTT\n\n" + String(repeating: cue, count: 5001), webVTT: true))
    }
    func testMCPBAndDXTUseValidatedZipAndRootManifest() throws {
        for ext in ["mcpb", "dxt"] {
            let url = URL(fileURLWithPath: "sample." + ext)
            XCTAssertEqual(PreviewCategory.detect(url), .archives); XCTAssertTrue(ReadableFormat.isCollection(url))
            let archive = try ArchiveDocument.parse(fixture("sample." + ext), name: url.lastPathComponent)
            let summary = try MCPBundle.summary(archive)
            XCTAssertTrue(summary.contains("preview-example")); XCTAssertTrue(summary.contains("server/index.js")); XCTAssertTrue(summary.contains("user_config"))
            XCTAssertTrue(String(decoding: try archive.read(XCTUnwrap(archive.entry("server/index.js"))), as: UTF8.self).contains("console.log"))
        }
        let missing = try ArchiveDocument.parse(fixture("sample.mcpb"), name: "sample.mcpb", limits: { var limits = PreviewLimits(); limits.archiveEntryBytes = 4; return limits }())
        XCTAssertThrowsError(try MCPBundle.summary(missing))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try MCPBundle.summary(ArchiveDocument.parse(fixture("sample.mcpb"), name: "sample.mcpb"), cancellation: token))
    }
    func testPNGPlainCompressedAndInternationalMetadata() throws {
        let metadata = try AIImageMetadata.parse(fixture("generation.png"))
        XCTAssertTrue(metadata.warnings.isEmpty)
        XCTAssertTrue(metadata.text.contains("Seed: 42")); XCTAssertTrue(metadata.text.contains("一只橘色小猫"))
        XCTAssertTrue(metadata.text.contains("3.seed: 42")); XCTAssertTrue(metadata.text.contains("example.safetensors"))
        XCTAssertTrue(metadata.fields.contains { $0.name == "workflow" })
        XCTAssertTrue(metadata.fields.contains { $0.name == "prompt" })
    }
    func testWebPExifBothByteOrders() throws {
        for file in ["generation.webp", "generation-big-endian.webp"] {
            let metadata = try AIImageMetadata.parse(fixture(file))
            XCTAssertTrue(metadata.fields.contains { $0.name == "workflow" && $0.value.contains("KSampler") }, file)
        }
        XCTAssertTrue(AIImageMetadata.exifComments(Data([0,1,2])).isEmpty)
    }
    func testMetadataIsOptionalAndCorruptionDoesNotBecomeImageError() throws {
        var data = try fixture("generation.png")
        let range = try XCTUnwrap(data.range(of: Data("parameters".utf8))); data[range.lowerBound + 1] ^= 1
        let metadata = try AIImageMetadata.parse(data)
        XCTAssertFalse(metadata.warnings.isEmpty); XCTAssertFalse(metadata.fields.contains { $0.value.contains("Seed: 42") })
        XCTAssertTrue(metadata.fields.contains { $0.name == "workflow" })
        XCTAssertTrue(try AIImageMetadata.parse(Data()).fields.isEmpty)
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try AIImageMetadata.parse(fixture("generation.png"), cancellation: token))
        var malformed = Data("RIFF".utf8); malformed.append(contentsOf: [255,255,255,255]); malformed.append(Data("WEBP".utf8))
        XCTAssertFalse(try AIImageMetadata.parse(malformed).warnings.isEmpty)
    }
}
