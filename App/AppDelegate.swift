import OrangeLenCore
import AppKit
import OrangeLenUI
import SwiftUI
@main
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) { app.run() }
    }
    var window: NSWindow!
    let reader = ReaderController()
    var settingsWindow: NSWindow?
    var diagnosticsWindow: NSWindow?
    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let appItem = NSMenuItem(); menu.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: L10n.text("打开…"), action: #selector(openFile), keyEquivalent: "o")
        appMenu.addItem(withTitle: L10n.text("设置…"), action: #selector(showSettings), keyEquivalent: ",")
        appMenu.addItem(withTitle: L10n.text("Quick Look 诊断…"), action: #selector(showDiagnostics), keyEquivalent: "d")
        appMenu.addItem(withTitle: L10n.text("关闭"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        appMenu.addItem(withTitle: L10n.text("退出 OrangeLen"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let editItem = NSMenuItem(); menu.addItem(editItem); editItem.submenu = NSMenu(title: L10n.text("编辑"))
        editItem.submenu?.addItem(withTitle: L10n.text("复制"), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editItem.submenu?.addItem(withTitle: L10n.text("全选"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        NSApp.mainMenu = menu
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 720), styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "OrangeLen — Quick Look for Developers"
        window.contentViewController = reader
        window.delegate = self; window.isReleasedWhenClosed = false
        window.center(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        if let path = ProcessInfo.processInfo.arguments.dropFirst().first, !path.hasPrefix("-") { reader.open(URL(fileURLWithPath: path)) { _ in } }
    }
    @objc func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            window.title = L10n.text("OrangeLen 设置"); window.isReleasedWhenClosed = false; settingsWindow = window
        }
        settingsWindow?.center(); settingsWindow?.makeKeyAndOrderFront(nil)
    }
    @objc func showDiagnostics() {
        if diagnosticsWindow == nil {
            let controller = DiagnosticsController()
            controller.openFile = { [weak self] url in self?.reader.open(url) { _ in }; self?.window.makeKeyAndOrderFront(nil) }
            let panel = NSWindow(contentViewController: controller)
            panel.title = L10n.text("OrangeLen · Quick Look 诊断"); panel.styleMask.insert(.resizable); panel.isReleasedWhenClosed = false
            diagnosticsWindow = panel
        }
        diagnosticsWindow?.center(); diagnosticsWindow?.makeKeyAndOrderFront(nil)
    }
    func applicationWillTerminate(_ notification: Notification) { reader.close() }
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === window { reader.close() }
    }
    @objc func openFile() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url = panel.url { reader.open(url) { _ in }; window.makeKeyAndOrderFront(nil) }
    }
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        if let path = filenames.first {
            let url = URL(fileURLWithPath: path)
            if url.pathExtension == "orangediagnostics" {
                showDiagnostics(); (diagnosticsWindow?.contentViewController as? DiagnosticsController)?.importSystemReport(url)
            } else { reader.open(url) { _ in }; window.makeKeyAndOrderFront(nil) }
        }
        sender.reply(toOpenOrPrint: .success)
    }
}
