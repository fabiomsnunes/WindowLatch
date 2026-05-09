import AppKit

/// The modifier combination that, paired with the four arrow keys, triggers
/// the cycle shortcuts. Exposed in Settings; the arrow keys themselves are fixed.
nonisolated enum ShortcutModifier: String, CaseIterable, Codable, Identifiable {
    case ctrlOption
    case ctrlCommand
    case commandOption
    case ctrlCommandShift

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .ctrlOption: "⌃⌥  Control + Option"
        case .ctrlCommand: "⌃⌘  Control + Command"
        case .commandOption: "⌘⌥  Command + Option"
        case .ctrlCommandShift: "⌃⌘⇧ Control + Command + Shift"
        }
    }

    @MainActor
    var nsFlags: NSEvent.ModifierFlags {
        switch self {
        case .ctrlOption: [.control, .option]
        case .ctrlCommand: [.control, .command]
        case .commandOption: [.command, .option]
        case .ctrlCommandShift: [.control, .command, .shift]
        }
    }

    static let `default`: ShortcutModifier = .ctrlOption
}
