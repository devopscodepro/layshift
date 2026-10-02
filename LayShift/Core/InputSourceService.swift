import AppKit
import Carbon.HIToolbox

@MainActor
protocol InputSourceProviding: AnyObject {
    func enabledSources() -> [InputSource]
    func currentSource() -> InputSource?
    func select(_ source: InputSource) -> Bool
    func icon(for source: InputSource) -> NSImage?
}

// Text Input Sources must be used from the main thread
@MainActor
final class TISInputSourceService: InputSourceProviding {
    private var references: [String: TISInputSource] = [:]

    func enabledSources() -> [InputSource] {
        let filter = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsEnabled as String: true,
            kTISPropertyInputSourceIsSelectCapable as String: true,
        ] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
            Log.sources.error("TISCreateInputSourceList returned nothing")
            return []
        }

        var seen: Set<String> = []
        var result: [InputSource] = []
        for reference in list {
            guard let source = Self.inputSource(from: reference), seen.insert(source.id).inserted else { continue }
            references[source.id] = reference
            result.append(source)
        }
        return result
    }

    func currentSource() -> InputSource? {
        guard let reference = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        return Self.inputSource(from: reference)
    }

    func select(_ source: InputSource) -> Bool {
        guard let reference = reference(for: source) else {
            Log.sources.error("No input source for \(source.id, privacy: .public)")
            return false
        }
        let status = TISSelectInputSource(reference)
        if status != noErr {
            Log.sources.error("TISSelectInputSource(\(source.id, privacy: .public)) failed: \(status)")
        }
        return status == noErr
    }

    // sources that only have a legacy IconRef get no icon: the API to draw one is deprecated
    func icon(for source: InputSource) -> NSImage? {
        guard let reference = reference(for: source),
              let url = Self.property(reference, kTISPropertyIconImageURL) as? URL else { return nil }
        return NSImage(contentsOf: url)
    }

    private func reference(for source: InputSource) -> TISInputSource? {
        if let cached = references[source.id] {
            return cached
        }
        _ = enabledSources()
        return references[source.id]
    }

    private static func inputSource(from reference: TISInputSource) -> InputSource? {
        guard let id = property(reference, kTISPropertyInputSourceID) as? String,
              let type = property(reference, kTISPropertyInputSourceType) as? String else { return nil }
        let kind: InputSource.Kind = type == (kTISTypeKeyboardInputMode as String) ? .inputMode : .keyboardLayout
        return InputSource(
            id: id,
            name: property(reference, kTISPropertyLocalizedName) as? String ?? id,
            kind: kind,
            languages: property(reference, kTISPropertyInputSourceLanguages) as? [String] ?? []
        )
    }

    private static func property(_ reference: TISInputSource, _ key: CFString) -> AnyObject? {
        guard let pointer = TISGetInputSourceProperty(reference, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue()
    }
}
