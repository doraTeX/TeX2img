import AppKit
import Carbon.HIToolbox

// Menu shortcuts on French and German keyboard layouts, matched by AppKit's own dispatch (TeXShop 6.00, reported by
// Bruno Voisin). It switches keyboard layouts, so it runs only in a VM: tests/test_shortcut_keyboard_layouts.py builds it
// and runs it over ssh with TEX2IMG_ALLOW_LAYOUT_SWITCH=1. The argument is the menu fixture made from MainMenu.xib.
// The layouts it turned on are turned off again, and ABC is selected at the end.

let abc = "com.apple.keylayout.ABC", french = "com.apple.keylayout.French", german = "com.apple.keylayout.German"
var enabledHere = Set<String>()
var failures = 0

func source(_ identifier: String) -> TISInputSource? {
    let list = TISCreateInputSourceList([kTISPropertyInputSourceID as String: identifier] as CFDictionary, true)?.takeRetainedValue()
    guard let list, CFArrayGetCount(list) > 0 else { return nil }
    return Unmanaged<TISInputSource>.fromOpaque(CFArrayGetValueAtIndex(list, 0)).takeUnretainedValue()
}
func spin(_ seconds: TimeInterval) { RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds)) }
func select(_ identifier: String, wait: TimeInterval = 0.6) {
    guard let source = source(identifier) else { fail("no input source \(identifier)"); return }
    let enabled = (TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled)).map {
        Unmanaged<CFBoolean>.fromOpaque($0).takeUnretainedValue() == kCFBooleanTrue
    } ?? false
    if !enabled { TISEnableInputSource(source); enabledHere.insert(identifier) }
    TISSelectInputSource(source)
    spin(wait)
}
func restoreLayouts() {
    if let source = source(abc) { TISSelectInputSource(source) }
    for identifier in enabledHere { if let source = source(identifier) { TISDisableInputSource(source) } }
}
func currentLayout() -> String {
    guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
          let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return "" }
    return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
}
func fail(_ message: String) {
    failures += 1
    FileHandle.standardError.write("FAIL: \(message)\n".data(using: .utf8)!)
}
func require(_ ok: Bool, _ message: @autoclosure () -> String) { if !ok { fail(message()) } }
func describe(_ binding: ShortcutBinding) -> String { "\(binding.key) \(String(binding.modifiers.rawValue, radix: 16))" }
func shown(_ item: NSMenuItem) -> ShortcutBinding { ShortcutBinding(item.keyEquivalent, item.keyEquivalentModifierMask) }

final class Target: NSObject, NSMenuItemValidation {
    var last: NSMenuItem?
    @objc func fixture(_ sender: NSMenuItem) { last = sender }
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool { true }
}
let target = Target()
var window: NSWindow!
var fixture: [[String: Any]] = []

/// TeX2img's menu commands with the keys MainMenu.xib gives them.
func buildMenu() -> NSMenu {
    let main = NSMenu()
    main.addItem(withTitle: "App", action: nil, keyEquivalent: "").submenu = NSMenu()
    let top = main.addItem(withTitle: "Commands", action: nil, keyEquivalent: "")
    top.submenu = NSMenu(title: "Commands")
    for entry in fixture {
        let item = NSMenuItem(title: entry["identifier"] as! String, action: #selector(Target.fixture(_:)), keyEquivalent: "")
        item.identifier = NSUserInterfaceItemIdentifier(entry["identifier"] as! String)
        item.target = target
        item.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: (entry["modifiers"] as! NSNumber).uintValue)
        item.keyEquivalent = entry["key"] as! String
        top.submenu!.addItem(item)
    }
    return main
}
func item(_ main: NSMenu, _ identifier: String) -> NSMenuItem? {
    main.items[1].submenu!.items.first { $0.identifier?.rawValue == identifier }
}
func command(_ store: ShortcutStore, _ identifier: String) -> ShortcutCommand? {
    store.commands.first { $0.commandID == identifier }
}

