import Foundation

/// Reads the topic structure without extracting archive members or following links.
public enum MindManagerDocument {
    public static func load(_ url: URL, root: URL?, cancellation: Cancellation = .init()) throws -> DiagramDocument {
        var limits = PreviewLimits(); limits.fileBytes = limits.containerBytes
        return try parse(AccessBroker.readBytes(url, root: root, limits: limits, cancellation: cancellation).data, cancellation: cancellation)
    }
    public static func parse(_ data: Data, cancellation: Cancellation = .init()) throws -> DiagramDocument {
        try cancellation.check()
        let archive = try ArchiveDocument.parse(data, name: "map.mmap", cancellation: cancellation)
        guard let entry = archive.entry("Document.xml") else { throw PreviewError.malformed("MindManager: missing Document.xml (encrypted/legacy maps are unsupported)") }
        let source = try AccessBroker.decode(archive.read(entry, cancellation: cancellation)).0
        return try parseXML(source, cancellation: cancellation)
    }
    static func parseXML(_ source: String, cancellation: Cancellation = .init()) throws -> DiagramDocument {
        let root = try BoundedXML.parse(source, token: cancellation)
        func name(_ node: BoundedXML.Node) -> String { String(node.name.split(separator: ":").last ?? "") }
        func children(_ node: BoundedXML.Node, _ tag: String) -> [BoundedXML.Node] { node.children.filter { name($0) == tag } }
        guard name(root) == "Map" else { throw PreviewError.malformed("MindManager Map root") }
        let roots = children(root, "OneTopic").flatMap { children($0, "Topic") }
            + children(root, "FloatingTopics").flatMap { children($0, "Topic") }
        guard !roots.isEmpty else { throw PreviewError.malformed("MindManager root topic") }
        var boxes: [DiagramDocument.Box] = [], edges: [DiagramDocument.Edge] = [], ids = Set<String>(), row = 0
        func walk(_ node: BoundedXML.Node, depth: Int, parent: String?) throws -> Double {
            try cancellation.check()
            guard boxes.count < 2000, depth <= 48 else { throw PreviewError.limit("MindManager topics/depth") }
            if let oid = node.attributes["OId"], !oid.isEmpty {
                guard ids.insert(oid).inserted else { throw PreviewError.malformed("MindManager duplicate topic ID") }
            }
            let index = boxes.count, id = "topic-\(boxes.count)"
            let title = children(node, "Text").first?.attributes["PlainText"] ?? ""
            guard title.utf8.count <= 65536 else { throw PreviewError.limit("MindManager title") }
            boxes.append(.init(id: id, text: title, color: depth == 0 ? "2" : "5", shape: "node", x: Double(depth) * 300, y: 0, width: 250, height: 90, file: nil))
            if let parent { edges.append(.init(from: parent, to: id, label: "")) }
            var positions: [Double] = []
            for group in children(node, "SubTopics") {
                for child in children(group, "Topic") { positions.append(try walk(child, depth: depth + 1, parent: id)) }
            }
            let y: Double
            if let first = positions.first, let last = positions.last { y = (first + last) / 2 }
            else { y = Double(row) * 120; row += 1 }
            boxes[index].y = y
            return y
        }
        for topic in roots { _ = try walk(topic, depth: 0, parent: nil); row += 1 }
        try DiagramDocument.bounded(boxes, edges)
        return .init(kind: "MindManager", pages: [.init(title: "MindManager", boxes: boxes, edges: edges)], notice: "Automatic topic tree · original styles, relationships, notes, tasks and attachments omitted · links never fetched")
    }
}
