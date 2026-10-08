import XCTest
import AppKit
@testable import OrangeLenUI

@MainActor final class GlassSurfaceTests: XCTestCase {
    func testAccessibilityFallbackPreservesContentAndLayout() {
        _ = NSApplication.shared
        let content = NSButton(title: "Refresh", target: nil, action: nil)
        let surface = GlassSurface(content: content, inset: 8)
        surface.frame = NSRect(x: 0, y: 0, width: 240, height: 500)
        for enabled in [false, true, false, true, false] {
            surface.setGlassEnabled(enabled); surface.layoutSubtreeIfNeeded()
            XCTAssertTrue(content.isDescendant(of: surface))
            XCTAssertEqual(surface.subviews.count, 1)
            if !enabled {
                XCTAssertFalse(surface.usesGlass)
                XCTAssertEqual(content.frame.size, NSSize(width: 224, height: 484))
            } else if #available(macOS 26.0, *) { XCTAssertTrue(surface.usesGlass) }
        }
    }
}