/// A key press as the current layout types the character with these modifiers, or nil.
func keyPress(_ character: String, _ flags: NSEvent.ModifierFlags) -> NSEvent? {
    guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
          let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
    let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue()
    func characters(_ code: UInt16, _ flags: NSEvent.ModifierFlags) -> String {
        var state = 0
        if flags.contains(.command) { state |= cmdKey }
        if flags.contains(.shift) { state |= shiftKey }
        if flags.contains(.option) { state |= optionKey }
        if flags.contains(.control) { state |= controlKey }
        return ShortcutKeys.translate(data, keyCode: code, modifierState: UInt32(state >> 8), keyboardType: UInt32(LMGetKbdType())) ?? ""
    }
    for code in UInt16(0)..<128 {
        for shift in [false, true] {
            let plain = characters(code, shift ? .shift : [])
            guard plain == character else { continue }
            let modifiers = shift ? flags.union(.shift) : flags
            return NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers,
                                    timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil,
                                    characters: characters(code, modifiers), charactersIgnoringModifiers: plain, isARepeat: false, keyCode: code)
        }
    }
    return nil
}
/// The item AppKit runs for the key press that types this key on the current layout.
func dispatch(_ binding: ShortcutBinding) -> NSMenuItem? {
    // A capital letter or a shifted symbol in a key equivalent is typed with Shift.
    var event = keyPress(binding.key, binding.modifiers.subtracting(.shift))
    if let e = event, binding.modifiers.contains(.shift), !e.modifierFlags.contains(.shift) { event = nil }
    if event == nil { event = keyPress(binding.key, binding.modifiers) }
    guard let event else { return nil }
    target.last = nil
    NSApp.sendEvent(event)
    spin(0.05)
    return target.last
}
/// Keys AppKit shows for the menu on this layout with no shortcut store, and the items whose shown key runs them.
func referenceKeys() -> ([String: ShortcutBinding], Set<String>) {
    let main = buildMenu()
    NSApp.mainMenu = main
    spin(0.3)
    var keys: [String: ShortcutBinding] = [:], runs = Set<String>()
    for item in main.items[1].submenu!.items {
        let binding = shown(item)
        keys[item.identifier!.rawValue] = binding
        if let c = binding.key.utf16.first, c < 0xf700, dispatch(binding) === item { runs.insert(item.identifier!.rawValue) }
    }
    return (keys, runs)
}
var checkedKeys = 0
func checkLikeReference(_ main: NSMenu, _ reference: [String: ShortcutBinding], _ runs: Set<String>, _ stage: String, except: Set<String> = []) {
    let layout = currentLayout()
    for item in main.items[1].submenu!.items {
        let identifier = item.identifier!.rawValue
        guard !except.contains(identifier), let expected = reference[identifier] else { continue }
        require(shown(item) == expected, "\(stage) on \(layout): \(identifier) shows \(describe(shown(item))), AppKit shows \(describe(expected)) for the xib's key")
        guard runs.contains(identifier) else { continue }
        let ran = dispatch(expected)
        require(ran === item, "\(stage) on \(layout): the key \(describe(expected)) shown for \(identifier) runs \(ran?.identifier?.rawValue ?? "nothing")")
        checkedKeys += 1
    }
}

@main
struct Probe {
    static func main() {
        guard ProcessInfo.processInfo.environment["TEX2IMG_ALLOW_LAYOUT_SWITCH"] == "1" else {
            FileHandle.standardError.write("Refusing to switch keyboard layouts here; run this in a VM with TEX2IMG_ALLOW_LAYOUT_SWITCH=1.\n".data(using: .utf8)!)
            exit(2)
        }
        fixture = NSArray(contentsOfFile: CommandLine.arguments[1]) as! [[String: Any]]
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.finishLaunching()
        window = NSWindow(contentRect: NSRect(x: 80, y: 80, width: 240, height: 120), styleMask: .titled, backing: .buffered, defer: false)
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)
        spin(0.5)
        // exit() skips defer: every way out goes through finish. The store's settings live in memory (MemoryDefaults).
        func finish(_ code: Int32) -> Never {
            restoreLayouts()
            spin(0.3)
            exit(code)
        }
        let insertMark = "TSShortcut.placeBullet:.0", jump = "TSShortcut.centerSelectionInVisibleArea:.0"
        var references: [String: [String: ShortcutBinding]] = [:], runsByLayout: [String: Set<String>] = [:]
        for layout in [abc, french, german] {
            select(layout)
            let (keys, runs) = referenceKeys()
            references[layout] = keys
            runsByLayout[layout] = runs
            require(runs.count > fixture.count / 2, "\(runs.count) of \(fixture.count) keys run their command on \(layout) without a store")
        }
        let french8 = references[french]![insertMark]!
        require(french8 != ShortcutBinding("8", .command), "AppKit adapts Command-8 on French (shows \(describe(french8)))")
        print("French shows \(describe(french8)) for Insert Mark (Command-8 in the xib)")

