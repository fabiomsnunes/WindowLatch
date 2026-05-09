import SwiftUI

struct ZonesTab: View {
    var body: some View {
        ContentUnavailableView(
            "Zones",
            systemImage: "rectangle.split.2x2",
            description: Text("Pick a zone preset for each monitor.")
        )
    }
}
