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
    let defaultKey: String
    let defaultModifiers: NSEvent.ModifierFlags
    let defaultLocalization: Bool

    init(item: NSMenuItem, identifier: String, path: String) {
        self.item = item
        commandID = identifier
        self.path = path
        defaultKey = item.keyEquivalent
        defaultModifiers = item.keyEquivalentModifierMask
        defaultLocalization = item.allowsAutomaticKeyEquivalentLocalization
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

    /// Visits every item of a menu with its path ("File › Save"), skipping the Services menu.
    static func visit(_ menu: NSMenu?, path: String = "", _ body: (NSMenuItem, String) -> Void) {
        guard let menu else { return }
        for item in menu.items {
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
final class ShortcutStore {
    static let overridesKey = "MenuShortcutOverrides"

    let menu: NSMenu
    let defaults: UserDefaults
    private var overrides: [String: ShortcutBinding] = [:]
    private(set) var commands: [ShortcutCommand] = []
    private(set) var unavailableCommands: [String] = []

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
        applySavedOverrides()
    }

    /// Assignments that collide with another menu key stay inactive, as in TeXShop.
    private func applySavedOverrides() {
        var active = Set(commands.filter { overrides[$0.commandID] != nil }.map(\.commandID))
        var unavailable: [String] = []
        func markUnavailable(_ path: String) { if !unavailable.contains(path) { unavailable.append(path) } }
        var planned: [ObjectIdentifier: (NSMenuItem, ShortcutBinding)] = [:]
        var changed: Bool
        repeat {
            changed = false
            planned.removeAll()
            ShortcutKeys.visit(menu) { item, _ in
                if item.submenu == nil { planned[ObjectIdentifier(item)] = (item, ShortcutBinding(item.keyEquivalent, item.keyEquivalentModifierMask)) }
            }
            for command in commands {
                let value = active.contains(command.commandID) ? overrides[command.commandID]! : ShortcutBinding(command.defaultKey, command.defaultModifiers)
                planned[ObjectIdentifier(command.item)] = (command.item, value)
            }
            var rejected = Set<String>()
            for command in commands where active.contains(command.commandID) {
                guard let value = planned[ObjectIdentifier(command.item)]?.1, !value.key.isEmpty else { continue }
                if planned.values.contains(where: { $0.0 !== command.item && $0.1 == value }) {
                    rejected.insert(command.commandID)
                    markUnavailable(command.path)
                }
            }
            if !rejected.isEmpty {
                active.subtract(rejected)
                changed = true
            }
        } while changed
        // Avoid transient duplicates when restoring defaults or swapping two saved bindings.
        for command in commands { command.item.keyEquivalent = "" }
        for command in commands {
            if active.contains(command.commandID), let binding = overrides[command.commandID] {
                command.item.allowsAutomaticKeyEquivalentLocalization = false
                command.item.keyEquivalentModifierMask = binding.modifiers
                command.item.keyEquivalent = binding.key
            } else {
                command.item.allowsAutomaticKeyEquivalentLocalization = command.defaultLocalization
                command.item.keyEquivalentModifierMask = command.defaultModifiers
                command.item.keyEquivalent = command.defaultKey
            }
        }
        for command in commands where active.contains(command.commandID) {
            if ShortcutBinding(command.item.keyEquivalent, command.item.keyEquivalentModifierMask) != planned[ObjectIdentifier(command.item)]?.1 {
                markUnavailable(command.path)
            }
        }
        unavailableCommands = unavailable
    }

    private func persist() {
        if overrides.isEmpty {
            defaults.removeObject(forKey: Self.overridesKey)
        } else {
            defaults.set(overrides.mapValues(\.propertyList), forKey: Self.overridesKey)
        }
    }

    func menuMatches(_ binding: ShortcutBinding, excluding excluded: NSMenuItem? = nil) -> [ShortcutMatch] {
        guard !binding.key.isEmpty else { return [] }
        var matches: [ShortcutMatch] = []
        ShortcutKeys.visit(menu) { item, path in
            guard item !== excluded, item.submenu == nil, !item.keyEquivalent.isEmpty,
                  ShortcutBinding(item.keyEquivalent, item.keyEquivalentModifierMask) == binding else { return }
            matches.append(ShortcutMatch(path: path, item: item, command: commands.first { $0.item === item }, winner: matches.isEmpty))
        }
        return matches
    }

    func conflict(for binding: ShortcutBinding, except excluded: NSMenuItem?) -> String? {
        menuMatches(binding, excluding: excluded).last?.path
    }

    func conflictForRestoring(_ command: ShortcutCommand) -> String? {
        let binding = ShortcutBinding(command.defaultKey, command.defaultModifiers)
        if let conflict = conflict(for: binding, except: command.item) { return conflict }
        // Defaults may overlap in their physical spellings on a layout; only live custom keys take part.
        let custom = commands.filter { other in
            other.item !== command.item && !other.item.keyEquivalent.isEmpty
                && overrides[other.commandID] == ShortcutBinding(other.item.keyEquivalent, other.item.keyEquivalentModifierMask)
        }
        guard !custom.isEmpty else { return nil }
        let spellings = ShortcutKeys.restorationBindings(key: command.defaultKey, modifiers: command.defaultModifiers)
        return custom.first { spellings.contains(ShortcutBinding($0.item.keyEquivalent, $0.item.keyEquivalentModifierMask)) }?.path
    }

    /// Returns an error message, or nil when the shortcut was assigned.
    func setKey(_ key: String, modifiers: NSEvent.ModifierFlags, for command: ShortcutCommand) -> String? {
        guard commands.contains(where: { $0 === command }) else { return NSLocalizedString("This command is no longer available.", comment: "") }
        guard ShortcutKeys.isAllowed(key: key, modifiers: modifiers) else {
            return NSLocalizedString("This key cannot be used as a shortcut. Use Command or Control with a key, or F1–F20.", comment: "")
        }
        let binding = ShortcutBinding(key, modifiers)
        if binding == ShortcutBinding(command.defaultKey, command.defaultModifiers) { return restore(command) }
        if let conflict = conflict(for: binding, except: command.item) {
            return String(format: NSLocalizedString("This shortcut is already used by “%@”.", comment: ""), conflict)
        }
        overrides[command.commandID] = binding
        applySavedOverrides()
        persist()
        return unavailableCommands.contains(command.path) ? NSLocalizedString("Shortcut Unavailable", comment: "") : nil
    }

    func restore(_ command: ShortcutCommand) -> String? {
        guard commands.contains(where: { $0 === command }) else { return NSLocalizedString("This command is no longer available.", comment: "") }
        if let conflict = conflictForRestoring(command) {
            return String(format: NSLocalizedString("This shortcut is already used by “%@”.", comment: ""), conflict)
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
