import Testing
@testable import LayShift

struct SystemShortcutsTests {
    @Test func parsesTheDefaultControlSpace() {
        let entry: [String: Any] = ["enabled": 1, "value": ["type": "standard", "parameters": [32, 49, 262144]]]

        #expect(SystemShortcuts.parse(entry) == SystemShortcuts.defaultPrevious)
    }

    @Test func parsesControlOptionSpace() {
        let entry: [String: Any] = ["enabled": true, "value": ["type": "standard", "parameters": [32, 49, 786432]]]

        #expect(SystemShortcuts.parse(entry) == SystemShortcuts.defaultNext)
    }

    @Test func disabledShortcutIsNil() {
        let entry: [String: Any] = ["enabled": 0, "value": ["type": "standard", "parameters": [32, 49, 262144]]]

        #expect(SystemShortcuts.parse(entry) == nil)
    }

    @Test func garbageIsNil() {
        #expect(SystemShortcuts.parse(["enabled": 1]) == nil)
        #expect(SystemShortcuts.parse(["enabled": 1, "value": ["parameters": [1, 2]]]) == nil)
    }
}
