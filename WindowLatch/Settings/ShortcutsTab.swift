import KeyboardShortcuts
import SwiftUI

struct ShortcutsTab: View {
    var body: some View {
        Form {
            Section {
                row("Cycle left",  name: .cycleLeft)
                row("Cycle right", name: .cycleRight)
                row("Cycle up",    name: .cycleUp)
                row("Cycle down",  name: .cycleDown)
            } footer: {
                Text("Click a shortcut to record a new combination, or use the × button to clear it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Restore defaults") {
                    KeyboardShortcuts.reset(.cycleLeft, .cycleRight, .cycleUp, .cycleDown)
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
    }

    private func row(_ label: String, name: KeyboardShortcuts.Name) -> some View {
        LabeledContent(label) {
            KeyboardShortcuts.Recorder(for: name)
        }
    }
}
