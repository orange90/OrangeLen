import Foundation

/// IEEE 754 binary16 decoded into binary32, including subnormals and signed zero.
/// Swift's Float16 is unavailable on Intel macOS; all binary16 values fit Float.
enum HalfPrecision {
    static func float(bitPattern bits: UInt16) -> Float {
        let sign = UInt32(bits & 0x8000) << 16
        let exponent = UInt32((bits >> 10) & 31)
        var fraction = UInt32(bits & 1023)
        if exponent == 31 { return Float(bitPattern: sign | 0x7f800000 | (fraction << 13)) }
        if exponent != 0 { return Float(bitPattern: sign | ((exponent + 112) << 23) | (fraction << 13)) }
        if fraction == 0 { return Float(bitPattern: sign) }
        var normalizedExponent: UInt32 = 113
        while fraction & 1024 == 0 { fraction <<= 1; normalizedExponent -= 1 }
        return Float(bitPattern: sign | (normalizedExponent << 23) | ((fraction & 1023) << 13))
    }
}
