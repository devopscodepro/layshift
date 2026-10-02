import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var settings: SettingsStore

    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var needsApproval = LaunchAtLogin.needsApproval

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { launchAtLogin },
                    set: {
                        LaunchAtLogin.setEnabled($0)
                        refresh()
                    }
                ))
                if needsApproval {
                    Text("Allow LayShift in System Settings → General → Login Items.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Toggle(isOn: $settings.showsMenuBarIcon) {
                    Text("Show LayShift in the menu bar")
                    Text("Without the icon, open LayShift again to get back to Settings.")
                }
            }

            Section {
                HStack(spacing: 10) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LayShift")
                            .fontWeight(.semibold)
                        Text("Version \(Self.version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Quit LayShift") {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            refresh()
        }
    }

    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private func refresh() {
        launchAtLogin = LaunchAtLogin.isEnabled
        needsApproval = LaunchAtLogin.needsApproval
    }
}
