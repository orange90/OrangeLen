import Foundation

/// XMind workbook content is read directly from its ZIP; no members are extracted.
public enum XMindDocument {
    public static func load(_ url: URL, root: URL?, cancellation: Cancellation = .init()) throws -> DiagramDocument {
        var limits = PreviewLimits(); limits.fileBytes = limits.containerBytes
        let data = try AccessBroker.readBytes(url, root: root, limits: limits, cancellation: cancellation).data
        return try parse(data, cancellation: cancellation)
    }

    public static func parse(_ data: Data, cancellation: Cancellation = .init()) throws -> DiagramDocument {
        try cancellation.check()
        let archive = try ArchiveDocument.parse(data, name: "workbook.xmind", cancellation: cancellation)
        let sheets: [[String: Any]]
        if let entry = archive.entry("content.json") {
            let bytes = try archive.read(entry, cancellation: cancellation)
            let source = try AccessBroker.decode(bytes).0
            _ = try JSONParser.parse(source, cancellation: cancellation)
            guard let value = try JSONSerialization.jsonObject(with: bytes) as? [[String: Any]] else { throw PreviewError.malformed("XMind sheets") }
            sheets = value
        } else if let entry = archive.entry("content.xml") {
            let source = try AccessBroker.decode(archive.read(entry, cancellation: cancellation)).0
            let root = try BoundedXML.parse(source, token: cancellation)
            guard root.name == "xmap-content" else { throw PreviewError.malformed("XMind XML root") }
            func topic(_ node: BoundedXML.Node) -> [String: Any] {
                let groups = node.children.first { $0.name == "children" }?.children.filter { $0.name == "topics" } ?? []
                var children: [String: [[String: Any]]] = [:]
                for group in groups { children[group.attributes["type"] ?? "attached", default: []] += group.children.filter { $0.name == "topic" }.map(topic) }
                return ["id": node.attributes["id"] ?? "", "title": node.children.first { $0.name == "title" }?.text ?? "", "children": children]
            }
            sheets = try root.children.filter { $0.name == "sheet" }.map { sheet in
                try cancellation.check()
                guard let rootTopic = sheet.children.first(where: { $0.name == "topic" }) else { throw PreviewError.malformed("XMind root topic") }
                let relationships = sheet.children.first { $0.name == "relationships" }?.children.filter { $0.name == "relationship" }.map { relation -> [String: Any] in
                    ["end1Id": relation.attributes["end1"] ?? "", "end2Id": relation.attributes["end2"] ?? "", "title": relation.children.first { $0.name == "title" }?.text ?? ""]
                } ?? []
                return ["title": sheet.children.first { $0.name == "title" }?.text ?? "", "rootTopic": topic(rootTopic), "relationships": relationships]
            }
        } else { throw PreviewError.malformed("XMind: missing content.json / content.xml") }
        guard !sheets.isEmpty, sheets.count <= 50 else { throw PreviewError.limit("XMind sheets (1–50)") }
        var total = 0
        let pages = try sheets.enumerated().map { pageIndex, sheet -> DiagramDocument.Page in
            try cancellation.check()
            guard let root = sheet["rootTopic"] as? [String: Any] else { throw PreviewError.malformed("XMind root topic") }
            var boxes: [DiagramDocument.Box] = [], edges: [DiagramDocument.Edge] = [], row = 0
            func walk(_ topic: [String: Any], depth: Int, parent: String?) throws -> Double {
                try cancellation.check(); total += 1
                guard total <= 2000, depth <= 48 else { throw PreviewError.limit("XMind topics/depth") }
                let id = topic["id"] as? String ?? "", title = topic["title"] as? String ?? ""
                guard !id.isEmpty, title.utf8.count <= 65536 else { throw PreviewError.malformed("XMind topic ID/title") }
                let index = boxes.count
                boxes.append(.init(id: id, text: title, color: depth == 0 ? "2" : "5", shape: "node", x: Double(depth) * 300, y: 0, width: 250, height: 90, file: nil))
                if let parent { edges.append(.init(from: parent, to: id, label: "")) }
                let groups = topic["children"] as? [String: Any] ?? [:]
                var positions: [Double] = []
                for key in groups.keys.sorted() {
                    guard let children = groups[key] as? [[String: Any]] else { throw PreviewError.malformed("XMind children") }
                    for child in children { positions.append(try walk(child, depth: depth + 1, parent: key == "detached" ? nil : id)) }
                }
                let y: Double
                if let first = positions.first, let last = positions.last { y = (first + last) / 2 }
                else { y = Double(row) * 120; row += 1 }
                boxes[index].y = y
                return y
            }
            _ = try walk(root, depth: 0, parent: nil)
            let relationships = sheet["relationships"] as? [[String: Any]] ?? []
            guard relationships.count <= 3000 else { throw PreviewError.limit("XMind relationships") }
            for relation in relationships {
                try cancellation.check()
                edges.append(.init(from: relation["end1Id"] as? String ?? "", to: relation["end2Id"] as? String ?? "", label: String((relation["title"] as? String ?? "").prefix(160))))
            }
            try DiagramDocument.bounded(boxes, edges)
            return .init(title: sheet["title"] as? String ?? "Sheet \(pageIndex + 1)", boxes: boxes, edges: edges)
        }
        return .init(kind: "XMind", pages: pages, notice: "Tree layout · topics and relationships · original styles, images, attachments, notes and summaries are not rendered")
    }
}
