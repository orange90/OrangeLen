import Foundation

private final class SafeXMLNode {
    let name: String; let attributes: [String:String]; var children: [SafeXMLNode] = []; var text = ""
    init(_ name: String, _ attributes: [String:String]) { self.name = name.components(separatedBy:":").last!.lowercased(); self.attributes = attributes }
    func all(_ name: String) -> [SafeXMLNode] { (self.name == name ? [self] : []) + children.flatMap { $0.all(name) } }
}
private final class SafeXML: NSObject, XMLParserDelegate {
    var stack: [SafeXMLNode] = []; var root: SafeXMLNode?; var count = 0; var failure: Error?
    let token: Cancellation
    init(_ token: Cancellation) { self.token = token }
    static func parse(_ data: Data, token: Cancellation) throws -> SafeXMLNode {
        guard data.count <= PreviewLimits().archiveEntryBytes,
              !(try AccessBroker.decode(data).0).uppercased().contains("<!DOCTYPE"),
              !(try AccessBroker.decode(data).0).uppercased().contains("<!ENTITY") else { throw PreviewError.malformed("XML DTD/实体或大小不支持") }
        let delegate = SafeXML(token); let parser = XMLParser(data:data)
        parser.delegate = delegate; parser.shouldResolveExternalEntities = false
        guard parser.parse(), delegate.failure == nil, let root = delegate.root else { throw delegate.failure ?? PreviewError.malformed("EPUB XML 损坏") }
        return root
    }
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String:String]) {
        do { try token.check(); count += 1; guard count <= 20000, stack.count < 64 else { throw PreviewError.limit("EPUB XML 结构") } }
        catch { failure = error; parser.abortParsing(); return }
        let node = SafeXMLNode(elementName,attributeDict)
        if let parent = stack.last { parent.children.append(node) } else { root = node }
        stack.append(node)
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Text nodes preserve interleaving, unlike flattening text before child nodes.
        count += 1
        if count > 20000 { failure = PreviewError.limit("EPUB XML 文本节点"); parser.abortParsing(); return }
        let child = SafeXMLNode("#text",[:]); child.text = string; stack.last?.children.append(child)
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) { if !stack.isEmpty { stack.removeLast() } }
    func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data? { failure = PreviewError.unsafePath; parser.abortParsing(); return nil }
}
public struct EPUBChapter: Sendable { public let id: String; public let path: String; public let title: String }
public struct EPUBDocument: Sendable {
    public let title: String
    public let chapters: [EPUBChapter]
    public let warning: String
    public let archive: ArchiveDocument
    public let encryptedPaths: Set<String>
    public static func resolve(_ href: String, base: String) -> String? {
        guard let parts = URLComponents(string:href), parts.scheme == nil, parts.host == nil, !href.hasPrefix("/"),
              let decoded = parts.percentEncodedPath.removingPercentEncoding, !decoded.contains("\\"), !decoded.contains(":") else { return nil }
        var components = base.split(separator:"/").dropLast().map(String.init)
        for part in decoded.split(separator:"/") {
            if part == "." { continue }
            if part == ".." { guard !components.isEmpty else { return nil }; components.removeLast() }
            else { components.append(String(part)) }
        }
        let path = components.joined(separator:"/")
        return ArchiveDocument.safePath(path) ? path : nil
    }
    public static func parse(_ data: Data, cancellation: Cancellation = .init()) throws -> Self {
        let archive = try ArchiveDocument.parse(data,name:"book.epub",cancellation:cancellation)
        guard let mime = archive.entry("mimetype"), String(data:try archive.read(mime,cancellation:cancellation),encoding:.utf8)?.trimmingCharacters(in:.whitespacesAndNewlines) == "application/epub+zip",
              let container = archive.entry("META-INF/container.xml") else { throw PreviewError.malformed("EPUB mimetype/container 缺失") }
        let xml = try SafeXML.parse(archive.read(container,cancellation:cancellation),token:cancellation)
        guard let packagePath = xml.all("rootfile").first?.attributes["full-path"], ArchiveDocument.safePath(packagePath), let entry = archive.entry(packagePath) else { throw PreviewError.malformed("EPUB package 路径") }
        let package = try SafeXML.parse(archive.read(entry,cancellation:cancellation),token:cancellation)
        var items: [String:(String,String)] = [:]
        for item in package.all("item") {
            guard let id = item.attributes["id"], let href = item.attributes["href"], let path = resolve(href,base:packagePath) else { continue }
            items[id] = (path,item.attributes["media-type"] ?? "")
        }
        var navTitles: [String:String] = [:]
        for item in package.all("item") where item.attributes["properties"]?.split(separator:" ").contains("nav") == true {
            if let id = item.attributes["id"], let path = items[id]?.0, let nav = archive.entry(path),
               let node = try? SafeXML.parse(archive.read(nav,cancellation:cancellation),token:cancellation) {
                for link in node.all("a") {
                    if let href = link.attributes["href"], let target = resolve(href,base:path) { navTitles[target] = plain(link).trimmingCharacters(in:.whitespacesAndNewlines) }
                }
            }
        }
        var chapters: [EPUBChapter] = []
        for reference in package.all("itemref") {
            guard let id = reference.attributes["idref"], let item = items[id], item.1 == "application/xhtml+xml", archive.entry(item.0) != nil else { continue }
            chapters.append(.init(id:id,path:item.0,title:navTitles[item.0] ?? item.0))
        }
        guard !chapters.isEmpty, chapters.count <= 1000 else { throw PreviewError.malformed("没有可重排 XHTML 章节或章节过多") }
        var encrypted = Set<String>(); var obfuscatedFonts = 0
        if let encryption = archive.entry("META-INF/encryption.xml") {
            let node = try SafeXML.parse(archive.read(encryption,cancellation:cancellation),token:cancellation)
            for encryptedData in node.all("encrypteddata") {
                let algorithm = encryptedData.all("encryptionmethod").first?.attributes["Algorithm"] ?? ""
                for reference in encryptedData.all("cipherreference") {
                    if let uri = reference.attributes["URI"], let path = resolve(uri,base:"root") {
                        if algorithm.contains("embedding") || algorithm.contains("obfuscation") { obfuscatedFonts += 1 }
                        else { encrypted.insert(path) }
                    }
                }
            }
        }
        let fixed = package.all("meta").contains { $0.attributes["property"] == "rendition:layout" && plain($0).contains("pre-paginated") }
        let title = package.all("title").first.map(plain) ?? "EPUB"
        return .init(title:title,chapters:chapters,warning:(fixed ? "固定版式降级为文字；不承诺布局还原。 " : "") + (obfuscatedFonts > 0 ? "字体混淆资源不加载，采用系统字体。 " : "") + "不执行脚本/CSS，不请求外链。",archive:archive,encryptedPaths:encrypted)
    }
    public func chapter(_ chapter: EPUBChapter, cancellation: Cancellation = .init()) throws -> DocumentSection {
        guard chapters.contains(where: { $0.id == chapter.id && $0.path == chapter.path }), !encryptedPaths.contains(chapter.path), let entry = archive.entry(chapter.path) else { throw PreviewError.malformed("正文受保护或资源缺失") }
        let node = try SafeXML.parse(archive.read(entry,cancellation:cancellation),token:cancellation)
        let body = node.all("body").first ?? node
        return .init(id:chapter.id,title:chapter.title,text:Self.markdown(body,base:chapter.path),markdown:true,warning:warning)
    }
    private static func plain(_ node: SafeXMLNode) -> String { node.text + node.children.map(plain).joined() }
    private static func markdown(_ node: SafeXMLNode, base: String) -> String {
        if ["script","style","iframe","object","embed","svg"].contains(node.name) { return "" }
        if node.name == "#text" { return node.text.replacingOccurrences(of:"\\",with:"\\\\").replacingOccurrences(of:"[",with:"\\[").replacingOccurrences(of:"*",with:"\\*") }
        let content = node.children.map { markdown($0,base:base) }.joined()
        switch node.name {
        case "h1","h2","h3","h4","h5","h6": return "\n\n" + String(repeating:"#",count:Int(node.name.suffix(1))!) + " " + content + "\n\n"
        case "p","div","section","article": return "\n\n" + content + "\n\n"
        case "br": return "\n"
        case "li": return "\n- " + content
        case "strong","b": return "**" + content + "**"
        case "em","i": return "*" + content + "*"
        case "pre": return "\n\n~~~~\n" + plain(node) + "\n~~~~\n\n"
        case "img":
            guard let src = node.attributes["src"], let path = resolve(src,base:base) else { return "[外部或非法图片未加载]" }
            let encoded = path.addingPercentEncoding(withAllowedCharacters:.urlPathAllowed) ?? ""
            return "![" + (node.attributes["alt"] ?? "图片").replacingOccurrences(of:"]",with:"\\]") + "](" + encoded + ")"
        default: return content
        }
    }
}
