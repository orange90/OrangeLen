import Foundation
import Yams

/// A read-only geometry model. URLs, scripts and workflow tools never execute.
public struct DiagramDocument: Sendable {
    public struct Box: Sendable { public var id: String, text: String, color: String, shape: String; public var x: Double, y: Double, width: Double, height: Double; public var file: String? }
    public struct Edge: Sendable { public var from: String, to: String, label: String; public var points: [[Double]] = [] }
    public struct Page: Sendable { public var title: String, boxes: [Box], edges: [Edge] }
    public var kind: String, pages: [Page], notice: String
    public static func parseIfKnown(_ source: String, name: String, cancellation: Cancellation = .init()) throws -> Self? {
        guard source.utf8.count <= 1024 * 1024 else { throw PreviewError.limit("Diagram 1 MiB") }
        let ext = (name as NSString).pathExtension.lowercased()
        if ext == "drawio" || (ext == "xml" && (source.contains("<mxfile") || source.contains("<mxGraphModel"))) { return try drawio(source, token: cancellation) }
        guard ["canvas", "json", "yaml", "yml"].contains(ext) else { return nil }
        try cancellation.check()
        let object: [String: Any]
        if ext == "yaml" || ext == "yml" {
            // Refuse alias expansion before a third-party YAML parser sees input.
            guard source.range(of: #"(?:^|\s)[&*][A-Za-z0-9_-]+"#, options: .regularExpression) == nil else { throw PreviewError.malformed("YAML aliases are not supported in workflow previews") }
            guard source.contains("workflow:") && source.contains("graph:") else { return nil }
            var levels: [Int] = [], depth = 0
            let lines = source.split(separator:"\n",omittingEmptySubsequences:false)
            guard lines.count <= 20000 else { throw PreviewError.limit("YAML lines") }
            for line in lines {
                try cancellation.check()
                let indent = line.prefix(while:{$0 == " "}).count
                while let last = levels.last, last >= indent { levels.removeLast() }
                if !line.trimmingCharacters(in:.whitespaces).isEmpty { levels.append(indent) }
                guard levels.count <= 64 else { throw PreviewError.limit("YAML depth") }
                for ch in line { if ch == "[" || ch == "{" { depth += 1 }; if ch == "]" || ch == "}" { depth = max(0,depth - 1) }; guard depth <= 64 else { throw PreviewError.limit("YAML flow depth") } }
            }
            object = try Yams.load(yaml: source) as? [String: Any] ?? [:]
        } else {
            _ = try JSONParser.parse(source, cancellation: cancellation)
            guard let dict = try JSONSerialization.jsonObject(with: Data(source.utf8)) as? [String: Any] else { return nil }; object = dict
        }
        if ext == "canvas" { return try canvas(object, token: cancellation) }
        if let graph = (object["workflow"] as? [String: Any])?["graph"] as? [String: Any] { return try workflow(graph, kind: "Dify", token: cancellation) }
        if let nodes = object["nodes"] as? [[String: Any]] {
            if nodes.contains(where: { $0["class_type"] != nil }) || object["links"] != nil { return try workflow(object, kind: "ComfyUI", token: cancellation) }
            if object["connections"] != nil { return try workflow(object, kind: "n8n", token: cancellation) }
        }
        if !object.isEmpty && object.values.allSatisfy({ ($0 as? [String: Any])?["class_type"] != nil }) { return try comfyAPI(object, token: cancellation) }
        return nil
    }
    public func resolvingCards(document: URL, root: URL?, cancellation: Cancellation) throws -> Self {
        guard let root else { return self }
        var result = self
        var limits = PreviewLimits(); limits.fileBytes = 8192
        var remaining = 128 * 1024
        for p in result.pages.indices { for b in result.pages[p].boxes.indices {
            try cancellation.check()
            guard let path = result.pages[p].boxes[b].file, ArchiveDocument.safePath(path), remaining > 0 else { continue }
            let target = document.deletingLastPathComponent().appendingPathComponent(path)
            guard ReadableFormat.isText(target) else { continue }
            do {
                let bytes = try AccessBroker.readBytes(target,root:root,limits:limits,cancellation:cancellation,allowPartial:true).data
                let text = try AccessBroker.decode(bytes).0; remaining -= bytes.count
                result.pages[p].boxes[b].text = path + "\n\n" + String(text.prefix(4096))
            } catch is CancellationError { throw CancellationError() }
            catch { result.pages[p].boxes[b].text = path + "\n[unavailable within the authorized folder]" }
        } }
        return result
    }
    static func number(_ object: [String: Any], _ key: String, _ fallback: Double) throws -> Double {
        let value = (object[key] as? NSNumber)?.doubleValue ?? fallback
        guard value.isFinite, abs(value) <= 1_000_000 else { throw PreviewError.limit("Diagram geometry") }; return value
    }
    static func identifier(_ value: Any?) -> String { value.map { String(describing: $0) } ?? "" }
    static func bounded(_ boxes: [Box], _ edges: [Edge]) throws {
        guard boxes.count <= 2000, edges.count <= 5000, Set(boxes.map(\.id)).count == boxes.count,
              boxes.allSatisfy({ $0.x.isFinite && $0.y.isFinite && abs($0.x) <= 1e6 && abs($0.y) <= 1e6 && !$0.id.isEmpty && $0.text.utf8.count <= 65536 && $0.width > 0 && $0.height > 0 }) else { throw PreviewError.limit("Diagram nodes/edges/labels") }
    }
    static func canvas(_ obj: [String: Any], token: Cancellation) throws -> Self {
        guard let nodes = obj["nodes"] as? [[String: Any]], nodes.count <= 2000 else { throw PreviewError.malformed("JSON Canvas nodes") }
        let boxes = try nodes.map { node -> Box in
            try token.check(); let type = node["type"] as? String ?? ""
            guard ["text","file","link","group"].contains(type) else { throw PreviewError.malformed("JSON Canvas node type") }
            return Box(id: identifier(node["id"]), text: node["text"] as? String ?? node["file"] as? String ?? node["url"] as? String ?? node["label"] as? String ?? type, color: node["color"] as? String ?? "", shape: type, x: try number(node,"x",0), y: try number(node,"y",0), width: try number(node,"width",240), height: try number(node,"height",140), file: node["file"] as? String)
        }
        let edges = (obj["edges"] as? [[String: Any]] ?? []).map { Edge(from: identifier($0["fromNode"]), to: identifier($0["toNode"]), label: $0["label"] as? String ?? "") }
        try bounded(boxes,edges)
        return .init(kind: "JSON Canvas", pages: [.init(title: "Canvas", boxes: boxes, edges: edges)], notice: "Links are labels; authorized local text cards are bounded. External resources are not fetched.")
    }
    static func workflow(_ obj: [String: Any], kind: String, token: Cancellation) throws -> Self {
        let nodes = obj["nodes"] as? [[String: Any]] ?? []; guard nodes.count <= 2000 else { throw PreviewError.limit("Workflow nodes") }
        var boxes: [Box] = []
        for (i,node) in nodes.enumerated() {
            try token.check(); let data = node["data"] as? [String: Any] ?? node
            let pos = node["position"] as? [String: Any] ?? [:], list = node["pos"] as? [Double] ?? node["position"] as? [Double] ?? []
            let title = data["title"] as? String ?? node["name"] as? String ?? node["type"] as? String ?? data["type"] as? String ?? "Node"
            var text = title
            if let inputs = node["inputs"] as? [[String: Any]] { text += "\n" + inputs.compactMap { $0["name"] as? String }.prefix(8).joined(separator: " · ") }
            if let parameters = node["parameters"] as? [String: Any] { text += "\n" + parameters.keys.sorted().prefix(8).map { String($0.prefix(80)) }.joined(separator: " · ") }
            let id = kind == "n8n" ? (node["name"] ?? node["id"]) : node["id"]
            let x = list.count > 0 ? list[0] : try number(pos,"x",Double(i % 4) * 300)
            let y = list.count > 1 ? list[1] : try number(pos,"y",Double(i / 4) * 170)
            guard x.isFinite, y.isFinite, abs(x) <= 1e6, abs(y) <= 1e6 else { throw PreviewError.limit("Workflow position") }
            boxes.append(.init(id: identifier(id), text: text, color: "5", shape: "node", x: x, y: y, width: 250, height: 110, file: nil))
        }
        var edges = (obj["edges"] as? [[String: Any]] ?? []).map { Edge(from: identifier($0["source"]), to: identifier($0["target"]), label: $0["sourceHandle"] as? String ?? "") }
        if let links = obj["links"] as? [[Any]] { edges += links.filter { $0.count >= 5 }.map { Edge(from: identifier($0[1]), to: identifier($0[3]), label: $0.count > 5 ? identifier($0[5]) : "") } }
        if let connections = obj["connections"] as? [String: Any] {
            for (from, output) in connections {
                for value in (output as? [String: Any] ?? [:]).values {
                    for targets in value as? [[[String: Any]]] ?? [] { for target in targets { edges.append(.init(from: from, to: identifier(target["node"]), label: "")) } }
                }
            }
        }
        try bounded(boxes,edges)
        return .init(kind: kind, pages: [.init(title: kind, boxes: boxes, edges: edges)], notice: "Read-only workflow · source retains complete parameters and dependencies · tools never execute")
    }
    static func comfyAPI(_ obj: [String: Any], token: Cancellation) throws -> Self {
        guard obj.count <= 2000 else { throw PreviewError.limit("Workflow nodes") }
        var boxes: [Box] = [], edges: [Edge] = []
        for (i,id) in obj.keys.sorted().enumerated() {
            try token.check(); let node = obj[id] as? [String: Any] ?? [:], inputs = node["inputs"] as? [String: Any] ?? [:]
            var text = node["class_type"] as? String ?? id
            for key in inputs.keys.sorted() {
                if let link = inputs[key] as? [Any], link.count == 2 { edges.append(.init(from: identifier(link[0]), to: id, label: key)) }
                else { text += "\n" + key + ": " + String(identifier(inputs[key]).prefix(100)) }
            }
            boxes.append(.init(id: id, text: String(text.prefix(2000)), color: "5", shape: "node", x: Double(i % 4) * 300, y: Double(i / 4) * 200, width: 250, height: 160, file: nil))
        }
        try bounded(boxes,edges)
        return .init(kind: "ComfyUI API", pages: [.init(title: "ComfyUI API", boxes: boxes, edges: edges)], notice: "Automatic grid layout · complete parameters remain in source")
    }
    static func drawio(_ source: String, token: Cancellation) throws -> Self {
        let root = try BoundedXML.parse(source, token: token)
        var pages: [Page] = []
        let diagrams = root.name == "mxGraphModel" ? [root] : root.children.filter { $0.name == "diagram" }
        guard !diagrams.isEmpty, diagrams.count <= 50 else { throw PreviewError.malformed("Draw.io pages") }
        for (pageIndex,diagram) in diagrams.enumerated() {
            try token.check()
            let model: BoundedXML.Node
            if diagram.name == "mxGraphModel" { model = diagram }
            else if let child = diagram.children.first(where: { $0.name == "mxGraphModel" }) { model = child }
            else {
                guard let data = Data(base64Encoded: diagram.text.trimmingCharacters(in: .whitespacesAndNewlines)) else { throw PreviewError.malformed("Draw.io Base64") }
                let inflated = try ArchiveDocument.inflate(data, window: -15, maximum: 1024 * 1024, token: token)
                guard let encoded = String(data: inflated, encoding: .utf8), let xml = encoded.removingPercentEncoding else { throw PreviewError.malformed("Draw.io URI encoding") }
                model = try BoundedXML.parse(xml, token: token)
            }
            let cells = model.descendants("mxCell")
            var boxes: [Box] = [], edges: [Edge] = []
            for cell in cells {
                try token.check(); let a = cell.attributes
                let geometry = cell.children.first(where: { $0.name == "mxGeometry" }), g = geometry?.attributes ?? [:]
                func value(_ k: String,_ fallback: Double) throws -> Double { guard let raw = g[k] else { return fallback }; guard let n = Double(raw), n.isFinite, abs(n) <= 1e6 else { throw PreviewError.malformed("Draw.io geometry") }; return n }
                let label = a["value"] ?? cell.wrapperLabel ?? "", style = a["style"] ?? ""
                if a["vertex"] == "1" { boxes.append(.init(id: a["id"] ?? cell.wrapperID ?? "", text: label.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression), color: style.components(separatedBy: ";").first { $0.hasPrefix("fillColor=") }?.components(separatedBy: "=").last ?? "", shape: style.contains("ellipse") ? "ellipse" : style.contains("rhombus") ? "diamond" : "node", x: try value("x",0), y: try value("y",0), width: try value("width",160), height: try value("height",80), file: nil)) }
                if a["edge"] == "1" { edges.append(.init(from: a["source"] ?? "", to: a["target"] ?? "", label: label)) }
            }
            // Parent-relative geometry is accumulated with cycle and depth protection.
            var index: [String: BoundedXML.Node] = [:]
            for cell in cells { if let id = cell.attributes["id"] ?? cell.wrapperID { guard index[id] == nil else { throw PreviewError.malformed("Draw.io duplicate cell ID") }; index[id] = cell } }
            for i in boxes.indices {
                var current = index[boxes[i].id]?.attributes["parent"], seen = Set<String>()
                while let id = current, let parent = index[id] {
                    guard seen.insert(id).inserted, seen.count < 64 else { throw PreviewError.malformed("Draw.io parent cycle") }
                    if parent.attributes["vertex"] == "1", let g = parent.children.first(where: { $0.name == "mxGeometry" })?.attributes {
                        boxes[i].x += Double(g["x"] ?? "0") ?? 0; boxes[i].y += Double(g["y"] ?? "0") ?? 0
                    }
                    current = parent.attributes["parent"]
                }
            }
            try bounded(boxes,edges)
            pages.append(.init(title: diagram.attributes["name"] ?? "Page \(pageIndex + 1)", boxes: boxes, edges: edges))
        }
        return .init(kind: "Draw.io", pages: pages, notice: "Basic shapes, labels and connections · custom stencils/images/styles may be simplified · source retained")
    }
}

