import XCTest
import AppKit
import OrangeLenCore
@testable import OrangeLenUI
@MainActor final class DeveloperPreviewTests: XCTestCase {
    func fixture(_ name: String) -> URL { URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/developer-batch1/"+name) }
    func open(_ reader:ReaderController,_ name:String) async {let ready=expectation(description:name);reader.open(fixture(name)){error in XCTAssertNil(error,name);ready.fulfill()};await fulfillment(of:[ready],timeout:40)}
    func testArrowFileStreamAndCompression() async throws {
        _=NSApplication.shared;let reader=ReaderController();reader.loadViewIfNeeded();defer{reader.close()}
        for file in ["dataset.arrow","stream.ipc","compressed.feather","zstd.feather"] {
            await open(reader,file);let view=try XCTUnwrap(reader.advancedView as? ScientificPreview,file)
            XCTAssertTrue(view.summary.string.contains("3 rows"),file);XCTAssertTrue(view.table.data.rows.flatMap{$0}.contains{$0.value.contains("中文样本")},file)
        }
    }
    func testReportsModelPackagesAndSourceSwitch() async throws {
        _=NSApplication.shared;let reader=ReaderController();reader.loadViewIfNeeded();defer{reader.close()}
        for file in ["junit.xml","scan.sarif","api.yaml","model.onnx"] {await open(reader,file);XCTAssertNotNil(reader.advancedView as? ScientificPreview,file)
            if file == "junit.xml" { let report = try XCTUnwrap(reader.advancedView as? ScientificPreview); XCTAssertEqual(report.table.data.rows.count, 4); XCTAssertTrue(report.table.data.rows[2][4].value.contains("preview.swift:42")) }
            if file != "model.onnx" {reader.mode.selectedSegment=1;reader.present();XCTAssertEqual(reader.text.string,try String(contentsOf:fixture(file)),file)}
        }
        for file in ["orange_demo-1.0-py3-none-any.whl","orange-demo.vsix"] {await open(reader,file);XCTAssertNotNil(reader.archiveController?.bundleSummary,file)}
        await open(reader,"sample.pyi");XCTAssertNil(reader.advancedView);XCTAssertTrue(reader.text.string.contains("predict"))
    }
    func testDOTSnapshotAndLegacyFeatherFailure() async throws {
        _=NSApplication.shared;let reader=ReaderController();reader.loadViewIfNeeded();defer{reader.close()}
        await open(reader,"architecture.gv");XCTAssertNotNil(reader.canvasImage);reader.mode.selectedSegment=1;reader.present();XCTAssertTrue(reader.text.string.contains("digraph"))
        let failed=expectation(description:"legacy");reader.open(fixture("legacy.feather")){error in XCTAssertNotNil(error);failed.fulfill()};await fulfillment(of:[failed],timeout:40);XCTAssertNil(reader.advancedView)
    }
}
