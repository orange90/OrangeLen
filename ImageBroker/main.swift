import Foundation
import OrangeLenCore

final class ImageBroker: NSObject, ImageBrokerProtocol, @unchecked Sendable {
    let loader = RemoteImageLoader()
    private let lock = NSLock()
    private var started = false
    func fetchImage(_ destination: String, reply: @escaping (Data?, String?) -> Void) {
        lock.lock(); let alreadyStarted = started; started = true; lock.unlock()
        guard !alreadyStarted else { reply(nil, L10n.text("每个图片连接仅接受一次请求")); return }
        Task {
            do { reply(try await loader.load(destination), nil) }
            catch { reply(nil, error.localizedDescription) }
        }
    }
}
final class ListenerDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        let broker = ImageBroker()
        connection.exportedInterface = NSXPCInterface(with: ImageBrokerProtocol.self)
        connection.exportedObject = broker
        connection.invalidationHandler = { broker.loader.cancel() }
        connection.interruptionHandler = { broker.loader.cancel() }
        connection.resume(); return true
    }
}
let delegate = ListenerDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
