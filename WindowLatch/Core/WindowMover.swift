import AppKit
import ApplicationServices
import OSLog

private let log = Logger(subsystem: "com.fabiomsnunes.WindowLatch", category: "mover")

@MainActor
enum WindowMover {
    /// Moves the currently focused window to `zone` on the screen the window is currently on.
    /// No-op (with a log line) if no window is focused.
    static func moveFocusedWindow(to zone: Zone, gap: CGFloat = 8) {
        guard let window = AccessibilityClient.focusedWindow() else {
            log.info("No focused window — ignoring move")
            return
        }
        guard let screen = ScreenManager.shared.screen(forFocusedWindow: window) else {
            log.info("Could not determine screen for focused window — ignoring move")
            return
        }
        let target = computeTargetRect(zone: zone, on: screen, gap: gap)
        log.debug("Move to \(zone.id, privacy: .public) on \(screen.name, privacy: .public): target AX \(String(describing: target), privacy: .public)")
        AccessibilityClient.setFrame(target, on: window)
    }

    /// Returns the target rect in AX coords (top-left, primary-relative) for `zone` on `screen`.
    /// Public for testability.
    static func computeTargetRect(zone: Zone, on screen: ScreenInfo, gap: CGFloat) -> CGRect {
        let vf = screen.visibleFrame // NSScreen coords (bottom-left)

        // Convert zone's AX-style fractional y-origin to NSScreen-style fractional y-origin.
        let zoneNSYOriginFraction = 1 - (zone.rect.origin.y + zone.rect.size.height)

        var rectNS = CGRect(
            x: vf.origin.x + zone.rect.origin.x * vf.size.width,
            y: vf.origin.y + zoneNSYOriginFraction * vf.size.height,
            width: zone.rect.size.width * vf.size.width,
            height: zone.rect.size.height * vf.size.height
        )

        // Edge classification — full gap on outer edges, half gap on inner edges between zones.
        let leftExternal   = zone.rect.minX <= 0.0001
        let rightExternal  = zone.rect.maxX >= 0.9999
        let topExternal    = zone.rect.minY <= 0.0001 // top in zone coords = top of screen
        let bottomExternal = zone.rect.maxY >= 0.9999 // bottom in zone coords = bottom of screen

        let leftGap   = leftExternal   ? gap : gap / 2
        let rightGap  = rightExternal  ? gap : gap / 2
        let topGap    = topExternal    ? gap : gap / 2
        let bottomGap = bottomExternal ? gap : gap / 2

        // Apply insets in NSScreen coords (y grows up).
        rectNS.origin.x   += leftGap
        rectNS.size.width  -= leftGap + rightGap
        rectNS.origin.y   += bottomGap
        rectNS.size.height -= topGap + bottomGap

        return ScreenManager.shared.toAX(rectNS)
    }
}
