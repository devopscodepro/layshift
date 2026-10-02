import AppKit
import Combine

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let sources: InputSourceStore
    private let settings: SettingsStore
    private let openSettings: () -> Void

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private let currentItem = NSMenuItem()
    private let secureInputItem = NSMenuItem()
    private var subscriptions: Set<AnyCancellable> = []

    init(sources: InputSourceStore, settings: SettingsStore, openSettings: @escaping () -> Void) {
        self.sources = sources
        self.settings = settings
        self.openSettings = openSettings
        super.init()

        buildMenu()
        settings.$showsMenuBarIcon
            .sink { [weak self] in self?.setIconVisible($0) }
            .store(in: &subscriptions)
        sources.$current
            .sink { [weak self] in self?.update(current: $0) }
            .store(in: &subscriptions)
    }

    private func buildMenu() {
        menu.autoenablesItems = false
        menu.delegate = self

        currentItem.isEnabled = false
        menu.addItem(currentItem)
        secureInputItem.isEnabled = false
        secureInputItem.isHidden = true
        secureInputItem.image = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil)
        menu.addItem(secureInputItem)
        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: String(localized: "Settings…"), action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: String(localized: "Quit LayShift"), action: #selector(NSApplication.terminate), keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    private func setIconVisible(_ visible: Bool) {
        if visible, statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            item.menu = menu
            item.button?.image = MenuBarIcon.image
            item.button?.toolTip = "LayShift"
            statusItem = item
            update(current: sources.current)
        } else if !visible, let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func update(current: InputSource?) {
        let name = current?.name ?? String(localized: "No input source")
        currentItem.title = name
        currentItem.image = current.flatMap { sources.icon(for: $0) }.map { icon in
            icon.size = NSSize(width: 16, height: 16)
            return icon
        }
        statusItem?.button?.setAccessibilityLabel(String(localized: "LayShift, current layout \(name)"))
    }

    func menuWillOpen(_ menu: NSMenu) {
        sources.refresh()
        updateSecureInput()
    }

    // nothing can be done about it from here, but the user should know why shortcuts went quiet
    private func updateSecureInput() {
        guard let app = SystemKeyboard.secureInputApp else {
            secureInputItem.isHidden = true
            return
        }
        secureInputItem.title = app.isEmpty
            ? String(localized: "Shortcuts paused: secure input is on")
            : String(localized: "Shortcuts paused: \(app) uses secure input")
        secureInputItem.isHidden = false
    }

    @objc private func showSettings() {
        openSettings()
    }
}
