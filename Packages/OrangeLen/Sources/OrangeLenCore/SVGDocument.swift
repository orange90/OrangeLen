import Foundation

/// Rebuilds static SVG from an allowlist. Scripts, CSS, foreign content, resource URLs,
/// entity declarations, animation and recursive use elements never reach WebKit.
public struct SVGDocument: Sendable {
    public let xml: String
    public let omitted: Int
    public static func parse(_ source: String, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> Self {
        guard source.utf8.count <= limits.fileBytes else { throw PreviewError.limit(L10n.text("SVG 输入字节预算")) }
        // Source is already decoded (including UTF-16); reject declarations before XMLParser can expand them.
        guard source.range(of:"<!DOCTYPE",options:.caseInsensitive) == nil,
              source.range(of:"<!ENTITY",options:.caseInsensitive) == nil else { throw PreviewError.malformed(L10n.text("SVG 不接受 DTD 或实体声明")) }
        try cancellation.check()
        let builder = Builder(limits:limits,token:cancellation)
        let parser = XMLParser(data:Data(source.utf8)); parser.shouldProcessNamespaces = true; parser.shouldResolveExternalEntities = false; parser.delegate = builder
        guard parser.parse(), builder.error == nil, builder.rootSeen else { throw builder.error ?? PreviewError.malformed(L10n.text("SVG XML 无效")) }
        try cancellation.check()
        return Self(xml:builder.output,omitted:builder.omitted)
    }
    private final class Builder: NSObject, XMLParserDelegate {
        let limits: PreviewLimits; let token: Cancellation
        var output = ""; var error: Error?; var depth = 0; var nodes = 0; var skippedDepth = 0; var rootSeen = false; var omitted = 0
        let elements: Set<String> = ["svg","g","defs","path","rect","circle","ellipse","line","polyline","polygon","text","tspan","title","desc","linearGradient","radialGradient","stop","clipPath"]
        let attributes: Set<String> = ["id","viewBox","preserveAspectRatio","x","y","x1","y1","x2","y2","dx","dy","width","height","rx","ry","cx","cy","r","d","points","transform","fill","stroke","color","fill-rule","clip-rule","fill-opacity","stroke-opacity","opacity","stroke-width","stroke-linecap","stroke-linejoin","stroke-miterlimit","stroke-dasharray","stroke-dashoffset","font-family","font-size","font-weight","font-style","text-anchor","dominant-baseline","letter-spacing","word-spacing","textLength","lengthAdjust","gradientUnits","gradientTransform","spreadMethod","fx","fy","fr","offset","stop-color","stop-opacity","clip-path","clipPathUnits","vector-effect"]
        let presentation: Set<String> = ["fill","stroke","color","fill-rule","clip-rule","fill-opacity","stroke-opacity","opacity","stroke-width","stroke-linecap","stroke-linejoin","stroke-miterlimit","stroke-dasharray","stroke-dashoffset","font-family","font-size","font-weight","font-style","text-anchor","dominant-baseline","letter-spacing","word-spacing","stop-color","stop-opacity","clip-path","vector-effect"]
        init(limits:PreviewLimits,token:Cancellation) { self.limits = limits; self.token = token }
        func escape(_ value: String) -> String {
            value.replacingOccurrences(of:"&",with:"&amp;").replacingOccurrences(of:"<",with:"&lt;").replacingOccurrences(of:">",with:"&gt;").replacingOccurrences(of:"\"",with:"&quot;")
        }
        func safeValue(_ value: String, key: String) -> Bool {
            guard value.utf8.count <= 250_000 else { return false }
            if ["fill","stroke","color","stop-color"].contains(key) {
                return value.range(of:#"^(?:#[0-9a-fA-F]{3,8}|[a-zA-Z]{1,32}|(?:rgb|rgba|hsl|hsla)\([0-9.,% +\-]+\)|url\(#[a-zA-Z_][a-zA-Z0-9_.\-]*\))$"#,options:.regularExpression) != nil
            }
            if key == "clip-path" { return value == "none" || value.range(of:#"^url\(#[a-zA-Z_][a-zA-Z0-9_.\-]*\)$"#,options:.regularExpression) != nil }
            return value.range(of:#"[<>\\]|(?:url\s*\(|https?:|file:|data:|javascript:|@import)"#,options:[.regularExpression,.caseInsensitive]) == nil
        }
        func fail(_ parser: XMLParser, _ failure: Error) { error = failure; parser.abortParsing() }
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String:String]) {
            do { try token.check() } catch { fail(parser,error); return }
            depth += 1; nodes += 1
            guard depth <= limits.structureDepth, nodes <= limits.structureNodes else { fail(parser,PreviewError.limit(L10n.text("SVG 深度或元素预算"))); return }
            let svgNamespace = namespaceURI == nil || namespaceURI == "" || namespaceURI == "http://www.w3.org/2000/svg"
            if depth == 1 {
                guard elementName == "svg", svgNamespace else { fail(parser,PreviewError.malformed(L10n.text("SVG 根元素无效"))); return }; rootSeen = true
            }
            if skippedDepth > 0 { return }
            guard svgNamespace, elements.contains(elementName), depth == 1 || elementName != "svg" else { skippedDepth = depth; omitted += 1; return }
            output += "<" + elementName
            if depth == 1 { output += " xmlns=\"http://www.w3.org/2000/svg\"" }
            var clean = attributeDict
            if let style = clean.removeValue(forKey:"style") {
                for declaration in style.split(separator:";") {
                    let parts = declaration.split(separator:":",maxSplits:1).map { $0.trimmingCharacters(in:.whitespacesAndNewlines) }
                    if parts.count == 2, presentation.contains(parts[0]), safeValue(parts[1],key:parts[0]) { clean[parts[0]] = parts[1] }
                    else { omitted += 1 }
                }
            }
            for key in clean.keys.sorted() {
                let value = clean[key]!
                if key == "xmlns" || key.hasPrefix("xmlns:") { continue }
                guard attributes.contains(key), safeValue(value,key:key) else { omitted += 1; continue }
                output += " " + key + "=\"" + escape(value) + "\""
            }
            output += ">"
        }
        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if skippedDepth == 0 { output += "</" + elementName + ">" }
            else if skippedDepth == depth { skippedDepth = 0 }
            depth -= 1
        }
        func parser(_ parser: XMLParser, foundCharacters string: String) { if skippedDepth == 0 { output += escape(string) } }
        func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            if let string = String(data:CDATABlock,encoding:.utf8), skippedDepth == 0 { output += escape(string) }
        }
        func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data? { nil }
    }
}
