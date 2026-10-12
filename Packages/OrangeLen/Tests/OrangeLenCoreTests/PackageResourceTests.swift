import XCTest
@testable import OrangeLenCore

final class PackageResourceTests: XCTestCase {
    func testStandaloneSwiftPMKeepsLocalization() throws {
        let resources = try XCTUnwrap(PackageResources.bundle(.core,fallback:Bundle.module))
        XCTAssertNotNil(resources.url(forResource:"Localizable",withExtension:"strings",subdirectory:nil,localization:"en"))
        XCTAssertEqual(L10n.text("文件夹概览",language:"en"),"Folder Overview")
    }
}
