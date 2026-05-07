import AppKit
import SwiftUI

final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    private let permissions: PermissionsManager

    init(permissions: PermissionsManager) {
        self.permissions = permissions

        let hostingController = NSHostingController(
            rootView: OnboardingView(
                permissions: permissions,
                onQuit: { NSApp.terminate(nil) }
            )
        )

        let window = NSWindow(contentViewController: hostingController)
        window.title = "WindowLatch"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        window.level = .floating

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show() {
        permissions.startPolling()
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
    }

    func hide() {
        permissions.stopPolling()
        window?.orderOut(nil)
    }

    func windowWillClose(_ notification: Notification) {
        permissions.stopPolling()
    }
}
