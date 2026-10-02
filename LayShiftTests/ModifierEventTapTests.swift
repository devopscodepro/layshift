import CoreGraphics
import Testing
@testable import LayShift

struct ModifierEventTapTests {
    // values observed on macOS 27 for each key alone
    @Test func readsSidesFromDeviceFlags() {
        #expect(ModifierEventTap.keys(in: CGEventFlags(rawValue: 0x100008)) == [.leftCommand])
        #expect(ModifierEventTap.keys(in: CGEventFlags(rawValue: 0x100010)) == [.rightCommand])
        #expect(ModifierEventTap.keys(in: CGEventFlags(rawValue: 0x20002)) == [.leftShift])
        #expect(ModifierEventTap.keys(in: CGEventFlags(rawValue: 0x20004)) == [.rightShift])
        #expect(ModifierEventTap.keys(in: CGEventFlags(rawValue: 0x40001)) == [.leftControl])
        #expect(ModifierEventTap.keys(in: CGEventFlags(rawValue: 0x42000)) == [.rightControl])
        #expect(ModifierEventTap.keys(in: CGEventFlags(rawValue: 0x80020)) == [.leftOption])
        #expect(ModifierEventTap.keys(in: CGEventFlags(rawValue: 0x80040)) == [.rightOption])
        #expect(ModifierEventTap.keys(in: CGEventFlags(rawValue: 0x800000)) == [.function])
        #expect(ModifierEventTap.keys(in: CGEventFlags(rawValue: 0x60003)) == [.leftControl, .leftShift])
        #expect(ModifierEventTap.keys(in: CGEventFlags(rawValue: 0)) == [])
    }

    @Test func capsLockIsNotAModifierKey() {
        #expect(ModifierEventTap.keys(in: .maskAlphaShift) == [])
    }
}
