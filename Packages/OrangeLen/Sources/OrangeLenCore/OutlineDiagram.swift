import Foundation

/// Bounded, offline FreeMind/Freeplane and OPML topic trees.
enum OutlineDiagram {
    static func parse(_ source: String, kind: String, cancellation: Cancellation) throws -> DiagramDocument {
        let root = try BoundedXML.parse(source, token: cancellation)
        let opml = kind == "opml"
        guard root.name == (opml ? "opml" : "map") else { throw PreviewError.malformed("Expected \(opml ? "OPML" : "FreeMind") XML") }
        let name = opml ? "outline" : "node"
        let roots: [BoundedXML.Node]
        if opml {
            guard let body = root.children.first(where: { $0.name == "body" }) else { throw PreviewError.malformed("OPML body") }
            roots = body.children.filter { $0.name == name }
        } else { roots = root.children.filter { $0.name == name } }
        guard !roots.isEmpty else { throw PreviewError.malformed("Empty topic tree") }
        var boxes: [DiagramDocument.Box] = [], edges: [DiagramDocument.Edge] = []
        var identifiers: [String: String] = [:], links: [(String, String)] = [], row = 0
        func walk(_ node: BoundedXML.Node, depth: Int, parent: String?) throws -> Double {
            try cancellation.check()
            guard boxes.count < 2000, depth <= 48 else { throw PreviewError.limit("Mind map topics/depth") }
            let id = "topic-\(boxes.count)", index = boxes.count
            if let externalID = node.attributes["ID"], !externalID.isEmpty {
                guard identifiers[externalID] == nil else { throw PreviewError.malformed("Duplicate topic ID") }
                identifiers[externalID] = id
            }
            let title: String
            if opml {
                guard let text = node.attributes["text"] else { throw PreviewError.malformed("OPML outline text") }
                title = text
            } else {
                title = node.attributes["TEXT"] ?? node.children.first { $0.name == "richcontent" && $0.attributes["TYPE"] == "NODE" }?.richText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
            guard title.utf8.count <= 65536 else { throw PreviewError.limit("Mind map label") }
            boxes.append(.init(id: id, text: title, color: depth == 0 ? "2" : "5", shape: "node", x: Double(depth) * 300, y: 0, width: 250, height: 90, file: nil))
            if let parent { edges.append(.init(from: parent, to: id, label: "")) }
            for arrow in node.children where arrow.name == "arrowlink" {
                guard links.count < 3000 else { throw PreviewError.limit("Mind map links") }
                if let target = arrow.attributes["DESTINATION"] { links.append((id, target)) }
            }
            var positions: [Double] = []
            for child in node.children where child.name == name { positions.append(try walk(child, depth: depth + 1, parent: id)) }
            let y: Double
            if let first = positions.first, let last = positions.last { y = (first + last) / 2 }
            else { y = Double(row) * 120; row += 1 }
            boxes[index].y = y
            return y
        }
        for node in roots { _ = try walk(node, depth: 0, parent: nil); row += 1 }
        for (from, target) in links { if let to = identifiers[target] { edges.append(.init(from: from, to: to, label: "")) } }
        try DiagramDocument.bounded(boxes, edges)
        let title = root.children.first { $0.name == "head" }?.children.first { $0.name == "title" }?.text ?? (opml ? "OPML" : "FreeMind / Freeplane")
        return .init(kind: opml ? "OPML" : "FreeMind / Freeplane", pages: [.init(title: title, boxes: boxes, edges: edges)], notice: "Automatic tree layout · styles, notes and attachments omitted · links never fetched · complete source available")
    }
}
