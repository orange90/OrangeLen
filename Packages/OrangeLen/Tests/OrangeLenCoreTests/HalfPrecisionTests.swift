import XCTest
@testable import OrangeLenCore

final class HalfPrecisionTests: XCTestCase {
    func testIEEEValuesOnEveryArchitecture() {
        let pairs: [(UInt16, UInt32)] = [(0,0),(0x8000,0x80000000),(0x0001,0x33800000),
            (0x03ff,0x387fc000),(0x0400,0x38800000),(0x3c00,0x3f800000),
            (0xc000,0xc0000000),(0x7bff,0x477fe000),(0x7c00,0x7f800000),(0xfc00,0xff800000)]
        for (input, expected) in pairs { XCTAssertEqual(HalfPrecision.float(bitPattern:input).bitPattern, expected) }
        XCTAssertTrue(HalfPrecision.float(bitPattern:0x7e00).isNaN)
        #if arch(arm64)
        for bits in UInt32(0)...UInt32(UInt16.max) {
            let input = UInt16(bits), native = Float(Float16(bitPattern:input)), portable = HalfPrecision.float(bitPattern:input)
            if native.isNaN { XCTAssertTrue(portable.isNaN) }
            else { XCTAssertEqual(portable.bitPattern,native.bitPattern) }
        }
        #endif
    }
}
