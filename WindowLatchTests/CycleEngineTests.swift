import CoreGraphics
import Foundation
import Testing
@testable import WindowLatch

struct CycleEngineTests {
    let engine = CycleEngine()
    let t0 = Date(timeIntervalSince1970: 1_000_000)

    // MARK: - Cycle continuation

    @Test
    func firstPress_appliesFirstZoneOfSequence() {
        let (action, newState) = engine.process(CycleInput(
            direction: .left,
            currentZoneID: nil,
            now: t0,
            hasNeighbour: false,
            state: .initial
        ))
        #expect(action == .apply(DefaultLayouts.leftTwoThirds, on: .current))
        #expect(newState.lastDirection == .left)
        #expect(newState.lastZone == DefaultLayouts.leftTwoThirds)
        #expect(newState.lastTimestamp == t0)
    }

    @Test
    func secondPress_advancesToHalf() {
        let state = CycleState(lastDirection: .left, lastZone: DefaultLayouts.leftTwoThirds, lastTimestamp: t0)
        let (action, _) = engine.process(CycleInput(
            direction: .left,
            currentZoneID: "left-two-thirds",
            now: t0.addingTimeInterval(0.5),
            hasNeighbour: false,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.leftHalf, on: .current))
    }

    @Test
    func thirdPress_advancesToThird() {
        let state = CycleState(lastDirection: .left, lastZone: DefaultLayouts.leftHalf, lastTimestamp: t0)
        let (action, _) = engine.process(CycleInput(
            direction: .left,
            currentZoneID: "left-half",
            now: t0.addingTimeInterval(0.5),
            hasNeighbour: false,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.leftThird, on: .current))
    }

    // MARK: - Cross-monitor

    @Test
    func fourthPress_withNeighbour_jumpsToOppositeZoneOnNeighbour() {
        let state = CycleState(lastDirection: .left, lastZone: DefaultLayouts.leftThird, lastTimestamp: t0)
        let (action, _) = engine.process(CycleInput(
            direction: .left,
            currentZoneID: "left-third",
            now: t0.addingTimeInterval(0.5),
            hasNeighbour: true,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.rightHalf, on: .neighbour))
    }

    @Test
    func fourthPress_withoutNeighbour_isNoOp() {
        let state = CycleState(lastDirection: .left, lastZone: DefaultLayouts.leftThird, lastTimestamp: t0)
        let (action, newState) = engine.process(CycleInput(
            direction: .left,
            currentZoneID: "left-third",
            now: t0.addingTimeInterval(0.5),
            hasNeighbour: false,
            state: state
        ))
        #expect(action == .noOp)
        #expect(newState.lastDirection == .left)
        #expect(newState.lastZone == DefaultLayouts.leftThird)
    }

    // MARK: - Combo

    @Test
    func leftThenUp_within1s_appliesIntersectionAsTopLeftQuadrant() {
        let state = CycleState(lastDirection: .left, lastZone: DefaultLayouts.leftHalf, lastTimestamp: t0)
        let (action, newState) = engine.process(CycleInput(
            direction: .up,
            currentZoneID: "left-half",
            now: t0.addingTimeInterval(1.0),
            hasNeighbour: false,
            state: state
        ))
        guard case let .apply(zone, target) = action else {
            Issue.record("Expected .apply, got \(action)")
            return
        }
        #expect(target == .current)
        #expect(zone.rect == CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
        #expect(newState.lastDirection == nil)
        #expect(newState.lastZone == zone)
    }

    @Test
    func leftThenUp_after2s_isNotComboButReset() {
        let state = CycleState(lastDirection: .left, lastZone: DefaultLayouts.leftHalf, lastTimestamp: t0)
        let (action, _) = engine.process(CycleInput(
            direction: .up,
            currentZoneID: "left-half",
            now: t0.addingTimeInterval(2.0),
            hasNeighbour: false,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.topTwoThirds, on: .current))
    }

    @Test
    func sameAxisOppositePress_isReverseCycleNotCombo() {
        // Same axis (horizontal) is never a combo regardless of timing. Behaviour falls
        // through to the reverse-cycle branch: window in left-half, lastDir=.left,
        // pressing right steps back through left's sequence to leftTwoThirds.
        let state = CycleState(lastDirection: .left, lastZone: DefaultLayouts.leftHalf, lastTimestamp: t0)
        let (action, _) = engine.process(CycleInput(
            direction: .right,
            currentZoneID: "left-half",
            now: t0.addingTimeInterval(0.5),
            hasNeighbour: false,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.leftTwoThirds, on: .current))
    }

    // MARK: - Reverse cycle

    @Test
    func oppositePress_undoesLastStep() {
        // After cycling right twice, window is in right-half (rightTwoThirds → rightHalf).
        // Pressing left should return to rightTwoThirds, not jump to a left zone.
        let state = CycleState(lastDirection: .right, lastZone: DefaultLayouts.rightHalf, lastTimestamp: t0)
        let (action, newState) = engine.process(CycleInput(
            direction: .left,
            currentZoneID: "right-half",
            now: t0.addingTimeInterval(0.3),
            hasNeighbour: false,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.rightTwoThirds, on: .current))
        // lastDirection stays as .right so successive ← presses keep stepping back.
        #expect(newState.lastDirection == .right)
    }

