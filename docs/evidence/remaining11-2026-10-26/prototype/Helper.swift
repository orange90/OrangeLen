import AppKit
import ApplicationServices
import OrangeLenUI
import os

private let blockedExtensions: Set<String> = ["ts", "mts", "dot", "html", "htm", "xhtml", "txt", "text", "pdf", "csv", "svg"]
private let logger = Logger(subsystem: "local.OrangeLen", category: "FinderSpaceHelper")

// This prototype is a separate user-enabled helper. It is not a Quick Look extension.
@main
final class FinderSpaceHelper: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static func main() {
        let app = NSApplication.shared
        let delegate = FinderSpaceHelper()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) { app.run() }
    }
    private var setup: NSWindow!
    private var preview: NSPanel!
    private let reader = ReaderController()
    private let status = NSTextField(wrappingLabelWithString: "未启用 Finder 空格辅助预览。")
    private var eventTap: CFMachPort?
    private var source: CFRunLoopSource?
    private var enabled = false
    private var lastURL: URL?
    private var generation = UUID()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let root = NSMenuItem(); menu.addItem(root)
        let appMenu = NSMenu(); root.submenu = appMenu
        appMenu.addItem(withTitle: "显示设置", action: #selector(showSetup), keyEquivalent: ",")
        appMenu.addItem(withTitle: "停止辅助预览", action: #selector(stop), keyEquivalent: "")
        appMenu.addItem(withTitle: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let edit = NSMenuItem(); menu.addItem(edit); edit.submenu = NSMenu(title: "编辑")
        edit.submenu?.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.submenu?.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        NSApp.mainMenu = menu
        setup = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 730, height: 340), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        setup.title = "OrangeLen · Finder 空格辅助原型"
        setup.isReleasedWhenClosed = false
        let stack = NSStackView(); stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        let info = NSTextField(wrappingLabelWithString: "仅在 Finder 中处理这 11 个后缀的单文件空格：TS、MTS、DOT、HTML、HTM、XHTML、TXT、TEXT、PDF、CSV、SVG。\n显示独立 OrangeLen 预览窗口；这不是系统 Quick Look 扩展接管。\n需要辅助功能权限。关闭本程序即可停止；没有开机自启。")
        stack.addArrangedSubview(info)
        let enable = NSButton(title: "手动授权后启用 Finder 空格辅助预览", target: self, action: #selector(enableFromUser))
        stack.addArrangedSubview(enable)
        stack.addArrangedSubview(NSButton(title: "停止辅助预览", target: self, action: #selector(stop)))
        let demos = NSStackView(); demos.spacing = 10
        for (title, tag) in [("查看 TS 样例", 1), ("查看 MTS 样例", 2), ("查看 DOT 样例", 3)] {
            let button = NSButton(title: title, target: self, action: #selector(demo(_:))); button.tag = tag; demos.addArrangedSubview(button)
        }
        stack.addArrangedSubview(demos); stack.addArrangedSubview(status)
        stack.frame = NSRect(x: 0, y: 0, width: 730, height: 340); setup.contentView = stack
        preview = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 720), styleMask: [.titled, .closable, .resizable, .nonactivatingPanel], backing: .buffered, defer: false)
        preview.title = "OrangeLen · 辅助预览（非系统 Quick Look）"
        preview.contentViewController = reader; preview.isReleasedWhenClosed = false
        preview.delegate = self; preview.level = .floating; preview.hidesOnDeactivate = false
        showSetup()
    }
    @objc private func showSetup() { setup.center(); setup.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    @objc private func demo(_ sender: NSButton) {
        let names = [1: "01-ts.ts", 2: "02-mts.mts", 3: "03-dot.dot"]
        guard let name = names[sender.tag] else { return }
        let root = URL(fileURLWithPath: "/Users/huangzhe/Documents/GitHub/OrangeLen/build/provider-fixes21/fixtures")
        open(root.appendingPathComponent(name), trigger: "manual-demo")
    }
    @objc private func enableFromUser() {
        guard AXIsProcessTrusted() else {
            status.stringValue = "请在系统设置 → 隐私与安全性 → 辅助功能中手动允许此原型，然后再次点击启用。"
            // This action must only be invoked by the user after reviewing the permission request.
            _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
            return
        }
        guard eventTap == nil else { return }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let helper = Unmanaged<FinderSpaceHelper>.fromOpaque(userInfo).takeUnretainedValue()
            return helper.handle(type, event: event)
        }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: callback, userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            status.stringValue = "无法创建空格事件监听；请检查辅助功能授权。"; return
        }
        eventTap = tap
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        enabled = true; CGEvent.tapEnable(tap: tap, enable: true)
        status.stringValue = "已启用。仅 Finder 单选上述后缀时处理无修饰键空格；空格或 Esc 关闭辅助预览。"
        logger.notice("helper enabled source=FinderSpaceHelper accessibility=true")
    }
    private func handle(_ type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if enabled, let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        guard enabled, NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder" else { return Unmanaged.passUnretained(event) }
        let key = event.getIntegerValueField(.keyboardEventKeycode)
        let modifiers = event.flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift, .maskSecondaryFn])
        guard modifiers.isEmpty, key == 49 || key == 53 else { return Unmanaged.passUnretained(event) }
        if preview.isVisible {
            if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 { closePreview() }
            return nil
        }
        guard key == 49, event.getIntegerValueField(.keyboardEventAutorepeat) == 0,
              let url = FinderSelection.singleURL(), blockedExtensions.contains(url.pathExtension.lowercased()) else { return Unmanaged.passUnretained(event) }
        open(url, trigger: "finder-space")
        return nil
    }
    private func open(_ url: URL, trigger: String) {
        let id = UUID(); generation = id; lastURL = url
        let ext = url.pathExtension.lowercased()
        logger.notice("helper received source=FinderSpaceHelper trigger=\(trigger, privacy: .public) type=\(ext, privacy: .public) file=\(url.lastPathComponent, privacy: .public) request=\(id.uuidString, privacy: .public)")
        reader.previewCategory = nil
        reader.open(url) { [weak self] error in
            guard let self, self.generation == id else { return }
            let ok = error == nil
            logger.notice("helper completed source=FinderSpaceHelper success=\(ok, privacy: .public) type=\(ext, privacy: .public) request=\(id.uuidString, privacy: .public)")
        }
        preview.title = "\(url.lastPathComponent) — OrangeLen 辅助预览（非系统 Quick Look）"
        preview.center(); preview.makeKeyAndOrderFront(nil)
    }
    private func closePreview() { generation = UUID(); reader.close(); preview.orderOut(nil); lastURL = nil }
    @objc private func stop() {
        enabled = false
        if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: false); CFMachPortInvalidate(eventTap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        eventTap = nil; source = nil; closePreview(); status.stringValue = "已停止。Finder 空格恢复系统处理。"
        logger.notice("helper stopped source=FinderSpaceHelper")
    }
    func applicationWillTerminate(_ notification: Notification) { stop() }
    func windowWillClose(_ notification: Notification) { if notification.object as? NSWindow === preview { closePreview() } }
}

