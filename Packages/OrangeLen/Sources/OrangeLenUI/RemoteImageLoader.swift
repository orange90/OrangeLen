import Foundation
import Network
import Security
import Darwin
import OrangeLenCore

// Dedicated image-only HTTPS client. Resolve once, reject non-public addresses,
// connect to that exact IP, and validate TLS for the original hostname. No DNS
// check/use race, cookies, credentials, redirects or disk cache. System-managed
// proxies may still carry the validated destination, under the user’s OS settings.
enum RemoteImagePolicy {
    static let byteLimit = 5 * 1024 * 1024
    static func url(_ value: String) throws -> URL {
        guard value.utf8.count <= 4096, let parts = URLComponents(string: value),
              parts.scheme?.lowercased() == "https", parts.user == nil, parts.password == nil,
              parts.port == nil || parts.port == 443, let host = parts.host?.lowercased(),
              !host.isEmpty, !host.hasSuffix("."), !host.contains("%"),
              !["localhost", "local", "internal", "home", "lan", "test", "invalid"].contains(where: { host == $0 || host.hasSuffix("." + $0) }),
              let url = parts.url else { throw PreviewError.malformed("远程图片仅允许公共 HTTPS 地址（443，无账号）") }
        return url
    }
    static func isPublic(_ ip: String) -> Bool {
        var v4 = in_addr()
        if inet_pton(AF_INET, ip, &v4) == 1 {
            let n = UInt32(bigEndian: v4.s_addr), a = n >> 24, b = (n >> 16) & 255
            return !(a == 0 || a == 10 || a == 127 || a >= 224 || (a == 100 && (64...127).contains(b)) ||
                (a == 169 && b == 254) || (a == 172 && (16...31).contains(b)) || (a == 192 && b == 168) ||
                (a == 192 && b == 0) || (a == 192 && b == 88 && ((n >> 8) & 255) == 99) ||
                (a == 198 && (b == 18 || b == 19 || b == 51)) || (a == 203 && b == 0 && ((n >> 8) & 255) == 113))
        }
        var v6 = in6_addr()
        guard inet_pton(AF_INET6, ip, &v6) == 1 else { return false }
        let bytes = withUnsafeBytes(of: v6) { Array($0) }
        // Global unicast only. Exclude documentation, transition and special-purpose ranges.
        return bytes[0] & 0xe0 == 0x20 && !(bytes[0] == 0x20 && bytes[1] == 0x01 && (bytes[2] < 2 || (bytes[2] == 0x0d && bytes[3] == 0xb8))) && !(bytes[0] == 0x20 && bytes[1] == 0x02) && !(bytes[0] == 0x3f && bytes[1] == 0xff)
    }
    static func resolve(_ host: String) throws -> String {
        var hints = addrinfo(); hints.ai_family = AF_UNSPEC; hints.ai_socktype = SOCK_STREAM; hints.ai_protocol = IPPROTO_TCP
        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, "443", &hints, &result) == 0, let first = result else { throw PreviewError.malformed("图片域名解析失败") }
        defer { freeaddrinfo(first) }
        var cursor: UnsafeMutablePointer<addrinfo>? = first; var addresses: [String] = []
        while let item = cursor {
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(item.pointee.ai_addr, item.pointee.ai_addrlen, &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST) == 0 else { throw PreviewError.malformed("图片地址无效") }
            let ip = String(cString: buffer)
            guard isPublic(ip) else { throw PreviewError.malformed("已阻止访问本机、局域网或保留地址") }
            addresses.append(ip); guard addresses.count <= 32 else { throw PreviewError.limit("图片 DNS 地址过多") }
            cursor = item.pointee.ai_next
        }
        guard let ip = addresses.first else { throw PreviewError.malformed("无可用图片地址") }
        return ip
    }
}

