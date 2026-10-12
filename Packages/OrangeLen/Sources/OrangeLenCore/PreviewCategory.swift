import Foundation

public enum PreviewCategory: String, CaseIterable, Sendable {
    case code = "Code", markdown = "Markdown", data = "Data", folders = "Folders", archives = "Archives", books = "Books", drawings = "Drawings"
    public static func detect(_ url: URL) -> Self {
        if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true { return .folders }
        let ext = url.pathExtension.lowercased()
        if ["drawio", "canvas", "obj", "stl", "gltf", "glb", "png", "webp", "mmd", "mermaid", "svg", "excalidraw"].contains(ext) { return .drawings }
        if ["mdx", "tex", "typ", "md", "markdown", "ipynb"].contains(ext) { return .markdown }
        if ext == "epub" { return .books }
        if ["npz", "n8np", "mcpb", "dxt", "skill", "zip", "tar", "tgz", "gz"].contains(ext) { return .archives }
        if ["xmp", "c2pa", "parquet", "npy", "safetensors", "gguf", "latent", "srt", "vtt", "json", "jsonc", "json5", "jsonl", "ndjson", "csv", "tsv", "xml", "yaml", "yml", "toml", "sqlite", "sqlite3", "db", "har", "diff", "patch"].contains(ext) { return .data }
        return .code
    }
}
