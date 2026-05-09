import CoreGraphics
import Foundation
import Testing
@testable import WindowLatch

/// Verifies `WindowMover.computeTargetRect` gap math. Tests assert width/height
/// (flip-invariant) and inter-zone relationships rather than absolute Y, so they
/// don't depend on the test machine's primary screen height.
@MainActor
struct ZoneLayoutTests {
    private func screen(width: CGFloat, height: CGFloat) -> ScreenInfo {
        // visibleFrame == frame → no menu/dock subtraction in tests.
        let f = CGRect(x: 0, y: 0, width: width, height: height)
        return ScreenInfo(id: 1, frame: f, visibleFrame: f, name: "test")
    }

    // MARK: - Gap math

    @Test
    func leftHalf_gap8_reservesFullGapOnOuterEdgesAndHalfGapOnInnerEdge() {
        let s = screen(width: 1000, height: 800)
        let rect = WindowMover.computeTargetRect(zone: DefaultLayouts.leftHalf, on: s, gap: 8)
        // Width: half of 1000 minus full gap (left external) minus half gap (right inner) = 500 - 8 - 4 = 488
        #expect(rect.size.width == 488)
        // Height: full minus full gap top/bottom (both external) = 800 - 16 = 784
        #expect(rect.size.height == 784)
    }

    @Test
    func gapZero_zonesFillScreenExactly() {
        let s = screen(width: 1920, height: 1080)
        let left = WindowMover.computeTargetRect(zone: DefaultLayouts.leftHalf, on: s, gap: 0)
        let right = WindowMover.computeTargetRect(zone: DefaultLayouts.rightHalf, on: s, gap: 0)
        #expect(left.size.width == 960)
        #expect(right.size.width == 960)
        #expect(left.size.width + right.size.width == 1920)
        #expect(left.size.height == 1080)
    }

    @Test
    func quadrants_addUpToFullScreenMinusGaps() {
        let s = screen(width: 1600, height: 1000)
        let gap: CGFloat = 8
        let tl = WindowMover.computeTargetRect(zone: DefaultLayouts.topLeftQuadrant, on: s, gap: gap)
        let tr = WindowMover.computeTargetRect(zone: DefaultLayouts.topRightQuadrant, on: s, gap: gap)
        let bl = WindowMover.computeTargetRect(zone: DefaultLayouts.bottomLeftQuadrant, on: s, gap: gap)
        let br = WindowMover.computeTargetRect(zone: DefaultLayouts.bottomRightQuadrant, on: s, gap: gap)
        // Each quadrant: width = 800 - 8 (outer) - 4 (inner) = 788; height = 500 - 8 - 4 = 488
        #expect(tl.size.width == 788)
        #expect(tl.size.height == 488)
        // All four quadrants have identical dimensions (symmetry).
        #expect(tl.size == tr.size)
        #expect(tl.size == bl.size)
        #expect(tl.size == br.size)
    }

    // MARK: - Multi-resolution coverage

    @Test
    func leftHalfMath_isLinearAcrossResolutions() {
        let resolutions: [(CGFloat, CGFloat)] = [
            (1280, 800),
            (1920, 1080),
            (3840, 1600), // ultrawide
            (5120, 2880), // 5K
        ]
        for (w, h) in resolutions {
            let s = screen(width: w, height: h)
            let rect = WindowMover.computeTargetRect(zone: DefaultLayouts.leftHalf, on: s, gap: 8)
            // width = w/2 - 8 (external) - 4 (inner) = w/2 - 12
            #expect(rect.size.width == w / 2 - 12, "Width mismatch at \(w)x\(h)")
            #expect(rect.size.height == h - 16,    "Height mismatch at \(w)x\(h)")
        }
    }

    @Test
    func leftThird_widthIsOneThirdMinusGaps() {
        let s = screen(width: 1800, height: 1000)
        let rect = WindowMover.computeTargetRect(zone: DefaultLayouts.leftThird, on: s, gap: 8)
        // width = 1800/3 - 8 (left external) - 4 (right inner) = 600 - 12 = 588
        #expect(abs(rect.size.width - 588) < 0.001)
    }

    @Test
    func rightTwoThirds_widthIs2of3MinusGaps() {
        let s = screen(width: 1800, height: 1000)
        let rect = WindowMover.computeTargetRect(zone: DefaultLayouts.rightTwoThirds, on: s, gap: 8)
        // width = 1800 * 2/3 - 4 (left inner) - 8 (right external) = 1200 - 12 = 1188
        #expect(abs(rect.size.width - 1188) < 0.001)
    }

    // MARK: - Visible frame offset

    @Test
    func visibleFrameOffset_isHonoured() {
        // Simulate a screen with menu bar and dock taking 64px combined.
        let frame = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let visible = CGRect(x: 0, y: 0, width: 1000, height: 736)
        let s = ScreenInfo(id: 1, frame: frame, visibleFrame: visible, name: "test")
        let rect = WindowMover.computeTargetRect(zone: DefaultLayouts.leftHalf, on: s, gap: 8)
        // Height = 736 - 16 = 720
        #expect(rect.size.height == 720)
    }
}
