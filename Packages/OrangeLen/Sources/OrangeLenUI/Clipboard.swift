import AppKit

/// Report success only after the pasteboard accepts the source text.
enum Clipboard {
    static func write(_ value: String, feedback: ((String) -> Void)?) {
        NSPasteboard.general.clearContents()
        let copied = NSPasteboard.general.setString(value, forType: .string)
        feedback?(copied ? "已复制" : "复制失败，请重试")
    }
}
