import AppKit
import Combine

// Turns the shortcuts in settings into live triggers: key combos go to Carbon,
// modifier-only combos to the event tap, both end up selecting an input source.
@MainActor
final class ShortcutController: ObservableObject {
    enum Action: Hashable {
        case select(sourceID: String)
        case next
    }

    // the event tap could not be started, which means Input Monitoring is missing
    @Published private(set) var tapUnavailable = false
    @Published private(set) var rejectedKeyCombos: Set<KeyCombo> = []

    private let sources: InputSourceStore
    private let settings: SettingsStore
    private var hotKeys: CarbonHotKeys?
    private var tap: ModifierEventTap?
    private var detector = ModifierTapDetector()
    private var actions: [Shortcut: Action] = [:]
    private var subscriptions: Set<AnyCancellable> = []
    private var permissionTimer: Timer?

    init(sources: InputSourceStore, settings: SettingsStore) {
        self.sources = sources
        self.settings = settings

        hotKeys = CarbonHotKeys { [weak self] combo in
            self?.perform(.key(combo))
        }
        tap = ModifierEventTap { [weak self] events in
            self?.handle(events)
        }

        // @Published emits before the property changes, so take the values from the pipeline
        settings.$layoutShortcuts
            .combineLatest(settings.$cycleShortcut, settings.$isRecording)
            .sink { [weak self] layoutShortcuts, cycleShortcut, isRecording in
                self?.rebind(layoutShortcuts: layoutShortcuts, cycleShortcut: cycleShortcut, isRecording: isRecording)
            }
            .store(in: &subscriptions)
    }

    // called again when the permission may have been granted meanwhile
    func rebind() {
        rebind(layoutShortcuts: settings.layoutShortcuts, cycleShortcut: settings.cycleShortcut, isRecording: settings.isRecording)
    }

    private func rebind(layoutShortcuts: [String: Shortcut], cycleShortcut: Shortcut?, isRecording: Bool) {
        actions = [:]
        for (sourceID, shortcut) in layoutShortcuts {
            actions[shortcut] = .select(sourceID: sourceID)
        }
        if let shortcut = cycleShortcut {
            actions[shortcut] = .next
        }

        var keyCombos: Set<KeyCombo> = []
        var modifierCombos: Set<ModifierCombo> = []
        if !isRecording {
            for shortcut in actions.keys {
                switch shortcut {
                case .key(let combo): keyCombos.insert(combo)
                case .modifiers(let combo): modifierCombos.insert(combo)
                }
            }
        }

        rejectedKeyCombos = hotKeys?.register(keyCombos) ?? []
        Log.shortcuts.debug("Rebind: \(keyCombos.count) key combos, \(modifierCombos.count) modifier combos, recording \(isRecording)")
        detector.bindings = modifierCombos
        detector.reset()

        if modifierCombos.isEmpty {
            tap?.stop()
            tapUnavailable = false
        } else if let tap {
            // creating the tap is what makes macOS ask for Input Monitoring; without the permission
            // the tap exists but never gets events, so it is made again once the permission arrives
            if tapUnavailable {
                tap.stop()
            }
            let started = tap.start()
            let granted = Permissions.hasInputMonitoring
            Log.shortcuts.info("Event tap started: \(started), Input Monitoring granted: \(granted)")
            tapUnavailable = !started || !granted
        }
        watchPermission(tapUnavailable)
    }

    // macOS doesn't say when Input Monitoring gets granted, so look every couple of seconds
    private func watchPermission(_ watching: Bool) {
        guard watching else {
            permissionTimer?.invalidate()
            permissionTimer = nil
            return
        }
        guard permissionTimer == nil else { return }
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard Permissions.hasInputMonitoring else { return }
                Log.shortcuts.info("Input Monitoring granted")
                self?.rebind()
            }
        }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    private func handle(_ events: [ModifierTapDetector.Event]) {
        guard !settings.isRecording else { return }
        for event in events {
            if let combo = detector.handle(event) {
                Log.shortcuts.debug("Modifier combo fired: \(combo.displayString, privacy: .public)")
                perform(.modifiers(combo))
            }
        }
    }

    private func perform(_ shortcut: Shortcut) {
        guard let action = actions[shortcut] else { return }
        switch action {
        case .select(let sourceID):
            guard let source = sources.sources.first(where: { $0.id == sourceID }) else {
                Log.shortcuts.info("Shortcut for a source that is no longer enabled: \(sourceID, privacy: .public)")
                return
            }
            sources.select(source)
        case .next:
            sources.selectNext()
        }
    }
}
