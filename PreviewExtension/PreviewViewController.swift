import AppKit
import Quartz
import OrangeLenUI
import os
final class PreviewViewController: NSViewController, QLPreviewingController {
    let reader = ReaderController()
    let logger = Logger(subsystem: "local.OrangeLen", category: "QuickLook")
    override func loadView() {
        addChild(reader)
        view = reader.view
        preferredContentSize = NSSize(width: 1000, height: 720)
    }
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        loadViewIfNeeded()
        logger.notice("prepare received extension=OrangeLen type=\(url.pathExtension, privacy: .public)")
        reader.open(url) { [logger] error in
            logger.notice("prepare completed success=\(error == nil, privacy: .public)")
            // Present actionable read/parse errors in our view instead of hiding them behind a generic system card.
            handler(error is CancellationError ? error : nil)
        }
    }
    override func viewDidDisappear() {
        super.viewDidDisappear()
        reader.close()
        logger.notice("preview disappeared")
    }
}