struct ImageHTTPResponse {
    // nil means more bytes are needed. No body is decoded before header validation.
    static func body(_ data: Data, eof: Bool = false) throws -> Data? {
        guard let end = data.range(of: Data("\r\n\r\n".utf8)) else {
            guard data.count <= 16384, !eof else { throw PreviewError.malformed("图片响应头无效或过大") }; return nil
        }
        guard end.lowerBound <= 16384, let header = String(data: data[..<end.lowerBound], encoding: .utf8) else { throw PreviewError.malformed("图片响应头无效") }
        let lines = header.components(separatedBy: "\r\n")
        let status = lines[0].split(separator: " ")
        guard status.count >= 2, ["HTTP/1.1", "HTTP/1.0"].contains(String(status[0])), status[1] == "200" else { throw PreviewError.malformed("图片服务器未返回 200；不跟随重定向") }
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colon = line.firstIndex(of: ":"), !line.hasPrefix(" "), !line.hasPrefix("\t") else { throw PreviewError.malformed("图片响应头无效") }
            let key = line[..<colon].lowercased(), value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            guard headers[key] == nil else { throw PreviewError.malformed("图片响应头重复") }; headers[key] = value
        }
        let mime = headers["content-type"]?.split(separator: ";").first?.lowercased() ?? ""
        guard ["image/png", "image/jpeg", "image/gif", "image/webp", "image/tiff", "image/heic", "image/heif", "image/bmp", "image/x-icon", "image/vnd.microsoft.icon"].contains(mime),
              headers["content-encoding"] == nil || headers["content-encoding"]?.lowercased() == "identity" else { throw PreviewError.malformed("仅接受栅格图片；拒绝 SVG、HTML 和压缩响应") }
        let raw = Data(data[end.upperBound...])
        if let transfer = headers["transfer-encoding"] {
            guard transfer.lowercased() == "chunked", headers["content-length"] == nil else { throw PreviewError.malformed("图片传输编码无效") }
            var offset = 0; var body = Data()
            while offset < raw.count {
                guard let line = raw.range(of: Data("\r\n".utf8), in: offset..<raw.count) else { if eof { throw PreviewError.malformed("图片分块不完整") }; return nil }
                guard line.lowerBound - offset <= 128,
                      let sizeText = String(data: raw[offset..<line.lowerBound], encoding: .ascii)?.split(separator: ";").first,
                      let size = Int(sizeText, radix: 16), size >= 0, size <= RemoteImagePolicy.byteLimit - body.count else { throw PreviewError.limit("远程图片最多 5 MiB") }
                offset = line.upperBound
                if size == 0 {
                    guard raw.count >= offset + 2 else { if eof { throw PreviewError.malformed("图片分块不完整") }; return nil }
                    guard raw[offset..<offset+2] == Data("\r\n".utf8) else { throw PreviewError.malformed("不接受图片响应尾部字段") }
                    return body
                }
                guard raw.count >= offset + size + 2 else { if eof { throw PreviewError.malformed("图片分块不完整") }; return nil }
                body.append(raw[offset..<offset+size]); offset += size
                guard raw[offset..<offset+2] == Data("\r\n".utf8) else { throw PreviewError.malformed("图片分块格式无效") }; offset += 2
            }
            if eof { throw PreviewError.malformed("图片分块不完整") }; return nil
        }
        if let length = headers["content-length"] {
            guard let count = Int(length), count >= 0, count <= RemoteImagePolicy.byteLimit else { throw PreviewError.limit("远程图片最多 5 MiB") }
            if raw.count < count { if eof { throw PreviewError.malformed("图片响应不完整") }; return nil }
            return Data(raw.prefix(count))
        }
        guard raw.count <= RemoteImagePolicy.byteLimit else { throw PreviewError.limit("远程图片最多 5 MiB") }
        return eof ? raw : nil
    }
}

