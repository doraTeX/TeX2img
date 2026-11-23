import AppKit
import Carbon.HIToolbox

// Customizable menu shortcuts, ported from TeXShop 5.60 (Sources/Shortcuts). TeX2img has no macros,
// so only menu commands take part. Assignments are kept in the user defaults, outside the profiles.

/// A key equivalent: a character and the modifiers that matter for shortcuts.
struct ShortcutBinding: Hashable {
    static let modifierMask: NSEvent.ModifierFlags = [.command, .option, .control, .shift]

    let key: String
    let modifiers: NSEvent.ModifierFlags

    /// AppKit spells Shift-letter as an upper-case key; compare such bindings without a keyboard layout.
    init(_ key: String?, _ flags: NSEvent.ModifierFlags) {
        var flags = flags.intersection(Self.modifierMask)
        guard var key, !key.isEmpty else {
            self.key = ""
            self.modifiers = []
            return
        }
        if key.count == 1, let scalar = key.unicodeScalars.first, ("A"..."Z").contains(scalar) {
            key = key.lowercased()
            flags.insert(.shift)
        }
        self.key = key
        self.modifiers = flags
    }

    static func == (a: ShortcutBinding, b: ShortcutBinding) -> Bool { a.key == b.key && a.modifiers.rawValue == b.modifiers.rawValue }
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(modifiers.rawValue)
    }

    var propertyList: [String: Any] { ["key": key, "modifiers": NSNumber(value: modifiers.rawValue)] }
}

/// A menu command whose shortcut can be changed.
final class ShortcutCommand {
    let item: NSMenuItem
    let commandID: String
    var path: String
    /// The key the item was given, which AppKit adapts to each keyboard layout (TeXShop 6.00).
    let defaultKey: String
    let defaultModifiers: NSEvent.ModifierFlags
    let defaultLocalization: Bool
    /// The default as AppKit showed it, for each keyboard layout it was seen on.
    var shownDefaults: [String: ShortcutBinding] = [:]

    init(item: NSMenuItem, identifier: String, path: String) {
        self.item = item
        commandID = identifier
        self.path = path
        // The key AppKit shows on this layout is read first: reading the given key makes AppKit work the shown key out
        // again (on a French layout, & for the 1 the item was given; giving & back would show Shift-Command-7).
        defaultLocalization = item.allowsAutomaticKeyEquivalentLocalization
        let shown = ShortcutKeys.shownBinding(item)
        item.allowsAutomaticKeyEquivalentLocalization = false
        defaultKey = item.keyEquivalent
        defaultModifiers = item.keyEquivalentModifierMask
        item.allowsAutomaticKeyEquivalentLocalization = defaultLocalization
        if defaultLocalization && !shown.key.isEmpty { shownDefaults[ShortcutKeys.keyboardLayoutID()] = shown }
    }
}

/// A menu item found by a key search. Only the first item with a key receives it.
struct ShortcutMatch {
    let path: String
    let item: NSMenuItem
    let command: ShortcutCommand?
    let winner: Bool
}

enum ShortcutKeys {
    static let identifierPrefix = "TSShortcut."

    /// A key as AppKit shows it now: with automatic key-equivalent localization, the key of the current keyboard layout
    /// (on a French layout, & for the 1 the item was given), worked out again whenever the item changes.
    static func shownBinding(_ item: NSMenuItem) -> ShortcutBinding {
        ShortcutBinding(item.keyEquivalent, item.keyEquivalentModifierMask)
    }

    /// The key and modifiers the item was given, read with the localization turned off for a moment; AppKit localizes
    /// the item again on its own (TeXShop 6.00).
    static func givenBinding(_ item: NSMenuItem) -> ShortcutBinding {
        guard item.allowsAutomaticKeyEquivalentLocalization else { return shownBinding(item) }
        item.allowsAutomaticKeyEquivalentLocalization = false
        let given = shownBinding(item)
        item.allowsAutomaticKeyEquivalentLocalization = true
        return given
    }

    /// The identifier of the current keyboard layout (switching an input method, as between Japanese and ABC, keeps it).
    static func keyboardLayoutID() -> String {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return "" }
        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    /// Keys AppKit adapts to the layout: not letters, which every layout keeps, nor function keys.
    static func layoutAdaptsKey(_ key: String) -> Bool {
        guard key.utf16.count == 1, let c = key.utf16.first else { return false }
        return !((c >= 0x61 && c <= 0x7a) || (c >= 0x41 && c <= 0x5a) || c >= 0x7f || c < 0x21)
    }

    /// The hidden items that show the keys of a keyboard layout for a moment (ShortcutStore.learnLayoutKeys).
    static let learningIdentifier = NSUserInterfaceItemIdentifier("TeX2imgShortcutLearning")

    /// Visits every item of a menu with its path ("File › Save"), skipping the Services menu and the hidden items that
    /// show the keys of a keyboard layout.
    static func visit(_ menu: NSMenu?, path: String = "", _ body: (NSMenuItem, String) -> Void) {
        guard let menu else { return }
        for item in menu.items where item.identifier != learningIdentifier {
            if let submenu = item.submenu, submenu === NSApp.servicesMenu { continue }
            let title = path.isEmpty ? item.title : "\(path) › \(item.title)"
            body(item, title)
            if let submenu = item.submenu { visit(submenu, path: title, body) }
        }
    }

