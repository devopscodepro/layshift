import SwiftUI

struct ShortcutsSettingsView: View {
    @ObservedObject var sources: InputSourceStore
    @ObservedObject var settings: SettingsStore
    @ObservedObject var shortcuts: ShortcutController

    var body: some View {
        Form {
            Section {
                ForEach(sources.sources) { source in
                    LabeledContent {
                        ShortcutRecorder(settings: settings, shortcut: settings.layoutShortcuts[source.id]) { shortcut in
                            settings.setShortcut(shortcut, forSource: source.id)
                            requestPermissionsIfNeeded(for: shortcut, source: source)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if let icon = sources.icon(for: source) {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                            Text(source.name)
                        }
                    }
                }
            } header: {
                Text("Switch to a layout")
            } footer: {
                Text("A shortcut can be keys like ⌥1, or modifiers pressed and released on their own, like ⌃⇧ or the right ⌘. Layouts come from System Settings → Keyboard → Input Sources.")
            }

            Section {
                LabeledContent("Next layout") {
                    ShortcutRecorder(settings: settings, shortcut: settings.cycleShortcut) { shortcut in
                        settings.setCycleShortcut(shortcut)
                        requestPermissionsIfNeeded(for: shortcut, source: nil)
                    }
                }
            } header: {
                Text("Cycle")
            } footer: {
                Text("Goes through the layouts in the order above.")
            }

            if shortcuts.tapUnavailable {
                PermissionNotice(
                    text: String(localized: "Modifier-only shortcuts need the Input Monitoring permission."),
                    button: String(localized: "Open System Settings"),
                    action: Permissions.openInputMonitoringSettings
                )
            }
            if sources.nudgeFailed {
                PermissionNotice(
                    text: String(localized: "Switching to an input method needs the Accessibility permission and the system shortcut “Select the previous input source”."),
                    button: String(localized: "Open System Settings"),
                    action: Permissions.openAccessibilitySettings
                )
            }
            if !shortcuts.rejectedKeyCombos.isEmpty {
                Section {
                    Text("macOS didn't accept \(shortcuts.rejectedKeyCombos.map(\.displayString).sorted().joined(separator: ", ")). Pick a different shortcut.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { sources.refresh() }
    }

    // ask at the moment the user needs it, not at launch
    private func requestPermissionsIfNeeded(for shortcut: Shortcut?, source: InputSource?) {
        guard let shortcut else { return }
        if case .modifiers = shortcut, !Permissions.hasInputMonitoring {
            Permissions.requestInputMonitoring()
        }
        let involvesInputMethod = source?.kind == .inputMode || (source == nil && sources.hasInputMethods)
        if involvesInputMethod, !Permissions.hasAccessibility {
            Permissions.requestAccessibility()
        }
    }
}

struct PermissionNotice: View {
    let text: String
    let button: String
    let action: @MainActor () -> Void

    var body: some View {
        Section {
            HStack(alignment: .firstTextBaseline) {
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button(button, action: action)
                    .controlSize(.small)
            }
        }
    }
}
