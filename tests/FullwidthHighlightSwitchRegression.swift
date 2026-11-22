import AppKit

// Runs the product's TeXTextView in a window that is never shown, with a stand-in for ControllerG, and checks the switch
// of the highlight of fullwidth letters, digits, symbols and the minus sign (Settings › Editor › Syntax Highlighting):
// off, these characters take exactly the attributes of ordinary text in every context and after every coloring;
// on again, they get the theme's colors back; a profile without the switch (an earlier version's) has it on.
// Run through tests/test_fullwidth_highlight_switch.py.

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
let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 300), styleMask: [.titled], backing: .buffered, defer: false)
let scroll = NSScrollView(frame: window.contentView!.bounds)
scroll.hasVerticalScroller = true
let textView = TeXTextView(frame: NSRect(x: 0, y: 0, width: 480, height: 300))
textView.minSize = NSSize(width: 0, height: 300)
textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
textView.isVerticallyResizable = true
textView.autoresizingMask = [.width]
textView.textContainer?.widthTracksTextView = true
scroll.documentView = textView
window.contentView = scroll
textView.controller = controller
controller.sourceTextView = textView
textView.awakeFromNib()
textView.layoutManager?.allowsNonContiguousLayout = true
textView.isContinuousSpellCheckingEnabled = false
textView.allowsUndo = true
// The preamble, in a window of its own that is never shown either.
let preambleWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 300), styleMask: [.titled], backing: .buffered, defer: false)
let preambleScroll = NSScrollView(frame: preambleWindow.contentView!.bounds)
let preamble = TeXTextView(frame: NSRect(x: 0, y: 0, width: 480, height: 300))
preamble.minSize = NSSize(width: 0, height: 300)
preamble.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
preamble.isVerticallyResizable = true
preamble.autoresizingMask = [.width]
preamble.textContainer?.widthTracksTextView = true
preambleScroll.documentView = preamble
preambleWindow.contentView = preambleScroll
preamble.controller = controller
controller.preambleTextView = preamble
preamble.awakeFromNib()
preamble.layoutManager?.allowsNonContiguousLayout = true
preamble.isContinuousSpellCheckingEnabled = false

var failures = 0
func expect(_ condition: Bool, _ message: String) {
    if !condition { FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8)); failures += 1 }
}
expect(window.isVisible == false && preambleWindow.isVisible == false, "the windows stay hidden")

controller.profile = [CheckBraceKey: true, CheckBracketKey: true, CheckSquareBracketKey: true, CheckParenKey: true]
let lm = textView.layoutManager!
func spin(_ seconds: TimeInterval = 0.1) { RunLoop.current.run(until: Date().addingTimeInterval(seconds)) }

/// The attributes the coloring gave a character.
struct Look: Equatable, CustomStringConvertible {
    let foreground: NSColor?
    let background: NSColor?
    let mark: Bool
    var description: String { "fg=\(foreground.map { "\($0)" } ?? "none") bg=\(background.map { "\($0)" } ?? "none") mark=\(mark)" }
}
func look(_ i: Int) -> Look {
    Look(foreground: lm.temporaryAttribute(.foregroundColor, atCharacterIndex: i, effectiveRange: nil) as? NSColor,
         background: lm.temporaryAttribute(.backgroundColor, atCharacterIndex: i, effectiveRange: nil) as? NSColor,
         mark: lm.temporaryAttribute(.fullwidthBackgroundMark, atCharacterIndex: i, effectiveRange: nil) != nil)
}
var length: Int { (textView.string as NSString).length }
func anyMark() -> Bool { (0..<length).contains { look($0).mark } }
/// The switch as the settings window stores it (the state of the switch, 1 or 0), or no switch at all (nil), and the
/// product's action of the switch (ControllerG.fullwidthHighlightChanged, copied in by the runner).
func setSwitch(_ on: Bool?) {
    if let on { controller.profile[HighlightFullwidthCharactersKey] = on ? 1 : 0 } else { controller.profile[HighlightFullwidthCharactersKey] = nil }
    controller.fullwidthHighlightChanged(nil)
}
func start(_ text: String, at location: Int) {
    textView.string = text
    textView.colorizeText()
    textView.setSelectedRange(NSRange(location: location, length: 0))
    spin()
    textView.lastCursorLocation = UInt(location)
    textView.lastStringLength = UInt((text as NSString).length)
}
func fullwidthLook() -> Look {
    let attributes = UtilityG.fullwidthAttributes(inProfile: controller.profile)
    return Look(foreground: attributes?[.foregroundColor] as? NSColor, background: attributes?[.backgroundColor] as? NSColor,
                mark: attributes?[.backgroundColor] != nil)
}

