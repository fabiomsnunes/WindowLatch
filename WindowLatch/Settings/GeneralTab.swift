import SwiftUI

struct GeneralTab: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Form {
            Section {
                Stepper(
                    value: gapBinding,
                    in: 0...32,
                    step: 2
                ) {
                    LabeledContent("Gap between windows") {
                        Text("\(Int(settings.gap)) px")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(
                    value: $settings.cycleResetDelay,
                    in: 0.5...5.0,
                    step: 0.5
                ) {
                    LabeledContent("Cycle reset delay") {
                        Text(String(format: "%.1f s", settings.cycleResetDelay))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("Reset delay also bounds the window for jump-back and reverse-cycle gestures.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Restore defaults") {
                    settings.restoreDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
    }

    private var gapBinding: Binding<Double> {
        Binding(
            get: { Double(settings.gap) },
            set: { settings.gap = CGFloat($0) }
        )
    }
}
