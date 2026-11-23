import AppKit

// The colors a theme lacks of text and what it is drawn on (TeXShop 6.00): a missing color of the source (text,
// background, cursor) or of the output window (text, background) is chosen so that its pairs read, nearest the default
// colors. Run through tests/test_theme_pairs.py with the bundled themes' folder as the argument. No window is shown.

var failures = 0
func check(_ ok: Bool, _ message: String) {
    if !ok { failures += 1; FileHandle.standardError.write("FAIL: \(message)\n".data(using: .utf8)!) }
}
func rgb(_ color: NSColor) -> [Int] {
    let c = color.usingColorSpace(.sRGB)!
    return [c.redComponent, c.greenComponent, c.blueComponent].map { Int(($0 * 255).rounded()) }
}
func drawn(_ role: ThemeRole, _ theme: ThemeColors?, _ dark: Bool) -> NSColor { ThemePalette.color(role, in: theme, dark: dark) }
func contrast(_ a: ThemeRole, _ b: ThemeRole, _ theme: ThemeColors?, _ dark: Bool) -> Double {
    ThemePairs.contrast(drawn(a, theme, dark), drawn(b, theme, dark))
}
func gray(_ v: Double) -> [Any] { [v, v, v, 1] }
let reads = 4.5 - 1e-6

// A theme with all its colors: they are drawn as they are, however little they read.
let full: ThemeColors = ["EditorText": gray(0.5), "EditorBackground": gray(0.55), "EditorInsertionPoint": gray(0.6),
                         "ConsoleText": gray(0.2), "ConsoleBackground": gray(0.25)]
for dark in [false, true] {
    check(rgb(drawn(.text, full, dark)) == [128, 128, 128] && rgb(drawn(.background, full, dark)) == [140, 140, 140]
          && rgb(drawn(.cursor, full, dark)) == [153, 153, 153], "own colors kept (dark \(dark))")
    check(rgb(drawn(.consoleText, full, dark)) == [51, 51, 51] && rgb(drawn(.consoleBackground, full, dark)) == [64, 64, 64],
          "own console colors kept (dark \(dark))")
}

// No theme, or an empty one: the default colors of the mode, which read.
for theme in [nil, ThemeColors()] as [ThemeColors?] {
    for dark in [false, true] {
        for role in [ThemeRole.text, .background, .cursor, .consoleText, .consoleBackground] {
            check(rgb(drawn(role, theme, dark)) == rgb(ThemePalette.defaultColor(role, dark: dark)),
                  "\(role) of an empty theme is the default (dark \(dark))")
        }
    }
}

// The text lost on a dark background in a light window: not the default black, but a color that reads, the default of
// the dark mode first.
let darkBackground: ThemeColors = ["EditorBackground": [0.157, 0.165, 0.212, 1], "EditorInsertionPoint": [0.97, 0.97, 0.95, 1],
                                   "ConsoleBackground": [0.157, 0.165, 0.212, 1]]
check(contrast(.text, .background, darkBackground, false) >= reads, "text lost on a dark background reads in a light window")
check(rgb(drawn(.text, darkBackground, false)) == rgb(ThemePalette.defaultColor(.text, dark: true)),
      "the default text of the dark mode is taken: \(rgb(drawn(.text, darkBackground, false)))")
check(contrast(.consoleText, .consoleBackground, darkBackground, false) >= reads, "console text lost on a dark background reads")
// And in a dark window the default of the mode itself, which reads.
check(rgb(drawn(.text, darkBackground, true)) == rgb(ThemePalette.defaultColor(.text, dark: true)), "the default text in a dark window")

// The background lost under pale text in a light window: dark enough for the text and the cursor.
let paleText: ThemeColors = ["EditorText": [0.97, 0.97, 0.95, 1], "EditorInsertionPoint": [0.97, 0.97, 0.95, 1]]
check(contrast(.text, .background, paleText, false) >= reads && contrast(.cursor, .background, paleText, false) >= reads,
      "background lost under pale text reads in a light window: \(rgb(drawn(.background, paleText, false)))")
// The default background of the mode when it reads.
let blackText: ThemeColors = ["EditorText": [0, 0, 0, 1], "EditorInsertionPoint": [0, 0, 0, 1]]
check(rgb(drawn(.background, blackText, false)) == rgb(ThemePalette.defaultColor(.background, dark: false)), "default background kept")

// The cursor lost: it reads on the theme's background.
let noCursor: ThemeColors = ["EditorText": [0.9, 0.9, 0.9, 1], "EditorBackground": [0.1, 0.1, 0.1, 1]]
check(contrast(.cursor, .background, noCursor, false) >= reads, "the cursor lost reads on a dark background in a light window")