// 1. The setting: a profile without it (an earlier version's) and one with it on color fullwidth characters; off, none.
for appearance in [NSAppearance.Name.aqua, .darkAqua] {
    NSApp.appearance = NSAppearance(named: appearance)
    controller.profile[HighlightFullwidthCharactersKey] = nil
    expect(UtilityG.fullwidthAttributes(inProfile: controller.profile)?[.backgroundColor] != nil, "\(appearance.rawValue): a profile without the switch has it on")
    controller.profile[HighlightFullwidthCharactersKey] = 1
    expect(UtilityG.fullwidthAttributes(inProfile: controller.profile)?[.backgroundColor] != nil, "\(appearance.rawValue): on")
    controller.profile[HighlightFullwidthCharactersKey] = 0
    expect(UtilityG.fullwidthAttributes(inProfile: controller.profile) == nil, "\(appearance.rawValue): off colors nothing")
    controller.profile[HighlightFullwidthCharactersKey] = nil
    start("xＡy", at: 0)
    expect(look(1) == fullwidthLook() && look(1).mark, "\(appearance.rawValue): without the switch, Ａ is highlighted: \(look(1))")
}
NSApp.appearance = nil

// 2. Contexts: (text, index of the fullwidth character, index of an ordinary character in the same context, whether the
// switch changes the character's look there).
let contexts: [(String, Int, Int, Bool)] = [
    ("xＡy", 1, 0, true),          // letter
    ("x１y", 1, 0, true),          // digit
    ("x＋y", 1, 0, true),          // symbol
    ("x−y", 1, 0, true),           // minus sign
    ("x！y", 1, 0, true),          // symbol
    ("\\aＢx", 2, 3, true),        // after a command name
    ("\\Ａ", 1, 0, false),         // the character of a command
    ("%aＡ", 2, 1, false),         // comment
    ("a{Ｃ}b", 2, 0, true),        // between braces
]

// Each way the text is colored again. The text may change; the fullwidth character and the ordinary one are found
// again by their offsets from the end of the text, which none of these change.
let pasteboard = NSPasteboard.withUniqueName()
let recolorings: [(String, () -> Void)] = [
    ("coloring", { textView.colorizeText() }),
    ("whole text", { textView.colorizeEntireText() }),
    ("resize", { textView.setFrameSize(NSSize(width: textView.frame.width + 10, height: textView.frame.height)) }),
    ("visible area", { textView.visibleAreaChanged(Notification(name: NSView.boundsDidChangeNotification, object: nil)) }),
    ("theme change", { controller.themeColorsChanged() }),
    ("appearance", { textView.viewDidChangeEffectiveAppearance() }),
    ("typing at the start", {
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        textView.insertText("q", replacementRange: textView.selectedRange())
    }),
    ("typing a fullwidth letter at the start", {
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        textView.insertText("Ｑ", replacementRange: textView.selectedRange())
    }),
    ("paste", {
        pasteboard.clearContents()
        pasteboard.setString("Ｑ１", forType: .string)
        controller.profile[ConvertYenMarkKey] = false
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        _ = textView.readSelection(from: pasteboard, type: .string)
    }),
    ("paste converting yen marks", {
        pasteboard.clearContents()
        pasteboard.setString("Ｑ¥ ", forType: .string)  // "\\ " is a command of its own
        controller.profile[ConvertYenMarkKey] = true
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        _ = textView.readSelection(from: pasteboard, type: .string)
        controller.profile[ConvertYenMarkKey] = false
    }),
    ("undo", {
        let undo = textView.undoManager!
        undo.removeAllActions()
        undo.groupsByEvent = false
        undo.beginUndoGrouping()
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        textView.insertText("Ｑ", replacementRange: textView.selectedRange())
        undo.endUndoGrouping()
        undo.undo()
        undo.groupsByEvent = true
    }),
    ("comment out and in", {
        let item = NSMenuItem()
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        item.tag = CommentOutTag
        textView.doCommentOrIndent(item)
        item.tag = UncommentTag
        textView.doCommentOrIndent(item)
    }),
    ("brace highlight ends", { textView.setSelectedRange(NSRange(location: length, length: 0)) }),
]

