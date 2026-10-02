import AppKit
import Carbon.HIToolbox

// a modifier key: either a physical one, left and right told apart, or "either side"
enum ModifierKey: String, Codable, CaseIterable, Hashable, Sendable {
    case leftControl, rightControl, control
    case leftOption, rightOption, option
    case leftShift, rightShift, shift
    case leftCommand, rightCommand, command
    case function

    enum Side: Sendable { case left, right }

    enum Family: Int, Comparable, Sendable {
        case control, option, shift, command, function

        static func < (lhs: Family, rhs: Family) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    // the keys a keyboard can actually report
    static let physical: [ModifierKey] = allCases.filter { $0.side != nil || $0 == .function }

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

    var family: Family {
        switch self {
        case .leftControl, .rightControl, .control: .control
        case .leftOption, .rightOption, .option: .option
        case .leftShift, .rightShift, .shift: .shift
        case .leftCommand, .rightCommand, .command: .command
        case .function: .function
        }
    }

    var side: Side? {
        switch self {
        case .leftControl, .leftOption, .leftShift, .leftCommand: .left
        case .rightControl, .rightOption, .rightShift, .rightCommand: .right
        case .control, .option, .shift, .command, .function: nil
        }
    }

    // true for "either side" keys, which match a left or a right press alike
    var isAnySide: Bool {
        side == nil && self != .function
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
        case .control: 0x2001
        case .shift: 0x0006
        case .command: 0x0018
        case .option: 0x0060
        }
    }

    var symbol: String {
        switch family {
        case .control: "⌃"
        case .option: "⌥"
        case .shift: "⇧"
        case .command: "⌘"
        case .function: "fn"
        }
    }
}
