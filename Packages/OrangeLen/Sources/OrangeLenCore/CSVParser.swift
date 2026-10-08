import Foundation
public struct TableCell: Sendable {
    public let value: String
    public let sourceRange: NSRange
}
public struct TableData: Sendable {
    public let rows: [[TableCell]]
    public let partial: Bool
    public func textModel(source: String) -> TextModel {
        var model = TextModel(source: source, display: "", mapping: [], styles: [], blocks: [], warnings: [])
        for row in rows {
            for (index, cell) in row.enumerated() {
                let range = NSRange(location: model.display.utf16.count, length: cell.value.utf16.count)
                model.display += cell.value
                model.mapping.append(.init(display: range, source: cell.sourceRange, exact: (source as NSString).substring(with: cell.sourceRange) == cell.value))
                model.display += index == row.count - 1 ? "\n" : "\t"
            }
        }
        return model
    }
    public init(rows: [[TableCell]], partial: Bool) { self.rows = rows; self.partial = partial }
}
public enum CSVParser {
    public static func parse(_ text: String, separator: UInt16 = 44, limits: PreviewLimits = .init(), cancellation: Cancellation = .init()) throws -> TableData {
        let chars = Array(text.utf16); var index = 0; var rows: [[TableCell]] = []; var row: [TableCell] = []
        var value: [UInt16] = []; var start = 0; var quoted = false; var closed = false
        func cell() { row.append(.init(value: String(decoding: value, as: UTF16.self), sourceRange: NSRange(location: start, length: index - start))); value = []; closed = false }
        while index < chars.count {
            if index % 1024 == 0 { try cancellation.check() }
            let c = chars[index]
            if quoted {
                if c == 34 {
                    if index + 1 < chars.count && chars[index + 1] == 34 { value.append(34); index += 2; continue }
                    quoted = false; closed = true
                } else { value.append(c) }
            } else if c == 34 && index == start { quoted = true }
            else if c == separator { cell(); start = index + 1 }
            else if c == 10 || c == 13 {
                cell(); rows.append(row); row = []
                if c == 13 && index + 1 < chars.count && chars[index + 1] == 10 { index += 1 }
                start = index + 1
                if rows.count >= limits.tableRows { return .init(rows: rows, partial: index + 1 < chars.count) }
            } else {
                if closed || c == 34 { throw PreviewError.malformed(L10n.text("CSV 第 \(rows.count + 1) 行引号不合法")) }
                value.append(c)
            }
            guard row.count < limits.tableColumns else { throw PreviewError.limit(L10n.text("表格最大 256 列")) }
            index += 1
        }
        guard !quoted else { throw PreviewError.malformed(L10n.text("CSV 引号未闭合")) }
        if start < chars.count || !row.isEmpty { cell(); rows.append(row) }
        return .init(rows: rows, partial: false)
    }
}
