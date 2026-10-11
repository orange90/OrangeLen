import XCTest
import AppKit
import WebKit
import Network
import OrangeLenCore
@testable import OrangeLenUI

@MainActor final class HTMLPreviewTests: XCTestCase {
    func testLocalAndHTTPResourcesModulesFetchAndLateSnapshot() async throws {
        _ = NSApplication.shared
        let server = try HTMLResourceServer()
        let started = expectation(description: "HTTP fixture ready")
        server.start { started.fulfill() }
        await fulfillment(of: [started], timeout: 5)
        defer { server.stop() }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("index.html")
        try "#local{color:rgb(11,22,33)}".write(to: directory.appendingPathComponent("style.css"), atomically: true, encoding: .utf8)
        try "window.localScript=true".write(to: directory.appendingPathComponent("script.js"), atomically: true, encoding: .utf8)
        try HTMLResourceServer.pixel.write(to: directory.appendingPathComponent("local.gif"))
        let base = "http://127.0.0.1:\(try XCTUnwrap(server.port))"
        let source = """
        <!doctype html><link rel="stylesheet" href="style.css"><link rel="stylesheet" href="\(base)/style.css">
        <script src="script.js"></script><script src="\(base)/script.js"></script>
        <script type="module" src="\(base)/module.js"></script>
        <p id="local">local</p><p id="remote">remote</p><img id="localImage" src="local.gif"><img id="remoteImage" src="\(base)/pixel.gif">
        <script>fetch('\(base)/data.json').then(r=>r.json()).then(v=>window.fetched=v.ok)</script>
        """
        try source.write(to: file, atomically: true, encoding: .utf8)
        let preview = HTMLPreview(source: source, documentURL: file, readAccessURL: directory, usesSnapshot: true)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 500), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = preview; window.orderBack(nil)
        defer { preview.cancel(); window.orderOut(nil) }
        try await settle(preview.webView)
        for _ in 0..<250 {
            if (try await preview.webView.evaluateJavaScript("window.moduleScript === true && window.fetched === true")) as? Bool == true, preview.snapshotImage != nil { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let values = try await preview.webView.evaluateJavaScript("[window.localScript === true, window.remoteScript === true, window.moduleScript === true, window.fetched === true, getComputedStyle(document.getElementById('local')).color, getComputedStyle(document.getElementById('remote')).color, document.getElementById('localImage').naturalWidth, document.getElementById('remoteImage').naturalWidth]") as? [Any]
        for i in 0..<4 { XCTAssertEqual(values?[i] as? Bool, true, "Script/fetch result \(i)") }
        XCTAssertEqual(values?[4] as? String, "rgb(11, 22, 33)")
        XCTAssertEqual(values?[5] as? String, "rgb(44, 55, 66)")
        XCTAssertEqual(values?[6] as? Int, 1); XCTAssertEqual(values?[7] as? Int, 1)
        let first = try XCTUnwrap(preview.snapshotImage)
        _ = try await preview.webView.evaluateJavaScript("setTimeout(()=>{ document.body.style.background='rgb(240,128,53)'; }, 300); true")
        for _ in 0..<250 {
            if let next = preview.snapshotImage, next !== first { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let next = try XCTUnwrap(preview.snapshotImage)
        XCTAssertFalse(next === first, "Late DOM changes must refresh Finder's native snapshot")
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(next.tiffRepresentation)))
        let pixel = try XCTUnwrap(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2)?.usingColorSpace(.sRGB))
        XCTAssertEqual(pixel.redComponent, 240.0 / 255, accuracy: 0.02)
    }

