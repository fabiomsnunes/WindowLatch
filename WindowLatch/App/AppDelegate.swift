import AppKit
import KeyboardShortcuts
import SwiftUI

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
    }

    // MARK: - Global shortcuts

    private func setupShortcuts() {
        KeyboardShortcuts.onKeyDown(for: .cycleLeft) { [weak self] in
            self?.cycleCoordinator.handle(.left)
        }
        KeyboardShortcuts.onKeyDown(for: .cycleRight) { [weak self] in
            self?.cycleCoordinator.handle(.right)
        }
        KeyboardShortcuts.onKeyDown(for: .cycleUp) { [weak self] in
            self?.cycleCoordinator.handle(.up)
        }
        KeyboardShortcuts.onKeyDown(for: .cycleDown) { [weak self] in
            self?.cycleCoordinator.handle(.down)
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
}
