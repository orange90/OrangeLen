import Foundation

/// Bounded active AND pending jobs. Cancellation immediately drops a pending
/// closure and its captured document; completion always runs on the main queue.
public final class PreviewWorkQueue: @unchecked Sendable {
    public static let parsing = PreviewWorkQueue(name: "OrangeLen.parse", concurrency: 2, pendingLimit: 2)
    public static let highlight = PreviewWorkQueue(name: "OrangeLen.highlight", concurrency: 1, pendingLimit: 1)
    public static let browsing = PreviewWorkQueue(name: "OrangeLen.browse", concurrency: 1, pendingLimit: 8)
    public static let directories = PreviewWorkQueue(name: "OrangeLen.directory", concurrency: 1, pendingLimit: 2, qos: .utility)
    private struct Job { let id: UUID; let run: () -> Void; let reject: (Error) -> Void }
    private let lock = NSLock(), workers: DispatchQueue
    private let concurrency: Int, pendingLimit: Int
    private let lane: String
    private var active = 0, pending: [Job] = []
    public init(name: String, concurrency: Int, pendingLimit: Int = 2, qos: DispatchQoS = .userInitiated) {
        self.concurrency = max(1, concurrency); self.pendingLimit = max(0, pendingLimit)
        lane = name.hasSuffix(".directory") ? "directory" : name.hasSuffix(".highlight") ? "highlight" : "parse"
        workers = DispatchQueue(label: name, qos: qos, attributes: .concurrent)
    }
    public func submit<T>(cancellation: Cancellation, work: @escaping () throws -> T, completion: @escaping (Result<T, Error>) -> Void) {
        let id = UUID(), observation = Observation(cancellation)
        let lane = lane
        let job = Job(id: id, run: { [weak self] in
            let result = Result {
                try cancellation.check()
                let lease = try PreviewResourceLease(lane: lane)
                return try withExtendedLifetime(lease) { let value = try autoreleasepool(invoking: work); try cancellation.check(); return value }
            }
            observation.end()
            DispatchQueue.main.async { completion(result) }
            self?.finished()
        }, reject: { error in observation.end(); DispatchQueue.main.async { completion(.failure(error)) } })
        lock.lock()
        if active < concurrency { active += 1; lock.unlock(); workers.async(execute: job.run) }
        else if pending.count < pendingLimit { pending.append(job); lock.unlock() }
        else { lock.unlock(); job.reject(PreviewError.limit("后台任务繁忙，请稍后重载")); return }
        // The callback captures only a weak queue + ID, never the work or document.
        // It is harmless if the job has already started or completed.
        observation.install(cancellation.onCancel { [weak self] in self?.cancelPending(id) })
    }
    private final class Observation {
        let token: Cancellation, lock = NSLock()
        var id: UUID?, ended = false
        init(_ token: Cancellation) { self.token = token }
        func install(_ value: UUID) { lock.lock(); if ended { lock.unlock(); token.removeObserver(value) } else { id = value; lock.unlock() } }
        func end() { lock.lock(); ended = true; let value = id; id = nil; lock.unlock(); if let value { token.removeObserver(value) } }
    }
    private func cancelPending(_ id: UUID) {
        lock.lock(); let index = pending.firstIndex { $0.id == id }; let job = index.map { pending.remove(at: $0) }; lock.unlock()
        job?.reject(CancellationError())
    }
    private func finished() {
        lock.lock()
        if pending.isEmpty { active -= 1; lock.unlock() }
        else { let job = pending.removeFirst(); lock.unlock(); workers.async(execute: job.run) }
    }
    /// Optional cosmetic work may be skipped when its lane is full.
    public func async(cancellation: Cancellation, _ operation: @escaping () -> Void) {
        submit(cancellation: cancellation, work: operation, completion: { _ in })
    }
}
