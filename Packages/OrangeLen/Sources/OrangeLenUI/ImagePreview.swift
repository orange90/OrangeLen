import AppKit
import ImageIO
import OrangeLenCore

struct ImagePreview {
    let image: CGImage
    let width: Int
    let height: Int
    let bytes: Int
    static func supports(_ url: URL) -> Bool {
        ["png", "jpg", "jpeg", "gif", "tif", "tiff", "heic", "heif", "webp", "bmp", "ico"].contains(url.pathExtension.lowercased())
    }
    static func load(_ url: URL, root: URL?, cancellation: Cancellation, maxBytes: Int = 25 * 1024 * 1024, maxPixelSize: Int = 2048) throws -> Self {
        var limits = PreviewLimits(); limits.fileBytes = maxBytes
        let raw = try AccessBroker.readBytes(url, root: root, limits: limits, cancellation: cancellation)
        return try decode(raw.data, cancellation: cancellation, maxPixelSize: maxPixelSize)
    }
    static func decode(_ data: Data, cancellation: Cancellation, maxPixelSize: Int = 1200, maxSourcePixels: Int = 100_000_000) throws -> Self {
        try cancellation.check()
        guard data.count <= 25 * 1024 * 1024 else { throw PreviewError.limit("图片字节预算") }
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let type = CGImageSourceGetType(source) as String?,
              ["public.png", "public.jpeg", "com.compuserve.gif", "public.tiff", "public.heic", "public.heif", "org.webmproject.webp", "com.microsoft.bmp", "com.microsoft.ico", "public.avif"].contains(type),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0, width <= maxSourcePixels / height else { throw PreviewError.limit("无效图片或超过源像素预算") }
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary) else { throw PreviewError.malformed("无法解码图片") }
        try cancellation.check()
        return Self(image: image, width: width, height: height, bytes: data.count)
    }
}
