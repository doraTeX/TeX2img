#!/usr/bin/env python3
"""Runs the real paste of the source (TeXTextView.readSelection) on an NSTextView off screen.
Pasted text gets LF line endings, as a file that is opened (TeXShop 6.00), with the yen sign setting on or off; text
without CR is left to AppKit; Undo gives back the text before the paste. #PASTE# of command completion gets LF too.
With --mutations, each mutation of the source must make the test fail.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
VIEW = ROOT / "Sources/Editor/TeXTextView.swift"
EXTENSION = ROOT / "Sources/NSString/NSMutableString-Extension.swift"


def extract_method(text, marker):
    start = text.index(marker)
    end = text.index("{", start) + 1
    depth = 1
    while depth:
        depth += (text[end] == "{") - (text[end] == "}")
        end += 1
    return text[start:end]


MAIN = r'''
import AppKit
import PDFKit

let ConvertYenMarkKey = "convertYenMark"
struct Profile { let yen: Bool; func boolForKey(_ key: String) -> Bool { key == ConvertYenMarkKey && yen } }
final class FakeController {
    var yen = false
    var sourceTextView: NSTextView?
    func currentProfile() -> Profile { Profile(yen: yen) }
    func importSource(fromFilePathOrPDFDocument document: PDFDocument, skipConfirm: Bool) -> Bool { false }
}

final class TeXTextView: NSTextView {
    let controller = FakeController()
    let manager = UndoManager()
    var colorized = 0
    override var undoManager: UndoManager? { manager }
    override var selectedRange: NSRange { get { super.selectedRange() } set { super.setSelectedRange(newValue) } }
    func colorizeText() { colorized += 1 }
__METHOD__
}

var failures = 0
func check(_ name: String, _ condition: Bool, _ detail: @autoclosure () -> String = "") {
    if !condition { print("FAIL \(name) \(detail())"); failures += 1 }
}

func paste(_ text: String, into original: String, yen: Bool) -> (TeXTextView, Bool) {
    let view = TeXTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
    view.isRichText = false
    view.allowsUndo = true
    view.manager.groupsByEvent = false
    view.string = original
    view.controller.yen = yen
    view.setSelectedRange(NSRange(location: 1, length: 1))
    let board = NSPasteboard(name: NSPasteboard.Name("tex2img-paste-test-\(UUID().uuidString)"))
    board.clearContents()
    board.setString(text, forType: .string)
    view.manager.beginUndoGrouping()
    let result = view.readSelection(from: board, type: .string)
    view.manager.endUndoGrouping()
    board.releaseGlobally()
    return (view, result)
}

@main
struct Main {
    static func main() {
        for yen in [false, true] {
            let cases: [(String, String)] = [
                ("a\r\nb\r\n", "a\nb\n"),
                ("a\rb\r", "a\nb\n"),
                ("a\r\n\r\rb\n", "a\n\n\nb\n"),
                ("\\x\r\n¥y", yen ? "\\x\n\\y" : "\\x\n¥y"),
            ]
            for (pasted, expected) in cases {
                let name = "\(pasted.debugDescription) yen=\(yen)"
                let (view, result) = paste(pasted, into: "XYZ", yen: yen)
                check("\(name) pasted", result)
                check("\(name) text", view.string == "X\(expected)Z", view.string.debugDescription)
                check("\(name) no CR", !view.string.contains("\r"))
                check("\(name) colorized", view.colorized == 1, "\(view.colorized)")
                check("\(name) cursor after the paste", view.selectedRange() == NSRange(location: 1 + (expected as NSString).length, length: 0),
                      "\(view.selectedRange())")
                view.manager.undo()
                check("\(name) undo", view.string == "XYZ", view.string.debugDescription)
            }
        }
        // Text without CR (and without the yen setting) is pasted by AppKit, as before.
        let (plain, result) = paste("a\nb", into: "XYZ", yen: false)
        check("LF only pasted", result)
        check("LF only text", plain.string == "Xa\nbZ", plain.string.debugDescription)
        check("LF only left to AppKit", plain.colorized == 0, "\(plain.colorized)")
        // The yen setting still turns yen signs into backslashes in text without CR.
        let (yen, _) = paste("¥a", into: "XYZ", yen: true)
        check("yen only", yen.string == "X\\aZ", yen.string.debugDescription)
        // #PASTE# takes the clipboard with LF line endings.
        let clipboard = NSMutableString(string: "p\r\nq\rr").replaceLineEndingsWithLF()
        check("#PASTE# helper", clipboard as String == "p\nq\nr", (clipboard as String).debugDescription)
        if failures > 0 { print("\(failures) failure(s)"); exit(1) }
        print("paste line endings: all checks passed")
    }
}
'''


def run(view_text, extension_text):
    method = extract_method(view_text, "override func readSelection(")
    paste_lines = extract_method(view_text, "private func insertSpecialNonStandard(")
    if "#PASTE#" not in paste_lines or "replaceLineEndingsWithLF()" not in paste_lines:
        print("FAIL #PASTE# does not take the clipboard with LF line endings")
        return False
    with tempfile.TemporaryDirectory(prefix="paste-line-endings-") as directory:
        path = Path(directory)
        (path / "main.swift").write_text(MAIN.replace("__METHOD__", method))
        (path / "Extension.swift").write_text(extension_text)
        build = subprocess.run(["swiftc", "-parse-as-library", str(path / "main.swift"), str(path / "Extension.swift"),
                                "-o", str(path / "test")], capture_output=True, text=True)
        if build.returncode:
            print(build.stderr[-3000:])
            return False
        result = subprocess.run([str(path / "test")], capture_output=True, text=True, timeout=30)
        print(result.stdout.strip())
        return result.returncode == 0


def main():
    view_text = VIEW.read_text()
    extension_text = EXTENSION.read_text()
    if not run(view_text, extension_text):
        sys.exit(1)
    if "--mutations" not in sys.argv:
        return
    mutations = [
        ("paste keeps CRLF", VIEW, "            string.replaceLineEndingsWithLF()\n", ""),
        ("CR is not converted", EXTENSION, 'for ending in ["\\r\\n", "\\r"]', 'for ending in ["\\r\\n"]'),
        ("CR before CRLF", EXTENSION, 'for ending in ["\\r\\n", "\\r"]', 'for ending in ["\\r", "\\r\\n"]'),
        ("everything left to AppKit without the yen setting", VIEW,
         "guard convertYen || string as String != pasteboardString", "guard convertYen"),
        ("#PASTE# keeps CRLF", VIEW,
         'NSMutableString(string: NSPasteboard.general.string(forType: .string) ?? "").replaceLineEndingsWithLF()',
         'NSMutableString(string: NSPasteboard.general.string(forType: .string) ?? "")'),
    ]
    survived = []
    for name, file, old, new in mutations:
        texts = {VIEW: view_text, EXTENSION: extension_text}
        assert texts[file].count(old) == 1, name
        texts[file] = texts[file].replace(old, new)
        print(f"-- mutation: {name}")
        if run(texts[VIEW], texts[EXTENSION]):
            survived.append(name)
    if survived:
        print("mutations not detected:", survived)
        sys.exit(1)
    print(f"all {len(mutations)} mutations detected")


main()
