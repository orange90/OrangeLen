import Foundation
import UniformTypeIdentifiers

public enum ReadableFormat {
    public static func isCollection(_ url: URL) -> Bool {
        ["openapi.json","swagger.json"].contains(url.lastPathComponent.lowercased()) || ["har","epub","jsonl","ndjson","diff","patch","sqlite","sqlite3","db","zip","tar","tgz","gz","ipynb"].contains(url.pathExtension.lowercased())
    }
    public static func isText(_ url: URL) -> Bool {
        if ["Makefile","Dockerfile","Gemfile","LICENSE","README",".gitignore",".env"].contains(url.lastPathComponent) { return true }
        let ext = url.pathExtension.lowercased()
        if ["txt","md","markdown","json","yaml","yml","toml","xml","csv","tsv","swift","py","js","ts","tsx","jsx","c","h","cpp","hpp","rs","go","sh","zsh","bash","rb","java","kt","css","html","sql","log","ini","conf","plist","diff","patch"].contains(ext) { return true }
        return UTType(filenameExtension:ext)?.conforms(to:.text) == true
    }
}
