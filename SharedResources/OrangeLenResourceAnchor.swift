import Foundation

/// A stable Objective-C anchor lets SwiftPM code find this loaded framework
/// without introducing an Xcode-only module dependency into the package.
@objc(OrangeLenResourceAnchor)
public final class OrangeLenResourceAnchor: NSObject { }