        for layout in [french, german, abc] {
            select(layout)
            let reference = references[layout]!, runs = runsByLayout[layout]!
            // As at launch: the menu is in place and AppKit has adapted its keys before the store starts.
            let main = buildMenu()
            NSApp.mainMenu = main
            spin(0.3)
            let store = ShortcutStore(menu: main, defaults: MemoryDefaults())
            spin(0.3)
            checkLikeReference(main, reference, runs, "store started")
            // The keys AppKit shows on this layout, worked out once, give every default as shown.
            var learned: Bool?
            store.learnLayoutKeys { learned = $0 }
            spin(0.3)
            require(learned != nil, "keys of \(layout) worked out")
            for command in store.commands {
                guard let expected = reference[command.commandID] else { continue }
                let worked = store.shownBinding(givenKey: command.defaultKey, modifiers: command.defaultModifiers)
                require(worked == expected, "\(command.commandID) on \(layout): the layout's keys give \(describe(worked)) for the xib's key, AppKit shows \(describe(expected))")
                require(store.shownDefault(for: command) == expected, "\(command.commandID) on \(layout): shown default \(describe(store.shownDefault(for: command)))")
            }
            checkLikeReference(main, reference, runs, "keys worked out")
            // The key 5.60's store gave Insert Mark on French: AppKit adapted the ! it read back once more.
            if layout == french, let insert = item(main, insertMark) {
                require(dispatch(ShortcutBinding("1", .command)) !== insert, "Command-1 runs Insert Mark on French")
            }
            store.refreshMenu()
            spin(0.3)
            checkLikeReference(main, reference, runs, "menu refreshed")
            guard let mark = command(store, insertMark), let jumpCommand = command(store, jump) else { fail("fixture commands are in the store"); continue }
            require(mark.defaultKey == "8" && mark.defaultModifiers == .command,
                    "Insert Mark default on \(layout) is \(mark.defaultKey) \(String(mark.defaultModifiers.rawValue, radix: 16)), the xib gives Command-8")
            // Another key for Jump to Selection, and back: the other defaults stay as they were.
            require(store.setKey("j", modifiers: [.command, .control], for: jumpCommand) == nil, "assigning Control-Command-J on \(layout)")
            // The other items are left alone: right away, before AppKit adapts anything again, they show their keys.
            for other in main.items[1].submenu!.items where other.identifier?.rawValue != jump {
                if let expected = reference[other.identifier!.rawValue] {
                    require(shown(other) == expected, "right after another command is assigned on \(layout): \(other.identifier!.rawValue) shows \(describe(shown(other))), not \(describe(expected))")
                }
            }
            spin(0.3)
            checkLikeReference(main, reference, runs, "other command assigned", except: [jump])
            require(dispatch(ShortcutBinding("j", [.command, .control])) === jumpCommand.item, "Control-Command-J runs Jump to Selection on \(layout)")
            require(store.restore(jumpCommand) == nil, "restoring Jump to Selection on \(layout)")
            spin(0.3)
            checkLikeReference(main, reference, runs, "command restored")
            // Insert Mark gets another key; recording the key the layout shows for its default restores the default.
            require(store.setKey("k", modifiers: [.command, .control], for: mark) == nil, "assigning to Insert Mark on \(layout)")
            spin(0.3)
            let shownDefault = reference[insertMark]!
            require(store.setKey(shownDefault.key, modifiers: shownDefault.modifiers, for: mark) == nil, "recording the shown default on \(layout)")
            require(!store.isCustomized(mark), "recording \(describe(shownDefault)) on \(layout) kept an override instead of the default")
            spin(0.3)
            checkLikeReference(main, reference, runs, "default recorded again")
            // The key that another command shows on this layout is taken, and so is the key it was given.
            for taken in [shownDefault, ShortcutBinding(mark.defaultKey, mark.defaultModifiers)] {
                // Refused as Insert Mark's key, not assigned and then found unavailable.
                let error = store.setKey(taken.key, modifiers: taken.modifiers, for: jumpCommand)
                require(error?.contains("placeBullet:") == true && !store.isCustomized(jumpCommand),
                        "\(describe(taken)) of Insert Mark on \(layout) given to Jump to Selection too: \(error ?? "assigned")")
                spin(0.3)
            }
            store.restoreAll()
            spin(0.3)
            checkLikeReference(main, reference, runs, "all restored")
        }

        // Layouts switched while the app runs: the defaults follow the layout, a recorded key stays as recorded.
        select(french)
        let main = buildMenu()
        NSApp.mainMenu = main
        spin(0.3)
        let store = ShortcutStore(menu: main, defaults: MemoryDefaults())
        spin(0.3)
        if let jumpCommand = command(store, jump) {
            require(store.setKey("é", modifiers: [.command, .control], for: jumpCommand) == nil, "recording Control-Command-é on French")
        }
        for layout in [german, abc, french] {
            select(layout, wait: 0.8)
            checkLikeReference(main, references[layout]!, runsByLayout[layout]!, "switched to", except: [jump])
            if let jumpItem = item(main, jump) {
                require(shown(jumpItem) == ShortcutBinding("é", [.command, .control]), "recorded key stays on \(layout): \(describe(shown(jumpItem)))")
            }
        }
        print("checked \(checkedKeys) key presses")
        if failures > 0 { FileHandle.standardError.write("\(failures) failure(s)\n".data(using: .utf8)!); finish(1) }
        print("PASS: menu shortcuts on ABC, French and German")
        finish(0)
    }
}
