import CoreGraphics
import Foundation
import Testing
@testable import WindowLatch

struct ScreenAdjacencyTests {
    private func makeScreen(_ id: CGDirectDisplayID, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> ScreenInfo {
        let f = CGRect(x: x, y: y, width: w, height: h)
        return ScreenInfo(id: id, frame: f, visibleFrame: f, name: "screen-\(id)")
    }

    // MARK: - Two-monitor horizontal

    @Test
    func horizontalLayout_findsLeftAndRightNeighbours() {
        let primary   = makeScreen(1, x: 0,    y: 0, w: 1920, h: 1080)
        let secondary = makeScreen(2, x: 1920, y: 0, w: 1920, h: 1080)
        let screens = [primary, secondary]

        #expect(ScreenAdjacency.screenRight(of: primary, in: screens)?.id == 2)
        #expect(ScreenAdjacency.screenLeft(of: secondary, in: screens)?.id == 1)
        #expect(ScreenAdjacency.screenLeft(of: primary, in: screens) == nil)
        #expect(ScreenAdjacency.screenRight(of: secondary, in: screens) == nil)
        #expect(ScreenAdjacency.screenAbove(of: primary, in: screens) == nil)
        #expect(ScreenAdjacency.screenBelow(of: primary, in: screens) == nil)
    }

    // MARK: - Vertical stack

    @Test
    func verticalStack_findsAboveAndBelow() {
        // Primary at (0,0). Secondary above it (NSScreen y grows up).
        let primary = makeScreen(1, x: 0, y: 0,    w: 1920, h: 1080)
        let above   = makeScreen(2, x: 0, y: 1080, w: 1920, h: 1080)
        let screens = [primary, above]

        #expect(ScreenAdjacency.screenAbove(of: primary, in: screens)?.id == 2)
        #expect(ScreenAdjacency.screenBelow(of: above, in: screens)?.id == 1)
        #expect(ScreenAdjacency.screenAbove(of: above, in: screens) == nil)
        #expect(ScreenAdjacency.screenBelow(of: primary, in: screens) == nil)
    }

    // MARK: - L-shape (3 monitors)

    @Test
    func lShape_threeMonitors_resolvesAdjacencyCorrectly() {
        // Primary in centre, secondary to the right, tertiary above primary.
        let primary   = makeScreen(1, x: 0,    y: 0,    w: 1920, h: 1080)
        let right     = makeScreen(2, x: 1920, y: 0,    w: 1920, h: 1080)
        let above     = makeScreen(3, x: 0,    y: 1080, w: 1920, h: 1080)
        let screens = [primary, right, above]

        #expect(ScreenAdjacency.screenRight(of: primary, in: screens)?.id == 2)
        #expect(ScreenAdjacency.screenAbove(of: primary, in: screens)?.id == 3)
        #expect(ScreenAdjacency.screenLeft(of: right, in: screens)?.id == 1)
        #expect(ScreenAdjacency.screenBelow(of: above, in: screens)?.id == 1)
        // Note: adjacency is decided per-axis only; corner-touching screens are
        // considered neighbours on both axes. `above` and `right` share the (1920, 1080)
        // corner, so above.right == right by design.
        #expect(ScreenAdjacency.screenRight(of: above, in: screens)?.id == 2)
    }

    // MARK: - Picks nearest when multiple candidates

    @Test
    func multipleCandidates_picksNearest() {
        // Primary at (0,0). Two screens to the right with a gap between.
        let primary = makeScreen(1, x: 0,    y: 0, w: 1000, h: 1000)
        let near    = makeScreen(2, x: 1000, y: 0, w: 1000, h: 1000)
        let far     = makeScreen(3, x: 3000, y: 0, w: 1000, h: 1000)
        let screens = [primary, near, far]

        #expect(ScreenAdjacency.screenRight(of: primary, in: screens)?.id == 2)
    }

    // MARK: - Tolerates 1px misalignment

    @Test
    func touchingWithSubpixelOverlap_isStillAdjacent() {
        // Some setups report frames overlapping by ~1px due to scale rounding.
        let primary = makeScreen(1, x: 0,      y: 0, w: 1920, h: 1080)
        let right   = makeScreen(2, x: 1919.5, y: 0, w: 1920, h: 1080)
        let screens = [primary, right]

        #expect(ScreenAdjacency.screenRight(of: primary, in: screens)?.id == 2)
        #expect(ScreenAdjacency.screenLeft(of: right, in: screens)?.id == 1)
    }

    // MARK: - Single screen

    @Test
    func singleScreen_hasNoNeighbours() {
        let only = makeScreen(1, x: 0, y: 0, w: 1920, h: 1080)
        let screens = [only]
        #expect(ScreenAdjacency.screenLeft(of: only, in: screens) == nil)
        #expect(ScreenAdjacency.screenRight(of: only, in: screens) == nil)
        #expect(ScreenAdjacency.screenAbove(of: only, in: screens) == nil)
        #expect(ScreenAdjacency.screenBelow(of: only, in: screens) == nil)
    }
}
