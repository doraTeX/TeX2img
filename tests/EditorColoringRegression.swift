import AppKit

// Runs the product's TeXTextView in a window that is never shown, with a stand-in for ControllerG,
// and checks that only the visible lines are colored and that scrolling colors the lines brought into view.
// Run through tests/test_editor_coloring.py.

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

let lines = (0..<3000).map { "\\section{Line \($0)} % comment \($0)" }
textView.string = lines.joined(separator: "\n")
textView.colorizeText()
let text = textView.string as NSString
func commandColor(line: Int) -> NSColor? {
    let location = text.range(of: "\\section{Line \(line)}").location
    return textView.layoutManager?.temporaryAttribute(.foregroundColor, atCharacterIndex: location, effectiveRange: nil) as? NSColor
}
let visible = textView.visibleCharacterRange
check(visible.length > 0 && visible.length < text.length / 10, "only part of the text is visible: \(visible)")
check(commandColor(line: 0) != nil, "a visible command is colored")
check(commandColor(line: 2900) == nil, "a line far below is not colored yet")

// Scrolling posts a bounds change of the clip view, which colors the lines brought into view.
let target = text.range(of: "\\section{Line 2900}")
textView.scrollRangeToVisible(target)
check(commandColor(line: 2900) != nil, "scrolling colors the lines brought into view")

// A range can be colored on request, as copying rich text does.
let far = text.range(of: "\\section{Line 1500}")
textView.colorizeText(range: far)
check(commandColor(line: 1500) != nil, "a requested range is colored")
let comment = text.range(of: "% comment 1500")
check(textView.layoutManager?.temporaryAttribute(.foregroundColor, atCharacterIndex: comment.location, effectiveRange: nil) != nil,
      "the rest of the requested line is colored")

// Text being composed with an input method is not colored, and the visible text is not recolored while it
// is there; both are colored once the composed text is committed (TeXShop 5.60).
func color(at location: Int) -> NSColor? {
    textView.layoutManager?.temporaryAttribute(.foregroundColor, atCharacterIndex: location, effectiveRange: nil) as? NSColor
}
textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
textView.colorizeText()
textView.setSelectedRange(NSRange(location: 0, length: 0))
textView.setMarkedText("\\composed", selectedRange: NSRange(location: 9, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
check(textView.hasMarkedText(), "text is being composed")
let lineOne = (textView.string as NSString).range(of: "\\section{Line 1}")
textView.layoutManager?.removeTemporaryAttribute(.foregroundColor, forCharacterRange: lineOne)
textView.colorizeText()
textView.visibleAreaChanged(Notification(name: NSView.frameDidChangeNotification, object: textView))
textView.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: textView))
RunLoop.current.run(until: Date().addingTimeInterval(0.1))
check(color(at: 0) == nil, "the composed text is not colored")
check(color(at: lineOne.location) == nil, "the visible text is not recolored while text is composed")
check(textView.coloringWaitsForMarkedText, "coloring waits for the composed text")
textView.insertText("\\composed", replacementRange: textView.markedRange())
check(!textView.hasMarkedText(), "the composed text is committed")
RunLoop.current.run(until: Date().addingTimeInterval(0.1))
check(!textView.coloringWaitsForMarkedText, "coloring no longer waits after the commit")
check(color(at: 0) != nil, "the committed command is colored")
check(color(at: lineOne.location) != nil, "the visible text is colored after the commit")
print("Editor coloring regression tests passed")
