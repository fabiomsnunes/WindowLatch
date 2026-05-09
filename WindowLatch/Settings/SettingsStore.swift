import CoreGraphics
import Foundation
import Observation

/// User-tunable settings persisted in `UserDefaults`. Read by `CycleCoordinator`
/// (gap, resetDelay) and `AppDelegate` (modifier). Mutations notify all
/// registered observers so consumers can react without a restart.
@Observable
@MainActor
final class SettingsStore {
    static let shared = SettingsStore()

    private enum Key {
        static let gap = "gap"
        static let cycleResetDelay = "cycleResetDelay"
        static let modifier = "shortcutModifier"
    }

    private enum Defaults {
        static let gap: CGFloat = 8
        static let cycleResetDelay: TimeInterval = 1.5
        static let modifier: ShortcutModifier = .default
    }

    var gap: CGFloat {
        didSet {
            guard gap != oldValue else { return }
            UserDefaults.standard.set(Double(gap), forKey: Key.gap)
            notify()
        }
    }

    var cycleResetDelay: TimeInterval {
        didSet {
            guard cycleResetDelay != oldValue else { return }
            UserDefaults.standard.set(cycleResetDelay, forKey: Key.cycleResetDelay)
            notify()
        }
    }

    var modifier: ShortcutModifier {
        didSet {
            guard modifier != oldValue else { return }
            UserDefaults.standard.set(modifier.rawValue, forKey: Key.modifier)
            notify()
        }
    }

    @ObservationIgnored private var observers: [() -> Void] = []

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Key.gap) != nil {
            self.gap = CGFloat(defaults.double(forKey: Key.gap))
        } else {
            self.gap = Defaults.gap
        }
        if defaults.object(forKey: Key.cycleResetDelay) != nil {
            self.cycleResetDelay = defaults.double(forKey: Key.cycleResetDelay)
        } else {
            self.cycleResetDelay = Defaults.cycleResetDelay
        }
        if let raw = defaults.string(forKey: Key.modifier),
           let m = ShortcutModifier(rawValue: raw) {
            self.modifier = m
        } else {
            self.modifier = Defaults.modifier
        }
    }

    func addObserver(_ block: @escaping () -> Void) {
        observers.append(block)
    }

    private func notify() {
        observers.forEach { $0() }
    }

    func restoreDefaults() {
        gap = Defaults.gap
        cycleResetDelay = Defaults.cycleResetDelay
        modifier = Defaults.modifier
    }
}
