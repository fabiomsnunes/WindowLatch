/// Per-direction cycle sequences (decreasing zone size: 2/3 → 1/2 → 1/3) and
/// the entry zone used when crossing into a neighbouring monitor.
nonisolated enum CycleDefinition {
    static func sequence(for direction: Direction) -> [Zone] {
        switch direction {
        case .left:
            return [DefaultLayouts.leftTwoThirds, DefaultLayouts.leftHalf, DefaultLayouts.leftThird]
        case .right:
            return [DefaultLayouts.rightTwoThirds, DefaultLayouts.rightHalf, DefaultLayouts.rightThird]
        case .up:
            return [DefaultLayouts.topTwoThirds, DefaultLayouts.topHalf, DefaultLayouts.topThird]
        case .down:
            return [DefaultLayouts.bottomTwoThirds, DefaultLayouts.bottomHalf, DefaultLayouts.bottomThird]
        }
    }

    /// The zone applied on the neighbouring screen when the cycle exhausts in `direction`.
    /// Coming from `.left` exhaustion lands on right-half of the screen to the left, etc.
    static func crossMonitorEntry(for direction: Direction) -> Zone {
        switch direction {
        case .left:  return DefaultLayouts.rightHalf
        case .right: return DefaultLayouts.leftHalf
        case .up:    return DefaultLayouts.bottomHalf
        case .down:  return DefaultLayouts.topHalf
        }
    }
}
