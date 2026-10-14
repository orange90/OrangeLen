import XCTest
import AppKit
import WebKit
import OrangeLenCore
@testable import OrangeLenUI

/// Each inventory extension must reach a substantive view, not merely finish without error.
@MainActor final class FormatInventoryAuditTests: XCTestCase {
    func check(_ ext: String) async throws {
        try await check(ext, folder: false)
        try await check(ext, folder: true)
    }
    private func check(_ ext: String, folder: Bool) async throws {
        _ = NSApplication.shared
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let name = ext == "gz" ? "audit.log.gz" : "audit." + ext
        let url = root.appendingPathComponent("Tests/Fixtures/format-audit-106/" + name)
        let reader = ReaderController(); reader.loadViewIfNeeded()
        // Deliberately use the broad Code candidate even for specialized formats.
        // Launch Services can select an overlapping category for a single file.
        reader.previewCategory = folder ? PreviewCategory.folders.rawValue : PreviewCategory.code.rawValue
        let window = NSWindow(contentRect: NSRect(x:0,y:0,width:1000,height:720), styleMask:[.titled], backing:.buffered, defer:false)
        window.contentViewController = reader; window.orderBack(nil)
        defer { reader.close(); window.contentViewController = nil; window.orderOut(nil) }
        let ready = expectation(description: ext)
        var loadError: Error?
        let started = Date()
        if folder {
            reader.open(url.deletingLastPathComponent()) { XCTAssertNil($0) }
            reader.loadFile(url) { error in loadError = error; ready.fulfill() }
        } else {
            reader.open(url) { error in loadError = error; ready.fulfill() }
        }
        await fulfillment(of:[ready], timeout:45)
        XCTAssertNil(loadError, ext)
        // Generic archives initially show their tree; select an actual readable member.
        if ["zip","tar","tgz"].contains(ext), let archive = reader.archiveController {
            let row = (0..<archive.outline.numberOfRows).first { index in
                guard let node = archive.outline.item(atRow:index) as? ArchiveController.Node,
                      let entry = node.entry, !entry.directory, entry.blocked == nil else { return false }
                return ReadableFormat.isText(URL(fileURLWithPath:entry.path))
            }
            archive.outline.selectRowIndexes(IndexSet(integer:try XCTUnwrap(row)),byExtendingSelection:false)
        }
        // Containers finish their outer load before their selected child has finished rendering.
        for _ in 0..<250 {
            let child = reader.collection?.reader ?? reader.archiveController?.reader
            if child == nil || (child?.source != nil && child?.completion == nil) { break }
            try await Task.sleep(nanoseconds:20_000_000)
        }
        var kind = "source"; var substantive = false
        if ["obj","stl","gltf","glb"].contains(ext) { kind = "3D"; substantive = (reader.advancedView as? MeshPreview)?.canvas.image != nil }
        else if ["c2pa","parquet","npy","safetensors","gguf","latent"].contains(ext) { kind = "structure"; substantive = (reader.advancedView as? ScientificPreview)?.table.data.rows.isEmpty == false }
        else if ["drawio","canvas"].contains(ext) { kind = "diagram"; substantive = (reader.advancedView as? DiagramPreview)?.canvas.image != nil }
        else if ["jsx","tsx","mdx","mmd","mermaid","svg","excalidraw"].contains(ext) { kind = "rendered-image"; substantive = reader.canvasImage != nil }
        else if ["tex","typ","pdf"].contains(ext) { kind = "PDF"; substantive = reader.pdf.document?.pageCount ?? 0 > 0 }
        else if ["sqlite","sqlite3","db"].contains(ext) {
            kind = "database"
            for _ in 0..<250 { if reader.databaseController?.page != nil { break }; try await Task.sleep(nanoseconds:20_000_000) }
            substantive = reader.databaseController?.page?.rows.isEmpty == false
        }
        else if ["zip","tar","tgz","skill","mcpb","dxt","npz","n8np"].contains(ext) { kind = "archive"; substantive = reader.archiveController?.reader.source?.text.isEmpty == false }
        else if ["epub","ipynb","jsonl","ndjson","diff","patch","har","gz"].contains(ext) { kind = "collection"; substantive = reader.collection?.reader.source?.text.isEmpty == false }
        else if ["json","jsonc","json5"].contains(ext) { kind = "JSON-tree"; substantive = reader.jsonTree?.root.children.isEmpty == false }
        else if ["csv","tsv","srt","vtt"].contains(ext) { kind = "table"; substantive = reader.tableData?.rows.isEmpty == false }
        else if ["html","htm"].contains(ext) {
            kind = "HTML"
            if let preview = reader.htmlPreview {
                for _ in 0..<250 { if !preview.webView.isLoading { break }; try await Task.sleep(nanoseconds:20_000_000) }
                substantive = (try? await preview.webView.evaluateJavaScript("document.body.innerText.includes('OrangeLen')")) as? Bool == true
            }
        }
        else if ["md","markdown"].contains(ext) { kind = "Markdown"; substantive = reader.rendered?.display.isEmpty == false && !reader.text.string.isEmpty }
        else { substantive = reader.source?.text.isEmpty == false && reader.text.string == reader.source?.text }
        XCTAssertTrue(substantive, "No substantive " + kind + " view for ." + ext + ": " + reader.text.string + " " + reader.parseWarning)
        let record: [String:Any] = ["extension":ext,"entry":folder ? "folder" : "single-file-overlapping-category","passed":substantive && loadError == nil,"kind":kind,"seconds":Date().timeIntervalSince(started),"warning":reader.parseWarning,"error":loadError?.localizedDescription ?? ""]
        let data = try JSONSerialization.data(withJSONObject:record, options:[.sortedKeys])
        guard let directory = ProcessInfo.processInfo.environment["ORANGELEN_FORMAT_AUDIT_EVIDENCE_DIR"] else { return }
        let evidence = URL(fileURLWithPath:directory).appendingPathComponent("reader-results.jsonl")
        if !FileManager.default.fileExists(atPath:evidence.path) { FileManager.default.createFile(atPath:evidence.path,contents:nil) }
        let handle = try FileHandle(forWritingTo:evidence); try handle.seekToEnd(); try handle.write(contentsOf:data + Data([10])); try handle.close()
    }
    func test_swift() async throws { try await check("swift") }
    func test_py() async throws { try await check("py") }
    func test_js() async throws { try await check("js") }
    func test_ts() async throws { try await check("ts") }
    func test_tsx() async throws { try await check("tsx") }
    func test_jsx() async throws { try await check("jsx") }
    func test_mjs() async throws { try await check("mjs") }
    func test_cjs() async throws { try await check("cjs") }
    func test_mts() async throws { try await check("mts") }
    func test_cts() async throws { try await check("cts") }
    func test_vue() async throws { try await check("vue") }
    func test_svelte() async throws { try await check("svelte") }
    func test_astro() async throws { try await check("astro") }
    func test_c() async throws { try await check("c") }
    func test_h() async throws { try await check("h") }
    func test_cpp() async throws { try await check("cpp") }
    func test_hpp() async throws { try await check("hpp") }
    func test_rs() async throws { try await check("rs") }
    func test_go() async throws { try await check("go") }
    func test_sh() async throws { try await check("sh") }
    func test_zsh() async throws { try await check("zsh") }
    func test_bash() async throws { try await check("bash") }
    func test_rb() async throws { try await check("rb") }
    func test_java() async throws { try await check("java") }
    func test_kt() async throws { try await check("kt") }
    func test_css() async throws { try await check("css") }
    func test_scss() async throws { try await check("scss") }
    func test_sass() async throws { try await check("sass") }
    func test_less() async throws { try await check("less") }
    func test_html() async throws { try await check("html") }
    func test_htm() async throws { try await check("htm") }
    func test_xhtml() async throws { try await check("xhtml") }
    func test_sql() async throws { try await check("sql") }
    func test_cs() async throws { try await check("cs") }
    func test_php() async throws { try await check("php") }
    func test_dart() async throws { try await check("dart") }
    func test_lua() async throws { try await check("lua") }
    func test_r() async throws { try await check("r") }
    func test_scala() async throws { try await check("scala") }
    func test_ps1() async throws { try await check("ps1") }
    func test_proto() async throws { try await check("proto") }
    func test_graphql() async throws { try await check("graphql") }
    func test_gql() async throws { try await check("gql") }
    func test_tf() async throws { try await check("tf") }
    func test_tfvars() async throws { try await check("tfvars") }
    func test_hcl() async throws { try await check("hcl") }
    func test_txt() async throws { try await check("txt") }
    func test_log() async throws { try await check("log") }
    func test_ini() async throws { try await check("ini") }
    func test_conf() async throws { try await check("conf") }
    func test_config() async throws { try await check("config") }
    func test_properties() async throws { try await check("properties") }
    func test_plist() async throws { try await check("plist") }
    func test_yaml() async throws { try await check("yaml") }
    func test_yml() async throws { try await check("yml") }
    func test_toml() async throws { try await check("toml") }
    func test_xml() async throws { try await check("xml") }
    func test_md() async throws { try await check("md") }
    func test_markdown() async throws { try await check("markdown") }
    func test_mdx() async throws { try await check("mdx") }
    func test_tex() async throws { try await check("tex") }
    func test_typ() async throws { try await check("typ") }
    func test_ipynb() async throws { try await check("ipynb") }
    func test_epub() async throws { try await check("epub") }
    func test_pdf() async throws { try await check("pdf") }
    func test_json() async throws { try await check("json") }
    func test_jsonc() async throws { try await check("jsonc") }
    func test_json5() async throws { try await check("json5") }
    func test_jsonl() async throws { try await check("jsonl") }
    func test_ndjson() async throws { try await check("ndjson") }
    func test_csv() async throws { try await check("csv") }
    func test_tsv() async throws { try await check("tsv") }
    func test_sqlite() async throws { try await check("sqlite") }
    func test_sqlite3() async throws { try await check("sqlite3") }
    func test_db() async throws { try await check("db") }
    func test_har() async throws { try await check("har") }
    func test_mmd() async throws { try await check("mmd") }
    func test_mermaid() async throws { try await check("mermaid") }
    func test_excalidraw() async throws { try await check("excalidraw") }
    func test_drawio() async throws { try await check("drawio") }
    func test_canvas() async throws { try await check("canvas") }
    func test_svg() async throws { try await check("svg") }
    func test_skill() async throws { try await check("skill") }
    func test_mcpb() async throws { try await check("mcpb") }
    func test_dxt() async throws { try await check("dxt") }
    func test_n8np() async throws { try await check("n8np") }
    func test_zip() async throws { try await check("zip") }
    func test_tar() async throws { try await check("tar") }
    func test_tgz() async throws { try await check("tgz") }
    func test_gz() async throws { try await check("gz") }
    func test_obj() async throws { try await check("obj") }
    func test_stl() async throws { try await check("stl") }
    func test_gltf() async throws { try await check("gltf") }
    func test_glb() async throws { try await check("glb") }
    func test_parquet() async throws { try await check("parquet") }
    func test_npy() async throws { try await check("npy") }
    func test_npz() async throws { try await check("npz") }
    func test_safetensors() async throws { try await check("safetensors") }
    func test_gguf() async throws { try await check("gguf") }
    func test_latent() async throws { try await check("latent") }
    func test_srt() async throws { try await check("srt") }
    func test_vtt() async throws { try await check("vtt") }
    func test_diff() async throws { try await check("diff") }
    func test_patch() async throws { try await check("patch") }
    func test_xmp() async throws { try await check("xmp") }
    func test_c2pa() async throws { try await check("c2pa") }
}
