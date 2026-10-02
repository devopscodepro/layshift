import Foundation

// the ready-made choices for "next layout", like MLSwitcher2's list; any side of the keyboard works
enum CyclePreset: String, CaseIterable, Identifiable {
    case none
    case controlShift, optionShift, commandShift, controlOption
    case control, option, command, shift
    case rightCommand, rightOption, function
    case custom

    var id: String { rawValue }

    var shortcut: Shortcut? {
        switch self {
        case .none, .custom: nil
        case .controlShift: .modifiers(ModifierCombo(.control, .shift))
        case .optionShift: .modifiers(ModifierCombo(.option, .shift))
        case .commandShift: .modifiers(ModifierCombo(.command, .shift))
        case .controlOption: .modifiers(ModifierCombo(.control, .option))
        case .control: .modifiers(ModifierCombo(.control))
        case .option: .modifiers(ModifierCombo(.option))
        case .command: .modifiers(ModifierCombo(.command))
        case .shift: .modifiers(ModifierCombo(.shift))
        case .rightCommand: .modifiers(ModifierCombo(.rightCommand))
        case .rightOption: .modifiers(ModifierCombo(.rightOption))
        case .function: .modifiers(ModifierCombo(.function))
        }
    }

    @MainActor
    var title: String {
        switch self {
        case .none: String(localized: "None")
        case .custom: String(localized: "Custom…")
        case .controlShift: "⌃ Control + ⇧ Shift"
        case .optionShift: "⌥ Option + ⇧ Shift"
        case .commandShift: "⌘ Command + ⇧ Shift"
        case .controlOption: "⌃ Control + ⌥ Option"
        case .control: "⌃ Control"
        case .option: "⌥ Option"
        case .command: "⌘ Command"
        case .shift: "⇧ Shift"
        case .rightCommand: String(localized: "Right ⌘ Command")
        case .rightOption: String(localized: "Right ⌥ Option")
        case .function: String(localized: "fn / 🌐 Globe")
        }
    }

    // which preset a stored shortcut corresponds to; anything recorded by hand is "custom"
    static func preset(for shortcut: Shortcut?) -> CyclePreset {
        guard let shortcut else { return .none }
        return allCases.first { $0.shortcut == shortcut } ?? .custom
    }
}
