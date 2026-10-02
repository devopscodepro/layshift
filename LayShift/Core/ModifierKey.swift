import AppKit
import Carbon.HIToolbox

// a physical modifier key, left and right told apart
enum ModifierKey: String, Codable, CaseIterable, Hashable, Sendable {
    case leftControl, rightControl
    case leftOption, rightOption
    case leftShift, rightShift
    case leftCommand, rightCommand
    case function

    enum Side: Sendable { case left, right }

    init?(keyCode: UInt16) {
        switch Int(keyCode) {
        case kVK_Control: self = .leftControl
        case kVK_RightControl: self = .rightControl
        case kVK_Option: self = .leftOption
        case kVK_RightOption: self = .rightOption
        case kVK_Shift: self = .leftShift
        case kVK_RightShift: self = .rightShift
        case kVK_Command: self = .leftCommand
        case kVK_RightCommand: self = .rightCommand
        case kVK_Function: self = .function
        default: return nil
        }
    }

    var side: Side? {
        switch self {
        case .leftControl, .leftOption, .leftShift, .leftCommand: .left
        case .rightControl, .rightOption, .rightShift, .rightCommand: .right
        case .function: nil
        }
    }

    var flag: NSEvent.ModifierFlags {
        switch self {
        case .leftControl, .rightControl: .control
        case .leftOption, .rightOption: .option
        case .leftShift, .rightShift: .shift
        case .leftCommand, .rightCommand: .command
        case .function: .function
        }
    }

    // the bit NSEvent sets for this exact key, so a press is told from a release without guessing
    var deviceFlag: UInt {
        switch self {
        case .leftControl: 0x0001
        case .rightControl: 0x2000
        case .leftShift: 0x0002
        case .rightShift: 0x0004
        case .leftCommand: 0x0008
        case .rightCommand: 0x0010
        case .leftOption: 0x0020
        case .rightOption: 0x0040
        case .function: NSEvent.ModifierFlags.function.rawValue
        }
    }

    var symbol: String {
        switch self {
        case .leftControl, .rightControl: "⌃"
        case .leftOption, .rightOption: "⌥"
        case .leftShift, .rightShift: "⇧"
        case .leftCommand, .rightCommand: "⌘"
        case .function: "fn"
        }
    }

    // ⌃ ⌥ ⇧ ⌘ is the order macOS uses in menus
    var sortOrder: Int {
        switch self {
        case .leftControl, .rightControl: 0
        case .leftOption, .rightOption: 1
        case .leftShift, .rightShift: 2
        case .leftCommand, .rightCommand: 3
        case .function: 4
        }
    }
}
