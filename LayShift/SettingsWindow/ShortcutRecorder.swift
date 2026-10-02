import AppKit
import Carbon.HIToolbox
import SwiftUI

// A button that records either a key combo (⌥1) or a modifier-only combo (press and release ⌃⇧).
// While recording, the global shortcuts are paused through settings.isRecording.
struct ShortcutRecorder: View {
    @ObservedObject var settings: SettingsStore
    let shortcut: Shortcut?
    let onChange: (Shortcut?) -> Void

    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var held: Set<ModifierKey> = []
    @State private var peak: Set<ModifierKey> = []
    @State private var problem: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 6) {
                Button {
                    isRecording ? stop() : start()
                } label: {
                    Text(label)
                        .frame(minWidth: 110)
                }
                .help(isRecording
                    ? String(localized: "Press keys, or press and release modifiers. Esc cancels, Delete clears.")
                    : String(localized: "Click to record a shortcut"))

                if !isRecording, shortcut != nil {
                    Button {
                        onChange(nil)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help(String(localized: "Remove shortcut"))
                    .accessibilityLabel(Text("Remove shortcut"))
                }
            }
            if let problem {
                Text(problem)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .onDisappear { stop() }
    }

    private var label: String {
        if isRecording {
            return held.isEmpty ? String(localized: "Type shortcut…") : ModifierCombo(held).displayString
        }
        return shortcut?.displayString ?? String(localized: "None")
    }

    private func start() {
        isRecording = true
        settings.isRecording = true
        problem = nil
        held = []
        peak = []
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            handle(event)
            return nil
        }
    }

    private func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        isRecording = false
        settings.isRecording = false
        held = []
        peak = []
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            held = Self.keys(in: event.modifierFlags)
            if held.isEmpty {
                if !peak.isEmpty {
                    accept(.modifiers(ModifierCombo(peak)))
                }
            } else {
                peak.formUnion(held)
            }

        case .keyDown:
            let plain = event.modifierFlags.intersection(KeyCombo.relevantModifiers).isEmpty
            switch Int(event.keyCode) {
            case kVK_Escape where plain:
                stop()
            case kVK_Delete where plain, kVK_ForwardDelete where plain:
                onChange(nil)
                stop()
            default:
                let combo = KeyCombo(keyCode: event.keyCode, modifiers: event.modifierFlags)
                if combo.isValid {
                    accept(.key(combo))
                } else {
                    NSSound.beep()
                    peak = []
                }
            }

        default:
            break
        }
    }

    private func accept(_ shortcut: Shortcut) {
        if case .key(let combo) = shortcut, SystemShortcuts.isTaken(combo) {
            problem = String(localized: "macOS uses this shortcut to switch input sources.")
            NSSound.beep()
            stop()
            return
        }
        onChange(shortcut)
        stop()
    }

    private static func keys(in flags: NSEvent.ModifierFlags) -> Set<ModifierKey> {
        Set(ModifierKey.physical.filter { flags.rawValue & $0.deviceFlag != 0 })
    }
}
