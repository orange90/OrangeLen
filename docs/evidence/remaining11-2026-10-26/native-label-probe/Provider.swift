import AppKit
import QuickLookUI
import UniformTypeIdentifiers
import os
final class Provider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest, completionHandler handler: @escaping (QLPreviewReply?, Error?) -> Void) {
        let log=Logger(subsystem:"local.OrangeLen",category:"QuickLook")
        let name=request.fileURL.lastPathComponent
        log.notice("label-probe received file=\(name,privacy:.public)")
        do {
            let data=try Data(contentsOf:request.fileURL)
            let text="OrangeLen native file-type label diagnostic\n"+name+"\n"+(String(data:data,encoding:.utf8) ?? "Unreadable")
            handler(QLPreviewReply(dataOfContentType:.plainText,contentSize:CGSize(width:850,height:600)){_ in Data(text.utf8)},nil)
            log.notice("label-probe completed success=true file=\(name,privacy:.public)")
        } catch { log.notice("label-probe completed success=false file=\(name,privacy:.public)"); handler(nil,error) }
    }
}