    func testNativeSnapshotRendersLongPageAndResizes() async throws {
        _ = NSApplication.shared
        let preview = HTMLPreview(source: "<!doctype html><style>body{margin:0;background:#f07835} main{height:1400px}</style><main>Native snapshot</main>", usesSnapshot: true)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 500), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = preview; window.orderBack(nil)
        defer { preview.cancel(); window.orderOut(nil) }
        preview.onFailure = { XCTFail("Native snapshot failed") }
        for _ in 0..<250 {
            if preview.snapshotImage != nil { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let image = try XCTUnwrap(preview.snapshotImage)
        XCTAssertGreaterThanOrEqual(image.size.height, 1400)
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation)))
        let pixel = try XCTUnwrap(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2)?.usingColorSpace(.sRGB))
        XCTAssertEqual(pixel.redComponent, 240.0 / 255, accuracy: 0.02)
        window.setContentSize(NSSize(width: 480, height: 500)); preview.layoutSubtreeIfNeeded()
        for _ in 0..<250 {
            if let width = preview.snapshotImage?.size.width, width < image.size.width { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertLessThan(try XCTUnwrap(preview.snapshotImage).size.width, image.size.width)
    }

    func load(_ reader: ReaderController, _ url: URL) async {
        let done = expectation(description: "load document")
        reader.open(url) { error in XCTAssertNil(error); done.fulfill() }
        await fulfillment(of: [done], timeout: 20)
    }

    func settle(_ web: WKWebView) async throws {
        for _ in 0..<250 {
            if !web.isLoading, (try? await web.evaluateJavaScript("document.readyState")) as? String == "complete" { return }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTFail("WebKit did not finish rendering")
    }

    func testHTMLExecutesScriptsAndPreservesSource() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 650), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = reader.view; window.orderBack(nil)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".HTML")
        let source = """
        <!doctype html><html><head><style>body{background:rgb(21,32,43)} h1{color:rgb(255,128,0)}</style></head>
        <body><h1 id="title">OrangeLen 中文🍊</h1><script>document.getElementById('title').textContent='executed'</script>
        <img id="pixel" src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7">
        <a id="link" href="https://example.com">External</a></body></html>
        """
        try source.write(to: url, atomically: true, encoding: .utf8)
        defer { reader.close(); window.orderOut(nil); try? FileManager.default.removeItem(at: url) }
        await load(reader, url)
        let preview = try XCTUnwrap(reader.htmlPreview)
        XCTAssertTrue(reader.currentContent === preview); XCTAssertTrue(reader.mode.isEnabled)
        try await settle(preview.webView)
        let values = try await preview.webView.evaluateJavaScript("[document.getElementById('title').textContent, getComputedStyle(document.getElementById('title')).color, document.getElementById('pixel').naturalWidth]") as? [Any]
        XCTAssertEqual(values?[0] as? String, "executed")
        XCTAssertEqual(values?[1] as? String, "rgb(255, 128, 0)")
        XCTAssertEqual(values?[2] as? Int, 1)
        _ = try await preview.webView.evaluateJavaScript("document.getElementById('link').click(); true")
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(preview.webView.url, url)
        reader.mode.selectedSegment = 1; reader.toggleSource()
        XCTAssertTrue(reader.currentContent === reader.scroll)
        XCTAssertEqual(reader.text.string, source)
        XCTAssertEqual(reader.text.model.copiedSource(NSRange(location: 0, length: source.utf16.count)), source)
        reader.mode.selectedSegment = 0; reader.toggleSource()
        XCTAssertTrue(reader.htmlPreview === preview)
        reader.close(); XCTAssertNil(reader.htmlPreview)
    }

    func testSwitchingFilesAndOversizeHTMLCannotKeepOldPreview() async throws {
        _ = NSApplication.shared
        let reader = ReaderController(); reader.loadViewIfNeeded(); defer { reader.close() }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let small = directory.appendingPathComponent("small.htm"), code = directory.appendingPathComponent("main.swift"), large = directory.appendingPathComponent("large.html")
        try "<h1>Hello</h1>".write(to: small, atomically: true, encoding: .utf8)
        try "let value = 42".write(to: code, atomically: true, encoding: .utf8)
        try String(repeating: "<p>content</p>\n", count: 100_000).write(to: large, atomically: true, encoding: .utf8)
        await load(reader, small); XCTAssertNotNil(reader.htmlPreview)
        await load(reader, code); XCTAssertNil(reader.htmlPreview); XCTAssertTrue(reader.currentContent === reader.scroll)
        await load(reader, large); XCTAssertNil(reader.htmlPreview); XCTAssertTrue(reader.source?.partial == true)
        XCTAssertTrue(reader.currentContent === reader.scroll); XCTAssertFalse(reader.mode.isEnabled)
    }
}

/// A loopback-only server: exercise WebKit's actual network stack without a CDN dependency.
private final class HTMLResourceServer {
    static let pixel = Data(base64Encoded: "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7")!
    let listener: NWListener
    let queue = DispatchQueue(label: "HTMLResourceServer")
    var port: UInt16? { listener.port?.rawValue }
    init() throws {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        listener = try NWListener(using: parameters)
    }
    func start(ready: @escaping () -> Void) {
        listener.stateUpdateHandler = { if case .ready = $0 { ready() } }
        listener.newConnectionHandler = { [queue] connection in
            connection.start(queue: queue)
            connection.receive(minimumIncompleteLength: 1, maximumLength: 16384) { data, _, _, _ in
                let path = String(data: data ?? Data(), encoding: .utf8)?.split(separator: " ").dropFirst().first.map(String.init) ?? ""
                let content: (String, Data)
                switch path {
                case "/style.css": content = ("text/css", Data("#remote{color:rgb(44,55,66)}".utf8))
                case "/script.js": content = ("text/javascript", Data("window.remoteScript=true".utf8))
                case "/module.js": content = ("text/javascript", Data("window.moduleScript=true; export default true;".utf8))
                case "/data.json": content = ("application/json", Data("{\"ok\":true}".utf8))
                default: content = ("image/gif", Self.pixel)
                }
                let headers = "HTTP/1.1 200 OK\r\nContent-Type: \(content.0)\r\nContent-Length: \(content.1.count)\r\nAccess-Control-Allow-Origin: *\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"
                connection.send(content: Data(headers.utf8) + content.1, completion: .contentProcessed { _ in connection.cancel() })
            }
        }
        listener.start(queue: queue)
    }
    func stop() { listener.cancel() }
}
