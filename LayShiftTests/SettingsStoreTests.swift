import Carbon.HIToolbox
import Foundation
import Testing
@testable import LayShift

@MainActor
struct SettingsStoreTests {
    let option1 = Shortcut.key(KeyCombo(keyCode: UInt16(kVK_ANSI_1), modifiers: .option))
    let ctrlShift = Shortcut.modifiers(ModifierCombo(.leftControl, .leftShift))

    func makeDefaults() -> UserDefaults {
        let name = "LayShiftTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func shortcutsPersist() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        store.setShortcut(option1, forSource: InputSource.abc.id)
        store.setCycleShortcut(ctrlShift)

        let reloaded = SettingsStore(defaults: defaults)

        #expect(reloaded.layoutShortcuts == [InputSource.abc.id: option1])
        #expect(reloaded.cycleShortcut == ctrlShift)
    }

    @Test func assigningAShortcutTakesItAwayFromItsPreviousOwner() {
        let store = SettingsStore(defaults: makeDefaults())
        store.setShortcut(option1, forSource: InputSource.abc.id)
        store.setCycleShortcut(ctrlShift)

        store.setShortcut(option1, forSource: InputSource.russian.id)
        store.setShortcut(ctrlShift, forSource: InputSource.abc.id)

        #expect(store.layoutShortcuts == [InputSource.russian.id: option1, InputSource.abc.id: ctrlShift])
        #expect(store.cycleShortcut == nil)
    }

    @Test func removingAShortcut() {
        let store = SettingsStore(defaults: makeDefaults())
        store.setShortcut(option1, forSource: InputSource.abc.id)

        store.setShortcut(nil, forSource: InputSource.abc.id)

        #expect(store.layoutShortcuts.isEmpty)
    }

    @Test func knowsWhenModifierShortcutsAreInUse() {
        let store = SettingsStore(defaults: makeDefaults())
        #expect(!store.usesModifierShortcuts)

        store.setShortcut(option1, forSource: InputSource.abc.id)
        #expect(!store.usesModifierShortcuts)

        store.setCycleShortcut(ctrlShift)
        #expect(store.usesModifierShortcuts)
    }

    @Test func defaultsAreSane() {
        let store = SettingsStore(defaults: makeDefaults())

        #expect(store.showsMenuBarIcon)
        #expect(store.layoutShortcuts.isEmpty)
        #expect(store.cycleShortcut == nil)
        #expect(!store.isRecording)
    }
}
