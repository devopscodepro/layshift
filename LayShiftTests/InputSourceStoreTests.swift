import Testing
@testable import LayShift

@MainActor
struct InputSourceStoreTests {
    @Test func loadsSourcesAndCurrentOnInit() {
        let service = MockInputSourceService(sources: [.abc, .russian], current: .russian)
        let store = InputSourceStore(service: service)

        #expect(store.sources == [.abc, .russian])
        #expect(store.current == .russian)
    }

    @Test func nextWrapsAround() {
        let service = MockInputSourceService(sources: [.abc, .russian, .hiragana])
        let store = InputSourceStore(service: service)

        #expect(store.next(after: .abc) == .russian)
        #expect(store.next(after: .hiragana) == .abc)
        #expect(store.next(after: nil) == .abc)
        #expect(store.next(after: .pinyin) == .abc)
    }

    @Test func selectNextGoesThroughTheService() {
        let service = MockInputSourceService(sources: [.abc, .russian], current: .abc)
        let store = InputSourceStore(service: service)

        store.selectNext()

        #expect(service.selected == [.russian])
        #expect(store.current == .russian)
    }

    @Test func failedSelectKeepsCurrent() {
        let service = MockInputSourceService(sources: [.abc, .russian], current: .abc)
        service.selectSucceeds = false
        let store = InputSourceStore(service: service)

        store.select(.russian)

        #expect(store.current == .abc)
    }

    @Test func refreshPicksUpSystemChanges() {
        let service = MockInputSourceService(sources: [.abc], current: .abc)
        let store = InputSourceStore(service: service)

        service.sources = [.abc, .pinyin]
        service.current = .pinyin
        store.refresh()

        #expect(store.sources == [.abc, .pinyin])
        #expect(store.current == .pinyin)
    }

    @Test func shortCodeComesFromTheLanguage() {
        #expect(InputSource.abc.shortCode == "EN")
        #expect(InputSource.pinyin.shortCode == "ZH")
        #expect(InputSource(id: "x", name: "Custom", kind: .keyboardLayout, languages: []).shortCode == "CU")
    }
}
