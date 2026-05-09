import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import OSLog

private let log = Logger(subsystem: "com.fabiomsnunes.WindowLatch", category: "cycle")

/// Bridges the pure `CycleEngine` to the live AX / screen world.
@MainActor
final class CycleCoordinator {
    private var gap: CGFloat
    private var resetDelay: TimeInterval
    private var state: CycleState = .initial
    private let settings: SettingsStore
    private let zones: ZoneStore

    init(settings: SettingsStore, zones: ZoneStore) {
        self.settings = settings
        self.zones = zones
        self.gap = settings.gap
        self.resetDelay = settings.cycleResetDelay
        settings.addObserver { [weak self] in
            guard let self else { return }
            self.gap = settings.gap
            self.resetDelay = settings.cycleResetDelay
        }
    }

    func handle(_ direction: Direction) {
        log.info("handle(\(direction.rawValue, privacy: .public)) entered")
        guard let window = AccessibilityClient.focusedWindow() else {
            log.info("No focused window — ignoring \(direction.rawValue, privacy: .public)")
            return
        }
        guard let frame = AccessibilityClient.frame(of: window) else {
            log.info("Could not read frame of focused window")
            return
        }
        guard let currentScreen = ScreenManager.shared.screen(forFocusedWindow: window) else {
            log.info("Could not determine current screen")
            return
        }

        let currentZoneID = matchedZoneID(for: frame, on: currentScreen)
        let neighbour = ScreenManager.shared.screen(in: direction, of: currentScreen)

        // Build an engine using the zone groups enabled for the current monitor; the
        // engine is stateless apart from its constants so reconstructing per-keystroke
        // is cheap. Combo (quadrant snap) is gated on the `quarters` group.
        let enabled = zones.enabledGroups(for: currentScreen.id)
        let engine = CycleEngine(
            resetDelay: resetDelay,
            comboEnabled: enabled.contains(.quarters),
            sequence: { ZoneGroup.sequence(for: $0, enabled: enabled) }
        )

        let input = CycleInput(
            direction: direction,
            currentZoneID: currentZoneID,
            now: Date(),
            hasNeighbour: neighbour != nil,
            state: state
        )
        let (action, newState) = engine.process(input)
        state = newState

        switch action {
        case .noOp:
            log.debug("noOp for \(direction.rawValue, privacy: .public) (no neighbour or already exhausted)")
        case let .apply(zone, .current):
            apply(zone: zone, on: currentScreen, window: window)
        case let .apply(zone, .neighbour):
            if let neighbour {
                apply(zone: zone, on: neighbour, window: window)
            }
        }
    }

    private func apply(zone: Zone, on screen: ScreenInfo, window: AXUIElement) {
        let target = WindowMover.computeTargetRect(zone: zone, on: screen, gap: gap)
        log.debug("Apply zone \(zone.id, privacy: .public) on \(screen.name, privacy: .public)")
        AccessibilityClient.setFrame(target, on: window)
    }

    /// Returns the ID of the zone whose computed AX target matches `frame` on `screen`, within tolerance.
    private func matchedZoneID(for frame: CGRect, on screen: ScreenInfo) -> String? {
        let tolerance = max(gap * 2, 4)
        for zone in DefaultLayouts.allCycleZones {
            let target = WindowMover.computeTargetRect(zone: zone, on: screen, gap: gap)
            if abs(frame.origin.x - target.origin.x) <= tolerance,
               abs(frame.origin.y - target.origin.y) <= tolerance,
               abs(frame.size.width - target.size.width) <= tolerance,
               abs(frame.size.height - target.size.height) <= tolerance
            {
                return zone.id
            }
        }
        return nil
    }
}

extension ScreenManager {
    /// Returns the neighbouring screen in `direction`, if any.
    func screen(in direction: Direction, of screen: ScreenInfo) -> ScreenInfo? {
        switch direction {
        case .left: screenLeft(of: screen)
        case .right: screenRight(of: screen)
        case .up: screenAbove(of: screen)
        case .down: screenBelow(of: screen)
        }
    }
}