for appearance in [NSAppearance.Name.aqua, .darkAqua] {
    NSApp.appearance = NSAppearance(named: appearance)
    for (text, index, ordinary, changes) in contexts {
        let fromEnd = (text as NSString).length - index
        let ordinaryFromEnd = (text as NSString).length - ordinary
        for (name, recolor) in recolorings {
            let place = "\(appearance.rawValue) “\(text)” \(name)"
            start(text, at: 0)
            setSwitch(true)
            let onLook = look(index)
            if changes {
                expect(onLook == fullwidthLook(), "\(place): highlighted while on: \(onLook)")
            }
            // Off: exactly the look of an ordinary character in the same context.
            setSwitch(false)
            expect(look(index) == look(ordinary) && !anyMark(), "\(place): off: \(look(index)) vs \(look(ordinary))")
            recolor()
            spin()
            let i = length - fromEnd, o = length - ordinaryFromEnd
            expect(look(i) == look(o), "\(place): after \(name) while off: \(look(i)) vs \(look(o))")
            expect(!anyMark(), "\(place): a fullwidth background mark after \(name) while off")
            for j in 0..<length where ThemeLibrary.isHighlightedFullwidthCharacter((textView.string as NSString).character(at: j)) {
                let background = look(j).background
                expect(background == nil || background == UtilityG.enclosedContentBackgroundColor(inProfile: controller.profile),
                       "\(place): a fullwidth background at \(j) after \(name) while off")
            }
            // On again: the look the character had before.
            setSwitch(true)
            expect(look(i) == onLook, "\(place): on again after \(name): \(look(i)) vs \(onLook)")
        }
    }
}
NSApp.appearance = nil
setSwitch(nil)

// 3. Inside highlighted enclosed contents and next to highlighted braces: off, the fullwidth character inside has the
// highlight as the ordinary characters around it, and keeps it through every coloring; the one outside has nothing.
controller.profile[HighlightContentKey] = true
for appearance in [NSAppearance.Name.aqua, .darkAqua] {
    NSApp.appearance = NSAppearance(named: appearance)
    let content = UtilityG.enclosedContentBackgroundColor(inProfile: controller.profile)
    let braceColor = UtilityG.highlightedBraceColor(inProfile: controller.profile)
    for (name, recolor) in recolorings.prefix(6) {
        let place = "\(appearance.rawValue) contents \(name)"
        // "x{a１b}z２": the cursor after "{" highlights "{a１b}".
        start("x{a１b}z２", at: 1)
        setSwitch(false)
        textView.setSelectedRange(NSRange(location: 2, length: 0))
        spin()
        expect(look(3) == look(2) && look(3).background == content, "\(place): inside: \(look(3)) vs \(look(2))")
        expect(look(7) == look(6) && look(7).background == nil, "\(place): outside: \(look(7))")
        expect((look(1).foreground, look(5).foreground) == (braceColor, braceColor), "\(place): the braces are highlighted")
        recolor()
        spin()
        expect(look(3) == look(2) && look(3).background == content && !look(3).mark, "\(place): inside after \(name): \(look(3)) vs \(look(2))")
        expect(look(7) == look(6) && !anyMark(), "\(place): outside after \(name): \(look(7))")
        // Turning the switch on while the contents are highlighted keeps the highlight inside and colors the outside.
        setSwitch(true)
        expect(look(3).background == content && look(2).background == content && !look(3).mark, "\(place): inside when switched on: \(look(3))")
        expect(look(7) == fullwidthLook(), "\(place): outside when switched on: \(look(7))")
        expect((look(1).foreground, look(5).foreground) == (braceColor, braceColor), "\(place): the braces stay highlighted when switched on")
        // ... and off again.
        setSwitch(false)
        expect(look(3) == look(2) && look(3).background == content, "\(place): inside when switched off: \(look(3))")
        expect(look(7) == look(6) && !anyMark(), "\(place): outside when switched off: \(look(7))")
        expect((look(1).foreground, look(5).foreground) == (braceColor, braceColor), "\(place): the braces stay highlighted when switched off")
        // The end of the highlight leaves the fullwidth character inside as the ordinary ones.
        textView.setSelectedRange(NSRange(location: 8, length: 0))
        spin()
        expect(look(3) == look(2) && look(3).background == nil && !anyMark(), "\(place): after the highlight ends: \(look(3)) vs \(look(2))")
        // On: the end of the highlight gives the fullwidth background back.
        setSwitch(true)
        textView.setSelectedRange(NSRange(location: 1, length: 0))
        textView.setSelectedRange(NSRange(location: 2, length: 0))
        spin()
        expect(look(3).background == content, "\(place): on, highlighted again: \(look(3))")
        textView.setSelectedRange(NSRange(location: 8, length: 0))
        spin()
        expect(look(3) == fullwidthLook(), "\(place): on, after the highlight ends: \(look(3))")
    }
}
NSApp.appearance = nil
controller.profile[HighlightContentKey] = false
setSwitch(nil)