    /// TeXShop gives each customizable menu item the identifier "TSShortcut.<action>.<tag>" in its nibs.
    /// TeX2img gives the same identifiers when the menu is first read. Items that AppKit adds and window
    /// list items have no stable identity and are not customizable.
    static func prepareIdentifiers(_ menu: NSMenu) {
        visit(menu) { item, _ in
            guard item.submenu == nil, let action = item.action, !(item.identifier?.rawValue.hasPrefix(identifierPrefix) ?? false) else { return }
            let name = NSStringFromSelector(action)
            guard !name.hasPrefix("_"), !(item.target is NSWindow), name != "makeKeyAndOrderFront:" else { return }
            item.identifier = NSUserInterfaceItemIdentifier("\(identifierPrefix)\(name).\(item.tag)")
        }
    }

    /// Shortcuts must not take plain typing, navigation, or dead-key combinations away from editors.
    static func isAllowed(key: String, modifiers: NSEvent.ModifierFlags) -> Bool {
        if key.isEmpty { return true }
        guard key.utf16.count == 1, modifiers.subtracting(ShortcutBinding.modifierMask).isEmpty,
              let c = key.utf16.first else { return false }
        if c >= UInt16(NSF1FunctionKey) && c <= UInt16(NSF20FunctionKey) { return true }
        return !modifiers.intersection([.command, .control]).isEmpty && c >= 0x20 && c != 0x7f && !(0xd800...0xdfff).contains(c)
    }

    static func display(key: String, modifiers: NSEvent.ModifierFlags) -> String {
        guard let c = key.utf16.first else { return "—" }
        var flags = modifiers
        // Show the actual menu definition; canonical forms are for comparison only.
        if key.count == 1, let scalar = key.unicodeScalars.first, ("A"..."Z").contains(scalar) { flags.insert(.shift) }
        var text = ""
        if flags.contains(.control) { text += "⌃" }
        if flags.contains(.option) { text += "⌥" }
        if flags.contains(.shift) { text += "⇧" }
        if flags.contains(.command) { text += "⌘" }
        let symbols: [Int: String] = [NSLeftArrowFunctionKey: "←", NSRightArrowFunctionKey: "→", NSUpArrowFunctionKey: "↑",
                                      NSDownArrowFunctionKey: "↓", 13: "↩", 9: "⇥", 27: "⎋", 32: "␣", 127: "⌫", NSDeleteFunctionKey: "⌦"]
        if Int(c) >= NSF1FunctionKey && Int(c) <= NSF20FunctionKey {
            text += "F\(Int(c) - NSF1FunctionKey + 1)"
        } else {
            text += symbols[Int(c)] ?? key.uppercased()
        }
        return text
    }

    // MARK: Events

    /// Translates a key code with a keyboard layout; used for event input only, never for comparing bindings.
    static func translate(_ data: CFData?, keyCode: UInt16, modifierState: UInt32, keyboardType: UInt32) -> String? {
        guard let data, let bytes = CFDataGetBytePtr(data) else { return nil }
        var chars = [UniChar](repeating: 0, count: 8)
        var count = 0
        var dead: UInt32 = 0
        let result = bytes.withMemoryRebound(to: UCKeyboardLayout.self, capacity: 1) { layout in
            UCKeyTranslate(layout, keyCode, UInt16(kUCKeyActionDown), modifierState, keyboardType,
                           OptionBits(kUCKeyTranslateNoDeadKeysBit), &dead, 8, &count, &chars)
        }
        return result == noErr ? String(utf16CodeUnits: chars, count: count) : nil
    }

    private static func layoutData(_ source: TISInputSource?) -> CFData? {
        guard let source, let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        return Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue()
    }

    /// The character of a key event, honoring the Command layer (including Dvorak–QWERTY Command).
    /// Option and Control combinations do not use the composed character (Option-G = ©).
    static func character(for event: NSEvent) -> String {
        let key = event.charactersIgnoringModifiers ?? ""
        guard event.modifierFlags.contains(.command) else { return key }
        let characters = event.characters ?? ""
        let c = characters.utf16.count == 1 ? characters.utf16.first! : 0
        let plainASCII = event.modifierFlags.intersection([.option, .control]).isEmpty && c >= 0x20 && c < 0x7f
        // Shift comes from the event flags; Caps Lock must not add Shift.
        if plainASCII, let scalar = Unicode.Scalar(c), CharacterSet.letters.contains(scalar), c < 0x80 { return characters.lowercased() }
        // Command layers can suppress Shift for punctuation; keep the normal layer.
        if key.utf16.count == 1, let k = key.utf16.first, k < 0x80 || k >= 0xf700 { return key }
        if key.utf16.count == 1, let scalar = key.unicodeScalars.first, !CharacterSet.letters.contains(scalar) { return key }
        if plainASCII { return key.isEmpty ? characters : key }
        if key.utf16.count != 1 { return key }
        let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue()
        let latin = translate(layoutData(source), keyCode: event.keyCode,
                              modifierState: event.modifierFlags.contains(.shift) ? UInt32(shiftKey >> 8) : 0,
                              keyboardType: UInt32(LMGetKbdType()))
        if let latin, latin.utf16.count == 1, let l = latin.utf16.first, l >= 0x20, l < 0x7f { return latin }
        return key
    }

