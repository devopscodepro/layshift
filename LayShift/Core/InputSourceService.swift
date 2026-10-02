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

    // Two TIS quirks: a property filter keeps listing an input mode after its input method was
    // turned off, and a long-running process keeps such orphans in the unfiltered list too.
    // The Input menu never shows them, so modes without their input method are dropped here.
    func enabledSources() -> [InputSource] {
        guard let list = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            Log.sources.error("TISCreateInputSourceList returned nothing")
            return []
        }
        let keyboard = list.filter {
            Self.property($0, kTISPropertyInputSourceCategory) as? String == kTISCategoryKeyboardInputSource as String
        }
        let inputMethods = Set(keyboard.compactMap { reference -> String? in
            guard Self.property(reference, kTISPropertyInputSourceType) as? String == kTISTypeKeyboardInputMethodModeEnabled as String else { return nil }
            return Self.property(reference, kTISPropertyBundleID) as? String
        })

        var seen: Set<String> = []
        var result: [InputSource] = []
        for reference in keyboard {
            guard Self.property(reference, kTISPropertyInputSourceIsSelectCapable) as? Bool == true,
                  let source = Self.inputSource(from: reference) else { continue }
            if source.kind == .inputMode,
               let bundle = Self.property(reference, kTISPropertyBundleID) as? String, !inputMethods.contains(bundle) {
                continue
            }
            guard seen.insert(source.id).inserted else { continue }
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
        guard status == noErr else {
            Log.sources.error("TISSelectInputSource(\(source.id, privacy: .public)) failed: \(status)")
            return false
        }
        // macOS reports success for a source it quietly refused, e.g. one that was just disabled
        guard currentSource()?.id == source.id else {
            Log.sources.error("macOS did not switch to \(source.id, privacy: .public)")
            references[source.id] = nil
            return false
        }
        return true
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
