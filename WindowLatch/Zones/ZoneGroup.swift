/// A toggleable group of zones the user can enable per monitor.
///
/// Horizontal groups feed the left/right cycle sequence; vertical groups feed the
/// up/down sequence. `quarters` only governs whether the cross-axis combo gesture
/// (e.g. Left then Up) produces a quadrant snap.
nonisolated enum ZoneGroup: String, CaseIterable, Codable, Identifiable {
    case halvesHorizontal
    case thirdsHorizontal
    case halvesVertical
    case thirdsVertical
    case quarters

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .halvesHorizontal: "Halves — left / right"
        case .thirdsHorizontal: "Thirds — left / right"
        case .halvesVertical: "Halves — top / bottom"
        case .thirdsVertical: "Thirds — top / bottom"
        case .quarters: "Quarters (via direction combo)"
        }
    }

    var systemImage: String {
        switch self {
        case .halvesHorizontal: "rectangle.split.2x1"
        case .thirdsHorizontal: "rectangle.split.3x1"
        case .halvesVertical: "rectangle.split.1x2"
        case .thirdsVertical: "square.split.1x2"
        case .quarters: "rectangle.split.2x2"
        }
    }

    /// All groups enabled — the default for any monitor with no saved selection.
    static let defaults: Set<ZoneGroup> = Set(ZoneGroup.allCases)

    /// Build the cycle sequence for `direction` from the enabled groups.
    /// Order is largest → smallest: thirds-2/3 → halves-1/2 → thirds-1/3.
    static func sequence(for direction: Direction, enabled: Set<ZoneGroup>) -> [Zone] {
        let halvesGroup: ZoneGroup = (direction.axis == .horizontal) ? .halvesHorizontal : .halvesVertical
        let thirdsGroup: ZoneGroup = (direction.axis == .horizontal) ? .thirdsHorizontal : .thirdsVertical
        let hasHalves = enabled.contains(halvesGroup)
        let hasThirds = enabled.contains(thirdsGroup)

        let twoThirds: Zone, half: Zone, third: Zone
        switch direction {
        case .left:
            twoThirds = DefaultLayouts.leftTwoThirds; half = DefaultLayouts.leftHalf; third = DefaultLayouts.leftThird
        case .right:
            twoThirds = DefaultLayouts.rightTwoThirds; half = DefaultLayouts.rightHalf; third = DefaultLayouts
                .rightThird
        case .up:
            twoThirds = DefaultLayouts.topTwoThirds; half = DefaultLayouts.topHalf; third = DefaultLayouts.topThird
        case .down:
            twoThirds = DefaultLayouts.bottomTwoThirds; half = DefaultLayouts.bottomHalf; third = DefaultLayouts
                .bottomThird
        }

        var seq: [Zone] = []
        if hasThirds { seq.append(twoThirds) }
        if hasHalves { seq.append(half) }
        if hasThirds { seq.append(third) }
        return seq
    }
}
