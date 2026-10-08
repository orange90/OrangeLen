import XCTest
import AppKit
@testable import OrangeLenUI
import OrangeLenCore

@MainActor final class RichContentTests: XCTestCase {
    func testMathAndMermaidKeepSourceMapping() throws {
        let source = #"""
        # Formula 👩🏽‍💻
        中文 $x_i^2 + \frac{a}{b}$ 后文。
        \(\sqrt{2}\) 与 \[\sum_{i=1}^n i\]

        $$
        \begin{pmatrix}a&b\\c&d\end{pmatrix}
        $$

        ```mermaid
        graph LR
          A[开始] --> B[完成]
        ```

        `$notMath$` and \$escaped\$ and $5 dollars.
        """#
        let model = try MarkdownModel.parse(source)
        XCTAssertEqual(model.richContent.count, 5)
        XCTAssertEqual(model.richContent.filter { $0.kind == .mermaid }.count, 1)
        XCTAssertTrue(model.richContent.contains { $0.content == #"x_i^2 + \frac{a}{b}"# })
        for item in model.richContent {
            XCTAssertEqual(model.copiedSource(item.range), (source as NSString).substring(with: item.source))
            XCTAssertEqual((model.display as NSString).substring(with: item.range), "\u{FFFC}")
            XCTAssertTrue(model.search(item.content).contains(item.range))
        }
        XCTAssertTrue(model.display.contains("$notMath$"))
        XCTAssertEqual(model.copiedSource((model.display as NSString).range(of: "后文")), "后文")
        XCTAssertEqual(model.copiedSource((model.display as NSString).range(of: "👩🏽‍💻")), "👩🏽‍💻")
        let styled = TextStyler.attributed(model, markdown: true, settings: .init())
        XCTAssertEqual(styled.length, (model.display as NSString).length)
    }
    func testRemoteImagesStayIdleUntilUserAction() async throws {
        _ = NSApplication.shared
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".md")
        try "![remote](https://example.com/test.png)".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: file) }
        let reader = ReaderController(); reader.loadViewIfNeeded()
        await withCheckedContinuation { continuation in reader.open(file) { _ in continuation.resume() } }
        XCTAssertEqual(reader.remoteAttempts, 0)
        XCTAssertNil(reader.remoteTask); XCTAssertNil(reader.remoteLoader)
        XCTAssertTrue(reader.markdownAssets.images.isEmpty)
        XCTAssertFalse(reader.remoteBar.isHidden)
        let placeholder = TextStyler.placeholderCell("加载远程图片", width: 200)
        XCTAssertGreaterThan(placeholder.image?.size.width ?? 0, 30)
        reader.close()
        XCTAssertNil(reader.remoteTask)
    }
    func testRemoteImagePolicy() throws {
        for target in ["http://example.com/a.png", "https://localhost/a", "https://secret@public.example/a", "https://a.local/x", "file:///a", "https://example.com:8443/a"] {
            XCTAssertThrowsError(try RemoteImagePolicy.url(target), target)
        }
        XCTAssertNoThrow(try RemoteImagePolicy.url("https://example.com/a.png?x=1"))
        for ip in ["127.0.0.1", "10.2.3.4", "0.0.0.0", "100.64.0.1", "169.254.169.254", "172.16.0.1", "192.168.1.1", "192.0.2.1", "198.18.0.1", "203.0.113.1", "224.0.0.1", "::1", "::ffff:127.0.0.1", "fc00::1", "fe80::1", "2001:db8::1", "2002:7f00:1::1", "64:ff9b::7f00:1"] {
            XCTAssertFalse(RemoteImagePolicy.isPublic(ip), ip)
        }
        XCTAssertTrue(RemoteImagePolicy.isPublic("1.1.1.1"))
        XCTAssertTrue(RemoteImagePolicy.isPublic("2606:4700:4700::1111"))
    }
    func testImageHTTPBoundaries() throws {
        func bytes(_ s: String) -> Data { Data(s.utf8) }
        let header = "HTTP/1.1 200 OK\r\nContent-Type: image/png\r\n"
        XCTAssertEqual(try ImageHTTPResponse.body(bytes(header + "Content-Length: 3\r\n\r\nabc")), bytes("abc"))
        XCTAssertNil(try ImageHTTPResponse.body(bytes(header + "Content-Length: 3\r\n\r\na")))
        XCTAssertEqual(try ImageHTTPResponse.body(bytes(header + "Transfer-Encoding: chunked\r\n\r\n3\r\nabc\r\n0\r\n\r\n")), bytes("abc"))
        for response in [
            "HTTP/1.1 302 Found\r\nLocation: https://127.0.0.1/x\r\n\r\n",
            "HTTP/1.1 200 OK\r\nContent-Type: image/svg+xml\r\n\r\n<svg/>",
            "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<script/>",
            header + "Content-Length: 999999999\r\n\r\n",
            header + "Content-Length: 3\r\nContent-Length: 2\r\n\r\nabc",
            header + "Content-Encoding: gzip\r\n\r\nabc",
            header + "Transfer-Encoding: chunked\r\nContent-Length: 1\r\n\r\na",
            header + "Transfer-Encoding: chunked\r\n\r\nffffffffffffffffffffffff\r\n"
        ] { XCTAssertThrowsError(try ImageHTTPResponse.body(bytes(response), eof: true)) }
        XCTAssertThrowsError(try ImagePreview.decode(Data("<svg xmlns='http://www.w3.org/2000/svg'><script>alert(1)</script></svg>".utf8), cancellation: .init()))
    }
    func testOfflineRendererAndInjectionRefusal() async throws {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 700), styleMask: [.titled], backing: .buffered, defer: false)
        let parent = NSView(frame: window.contentView!.bounds); window.contentView = parent
        window.orderBack(nil)
        let renderer = RichContentRenderer()
        defer { renderer.cancel(); window.orderOut(nil) }
        func item(_ kind: MarkdownRichContent.Kind, _ text: String) -> MarkdownRichContent { .init(range: NSRange(location: 0,length: 1), source: NSRange(location: 0,length: text.utf16.count), kind: kind, content: text) }
        let inline = try await renderer.render(item(.math, "E = mc^2"), in: parent)
        if let directory = ProcessInfo.processInfo.environment["ORANGELEN_EVIDENCE_DIR"], let tiff = inline.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff), let png = bitmap.representation(using: .png, properties: [:]) {
            try png.write(to: URL(fileURLWithPath: directory).appendingPathComponent("formula-inline.png"))
        }
        let math = try await renderer.render(item(.displayMath, #"\int_0^1 x^2\,dx = \frac{1}{3}"#), in: parent)
        XCTAssertGreaterThan(math.size.width, 50); XCTAssertGreaterThan(math.size.height, 20)
        let diagram = try await renderer.render(item(.mermaid, "graph LR\n A[开始] --> B{完成?}\n B --> C[是]"), in: parent)
        XCTAssertGreaterThan(diagram.size.width, 100)
        let sequence = try await renderer.render(item(.mermaid, "sequenceDiagram\n A->>B: Request\n B-->>A: Response"), in: parent)
        XCTAssertGreaterThan(sequence.size.height, 40)
        let classes = try await renderer.render(item(.mermaid, "classDiagram\n Animal <|-- Duck\n Animal : +int age"), in: parent)
        XCTAssertGreaterThan(classes.size.height, 40)
        for payload in ["graph LR\n A-->B\n click A \"https://example.com\"", "%%{init:{securityLevel:'loose'}}%%\ngraph LR\n A-->B", "graph LR\n A[<script>alert(1)</script>]"] {
            do { _ = try await renderer.render(item(.mermaid, payload), in: parent); XCTFail("Unsafe diagram accepted") } catch {}
        }
        do { _ = try await renderer.render(item(.math, #"\def\a{\a}\a"#), in: parent); XCTFail("Unbounded macro accepted") } catch {}
        renderer.cancel()
        do { _ = try await renderer.render(item(.math, "x"), in: parent); XCTFail("Cancelled renderer reused") } catch {}
    }
    func testRemoteCancellationAndOptionalPublicFetch() async throws {
        let cancelled = RemoteImageLoader(); cancelled.cancel()
        do { _ = try await cancelled.load("https://example.com/a.png"); XCTFail("Cancelled fetch ran") } catch {}
        guard ProcessInfo.processInfo.environment["ORANGELEN_NETWORK_TEST"] == "1" else { return }
        let data = try await RemoteImageLoader().load("https://www.w3.org/assets/logos/w3c-2025-transitional/w3c-72x48.png")
        let image = try ImagePreview.decode(data, cancellation: .init())
        XCTAssertGreaterThan(image.width, 1)
        for refused in ["https://127.0.0.1/private.png", "https://expired.badssl.com/test.png"] {
            do { _ = try await RemoteImageLoader().load(refused); XCTFail("Unsafe request succeeded") } catch {}
        }
    }
}
