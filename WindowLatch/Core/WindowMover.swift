import AppKit
import ApplicationServices

@MainActor
enum WindowMover {
    /// Returns the target rect in AX coords (top-left, primary-relative) for `zone` on `screen`.
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
        let leftExternal = zone.rect.minX <= 0.0001
        let rightExternal = zone.rect.maxX >= 0.9999
        let topExternal = zone.rect.minY <= 0.0001
        let bottomExternal = zone.rect.maxY >= 0.9999

        let leftGap = leftExternal ? gap : gap / 2
        let rightGap = rightExternal ? gap : gap / 2
        let topGap = topExternal ? gap : gap / 2
        let bottomGap = bottomExternal ? gap : gap / 2

        rectNS.origin.x += leftGap
        rectNS.size.width -= leftGap + rightGap
        rectNS.origin.y += bottomGap
        rectNS.size.height -= topGap + bottomGap

        return ScreenManager.shared.toAX(rectNS)
    }
}