    @Test
    func oppositePress_atFirstZoneOfLastSequence_fallsThrough() {
        // Window already at rightTwoThirds (idx 0 of right-sequence). Pressing left has
        // nothing to undo → falls through to default (leftTwoThirds).
        let state = CycleState(lastDirection: .right, lastZone: DefaultLayouts.rightTwoThirds, lastTimestamp: t0)
        let (action, _) = engine.process(CycleInput(
            direction: .left,
            currentZoneID: "right-two-thirds",
            now: t0.addingTimeInterval(0.3),
            hasNeighbour: false,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.leftTwoThirds, on: .current))
    }

    // MARK: - Jump-back

    @Test
    func jumpBack_oppositeOfLastJump_returnsToOriginalMonitor() {
        // After a leftward cross-monitor jump landed on rightHalf of the neighbour monitor,
        // pressing right within the reset window should jump back to the original (left) monitor.
        let state = CycleState(
            lastDirection: .left,
            lastZone: DefaultLayouts.rightHalf,
            lastTimestamp: t0,
            lastJumpDirection: .left
        )
        let (action, newState) = engine.process(CycleInput(
            direction: .right,
            currentZoneID: "right-half",
            now: t0.addingTimeInterval(0.3),
            hasNeighbour: true,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.leftHalf, on: .neighbour))
        #expect(newState.lastJumpDirection == .right)
    }

    @Test
    func jumpBack_afterResetDelay_doesNotFire() {
        // Same setup but past the reset delay → branch 2 doesn't fire.
        // Falls through to reverse-cycle (right-half is in right-sequence at idx 1; lastDir=.left,
        // input=.right → opposite, lastDirSequence(.left) doesn't contain "right-half" → no).
        // Falls to cycle continuation: right-half in right-seq at idx 1 → next = rightThird.
        let state = CycleState(
            lastDirection: .left,
            lastZone: DefaultLayouts.rightHalf,
            lastTimestamp: t0,
            lastJumpDirection: .left
        )
        let (action, _) = engine.process(CycleInput(
            direction: .right,
            currentZoneID: "right-half",
            now: t0.addingTimeInterval(3.0),
            hasNeighbour: true,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.rightThird, on: .current))
    }

    @Test
    func crossMonitorJump_setsLastJumpDirection() {
        // Window in left-third (tail of left-sequence), pressing left with neighbour → jump.
        // Verifies that the regular cross-monitor branch records lastJumpDirection so
        // the immediate opposite-press triggers jump-back rather than continuation.
        let state = CycleState(lastDirection: .left, lastZone: DefaultLayouts.leftThird, lastTimestamp: t0)
        let (_, newState) = engine.process(CycleInput(
            direction: .left,
            currentZoneID: "left-third",
            now: t0.addingTimeInterval(0.3),
            hasNeighbour: true,
            state: state
        ))
        #expect(newState.lastJumpDirection == .left)
    }

    // MARK: - Long pause continuation (no aggressive reset)

    @Test
    func pauseExceedsResetDelay_continuesCycleFromCurrentPosition() {
        // After a 3s pause, pressing left while window is in left-half should advance
        // to left-third — NOT restart at left-two-thirds. The window's current zone is
        // the source of truth, not a stale lastZone.
        let state = CycleState(lastDirection: .left, lastZone: DefaultLayouts.leftHalf, lastTimestamp: t0)
        let (action, _) = engine.process(CycleInput(
            direction: .left,
            currentZoneID: "left-half",
            now: t0.addingTimeInterval(3.0),
            hasNeighbour: false,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.leftThird, on: .current))
    }

    @Test
    func windowNotInAnyZone_appliesFirstOfSequence() {
        let (action, _) = engine.process(CycleInput(
            direction: .right,
            currentZoneID: nil,
            now: t0,
            hasNeighbour: false,
            state: .initial
        ))
        #expect(action == .apply(DefaultLayouts.rightTwoThirds, on: .current))
    }

    // MARK: - Combo gating

    @Test
    func combo_disabledByConfig_fallsThroughInsteadOfQuadrant() {
        // With comboEnabled=false, an axis-cross press behaves as a fresh first-press
        // in the new direction's sequence — it does NOT produce a quarter intersection.
        let engine = CycleEngine(comboEnabled: false)
        let state = CycleState(lastDirection: .left, lastZone: DefaultLayouts.leftHalf, lastTimestamp: t0)
        let (action, _) = engine.process(CycleInput(
            direction: .up,
            currentZoneID: "left-half",
            now: t0.addingTimeInterval(0.5),
            hasNeighbour: false,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.topTwoThirds, on: .current))
    }

    // MARK: - Empty configuration

    @Test
    func emptyDirectionSequence_isNoOp() {
        // If user disables every group on this axis, the sequence is empty —
        // engine returns noOp instead of crashing on first-zone access.
        let engine = CycleEngine(sequence: { _ in [] })
        let (action, newState) = engine.process(CycleInput(
            direction: .left,
            currentZoneID: nil,
            now: t0,
            hasNeighbour: false,
            state: .initial
        ))
        #expect(action == .noOp)
        #expect(newState == .initial)
    }

    @Test
    func allFourDirections_haveSymmetricFirstZones() {
        for (dir, expected): (Direction, Zone) in [
            (.left, DefaultLayouts.leftTwoThirds),
            (.right, DefaultLayouts.rightTwoThirds),
            (.up, DefaultLayouts.topTwoThirds),
            (.down, DefaultLayouts.bottomTwoThirds)
        ] {
            let (action, _) = engine.process(CycleInput(
                direction: dir,
                currentZoneID: nil,
                now: t0,
                hasNeighbour: false,
                state: .initial
            ))
            #expect(action == .apply(expected, on: .current), "Direction \(dir) should land on \(expected.id)")
        }
    }
}
