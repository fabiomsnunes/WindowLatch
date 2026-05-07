import SwiftUI

@main
struct WindowLatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Settings scene is declared (required for a valid SwiftUI App), but never
        // triggered: the actual settings window is opened via a manual NSWindowController
        // from AppDelegate, which is more reliable for LSUIElement / .accessory apps.
        Settings { EmptyView() }
    }
}