// The cursor lost on a theme whose own text does not read on its own background: the pair of the theme's own colors
// does not count, and the cursor is the default of the other mode, the first choice that reads.
let ownPairPoor: ThemeColors = ["EditorText": gray(0.5), "EditorBackground": gray(0.55)]
check(rgb(drawn(.cursor, ownPairPoor, true)) == rgb(ThemePalette.defaultColor(.cursor, dark: false)),
      "the cursor on a poor pair of own colors: \(rgb(drawn(.cursor, ownPairPoor, true)))")
check(contrast(.cursor, .background, ownPairPoor, true) >= reads, "that cursor reads")

// Text and cursor that read only on a middle gray: the background lost becomes a gray on which both read.
let middle: ThemeColors = ["EditorText": [0, 0, 0, 1], "EditorInsertionPoint": [1, 1, 1, 1]]
let middleBackground = drawn(.background, middle, false)
check(contrast(.text, .background, middle, false) >= reads && contrast(.cursor, .background, middle, false) >= reads,
      "black text and white cursor both read on the gray chosen: \(rgb(middleBackground))")
// Text and cursor of the user's own that read only on a gray between two of the 64 steps.
// (Black text and a cursor of luminance 0.975: the background must lie between 0.175 and 0.178, between the grays 28/63
// and 29/63.)
let narrow: ThemeColors = ["EditorText": [0, 0, 0, 1], "EditorInsertionPoint": [0.989, 0.989, 0.989, 1]]
check(contrast(.text, .background, narrow, true) >= reads && contrast(.cursor, .background, narrow, true) >= reads,
      "narrow range solved with a gray: \(rgb(drawn(.background, narrow, true)))")
// No background can make both read: the text reads, the cursor as well as it can.
let impossible: ThemeColors = ["EditorText": [0.45, 0.45, 0.45, 1], "EditorInsertionPoint": [0.5, 0.5, 0.5, 1]]
check(contrast(.text, .background, impossible, false) >= reads, "the text reads first")
check(contrast(.cursor, .background, impossible, false) > 2.5, "the cursor reads as well as it can besides")

// Text and background both lost under a theme's cursor: all three read together.
let cursorOnly: ThemeColors = ["EditorInsertionPoint": [1, 1, 1, 1]]
for dark in [false, true] {
    check(contrast(.text, .background, cursorOnly, dark) >= reads && contrast(.cursor, .background, cursorOnly, dark) >= reads,
          "a white cursor alone: text and cursor read (dark \(dark))")
}

// The source and the output window are chosen apart: a theme whose two backgrounds are black and which lacks the text and
// the cursor gets a cursor that reads, whichever color is asked for first.
let blackBackgrounds: ThemeColors = ["EditorBackground": [0, 0, 0, 1], "ConsoleBackground": [0, 0, 0, 1]]
_ = drawn(.consoleText, blackBackgrounds, false)
check(contrast(.cursor, .background, blackBackgrounds, false) >= reads, "the cursor after the output window's text was asked for")
check(contrast(.consoleText, .consoleBackground, blackBackgrounds, false) >= reads, "the output window's text")

// The fullwidth colors a theme lacks follow the text and the background drawn.
check(rgb(drawn(.fullwidthSymbol, darkBackground, false)) == rgb(drawn(.text, darkBackground, false)), "fullwidth text follows the text")

// The theme is not changed, and the same choice comes again.
let before = NSDictionary(dictionary: darkBackground)
_ = drawn(.text, darkBackground, false)
check(NSDictionary(dictionary: darkBackground).isEqual(to: before as! [AnyHashable: Any]), "the theme is not changed")
check(rgb(drawn(.background, paleText, false)) == rgb(drawn(.background, paleText, false)), "the same choice again")

// The bundled themes have every color of the pairs: they are drawn as stored.
let folder = URL(fileURLWithPath: CommandLine.arguments[1])
let names = try! FileManager.default.contentsOfDirectory(atPath: folder.path).filter { $0.hasSuffix(".plist") }
check(names.count >= 11, "bundled themes found: \(names.count)")
for name in names {
    let theme = NSDictionary(contentsOf: folder.appendingPathComponent(name)) as! ThemeColors
    for role in [ThemeRole.text, .background, .cursor, .consoleText, .consoleBackground] {
        guard let own = ThemePalette.color(theme, key: role.key) else { check(false, "\(name) lacks \(role.key)"); continue }
        for dark in [false, true] { check(rgb(drawn(role, theme, dark)) == rgb(own), "\(name) \(role) drawn as stored") }
    }
}

if failures > 0 { FileHandle.standardError.write("\(failures) failure(s)\n".data(using: .utf8)!); exit(1) }
print("Theme pairs: all checks passed")
