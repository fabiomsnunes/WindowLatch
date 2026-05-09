import SwiftUI

@main
struct WindowLatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Required to satisfy the App scene contract; the real Settings window is
        // opened by AppDelegate via NSWindowController (more reliable for .accessory apps).
        Settings { EmptyView() }
    }
}
