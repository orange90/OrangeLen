import Foundation

/// Shared by the app, Quick Look extensions, and helper services. Resolve once per
/// process, like native macOS localization; reopen the app/preview after changing language.
public enum L10n {
    public static let supportedLanguages = ["en", "zh-Hans"]
    public static func language(for preferences: [String]) -> String {
        Bundle.preferredLocalizations(from: supportedLanguages, forPreferences: preferences).first ?? "en"
    }
    public static let currentLanguage = language(for: Locale.preferredLanguages)
    private static let currentBundle = resourceBundle(language: currentLanguage)

    private static func resourceBundle(language: String) -> Bundle {
        let selected = supportedLanguages.contains(language) ? language : "en"
        // SwiftPM normalizes localization directory names (zh-Hans → zh-hans).
        let directory = Bundle.module.localizations.first { $0.caseInsensitiveCompare(selected) == .orderedSame } ?? selected
        guard let url = Bundle.module.resourceURL?.appendingPathComponent(directory + ".lproj"),
              let bundle = Bundle(url: url) else { return Bundle.module }
        return bundle
    }

    public static func text(_ message: Message) -> String {
        render(message, bundle: currentBundle)
    }

    // Explicit language is useful for deterministic tests without changing global preferences.
    static func text(_ message: Message, language: String) -> String {
        render(message, bundle: resourceBundle(language: language))
    }

    private static func render(_ message: Message, bundle: Bundle) -> String {
        let template = bundle.localizedString(forKey: message.key, value: message.key, table: nil)
        // Scan only the template. File names / user text containing placeholders or percent
        // signs are inserted verbatim and never interpreted as another formatting directive.
        var result = "", cursor = template.startIndex
        while cursor < template.endIndex {
            if template[cursor] == "{", let end = template[cursor...].firstIndex(of: "}"),
               let index = Int(template[template.index(after: cursor)..<end]),
               message.arguments.indices.contains(index) {
                result += message.arguments[index]
                cursor = template.index(after: end)
            } else {
                result.append(template[cursor]); cursor = template.index(after: cursor)
            }
        }
        return result
    }

    public struct Message: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
        let key: String
        let arguments: [String]
        public init(stringLiteral value: String) { key = value; arguments = [] }
        public init(stringInterpolation: StringInterpolation) {
            key = stringInterpolation.key; arguments = stringInterpolation.arguments
        }
        public struct StringInterpolation: StringInterpolationProtocol {
            var key = ""
            var arguments: [String] = []
            public init(literalCapacity: Int, interpolationCount: Int) {
                key.reserveCapacity(literalCapacity); arguments.reserveCapacity(interpolationCount)
            }
            public mutating func appendLiteral(_ literal: String) { key += literal }
            public mutating func appendInterpolation<T>(_ value: T) {
                key += "{\(arguments.count)}"; arguments.append(String(describing: value))
            }
        }
    }
}
