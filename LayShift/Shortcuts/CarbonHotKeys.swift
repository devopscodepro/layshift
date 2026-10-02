import Carbon.HIToolbox

// Carbon is the only way to get system-wide key shortcuts without any permission
@MainActor
final class CarbonHotKeys {
    private let action: (KeyCombo) -> Void
    private var handlerRef: EventHandlerRef?
    private var registered: [UInt32: (KeyCombo, EventHotKeyRef)] = [:]
    private var nextID: UInt32 = 1

    init(action: @escaping (KeyCombo) -> Void) {
        self.action = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData, let event else { return OSStatus(eventNotHandledErr) }
                var hotKeyID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                let hotKeys = Unmanaged<CarbonHotKeys>.fromOpaque(userData).takeUnretainedValue()
                MainActor.assumeIsolated { hotKeys.fire(id: hotKeyID.id) }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        if status != noErr {
            Log.shortcuts.error("InstallEventHandler failed: \(status)")
        }
    }

    // returns the combos macOS refused; another app using the same keys is not reported
    @discardableResult
    func register(_ combos: Set<KeyCombo>) -> Set<KeyCombo> {
        unregisterAll()
        var rejected: Set<KeyCombo> = []
        for combo in combos {
            let id = nextID
            nextID += 1
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                UInt32(combo.keyCode),
                combo.carbonModifiers,
                EventHotKeyID(signature: OSType(0x4C61_7953), id: id), // 'LayS'
                GetApplicationEventTarget(),
                0,
                &ref
            )
            if status == noErr, let ref {
                registered[id] = (combo, ref)
            } else {
                Log.shortcuts.error("RegisterEventHotKey failed: \(status)")
                rejected.insert(combo)
            }
        }
        return rejected
    }

    func unregisterAll() {
        for (_, ref) in registered.values {
            UnregisterEventHotKey(ref)
        }
        registered = [:]
    }

    private func fire(id: UInt32) {
        guard let (combo, _) = registered[id] else { return }
        action(combo)
    }
}
