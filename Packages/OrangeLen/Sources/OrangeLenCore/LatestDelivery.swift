import Foundation

/// At most one queued main-thread progress update; slow UI consumes the latest.
public final class LatestDelivery<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: Value?
    private var scheduled = false
    private let receive: (Value) -> Void
    public init(_ receive: @escaping (Value) -> Void) { self.receive = receive }
    public func send(_ value: Value) {
        lock.lock(); pending = value
        guard !scheduled else { lock.unlock(); return }
        scheduled = true; lock.unlock()
        DispatchQueue.main.async { [self] in
            lock.lock(); let value = pending; pending = nil; scheduled = false; lock.unlock()
            if let value { receive(value) }
        }
    }
}
