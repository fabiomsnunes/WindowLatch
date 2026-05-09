import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let cycleLeft = Self("cycleLeft", default: .init(.leftArrow, modifiers: [.control, .option]))
    static let cycleRight = Self("cycleRight", default: .init(.rightArrow, modifiers: [.control, .option]))
    static let cycleUp = Self("cycleUp", default: .init(.upArrow, modifiers: [.control, .option]))
    static let cycleDown = Self("cycleDown", default: .init(.downArrow, modifiers: [.control, .option]))
}
