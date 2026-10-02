import AppKit
import CoreGraphics

// Switching between a keyboard layout and an input method (Hiragana, Pinyin…) from a
// background app updates the menu bar but the frontmost app keeps the old source until it
// regains focus. Pressing the system "previous input source" shortcut twice goes through
// the path that updates the app, and ends on the source we selected.
@MainActor
protocol InputSourceNudging: AnyObject {
    // false when the nudge can't be performed, so the caller can tell the user why
    func nudge() -> Bool
}

@MainActor
final class SystemShortcutNudge: InputSourceNudging {
    func nudge() -> Bool {
        guard Permissions.hasAccessibility, let combo = SystemShortcuts.previousInputSource else { return false }
        for _ in 0..<2 {
            press(combo)
        }
        return true
    }

    private func press(_ combo: KeyCombo) {
        let source = CGEventSource(stateID: .combinedSessionState)
        for down in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(combo.keyCode), keyDown: down) else { continue }
            event.flags = CGEventFlags(rawValue: UInt64(combo.modifiers.rawValue))
            event.setIntegerValueField(.eventSourceUserData, value: ModifierEventTap.syntheticMarker)
            event.post(tap: .cghidEventTap)
        }
    }
}