// 4. Lines out of view: the switch colors the whole text, not only the visible lines.
do {
    let text = String(repeating: "line\n", count: 400) + "Ａ"
    start(text, at: 0)
    let last = length - 1
    expect(NSMaxRange(textView.visibleCharacterRange) < last, "the last line is out of view: \(textView.visibleCharacterRange)")
    setSwitch(true)
    expect(look(last) == fullwidthLook(), "on: the line out of view is highlighted: \(look(last))")
    setSwitch(false)
    expect(look(last) == look(last - 2) && !anyMark(), "off: the line out of view keeps the highlight: \(look(last))")
    setSwitch(true)
    expect(look(last) == fullwidthLook(), "on again: the line out of view: \(look(last))")
}
setSwitch(nil)

// 5. The background flash for a brace without a partner, while off: the flash is seen and the fullwidth character stays
// ordinary after it.
controller.profile[FlashBackgroundKey] = true
start("Ａx", at: 2)
setSwitch(false)
textView.insertText("}", replacementRange: textView.selectedRange())
spin(0.1)
expect(textView.backgroundColor == UtilityG.flashingBackgroundColor(inProfile: controller.profile), "off: the background flash is seen")
spin(0.3)
expect(textView.backgroundColor == UtilityG.backgroundColor(inProfile: controller.profile), "off: the background flash ends")
expect(look(0) == look(1) && !anyMark(), "off: Ａ after the flash: \(look(0))")
controller.profile[FlashBackgroundKey] = false
setSwitch(nil)

// 6. The two colors of the theme editor still take effect while on, and do nothing while off.
do {
    var theme = ThemeLibrary.shared.store.read(title: ThemeStore.defaultLightTitle)!
    theme["EditorHighlightZenkakuSymbol"] = [0.9, 0.1, 0.1, 1.0]
    theme["EditorHighlightZenkakuSymbolBackground"] = [0.1, 0.9, 0.1, 1.0]
    try! ThemeLibrary.shared.store.write(theme, title: "Edited Fullwidth")
    ThemeLibrary.shared.invalidate()
    NSApp.appearance = NSAppearance(named: .aqua)
    controller.profile[LightThemeKey] = "Edited Fullwidth"
    start("xＡy", at: 0)
    setSwitch(true)
    let expected = Look(foreground: ThemePalette.color(theme, key: "EditorHighlightZenkakuSymbol")!.withAlphaComponent(1),
                        background: ThemePalette.color(theme, key: "EditorHighlightZenkakuSymbolBackground"), mark: true)
    expect(look(1) == expected, "on: the edited colors: \(look(1)) vs \(expected)")
    setSwitch(false)
    controller.themeColorsChanged()
    expect(look(1) == look(0) && !anyMark(), "off: a theme change colors nothing: \(look(1))")
    controller.profile[LightThemeKey] = nil
    NSApp.appearance = nil
}

