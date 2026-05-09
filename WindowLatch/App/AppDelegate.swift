import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var onboardingController: OnboardingWindowController?
    private var settingsController: SettingsWindowController?
    let permissions = PermissionsManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPermissionsObserver()

        if !permissions.isTrusted {
            showOnboarding()
        }
    }

    // MARK: - Status item

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.split.2x2",
                accessibilityDescription: "WindowLatch"
            )
            button.image?.isTemplate = true
        }
        item.menu = buildMenu()
        item.behavior = []
        statusItem = item
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(
            title: "About WindowLatch",
            action: #selector(showAbout(_:)),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        // PRD-3: temporary test items (removed in PRD-4 once shortcuts land).
        menu.addItem(.separator())
        let testHeader = NSMenuItem(title: "Test", action: nil, keyEquivalent: "")
        testHeader.isEnabled = false
        menu.addItem(testHeader)
        addTestItem(menu, title: "Test: Left Half",            zone: DefaultLayouts.halves.zones[0])
        addTestItem(menu, title: "Test: Right Half",           zone: DefaultLayouts.halves.zones[1])
        addTestItem(menu, title: "Test: Top-Left Quadrant",    zone: DefaultLayouts.quadrants.zones[0])
        addTestItem(menu, title: "Test: Top-Right Quadrant",   zone: DefaultLayouts.quadrants.zones[1])
        addTestItem(menu, title: "Test: Bottom-Left Quadrant", zone: DefaultLayouts.quadrants.zones[2])
        addTestItem(menu, title: "Test: Bottom-Right Quadrant", zone: DefaultLayouts.quadrants.zones[3])

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit WindowLatch",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        return menu
    }

    private func addTestItem(_ menu: NSMenu, title: String, zone: Zone) {
        let item = NSMenuItem(title: title, action: #selector(performTestMove(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = zone
        menu.addItem(item)
    }

    @objc private func performTestMove(_ sender: NSMenuItem) {
        guard let zone = sender.representedObject as? Zone else { return }
        WindowMover.moveFocusedWindow(to: zone, gap: 8)
    }

    // MARK: - Permissions

    private func setupPermissionsObserver() {
        permissions.onChange = { [weak self] isTrusted in
            guard let self else { return }
            if isTrusted {
                self.onboardingController?.hide()
            } else if self.onboardingController == nil || self.onboardingController?.window?.isVisible == false {
                self.showOnboarding()
            }
        }
    }

    private func showOnboarding() {
        let controller = onboardingController ?? OnboardingWindowController(permissions: permissions)
        onboardingController = controller
        controller.show()
    }

    // MARK: - Menu actions

    @objc private func openSettings(_ sender: Any?) {
        let controller = settingsController ?? SettingsWindowController()
        settingsController = controller
        controller.show()
    }

    @objc private func showAbout(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(sender)
    }
}
