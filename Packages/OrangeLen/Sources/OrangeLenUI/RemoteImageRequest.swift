import Foundation
import OrangeLenCore

@MainActor final class RemoteImageRequest {
    private let direct = RemoteImageLoader()
    private var connection: NSXPCConnection?
    private var continuation: CheckedContinuation<Data, Error>?
    private var deadline: Task<Void, Never>?
    private var cancelled = false
    func cancel() {
        cancelled = true; direct.cancel(); finish(.failure(CancellationError()))
    }
    private func finish(_ result: Result<Data, Error>) {
        deadline?.cancel(); deadline = nil
        let callback = continuation; continuation = nil
        connection?.invalidate(); connection = nil
        callback?.resume(with: result)
    }
    func load(_ destination: String) async throws -> Data {
        guard !cancelled else { throw CancellationError() }
        _ = try RemoteImagePolicy.url(destination)
        if Bundle.main.bundleURL.pathExtension != "appex" { return try await direct.load(destination) }
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { callback in
                guard !cancelled else { callback.resume(throwing: CancellationError()); return }
                continuation = callback
                let connection = NSXPCConnection(serviceName: "local.OrangeLen.ImageBroker")
                self.connection = connection
                connection.remoteObjectInterface = NSXPCInterface(with: ImageBrokerProtocol.self)
                connection.invalidationHandler = { [weak self] in Task { @MainActor in self?.finish(.failure(PreviewError.malformed("图片下载服务连接已关闭"))) } }
                connection.interruptionHandler = { [weak self] in Task { @MainActor in self?.finish(.failure(PreviewError.malformed("图片下载服务中断"))) } }
                connection.resume()
                deadline = Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 20_000_000_000)
                    guard !Task.isCancelled else { return }; self?.finish(.failure(PreviewError.limit("图片下载服务超时")))
                }
                guard let proxy = connection.remoteObjectProxyWithErrorHandler({ [weak self] error in
                    Task { @MainActor in self?.finish(.failure(error)) }
                }) as? ImageBrokerProtocol else { finish(.failure(PreviewError.malformed("图片下载服务不可用"))); return }
                proxy.fetchImage(destination) { [weak self] data, message in
                    Task { @MainActor in
                        if let data, data.count <= RemoteImagePolicy.byteLimit { self?.finish(.success(data)) }
                        else { self?.finish(.failure(PreviewError.malformed(message ?? "图片数据无效"))) }
                    }
                }
            }
        }, onCancel: { Task { @MainActor [weak self] in self?.cancel() } })
    }
}
