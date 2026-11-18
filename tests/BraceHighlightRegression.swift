import AppKit

// Runs the product's TeXTextView in a window that is never shown, with a stand-in for ControllerG, and checks the
// background of fullwidth characters while editing (the 1st audit of the TeX2img port, F5). Run through tests/test_brace_highlight.py.

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
ThemeLibrary.shared.prepare()
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
let braceColor = UtilityG.highlightedBraceColor(inProfile: controller.profile)
func highlighted(_ i: Int) -> Bool {
    (lm.temporaryAttribute(.foregroundColor, atCharacterIndex: i, effectiveRange: nil) as? NSColor) == braceColor
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
