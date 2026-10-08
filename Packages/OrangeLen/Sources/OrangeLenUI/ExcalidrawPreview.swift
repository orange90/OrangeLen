import AppKit
import OrangeLenCore

/// Bounded input for the bundled exporter. Original JSON stays available in source mode.
struct ExcalidrawPreview {
    let json: String
    let warning: String
    let count: Int

    static func parse(_ source: String, cancellation: Cancellation = .init()) throws -> Self {
        guard source.utf8.count <= PreviewLimits().fileBytes else { throw PreviewError.limit(L10n.text("Excalidraw 文件最大 5 MiB")) }
        _ = try JSONParser.parse(source, cancellation: cancellation)
        guard let document = try JSONSerialization.jsonObject(with: Data(source.utf8)) as? [String: Any],
              document["type"] as? String == "excalidraw",
              let elements = document["elements"] as? [[String: Any]] else { throw PreviewError.malformed(L10n.text("不是 Excalidraw 画布")) }
        guard elements.count <= 1000 else { throw PreviewError.limit(L10n.text("画布最多 1,000 个元素")) }
        let types: Set<String> = ["rectangle", "diamond", "ellipse", "text", "line", "arrow", "freedraw", "image", "frame", "magicframe"]
        let keys: Set<String> = ["id", "type", "x", "y", "width", "height", "angle", "strokeColor", "backgroundColor", "fillStyle", "strokeWidth", "strokeStyle", "roughness", "opacity", "seed", "version", "versionNonce", "isDeleted", "groupIds", "frameId", "roundness", "boundElements", "points", "pressures", "simulatePressure", "lastCommittedPoint", "startBinding", "endBinding", "startArrowhead", "endArrowhead", "elbowed", "fixedSegments", "startIsSpecial", "endIsSpecial", "text", "originalText", "fontSize", "fontFamily", "textAlign", "verticalAlign", "containerId", "lineHeight", "autoResize", "fileId", "status", "scale", "crop", "name", "locked"]
        var clean: [[String: Any]] = []; var skipped = 0; var pointCount = 0
        var ids = Set<String>()
        for element in elements {
            try cancellation.check()
            if element["isDeleted"] as? Bool == true { continue }
            guard let type = element["type"] as? String, types.contains(type) else { skipped += 1; continue }
            guard let id = element["id"] as? String, !id.isEmpty, ids.insert(id).inserted else { throw PreviewError.malformed(L10n.text("画布元素 ID 缺失或重复")) }
            var item = element.filter { keys.contains($0.key) }
            for key in ["x", "y", "width", "height", "angle", "fontSize", "lineHeight", "strokeWidth", "roughness"] {
                if let raw = element[key] {
                    guard let number = raw as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue.isFinite, abs(number.doubleValue) <= 1_000_000 else { throw PreviewError.malformed(L10n.text("画布坐标或尺寸无效")) }
                }
            }
            for key in ["x", "y", "width", "height"] where item[key] == nil { throw PreviewError.malformed(L10n.text("画布缺少坐标或尺寸")) }
            for key in ["width", "height", "fontSize", "lineHeight", "strokeWidth", "roughness"] {
                if let number = item[key] as? NSNumber, number.doubleValue < 0 { throw PreviewError.malformed(L10n.text("画布尺寸不能为负")) }
            }
            if let points = item["points"] as? [[Double]] {
                pointCount += points.count
                guard pointCount <= 10000, points.allSatisfy({ $0.count == 2 && $0.allSatisfy({ $0.isFinite && abs($0) <= 1_000_000 }) }) else { throw PreviewError.limit(L10n.text("画布路径点预算或坐标无效")) }
            } else if item["points"] != nil { throw PreviewError.malformed(L10n.text("画布路径点无效")) }
            for key in ["strokeColor", "backgroundColor"] { item[key] = color(item[key] as? String, fallback: key == "strokeColor" ? "#1b1b1f" : "transparent") }
            // Unbundled font families fall back to local system fonts; no font URLs are accepted.
            if let font = item["fontFamily"] as? Int, ![1, 2, 3, 5].contains(font) { item["fontFamily"] = 2 }
            clean.append(item)
        }
        var files: [String: Any] = [:]; var unavailable = 0; var pixels = 0
        let originals = document["files"] as? [String: [String: Any]] ?? [:]
        for id in Set(clean.compactMap { $0["type"] as? String == "image" ? $0["fileId"] as? String : nil }) {
            try cancellation.check()
            guard let file = originals[id], let uri = file["dataURL"] as? String,
                  let comma = uri.firstIndex(of: ","),
                  ["data:image/png;base64", "data:image/jpeg;base64", "data:image/gif;base64", "data:image/webp;base64"].contains(String(uri[..<comma]).lowercased()),
                  let data = Data(base64Encoded: String(uri[uri.index(after: comma)...])),
                  let decoded = try? ImagePreview.decode(data, cancellation: cancellation, maxPixelSize: 1600, maxSourcePixels: 25_000_000),
                  pixels + decoded.image.width * decoded.image.height <= 8_000_000 else { unavailable += 1; continue }
            pixels += decoded.image.width * decoded.image.height
            let bitmap = NSBitmapImageRep(cgImage: decoded.image)
            guard let png = bitmap.representation(using: .png, properties: [:]) else { unavailable += 1; continue }
            files[id] = ["id": id, "mimeType": "image/png", "dataURL": "data:image/png;base64," + png.base64EncodedString(), "created": 0]
        }
        let appState = document["appState"] as? [String: Any]
        let data = try JSONSerialization.data(withJSONObject: ["elements": clean, "files": files, "background": color(appState?["viewBackgroundColor"] as? String, fallback: "#ffffff")])
        let warnings = [skipped > 0 ? L10n.text("\(skipped) 个网页嵌入或未知元素未渲染") : "", unavailable > 0 ? L10n.text("\(unavailable) 张图片缺失或不支持（仅内嵌栅格图片）") : ""].filter { !$0.isEmpty }
        return Self(json: String(decoding: data, as: UTF8.self), warning: warnings.joined(separator: "；"), count: clean.count)
    }
    private static func color(_ string: String?, fallback: String) -> String {
        guard let string, string.range(of: #"^(#[0-9a-fA-F]{3,8}|[a-zA-Z]{1,24})$"#, options: .regularExpression) != nil else { return fallback }
        return string
    }
}
