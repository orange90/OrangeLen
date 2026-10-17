import Foundation
import CArchive
import CZstd

/// Only memory readers are enabled. No extraction, programs, passwords or external volumes.
enum NativeArchiveDecoder {
    struct Contents { let entries: [ArchiveEntry]; let bytes: Data; let kind: String }
    static func parse(_ input: Data, name: String, limits: PreviewLimits, token: Cancellation) throws -> Contents {
        var data = input
        let lower = name.lowercased()
        let zstd = lower.hasSuffix(".tar.zst") || lower.hasSuffix(".tzst")
        if zstd {
            try token.check()
            let maximum = min(limits.archiveExpandedBytes, max(1, input.count) * limits.archiveRatio)
            var output = Data(count: maximum), count = 0
            let success = input.withUnsafeBytes { source in
                output.withUnsafeMutableBytes { target in
                    orange_zstd_decode(source.baseAddress, source.count, target.baseAddress, target.count, &count)
                }
            }
            guard success == 1 else { throw PreviewError.malformed("Zstandard data damaged or exceeds output/window budget") }
            output.count = count; data = output
        }
        guard let reader = archive_read_new() else { throw PreviewError.unavailable }
        defer { archive_read_free(reader) }
        func check(_ status: Int32) throws {
            guard status == ARCHIVE_OK else {
                let detail = archive_error_string(reader).map { String(cString: $0) } ?? "Archive decoder error"
                throw PreviewError.malformed(detail)
            }
        }
        try check(archive_read_support_filter_none(reader))
        let kind: String
        if lower.hasSuffix(".7z") {
            try check(archive_read_support_format_7zip(reader)); kind = "7z"
        } else if lower.hasSuffix(".rar") {
            try check(archive_read_support_format_rar(reader)); try check(archive_read_support_format_rar5(reader)); kind = "RAR"
        } else {
            try check(archive_read_support_format_tar(reader))
            if lower.hasSuffix(".tar.xz") || lower.hasSuffix(".txz") {
                try check(archive_read_support_filter_xz(reader)); kind = "TAR/XZ"
            } else if lower.hasSuffix(".tar.bz2") || lower.hasSuffix(".tbz2") {
                try check(archive_read_support_filter_bzip2(reader)); kind = "TAR/BZIP2"
            } else if zstd { kind = "TAR/Zstandard" }
            else { throw PreviewError.malformed("Unsupported compressed TAR suffix") }
        }
        return try data.withUnsafeBytes { source in
            try check(archive_read_open_memory(reader, source.baseAddress, source.count))
            var entries: [ArchiveEntry] = [], storage = Data(), total = 0
            while true {
                try token.check()
                var item: OpaquePointer?
                let status = archive_read_next_header(reader, &item)
                if status == ARCHIVE_EOF { break }
                try check(status)
                guard let item, entries.count < limits.archiveEntries else { throw PreviewError.limit("Archive entry count") }
                guard let raw = archive_entry_pathname_utf8(item) ?? archive_entry_pathname(item),
                      let path = String(validatingCString: raw), ArchiveDocument.safePath(path) else { throw PreviewError.unsafePath }
                let declared = archive_entry_size(item)
                guard archive_entry_size_is_set(item) != 0, declared >= 0,
                      declared <= Int64(limits.archiveExpandedBytes - total) else { throw PreviewError.limit("Archive declared expanded bytes") }
                let size = Int(declared); total += size
                guard total <= max(1, input.count) * limits.archiveRatio else { throw PreviewError.limit("Archive expansion ratio") }
                let type = archive_entry_filetype(item), directory = type == 0o040000
                let link = archive_entry_symlink(item) != nil || archive_entry_hardlink(item) != nil
                let blocked: String?
                if archive_entry_is_encrypted(item) != 0 { blocked = "Encrypted archive member is not supported" }
                else if link || (type != 0o100000 && !directory) { blocked = "Links and special archive members are not supported" }
                else if size > limits.archiveEntryBytes { blocked = "Archive member exceeds 5 MiB" }
                else { blocked = nil }
                let offset = storage.count
                if blocked == nil && !directory {
                    var chunk = [UInt8](repeating: 0, count: 65536), received = 0
                    while true {
                        try token.check()
                        let count = archive_read_data(reader, &chunk, chunk.count)
                        guard count >= 0 else { try check(ARCHIVE_FATAL); throw PreviewError.unavailable }
                        if count == 0 { break }
                        guard count <= size - received, count <= limits.archiveExpandedBytes - storage.count else { throw PreviewError.limit("Archive actual expanded bytes") }
                        storage.append(contentsOf: chunk.prefix(count)); received += count
                    }
                    guard received == size else { throw PreviewError.malformed("Archive member size mismatch") }
                } else { try check(archive_read_data_skip(reader)) }
                entries.append(.init(path: path, size: size, directory: directory, blocked: blocked,
                                     offset: offset, compressed: blocked == nil && !directory ? size : 0, method: 0, crc: nil))
            }
            guard !entries.isEmpty else { throw PreviewError.malformed("Archive is empty or incomplete") }
            try token.check()
            return Contents(entries: entries, bytes: storage, kind: kind)
        }
    }
}
