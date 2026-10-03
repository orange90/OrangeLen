import Foundation

// A narrow, image-only contract. No file access, shell, HTML or arbitrary code API.
@objc public protocol ImageBrokerProtocol {
    func fetchImage(_ destination: String, reply: @escaping (Data?, String?) -> Void)
}
