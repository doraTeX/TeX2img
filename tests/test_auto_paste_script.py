#!/usr/bin/env python3
"""Checks the auto-paste AppleScripts line by line against what the Objective-C Converter wrote (one line each)."""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATHS = ["/tmp/a b/out-1.png", "/tmp/a b/out-2.png"]

MAIN = r'''
import Foundation
let paths = CommandLine.arguments.dropFirst(2).map { String($0) }
switch CommandLine.arguments[1] {
case "word": print(AutoPasteScript.word(paths), terminator: "")
case "powerpoint": print(AutoPasteScript.powerPoint(paths), terminator: "")
default: print(AutoPasteScript.iWork(CommandLine.arguments[1]), terminator: "")
}
'''

SYSTEM_EVENTS = 'tell application "System Events" to (keystroke "v" using command down)'


def picture(path):
    return 'file name:(POSIX file "%s") as Unicode text, save with document:true}' % path


def expected_word(paths):
    lines = ['tell application "Microsoft Word"', "activate", "if version < 15 then", "tell selection",
             "set myStart to selection start", "set myEnd to selection end", "end tell", "tell active document",
             "set theRange to create range start myStart end myEnd"]
    lines += ["make new inline picture at theRange with properties {" + picture(p) for p in reversed(paths)]
    lines += ["end tell", "else", "tell active document", SYSTEM_EVENTS, "end tell", "end if", "end tell"]
    return "".join(line + "\n" for line in lines)


def expected_powerpoint(paths):
    lines = ['tell application "Microsoft PowerPoint"', "activate", "if version < 15 then",
             "set thisSlide to slide index of slide of view of active window",
             "tell slide thisSlide of active presentation"]
    for p in paths:
        lines += ["set thePicture to make new picture at end with properties {" + picture(p), "tell thePicture",
                  "scale height factor 1 scale scale from top left with relative to original size",
                  "scale width factor 1 scale scale from top left with relative to original size", "end tell"]
    lines += ["end tell", "else", "tell active presentation", SYSTEM_EVENTS, "end tell", "end if", "end tell"]
    return "".join(line + "\n" for line in lines)


def expected_iwork(app):
    lines = ['tell application "%s"' % app, "activate", "tell document", SYSTEM_EVENTS, "end tell", "end tell"]
    return "".join(line + "\n" for line in lines)


def main():
    work = tempfile.mkdtemp(prefix="tex2img-autopaste-")
    try:
        main_file = os.path.join(work, "main.swift")
        with open(main_file, "w") as f:
            f.write(MAIN)
        binary = os.path.join(work, "autopaste")
        subprocess.run(["xcrun", "swiftc", os.path.join(ROOT, "Sources/Converter/AutoPasteScript.swift"), main_file,
                        "-o", binary], check=True)
        cases = [(["word"] + PATHS, expected_word(PATHS)), (["powerpoint"] + PATHS, expected_powerpoint(PATHS))]
        cases += [([app], expected_iwork(app)) for app in ("Pages", "Numbers", "Keynote")]
        failures = 0
        for args, expected in cases:
            actual = subprocess.run([binary] + args, capture_output=True, text=True, check=True).stdout
            if actual != expected:
                failures += 1
                print("FAIL: %s\n--- expected\n%s--- actual\n%s" % (args[0], expected, actual), file=sys.stderr)
        if failures:
            return 1
        print("Auto-paste script tests passed")
        return 0
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