private enum FinderSelection {
    static func value(_ element: AXUIElement, _ key: CFString) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key, &result) == .success else { return nil }
        return result
    }
    static func singleURL() -> URL? {
        guard let finder = NSWorkspace.shared.frontmostApplication, finder.bundleIdentifier == "com.apple.finder" else { return nil }
        let app = AXUIElementCreateApplication(finder.processIdentifier)
        AXUIElementSetMessagingTimeout(app, 0.06)
        if let focus = value(app, kAXFocusedUIElementAttribute as CFString), CFGetTypeID(focus) == AXUIElementGetTypeID() {
            let element = focus as! AXUIElement
            let role = value(element, kAXRoleAttribute as CFString) as? String ?? ""
            if [kAXTextFieldRole, kAXTextAreaRole, kAXComboBoxRole].contains(role) { return nil }
        }
        guard let rawWindow = value(app, kAXFocusedWindowAttribute as CFString), CFGetTypeID(rawWindow) == AXUIElementGetTypeID() else { return nil }
        let window = rawWindow as! AXUIElement
        let deadline = Date().addingTimeInterval(0.15)
        var queue: [AXUIElement] = [window], inspected = 0
        while !queue.isEmpty && inspected < 450 && Date() < deadline {
            let current = queue.removeFirst(); inspected += 1
            let description = value(current, kAXDescriptionAttribute as CFString) as? String ?? ""
            let identifier = value(current, kAXIdentifierAttribute as CFString) as? String ?? ""
            if description.lowercased().contains("sidebar") || identifier.lowercased().contains("sidebar") { continue }
            let rows = value(current, kAXSelectedRowsAttribute as CFString) as? [AXUIElement] ?? []
            if !rows.isEmpty {
                let urls = rows.compactMap { url(in: $0, deadline: deadline) }
                if !urls.isEmpty { return rows.count == 1 && urls.count == 1 ? urls[0] : nil }
            }
            if let children = value(current, kAXChildrenAttribute as CFString) as? [AXUIElement] { queue.append(contentsOf: children) }
        }
        return nil
    }
    static func url(in element: AXUIElement, deadline: Date) -> URL? {
        var queue = [element], inspected = 0
        while !queue.isEmpty && inspected < 50 && Date() < deadline {
            let current = queue.removeFirst(); inspected += 1
            if let url = value(current, kAXURLAttribute as CFString) as? URL, url.isFileURL { return url }
            if let string = value(current, kAXURLAttribute as CFString) as? String, let url = URL(string: string), url.isFileURL { return url }
            if let children = value(current, kAXChildrenAttribute as CFString) as? [AXUIElement] { queue.append(contentsOf: children) }
        }
        return nil
    }
}
