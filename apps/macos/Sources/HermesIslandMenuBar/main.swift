import AppKit
import HermesIslandCompanionCore

@MainActor
final class MenuBarAppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ notification: Notification) {
        let result = CompanionDemo().run()

        statusItem.button?.title = "Hermes"
        statusItem.button?.toolTip = "Hermes Island"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "State: \(result.connectionState)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Island: \(result.islandTitle)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Tasks: \(result.taskCount)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
}

let app = NSApplication.shared
let delegate = MenuBarAppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
