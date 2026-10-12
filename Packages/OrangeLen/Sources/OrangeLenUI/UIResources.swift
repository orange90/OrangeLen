import Foundation
import OrangeLenCore

enum UIResources {
    private static let bundle = PackageResources.bundle(.ui, fallback: Bundle.module)
    static func url(forResource name: String, withExtension ext: String) -> URL? {
        guard !name.contains("/"), !ext.contains("/"), name != ".." else { return nil }
        return bundle?.resourceURL?.appendingPathComponent(name + "." + ext)
    }
}
