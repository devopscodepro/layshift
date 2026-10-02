import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private enum Key {
        static let showsMenuBarIcon = "showsMenuBarIcon"
        static let hideIconExplained = "hideIconExplained"
        static let layoutShortcuts = "layoutShortcuts"
        static let cycleShortcut = "cycleShortcut"
    }

    private let defaults: UserDefaults

    @Published var showsMenuBarIcon: Bool {
        didSet { defaults.set(showsMenuBarIcon, forKey: Key.showsMenuBarIcon) }
    }

    // the "how to get Settings back" note is shown once
    @Published var hideIconExplained: Bool {
        didSet { defaults.set(hideIconExplained, forKey: Key.hideIconExplained) }
    }

    // keyed by input source ID, so a shortcut survives the layout being removed and re-added
    @Published var layoutShortcuts: [String: Shortcut] {
        didSet { defaults.set(try? JSONEncoder().encode(layoutShortcuts), forKey: Key.layoutShortcuts) }
    }

    @Published var cycleShortcut: Shortcut? {
        didSet { defaults.set(try? JSONEncoder().encode(cycleShortcut), forKey: Key.cycleShortcut) }
    }

    // not saved: set while a recorder listens, so no shortcut fires meanwhile
    @Published var isRecording = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showsMenuBarIcon = defaults.object(forKey: Key.showsMenuBarIcon) as? Bool ?? true
        hideIconExplained = defaults.bool(forKey: Key.hideIconExplained)
        layoutShortcuts = defaults.data(forKey: Key.layoutShortcuts)
            .flatMap { try? JSONDecoder().decode([String: Shortcut].self, from: $0) } ?? [:]
        // assigning an optional @Published property in init would run didSet and write defaults
        _cycleShortcut = Published(initialValue: defaults.data(forKey: Key.cycleShortcut)
            .flatMap { try? JSONDecoder().decode(Shortcut?.self, from: $0) } ?? nil)
    }

    // a shortcut can only do one thing: assigning it somewhere takes it away from where it was
    func setShortcut(_ shortcut: Shortcut?, forSource sourceID: String) {
        if let shortcut {
            removeEverywhere(shortcut)
        }
        layoutShortcuts[sourceID] = shortcut
    }

    func setCycleShortcut(_ shortcut: Shortcut?) {
        Log.settings.debug("setCycleShortcut \(String(describing: shortcut), privacy: .public)")
        if let shortcut {
            removeEverywhere(shortcut)
        }
        cycleShortcut = shortcut
    }

    var usesModifierShortcuts: Bool {
        (Array(layoutShortcuts.values) + [cycleShortcut].compactMap { $0 }).contains { shortcut in
            if case .modifiers = shortcut { return true }
            return false
        }
    }

    private func removeEverywhere(_ shortcut: Shortcut) {
        for (sourceID, existing) in layoutShortcuts where existing == shortcut {
            layoutShortcuts[sourceID] = nil
        }
        if cycleShortcut == shortcut {
            cycleShortcut = nil
        }
    }
}
