import Foundation
import UniformTypeIdentifiers

// Read-only audit of the installed product and actual filesystem UTIs.
// A matching declaration is candidate eligibility, never proof of Finder rendering.
guard CommandLine.arguments.count == 4 else {
    fputs("Usage: xcrun swift scripts/audit-format-dispatch.swift APP FIXTURES docs/format-count.md\n", stderr)
    exit(2)
}
let app = URL(fileURLWithPath: CommandLine.arguments[1])
let fixtures = URL(fileURLWithPath: CommandLine.arguments[2])
let inventory = try String(contentsOfFile: CommandLine.arguments[3], encoding: .utf8)
let expression = try NSRegularExpression(pattern: "`\\.([a-z0-9]+)`")
var extensions: Set<String> = []
for line in inventory.components(separatedBy: .newlines) where line.hasPrefix("|") {
    let text = line as NSString
    for match in expression.matches(in: line, range: NSRange(location: 0, length: text.length)) {
        extensions.insert(text.substring(with: match.range(at: 1)))
    }
}
guard extensions.count == 106 else { fatalError("Inventory changed: update audit expectations (\(extensions.count))") }
let plugins = try FileManager.default.contentsOfDirectory(at: app.appendingPathComponent("Contents/PlugIns"), includingPropertiesForKeys: nil)
var candidates: [(String, String, [String])] = []
for plugin in plugins.sorted(by: { $0.path < $1.path }) where plugin.pathExtension == "appex" {
    let bytes = try Data(contentsOf: plugin.appendingPathComponent("Contents/Info.plist"))
    let plist = try PropertyListSerialization.propertyList(from: bytes, format: nil) as! [String: Any]
    let configuration = plist["NSExtension"] as! [String: Any]
    let attributes = configuration["NSExtensionAttributes"] as! [String: Any]
    candidates.append((plugin.lastPathComponent, plist["OrangeLenPreviewCategory"] as! String,
                       attributes["QLSupportedContentTypes"] as! [String]))
}
print("extension\tactual_uti\tcandidate_extensions\tcategories\tmatched_declarations\tresult")
var missing: [String] = []
for ext in extensions.sorted() {
    let file = fixtures.appendingPathComponent(ext == "gz" ? "audit.log.gz" : "audit." + ext)
    // Do not replace filesystem type with UTType(filenameExtension:) or a source-code hint.
    let type = try file.resourceValues(forKeys: [.contentTypeKey]).contentType
    var matches: [(String, String, String)] = []
    for (plugin, category, declarations) in candidates {
        for declaration in declarations {
            if let type, type.identifier == declaration || UTType(declaration).map({ type.conforms(to: $0) }) == true {
                matches.append((plugin, category, declaration))
            }
        }
    }
    let eligible = !matches.isEmpty
    if !eligible { missing.append(ext) }
    func joined(_ values: [String]) -> String { Set(values).sorted().joined(separator: ",") }
    print([ext, type?.identifier ?? "unknown", joined(matches.map { $0.0 }),
           joined(matches.map { $0.1 }), joined(matches.map { $0.2 }),
           eligible ? "candidate-only" : "NO-CANDIDATE"].joined(separator: "\t"))
}
fputs("\(extensions.count) extensions; \(missing.count) without candidate: \(missing.joined(separator: ","))\n", stderr)
if !missing.isEmpty { exit(1) }
