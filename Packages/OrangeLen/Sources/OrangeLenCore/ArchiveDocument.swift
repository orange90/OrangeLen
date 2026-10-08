import Foundation
import CZlib

public struct ArchiveEntry: Sendable {
    public let path: String
    public let size: Int
    public let directory: Bool
    public let blocked: String?
    let offset: Int
    let compressed: Int
    let method: Int
    let crc: UInt32?
}
public struct ArchiveDocument: Sendable {
    public let entries: [ArchiveEntry]
    public let kind: String
    private let bytes: Data
    private let limits: PreviewLimits
    public static func safePath(_ path: String) -> Bool {
        !path.isEmpty && !path.hasPrefix("/") && !path.contains("\\") && !path.contains(":") &&
        !path.unicodeScalars.contains(where: { $0.value < 32 }) &&
        !path.split(separator: "/", omittingEmptySubsequences: false).contains("..") && path.utf8.count <= 1024
    }
    /// UI and container readers use the same identity for slash and dot aliases.
    public static func canonicalPath(_ path: String) -> String? {
        guard safePath(path) else { return nil }
        return path.split(separator: "/").filter { $0 != "." }.joined(separator: "/")
    }
    private static func validateIdentities(_ entries: [ArchiveEntry]) throws {
        var kinds: [String: Bool] = [:]
        var ancestors = Set<String>()
        for entry in entries {
            guard let path = canonicalPath(entry.path) else { throw PreviewError.unsafePath }
            if path.isEmpty { guard entry.directory else { throw PreviewError.unsafePath }; continue }
            guard kinds[path] == nil, entry.directory || !ancestors.contains(path) else { throw PreviewError.malformed("归档路径冲突：" + path) }
            var components = path.split(separator: "/"); components.removeLast()
            while !components.isEmpty {
                let parent = components.joined(separator: "/")
                guard kinds[parent] != false else { throw PreviewError.malformed("归档文件不能同时作为目录：" + parent) }
                ancestors.insert(parent); components.removeLast()
            }
            kinds[path] = entry.directory
        }
    }
    /// Fully verify every member before handing raw ZIP bytes to an OS importer.
    public func validateForNativeImport(cancellation: Cancellation = .init()) throws {
        for entry in entries {
            try cancellation.check()
            guard entry.blocked == nil else { throw PreviewError.limit(entry.path + "：" + entry.blocked!) }
            if !entry.directory { _ = try read(entry, cancellation: cancellation) }
        }
    }
    public static func parse(_ data: Data, name: String, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> Self {
        guard data.count <= limits.containerBytes else { throw PreviewError.limit("容器输入 64 MiB") }
        let lower = name.lowercased()
        if lower.hasSuffix(".zip") || lower.hasSuffix(".epub") { return try zip(data, limits: limits, token: cancellation) }
        let tarData = lower.hasSuffix(".gz") || lower.hasSuffix(".tgz") ? try inflate(data, window: 31, maximum: limits.archiveExpandedBytes, token: cancellation) : data
        guard tarData.count <= max(1,data.count) * limits.archiveRatio else { throw PreviewError.limit("gzip 展开比例") }
        return try tar(tarData, limits: limits, token: cancellation)
    }
    public func read(_ entry: ArchiveEntry, cancellation: Cancellation = .init()) throws -> Data {
        try cancellation.check()
        guard entries.contains(where: { $0.path == entry.path && $0.offset == entry.offset }), entry.blocked == nil, !entry.directory else { throw PreviewError.unsafePath }
        guard entry.size <= limits.archiveEntryBytes, entry.offset >= 0, entry.compressed <= bytes.count - entry.offset else { throw PreviewError.limit("条目最大 5 MiB") }
        let input = bytes.subdata(in: entry.offset..<(entry.offset + entry.compressed))
        let output = entry.method == 8 ? try Self.inflate(input, window: -15, maximum: min(entry.size, limits.archiveEntryBytes), token: cancellation) : input
        guard output.count == entry.size else { throw PreviewError.malformed("归档条目长度不一致") }
        if let expected = entry.crc {
            let actual = output.withUnsafeBytes { buffer in crc32(0, buffer.bindMemory(to: Bytef.self).baseAddress, uInt(buffer.count)) }
            guard UInt32(actual) == expected else { throw PreviewError.malformed("ZIP CRC 校验失败") }
        }
        try cancellation.check(); return output
    }
    public func entry(_ path: String) -> ArchiveEntry? { entries.first { Self.canonicalPath($0.path) == Self.canonicalPath(path) } }
    static func inflate(_ data: Data, window: Int32, maximum: Int, token: Cancellation) throws -> Data {
        var stream = z_stream()
        guard inflateInit2_(&stream, window, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else { throw PreviewError.malformed("压缩初始化失败") }
        defer { inflateEnd(&stream) }
        return try data.withUnsafeBytes { input in
            stream.next_in = UnsafeMutablePointer(mutating: input.bindMemory(to: Bytef.self).baseAddress); stream.avail_in = uInt(input.count)
            var output = Data(); var chunk = [UInt8](repeating: 0, count: 65536)
            while true {
                try token.check()
                let result = chunk.withUnsafeMutableBytes { buffer -> Int32 in
                    stream.next_out = buffer.bindMemory(to: Bytef.self).baseAddress; stream.avail_out = uInt(buffer.count)
                    return CZlib.inflate(&stream, Z_NO_FLUSH)
                }
                let count = chunk.count - Int(stream.avail_out)
                guard count <= maximum - output.count else { throw PreviewError.limit("归档展开字节预算") }
                output.append(contentsOf: chunk.prefix(count))
                if result == Z_STREAM_END { guard stream.avail_in == 0 else { throw PreviewError.malformed("压缩尾部包含额外数据") }; return output }
                guard result == Z_OK, count > 0 else { throw PreviewError.malformed("压缩数据损坏") }
            }
        }
    }
    private static func zip(_ data: Data, limits: PreviewLimits, token: Cancellation) throws -> Self {
        let b = [UInt8](data)
        func u16(_ n: Int) -> Int { Int(b[n]) | Int(b[n+1]) << 8 }
        func u32(_ n: Int) -> Int { u16(n) | u16(n+2) << 16 }
        guard b.count >= 22 else { throw PreviewError.malformed("ZIP 头缺失") }
        var end: Int?
        for n in stride(from: b.count - 22, through: max(0, b.count - 65557), by: -1) {
            if u32(n) == 0x06054b50 && n + 22 + u16(n+20) == b.count { end = n; break }
        }
        guard let end, u16(end+4) == 0, u16(end+6) == 0, u16(end+8) == u16(end+10) else { throw PreviewError.malformed("仅支持单卷普通 ZIP") }
        let count = u16(end+10), start = u32(end+16), centralSize = u32(end+12)
        guard count < 65535, count <= limits.archiveEntries, start <= end, centralSize == end - start else { throw PreviewError.limit("ZIP64/条目数/目录范围") }
        var cursor = start; var entries: [ArchiveEntry] = []; var total = 0; var names = Set<String>()
        for _ in 0..<count {
            try token.check()
            guard cursor <= end - 46, u32(cursor) == 0x02014b50 else { throw PreviewError.malformed("ZIP 中央目录损坏") }
            let flags = u16(cursor+8), method = u16(cursor+10), compressed = u32(cursor+20), size = u32(cursor+24)
            let length = u16(cursor+28), extra = u16(cursor+30), comment = u16(cursor+32), local = u32(cursor+42)
            guard length > 0, cursor + 46 + length + extra + comment <= end, u16(cursor+34) == 0 else { throw PreviewError.malformed("ZIP 条目范围") }
            let pathData = Data(b[(cursor+46)..<(cursor+46+length)])
            guard let path = String(data: pathData, encoding: .utf8) else { throw PreviewError.encoding }
            guard safePath(path), names.insert(path).inserted else { throw PreviewError.unsafePath }
            let unixType = (u32(cursor+38) >> 16) & 0xf000
            var blocked: String?
            if flags & 1 != 0 { blocked = "加密条目不支持" }
            else if method != 0 && method != 8 { blocked = "压缩方法不支持" }
            else if unixType != 0 && unixType != 0x8000 && unixType != 0x4000 { blocked = "链接或特殊条目不跟随" }
            else if size > limits.archiveEntryBytes || size > max(1, compressed) * limits.archiveRatio { blocked = "条目大小或压缩比超过预算" }
            guard size <= limits.archiveExpandedBytes - total else { throw PreviewError.limit("归档声明展开总量 64 MiB") }; total += size
            guard local <= start - 30, u32(local) == 0x04034b50 else { throw PreviewError.malformed("ZIP 本地头损坏") }
            let localName = u16(local+26), localExtra = u16(local+28), offset = local + 30 + localName + localExtra
            guard offset <= start, compressed <= start - offset, localName == length,
                  Data(b[(local+30)..<(local+30+localName)]) == pathData, u16(local+8) == method, u16(local+6) == flags else { throw PreviewError.malformed("ZIP 本地头不一致") }
            entries.append(.init(path: path, size: size, directory: path.hasSuffix("/"), blocked: blocked, offset: offset, compressed: compressed, method: method, crc: UInt32(u32(cursor+16))))
            cursor += 46 + length + extra + comment
        }
        guard cursor == end else { throw PreviewError.malformed("ZIP 中央目录数量不一致") }
        try validateIdentities(entries)
        return .init(entries: entries, kind: "ZIP", bytes: data, limits: limits)
    }
    private static func tar(_ data: Data, limits: PreviewLimits, token: Cancellation) throws -> Self {
        let b = [UInt8](data); var cursor = 0; var entries: [ArchiveEntry] = []; var total = 0; var names = Set<String>()
        func string(_ start: Int, _ count: Int) -> String { String(decoding: b[start..<(start+count)].prefix { $0 != 0 }, as: UTF8.self) }
        while cursor + 512 <= b.count {
            try token.check()
            if b[cursor..<(cursor+512)].allSatisfy({ $0 == 0 }) { break }
            guard entries.count < limits.archiveEntries else { throw PreviewError.limit("归档条目数") }
            guard let sum = Int(string(cursor+148,8).trimmingCharacters(in: .whitespacesAndNewlines), radix:8),
                  sum == b[cursor..<(cursor+512)].enumerated().reduce(0,{ $0 + (($1.offset >= 148 && $1.offset < 156) ? 32 : Int($1.element)) }),
                  let size = Int(string(cursor+124,12).trimmingCharacters(in: .whitespacesAndNewlines),radix:8), size >= 0 else { throw PreviewError.malformed("TAR 校验或长度损坏") }
            let prefix = string(cursor+345,155), name = string(cursor,100), path = prefix.isEmpty ? name : prefix + "/" + name
            guard safePath(path), names.insert(path).inserted else { throw PreviewError.unsafePath }
            let type = b[cursor+156]; let offset = cursor + 512
            guard size <= b.count - offset, size <= limits.archiveExpandedBytes - total else { throw PreviewError.limit("TAR 展开预算或条目范围") }; total += size
            let blocked = ![UInt8(0),48,53].contains(type) ? "链接、PAX/GNU 扩展或特殊条目不支持" : size > limits.archiveEntryBytes ? "条目大于 5 MiB" : nil
            entries.append(.init(path:path,size:size,directory:type == 53,blocked:blocked,offset:offset,compressed:size,method:0,crc:nil))
            cursor = offset + ((size + 511) / 512) * 512
        }
        guard !entries.isEmpty || b.count >= 1024 else { throw PreviewError.malformed("TAR 不完整") }
        try validateIdentities(entries)
        return .init(entries: entries, kind:"TAR",bytes:data,limits:limits)
    }
}
