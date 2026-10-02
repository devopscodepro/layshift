// Recognises modifier-only shortcuts from the raw stream of modifier presses and releases.
//
// A combo fires on the first release after exactly its keys were held, provided nothing else
// happened in between: no other key, no mouse click, no extra modifier. Anything else poisons
// the gesture until every modifier is released, so ⌘C, ⌘-click and ⌃⇧R never switch layouts.
struct ModifierTapDetector {
    enum Event: Equatable {
        case modifierDown(ModifierKey)
        case modifierUp(ModifierKey)
        case otherInput
    }

    var bindings: Set<ModifierCombo>

    private(set) var held: Set<ModifierKey> = []
    private var armed: ModifierCombo?
    private var contaminated = false
    private var fired = false

    init(bindings: Set<ModifierCombo> = []) {
        self.bindings = bindings
    }

    mutating func handle(_ event: Event) -> ModifierCombo? {
        switch event {
        case .modifierDown(let key):
            held.insert(key)
            guard !contaminated, !fired else { return nil }
            if let combo = bindings.first(where: { $0.matches(held) }) {
                armed = combo
            } else if bindings.contains(where: { $0.couldStillMatch(held) }) {
                armed = nil
            } else {
                contaminated = true
                armed = nil
            }
            return nil

        case .modifierUp(let key):
            held.remove(key)
            var result: ModifierCombo?
            if let combo = armed, !contaminated, !fired {
                fired = true
                result = combo
            }
            armed = nil
            if held.isEmpty {
                contaminated = false
                fired = false
            }
            return result

        case .otherInput:
            if !held.isEmpty {
                contaminated = true
                armed = nil
            }
            return nil
        }
    }

    // after a tap was started before we began listening, or when the tap was re-enabled
    mutating func reset() {
        held = []
        armed = nil
        contaminated = false
        fired = false
    }
}
