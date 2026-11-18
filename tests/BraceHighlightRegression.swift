import AppKit

// Runs the product's TeXTextView in a window that is never shown, with a stand-in for ControllerG, and checks the
// highlight of matching braces and the background of fullwidth characters while editing (the 1st audit of the
// TeX2eps port, F1 and F2, which TeX2img shares). Run through tests/test_brace_highlight.py.

final class ControllerG: NSObject, DnDDelegate {
    var commandCompletionList: String?
    var sourceTextView: TeXTextView!
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

func check(_ condition: Bool, _ message: String) {
    if !condition {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
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
check(window.isVisible == false, "the window stays hidden")


controller.profile = [CheckBraceKey: true, CheckBracketKey: true, CheckSquareBracketKey: true, CheckParenKey: true]
textView.isContinuousSpellCheckingEnabled = false
let lm = textView.layoutManager!
func spin(_ seconds: TimeInterval = 0.1) { RunLoop.current.run(until: Date().addingTimeInterval(seconds)) }
func highlighted(_ i: Int) -> Bool {
    // The color of the current appearance (light or dark).
    (lm.temporaryAttribute(.foregroundColor, atCharacterIndex: i, effectiveRange: nil) as? NSColor)
        == UtilityG.highlightedBraceColor(inProfile: controller.profile)
}
func start(_ text: String, at location: Int) {
    textView.string = text
    textView.colorizeText()
    textView.setSelectedRange(NSRange(location: location, length: 0))
    spin()
    textView.lastCursorLocation = UInt(location)
    textView.lastStringLength = UInt((text as NSString).length)
}
var failures = 0
func expect(_ condition: Bool, _ message: String) {
    if !condition { FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8)); failures += 1 }
}

// 1. A brace being composed with an input method (marked text) is not highlighted; once committed, it is.
start("}", at: 0)
textView.setMarkedText("{", selectedRange: NSRange(location: 1, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
spin()
expect(textView.hasMarkedText() && textView.string == "{}", "marked: \(textView.string)")
expect(!highlighted(0) && !highlighted(1), "the marked brace is highlighted")
textView.insertText("{", replacementRange: textView.markedRange())
spin()
expect(!textView.hasMarkedText() && textView.string == "{}", "committed: \(textView.string)")
expect(highlighted(0) && highlighted(1), "the committed brace is not highlighted")
// Composed text that is removed highlights nothing.
start("}", at: 0)
textView.setMarkedText("{", selectedRange: NSRange(location: 1, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
spin()
textView.setMarkedText("", selectedRange: NSRange(location: 0, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
textView.unmarkText()
spin()
expect(!textView.hasMarkedText() && textView.string == "}" && !highlighted(0), "cancelled: \(textView.string)")

// 2. A brace typed directly stays highlighted after the coloring that follows the edit.
start("}", at: 0)
textView.insertText("{", replacementRange: textView.selectedRange())
spin()
expect(textView.string == "{}" && highlighted(0) && highlighted(1), "the typed brace is not highlighted: \(textView.string)")
// Moving the cursor over a brace highlights the pair, as before.
start("a{b}c", at: 1)
textView.setSelectedRange(NSRange(location: 2, length: 0))
spin()
expect(highlighted(1) && highlighted(3), "moving over a brace")
// The highlight goes when the cursor moves on (SOLID).
textView.setSelectedRange(NSRange(location: 4, length: 0))
textView.setSelectedRange(NSRange(location: 5, length: 0))
spin()
expect(!highlighted(1), "the highlight stays after moving away")

// 5. A highlight that the selection change during composed text (marked text) could not remove is removed after the
// composed text is committed or cancelled, and is not given again by the coloring then (TeX2eps port, 3rd audit F4).
// Composed text is never colored. Light and dark.
func anyHighlighted() -> Bool { (0..<(textView.string as NSString).length).contains(where: highlighted) }
func mark(_ text: String) {
    textView.setMarkedText(text, selectedRange: NSRange(location: (text as NSString).length, length: 0),
                           replacementRange: NSRange(location: NSNotFound, length: 0))
}
func cancelMarked() {
    textView.setMarkedText("", selectedRange: NSRange(location: 0, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
    textView.unmarkText()
}
func commitMarked(_ text: String) { textView.insertText(text, replacementRange: textView.markedRange()) }
for appearance in [NSAppearance.Name.aqua, .darkAqua] {
    NSApp.appearance = NSAppearance(named: appearance)
    let mode = appearance == .aqua ? "light" : "dark"
    // a. Typed brace lit, composed text after it, cancelled.
    start("}", at: 0)
    textView.insertText("{", replacementRange: textView.selectedRange())
    spin()
    expect(highlighted(0) && highlighted(1), "\(mode) a: lit")
    mark("１２")
    spin()
    expect(!highlighted(1) || highlighted(0), "\(mode) a: marked")
    cancelMarked()
    spin()
    expect(!anyHighlighted(), "\(mode) a: the highlight stays after the composed text is cancelled")
    // b. The same, committed.
    start("}", at: 0)
    textView.insertText("{", replacementRange: textView.selectedRange())
    spin()
    mark("ab")
    spin()
    commitMarked("ab")
    spin()
    expect(textView.string == "{ab}" && !anyHighlighted(), "\(mode) b: the highlight stays after the composed text is committed: \(textView.string)")
    // c. Cursor on a brace, composed text elsewhere, committed: the old pair is not lit again.
    start("a{b}c", at: 1)
    textView.setSelectedRange(NSRange(location: 2, length: 0))
    spin()
    expect(highlighted(1) && highlighted(3), "\(mode) c: lit")
    textView.setSelectedRange(NSRange(location: 5, length: 0))
    textView.lastCursorLocation = 5
    mark("x")
    spin()
    commitMarked("x")
    spin()
    textView.colorizeText()
    expect(!anyHighlighted(), "\(mode) c: the old pair is lit again after the commit")
    // d. Undo (⌘Z) of the typed brace while it is lit.
    start("}", at: 0)
    textView.allowsUndo = true
    let undo = textView.undoManager!
    undo.removeAllActions()
    undo.groupsByEvent = false
    undo.beginUndoGrouping()
    textView.insertText("{", replacementRange: textView.selectedRange())
    undo.endUndoGrouping()
    spin()
    expect(highlighted(0) && highlighted(1), "\(mode) d: lit")
    undo.undo()
    undo.groupsByEvent = true
    spin()
    expect(textView.string == "}" && !anyHighlighted(), "\(mode) d: a highlight stays after the undo: \(textView.string)")
    // e. Composed text is never colored as a highlight.
    start("}", at: 0)
    mark("{")
    spin()
    expect(!anyHighlighted(), "\(mode) e: composed text is highlighted")
    cancelMarked()
    spin()
}
NSApp.appearance = nil

// 6. A theme whose background of enclosed contents is the color of the fullwidth background: the coloring keeps the
// highlight of the enclosed contents (it removed every background of that color; 2nd audit of the port, F5).
do {
    var sameColors = ThemeLibrary.shared.store.read(title: ThemeStore.defaultLightTitle)!
    let shared: [Double] = [0.2, 0.4, 1.0, 1.0]
    sameColors["EditorHighlightContent"] = shared
    sameColors["EditorHighlightZenkakuSymbolBackground"] = shared
    try! ThemeLibrary.shared.store.write(sameColors, title: "Same Backgrounds")
    ThemeLibrary.shared.invalidate()
    for appearance in [NSAppearance.Name.aqua, .darkAqua] {
        NSApp.appearance = NSAppearance(named: appearance)
        controller.profile[LightThemeKey] = "Same Backgrounds"
        controller.profile[DarkThemeKey] = "Same Backgrounds"
        controller.profile[HighlightContentKey] = true
        start("x{ab}z１", at: 1)
        textView.setSelectedRange(NSRange(location: 2, length: 0))
        spin()
        func background(_ i: Int) -> NSColor? { lm.temporaryAttribute(.backgroundColor, atCharacterIndex: i, effectiveRange: nil) as? NSColor }
        let content = UtilityG.enclosedContentBackgroundColor(inProfile: controller.profile)
        expect(background(2) == content && background(3) == content, "\(appearance.rawValue): the enclosed contents are highlighted")
        textView.colorizeText()
        expect(background(2) == content && background(3) == content, "\(appearance.rawValue): the coloring removed the highlight of the enclosed contents")
        expect(background(6) != nil, "\(appearance.rawValue): the fullwidth digit keeps its background")
        controller.profile[HighlightContentKey] = false
        controller.profile[LightThemeKey] = nil
        controller.profile[DarkThemeKey] = nil
    }
    NSApp.appearance = nil
}

// 7. The bundled themes: the highlight of enclosed contents stays on a fullwidth character inside when the text is
// colored again without a selection change (the view is resized, scrolled, or colored after a setting change), and
// the fullwidth character outside keeps the fullwidth background (3rd audit of the port, F5).
for appearance in [NSAppearance.Name.aqua, .darkAqua] {
    NSApp.appearance = NSAppearance(named: appearance)
    controller.profile[HighlightContentKey] = true
    func background(_ i: Int) -> NSColor? { lm.temporaryAttribute(.backgroundColor, atCharacterIndex: i, effectiveRange: nil) as? NSColor }
    let content = UtilityG.enclosedContentBackgroundColor(inProfile: controller.profile)
    let fullwidth = UtilityG.fullwidthAttributes(inProfile: controller.profile)?[.backgroundColor] as? NSColor
    for (trigger, recolor) in [("resize", { textView.setFrameSize(NSSize(width: textView.frame.width + 10, height: textView.frame.height)) }),
                               ("scroll", { textView.visibleAreaChanged(Notification(name: NSView.boundsDidChangeNotification, object: nil)) }),
                               ("coloring", { textView.colorizeText() })] as [(String, () -> Void)] {
        start("x{a１b}z２", at: 1)
        textView.setSelectedRange(NSRange(location: 2, length: 0))
        spin()
        let mode = "\(appearance.rawValue) \(trigger)"
        expect(background(2) == content && background(3) == content && background(4) == content, "\(mode): the enclosed contents are highlighted")
        expect(fullwidth != nil && background(7) == fullwidth, "\(mode): the fullwidth digit outside has the fullwidth background")
        recolor()
        spin()
        expect(background(2) == content && background(3) == content && background(4) == content,
               "\(mode): the highlight of the enclosed contents broke under the fullwidth digit: \(String(describing: background(3)))")
        expect(background(7) == fullwidth, "\(mode): the fullwidth digit outside lost its background")
        // Moving away ends the highlight; the fullwidth digit inside gets its own background back.
        textView.setSelectedRange(NSRange(location: 8, length: 0))
        spin()
        expect(background(2) == nil && background(3) == fullwidth, "\(mode): after the highlight ends")
    }
    controller.profile[HighlightContentKey] = false
}
NSApp.appearance = nil

// 4. The background flash for a brace without a partner is seen, and a flash that a later one started is not ended
// by the earlier timer (the 2nd audit of the TeX2eps port, F3, which TeX2img shares).
controller.profile[FlashBackgroundKey] = true
let flashColor = UtilityG.flashingBackgroundColor(inProfile: controller.profile)
func flashing() -> Bool { textView.backgroundColor == flashColor }
start("x", at: 1)
textView.insertText("}", replacementRange: textView.selectedRange())
spin(0.1)
expect(flashing(), "a single background flash is not seen")
spin(0.3)
expect(!flashing(), "the single background flash does not end")
start("x", at: 1)
textView.insertText("}", replacementRange: textView.selectedRange())
spin(0.15)
textView.insertText("}", replacementRange: textView.selectedRange())
spin(0.1)
expect(flashing(), "the second background flash was ended by the earlier timer")
spin(0.3)
expect(!flashing(), "the second background flash does not end")
controller.profile[FlashBackgroundKey] = false

// 3. Fullwidth letters that a deleted line end puts into a comment lose their background (light and dark).
for appearance in [NSAppearance.Name.aqua, .darkAqua] {
    NSApp.appearance = NSAppearance(named: appearance)
    let fullwidthBackground = UtilityG.fullwidthAttributes(inProfile: controller.profile)?[.backgroundColor]
    start("%x\n１２", at: 3)
    expect(fullwidthBackground != nil && lm.temporaryAttribute(.backgroundColor, atCharacterIndex: 3, effectiveRange: nil) != nil,
           "\(appearance.rawValue): fullwidth digits have their background before the join")
    textView.deleteBackward(nil)
    spin()
    expect(textView.string == "%x１２", "joined: \(textView.string)")
    for index in [3, 4] {
        expect(lm.temporaryAttribute(.backgroundColor, atCharacterIndex: index, effectiveRange: nil) == nil,
               "\(appearance.rawValue): the commented fullwidth digit \(index) keeps the fullwidth background")
    }
    // The background of the contents of braces is another highlight: it stays when the text is colored again.
    start("{ab}１", at: 0)
    lm.addTemporaryAttribute(.backgroundColor, value: NSColor.yellow, forCharacterRange: NSRange(location: 0, length: 4))
    textView.colorizeText()
    expect((lm.temporaryAttribute(.backgroundColor, atCharacterIndex: 1, effectiveRange: nil) as? NSColor) == NSColor.yellow,
           "\(appearance.rawValue): the background of enclosed contents is kept")
    expect(lm.temporaryAttribute(.backgroundColor, atCharacterIndex: 4, effectiveRange: nil) != nil,
           "\(appearance.rawValue): a fullwidth digit outside a comment keeps its background")
    // The end of a highlight of enclosed contents puts back the fullwidth backgrounds: not in a comment.
    start("%１\n２", at: 0)
    lm.addTemporaryAttribute(.backgroundColor, value: NSColor.yellow, forCharacterRange: NSRange(location: 0, length: 4))
    textView.resetBackgroundColor(nil)
    expect(lm.temporaryAttribute(.backgroundColor, atCharacterIndex: 1, effectiveRange: nil) == nil,
           "\(appearance.rawValue): a commented fullwidth digit gets a background when a highlight ends")
    expect(lm.temporaryAttribute(.backgroundColor, atCharacterIndex: 3, effectiveRange: nil) != nil,
           "\(appearance.rawValue): a fullwidth digit gets its background back when a highlight ends")
}
NSApp.appearance = nil

if failures > 0 { exit(1) }
print("Brace highlight and fullwidth background tests passed")
