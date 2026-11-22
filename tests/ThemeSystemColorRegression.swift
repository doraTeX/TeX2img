import AppKit

// The selection color of themes and the "Use system color" switches of the cursor and the selection (TeXShop 6.00):
// how a switch is read, the color drawn, the comparison of a copy with its bundled theme, and the bundled themes.
// Run through tests/test_theme_system_colors.py with the bundled themes' folder as the argument. No window is shown.

var failures = 0
func check(_ ok: Bool, _ message: String) {
    if !ok { failures += 1; FileHandle.standardError.write("FAIL: \(message)\n".data(using: .utf8)!) }
}
func rgb(_ color: NSColor) -> [Int] {
    let c = color.usingColorSpace(.sRGB)!
    return [c.redComponent, c.greenComponent, c.blueComponent].map { Int(($0 * 255).rounded()) }
}

let red: [Any] = [1, 0, 0, 1], green: [Any] = [0, 1, 0, 1]
let cursorKey = ThemeSystemColor.key(.cursor)!, selectionKey = ThemeSystemColor.key(.selection)!
check(cursorKey == "EditorInsertionPointUsesSystemColor" && selectionKey == "EditorSelectionUsesSystemColor", "switch keys as TeXShop")
check(ThemeRole.selection.key == "EditorSelection" && !ThemeRole.selection.usesOpacity, "selection key, opaque")

// A switch: its number; anything else, or nothing, reads as before the switches (theme cursor, system selection).
for (role, key, before) in [(ThemeRole.cursor, cursorKey, false), (.selection, selectionKey, true)] {
    check(ThemeSystemColor.uses(role, in: nil) == before && ThemeSystemColor.uses(role, in: [:]) == before, "\(key) missing")
    for value: Any in ["YES", [1], ["a": 1], Data()] { check(ThemeSystemColor.uses(role, in: [key: value]) == before, "\(key) not a number") }
    check(ThemeSystemColor.uses(role, in: [key: true]) && !ThemeSystemColor.uses(role, in: [key: false]), "\(key) bool")
    check(ThemeSystemColor.uses(role, in: [key: 1]) && !ThemeSystemColor.uses(role, in: [key: 0]), "\(key) integer")
}
check(!ThemeSystemColor.uses(.text, in: [cursorKey: true]), "other roles have no switch")

// The color drawn.
for dark in [false, true] {
    let theme: ThemeColors = ["EditorInsertionPoint": red, "EditorSelection": green]
    check(rgb(ThemePalette.drawnColor(.cursor, in: theme, dark: dark)) == [255, 0, 0], "theme cursor without the switch")
    check(ThemePalette.drawnColor(.selection, in: theme, dark: dark) === NSColor.selectedTextBackgroundColor, "system selection without the switch")
    var on = theme; on[cursorKey] = true; on[selectionKey] = true
    check(ThemePalette.drawnColor(.cursor, in: on, dark: dark) === ThemeSystemColor.systemColor(.cursor)!, "system cursor with the switch")
    var off = theme; off[cursorKey] = false; off[selectionKey] = false
    check(rgb(ThemePalette.drawnColor(.selection, in: off, dark: dark)) == [0, 255, 0], "theme selection with the switch off")
    check(rgb(ThemePalette.drawnColor(.selection, in: [selectionKey: false], dark: dark)) == (dark ? [0x3F, 0x63, 0x8B] : [0xB3, 0xD7, 0xFF]), "built-in selection")
    check(rgb(ThemePalette.drawnColor(.text, in: on, dark: dark)) == rgb(ThemePalette.color(.text, in: on, dark: dark)), "other roles drawn as before")
}

// A text view keeps its other selection attributes when the selection color is set, the system's included.
let view = NSTextView(frame: NSRect(x: 0, y: 0, width: 100, height: 40))
view.selectedTextAttributes = [.foregroundColor: NSColor.orange, .backgroundColor: NSColor.yellow]
ThemeSystemColor.setSelectionColor(.green, of: view)
check(view.selectedTextAttributes[.backgroundColor] as? NSColor == .green, "theme selection set")
ThemeSystemColor.setSelectionColor(.selectedTextBackgroundColor, of: view)
check(view.selectedTextAttributes[.backgroundColor] as? NSColor === NSColor.selectedTextBackgroundColor, "system selection set again")
check(view.selectedTextAttributes[.foregroundColor] as? NSColor == .orange, "other attributes kept")

// A copy of a bundled theme from before the switches is not "changed"; a changed switch or color is.
let bundled: ThemeColors = ["Title": "B", "EditorText": red, "EditorSelection": green, cursorKey: false, selectionKey: true]
let older: ThemeColors = ["Title": "B", "EditorText": red]
check(ThemePalette.sameSharedColors(older, bundled), "an earlier copy is the bundled theme")
check(!ThemePalette.sameSharedColors(["EditorText": red, selectionKey: false], bundled), "a switch turned off is a change")
check(!ThemePalette.sameSharedColors(["EditorText": green], bundled), "a color is a change")
check(!ThemePalette.sameUsedColors(["EditorText": red, selectionKey: false], ["EditorText": red]), "a TeXShop theme with another switch is importable")

// The bundled themes.
let folder = URL(fileURLWithPath: CommandLine.arguments[1])
let chosen = ["LiteTheme": "B3D7FF", "GLG-Lite": "B3D7FF", "Manteuffel": "B3D7FF", "TransparentTheme": "B3D7FF", "SolarizedLite": "B3D7FF",
              "DarkTheme": "3F638B", "PreTeXt-Dark": "3F638B", "Dracula": "44475A", "SolarizedDark": "274642",
              "TeX2img Lite": "B3D7FF", "TeX2img Dark": "264F78"]
let store = ThemeStore(directory: folder)
check(Set(store.titles()) == Set(chosen.keys), "the bundled themes: \(store.titles())")
for (title, hex) in chosen {
    guard let theme = store.read(title: title) else { check(false, "\(title) readable"); continue }
    check(theme[cursorKey] as? Bool == false && theme[selectionKey] as? Bool == true, "\(title) switches")
    let c = ThemePalette.components(theme, key: "EditorSelection") ?? []
    check(c.count == 4 && c[3] == 1 && c.prefix(3).map { String(format: "%02X", Int(($0 * 255).rounded())) }.joined() == hex, "\(title) selection \(c)")
}
if failures == 0 { print("PASS: theme selection color and system color switches") }
exit(failures == 0 ? 0 : 1)
