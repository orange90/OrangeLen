import Foundation
import UniformTypeIdentifiers
let fm = FileManager.default
let input = URL(fileURLWithPath: "build/provider-fixes21/fixtures", isDirectory: true)
let output = URL(fileURLWithPath: "build/remaining11-research/resource-probes", isDirectory: true)
try fm.createDirectory(at: output, withIntermediateDirectories: true)
func actual(_ url: URL) throws -> String { try URL(fileURLWithPath:url.path).resourceValues(forKeys: [.contentTypeKey]).contentType?.identifier ?? "unknown" }
for (name, type) in [("01-ts.ts", "com.microsoft.typescript"), ("02-mts.mts", "com.microsoft.typescript"), ("03-dot.dot", "local.orangelen.diagram")] {
    let url = output.appendingPathComponent(name)
    if fm.fileExists(atPath:url.path) { try fm.removeItem(at:url) }
    try fm.copyItem(at:input.appendingPathComponent(name),to:url)
    let before = try actual(url)
    do {
        try (url as NSURL).setResourceValue(UTType(type) as Any, forKey:.contentTypeKey)
        (url as NSURL).removeAllCachedResourceValues()
        print("\(name)\t\(before)\trequested=\(type)\tsetReturnedSuccess=true\tactual=\(try actual(url))")
    } catch { print("\(name)\t\(before)\terror=\(error)") }
}
