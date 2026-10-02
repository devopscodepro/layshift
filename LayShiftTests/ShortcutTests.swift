import AppKit
import Carbon.HIToolbox
import Foundation
import Testing
@testable import LayShift

@MainActor
struct ShortcutTests {
    @Test func keyComboDisplayFollowsMacOrder() {
        let combo = KeyCombo(keyCode: UInt16(kVK_ANSI_A), modifiers: [.command, .shift, .option, .control])

        #expect(combo.displayString == "⌃⌥⇧⌘A")
        #expect(combo.carbonModifiers == UInt32(controlKey | optionKey | shiftKey | cmdKey))
    }

    @Test func keyComboIgnoresUnrelatedFlags() {
        let combo = KeyCombo(keyCode: UInt16(kVK_ANSI_K), modifiers: [.command, .capsLock, .numericPad])

        #expect(combo.modifiers == .command)
    }

    @Test func keyComboValidity() {
        #expect(!KeyCombo(keyCode: UInt16(kVK_ANSI_K), modifiers: []).isValid)
        #expect(!KeyCombo(keyCode: UInt16(kVK_ANSI_K), modifiers: .shift).isValid)
        #expect(KeyCombo(keyCode: UInt16(kVK_ANSI_K), modifiers: .option).isValid)
        #expect(KeyCombo(keyCode: UInt16(kVK_F13), modifiers: []).isValid)
        #expect(KeyCombo(keyCode: UInt16(kVK_Space), modifiers: .control).displayString == "⌃Space")
    }

    @Test func modifierComboDisplay() {
        #expect(ModifierCombo(.rightCommand).displayString == "Right ⌘")
        #expect(ModifierCombo(.leftShift, .leftControl).displayString == "Left ⌃⇧")
        #expect(ModifierCombo(.leftControl, .rightShift).displayString == "Left ⌃ + Right ⇧")
        #expect(ModifierCombo(.function).displayString == "fn")
        #expect(ModifierCombo(.function, .leftShift).displayString == "Left ⇧fn")
        #expect(!ModifierCombo([]).isValid)
    }

    @Test func modifierKeysFromKeyCodes() {
        #expect(ModifierKey(keyCode: UInt16(kVK_Command)) == .leftCommand)
        #expect(ModifierKey(keyCode: UInt16(kVK_RightCommand)) == .rightCommand)
        #expect(ModifierKey(keyCode: UInt16(kVK_RightOption)) == .rightOption)
        #expect(ModifierKey(keyCode: UInt16(kVK_Function)) == .function)
        #expect(ModifierKey(keyCode: UInt16(kVK_ANSI_A)) == nil)
    }

    @Test func shortcutsRoundTripThroughJSON() throws {
        let shortcuts: [Shortcut] = [
            .key(KeyCombo(keyCode: UInt16(kVK_ANSI_1), modifiers: .option)),
            .modifiers(ModifierCombo(.leftControl, .leftShift)),
        ]

        let data = try JSONEncoder().encode(shortcuts)
        let decoded = try JSONDecoder().decode([Shortcut].self, from: data)

        #expect(decoded == shortcuts)
    }
}
