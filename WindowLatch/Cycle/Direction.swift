nonisolated enum Axis: Hashable {
    case horizontal, vertical
}

nonisolated enum Direction: String, Hashable, CaseIterable {
    case left, right, up, down

    var axis: Axis {
        switch self {
        case .left, .right: .horizontal
        case .up, .down: .vertical
        }
    }

    var opposite: Direction {
        switch self {
        case .left: .right
        case .right: .left
        case .up: .down
        case .down: .up
        }
    }
}
