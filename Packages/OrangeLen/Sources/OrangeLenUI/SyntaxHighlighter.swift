import AppKit
import JavaScriptCore
import OrangeLenCore

/// Document text is an argument, never JavaScript source. Highlight markup is decoded
/// back into native ranges and accepted only when it reproduces the input exactly.
final class SyntaxHighlighter {
    struct Token { let range: NSRange; let scope: String }
    static let shared = SyntaxHighlighter()
    private let lock = NSLock() // Protects only the small cache, never JS execution.
    private let engineLock = NSLock()
    private var context: JSContext?
    private var initialized = false
    private var cacheCosts: [String: Int] = [:]
    private var cacheBytes = 0
    private var cache: [String: [Token]] = [:]
    private var order: [String] = []
    private init() {}
    private func prepareEngine() {
        guard !initialized else { return }; initialized = true
        context = JSContext()
        if let url = Bundle.module.url(forResource: "Highlight", withExtension: "js"), let script = try? String(contentsOf: url, encoding: .utf8) { context?.evaluateScript(script) }
    }
    var languageCount: Int {
        engineLock.lock(); defer { engineLock.unlock() }; prepareEngine()
        return context?.objectForKeyedSubscript("OrangeHighlight")?.invokeMethod("languages", withArguments: [])?.toArray()?.count ?? 0
    }
    static func language(url: URL?, source: String) -> String? {
        if let url {
            let name = url.lastPathComponent.lowercased(), ext = url.pathExtension.lowercased()
            if name == "dockerfile" || name == "containerfile" || name.hasPrefix("dockerfile.") || name.hasPrefix("containerfile.") { return "dockerfile" }
            if name.contains("makefile") { return "makefile" }
            if name == "cmakelists.txt" { return "cmake" }
            if name == ".env" || name.hasPrefix(".env.") { return "ini" }
            if ["cargo.lock", "poetry.lock", "uv.lock", "pyproject.toml"].contains(name) { return "toml" }
            let aliases = ["py":"python","js":"javascript","mjs":"javascript","cjs":"javascript","jsx":"javascript","ts":"typescript","mts":"typescript","cts":"typescript","tsx":"typescript","h":"c","hpp":"cpp","rs":"rust","sh":"bash","zsh":"bash","rb":"ruby","kt":"kotlin","cs":"csharp","ps1":"powershell","r":"r","vue":"xml","svelte":"xml","astro":"xml","html":"xml","svg":"xml","plist":"xml","yml":"yaml","jsonc":"json","json5":"javascript","tf":"hcl","tfvars":"hcl","gql":"graphql"]
            if let alias = aliases[ext] { return alias }
            if !ext.isEmpty { return ext }
        }
        if let first = source.split(separator: "\n", maxSplits: 1).first, first.hasPrefix("#!") {
            if first.contains("python") { return "python" }
            if first.contains("node") { return "javascript" }
            if first.contains("ruby") { return "ruby" }
            if first.contains("sh") { return "bash" }
        }
        return nil
    }
    func tokens(_ source: String, language: String?, cancellation: Cancellation? = nil) -> [Token] {
        guard let language, !source.isEmpty, source.utf16.count <= PreviewLimits().highlightUTF16 else { return [] }
        if let cancellation, (try? cancellation.check()) == nil { return [] }
        let key = language + "\0" + source
        lock.lock(); let cached = cache[key]; lock.unlock()
        if let cached { return cached }
        engineLock.lock(); defer { engineLock.unlock() }
        if let cancellation, (try? cancellation.check()) == nil { return [] }
        prepareEngine()
        guard let html = context?.objectForKeyedSubscript("OrangeHighlight")?.invokeMethod("render", withArguments: [source, language])?.toString(), html != "null", html != "undefined" else { return [] }
        let decoder = HighlightDecoder()
        let parser = XMLParser(data: Data(("<root>" + html.replacingOccurrences(of: "&#x27;", with: "&apos;") + "</root>").utf8))
        parser.shouldResolveExternalEntities = false; parser.delegate = decoder
        guard parser.parse(), decoder.text == source else { return [] }
        if let cancellation, (try? cancellation.check()) == nil { return [] }
        let cost = key.utf8.count + decoder.tokens.reduce(0) { $0 + 32 + $1.scope.utf8.count }
        lock.lock()
        if cache[key] == nil, cost <= 8 * 1024 * 1024 {
            cache[key] = decoder.tokens; cacheCosts[key] = cost; cacheBytes += cost; order.append(key)
            while order.count > 12 || cacheBytes > 8 * 1024 * 1024 {
                let removed = order.removeFirst(); cache.removeValue(forKey: removed); cacheBytes -= cacheCosts.removeValue(forKey: removed) ?? 0
            }
        }
        lock.unlock()
        return decoder.tokens
    }
    func apply(_ text: NSMutableAttributedString, range: NSRange, language: String?) {
        let bounded = NSIntersectionRange(range, NSRange(location: 0, length: min(text.length, PreviewLimits().highlightUTF16)))
        guard bounded.length > 0 else { return }
        let content = (text.string as NSString).substring(with: bounded)
        guard let language else { return }
        let key = language + "\0" + content
        lock.lock(); let cached = cache[key]; lock.unlock()
        // Painting is cache-only. A Reader schedules misses off the main thread.
        if let cached { apply(cached, to: text, offset: bounded.location) }
    }
    func apply(_ tokens: [Token], to text: NSMutableAttributedString, offset: Int = 0) {
        for token in tokens {
            let scope = token.scope
            let color: NSColor
            if scope.contains("comment") || scope.contains("quote") { color = .secondaryLabelColor }
            else if scope.contains("string") || scope.contains("regexp") { color = .systemRed }
            else if scope.contains("number") || scope.contains("literal") { color = .systemOrange }
            else if scope.contains("keyword") || scope.contains("meta") { color = .systemPurple }
            else if scope.contains("title") || scope.contains("type") || scope.contains("built_in") { color = .systemTeal }
            else if scope.contains("attr") || scope.contains("variable") { color = .systemBlue }
            else { color = .textColor }
            text.addAttribute(.foregroundColor, value: color, range: NSRange(location: offset + token.range.location, length: token.range.length))
        }
    }
}
private final class HighlightDecoder: NSObject, XMLParserDelegate {
    var offset = 0
    var text = "", scopes: [String] = [], tokens: [SyntaxHighlighter.Token] = []
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) { scopes.append(attributeDict["class"] ?? "") }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) { if !scopes.isEmpty { scopes.removeLast() } }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard tokens.count < 20_000 else { parser.abortParsing(); return }
        if let scope = scopes.last(where: { !$0.isEmpty }) { tokens.append(.init(range: .init(location: offset, length: string.utf16.count), scope: scope)) }
        text += string; offset += string.utf16.count
    }
}