// 7. Text being composed (marked text) when the switch or the theme changes (1st audit of the switch, F1): the coloring
// waits, and once the composed text is committed or cancelled the whole text is colored, lines out of view too.
// Both views, on to off and off to on.
do {
    var themed = ThemeLibrary.shared.store.read(title: ThemeStore.defaultLightTitle)!
    themed["EditorHighlightZenkakuSymbolBackground"] = [0.3, 0.9, 0.5, 1.0]
    try! ThemeLibrary.shared.store.write(themed, title: "Composed Theme")
    ThemeLibrary.shared.invalidate()
    NSApp.appearance = NSAppearance(named: .aqua)
    let long = String(repeating: "abc\n", count: 600) + "Ａ"
    for (view, part) in [(textView, "source"), (preamble, "preamble")] {
        func lookIn(_ i: Int) -> Look {
            let lm = view.layoutManager!
            return Look(foreground: lm.temporaryAttribute(.foregroundColor, atCharacterIndex: i, effectiveRange: nil) as? NSColor,
                        background: lm.temporaryAttribute(.backgroundColor, atCharacterIndex: i, effectiveRange: nil) as? NSColor,
                        mark: lm.temporaryAttribute(.fullwidthBackgroundMark, atCharacterIndex: i, effectiveRange: nil) != nil)
        }
        for (change, from) in [("switch off", true), ("switch on", false), ("theme", true)] {
            for ending in ["commit", "cancel"] {
                let place = "\(part) \(change) while composing, \(ending)"
                controller.profile[LightThemeKey] = nil
                controller.profile[HighlightFullwidthCharactersKey] = from ? 1 : 0
                view.string = long
                view.colorizeEntireText()
                view.setSelectedRange(NSRange(location: 0, length: 0))
                view.scrollRangeToVisible(NSRange(location: 0, length: 0))
                spin()
                var lastIndex: Int { (view.string as NSString).length - 1 }
                expect(NSMaxRange(view.visibleCharacterRange) < lastIndex, "\(place): the last line is out of view")
                expect(lookIn(lastIndex) == (from ? fullwidthLook() : lookIn(lastIndex - 2)), "\(place): before: \(lookIn(lastIndex))")
                view.setMarkedText("あ", selectedRange: NSRange(location: 1, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
                spin()
                expect(view.hasMarkedText(), "\(place): composing")
                switch change {
                case "theme":
                    controller.profile[LightThemeKey] = "Composed Theme"
                    controller.themeColorsChanged()
                default:
                    controller.profile[HighlightFullwidthCharactersKey] = from ? 0 : 1
                    controller.fullwidthHighlightChanged(nil)
                }
                spin()
                if ending == "commit" {
                    view.insertText("あ", replacementRange: view.markedRange())
                } else {
                    view.setMarkedText("", selectedRange: NSRange(location: 0, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
                    view.unmarkText()
                }
                spin(0.3)
                expect(!view.hasMarkedText() && !view.coloringWaitsForMarkedText && !view.coloringWaitsForEntireText, "\(place): still waiting")
                expect(NSMaxRange(view.visibleCharacterRange) < lastIndex, "\(place): the last line is still out of view")
                let expected = change == "switch off" ? lookIn(lastIndex - 2) : fullwidthLook()
                expect(lookIn(lastIndex) == expected, "\(place): the line out of view: \(lookIn(lastIndex)) vs \(expected)")
                if change == "switch off" { expect(!(0...lastIndex).contains { lookIn($0).mark }, "\(place): a fullwidth mark is left") }
                if change == "theme" {
                    expect((lookIn(lastIndex).background?.usingColorSpace(.sRGB)?.redComponent ?? 1) < 0.5, "\(place): the new theme's background")
                }
                view.string = ""
            }
        }
    }
    controller.profile[LightThemeKey] = nil
    controller.profile[HighlightFullwidthCharactersKey] = nil
    NSApp.appearance = nil
}

pasteboard.releaseGlobally()
if failures > 0 { exit(1) }
print("Fullwidth highlight switch tests passed")
