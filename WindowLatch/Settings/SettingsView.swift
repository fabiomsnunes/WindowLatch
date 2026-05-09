import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        TabView {
            GeneralTab(settings: settings)
                .tabItem { Label("General", systemImage: "gearshape") }

            ShortcutsTab()
                .tabItem { Label("Shortcuts", systemImage: "command") }

            ZonesTab()
                .tabItem { Label("Zones", systemImage: "rectangle.split.2x2") }
        }
        .frame(width: 520, height: 380)
    }
}
