import AppKit
import Carbon.HIToolbox

// a key with modifiers, handled by Carbon without any permission
struct KeyCombo: Codable, Hashable, Sendable {
    static let relevantModifiers: NSEvent.ModifierFlags = [.control, .option, .shift, .command]

    var keyCode: UInt16
    var modifierFlags: UInt

    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifierFlags = modifiers.intersection(Self.relevantModifiers).rawValue
    }

    var modifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlags)
    }

    // plain letters and ⇧+letter would fire while typing
    var isValid: Bool {
        if Self.functionKeys.keys.contains(Int(keyCode)) { return true }
        return !modifiers.intersection([.control, .option, .command]).isEmpty
    }

    var carbonModifiers: UInt32 {
        var result = 0
        if modifiers.contains(.control) { result |= controlKey }
        if modifiers.contains(.option) { result |= optionKey }
        if modifiers.contains(.shift) { result |= shiftKey }
        if modifiers.contains(.command) { result |= cmdKey }
        return UInt32(result)
    }

    // keyboard layout APIs only work on the main thread
    @MainActor
    var displayString: String {
        var result = ""
        if modifiers.contains(.control) { result += "⌃" }
        if modifiers.contains(.option) { result += "⌥" }
        if modifiers.contains(.shift) { result += "⇧" }
        if modifiers.contains(.command) { result += "⌘" }
        return result + keyName
    }

    @MainActor
    var keyName: String {
        if let name = Self.functionKeys[Int(keyCode)] ?? Self.specialNames[Int(keyCode)] {
            return name
        }
        return Self.character(for: keyCode)?.uppercased() ?? "?"
    }

    private static let functionKeys: [Int: String] = [
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        kVK_F13: "F13", kVK_F14: "F14", kVK_F15: "F15", kVK_F16: "F16", kVK_F17: "F17",
        kVK_F18: "F18", kVK_F19: "F19", kVK_F20: "F20",
    ]

    private static let specialNames: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_Escape: "⎋", kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
    ]

    // the Latin layout, so ⌘K shows as K even when Russian is the active input source
    @MainActor
    private static func character(for keyCode: UInt16) -> String? {
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let property = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }

        let data = Unmanaged<CFData>.fromOpaque(property).takeUnretainedValue() as Data
        return data.withUnsafeBytes { buffer -> String? in
            guard let layout = buffer.bindMemory(to: UCKeyboardLayout.self).baseAddress else { return nil }
            var deadKeys: UInt32 = 0
            var length = 0
            var chars = [UniChar](repeating: 0, count: 4)
            let status = UCKeyTranslate(
                layout, keyCode, UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKeys, chars.count, &length, &chars
            )
            guard status == noErr, length > 0 else { return nil }
            return String(utf16CodeUnits: chars, count: length)
        }
    }
}

// modifiers pressed and released on their own, e.g. ⌃⇧ or the right ⌘
struct ModifierCombo: Codable, Hashable, Sendable {
    var keys: Set<ModifierKey>

    init(_ keys: Set<ModifierKey>) {
        self.keys = keys
    }

    init(_ keys: ModifierKey...) {
        self.keys = Set(keys)
    }

    var isValid: Bool {
        !keys.isEmpty
    }

    // "Right ⌘", "Left ⌃⇧", "Left ⌃ + Right ⇧", "fn"
    var displayString: String {
        let sorted = keys.sorted { $0.sortOrder < $1.sortOrder }
        let sides = Set(sorted.compactMap(\.side))
        if sides.count <= 1 {
            let symbols = sorted.map(\.symbol).joined()
            guard let side = sides.first else { return symbols }
            return "\(Self.name(for: side)) \(symbols)"
        }
        return sorted.map { key in
            guard let side = key.side else { return key.symbol }
            return "\(Self.name(for: side)) \(key.symbol)"
        }.joined(separator: " + ")
    }

    private static func name(for side: ModifierKey.Side) -> String {
        switch side {
        case .left: String(localized: "Left")
        case .right: String(localized: "Right")
        }
    }
}

enum Shortcut: Codable, Hashable, Sendable {
    case key(KeyCombo)
    case modifiers(ModifierCombo)

    var isValid: Bool {
        switch self {
        case .key(let combo): combo.isValid
        case .modifiers(let combo): combo.isValid
        }
    }

    @MainActor
    var displayString: String {
        switch self {
        case .key(let combo): combo.displayString
        case .modifiers(let combo): combo.displayString
        }
    }
}
