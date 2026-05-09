import CoreGraphics
import Foundation
import Observation

/// User-tunable settings persisted in `UserDefaults`. Read by `CycleCoordinator`
/// (gap) and `CycleEngine` (cycleResetDelay). Mutations notify `onChange` so
/// the coordinator can rebuild its engine.
@Observable
@MainActor
final class SettingsStore {
    static let shared = SettingsStore()

    private enum Key {
        static let gap = "gap"
        static let cycleResetDelay = "cycleResetDelay"
    }

    private enum Defaults {
        static let gap: CGFloat = 8
        static let cycleResetDelay: TimeInterval = 1.5
    }

    var onChange: (() -> Void)?

    var gap: CGFloat {
        didSet {
            guard gap != oldValue else { return }
            UserDefaults.standard.set(Double(gap), forKey: Key.gap)
            onChange?()
        }
    }

    var cycleResetDelay: TimeInterval {
        didSet {
            guard cycleResetDelay != oldValue else { return }
            UserDefaults.standard.set(cycleResetDelay, forKey: Key.cycleResetDelay)
            onChange?()
        }
    }

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
    }

    func restoreDefaults() {
        gap = Defaults.gap
        cycleResetDelay = Defaults.cycleResetDelay
    }
}
