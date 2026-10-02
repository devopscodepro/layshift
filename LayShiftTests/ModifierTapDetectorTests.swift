import Testing
@testable import LayShift

struct ModifierTapDetectorTests {
    let ctrlShift = ModifierCombo(.leftControl, .leftShift)
    let rightCommand = ModifierCombo(.rightCommand)
    let leftCommand = ModifierCombo(.leftCommand)

    @Test func comboFiresOnFirstRelease() {
        var detector = ModifierTapDetector(bindings: [ctrlShift])

        #expect(detector.handle(.modifierDown(.leftControl)) == nil)
        #expect(detector.handle(.modifierDown(.leftShift)) == nil)
        #expect(detector.handle(.modifierUp(.leftShift)) == ctrlShift)
        #expect(detector.handle(.modifierUp(.leftControl)) == nil)
    }

    @Test func orderOfPressesDoesNotMatter() {
        var detector = ModifierTapDetector(bindings: [ctrlShift])

        _ = detector.handle(.modifierDown(.leftShift))
        _ = detector.handle(.modifierDown(.leftControl))
        #expect(detector.handle(.modifierUp(.leftControl)) == ctrlShift)
    }

    @Test func singleModifierTap() {
        var detector = ModifierTapDetector(bindings: [rightCommand])

        _ = detector.handle(.modifierDown(.rightCommand))
        #expect(detector.handle(.modifierUp(.rightCommand)) == rightCommand)
    }

    @Test func sidesAreDistinct() {
        var detector = ModifierTapDetector(bindings: [rightCommand])

        _ = detector.handle(.modifierDown(.leftCommand))
        #expect(detector.handle(.modifierUp(.leftCommand)) == nil)
    }

    @Test func keyPressInBetweenCancels() {
        var detector = ModifierTapDetector(bindings: [ctrlShift, leftCommand])

        _ = detector.handle(.modifierDown(.leftCommand))
        _ = detector.handle(.otherInput)
        #expect(detector.handle(.modifierUp(.leftCommand)) == nil)

        _ = detector.handle(.modifierDown(.leftControl))
        _ = detector.handle(.modifierDown(.leftShift))
        _ = detector.handle(.otherInput)
        #expect(detector.handle(.modifierUp(.leftShift)) == nil)
        #expect(detector.handle(.modifierUp(.leftControl)) == nil)
    }

    @Test func typingWithoutModifiersDoesNotPoisonTheNextTap() {
        var detector = ModifierTapDetector(bindings: [leftCommand])

        _ = detector.handle(.otherInput)
        _ = detector.handle(.modifierDown(.leftCommand))
        #expect(detector.handle(.modifierUp(.leftCommand)) == leftCommand)
    }

    @Test func unboundSupersetCancels() {
        var detector = ModifierTapDetector(bindings: [leftCommand])

        _ = detector.handle(.modifierDown(.leftCommand))
        _ = detector.handle(.modifierDown(.leftShift))
        #expect(detector.handle(.modifierUp(.leftShift)) == nil)
        #expect(detector.handle(.modifierUp(.leftCommand)) == nil)
    }

    @Test func boundSupersetWinsOverItsSubset() {
        let commandShift = ModifierCombo(.leftCommand, .leftShift)
        var detector = ModifierTapDetector(bindings: [leftCommand, commandShift])

        _ = detector.handle(.modifierDown(.leftCommand))
        _ = detector.handle(.modifierDown(.leftShift))
        #expect(detector.handle(.modifierUp(.leftShift)) == commandShift)
        #expect(detector.handle(.modifierUp(.leftCommand)) == nil)
    }

    @Test func partialReleaseThenRepressDoesNotFireTwice() {
        var detector = ModifierTapDetector(bindings: [ctrlShift])

        _ = detector.handle(.modifierDown(.leftControl))
        _ = detector.handle(.modifierDown(.leftShift))
        #expect(detector.handle(.modifierUp(.leftShift)) == ctrlShift)
        _ = detector.handle(.modifierDown(.leftShift))
        #expect(detector.handle(.modifierUp(.leftShift)) == nil)
        _ = detector.handle(.modifierUp(.leftControl))

        _ = detector.handle(.modifierDown(.leftControl))
        _ = detector.handle(.modifierDown(.leftShift))
        #expect(detector.handle(.modifierUp(.leftShift)) == ctrlShift)
    }

    @Test func contaminationClearsOnFullRelease() {
        var detector = ModifierTapDetector(bindings: [leftCommand])

        _ = detector.handle(.modifierDown(.leftCommand))
        _ = detector.handle(.otherInput)
        _ = detector.handle(.modifierUp(.leftCommand))

        _ = detector.handle(.modifierDown(.leftCommand))
        #expect(detector.handle(.modifierUp(.leftCommand)) == leftCommand)
    }

    @Test func resetForgetsHeldKeys() {
        var detector = ModifierTapDetector(bindings: [leftCommand])

        _ = detector.handle(.modifierDown(.leftShift))
        detector.reset()
        _ = detector.handle(.modifierDown(.leftCommand))
        #expect(detector.handle(.modifierUp(.leftCommand)) == leftCommand)
    }

    @Test func nothingBoundNeverFires() {
        var detector = ModifierTapDetector()

        _ = detector.handle(.modifierDown(.leftCommand))
        #expect(detector.handle(.modifierUp(.leftCommand)) == nil)
    }
}
