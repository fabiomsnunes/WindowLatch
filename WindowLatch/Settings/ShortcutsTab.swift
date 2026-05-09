import SwiftUI

struct ShortcutsTab: View {
    var body: some View {
        ContentUnavailableView(
            "Shortcuts",
            systemImage: "command",
            description: Text("Customise the cycle shortcuts here.")
        )
    }
}
