import AppKit
import Carbon.HIToolbox

enum SystemKeyboard {
    // System Settings → Keyboard → "Press 🌐 key to"
    enum GlobeKeyAction: Int {
        case doNothing = 0
        case changeInputSource = 1
        case showEmoji = 2
        case startDictation = 3
    }

    // nil when the setting was never changed; macOS then picks a default that is not "Do Nothing"
    static var globeKeyAction: GlobeKeyAction? {
        guard let value = UserDefaults.standard.persistentDomain(forName: "com.apple.HIToolbox")?["AppleFnUsageType"] as? Int else { return nil }
        return GlobeKeyAction(rawValue: value)
    }

    // the fn key is free for us only when macOS does nothing with it
    static var globeKeyIsFree: Bool {
        globeKeyAction == .doNothing
    }

    // password fields and some terminals: keystrokes don't reach other apps, including us
    static var secureInputApp: String? {
        guard IsSecureEventInputEnabled() else { return nil }
        let session = CGSessionCopyCurrentDictionary() as? [String: Any]
        guard let pid = session?["kCGSSessionSecureInputPID"] as? Int32,
              let app = NSRunningApplication(processIdentifier: pid) else { return "" }
        return app.localizedName ?? ""
    }

    @MainActor
    static func openKeyboardSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
