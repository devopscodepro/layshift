import AppKit
import CoreGraphics

// Listens to modifier keys system-wide and reports presses, releases and anything that
// interrupts a modifier-only tap. Runs on its own thread so a busy main thread can't make
// macOS disable the tap for being slow. Needs the Input Monitoring permission.
final class ModifierEventTap: @unchecked Sendable {
    static let syntheticMarker: Int64 = 0x4C61_7953 // 'LayS', set on events we post ourselves

    private let handler: @Sendable ([ModifierTapDetector.Event]) -> Void
    private var thread: Thread?
    private var runLoop: CFRunLoop?
    private var port: CFMachPort?
    private var held: Set<ModifierKey> = []

    // events arrive on the main queue, in order
    init(handler: @escaping @MainActor ([ModifierTapDetector.Event]) -> Void) {
        self.handler = { events in
            DispatchQueue.main.async { handler(events) }
        }
    }

    var isRunning: Bool {
        port != nil
    }

    // false when the tap can't be created, in practice when Input Monitoring is missing
    func start() -> Bool {
        guard port == nil else { return true }

        let types: [CGEventType] = [.flagsChanged, .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                Unmanaged<ModifierEventTap>.fromOpaque(userInfo).takeUnretainedValue().handle(type, event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            Log.shortcuts.error("Event tap could not be created")
            return false
        }
        self.port = port

        let ready = DispatchSemaphore(value: 0)
        let thread = Thread { [self] in
            guard let port = self.port else { return }
            let runLoop = CFRunLoopGetCurrent()
            self.runLoop = runLoop
            CFRunLoopAddSource(runLoop, CFMachPortCreateRunLoopSource(nil, port, 0), .commonModes)
            CGEvent.tapEnable(tap: port, enable: true)
            ready.signal()
            CFRunLoopRun()
        }
        thread.name = "pro.devopscode.LayShift.event-tap"
        thread.qualityOfService = .userInteractive
        thread.start()
        ready.wait()
        self.thread = thread
        Log.shortcuts.info("Event tap started")
        return true
    }

    func stop() {
        guard let port else { return }
        CGEvent.tapEnable(tap: port, enable: false)
        CFMachPortInvalidate(port)
        if let runLoop {
            CFRunLoopStop(runLoop)
        }
        self.port = nil
        runLoop = nil
        thread = nil
        held = []
        Log.shortcuts.info("Event tap stopped")
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let port {
                CGEvent.tapEnable(tap: port, enable: true)
            }
            Log.shortcuts.warning("Event tap was disabled, re-enabled")
            held = []
            handler([.otherInput])

        case .flagsChanged:
            guard event.getIntegerValueField(.eventSourceUserData) != Self.syntheticMarker else { return }
            let now = Self.keys(in: event.flags)
            var events: [ModifierTapDetector.Event] = []
            // what a press or release means depends on which keys we saw before,
            // so changes are reported one key at a time
            for key in held.subtracting(now).sorted(by: { $0.sortOrder < $1.sortOrder }) {
                events.append(.modifierUp(key))
            }
            for key in now.subtracting(held).sorted(by: { $0.sortOrder < $1.sortOrder }) {
                events.append(.modifierDown(key))
            }
            held = now
            if !events.isEmpty {
                handler(events)
            }

        default:
            guard event.getIntegerValueField(.eventSourceUserData) != Self.syntheticMarker else { return }
            handler([.otherInput])
        }
    }

    // the per-key bits NSEvent exposes tell left from right
    static func keys(in flags: CGEventFlags) -> Set<ModifierKey> {
        let raw = UInt(flags.rawValue)
        return Set(ModifierKey.allCases.filter { raw & $0.deviceFlag != 0 })
    }
}
