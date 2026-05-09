import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsStore
    @Bindable var zones: ZoneStore
    @Bindable var screens: ScreenManager

    init(settings: SettingsStore, zones: ZoneStore, screens: ScreenManager) {
        self.settings = settings
        self.zones = zones
        self.screens = screens
    }

    var body: some View {
        Form {
            generalSection
            zonesSection
            aboutSection
        }
        .formStyle(.grouped)
        .frame(width: 540, height: 620)
    }

    // MARK: - General

    private var generalSection: some View {
        Section("General") {
            Picker(selection: $settings.modifier) {
                ForEach(ShortcutModifier.allCases) { mod in
                    Text(mod.label).tag(mod)
                }
            } label: {
                Text("Shortcut modifier")
                Text("Combined with the arrow keys.")
            }
            .pickerStyle(.menu)

            Stepper(
                value: gapBinding,
                in: 0...32,
                step: 4
            ) {
                LabeledContent("Window gap") {
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

            Button("Restore defaults") {
                settings.restoreDefaults()
            }
        }
    }

    private var gapBinding: Binding<Double> {
        Binding(
            get: { Double(settings.gap) },
            set: { settings.gap = CGFloat($0) }
        )
    }

    // MARK: - Zones per monitor

    private var zonesSection: some View {
        Section {
            if screens.screens.isEmpty {
                Text("No monitors detected.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(screens.screens) { screen in
                    monitorBlock(screen)
                }
            }
        } header: {
            Text("Zones per monitor")
        } footer: {
            Text("Enable the zone groups you want to cycle through on each monitor. Quarters are only reachable via a cross-axis combo (e.g. Left then Up).")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func monitorBlock(_ screen: ScreenInfo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "display")
                    .foregroundStyle(.secondary)
                Text(screen.name)
                    .font(.callout.weight(.medium))
                Text("\(Int(screen.frame.width)) × \(Int(screen.frame.height))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 2)

            ForEach(ZoneGroup.allCases) { group in
                Toggle(isOn: groupBinding(group, displayID: screen.id)) {
                    Label(group.label, systemImage: group.systemImage)
                }
                .toggleStyle(.checkbox)
            }
        }
        .padding(.vertical, 4)
    }

    private func groupBinding(_ group: ZoneGroup, displayID: CGDirectDisplayID) -> Binding<Bool> {
        Binding(
            get: { zones.enabledGroups(for: displayID).contains(group) },
            set: { zones.setGroup(group, enabled: $0, for: displayID) }
        )
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "rectangle.split.2x2")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.tint)
                    .frame(width: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text("WindowLatch")
                        .font(.headline)
                    Text("Version \(Self.appVersion)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("by Fábio Nunes")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Link("GitHub", destination: URL(string: "https://github.com/fabiomsnunes/WindowLatch")!)
                        Link("Report an issue", destination: URL(string: "https://github.com/fabiomsnunes/WindowLatch/issues")!)
                    }
                    .font(.callout)
                    .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }

    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }
}
