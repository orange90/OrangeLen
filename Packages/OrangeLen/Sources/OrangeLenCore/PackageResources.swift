import Foundation

/// The app and extensions link the same read-only resource framework. Pure
/// SwiftPM and external test hosts retain their generated module bundles.
public enum PackageResources {
    public enum Kind: String {
        case core = "OrangeLen_OrangeLenCore"
        case ui = "OrangeLen_OrangeLenUI"
    }
    private static let shared: Bundle? = {
        guard let anchor = NSClassFromString("OrangeLenResourceAnchor") else { return nil }
        return Bundle(for: anchor)
    }()

    public static func bundle(_ kind: Kind, fallback: @autoclosure () -> Bundle) -> Bundle? {
        // Do not invoke SwiftPM's fatal-error accessor in a packaged consumer.
        // The linked framework contains both localization and renderer resources.
        if let shared { return shared }
        return fallback()
    }
}
