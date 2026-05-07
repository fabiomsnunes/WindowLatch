import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    init() {
        let hostingController = NSHostingController(
            rootView: SettingsPlaceholderView()
        )

        let window = NSWindow(contentViewController: hostingController)
        window.title = "WindowLatch Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
            Text("Settings — coming soon")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("General, Shortcuts, Monitors and About will live here.")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .frame(width: 480, height: 320)
    }
}
