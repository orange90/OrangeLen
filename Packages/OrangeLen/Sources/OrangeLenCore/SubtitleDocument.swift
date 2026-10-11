import Foundation

public struct SubtitleDocument: Sendable {
    public struct Cue: Sendable {
        public let start: Int, end: Int
        public let timing: String, text: String
        public let timingRange: NSRange, textRange: NSRange
    }
    public let cues: [Cue]
    public let rejected: Int
    public var duration: Int { cues.map(\.end).max() ?? 0 }
    public static func timestamp(_ milliseconds: Int) -> String {
        String(format: "%02d:%02d:%02d.%03d", milliseconds / 3_600_000, milliseconds / 60_000 % 60, milliseconds / 1000 % 60, milliseconds % 1000)
    }
    public var table: TableData {
        let empty = NSRange(location: 0, length: 0)
        let titles = [L10n.text("开始"), L10n.text("结束"), L10n.text("字幕正文")]
        return .init(rows: [titles.map { TableCell(value: $0, sourceRange: empty) }] + cues.map {
            [TableCell(value: Self.timestamp($0.start), sourceRange: $0.timingRange),
             TableCell(value: Self.timestamp($0.end), sourceRange: $0.timingRange),
             TableCell(value: $0.text, sourceRange: $0.textRange)]
        }, partial: false)
    }
    public static func parse(_ source: String, webVTT: Bool, cancellation: Cancellation = .init()) throws -> Self {
        guard source.utf8.count <= PreviewLimits().fileBytes else { throw PreviewError.limit(L10n.text("字幕字节预算")) }
        let ns = source as NSString
        var lines: [(String, NSRange)] = [], cursor = 0
        while cursor < ns.length {
            try cancellation.check()
            let range = ns.lineRange(for: NSRange(location: cursor, length: 0))
            let value = ns.substring(with: range).trimmingCharacters(in: .newlines)
            guard lines.count < 50_000 else { throw PreviewError.limit(L10n.text("字幕最多 50,000 行")) }
            lines.append((value, NSRange(location: range.location, length: value.utf16.count))); cursor = NSMaxRange(range)
        }
        if webVTT {
            guard let first = lines.first?.0.replacingOccurrences(of: "\u{FEFF}", with: ""), first == "WEBVTT" || first.hasPrefix("WEBVTT ") || first.hasPrefix("WEBVTT\t") else {
                throw PreviewError.malformed(L10n.text("缺少 WEBVTT 文件头"))
            }
        }
        func time(_ value: String) -> Int? {
            let normalized = value.replacingOccurrences(of: ",", with: ".")
            let pieces = normalized.split(separator: ":", omittingEmptySubsequences: false)
            guard pieces.count == 3 || (webVTT && pieces.count == 2),
                  pieces.allSatisfy({ !$0.isEmpty }) else { return nil }
            let seconds = pieces.last!.split(separator: ".", omittingEmptySubsequences: false)
            guard seconds.count == 2, seconds[0].count == 2, seconds[1].count == 3,
                  let sec = Int(seconds[0]), let ms = Int(seconds[1]), sec < 60, sec >= 0, ms >= 0, ms < 1000,
                  let min = Int(pieces[pieces.count - 2]), min >= 0, min < 60,
                  pieces[pieces.count - 2].count == 2 else { return nil }
            let hours = pieces.count == 3 ? Int(pieces[0]) : 0
            guard let hour = hours, hour >= 0, hour <= 9999,
                  normalized.unicodeScalars.allSatisfy({ (48...57).contains($0.value) || $0 == ":" || $0 == "." }) else { return nil }
            return hour * 3_600_000 + min * 60_000 + sec * 1000 + ms
        }
        var groups: [[(String, NSRange)]] = [], block: [(String, NSRange)] = []
        for line in lines {
            if line.0.trimmingCharacters(in: .whitespaces).isEmpty { if !block.isEmpty { groups.append(block); block = [] } }
            else { block.append(line) }
        }
        if !block.isEmpty { groups.append(block) }
        var cues: [Cue] = [], rejected = 0
        for group in groups {
            try cancellation.check()
            let first = group[0].0
            if webVTT && (first.hasPrefix("WEBVTT") || first == "STYLE" || first == "REGION" || first == "NOTE" || first.hasPrefix("NOTE ") || first.hasPrefix("NOTE\t")) { continue }
            guard let index = group.firstIndex(where: { $0.0.contains("-->") }), index <= 1 else { rejected += 1; continue }
            let parts = group[index].0.components(separatedBy: "-->")
            guard parts.count == 2, let start = time(parts[0].trimmingCharacters(in: .whitespaces)),
                  let endValue = parts[1].split(whereSeparator: { $0.isWhitespace }).first,
                  let end = time(String(endValue)), end > start else { rejected += 1; continue }
            guard cues.count < 5000 else { throw PreviewError.limit(L10n.text("字幕最多 5,000 条")) }
            let payload = Array(group.dropFirst(index + 1))
            let range = payload.first.map { NSRange(location: $0.1.location, length: NSMaxRange(payload.last!.1) - $0.1.location) } ?? NSRange(location: NSMaxRange(group[index].1), length: 0)
            cues.append(.init(start: start, end: end, timing: group[index].0, text: payload.map(\.0).joined(separator: "\n"), timingRange: group[index].1, textRange: range))
        }
        guard !cues.isEmpty || rejected == 0 else { throw PreviewError.malformed(L10n.text("未找到有效字幕时间码")) }
        return .init(cues: cues, rejected: rejected)
    }
}
