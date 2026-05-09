import AppKit
import ApplicationServices
import Observation

struct ScreenInfo: Identifiable, Hashable, Sendable {
    let id: CGDirectDisplayID
    /// Full screen frame in NSScreen coordinates (bottom-left origin, primary at (0,0)).
    let frame: CGRect
    /// Screen frame minus menu bar and Dock, in NSScreen coordinates.
    let visibleFrame: CGRect
    /// Display name from `NSScreen.localizedName`. UI only — not unique.
    let name: String
}

@Observable
final class ScreenManager {
    static let shared = ScreenManager()

    private(set) var screens: [ScreenInfo] = []
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    private init() {
        refresh()
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.refresh() }
            }
        )
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func refresh() {
        screens = NSScreen.screens.compactMap { ns in
            guard let id = ns.displayID else { return nil }
            return ScreenInfo(
                id: id,
                frame: ns.frame,
                visibleFrame: ns.visibleFrame,
                name: ns.localizedName
            )
        }
    }

    /// Primary screen — the one with NSScreen frame origin at (0,0).
    var primary: ScreenInfo? {
        screens.first(where: { $0.frame.origin == .zero }) ?? screens.first
    }

    // MARK: - Coordinate conversion

    /// Converts a rect from NSScreen coords (bottom-left, primary-relative) to AX coords (top-left, primary-relative).
    func toAX(_ rect: CGRect) -> CGRect {
        guard let primary else { return rect }
        let flippedY = primary.frame.height - rect.origin.y - rect.size.height
        return CGRect(x: rect.origin.x, y: flippedY, width: rect.size.width, height: rect.size.height)
    }

    /// Converts a single point from AX coords to NSScreen coords.
    private func nsPoint(fromAX point: CGPoint) -> CGPoint? {
        guard let primary else { return nil }
        return CGPoint(x: point.x, y: primary.frame.height - point.y)
    }

    // MARK: - Window-to-screen lookup

    /// Returns the screen containing a point expressed in AX coords.
    func screen(containingAXPoint axPoint: CGPoint) -> ScreenInfo? {
        guard let nsPt = nsPoint(fromAX: axPoint) else { return nil }
        return screens.first(where: { $0.frame.contains(nsPt) })
    }

    /// Returns the screen the focused window's center sits in. Falls back to primary.
    func screen(forFocusedWindow window: AXUIElement) -> ScreenInfo? {
        guard let frame = AccessibilityClient.frame(of: window) else { return primary }
        let mid = CGPoint(x: frame.midX, y: frame.midY) // AX coords
        return screen(containingAXPoint: mid) ?? primary
    }

    // MARK: - Spatial adjacency (NSScreen coords; y grows up, "above" = higher y)

    /// Returns the nearest screen whose right edge sits at or before `screen`'s left edge.
    func screenLeft(of screen: ScreenInfo) -> ScreenInfo? {
        let candidates = screens.filter {
            $0.id != screen.id && $0.frame.maxX <= screen.frame.minX + 1
        }
        return candidates.min { (screen.frame.minX - $0.frame.maxX) < (screen.frame.minX - $1.frame.maxX) }
    }

    /// Returns the nearest screen whose left edge sits at or after `screen`'s right edge.
    func screenRight(of screen: ScreenInfo) -> ScreenInfo? {
        let candidates = screens.filter {
            $0.id != screen.id && $0.frame.minX >= screen.frame.maxX - 1
        }
        return candidates.min { ($0.frame.minX - screen.frame.maxX) < ($1.frame.minX - screen.frame.maxX) }
    }

    /// Returns the nearest screen physically above `screen` (higher NSScreen y).
    func screenAbove(of screen: ScreenInfo) -> ScreenInfo? {
        let candidates = screens.filter {
            $0.id != screen.id && $0.frame.minY >= screen.frame.maxY - 1
        }
        return candidates.min { ($0.frame.minY - screen.frame.maxY) < ($1.frame.minY - screen.frame.maxY) }
    }

    /// Returns the nearest screen physically below `screen` (lower NSScreen y).
    func screenBelow(of screen: ScreenInfo) -> ScreenInfo? {
        let candidates = screens.filter {
            $0.id != screen.id && $0.frame.maxY <= screen.frame.minY + 1
        }
        return candidates.min { (screen.frame.minY - $0.frame.maxY) < (screen.frame.minY - $1.frame.maxY) }
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
