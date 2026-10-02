import Combine
import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var sources: InputSourceStore
    @ObservedObject var shortcuts: ShortcutController

    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var needsApproval = LaunchAtLogin.needsApproval
    @State private var inputMonitoring = Permissions.hasInputMonitoring
    @State private var accessibility = Permissions.hasAccessibility

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
                PermissionRow(
                    name: String(localized: "Input Monitoring"),
                    detail: String(localized: "For shortcuts made of modifiers only, like ⌃⇧."),
                    granted: inputMonitoring,
                    needed: settings.usesModifierShortcuts,
                    request: Permissions.requestInputMonitoring,
                    open: Permissions.openInputMonitoringSettings
                )
                PermissionRow(
                    name: String(localized: "Accessibility"),
                    detail: String(localized: "For switching to input methods like Pinyin or Hiragana."),
                    granted: accessibility,
                    needed: sources.hasInputMethods,
                    request: Permissions.requestAccessibility,
                    open: Permissions.openAccessibilitySettings
                )
            } header: {
                Text("Permissions")
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
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            refresh()
        }
        .onReceive(timer) { _ in
            refreshPermissions()
        }
    }

    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private func refresh() {
        launchAtLogin = LaunchAtLogin.isEnabled
        needsApproval = LaunchAtLogin.needsApproval
        refreshPermissions()
    }

    // the system doesn't tell us when a permission is granted, so look while the window is open
    private func refreshPermissions() {
        let monitoring = Permissions.hasInputMonitoring
        if monitoring != inputMonitoring {
            inputMonitoring = monitoring
            if monitoring { shortcuts.rebind() }
        }
        accessibility = Permissions.hasAccessibility
    }
}

private struct PermissionRow: View {
    let name: String
    let detail: String
    let granted: Bool
    let needed: Bool
    let request: () -> Void
    let open: @MainActor () -> Void

    var body: some View {
        LabeledContent {
            if granted {
                Label(String(localized: "Granted"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .labelStyle(.titleAndIcon)
            } else if needed {
                Button(String(localized: "Grant…")) {
                    request()
                    open()
                }
                .controlSize(.small)
            } else {
                Text("Not needed")
                    .foregroundStyle(.secondary)
            }
        } label: {
            Text(name)
            Text(detail)
        }
    }
}
