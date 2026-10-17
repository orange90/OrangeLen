import Foundation

/// Shared by recognition, language selection and the type-declaration generator.
/// A suffix selects a reader, never authorizes execution of its contents.
public enum SourceCodeFormats {
    private struct Manifest: Decodable { let groups: [String: [String]] }
    public static let groups: [String: [String]] = {
        guard let url = PackageResources.bundle(.core, fallback: Bundle.module)?.url(forResource: "SourceCodeFormats", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else { return [:] }
        return manifest.groups
    }()
    public static let extensions = Set(groups.values.flatMap { $0 })
    public static func language(forExtension ext: String) -> String? {
        groups.first { $0.value.contains(ext.lowercased()) }?.key
    }
    public static let propertyListExtensions: Set<String> = ["plist", "loctable", "wflow", "strings", "stringsdict", "entitlements"]
    public static let appleScriptExtensions: Set<String> = ["scpt", "applescript", "ascr"]

    /// Oracle also uses .typ for SQL type definitions.
    public static func isSQLTypeDefinition(_ source: String) -> Bool {
        String(source.prefix(8192)).range(of: #"(?is)^\s*(?:--[^\n]*\n\s*)*(?:create\s+(?:or\s+replace\s+)?(?:type|package|procedure|function)\b|(?:type|package)\s+\w+\s+(?:as|is)\b|declare\b|begin\b)"#, options: .regularExpression) != nil
    }
}
