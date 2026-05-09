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
    func sameAxisPress_doesNotTriggerCombo() {
        let state = CycleState(lastDirection: .left, lastZone: DefaultLayouts.leftHalf, lastTimestamp: t0)
        let (action, _) = engine.process(CycleInput(
            direction: .right,
            currentZoneID: "left-half",
            now: t0.addingTimeInterval(0.5),
            hasNeighbour: false,
            state: state
        ))
        #expect(action == .apply(DefaultLayouts.rightTwoThirds, on: .current))
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

    @Test
    func allFourDirections_haveSymmetricFirstZones() {
        for (dir, expected): (Direction, Zone) in [
            (.left,  DefaultLayouts.leftTwoThirds),
            (.right, DefaultLayouts.rightTwoThirds),
            (.up,    DefaultLayouts.topTwoThirds),
            (.down,  DefaultLayouts.bottomTwoThirds),
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
