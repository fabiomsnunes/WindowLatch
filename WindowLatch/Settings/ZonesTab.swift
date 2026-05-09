import SwiftUI

struct ZonesTab: View {
    @Bindable var screens = ScreenManager.shared
    @Bindable var zones = ZoneStore.shared

    var body: some View {
        Form {
            Section {
                if screens.screens.isEmpty {
                    Text("No monitors detected.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(screens.screens) { screen in
                        row(for: screen)
                    }
                }
            } footer: {
                Text("Each monitor can use a different cycle preset. Selections persist to ~/Library/Application Support/WindowLatch/zones.json.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
    }

    private func row(for screen: ScreenInfo) -> some View {
        let preset = Binding(
            get: { zones.preset(for: screen.id) },
            set: { zones.setPreset($0, for: screen.id) }
        )
        return Picker(selection: preset) {
            ForEach(CyclePreset.allCases) { preset in
                Text(preset.label).tag(preset)
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(screen.name)
                Text("\(Int(screen.frame.width)) × \(Int(screen.frame.height))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .pickerStyle(.menu)
    }
}
