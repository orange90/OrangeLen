import Foundation
import Yams

/// Offline summaries. Content detection is deliberately narrow; unknown documents remain source.
public enum DeveloperReports {
    public static func parse(_ source: String, name: String, cancellation: Cancellation = .init()) throws -> ScientificDocument? {
        guard source.utf8.count <= 1024 * 1024 else { throw PreviewError.limit("Report 1 MiB") }
        try cancellation.check()
        let ext = (name as NSString).pathExtension.lowercased()
        if ext == "xml" {
            guard source.range(of: #"<(?:testsuites|testsuite)(?:\s|>)"#, options: .regularExpression) != nil else { return nil }
            let root = try BoundedXML.parse(source, token: cancellation)
            guard ["testsuite", "testsuites"].contains(root.name) else { return nil }
            let cases = root.descendants("testcase")
            guard cases.count <= 5000 else { throw PreviewError.limit("JUnit 5,000 cases") }
            var failed = 0, skipped = 0, errors = 0
            let rows = try cases.map { item -> [String] in
                try cancellation.check()
                let failure = item.children.first { ["failure", "error", "skipped"].contains($0.name) }
                let status = failure?.name ?? "passed"
                if status == "failure" { failed += 1 }; if status == "error" { errors += 1 }; if status == "skipped" { skipped += 1 }
                let detail = [failure?.attributes["message"] ?? "", failure?.text ?? ""].filter { !$0.isEmpty }.joined(separator: "\n")
                return [status, item.attributes["classname"] ?? "", item.attributes["name"] ?? "", item.attributes["time"] ?? "", detail]
            }
            return .init(title: "JUnit", summary: "JUnit test report\n\(rows.count) cases · \(rows.count - failed - skipped - errors) passed · \(failed) failures · \(errors) errors · \(skipped) skipped\nCounts derived from test cases; source retained. Time is reported seconds.", columns: ["Status", "Class", "Test", "Seconds", "Message / stack"], rows: rows)
        }
        let object: [String: Any]
        if ["yaml", "yml"].contains(ext) {
            guard source.range(of: #"(?m)^\s*(openapi|swagger)\s*:"#, options: .regularExpression) != nil else { return nil }
            // Compose without converting aliases into native recursive objects.
            guard source.range(of: #"(?:^|\s)[&*][A-Za-z0-9_-]+"#, options: .regularExpression) == nil else { throw PreviewError.malformed("YAML aliases are not supported") }
            guard let node = try Yams.compose(yaml: source) else { return nil }
            var count = 0
            func check(_ node: Yams.Node, depth: Int) throws {
                try cancellation.check(); count += 1
                guard depth <= 48, count <= 20000 else { throw PreviewError.limit("YAML structure") }
                switch node {
                case .scalar: break
                case .sequence(let sequence): for child in sequence { try check(child, depth: depth + 1) }
                case .mapping(let mapping): for (key, value) in mapping { try check(key, depth: depth + 1); try check(value, depth: depth + 1) }
                }
            }
            try check(node, depth: 0)
            object = try Yams.load(yaml: source) as? [String: Any] ?? [:]
        } else {
            guard ["json", "sarif"].contains(ext), ext == "sarif" || source.contains("\"runs\"") || source.contains("\"openapi\"") || source.contains("\"swagger\"") else { return nil }
            _ = try JSONParser.parse(source, cancellation: cancellation)
            object = try JSONSerialization.jsonObject(with: Data(source.utf8)) as? [String: Any] ?? [:]
        }
        if let runs = object["runs"] as? [[String: Any]], let version = object["version"] as? String, version.hasPrefix("2.") {
            var rows: [[String]] = []
            for run in runs {
                let tool = ((run["tool"] as? [String: Any])?["driver"] as? [String: Any])?["name"] as? String ?? ""
                for result in run["results"] as? [[String: Any]] ?? [] {
                    try cancellation.check(); guard rows.count < 5000 else { throw PreviewError.limit("SARIF 5,000 results") }
                    let location = (result["locations"] as? [[String: Any]])?.first?["physicalLocation"] as? [String: Any] ?? [:]
                    let artifact = location["artifactLocation"] as? [String: Any] ?? [:]
                    let region = location["region"] as? [String: Any] ?? [:]
                    let message = result["message"] as? [String: Any] ?? [:]
                    rows.append([result["level"] as? String ?? "default", result["ruleId"] as? String ?? "", artifact["uri"] as? String ?? "", region["startLine"].map { String(describing: $0) } ?? "", message["text"] as? String ?? message["markdown"] as? String ?? "", tool])
                }
            }
            return .init(title: "SARIF", summary: "SARIF \(version)\n\(runs.count) runs · \(rows.count) results\nFirst physical location shown; absent levels are tool defaults. Paths are labels, never opened automatically. Source includes remaining locations and rule details.", columns: ["Level", "Rule", "File", "Line", "Message", "Tool"], rows: rows)
        }
        if object["openapi"] != nil || object["swagger"] != nil {
            guard let paths = object["paths"] as? [String: Any], paths.count <= 1000 else { throw PreviewError.malformed("OpenAPI paths") }
            var rows: [[String]] = []
            for path in paths.keys.sorted() {
                let item = paths[path] as? [String: Any] ?? [:]
                for method in ["get", "post", "put", "patch", "delete", "head", "options", "trace"] {
                    try cancellation.check()
                    guard let operation = item[method] as? [String: Any] else { continue }
                    rows.append([method.uppercased(), path, operation["summary"] as? String ?? "", operation["operationId"] as? String ?? "", (operation["responses"] as? [String: Any] ?? [:]).keys.sorted().joined(separator: ", ")])
                }
            }
            let info = object["info"] as? [String: Any] ?? [:]
            return .init(title: "OpenAPI", summary: "OpenAPI · \(info["title"] as? String ?? "API")\n\(rows.count) operations · \(paths.count) paths\nRead-only summary; parameter/schema definitions remain in source. External $ref is not resolved.", columns: ["Method", "Path", "Summary", "Operation", "Responses"], rows: rows)
        }
        if ext == "sarif" { throw PreviewError.malformed("Expected SARIF 2.x runs") }
        return nil
    }
}

public enum DeveloperPackage {
    public static func summary(_ archive: ArchiveDocument, name: String, cancellation: Cancellation = .init()) throws -> String {
        func read(_ path: String) throws -> String {
            guard let entry = archive.entry(path) else { throw PreviewError.malformed("Missing package metadata: \(path)") }
            let data = try archive.read(entry, cancellation: cancellation)
            guard data.count <= 1024 * 1024 else { throw PreviewError.limit("Package metadata 1 MiB") }
            return try AccessBroker.decode(data).0
        }
        if name.lowercased().hasSuffix(".whl") {
            let candidates = archive.entries.filter { $0.path.hasSuffix(".dist-info/METADATA") }
            guard candidates.count == 1, let entry = candidates.first else { throw PreviewError.malformed("Wheel requires one dist-info/METADATA") }
            let metadata = try read(entry.path), directory = String(entry.path.dropLast("METADATA".count))
            let wheel = try read(directory + "WHEEL")
            let headers = metadata.components(separatedBy: "\n\n").first ?? metadata
            return "Python wheel · \(name)\n\(archive.entries.count) archive entries · not installed or executed\n\n" + headers + "\n\nWHEEL\n" + wheel
        }
        let source = try read("extension/package.json")
        _ = try JSONParser.parse(source, cancellation: cancellation)
        guard let object = try JSONSerialization.jsonObject(with: Data(source.utf8)) as? [String: Any], object["name"] is String, object["version"] is String else { throw PreviewError.malformed("VSIX extension/package.json") }
        var text = "VS Code VSIX · \(name)\n\(archive.entries.count) archive entries · not installed or executed\n\n"
        for key in ["displayName", "name", "version", "publisher", "description", "main", "browser"] { if let value = object[key] { text += "\(key): \(value)\n" } }
        text += "\nManifest\n" + source
        return text
    }
}
