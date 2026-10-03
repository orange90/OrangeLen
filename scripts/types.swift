import Foundation
import UniformTypeIdentifiers
for path in CommandLine.arguments.dropFirst() {
    let url = URL(fileURLWithPath: path)
    let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
    print("\(url.lastPathComponent)\t\(type?.identifier ?? "unknown")\t\(type?.supertypes.map(\.identifier).sorted().joined(separator: ",") ?? "")")
}
