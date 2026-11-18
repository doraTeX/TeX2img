import AppKit

// Runs the product's TeXTextView (the source and the preamble) in windows that are never shown, with a stand-in for
// ControllerG, and checks that a change of the theme or of one of its colors, and a change of the appearance, keep the
// highlight of the braces and of the enclosed contents, drawn in the new colors, with the switch of fullwidth letters
// and symbols on and off (user's decision 11-18: a theme is adjusted while looking at the highlights).
// Run through tests/test_theme_change_highlight.py.

final class ControllerG: NSObject, DnDDelegate {
    var commandCompletionList: String?
    var sourceTextView: TeXTextView!
    var preambleTextView: TeXTextView!
    func recolorOutputView() {}
    // @@CONTROLLER ACTIONS@@
    let makeatletterEnabledCheckBox = NSSwitch()
    var profile: Profile = [:]
    func currentProfile() -> Profile { profile }
    func showTabCharacterEnabled() -> Bool { false }
    func showNewLineCharacterEnabled() -> Bool { false }
    func showFullwidthSpaceCharacterEnabled() -> Bool { false }
    func showSpaceCharacterEnabled() -> Bool { false }
    func spaceCharacter() -> String { "␣" }
    func fullwidthSpaceCharacter() -> String { "□" }
    func returnCharacter() -> String { "↵" }
    func tabCharacter() -> String { "‣" }
    func invisibleColor() -> NSColor { .orange }
    @discardableResult func importSource(fromFilePathOrPDFDocument input: Any, skipConfirm: Bool) -> Bool { false }
    func textViewDroppedFile(_ file: Any) {}
}

_ = NSApplication.shared
NSApp.setActivationPolicy(.prohibited)
ThemeLibrary.shared.prepare(defaults: MemoryDefaults())  // nothing in the standard user defaults
let controller = ControllerG()
controller.profile = [CheckBraceKey: true, CheckBracketKey: true, CheckSquareBracketKey: true, CheckParenKey: true, HighlightContentKey: true]

func makeView() -> (NSWindow, TeXTextView) {
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 300), styleMask: [.titled], backing: .buffered, defer: false)
    let scroll = NSScrollView(frame: window.contentView!.bounds)
    scroll.hasVerticalScroller = true
    let view = TeXTextView(frame: NSRect(x: 0, y: 0, width: 480, height: 300))
    view.minSize = NSSize(width: 0, height: 300)
    view.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    view.isVerticallyResizable = true
    view.autoresizingMask = [.width]
    view.textContainer?.widthTracksTextView = true
    scroll.documentView = view
    window.contentView = scroll
    view.controller = controller
    view.awakeFromNib()
    view.layoutManager?.allowsNonContiguousLayout = true
    view.isContinuousSpellCheckingEnabled = false
    return (window, view)
}
let (sourceWindow, source) = makeView()
let (preambleWindow, preamble) = makeView()
controller.sourceTextView = source
controller.preambleTextView = preamble

var failures = 0
func expect(_ condition: Bool, _ message: String) {
    if !condition { FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8)); failures += 1 }
}
expect(!sourceWindow.isVisible && !preambleWindow.isVisible, "the windows stay hidden")
func spin(_ seconds: TimeInterval = 0.1) { RunLoop.current.run(until: Date().addingTimeInterval(seconds)) }

// Two themes of each appearance with different highlight colors: the bundled default and an edited copy.
let store = ThemeLibrary.shared.store
func colors(_ r: Double, _ g: Double, _ b: Double) -> [Double] { [r, g, b, 1] }
for (base, edited) in [(ThemeStore.defaultLightTitle, "Edited Lite"), (ThemeStore.defaultDarkTitle, "Edited Dark")] {
    var theme = store.read(title: base)!
    theme["EditorHighlightBraces"] = colors(0.1, 0.6, 0.2)
    theme["EditorHighlightContent"] = colors(0.95, 0.8, 0.3)
    theme["EditorHighlightZenkakuSymbol"] = colors(0.2, 0.2, 0.9)
    theme["EditorHighlightZenkakuSymbolBackground"] = colors(0.7, 0.95, 0.95)
    try! store.write(theme, title: edited)
}
ThemeLibrary.shared.invalidate()

// The text: braces whose contents hold a fullwidth digit, a fullwidth digit outside, and one on a line out of view.
let text = "x{a１b}z２" + String(repeating: "\nline", count: 400) + "\n３"
let last = (text as NSString).length - 1

func fg(_ view: TeXTextView, _ i: Int) -> NSColor? { view.layoutManager!.temporaryAttribute(.foregroundColor, atCharacterIndex: i, effectiveRange: nil) as? NSColor }
func bg(_ view: TeXTextView, _ i: Int) -> NSColor? { view.layoutManager!.temporaryAttribute(.backgroundColor, atCharacterIndex: i, effectiveRange: nil) as? NSColor }
func marked(_ view: TeXTextView, _ i: Int) -> Bool { view.layoutManager!.temporaryAttribute(.fullwidthBackgroundMark, atCharacterIndex: i, effectiveRange: nil) != nil }

