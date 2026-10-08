import XCTest
import AppKit
import QuickLookUI
import OrangeLenCore
@testable import OrangeLenUI

@MainActor final class SystemPreviewTests: XCTestCase {
    func testSystemFormatFamiliesAndExistingFormats() {
        for ext in ["mp4", "mov", "m4v", "mp3", "m4a", "wav", "aiff", "doc", "DOCX", "xlsx", "pptx", "pages", "numbers", "key", "rtf", "rtfd", "heic", "tiff", "usdz"] {
            XCTAssertTrue(SystemPreviewFormat.supports(URL(fileURLWithPath: "/tmp/example.\(ext)")), ext)
        }
        for ext in ["swift", "ts", "md", "json", "ipynb", "epub", "excalidraw", "zip", "unknownbinary"] {
            XCTAssertFalse(SystemPreviewFormat.supports(URL(fileURLWithPath: "/tmp/example.\(ext)")), ext)
        }
    }

    func requireBrokerHost() throws {
        try XCTSkipIf(Bundle.main.bundleURL.lastPathComponent != "OrangeLenTestHost.app", "Run scripts/test-native.sh for real sandboxed XPC + media integration")
    }
    func testFolderHandoffSwitchAndClose() async throws {
        try requireBrokerHost()
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let rich = root.appendingPathComponent("sample.rtf")
        try Data("{\\rtf1\\ansi Native rich text}".utf8).write(to: rich)
        let text = root.appendingPathComponent("sample.md")
        try Data("Back to text".utf8).write(to: text)
        let reader = ReaderController(); reader.previewCategory = PreviewCategory.folders.rawValue
        reader.open(root) { XCTAssertNil($0) }
        let richLoaded = expectation(description: "rich text")
        reader.loadFile(rich) { XCTAssertNil($0); richLoaded.fulfill() }
        await fulfillment(of: [richLoaded], timeout: 45)
        let first = try XCTUnwrap(reader.nativeDocumentPreview)
        XCTAssertTrue(reader.currentContent === first)
        XCTAssertEqual((first.documentView as? NSTextView)?.string, "Native rich text")
        XCTAssertNil(reader.source)
        let loaded = expectation(description: "text after system preview")
        reader.loadFile(text) { XCTAssertNil($0); loaded.fulfill() }
        await fulfillment(of: [loaded], timeout: 45)
        XCTAssertNil(reader.systemPreview)
        XCTAssertNil(first.superview)
        XCTAssertEqual(reader.source?.text, "Back to text")
        XCTAssertTrue(reader.mode.isEnabled)
        reader.loadFile(rich) { XCTAssertTrue($0 is CancellationError) }
        XCTAssertNil(reader.nativeDocumentPreview) // Loading asynchronously; closing cancels the importer.
        reader.close()
        XCTAssertNil(reader.systemPreview)
        XCTAssertNil(reader.systemPreviewScope)
    }

    func fixture(_ name: String) -> URL {
        #if SWIFT_PACKAGE
        return URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/system-preview/" + name)
        #else
        // A test host must read its own bundled fixtures, not require access to the developer's Documents folder.
        return Bundle(for: SystemPreviewTests.self).resourceURL!.appendingPathComponent("system-preview/" + name)
        #endif
    }

    func testWordAndMediaContentsAndCleanup() async throws {
        try requireBrokerHost()
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded()
        let ready = expectation(description: "Word")
        reader.open(fixture("sample.docx")) { XCTAssertNil($0); ready.fulfill() }
        await fulfillment(of: [ready], timeout: 45)
        XCTAssertTrue((reader.nativeDocumentPreview?.documentView as? NSTextView)?.string.contains("Rich text works.") == true)
        reader.loadFile(fixture("sample.mp4")) { XCTAssertNil($0) }
        let player = try XCTUnwrap(reader.mediaPreview?.player)
        XCTAssertNil(reader.nativeDocumentPreview)
        let duration = try await XCTUnwrap(player.currentItem).asset.load(.duration)
        XCTAssertEqual(duration.seconds, 3, accuracy: 0.1)
        reader.loadFile(fixture("sample.m4a")) { XCTAssertNil($0) }
        XCTAssertNil(player.currentItem)
        let audio = try XCTUnwrap(reader.mediaPreview?.player)
        reader.close()
        XCTAssertNil(audio.currentItem); XCTAssertNil(reader.mediaPreview)
    }

    func testOfficeContentAndImageFamilies() throws {
        let sheet = try OfficeContentPreview.text(Data(contentsOf: fixture("sample.xlsx")))
        XCTAssertTrue(sheet.contains("A1\tOrangeLens"))
        XCTAssertTrue(sheet.contains("C3\t42"))
        XCTAssertTrue(sheet.contains("公式：40+2"))
        let slides = try OfficeContentPreview.text(Data(contentsOf: fixture("sample.pptx")))
        XCTAssertTrue(slides.contains("Slide preview works"))
        for ext in ["png", "jpg", "heic", "tiff", "psd", "avif"] {
            XCTAssertTrue(ImagePreview.supports(URL(fileURLWithPath: "/tmp/sample.\(ext)")), ext)
        }
        XCTAssertFalse(ImagePreview.supports(URL(fileURLWithPath: "/tmp/sample.svg")))
    }

    func testSystemPreviewRejectsEscapingSymlink() throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let link = root.appendingPathComponent("escape.docx")
        try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: "/etc/hosts")
        let reader = ReaderController(); reader.loadViewIfNeeded(); reader.rootURL = root
        var failed = false
        reader.loadFile(link) { failed = $0 != nil }
        XCTAssertTrue(failed); XCTAssertNil(reader.systemPreview)
        reader.close()
    }
}