final class RemoteImageLoader: @unchecked Sendable {
    private let queue = DispatchQueue(label: "OrangeLen.remote-image")
    private var connection: NWConnection?
    private var handler: ((Result<Data, Error>) -> Void)?
    private var stopped = false
    private var received = Data()
    func cancel() { queue.async { self.stopped = true; self.finish(.failure(CancellationError())) } }
    private func finish(_ result: Result<Data, Error>) {
        connection?.cancel(); connection = nil; let callback = handler; handler = nil; received = Data(); callback?(result)
    }
    func load(_ value: String) async throws -> Data {
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                queue.async {
                    guard !self.stopped else { continuation.resume(throwing: CancellationError()); return }
                    self.handler = { continuation.resume(with: $0) }
                    self.queue.asyncAfter(deadline: .now() + 15) { [weak self] in
                        guard let self, self.handler != nil else { return }; self.stopped = true
                        self.finish(.failure(PreviewError.limit("远程图片加载超时")))
                    }
                    do {
                        let url = try RemoteImagePolicy.url(value)
                        let host = url.host() ?? ""
                        DispatchQueue.global(qos: .utility).async {
                            let resolved = Result { try RemoteImagePolicy.resolve(host) }
                            self.queue.async {
                                guard self.handler != nil, !self.stopped else { return }
                                do { self.connect(url, host: host, ip: try resolved.get()) }
                                catch { self.finish(.failure(error)) }
                            }
                        }
                    } catch { self.finish(.failure(error)) }
                }
            }
        }, onCancel: { self.cancel() })
    }
    private func connect(_ url: URL, host: String, ip: String) {
        let tls = NWProtocolTLS.Options()
        sec_protocol_options_set_tls_server_name(tls.securityProtocolOptions, host)
        sec_protocol_options_add_tls_application_protocol(tls.securityProtocolOptions, "http/1.1")
        sec_protocol_options_set_verify_block(tls.securityProtocolOptions, { _, trust, complete in
            let value = sec_trust_copy_ref(trust).takeRetainedValue()
            // Bind trust to the original DNS hostname even though the socket uses a
            // validated numeric IP. Never accept a bad certificate or fetch AIA URLs.
            let status = SecTrustSetPolicies(value, SecPolicyCreateSSL(true, host as CFString))
            SecTrustSetNetworkFetchAllowed(value, false)
            complete(status == errSecSuccess && SecTrustEvaluateWithError(value, nil))
        }, queue)
        let parameters = NWParameters(tls: tls, tcp: NWProtocolTCP.Options())
        let connection = NWConnection(host: NWEndpoint.Host(ip), port: 443, using: parameters)
        self.connection = connection
        connection.stateUpdateHandler = { [weak self] state in
            guard let self, self.handler != nil else { return }
            switch state {
            case .ready:
                let parts = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                let target = (parts.percentEncodedPath.isEmpty ? "/" : parts.percentEncodedPath) + (parts.percentEncodedQuery.map { "?" + $0 } ?? "")
                let request = "GET \(target) HTTP/1.1\r\nHost: \(host)\r\nUser-Agent: OrangeLen/1\r\nAccept: image/png,image/jpeg,image/gif,image/webp,image/heic,image/tiff\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n"
                connection.send(content: Data(request.utf8), completion: .contentProcessed { [weak self] error in
                    if let error { self?.finish(.failure(error)) } else { self?.receive() }
                })
            case .failed(let error): self.finish(.failure(error))
            default: break
            }
        }
        connection.start(queue: queue)
    }
    private func receive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 32768) { [weak self] data, _, complete, error in
            guard let self, self.handler != nil else { return }
            if let error { self.finish(.failure(error)); return }
            if let data { self.received.append(data) }
            do {
                guard self.received.count <= RemoteImagePolicy.byteLimit + 65536 else { throw PreviewError.limit("远程图片传输预算") }
                if let body = try ImageHTTPResponse.body(self.received, eof: complete) { self.finish(.success(body)) }
                else { self.receive() }
            } catch { self.finish(.failure(error)) }
        }
    }
}
