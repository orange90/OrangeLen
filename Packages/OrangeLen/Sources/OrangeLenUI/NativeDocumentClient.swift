import AppKit
import OrangeLenCore

/// Called only from the bounded parsing lane; never blocks the main thread.
enum NativeDocumentClient {
    static func load(_ data: Data, type: NSAttributedString.DocumentType, cancellation: Cancellation, onReady: @escaping () -> Void = {}) throws -> NSAttributedString {
        guard data.count <= 25 * 1024 * 1024 else { throw PreviewError.limit("文档输入最多 25 MiB") }
        try cancellation.check()
        let connection = NSXPCConnection(serviceName: "local.OrangeLen.DocumentBroker")
        connection.remoteObjectInterface = NSXPCInterface(with: DocumentBrokerProtocol.self)
        let lock = NSLock(), ready = DispatchSemaphore(value: 0), started = DispatchSemaphore(value: 0)
        var result: Result<Data, Error>?
        func finish(_ value: Result<Data, Error>) { lock.lock(); guard result == nil else { lock.unlock(); return }; result = value; lock.unlock(); ready.signal(); started.signal() }
        connection.interruptionHandler = { finish(.failure(PreviewError.limit("原生文档导入超时、内存超限或服务中断；可重载或用默认应用打开"))) }
        connection.invalidationHandler = { finish(.failure(PreviewError.malformed("文档服务不可用或连接已关闭；可重载或用默认应用打开"))) }
        connection.resume()
        let observer = cancellation.onCancel { finish(.failure(CancellationError())); connection.invalidate() }
        defer { cancellation.removeObserver(observer); connection.invalidate() }
        guard let broker = connection.remoteObjectProxyWithErrorHandler({ finish(.failure($0)) }) as? DocumentBrokerProtocol else { throw PreviewError.malformed("文档导入服务不可用") }
        // First sandbox/container initialization can take longer than parsing.
        // Keep startup bounded separately; cancellation still ends either wait.
        broker.prepare { started.signal() }
        guard started.wait(timeout: .now() + 30) == .success else { throw PreviewError.limit("文档服务启动超过 30 秒，请重试") }
        try cancellation.check()
        lock.lock(); let startupResult = result; lock.unlock()
        if let startupResult { _ = try startupResult.get() }
        onReady()
        broker.importDocument(data, type: type.rawValue) { output, error in
            if let output, output.count <= 8 * 1024 * 1024 { finish(.success(output)) }
            else { finish(.failure(PreviewError.malformed(error ?? "文档导入无结果"))) }
        }
        guard ready.wait(timeout: .now() + 6) == .success else { throw PreviewError.limit("原生文档导入超过 6 秒，可重试") }
        try cancellation.check()
        lock.lock(); let resolved = result; lock.unlock()
        let output = try resolved!.get()
        let payload = try JSONDecoder().decode(NativeDocumentPayload.self, from: output)
        return try attributed(payload)
    }
    static func attributed(_ payload: NativeDocumentPayload) throws -> NSAttributedString {
        try payload.validate()
        let result = NSMutableAttributedString(string: payload.text, attributes: [.font: NSFont.systemFont(ofSize: 14), .foregroundColor: NSColor.black])
        for span in payload.spans {
            var font = NSFont.systemFont(ofSize: span.size)
            if span.bold { font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask) }
            if span.italic { font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask) }
            result.addAttribute(.font, value: font, range: NSRange(location: span.location, length: span.length))
        }
        return result
    }
}
