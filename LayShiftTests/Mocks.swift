import AppKit
@testable import LayShift

@MainActor
final class MockInputSourceService: InputSourceProviding {
    var sources: [InputSource]
    var current: InputSource?
    var selected: [InputSource] = []
    var selectSucceeds = true

    init(sources: [InputSource], current: InputSource? = nil) {
        self.sources = sources
        self.current = current ?? sources.first
    }

    func enabledSources() -> [InputSource] { sources }
    func currentSource() -> InputSource? { current }
    func icon(for source: InputSource) -> NSImage? { nil }

    func select(_ source: InputSource) -> Bool {
        selected.append(source)
        if selectSucceeds { current = source }
        return selectSucceeds
    }
}

extension InputSource {
    static let abc = InputSource(id: "com.apple.keylayout.ABC", name: "ABC", kind: .keyboardLayout, languages: ["en"])
    static let russian = InputSource(id: "com.apple.keylayout.Russian", name: "Russian", kind: .keyboardLayout, languages: ["ru"])
    static let hiragana = InputSource(id: "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese", name: "Hiragana", kind: .inputMode, languages: ["ja"])
    static let pinyin = InputSource(id: "com.apple.inputmethod.SCIM.ITABC", name: "Pinyin – Simplified", kind: .inputMode, languages: ["zh-Hans"])
}
