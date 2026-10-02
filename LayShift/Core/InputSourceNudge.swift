import AppKit
import Carbon.HIToolbox
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
    // the two presses need a gap: macOS switches on key up and drops a second press that comes at once
    static let gap: TimeInterval = 0.15

    func nudge() -> Bool {
        guard Permissions.hasAccessibility, let combo = SystemShortcuts.previousInputSource else { return false }
        press(combo)
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.gap) { [self] in
            press(combo)
        }
        return true
    }

    // the system shortcut commits when the modifier is released, so the modifier keys are pressed
    // and released like a person would, not just set as flags on the key
    private func press(_ combo: KeyCombo) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let modifiers: [(NSEvent.ModifierFlags, CGKeyCode, CGEventFlags)] = [
            (.control, CGKeyCode(kVK_Control), .maskControl),
            (.option, CGKeyCode(kVK_Option), .maskAlternate),
            (.shift, CGKeyCode(kVK_Shift), .maskShift),
            (.command, CGKeyCode(kVK_Command), .maskCommand),
        ].filter { combo.modifiers.contains($0.0) }

        var flags: CGEventFlags = []
        for (_, keyCode, flag) in modifiers {
            flags.insert(flag)
            post(source, keyCode, down: true, flags: flags)
        }
        post(source, CGKeyCode(combo.keyCode), down: true, flags: flags)
        post(source, CGKeyCode(combo.keyCode), down: false, flags: flags)
        for (_, keyCode, flag) in modifiers.reversed() {
            flags.remove(flag)
            post(source, keyCode, down: false, flags: flags)
        }
    }

    private func post(_ source: CGEventSource?, _ keyCode: CGKeyCode, down: Bool, flags: CGEventFlags) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down) else { return }
        event.flags = flags
        event.setIntegerValueField(.eventSourceUserData, value: ModifierEventTap.syntheticMarker)
        event.post(tap: .cghidEventTap)
    }
}
