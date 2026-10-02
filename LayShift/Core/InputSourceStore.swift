import AppKit
import Carbon.HIToolbox

@MainActor
final class InputSourceStore: ObservableObject {
    @Published private(set) var sources: [InputSource] = []
    @Published private(set) var current: InputSource?

    private let service: InputSourceProviding
    private let notifications: DistributedNotificationCenter

    init(service: InputSourceProviding, notifications: DistributedNotificationCenter = .default()) {
        self.service = service
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

    func select(_ source: InputSource) {
        guard service.select(source) else { return }
        current = source
        Log.sources.debug("Selected \(source.id, privacy: .public)")
    }

    func selectNext() {
        guard let next = next(after: current) else { return }
        select(next)
    }

    func next(after source: InputSource?) -> InputSource? {
        guard !sources.isEmpty else { return nil }
        guard let source, let index = sources.firstIndex(of: source) else { return sources.first }
        return sources[(index + 1) % sources.count]
    }

    @objc private func systemChanged(_ notification: Notification) {
        refresh()
    }
}
