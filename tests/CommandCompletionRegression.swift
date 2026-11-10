// Checks the command completion of TeXTextView with a stand-in ControllerG, in a window that is never shown.
// Run through tests/test_command_completion.py.
import AppKit

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
func spin() { RunLoop.current.run(until: Date().addingTimeInterval(0.02)) }

_ = NSApplication.shared
NSApp.setActivationPolicy(.prohibited)
ThemeLibrary.shared.prepare()
let controller = ControllerG()
controller.profile = [CommandCompletionKeyKey: 0, BeepKey: false, FlashBackgroundKey: false, FlashInMovingKey: false,
                      CheckBraceKey: true, CheckParenKey: true, CheckSquareBracketKey: true, CheckBracketKey: false,
                      HighlightContentKey: false, TabWidthKey: 4, TabIndentKey: false, AutoIndentKey: true, AutoCompleteKey: true, ConvertYenMarkKey: true]
let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 300), styleMask: [.titled], backing: .buffered, defer: false)
let scroll = NSScrollView(frame: window.contentView!.bounds)
let tv = TeXTextView(frame: NSRect(x: 0, y: 0, width: 480, height: 300))
tv.isVerticallyResizable = true
tv.allowsUndo = true
scroll.documentView = tv
window.contentView = scroll
tv.controller = controller
controller.sourceTextView = tv
tv.awakeFromNib()
precondition(!window.isVisible)

func key(_ s: String, flags: NSEvent.ModifierFlags = []) -> NSEvent {
    NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: window.windowNumber, context: nil,
                     characters: s, charactersIgnoringModifiers: s, isARepeat: false, keyCode: 48)!
}
func reset(_ s: String, sel: NSRange) {
    tv.string = s
    tv.undoManager?.removeAllActions()
    tv.wasCompleted = false; tv.latexSpecial = false
    tv.setSelectedRange(sel)
    spin()
}
let L = { (s: String) in (s as NSString).length }

func completion(list: String, text: String, presses: Int) -> [String] {
    controller.commandCompletionList = list
    reset(text, sel: NSRange(location: L(text), length: 0))
    var out = [String]()
    for _ in 0..<presses {
        tv.keyDown(with: key("\t"))
        spin()
        out.append(tv.string)
    }
    return out
}

// A second Tab goes to the next candidate, also when the completion does not start with what was typed:
// the text is read again after the undo (a copy taken before it was compared).
var r = completion(list: "\nsec:=\\section{#INS#}\nsec:=\\subsection{#INS#}\n", text: "x sec", presses: 2)
check(r == ["x \\section{}", "x \\subsection{}"], "abbreviation candidates: \(r)")
// Lengths are UTF-16 lengths: a completion with an emoji also goes to the next candidate.
r = completion(list: "\nsm:=😀#INS#\nsm:=🙂#INS#\n", text: "x sm", presses: 2)
check(r == ["x 😀", "x 🙂"], "emoji candidates: \(r)")
// The candidates that start with what was typed, and back to it.
r = completion(list: "\n\\section\n\\subsection\n", text: "x \\sec", presses: 2)
check(r == ["x \\section", "x \\sec"], "plain candidates: \(r)")
// % does not end the word to complete (the "%C" of the Objective-C format was taken for a literal %).
r = completion(list: "\nsec:=\\section{#INS#}\n", text: "x%sec", presses: 1)
check(r == ["x%sec"], "no completion after %: \(r)")
print("Command completion regression tests passed")
