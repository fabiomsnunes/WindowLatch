import CoreGraphics
import Foundation

// MARK: - Engine I/O types

struct CycleState: Equatable {
    var lastDirection: Direction?
    var lastZone: Zone?
    var lastTimestamp: Date?
    /// Set when the last action was a cross-monitor jump; consumed by the jump-back branch
    /// when the user immediately presses the opposite direction.
    var lastJumpDirection: Direction?

    static let initial = CycleState(
        lastDirection: nil,
        lastZone: nil,
        lastTimestamp: nil,
        lastJumpDirection: nil
    )
}

struct CycleInput: Equatable {
    let direction: Direction
    /// ID of the zone the focused window currently matches, or nil if it doesn't match any.
    let currentZoneID: String?
    let now: Date
    /// Whether a screen exists in `direction` from the current screen.
    let hasNeighbour: Bool
    let state: CycleState
}

enum TargetScreen: Equatable {
    case current
    case neighbour
}

enum CycleAction: Equatable {
    case noOp
    case apply(Zone, on: TargetScreen)
}

// MARK: - Engine

/// Pure state machine for cycle behaviour. **Has no AX / NSScreen / Date.now dependency.**
///
/// State machine summary (Δt = now − state.lastTimestamp):
///
///     1. axis crosses && Δt ≤ comboTimeout                          → apply combo intersection on current
///     2. opposite of lastJumpDirection && Δt ≤ resetDelay           → cross-monitor jump back to original
///     3. opposite of lastDirection && current in lastDir's sequence → step BACK in lastDir's sequence
///     4. currentZoneID is in sequence                               → next zone (or cross-monitor on tail)
///     5. otherwise                                                  → apply first zone of sequence
///
/// The window's current zone is always the source of truth — a long pause does NOT
/// restart the cycle at the largest zone, because that would diverge from what the
/// user sees on screen.
nonisolated struct CycleEngine {
    let comboTimeout: TimeInterval
    let resetDelay: TimeInterval
    let comboEnabled: Bool
    let sequence: @Sendable (Direction) -> [Zone]
    let crossMonitorEntry: @Sendable (Direction) -> Zone

    init(
        comboTimeout: TimeInterval = 1.5,
        resetDelay: TimeInterval = 1.5,
        comboEnabled: Bool = true,
        sequence: @escaping @Sendable (Direction) -> [Zone] = CycleDefinition.sequence(for:),
        crossMonitorEntry: @escaping @Sendable (Direction) -> Zone = CycleDefinition.crossMonitorEntry(for:)
    ) {
        self.comboTimeout = comboTimeout
        self.resetDelay = resetDelay
        self.comboEnabled = comboEnabled
        self.sequence = sequence
        self.crossMonitorEntry = crossMonitorEntry
    }

    func process(_ input: CycleInput) -> (action: CycleAction, newState: CycleState) {
        let dt: TimeInterval = input.state.lastTimestamp.map { input.now.timeIntervalSince($0) } ?? .infinity
        let directionSequence = sequence(input.direction)

        // 1) Combo branch — axis crosses within combo window.
        if comboEnabled,
           let lastDir = input.state.lastDirection,
           let lastZone = input.state.lastZone,
           dt <= comboTimeout,
           lastDir.axis != input.direction.axis
        {
            let comboZone = makeComboZone(from: lastZone, direction: input.direction)
            let newState = CycleState(lastDirection: nil, lastZone: comboZone, lastTimestamp: input.now)
            return (.apply(comboZone, on: .current), newState)
        }

        // 2) Jump-back — user immediately presses the opposite of the last cross-monitor jump.
        //    Returns to the original monitor's mirror-zone (e.g. after a leftward jump that
        //    landed on rightHalf, pressing → jumps back to leftHalf on the previous screen).
        if let lastJump = input.state.lastJumpDirection,
           input.direction == lastJump.opposite,
           dt <= resetDelay,
           input.hasNeighbour
        {
            let entry = crossMonitorEntry(input.direction)
            let newState = CycleState(
                lastDirection: input.direction,
                lastZone: entry,
                lastTimestamp: input.now,
                lastJumpDirection: input.direction
            )
            return (.apply(entry, on: .neighbour), newState)
        }

        // 3) Reverse cycle — pressing the opposite of the last direction undoes the last step.
        //    Concretely: after → → (window now in right-half), pressing ← returns to
        //    rightTwoThirds rather than jumping to a left zone.
        if let lastDir = input.state.lastDirection,
           input.direction == lastDir.opposite,
           let curID = input.currentZoneID
        {
            let lastDirSequence = sequence(lastDir)
            if let idx = lastDirSequence.firstIndex(where: { $0.id == curID }), idx > 0 {
                let prev = lastDirSequence[idx - 1]
                // Keep lastDirection as lastDir so successive opposite presses keep stepping back.
                let newState = CycleState(lastDirection: lastDir, lastZone: prev, lastTimestamp: input.now)
                return (.apply(prev, on: .current), newState)
            }
        }

        // 4) Cycle continuation — current window matches a zone in this direction's sequence.
        if let curID = input.currentZoneID,
           let idx = directionSequence.firstIndex(where: { $0.id == curID })
        {
            if idx + 1 < directionSequence.count {
                let next = directionSequence[idx + 1]
                let newState = CycleState(lastDirection: input.direction, lastZone: next, lastTimestamp: input.now)
                return (.apply(next, on: .current), newState)
            } else {
                if input.hasNeighbour {
                    let entry = crossMonitorEntry(input.direction)
                    let newState = CycleState(
                        lastDirection: input.direction,
                        lastZone: entry,
                        lastTimestamp: input.now,
                        lastJumpDirection: input.direction
                    )
                    return (.apply(entry, on: .neighbour), newState)
                } else {
                    let newState = CycleState(
                        lastDirection: input.direction,
                        lastZone: input.state.lastZone,
                        lastTimestamp: input.now
                    )
                    return (.noOp, newState)
                }
            }
        }

        // 5) Default — start sequence. If the user disabled every group on this axis,
        // the sequence is empty and there's nothing to do.
        guard let first = directionSequence.first else {
            return (.noOp, input.state)
        }
        let newState = CycleState(lastDirection: input.direction, lastZone: first, lastTimestamp: input.now)
        return (.apply(first, on: .current), newState)
    }

    private func makeComboZone(from base: Zone, direction: Direction) -> Zone {
        let r = base.rect
        let newRect = switch direction {
        case .up:
            CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height / 2)
        case .down:
            CGRect(x: r.minX, y: r.minY + r.height / 2, width: r.width, height: r.height / 2)
        case .left:
            CGRect(x: r.minX, y: r.minY, width: r.width / 2, height: r.height)
        case .right:
            CGRect(x: r.minX + r.width / 2, y: r.minY, width: r.width / 2, height: r.height)
        }
        return Zone(
            id: "combo-\(base.id)-\(direction.rawValue)",
            label: "Combo \(base.label) + \(direction.rawValue)",
            rect: newRect
        )
    }
}
