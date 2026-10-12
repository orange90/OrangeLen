import Foundation
import WebKit

/// Per-renderer, read-only resources. Document scripts cannot name arbitrary files.
final class EmbeddedResourceHandler: NSObject, WKURLSchemeHandler {
    var input: Data?
    private let names: Set<String> = ["typst.wasm","parquet.wasm","LibertinusSerif-Regular.otf","NewCMMath-Book.otf","NotoSerifCJKsc-Regular.otf"]
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url, url.host == "assets", url.query == nil else { task.didFailWithError(URLError(.badURL)); return }
        let name = url.lastPathComponent
        guard url.path == "/" + name else { task.didFailWithError(URLError(.badURL)); return }
        do {
            let data: Data
            if name == "input.parquet", let input { data = input }
            else {
                guard names.contains(name), let file = Bundle.module.url(forResource:(name as NSString).deletingPathExtension,withExtension:(name as NSString).pathExtension) else { throw URLError(.resourceUnavailable) }
                data = try Data(contentsOf:file,options:.mappedIfSafe)
            }
            let response = HTTPURLResponse(url:url,statusCode:200,httpVersion:"HTTP/1.1",headerFields:["Content-Type":name.hasSuffix("wasm") ? "application/wasm" : "application/octet-stream","Content-Length":String(data.count),"Access-Control-Allow-Origin":"*"])!
            task.didReceive(response); task.didReceive(data); task.didFinish()
        } catch { task.didFailWithError(error) }
    }
    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) { }
}
