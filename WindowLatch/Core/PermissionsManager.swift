import AppKit
import ApplicationServices
import Observation
import OSLog

private let log = Logger(subsystem: "com.fabiomsnunes.WindowLatch", category: "permissions")

@Observable
final class PermissionsManager {
    private(set) var isTrusted: Bool = false
    var onChange: ((Bool) -> Void)?

    @ObservationIgnored private var pollTimer: Timer?
    @ObservationIgnored private var activateObserver: NSObjectProtocol?
    @ObservationIgnored private var distributedObserver: NSObjectProtocol?

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
        // macOS posts this distributed notification when the AX TCC database changes,
        // i.e. the user grants or revokes accessibility from System Settings. Subscribing
        // to it is more reliable than relying on didBecomeActive (which doesn't fire if
        // the user grants permission and the app is already active).
        distributedObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.accessibility.api"),
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
        if let distributedObserver {
            DistributedNotificationCenter.default().removeObserver(distributedObserver)
        }
        pollTimer?.invalidate()
    }

    func recheck() {
        let trusted = AccessibilityClient.isTrusted()
        guard trusted != isTrusted else { return }
        log.info("Accessibility trust changed: \(trusted, privacy: .public)")
        isTrusted = trusted
        onChange?(trusted)
    }

    /// Clears WindowLatch's Accessibility grant via `tccutil`, then relaunches the app.
    ///
    /// A reset leaves the *running* process in a half-trusted state that's awkward to
    /// recover from in place — the same state the onboarding screen warns about. So we
    /// relaunch into a clean launch, where `applicationDidFinishLaunching` sees the
    /// missing permission and shows onboarding again.
    func resetAccessibilityAndRelaunch() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }

        let reset = Process()
        reset.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        reset.arguments = ["reset", "Accessibility", bundleID]
        try? reset.run()
        reset.waitUntilExit()

        let relaunch = Process()
        relaunch.executableURL = URL(fileURLWithPath: "/bin/sh")
        relaunch.arguments = ["-c", "sleep 1; open \"\(Bundle.main.bundlePath)\""]
        try? relaunch.run()

        NSApp.terminate(nil)
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
