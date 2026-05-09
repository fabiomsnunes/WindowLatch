import CoreGraphics

/// Pure spatial adjacency helpers for ``ScreenInfo``. Operates on an explicit
/// `[ScreenInfo]` array so it can be unit-tested without `NSScreen.screens`.
///
/// All inputs/outputs are in NSScreen coordinates (y grows up; primary at origin).
nonisolated enum ScreenAdjacency {
    /// Nearest screen whose right edge sits at or before `screen`'s left edge.
    static func screenLeft(of screen: ScreenInfo, in screens: [ScreenInfo]) -> ScreenInfo? {
        let candidates = screens.filter {
            $0.id != screen.id && $0.frame.maxX <= screen.frame.minX + 1
        }
        return candidates.min { (screen.frame.minX - $0.frame.maxX) < (screen.frame.minX - $1.frame.maxX) }
    }

    /// Nearest screen whose left edge sits at or after `screen`'s right edge.
    static func screenRight(of screen: ScreenInfo, in screens: [ScreenInfo]) -> ScreenInfo? {
        let candidates = screens.filter {
            $0.id != screen.id && $0.frame.minX >= screen.frame.maxX - 1
        }
        return candidates.min { ($0.frame.minX - screen.frame.maxX) < ($1.frame.minX - screen.frame.maxX) }
    }

    /// Nearest screen physically above `screen` (higher NSScreen y).
    static func screenAbove(of screen: ScreenInfo, in screens: [ScreenInfo]) -> ScreenInfo? {
        let candidates = screens.filter {
            $0.id != screen.id && $0.frame.minY >= screen.frame.maxY - 1
        }
        return candidates.min { ($0.frame.minY - screen.frame.maxY) < ($1.frame.minY - screen.frame.maxY) }
    }

    /// Nearest screen physically below `screen` (lower NSScreen y).
    static func screenBelow(of screen: ScreenInfo, in screens: [ScreenInfo]) -> ScreenInfo? {
        let candidates = screens.filter {
            $0.id != screen.id && $0.frame.maxY <= screen.frame.minY + 1
        }
        return candidates.min { (screen.frame.minY - $0.frame.maxY) < (screen.frame.minY - $1.frame.maxY) }
    }
}