/// The highlights as they should look now, in the colors of the current theme and appearance.
func checkLit(_ view: TeXTextView, _ place: String, switchOn: Bool, wholeText: Bool = true) {
    let brace = UtilityG.highlightedBraceColor(inProfile: controller.profile)
    let content = UtilityG.enclosedContentBackgroundColor(inProfile: controller.profile)
    let fullwidth = UtilityG.fullwidthAttributes(inProfile: controller.profile)?[.backgroundColor] as? NSColor
    expect(fg(view, 1) == brace && fg(view, 5) == brace, "\(place): the braces are lit in the new color: \(String(describing: fg(view, 1)))")
    expect((2...4).allSatisfy { bg(view, $0) == content } && !marked(view, 3),
           "\(place): the enclosed contents are highlighted in the new color: \(String(describing: bg(view, 3)))")
    expect(view.contentHighlighting && view.braceHighlighting, "\(place): the highlight state ended")
    if switchOn {
        expect(fullwidth != nil && bg(view, 7) == fullwidth && marked(view, 7), "\(place): the fullwidth digit outside has the new background")
        // A change of the appearance colors the visible lines, as any coloring; lines out of view are colored when shown.
        expect(!wholeText || bg(view, last) == fullwidth, "\(place): the fullwidth digit out of view has the new background: \(String(describing: bg(view, last)))")
    } else {
        expect(bg(view, 7) == nil && fg(view, 7) == nil && bg(view, last) == nil && !marked(view, 7), "\(place): a fullwidth background with the switch off")
    }
}

let changes: [(String, () -> Void)] = [
    ("theme switched", {
        controller.profile[LightThemeKey] = "Edited Lite"
        controller.profile[DarkThemeKey] = "Edited Dark"
        controller.themeColorsChanged()  // the product's action, copied in by the runner
    }),
    ("theme color changed", {
        // The theme editor writes the changed color into the selected theme and calls themeColorsChanged.
        let title = NSApp.isDarkMode ? ThemeStore.defaultDarkTitle : ThemeStore.defaultLightTitle
        var theme = store.read(title: title)!
        theme["EditorHighlightBraces"] = colors(0.8, 0.1, 0.6)
        theme["EditorHighlightContent"] = colors(0.6, 0.9, 0.6)
        theme["EditorHighlightZenkakuSymbolBackground"] = colors(0.9, 0.7, 0.9)
        try! store.write(theme, title: title)
        ThemeLibrary.shared.invalidate(title: title)
        controller.themeColorsChanged()
    }),
    ("appearance changed", {
        NSApp.appearance = NSAppearance(named: NSApp.isDarkMode ? .aqua : .darkAqua)
        source.viewDidChangeEffectiveAppearance(); preamble.viewDidChangeEffectiveAppearance()
    }),
]
let bundledLight = store.read(title: ThemeStore.defaultLightTitle)!
let bundledDark = store.read(title: ThemeStore.defaultDarkTitle)!

for appearance in [NSAppearance.Name.aqua, .darkAqua] {
    for switchOn in [true, false] {
        for (name, change) in changes {
            NSApp.appearance = NSAppearance(named: appearance)
            try! store.write(bundledLight, title: ThemeStore.defaultLightTitle)
            try! store.write(bundledDark, title: ThemeStore.defaultDarkTitle)
            ThemeLibrary.shared.invalidate()
            controller.profile[LightThemeKey] = nil
            controller.profile[DarkThemeKey] = nil
            controller.profile[HighlightFullwidthCharactersKey] = switchOn ? 1 : 0
            let oldBrace = UtilityG.highlightedBraceColor(inProfile: controller.profile)
            let oldContent = UtilityG.enclosedContentBackgroundColor(inProfile: controller.profile)
            for view in [source, preamble] {
                view.string = text
                view.colorizeEntireText()
                view.setSelectedRange(NSRange(location: 1, length: 0))
                view.lastCursorLocation = 1
                view.lastStringLength = UInt((text as NSString).length)
                view.setSelectedRange(NSRange(location: 2, length: 0))
            }
            spin()
            for (view, part) in [(source, "source"), (preamble, "preamble")] {
                checkLit(view, "\(appearance.rawValue) switch \(switchOn ? "on" : "off") \(part) before \(name)", switchOn: switchOn)
            }
            change()
            spin()
            let newBrace = UtilityG.highlightedBraceColor(inProfile: controller.profile)
            let newContent = UtilityG.enclosedContentBackgroundColor(inProfile: controller.profile)
            expect(newBrace != oldBrace && newContent != oldContent, "\(appearance.rawValue) \(name): the colors changed (test setup)")
            for (view, part) in [(source, "source"), (preamble, "preamble")] {
                let place = "\(appearance.rawValue) switch \(switchOn ? "on" : "off") \(part) after \(name)"
                checkLit(view, place, switchOn: switchOn, wholeText: name != "appearance changed")
                // Coloring again (an edit elsewhere, a resize) keeps it.
                view.colorizeText()
                checkLit(view, place + ", colored again", switchOn: switchOn, wholeText: name != "appearance changed")
                // Moving the cursor away still ends the highlight.
                view.setSelectedRange(NSRange(location: 9, length: 0))
            }
            spin()
            for (view, part) in [(source, "source"), (preamble, "preamble")] {
                let place = "\(appearance.rawValue) switch \(switchOn ? "on" : "off") \(part) after \(name), moved away"
                let fullwidth = UtilityG.fullwidthAttributes(inProfile: controller.profile)?[.backgroundColor] as? NSColor
                expect(!view.contentHighlighting && bg(view, 2) == nil && fg(view, 1) != newBrace, "\(place): the highlight ends")
                expect(bg(view, 3) == (switchOn ? fullwidth : nil), "\(place): the fullwidth digit inside: \(String(describing: bg(view, 3)))")
            }
        }
    }
}
NSApp.appearance = nil
try! store.write(bundledLight, title: ThemeStore.defaultLightTitle)
try! store.write(bundledDark, title: ThemeStore.defaultDarkTitle)

if failures > 0 { exit(1) }
print("Theme change highlight tests passed")
