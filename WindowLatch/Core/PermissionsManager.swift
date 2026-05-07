import AppKit
import ApplicationServices
import Observation

@Observable
final class PermissionsManager {
    private(set) var isTrusted: Bool = false
    var onChange: ((Bool) -> Void)?

    @ObservationIgnored private var pollTimer: Timer?
    @ObservationIgnored private var activateObserver: NSObjectProtocol?

    init() {
        recheck()
        activateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.recheck()
            }
        }
    }

    deinit {
        if let activateObserver {
            NotificationCenter.default.removeObserver(activateObserver)
        }
        pollTimer?.invalidate()
    }

    func recheck() {
        let trusted = AXIsProcessTrustedWithOptions(nil)
        guard trusted != isTrusted else { return }
        isTrusted = trusted
        onChange?(trusted)
    }

    func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.recheck()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}
