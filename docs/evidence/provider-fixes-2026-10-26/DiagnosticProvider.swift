import AppKit
import QuickLookUI
import UniformTypeIdentifiers
import os
final class Provider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest, completionHandler handler: @escaping (QLPreviewReply?, Error?) -> Void) {
        let ext = request.fileURL.pathExtension
        let log = Logger(subsystem: "local.OrangeLen", category: "QuickLook")
        log.notice("probe received extension=OrangeLenProbe type=\(ext, privacy: .public)")
        let message = "OrangeLen native data-provider diagnostic\n" + request.fileURL.lastPathComponent
        handler(QLPreviewReply(dataOfContentType: .plainText, contentSize: CGSize(width: 800, height: 600)) { _ in Data(message.utf8) }, nil)
        log.notice("probe completed success=true type=\(ext, privacy: .public)")
    }
}
