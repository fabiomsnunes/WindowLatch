import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    init(settings: SettingsStore, zones: ZoneStore, screens: ScreenManager) {
        let hostingController = NSHostingController(
            rootView: SettingsView(settings: settings, zones: zones, screens: screens)
        )

        let window = NSWindow(contentViewController: hostingController)
        window.title = "WindowLatch Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
