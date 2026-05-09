import AppKit
import KeyboardShortcuts
import OSLog
import SwiftUI

private let log = Logger(subsystem: "com.fabiomsnunes.WindowLatch", category: "startup")

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var onboardingController: OnboardingWindowController?
    private var settingsController: SettingsWindowController?
    private let cycleCoordinator = CycleCoordinator(settings: .shared, zones: .shared)
    let permissions = PermissionsManager()

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPermissionsObserver()
        setupShortcuts()
        applyShortcutModifier(SettingsStore.shared.modifier)
        SettingsStore.shared.addObserver { [weak self] in
            self?.applyShortcutModifier(SettingsStore.shared.modifier)
        }
        logStartupDiagnostics()

        if !permissions.isTrusted {
            showOnboarding()
        }
    }

    private func applyShortcutModifier(_ modifier: ShortcutModifier) {
        let mods = modifier.nsFlags
        KeyboardShortcuts.setShortcut(.init(.leftArrow, modifiers: mods), for: .cycleLeft)
        KeyboardShortcuts.setShortcut(.init(.rightArrow, modifiers: mods), for: .cycleRight)
        KeyboardShortcuts.setShortcut(.init(.upArrow, modifiers: mods), for: .cycleUp)
        KeyboardShortcuts.setShortcut(.init(.downArrow, modifiers: mods), for: .cycleDown)
        log.info("Cycle shortcuts bound to \(modifier.rawValue, privacy: .public) + arrows")
    }

    private func logStartupDiagnostics() {
        log.info("WindowLatch starting; AX trusted=\(self.permissions.isTrusted, privacy: .public)")
        for (i, screen) in NSScreen.screens.enumerated() {
            let id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
            let f = screen.frame
            let v = screen.visibleFrame
            log.info(
                """
                screen[\(i, privacy: .public)] id=\(id, privacy: .public) \
                frame=(\(f.minX, privacy: .public),\(f.minY, privacy: .public) \
                \(f.width, privacy: .public)x\(f.height, privacy: .public)) \
                visible=(\(v.minX, privacy: .public),\(v.minY, privacy: .public) \
                \(v.width, privacy: .public)x\(v.height, privacy: .public))
                """
            )
        }
    }

    // MARK: - Global shortcuts

    private func setupShortcuts() {
        KeyboardShortcuts.onKeyDown(for: .cycleLeft) { [weak self] in
            log.info("cycleLeft fired")
            self?.cycleCoordinator.handle(.left)
        }
        KeyboardShortcuts.onKeyDown(for: .cycleRight) { [weak self] in
            log.info("cycleRight fired")
            self?.cycleCoordinator.handle(.right)
        }
        KeyboardShortcuts.onKeyDown(for: .cycleUp) { [weak self] in
            log.info("cycleUp fired")
            self?.cycleCoordinator.handle(.up)
        }
        KeyboardShortcuts.onKeyDown(for: .cycleDown) { [weak self] in
            log.info("cycleDown fired")
            self?.cycleCoordinator.handle(.down)
        }
        log.info("Shortcuts registered: cycleLeft/Right/Up/Down")
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

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit WindowLatch",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        return menu
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

    @objc private func openSettings(_: Any?) {
        let controller = settingsController ?? SettingsWindowController(
            settings: .shared,
            zones: .shared,
            screens: .shared
        )
        settingsController = controller
        controller.show()
    }

    @objc private func showAbout(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(sender)
    }
}
