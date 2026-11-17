#!/usr/bin/env python3
"""Runs the real Edit › Marks commands (TeXTextView-Bullet.swift) on an NSTextView off screen and undoes them.
Undo must remove exactly what the command changed (it removed other characters, or raised NSRangeException).
"""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MAIN = r'''
import AppKit

class TeXTextView: NSTextView {
    let manager = UndoManager()
    override var undoManager: UndoManager? { manager }
    override var selectedRange: NSRange { get { super.selectedRange() } set { super.setSelectedRange(newValue) } }
}

func view(_ text: String) -> TeXTextView {
    let view = TeXTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
    view.isRichText = false
    view.allowsUndo = true
    view.manager.groupsByEvent = false
    view.string = text
    return view
}
func event(_ view: TeXTextView, _ body: () -> Void) {
    view.manager.beginUndoGrouping(); body(); view.manager.endUndoGrouping()
}
func type(_ view: TeXTextView, _ text: String) {
    for character in text { event(view) { view.insertText(String(character), replacementRange: view.selectedRange) } }
}
var failures = 0
func check(_ name: String, _ actual: String, _ expected: String) {
    if actual != expected { print("FAIL \(name): \(actual.debugDescription), not \(expected.debugDescription)"); failures += 1 }
}

// Typing, then a command, then Undo twice: the command, and then the last key typed, are undone.
let commands: [(String, NSRange, (TeXTextView) -> Void, String)] = [
    ("Insert Mark", NSRange(location: 0, length: 0), { $0.placeBullet(NSNull()) }, "•x^2 + 2xy + y^2 = r^2"),
    ("Insert Comment", NSRange(location: 0, length: 3), { $0.placeComment(NSNull()) }, "•‹› + 2xy + y^2 = r^2"),
]
for (name, selection, command, after) in commands {
    let v = view("x^2 + y^2 = r^2")
    v.setSelectedRange(NSRange(location: 4, length: 0))
    type(v, "+ 2xy ")
    v.setSelectedRange(selection)
    event(v) { command(v) }
    check("\(name)", v.string, after)
    v.manager.undo()
    check("\(name), undo", v.string, "x^2 + 2xy + y^2 = r^2")
    v.manager.undo()
    check("\(name), undo typing", v.string, "x^2 + 2xy+ y^2 = r^2")
}
let comment = view("ab")
comment.setSelectedRange(NSRange(location: 1, length: 0))
event(comment) { comment.placeComment(NSNull()) }
check("Insert Comment inside", comment.string, "a•‹›b")
check("Insert Comment caret", "\(comment.selectedRange().location)", "3")

let deletions: [(String, Int, (TeXTextView) -> Void, String)] = [
    ("Next Mark (Del)", 0, { $0.doNextBulletAndDelete(NSNull()) }, "x = y + z"),
    ("Previous Mark (Del)", 9, { $0.doPreviousBulletAndDelete(NSNull()) }, "x = y + z"),
]
for (name, caret, command, after) in deletions {
    let v = view("x = y + z")
    v.setSelectedRange(NSRange(location: 4, length: 0))
    event(v) { v.placeBullet(NSNull()) }
    v.setSelectedRange(NSRange(location: caret == 0 ? 0 : v.string.utf16.count, length: 0))
    type(v, caret == 0 ? "" : "!")
    event(v) { command(v) }
    check(name, v.string, caret == 0 ? after : after + "!")
    v.manager.undo()
    check("\(name), undo", v.string, caret == 0 ? "x = •y + z" : "x = •y + z!")
}
if failures > 0 { exit(1) }
print("PASS: Edit › Marks commands are undone exactly")
'''

with tempfile.TemporaryDirectory(prefix='tex2img-bullet-undo-') as tmp:
    work = Path(tmp)
    (work / 'main.swift').write_text(MAIN)
    sources = ['Sources/Editor/TeXTextView-Bullet.swift', 'Sources/Extensions/Foundation/String-Extension.swift',
               'Sources/NSString/NSString-Extension.swift']
    subprocess.run(['xcrun', 'swiftc', '-module-name', 'BulletUndo', *[str(ROOT / s) for s in sources], str(work / 'main.swift'),
                    '-o', str(work / 'bullet')], check=True)
    result = subprocess.run([str(work / 'bullet')], capture_output=True, text=True, timeout=60)
    print(result.stdout + result.stderr, end='')
    sys.exit(0 if result.returncode == 0 else 1)
