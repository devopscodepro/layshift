import AppKit
import Carbon.HIToolbox

@MainActor
final class InputSourceStore: ObservableObject {
    @Published private(set) var sources: [InputSource] = []
    @Published private(set) var current: InputSource?
    // an input method was selected but the nudge that makes it take effect was not possible
    @Published private(set) var nudgeFailed = false

    private let service: InputSourceProviding
    private let nudge: InputSourceNudging?
    private let notifications: DistributedNotificationCenter
    // the nudge makes macOS pass through another source for a moment; remember where we are going
    private var pending: (source: InputSource, until: Date)?

    init(service: InputSourceProviding, nudge: InputSourceNudging? = nil, notifications: DistributedNotificationCenter = .default()) {
        self.service = service
        self.nudge = nudge
        self.notifications = notifications
        refresh()

        // App Nap delays distributed notifications for background apps unless asked to deliver at once
        let names = [kTISNotifySelectedKeyboardInputSourceChanged, kTISNotifyEnabledKeyboardInputSourcesChanged]
        for name in names.compactMap({ $0.map { $0 as String } }) {
            notifications.addObserver(
                self,
                selector: #selector(systemChanged),
                name: Notification.Name(name),
                object: nil,
                suspensionBehavior: .deliverImmediately
            )
        }
    }

    deinit {
        notifications.removeObserver(self)
    }

    func refresh() {
        let sources = service.enabledSources()
        if sources != self.sources {
            self.sources = sources
        }
        let current = service.currentSource()
        if current != self.current {
            self.current = current
        }
    }

    func icon(for source: InputSource) -> NSImage? {
        service.icon(for: source)
    }

    var hasInputMethods: Bool {
        sources.contains { $0.kind == .inputMode }
    }

    func select(_ source: InputSource) {
        let previous = pendingSource ?? current
        guard service.select(source) else {
            // the list may be stale, e.g. the source was removed in System Settings
            refresh()
            return
        }
        current = source
        pending = nil
        Log.sources.debug("Selected \(source.id, privacy: .public)")

        if Self.needsNudge(from: previous, to: source) {
            pending = (source, Date().addingTimeInterval(1))
            nudgeFailed = nudge?.nudge() != true
        }
    }

    func selectNext() {
        guard let next = next(after: pendingSource ?? current) else { return }
        select(next)
    }

    private var pendingSource: InputSource? {
        guard let pending, pending.until > Date() else { return nil }
        return pending.source
    }

    func next(after source: InputSource?) -> InputSource? {
        guard !sources.isEmpty else { return nil }
        guard let source, let index = sources.firstIndex(of: source) else { return sources.first }
        return sources[(index + 1) % sources.count]
    }

    // layout ↔ layout and input method ↔ input method switches take effect on their own
    static func needsNudge(from previous: InputSource?, to source: InputSource) -> Bool {
        guard let previous else { return source.kind == .inputMode }
        return previous.kind != source.kind
    }

    @objc private func systemChanged(_ notification: Notification) {
        refresh()
        Log.sources.debug("System says current is \(self.current?.id ?? "nil", privacy: .public)")
    }
}
