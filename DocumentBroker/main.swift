import AppKit
import OrangeLenCore
import Darwin

private let workerLock = NSLock()
private var activeRequest: UUID?

final class DocumentBroker: NSObject, DocumentBrokerProtocol {
    let request = UUID()
    private var used = false
    func prepare(reply: @escaping () -> Void) { reply() }
    func importDocument(_ data: Data, type: String, reply: @escaping (Data?, String?) -> Void) {
        workerLock.lock()
        guard !used, activeRequest == nil else { workerLock.unlock(); reply(nil, L10n.text("文档导入繁忙，请重载")); return }
        used = true; activeRequest = request; workerLock.unlock()
        let accepted: Set<String> = [NSAttributedString.DocumentType.docFormat.rawValue, NSAttributedString.DocumentType.officeOpenXML.rawValue, NSAttributedString.DocumentType.openDocument.rawValue, NSAttributedString.DocumentType.rtf.rawValue]
        guard accepted.contains(type), data.count <= 25 * 1024 * 1024 else { release(); reply(nil, L10n.text("文档输入超出范围")); return }
        let start = ImageDirectoryGrant.continuousTime()
        let watchdog = DispatchSource.makeTimerSource(queue: .global(qos: .userInitiated))
        watchdog.schedule(deadline: .now(), repeating: .milliseconds(50))
        watchdog.setEventHandler { [request] in
            workerLock.lock(); let running = activeRequest == request; workerLock.unlock()
            guard running else { return }
            var info = mach_task_basic_info(), count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
            let result = withUnsafeMutablePointer(to: &info) { pointer in pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count) } }
            if ImageDirectoryGrant.continuousTime() - start > 5 || (result == KERN_SUCCESS && info.resident_size > 256 * 1024 * 1024) { _exit(70) }
        }
        watchdog.resume()
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            defer { watchdog.cancel(); release() }
            autoreleasepool {
                do {
                    let documentType = NSAttributedString.DocumentType(rawValue: type)
                    if documentType == .officeOpenXML || documentType == .openDocument {
                        try ArchiveDocument.parse(data, name: "document.zip").validateForNativeImport()
                    }
                    let document = try NSAttributedString(data: data, options: [.documentType: documentType], documentAttributes: nil)
                    guard document.length <= 1_000_000 else { throw PreviewError.limit(L10n.text("文档文字超过 100 万 UTF-16 单元")) }
                    var spans: [NativeDocumentPayload.Span] = [], exceeded = false
                    document.enumerateAttribute(.font, in: NSRange(location: 0, length: document.length)) { value, range, stop in
                        guard spans.count < 20_000 else { exceeded = true; stop.pointee = true; return }
                        let font = value as? NSFont ?? NSFont.systemFont(ofSize: 14)
                        let traits = NSFontManager.shared.traits(of: font)
                        spans.append(.init(location: range.location, length: range.length, size: min(72, max(6, font.pointSize)), bold: traits.contains(.boldFontMask), italic: traits.contains(.italicFontMask)))
                    }
                    guard !exceeded else { throw PreviewError.limit(L10n.text("文档格式片段")) }
                    let payload = NativeDocumentPayload(text: document.string.replacingOccurrences(of: "\u{FFFC}", with: "□"), spans: spans)
                    try payload.validate()
                    let output = try JSONEncoder().encode(payload)
                    guard output.count <= 8 * 1024 * 1024 else { throw PreviewError.limit(L10n.text("文档输出")) }
                    reply(output, nil)
                } catch { reply(nil, String(error.localizedDescription.prefix(1000))) }
            }
        }
    }
    func release() { workerLock.lock(); if activeRequest == request { activeRequest = nil }; workerLock.unlock() }
    func cancel() {
        workerLock.lock(); let running = activeRequest == request; workerLock.unlock()
        if running { _exit(71) } // Terminate an uninterruptible system importer.
    }
}
final class ListenerDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        let broker = DocumentBroker()
        connection.exportedInterface = NSXPCInterface(with: DocumentBrokerProtocol.self)
        connection.exportedObject = broker
        connection.invalidationHandler = { broker.cancel() }
        connection.interruptionHandler = { broker.cancel() }
        connection.resume(); return true
    }
}
let delegate = ListenerDelegate(), listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
