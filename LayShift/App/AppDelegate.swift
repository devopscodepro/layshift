import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var sources: InputSourceStore?
    private var settings: SettingsStore?
    private var shortcuts: ShortcutController?
    private var menuBar: MenuBarController?
    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // unit tests use the app as a host, keep the menu bar clean there
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        let sources = InputSourceStore(service: TISInputSourceService(), nudge: SystemShortcutNudge())
        let settings = SettingsStore()
        let shortcuts = ShortcutController(sources: sources, settings: settings)
        let settingsWindow = SettingsWindowController(sources: sources, settings: settings, shortcuts: shortcuts)
        self.sources = sources
        self.settings = settings
        self.shortcuts = shortcuts
        self.settingsWindow = settingsWindow
        menuBar = MenuBarController(sources: sources, settings: settings) {
            settingsWindow.show()
        }
        installMainMenu()
        shortcuts.rebind()

        if !settings.showsMenuBarIcon || isFirstLaunch {
            settingsWindow.show()
        }
    }

    // a click on the Dock icon, or launching the app while it already runs
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow?.show()
        return false
    }

    private var isFirstLaunch: Bool {
        let key = "launchedBefore"
        defer { UserDefaults.standard.set(true, forKey: key) }
        return !UserDefaults.standard.bool(forKey: key)
    }

    // only shown while the settings window is open
    private func installMainMenu() {
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: String(localized: "About LayShift"), action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: String(localized: "Settings…"), action: #selector(showSettings), keyEquivalent: ",")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: String(localized: "Hide LayShift"), action: #selector(NSApplication.hide), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: String(localized: "Quit LayShift"), action: #selector(NSApplication.terminate), keyEquivalent: "q")

        let windowMenu = NSMenu(title: String(localized: "Window"))
        windowMenu.addItem(withTitle: String(localized: "Close"), action: #selector(NSWindow.performClose), keyEquivalent: "w")

        let mainMenu = NSMenu()
        for submenu in [appMenu, windowMenu] {
            let item = NSMenuItem()
            item.submenu = submenu
            mainMenu.addItem(item)
        }
        NSApplication.shared.mainMenu = mainMenu
        NSApplication.shared.windowsMenu = windowMenu
    }

    @objc private func showAbout() {
        AboutPanel.show()
    }

    @objc private func showSettings() {
        settingsWindow?.show()
    }
}
