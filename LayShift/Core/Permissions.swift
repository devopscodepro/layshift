import AppKit
import ApplicationServices

enum Permissions {
    // the event tap for modifier-only shortcuts
    static var hasInputMonitoring: Bool {
        CGPreflightListenEventAccess()
    }

    // posting the system shortcut that makes input methods take effect
    static var hasAccessibility: Bool {
        AXIsProcessTrusted()
    }

    static func requestInputMonitoring() {
        if !CGRequestListenEventAccess() {
            Log.shortcuts.info("Input Monitoring not granted yet")
        }
    }

    static func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options) {
            Log.shortcuts.info("Accessibility not granted yet")
        }
    }

    @MainActor
    static func openInputMonitoringSettings() {
        open("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent")
    }

    @MainActor
    static func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")
    }

    @MainActor
    private static func open(_ string: String) {
        if let url = URL(string: string) {
            NSWorkspace.shared.open(url)
        }
    }
}
