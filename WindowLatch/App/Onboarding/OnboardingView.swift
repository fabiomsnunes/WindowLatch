import SwiftUI

struct OnboardingView: View {
    @Bindable var permissions: PermissionsManager
    let onQuit: () -> Void

    private static let accessibilityPaneURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to WindowLatch")
                    .font(.title)
                    .fontWeight(.semibold)
                Text(
                    "WindowLatch needs Accessibility access to move and resize your windows. "
                        + "macOS requires this for any tool that controls other apps' windows."
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            statusRow

            Text(
                "If the status doesn't update within a few seconds after granting permission, "
                    + "quit and reopen WindowLatch."
            )
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Button("Quit", role: .destructive) { onQuit() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(action: openSystemSettings) {
                    Text("Open System Settings")
                }
                Button(action: requestAccess) {
                    Text("Grant Access…")
                        .frame(minWidth: 140)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .frame(width: 480)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Image(systemName: permissions.isTrusted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(permissions.isTrusted ? .green : .red)
                .font(.title3)
            Text(permissions.isTrusted ? "Accessibility granted" : "Accessibility not granted")
                .font(.callout)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func openSystemSettings() {
        NSWorkspace.shared.open(Self.accessibilityPaneURL)
    }

    private func requestAccess() {
        permissions.requestAccessWithPrompt()
    }
}
