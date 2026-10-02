import Testing
@testable import LayShift

@MainActor
final class MockNudge: InputSourceNudging {
    var calls = 0
    var succeeds = true

    func nudge() -> Bool {
        calls += 1
        return succeeds
    }
}

@MainActor
struct InputSourceNudgeTests {
    @Test func onlyBoundaryCrossingsNeedANudge() {
        #expect(!InputSourceStore.needsNudge(from: .abc, to: .russian))
        #expect(!InputSourceStore.needsNudge(from: .hiragana, to: .pinyin))
        #expect(InputSourceStore.needsNudge(from: .abc, to: .hiragana))
        #expect(InputSourceStore.needsNudge(from: .pinyin, to: .russian))
        #expect(InputSourceStore.needsNudge(from: nil, to: .pinyin))
        #expect(!InputSourceStore.needsNudge(from: nil, to: .abc))
    }

    @Test func storeNudgesAfterSelectingAnInputMethod() {
        let service = MockInputSourceService(sources: [.abc, .pinyin], current: .abc)
        let nudge = MockNudge()
        let store = InputSourceStore(service: service, nudge: nudge)

        store.select(.pinyin)
        #expect(nudge.calls == 1)
        #expect(!store.nudgeFailed)

        store.select(.abc)
        #expect(nudge.calls == 2)
    }

    @Test func layoutOnlySwitchesNeverNudge() {
        let service = MockInputSourceService(sources: [.abc, .russian], current: .abc)
        let nudge = MockNudge()
        let store = InputSourceStore(service: service, nudge: nudge)

        store.select(.russian)
        store.selectNext()

        #expect(nudge.calls == 0)
    }

    @Test func failedNudgeIsReported() {
        let service = MockInputSourceService(sources: [.abc, .hiragana], current: .abc)
        let nudge = MockNudge()
        nudge.succeeds = false
        let store = InputSourceStore(service: service, nudge: nudge)

        store.select(.hiragana)

        #expect(store.nudgeFailed)
    }
}