    /// The binding to record for an event. A shifted punctuation character already encodes Shift.
    static func recordedBinding(_ event: NSEvent, unshifted: String?) -> ShortcutBinding {
        let key = character(for: event)
        var flags = event.modifierFlags.intersection(ShortcutBinding.modifierMask)
        if flags.contains(.shift), key.utf16.count == 1, key != unshifted, let c = key.utf16.first, c < 0xf700,
           let scalar = key.unicodeScalars.first, !CharacterSet.letters.contains(scalar) {
            flags.remove(.shift)
        }
        return ShortcutBinding(key, flags)
    }

    /// All spellings of an event's input, used to find the items it would trigger.
    static func eventBindings(_ event: NSEvent, unshifted: String?) -> [ShortcutBinding] {
        let key = character(for: event)
        var bindings = [recordedBinding(event, unshifted: unshifted)]
        func add(_ binding: ShortcutBinding) { if !bindings.contains(binding) { bindings.append(binding) } }
        add(ShortcutBinding(key, event.modifierFlags))
        if event.modifierFlags.contains(.shift), key.utf16.count == 1, let unshifted, unshifted.utf16.count == 1,
           let c = key.utf16.first, c < 0xf700, let scalar = key.unicodeScalars.first, !CharacterSet.letters.contains(scalar) {
            add(ShortcutBinding(unshifted, event.modifierFlags))
        }
        return bindings
    }

    /// Spellings under which a default shortcut can be typed on the current layout. Used only to refuse
    /// restoring a default that a custom assignment already takes.
    static func restorationBindings(key: String, modifiers: NSEvent.ModifierFlags) -> [ShortcutBinding] {
        let original = ShortcutBinding(key, modifiers)
        var bindings = [original]
        guard key.count == 1, let scalar = key.unicodeScalars.first,
              CharacterSet.punctuationCharacters.contains(scalar) || CharacterSet.symbols.contains(scalar) else { return bindings }
        let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue()
        guard let data = layoutData(source) else { return bindings }
        let keyboardType = UInt32(LMGetKbdType())
        func characters(_ code: UInt16, _ flags: NSEvent.ModifierFlags) -> String {
            var state = 0
            if flags.contains(.command) { state |= cmdKey }
            if flags.contains(.shift) { state |= shiftKey }
            if flags.contains(.option) { state |= optionKey }
            if flags.contains(.control) { state |= controlKey }
            return translate(data, keyCode: code, modifierState: UInt32(state >> 8), keyboardType: keyboardType) ?? ""
        }
        // Constructs events for comparison only; nothing is posted.
        for code in UInt16(0)..<128 where ![66, 68, 70, 72, 73, 74, 77].contains(code) {
            let plain = characters(code, [])
            for shifted in [false, true] {
                var flags = modifiers.subtracting(.shift)
                if shifted { flags.insert(.shift) }
                guard let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0,
                                                   context: nil, characters: characters(code, flags),
                                                   charactersIgnoringModifiers: characters(code, flags.intersection(.shift)),
                                                   isARepeat: false, keyCode: code) else { continue }
                let spellings = eventBindings(event, unshifted: plain)
                if let recorded = spellings.first, isAllowed(key: recorded.key, modifiers: recorded.modifiers), spellings.contains(original) {
                    for spelling in spellings where !bindings.contains(spelling) { bindings.append(spelling) }
                }
            }
        }
        return bindings
    }
}

/// Reads the customizable commands from the main menu and applies the saved assignments to it.
///
/// On a keyboard layout other than the one a key was made for, AppKit shows another key for a menu item's key (on a
/// French layout, Command-& for the Command-1 the item was given) and matches key presses with it (TeXShop 6.00, reported
/// by Bruno Voisin). A default is kept as the key the item was given and assigned again as given, so that AppKit adapts
/// it as it adapts the menu's own keys; a recorded key is assigned as recorded, without the adaptation. Items whose key
/// does not change are left alone. A default reserves its key as given and as the current layout shows it.
final class ShortcutStore {
    static let overridesKey = "MenuShortcutOverrides"
    /// Posted when the keys AppKit shows changed after an assignment or a change of keyboard layout.
    static let shownKeysChangedNotification = Notification.Name("TeX2imgShortcutShownKeysChanged")

    let menu: NSMenu
    let defaults: UserDefaults
    private var overrides: [String: ShortcutBinding] = [:]
    private(set) var commands: [ShortcutCommand] = []
    private(set) var unavailableCommands: [String] = []
    /// Commands whose item does not have its default key: a saved key.
    private var heldCommandIDs = Set<String>()
    /// The keys each menu item had at the last assignment, as given and as AppKit showed them.
    private var itemBindings = NSMapTable<NSMenuItem, BindingSet>.weakToStrongObjects()
    /// For each keyboard layout, the keys AppKit shows for keys given with Command, and with Command and Shift.
    private var layoutKeys: [String: [ShortcutBinding: ShortcutBinding]] = [:]
    /// Saved keys of commands restored before the keys of the current layout were known, with that layout.
    private var restoredBeforeLayoutKeys: [String: (ShortcutBinding, String)] = [:]
    /// Commands given a key before the keys of the current layout were known, with that layout.
    private var recordedBeforeLayoutKeys: [String: String] = [:]
    private var assignedShownKeys: [ShortcutBinding] = []
    private var assignedLayout: String?
    /// The hidden items AppKit shows keys in, while they are in the menu, and who waits for them.
    private var learningHolder: NSMenuItem?
    private var learningLayout: String?
    private var learningCompletions: [(Bool) -> Void] = []
    /// The keyboard layout the menu was last assigned on, and the follow-ups of a change of layout.
    private var keyboardLayout: String?
    private var layoutRefreshPending = false
    private var settleCheckPending = false
    private var settleRounds = 0
    private var observers: [NSObjectProtocol] = []

