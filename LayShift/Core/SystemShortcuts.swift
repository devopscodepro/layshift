import AppKit

// the "Select the previous input source" and "Select next source in Input menu" shortcuts
// from System Settings → Keyboard → Keyboard Shortcuts → Input Sources
enum SystemShortcuts {
    static let previousInputSourceID = 60
    static let nextInputSourceID = 61

    static let defaultPrevious = KeyCombo(keyCode: 49, modifiers: .control)
    static let defaultNext = KeyCombo(keyCode: 49, modifiers: [.control, .option])

    static var previousInputSource: KeyCombo? {
        shortcut(id: previousInputSourceID, default: defaultPrevious)
    }

    static var nextInputSource: KeyCombo? {
        shortcut(id: nextInputSourceID, default: defaultNext)
    }

    static func isTaken(_ combo: KeyCombo) -> Bool {
        combo == previousInputSource || combo == nextInputSource
    }

    // nil when the user turned the shortcut off
    static func shortcut(id: Int, default fallback: KeyCombo) -> KeyCombo? {
        guard let all = UserDefaults.standard.persistentDomain(forName: "com.apple.symbolichotkeys")?["AppleSymbolicHotKeys"] as? [String: Any],
              let entry = all[String(id)] as? [String: Any] else { return fallback }
        return parse(entry) ?? fallback
    }

    static func parse(_ entry: [String: Any]) -> KeyCombo? {
        if let enabled = entry["enabled"] as? Bool, !enabled { return nil }
        if let enabled = entry["enabled"] as? Int, enabled == 0 { return nil }
        guard let value = entry["value"] as? [String: Any],
              let parameters = value["parameters"] as? [Int], parameters.count == 3 else { return nil }
        // parameters are character code, virtual key code, modifier flags
        return KeyCombo(keyCode: UInt16(parameters[1]), modifiers: NSEvent.ModifierFlags(rawValue: UInt(parameters[2])))
    }
}
