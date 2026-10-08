import AppKit
// Dedicated XCTest host: no user data or UI, but a real application bundle for
// NSXPC service discovery. Only the DocumentBroker child runs the importer.
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
app.run()