    final class BindingSet {
        let bindings: Set<ShortcutBinding>
        init(_ bindings: Set<ShortcutBinding>) { self.bindings = bindings }
    }

    init(menu: NSMenu, defaults: UserDefaults) {
        self.menu = menu
        self.defaults = defaults
        // A malformed preference is treated as absent, entry by entry.
        if let saved = defaults.dictionary(forKey: Self.overridesKey) {
            for (identifier, value) in saved {
                guard let entry = value as? [String: Any], let key = entry["key"] as? String,
                      let modifiers = entry["modifiers"] as? NSNumber else { continue }
                let flags = NSEvent.ModifierFlags(rawValue: modifiers.uintValue)
                if ShortcutKeys.isAllowed(key: key, modifiers: flags) { overrides[identifier] = ShortcutBinding(key, flags) }
            }
        }
        refreshMenu()
        // AppKit shows other keys on another keyboard layout; conflicts are worked out again with them. A layout chosen
        // while TeX2img was in the background is noticed when it comes to the front.
        for name in [NSTextInputContext.keyboardSelectionDidChangeNotification, NSApplication.didBecomeActiveNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.keyboardLayoutChanged()
            })
        }
    }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }

    func refreshMenu() {
        ShortcutKeys.prepareIdentifiers(menu)
        var previous: [ObjectIdentifier: ShortcutCommand] = [:]
        for command in commands { previous[ObjectIdentifier(command.item)] = command }
        var found: [ShortcutCommand] = []
        var seen = Set<String>()
        ShortcutKeys.visit(menu) { item, path in
            guard let identifier = item.identifier?.rawValue, identifier.hasPrefix(ShortcutKeys.identifierPrefix),
                  item.action != nil, item.submenu == nil, seen.insert(identifier).inserted else { return }
            let command = previous[ObjectIdentifier(item)] ?? ShortcutCommand(item: item, identifier: identifier, path: path)
            command.path = path
            found.append(command)
        }
        commands = found
        keyboardLayout = ShortcutKeys.keyboardLayoutID()
        applySavedOverrides()
        noteShownKeysAfterRefresh()
    }

    // MARK: Keys of the keyboard layout

    /// The modifiers each key of a layout's table is given with, Command first.
    private static let layoutKeyVariants: [NSEvent.ModifierFlags] = [.command, [.command, .control, .option], [.command, .control],
                                                                    [.command, .option], .control, .option]
    /// The keys a layout's table has: every such key with Command, and with Command and Shift.
    private static let layoutKeyCount = 2 * (0x7f - 0x21 - 52)

    /// Whether the item of a command has its default key now, as the store assigned it.
    private func commandHoldsDefault(_ command: ShortcutCommand) -> Bool {
        !heldCommandIDs.contains(command.commandID) && command.item.allowsAutomaticKeyEquivalentLocalization == command.defaultLocalization
    }

    /// AppKit adapts a key with any modifiers as it adapts the same key with Command, or with Command and Shift when the
    /// modifiers include Shift: the shown key and Shift come from that, the other modifiers stay. The keys AppKit shows
    /// with Command and with Command and Shift are worked out for each layout (learnLayoutKeys).
    private func layoutShownKey(_ key: String, modifiers: NSEvent.ModifierFlags, layout: String) -> ShortcutBinding? {
        let given = ShortcutBinding(key, modifiers)
        guard ShortcutKeys.layoutAdaptsKey(given.key) else { return given }
        guard let keys = layoutKeys[layout],
              let base = keys[ShortcutBinding(given.key, given.modifiers.intersection(.shift).union(.command))] else { return nil }
        return ShortcutBinding(base.key, given.modifiers.subtracting(.shift).union(base.modifiers.intersection(.shift)))
    }

    /// A key as AppKit shows it on the current layout, or the key itself while that is not known.
    func shownBinding(givenKey key: String, modifiers: NSEvent.ModifierFlags) -> ShortcutBinding {
        layoutShownKey(key, modifiers: modifiers, layout: ShortcutKeys.keyboardLayoutID()) ?? ShortcutBinding(key, modifiers)
    }

    /// The keys of the current layout are known, or the layout is the one the keys were last assigned on, whose defaults
    /// the items showed.
    var knowsKeysOfCurrentLayout: Bool {
        let layout = ShortcutKeys.keyboardLayoutID()
        return layoutKeys[layout] != nil || layout == assignedLayout
    }

    /// Runs the body once the keys of the current layout are known: at once, or after they are worked out (once: a layout
    /// chosen in the meantime does not make it wait again).
    func whenKeysOfCurrentLayoutAreKnown(_ body: @escaping () -> Void) {
        if knowsKeysOfCurrentLayout { body(); return }
        learnLayoutKeys { _ in body() }
    }

    /// The default of a command as AppKit shows it on the current keyboard layout.
    func shownDefault(for command: ShortcutCommand) -> ShortcutBinding {
        let given = ShortcutBinding(command.defaultKey, command.defaultModifiers)
        guard command.defaultLocalization, ShortcutKeys.layoutAdaptsKey(given.key) else { return given }
        let layout = ShortcutKeys.keyboardLayoutID()
        if let shown = layoutShownKey(command.defaultKey, modifiers: command.defaultModifiers, layout: layout) { return shown }
        // Before the layout's keys are worked out: the key the item shows while it has the default, or the key it showed
        // on this layout before.
        let known = command.shownDefaults[layout]
        if commandHoldsDefault(command) {
            // Until AppKit adapts a key assigned again, the item shows the given key.
            let live = ShortcutKeys.shownBinding(command.item)
            if live.key.isEmpty || (live == given && known != nil) { return known ?? given }
            command.shownDefaults[layout] = live
            return live
        }
        return known ?? given
    }

    private func noteShownDefaultsSettled() {
        let layout = ShortcutKeys.keyboardLayoutID()
        for command in commands where command.defaultLocalization && ShortcutKeys.layoutAdaptsKey(command.defaultKey) && commandHoldsDefault(command) {
            let shown = ShortcutKeys.shownBinding(command.item)
            if !shown.key.isEmpty { command.shownDefaults[layout] = shown }
        }
    }

    /// The key of a command as the list of Settings shows it.
    func shownBinding(for command: ShortcutCommand) -> ShortcutBinding {
        if command.item.keyEquivalent.isEmpty || !commandHoldsDefault(command) { return ShortcutKeys.shownBinding(command.item) }
        return shownDefault(for: command)
    }

    /// A default reserves its key as given and as shown: the given key is the one it shows again on a layout like the one
    /// the menu was made for.
    func defaultBindings(for command: ShortcutCommand) -> Set<ShortcutBinding> {
        let given = ShortcutBinding(command.defaultKey, command.defaultModifiers)
        guard !given.key.isEmpty else { return [] }
        return [given, shownDefault(for: command)]
    }

    /// Works out the keys AppKit shows on the current layout, once for each layout; the completion gets whether new keys
    /// were learned. Hidden items without an action, in the menu for one pass of the run loop, never run. AppKit leaves a
    /// key empty when another item shows it, so each key comes again with other modifiers, which AppKit keeps as they are
    /// while it adapts the key in the same way.
    func learnLayoutKeys(then completion: @escaping (Bool) -> Void) {
        let layout = ShortcutKeys.keyboardLayoutID()
        let known = layoutKeys[layout]
        if let known, known.count == Self.layoutKeyCount { completion(false); return }
        learningCompletions.append(completion)
        // One working out per layout: whoever asks while it runs waits for the same one.
        if learningHolder != nil && learningLayout == layout { return }
        stopLearning()
        let holder = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        holder.identifier = ShortcutKeys.learningIdentifier
        holder.isHidden = true
        holder.submenu = NSMenu(title: "")
        var bases: [ShortcutBinding] = [], items: [[NSMenuItem]] = []
        for c in UInt8(0x21)..<UInt8(0x7f) {
            let key = String(UnicodeScalar(c))
            guard ShortcutKeys.layoutAdaptsKey(key) else { continue }
            for shift in [NSEvent.ModifierFlags(), .shift] {
                let base = ShortcutBinding(key, shift.union(.command))
                if known?[base] != nil { continue }
                var pair: [NSMenuItem] = []
                for variant in Self.layoutKeyVariants {
                    let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
                    item.isHidden = true
                    item.keyEquivalentModifierMask = variant.union(shift)
                    item.keyEquivalent = key
                    holder.submenu!.addItem(item)
                    pair.append(item)
                }
                bases.append(base)
                items.append(pair)
            }
        }
        menu.addItem(holder)
        learningHolder = holder
        learningLayout = layout
        DispatchQueue.main.async { [weak self] in
            // Assigning keys removes the items first (applySavedOverrides): AppKit would empty a key assigned later that
            // one of them shows. That working out then starts again.
            guard let self, self.learningHolder === holder else { return }
            var learned = false
            if ShortcutKeys.keyboardLayoutID() == layout {
                var keys = self.layoutKeys[layout] ?? [:]
                // A key AppKit left empty with every variant shows as another item's key with each of them: when only one
                // key has items with all of them, that is the key.
                var occupied = Set<ShortcutBinding>(), characters = Set<String>()
                ShortcutKeys.visit(self.menu) { item, _ in
                    guard item.submenu == nil, !item.keyEquivalent.isEmpty else { return }
                    let shown = ShortcutKeys.shownBinding(item)
                    occupied.insert(shown)
                    characters.insert(shown.key)
                }
                for (index, base) in bases.enumerated() {
                    for (position, variant) in Self.layoutKeyVariants.enumerated() {
                        let shown = ShortcutKeys.shownBinding(items[index][position])
                        guard !shown.key.isEmpty, shown.modifiers.isSuperset(of: variant) else { continue }
                        keys[base] = ShortcutBinding(shown.key, shown.modifiers.intersection(.shift).union(.command))
                        break
                    }
                    if keys[base] != nil { continue }
                    var candidates = Set<ShortcutBinding>()
                    for character in characters {
                        for shift in [NSEvent.ModifierFlags(), .shift]
                        where Self.layoutKeyVariants.allSatisfy({ occupied.contains(ShortcutBinding(character, $0.union(shift))) }) {
                            candidates.insert(ShortcutBinding(character, shift.union(.command)))
                        }
                    }
                    if candidates.count == 1 { keys[base] = candidates.first }
                }
                learned = self.layoutKeys[layout] == nil || keys.count > self.layoutKeys[layout]!.count
                self.layoutKeys[layout] = keys
            }
            self.stopLearning()
            let waiting = self.learningCompletions
            self.learningCompletions.removeAll()
            if learned { self.checkChangesMadeBeforeLayoutKeys(layout) }
            for waiter in waiting { waiter(learned) }
        }
    }

    private func stopLearning() {
        let holder = learningHolder
        learningHolder = nil
        learningLayout = nil
        if let holder, let parent = holder.menu { parent.removeItem(holder) }
    }

    /// Assigning keys took the hidden items away before AppKit showed their keys: whoever waits for them gets a new
    /// working out.
    private func resumeLearning() {
        guard learningHolder == nil, !learningCompletions.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.learningHolder == nil, !self.learningCompletions.isEmpty else { return }
            let waiting = self.learningCompletions
            self.learningCompletions.removeAll()
            for waiter in waiting { self.learnLayoutKeys(then: waiter) }
        }
    }

    /// Recording or restoring before the layout's keys were known went by the given default. Once the keys of the layout
    /// it happened on are known, a recorded key that the layout shows for the default restores the command, and a restored
    /// default that another command's saved key or a menu item meets gives way to the key it had; neither takes a key from
    /// another.
    private func defaultOfCommandIsTaken(_ command: ShortcutCommand) -> Bool {
        let bindings = defaultBindings(for: command)
        if commands.contains(where: { $0 !== command && overrides[$0.commandID].map(bindings.contains) == true }) { return true }
        return conflictForRestoring(command) != nil
    }

    private func checkChangesMadeBeforeLayoutKeys(_ layout: String) {
        var changed = false
        for command in commands {
            let identifier = command.commandID
            let saved = overrides[identifier]
            if recordedBeforeLayoutKeys[identifier] == layout {
                recordedBeforeLayoutKeys[identifier] = nil
                if let saved, saved == layoutShownKey(command.defaultKey, modifiers: command.defaultModifiers, layout: layout) {
                    overrides[identifier] = nil
                    if defaultOfCommandIsTaken(command) { overrides[identifier] = saved } else { changed = true }
                }
            }
            if let (key, restoredOn) = restoredBeforeLayoutKeys[identifier], restoredOn == layout {
                if saved == nil && defaultOfCommandIsTaken(command) { overrides[identifier] = key; changed = true }
                restoredBeforeLayoutKeys[identifier] = nil
            }
        }
        if changed {
            applySavedOverrides()
            persist()
        }
    }

    /// The shown keys the last assignment went by: the defaults and the other items.
    private func shownKeySignature() -> [ShortcutBinding] {
        var signature = commands.map(shownDefault(for:))
        let commandItems = Set(commands.map { ObjectIdentifier($0.item) })
        ShortcutKeys.visit(menu) { item, _ in
            guard item.submenu == nil, !item.keyEquivalent.isEmpty, !commandItems.contains(ObjectIdentifier(item)) else { return }
            signature.append(ShortcutKeys.shownBinding(item))
        }
        return signature
    }

    private func shownKeysChangedSinceAssignment() -> Bool {
        noteShownDefaultsSettled()
        return shownKeySignature() != assignedShownKeys
    }

    /// Switching an input method, as between Japanese and ABC, keeps the keyboard layout. The keys of the new layout are
    /// worked out in the next pass, before the menu is assigned again.
    private func keyboardLayoutChanged() {
        guard let keyboardLayout, ShortcutKeys.keyboardLayoutID() != keyboardLayout, !layoutRefreshPending else { return }
        layoutRefreshPending = true
        learnLayoutKeys { _ in }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.layoutRefreshPending = false
            if ShortcutKeys.keyboardLayoutID() != self.keyboardLayout { self.refreshMenu() }
        }
    }

    /// AppKit adapts reassigned keys to the keyboard layout in a later pass of the run loop, and shows the keys of another
    /// layout a little after it is chosen. Once it has, the defaults are read as shown, the keys of the layout are worked
    /// out, and when any key differs from what the last assignment saw, the menu is assigned again with them.
    private func noteShownKeysAfterRefresh() {
        guard !settleCheckPending else { return }
        settleCheckPending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            self.settleCheckPending = false
            self.learnLayoutKeys { [weak self] _ in
                guard let self else { return }
                if self.shownKeysChangedSinceAssignment() && self.settleRounds < 2 {
                    self.settleRounds += 1
                    self.refreshMenu()
                    return
                }
                self.settleRounds = 0
                NotificationCenter.default.post(name: Self.shownKeysChangedNotification, object: self)
            }
        }
    }

    // MARK: Assigning

    /// Whether the item has the key already. Assigning a key again makes AppKit show the given key until it adapts the
    /// key once more, so unchanged items are left alone.
    private func command(_ command: ShortcutCommand, hasKey target: ShortcutBinding, localized: Bool) -> Bool {
        let item = command.item
        let shown = ShortcutKeys.shownBinding(item)
        if target.key.isEmpty { return shown.key.isEmpty }
        if item.allowsAutomaticKeyEquivalentLocalization != localized { return false }
        if shown == target { return true }
        if !localized { return false }
        if target == ShortcutBinding(command.defaultKey, command.defaultModifiers) && shown == shownDefault(for: command) { return true }
        return ShortcutKeys.givenBinding(item) == target
    }

    /// Assignments that collide with another menu key stay inactive, as in TeXShop.
    private func applySavedOverrides() {
        stopLearning()
        // What AppKit shows before anything is assigned; reading given keys below makes items show those until AppKit
        // adapts them again.
        assignedShownKeys = shownKeySignature()
        var active = Set(commands.filter { overrides[$0.commandID] != nil }.map(\.commandID))
        var unavailable: [String] = []
        func markUnavailable(_ path: String) { if !unavailable.contains(path) { unavailable.append(path) } }
        var defaultsOfItems: [ObjectIdentifier: Set<ShortcutBinding>] = [:]
        for command in commands { defaultsOfItems[ObjectIdentifier(command.item)] = defaultBindings(for: command) }
        let commandItems = Set(commands.map { ObjectIdentifier($0.item) })
        // Other menu items keep their keys, as given and as shown on this layout.
        var planned: [ObjectIdentifier: (NSMenuItem, Set<ShortcutBinding>)] = [:]
        ShortcutKeys.visit(menu) { item, _ in
            guard item.submenu == nil, !commandItems.contains(ObjectIdentifier(item)) else { return }
            let shown = ShortcutKeys.shownBinding(item)
            if !shown.key.isEmpty { planned[ObjectIdentifier(item)] = (item, [shown, ShortcutKeys.givenBinding(item)]) }
        }
        var changed: Bool
        repeat {
            changed = false
            for command in commands {
                let value: Set<ShortcutBinding> = active.contains(command.commandID) ? [overrides[command.commandID]!]
                    : defaultsOfItems[ObjectIdentifier(command.item)] ?? []
                planned[ObjectIdentifier(command.item)] = (command.item, value)
            }
            var rejected = Set<String>()
            for command in commands where active.contains(command.commandID) {
                guard let value = overrides[command.commandID], !value.key.isEmpty else { continue }
                if planned.contains(where: { $0.value.0 !== command.item && $0.value.1.contains(value) }) {
                    rejected.insert(command.commandID)
                    markUnavailable(command.path)
                }
            }
            if !rejected.isEmpty {
                active.subtract(rejected)
                changed = true
            }
        } while changed
        // A default is assigned as the menu gives it, so that AppKit adapts it to the keyboard layout as it does the
        // menu's own keys; a saved key is assigned as recorded.
        let changing = commands.filter { command in
            let saved = active.contains(command.commandID)
            let target = saved ? overrides[command.commandID]! : ShortcutBinding(command.defaultKey, command.defaultModifiers)
            return !self.command(command, hasKey: target, localized: saved ? false : command.defaultLocalization)
        }
        // Avoid transient duplicates when restoring defaults or swapping two saved bindings.
        for command in changing { command.item.keyEquivalent = "" }
        for command in changing {
            if active.contains(command.commandID), let binding = overrides[command.commandID] {
                apply(binding, to: command)
            } else {
                command.item.allowsAutomaticKeyEquivalentLocalization = command.defaultLocalization
                command.item.keyEquivalentModifierMask = command.defaultModifiers
                command.item.keyEquivalent = command.defaultKey
            }
        }
        for command in commands where active.contains(command.commandID) {
            if ShortcutKeys.shownBinding(command.item) != overrides[command.commandID] { markUnavailable(command.path) }
        }
        heldCommandIDs = active
        let bindings = NSMapTable<NSMenuItem, BindingSet>.weakToStrongObjects()
        for (item, value) in planned.values { bindings.setObject(BindingSet(value), forKey: item) }
        itemBindings = bindings
        if assignedLayout == nil { assignedLayout = ShortcutKeys.keyboardLayoutID() }
        unavailableCommands = unavailable
        resumeLearning()
    }

    /// A recorded key is assigned as recorded: it was typed on the current layout, and must not be adapted again.
    private func apply(_ binding: ShortcutBinding, to command: ShortcutCommand) {
        command.item.allowsAutomaticKeyEquivalentLocalization = false
        command.item.keyEquivalent = ""
        command.item.keyEquivalentModifierMask = binding.modifiers
        command.item.keyEquivalent = binding.key
    }

    private func persist() {
        if overrides.isEmpty {
            defaults.removeObject(forKey: Self.overridesKey)
        } else {
            defaults.set(overrides.mapValues(\.propertyList), forKey: Self.overridesKey)
        }
    }

    // MARK: Conflicts

    /// The items with a key: as AppKit shows it now, or as the item had it at the last assignment.
    func menuMatches(_ binding: ShortcutBinding, excluding excluded: NSMenuItem? = nil) -> [ShortcutMatch] {
        guard !binding.key.isEmpty else { return [] }
        var matches: [ShortcutMatch] = []
        ShortcutKeys.visit(menu) { item, path in
            guard item !== excluded, item.submenu == nil, !item.keyEquivalent.isEmpty,
                  ShortcutKeys.shownBinding(item) == binding || itemBindings.object(forKey: item)?.bindings.contains(binding) == true else { return }
            matches.append(ShortcutMatch(path: path, item: item, command: commands.first { $0.item === item }, winner: matches.isEmpty))
        }
        return matches
    }

    func conflict(for binding: ShortcutBinding, except excluded: NSMenuItem?) -> String? {
        menuMatches(binding, excluding: excluded).last?.path
    }

    func conflictForRestoring(_ command: ShortcutCommand) -> String? {
        for binding in defaultBindings(for: command) {
            if let conflict = conflict(for: binding, except: command.item) { return conflict }
        }
        // Defaults may overlap in their physical spellings on a layout; only live custom keys take part.
        let custom = commands.filter { other in
            other.item !== command.item && !other.item.keyEquivalent.isEmpty
                && overrides[other.commandID] == ShortcutKeys.shownBinding(other.item)
        }
        guard !custom.isEmpty else { return nil }
        var spellings = Set<ShortcutBinding>()
        for binding in defaultBindings(for: command) {
            spellings.formUnion(ShortcutKeys.restorationBindings(key: binding.key, modifiers: binding.modifiers))
        }
        return custom.first { spellings.contains(ShortcutKeys.shownBinding($0.item)) }?.path
    }

    /// Returns an error message, or nil when the shortcut was assigned.
    func setKey(_ key: String, modifiers: NSEvent.ModifierFlags, for command: ShortcutCommand) -> String? {
        guard commands.contains(where: { $0 === command }) else { return NSLocalizedString("This command is no longer available.", comment: "") }
        guard ShortcutKeys.isAllowed(key: key, modifiers: modifiers) else {
            return NSLocalizedString("This key cannot be used as a shortcut. Use Command or Control with a key, or F1–F20.", comment: "")
        }
        let binding = ShortcutBinding(key, modifiers)
        // The default, as given or as this keyboard layout shows it, restores the command.
        if defaultBindings(for: command).contains(binding) { return restore(command) }
        if let conflict = conflict(for: binding, except: command.item) {
            return String(format: NSLocalizedString("This shortcut is already used by “%@”.", comment: ""), conflict)
        }
        overrides[command.commandID] = binding
        if !knowsKeysOfCurrentLayout && ShortcutKeys.layoutAdaptsKey(command.defaultKey) {
            recordedBeforeLayoutKeys[command.commandID] = ShortcutKeys.keyboardLayoutID()
        }
        applySavedOverrides()
        persist()
        return unavailableCommands.contains(command.path) ? NSLocalizedString("Shortcut Unavailable", comment: "") : nil
    }

    func restore(_ command: ShortcutCommand) -> String? {
        guard commands.contains(where: { $0 === command }) else { return NSLocalizedString("This command is no longer available.", comment: "") }
        if let conflict = conflictForRestoring(command) {
            return String(format: NSLocalizedString("This shortcut is already used by “%@”.", comment: ""), conflict)
        }
        if let saved = overrides[command.commandID], !knowsKeysOfCurrentLayout, ShortcutKeys.layoutAdaptsKey(command.defaultKey) {
            restoredBeforeLayoutKeys[command.commandID] = (saved, ShortcutKeys.keyboardLayoutID())
        }
        overrides[command.commandID] = nil
        applySavedOverrides()
        persist()
        return nil
    }

    func restoreAll() {
        overrides.removeAll()
        applySavedOverrides()
        persist()
    }

    var hasCustomShortcuts: Bool { !overrides.isEmpty }

    func isCustomized(_ command: ShortcutCommand) -> Bool { overrides[command.commandID] != nil }

    /// Menu items an event would trigger, in menu order; the first item with a primary spelling wins.
    func matches(for event: NSEvent) -> [ShortcutMatch] {
        let unshifted = event.charactersIgnoringModifiers(applying: [])
        var found: [ObjectIdentifier: ShortcutMatch] = [:]
        for binding in ShortcutKeys.eventBindings(event, unshifted: unshifted) {
            for match in menuMatches(binding) where !(match.item.isHidden && !match.item.allowsKeyEquivalentWhenHidden) {
                if found[ObjectIdentifier(match.item)] == nil { found[ObjectIdentifier(match.item)] = match }
            }
        }
        let primary = [ShortcutKeys.recordedBinding(event, unshifted: unshifted), ShortcutBinding(ShortcutKeys.character(for: event), event.modifierFlags)]
        var ordered: [ShortcutMatch] = []
        var winner: ObjectIdentifier?
        var winningTier = Int.max
        ShortcutKeys.visit(menu) { item, _ in
            guard let match = found[ObjectIdentifier(item)] else { return }
            ordered.append(match)
            let tier = primary.contains(ShortcutBinding(item.keyEquivalent, item.keyEquivalentModifierMask)) ? 0 : 1
            if tier < winningTier {
                winner = ObjectIdentifier(item)
                winningTier = tier
            }
        }
        return ordered.map { ShortcutMatch(path: $0.path, item: $0.item, command: $0.command, winner: ObjectIdentifier($0.item) == winner) }
    }
}

private extension NSEvent {
    func charactersIgnoringModifiers(applying flags: NSEvent.ModifierFlags) -> String? {
        characters(byApplyingModifiers: flags)
    }
}
