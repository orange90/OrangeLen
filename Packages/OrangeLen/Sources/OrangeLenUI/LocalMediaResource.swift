import AVFoundation
import UniformTypeIdentifiers
import OrangeLenCore

final class LocalMediaResource: NSObject, AVAssetResourceLoaderDelegate {
    let asset: AVURLAsset
    private let file: ScopedMediaFile
    private let token = Cancellation()
    private let queue = DispatchQueue(label: "OrangeLen.media", qos: .utility)
    private let contentType: String
    private var requests: Set<ObjectIdentifier> = []
    init(_ url: URL, root: URL?) throws {
        file = try ScopedMediaFile(url, root: root)
        contentType = UTType(filenameExtension: url.pathExtension)?.identifier ?? "public.data"
        let local = URL(string: "orangelen-local:///" + UUID().uuidString + "." + url.pathExtension)!
        asset = AVURLAsset(url: local, options: [AVURLAssetReferenceRestrictionsKey: AVAssetReferenceRestrictions.forbidAll.rawValue])
        super.init(); asset.resourceLoader.setDelegate(self, queue: queue)
    }
    func cancel() { token.cancel(); asset.cancelLoading() }
    deinit { cancel() }
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource request: AVAssetResourceLoadingRequest) -> Bool {
        guard request.request.url == asset.url, (try? token.check()) != nil else { request.finishLoading(with: PreviewError.unsafePath); return true }
        if let info = request.contentInformationRequest {
            if let allowed = info.allowedContentTypes, !allowed.isEmpty, !allowed.contains(contentType) { request.finishLoading(with: PreviewError.malformed("不支持此媒体内容类型")); return true }
            info.contentType = contentType; info.contentLength = file.length; info.isByteRangeAccessSupported = true
        }
        guard let data = request.dataRequest else { request.finishLoading(); return true }
        guard requests.count < 8 else { request.finishLoading(with: PreviewError.limit("媒体并行请求")); return true }
        let start = max(data.currentOffset, data.requestedOffset)
        let end: Int64
        if data.requestsAllDataToEndOfResource { end = file.length }
        else {
            guard data.requestedOffset >= 0, data.requestedLength >= 0, Int64(data.requestedLength) <= Int64.max - data.requestedOffset else { request.finishLoading(with: PreviewError.unsafePath); return true }
            end = min(file.length, data.requestedOffset + Int64(data.requestedLength))
        }
        requests.insert(ObjectIdentifier(request))
        deliver(request, offset: start, end: end, deadline: ImageDirectoryGrant.continuousTime() + 10)
        return true
    }
    private func deliver(_ request: AVAssetResourceLoadingRequest, offset: Int64, end: Int64, deadline: TimeInterval) {
        let id = ObjectIdentifier(request)
        guard requests.contains(id), !request.isCancelled, !request.isFinished else { requests.remove(id); return }
        do {
            try token.check()
            guard offset <= end, ImageDirectoryGrant.continuousTime() < deadline else { throw PreviewError.limit("媒体请求超时或范围失效") }
            if offset == end { requests.remove(id); request.finishLoading(); return }
            let data = try file.read(offset: offset, count: Int(min(64 * 1024, end - offset)), cancellation: token)
            request.dataRequest?.respond(with: data)
            queue.async { [weak self] in self?.deliver(request, offset: offset + Int64(data.count), end: end, deadline: deadline) }
        } catch { requests.remove(id); request.finishLoading(with: error) }
    }
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) { requests.remove(ObjectIdentifier(loadingRequest)) }
}