/// XML without DTD/entity expansion, with shared depth/node/text budgets.
enum BoundedXML {
    final class Node { var name: String, attributes: [String: String], children: [Node] = [], text = "", wrapperLabel: String?, wrapperID: String?
        init(_ name: String,_ attributes: [String: String]) { self.name = name; self.attributes = attributes }
        func descendants(_ name: String) -> [Node] { children.flatMap { ($0.name == name ? [$0] : []) + $0.descendants(name) } }
    }
    static func parse(_ source: String, token: Cancellation) throws -> Node {
        guard source.utf8.count <= 5 * 1024 * 1024, source.range(of: "<!DOCTYPE",options:.caseInsensitive) == nil, source.range(of: "<!ENTITY",options:.caseInsensitive) == nil else { throw PreviewError.malformed("XML declarations/budget") }
        let delegate = Builder(token); let parser = XMLParser(data: Data(source.utf8)); parser.shouldResolveExternalEntities = false; parser.delegate = delegate
        guard parser.parse(), delegate.failure == nil, let root = delegate.root else { throw delegate.failure ?? PreviewError.malformed("XML") }; return root
    }
    final class Builder: NSObject, XMLParserDelegate {
        let token: Cancellation; var stack: [Node] = [], root: Node?, failure: Error?, count = 0, textBytes = 0
        init(_ token: Cancellation) { self.token = token }
        func parser(_ p: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName qName: String?, attributes a: [String: String]) {
            do { try token.check(); count += 1; guard count <= 20000, stack.count < 64 else { throw PreviewError.limit("XML tree") }
                let node = Node(name,a); node.wrapperLabel = stack.last?.attributes["label"]; node.wrapperID = stack.last?.attributes["id"]
                if let parent = stack.last { parent.children.append(node) } else { root = node }; stack.append(node)
            } catch { failure = error; p.abortParsing() }
        }
        func parser(_ p: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName qName: String?) { if !stack.isEmpty { stack.removeLast() } }
        func parser(_ p: XMLParser, foundCharacters value: String) { textBytes += value.utf8.count; if textBytes > 5 * 1024 * 1024 { failure = PreviewError.limit("XML text"); p.abortParsing() } else { stack.last?.text += value } }
        func parser(_ p: XMLParser, foundCDATA value: Data) { parser(p,foundCharacters:String(decoding:value,as:UTF8.self)) }
    }
}
