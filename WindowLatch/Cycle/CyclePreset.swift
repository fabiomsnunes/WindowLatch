/// A named cycle sequence. Each preset defines the per-direction zone progression
/// the cycle engine walks through. Selected per-monitor in the Settings UI.
nonisolated enum CyclePreset: String, CaseIterable, Codable, Identifiable, Sendable {
    /// 2/3 → 1/2 → 1/3 in the chosen direction. Default.
    case standard
    /// 1/2 only — single press snaps a half, second press jumps to the neighbour monitor.
    case halves

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: return "Standard (2/3 → 1/2 → 1/3)"
        case .halves:   return "Halves only"
        }
    }

    func sequence(for direction: Direction) -> [Zone] {
        switch self {
        case .standard:
            return CycleDefinition.sequence(for: direction)
        case .halves:
            switch direction {
            case .left:  return [DefaultLayouts.leftHalf]
            case .right: return [DefaultLayouts.rightHalf]
            case .up:    return [DefaultLayouts.topHalf]
            case .down:  return [DefaultLayouts.bottomHalf]
            }
        }
    }

    static let `default`: CyclePreset = .standard
}
