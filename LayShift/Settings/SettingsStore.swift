import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private enum Key {
        static let showsMenuBarIcon = "showsMenuBarIcon"
        static let hideIconExplained = "hideIconExplained"
    }

    private let defaults: UserDefaults

    @Published var showsMenuBarIcon: Bool {
        didSet { defaults.set(showsMenuBarIcon, forKey: Key.showsMenuBarIcon) }
    }

    // the "how to get Settings back" note is shown once
    @Published var hideIconExplained: Bool {
        didSet { defaults.set(hideIconExplained, forKey: Key.hideIconExplained) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showsMenuBarIcon = defaults.object(forKey: Key.showsMenuBarIcon) as? Bool ?? true
        hideIconExplained = defaults.bool(forKey: Key.hideIconExplained)
    }
}
