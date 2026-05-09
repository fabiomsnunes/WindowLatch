import AppKit

/// The modifier combination that, paired with the four arrow keys, triggers
/// the cycle shortcuts. Exposed in Settings; the arrow keys themselves are fixed.
nonisolated enum ShortcutModifier: String, CaseIterable, Codable, Identifiable, Sendable {
    case ctrlOption
    case ctrlCommand
    case commandOption
    case ctrlCommandShift

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ctrlOption:       return "⌃⌥  Control + Option"
        case .ctrlCommand:      return "⌃⌘  Control + Command"
        case .commandOption:    return "⌘⌥  Command + Option"
        case .ctrlCommandShift: return "⌃⌘⇧ Control + Command + Shift"
        }
    }

    @MainActor
    var nsFlags: NSEvent.ModifierFlags {
        switch self {
        case .ctrlOption:       return [.control, .option]
        case .ctrlCommand:      return [.control, .command]
        case .commandOption:    return [.command, .option]
        case .ctrlCommandShift: return [.control, .command, .shift]
        }
    }

    static let `default`: ShortcutModifier = .ctrlOption
}
