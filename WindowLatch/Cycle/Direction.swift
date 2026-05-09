nonisolated enum Axis: Sendable, Hashable {
    case horizontal, vertical
}

nonisolated enum Direction: String, Sendable, Hashable, CaseIterable {
    case left, right, up, down

    var axis: Axis {
        switch self {
        case .left, .right: return .horizontal
        case .up, .down:    return .vertical
        }
    }

    var opposite: Direction {
        switch self {
        case .left:  return .right
        case .right: return .left
        case .up:    return .down
        case .down:  return .up
        }
    }
}
