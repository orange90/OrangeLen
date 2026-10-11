import AppKit

/// VS Code-inspired Light+ / Dark+ colors, resolved in the reader's appearance.
enum CodePalette {
    static func color(_ light: UInt32, _ dark: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
        }
    }
    static let background = color(0xFFFFFF, 0x1E1E1E)
    static let foreground = color(0x333333, 0xD4D4D4)
    static let gutter = color(0xF8F8F8, 0x1E1E1E)
    static let lineNumber = color(0x858585, 0x858585)
    static let separator = color(0xEAEAEA, 0x303030)
    static let selection = color(0xADD6FF, 0x264F78)

    static let comment = color(0x008000, 0x6A9955)
    static let string = color(0xA31515, 0xCE9178)
    static let number = color(0x098658, 0xB5CEA8)
    static let keyword = color(0x0000FF, 0x569CD6)
    static let meta = color(0xAF00DB, 0xC586C0)
    static let function = color(0x795E26, 0xDCDCAA)
    static let type = color(0x267F99, 0x4EC9B0)
    static let property = color(0x001080, 0x9CDCFE)
    static let tag = color(0x800000, 0x808080)

    static func token(_ scope: String) -> NSColor {
        if scope.contains("comment") || scope.contains("quote") { return comment }
        if scope.contains("string") || scope.contains("regexp") { return string }
        if scope.contains("number") { return number }
        if scope.contains("keyword") || scope.contains("literal") || scope.contains("name") { return keyword }
        if scope.contains("meta") { return meta }
        if scope.contains("title") && !scope.contains("class") { return function }
        if scope.contains("type") || scope.contains("built_in") || scope.contains("class") { return type }
        if scope.contains("attr") || scope.contains("variable") || scope.contains("property") || scope.contains("params") { return property }
        if scope.contains("tag") { return tag }
        return foreground
    }
}
