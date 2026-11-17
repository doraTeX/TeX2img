#!/usr/bin/env python3
"""Runs the real TeXTextView.fixupTabs() on an NSTextView off screen: a tab is "tab width" spaces wide in
proportional fonts too (glyph number 32 was measured, which is not the space in most proportional fonts).
"""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def extract_method(source, marker):
    text = source.read_text()
    start = text.index(marker)
    end = text.index("{", start) + 1
    depth = 1
    while depth:
        depth += (text[end] == "{") - (text[end] == "}")
        end += 1
    return text[start:end]


method = extract_method(ROOT / 'Sources/Editor/TeXTextView.swift', 'func fixupTabs()')
MAIN = r'''
import AppKit
let TabWidthKey = "TabWidth"
struct Profile { func integerForKey(_ key: String) -> Int { 4 } }
final class FakeController { func currentProfile() -> Profile { Profile() } }
final class Probe: NSTextView {
    let controller = FakeController()
    __METHOD__
}
var failures = 0
for name in ["HiraginoSans-W3", "Helvetica", "Menlo-Regular", "Osaka-Mono"] {
    guard let font = NSFont(name: name, size: 13) else { continue }
    let view = Probe(frame: NSRect(x: 0, y: 0, width: 400, height: 100))
    view.font = font
    view.string = "a\tb"
    view.fixupTabs()
    let expected = 4 * (" " as NSString).size(withAttributes: [.font: font]).width
    let actual = view.defaultParagraphStyle?.defaultTabInterval ?? 0
    if abs(actual - expected) > 0.01 { print("FAIL \(name): tab \(actual), 4 spaces \(expected)"); failures += 1 }
}
if failures > 0 { exit(1) }
print("PASS: a tab is as wide as the tab width in spaces")
'''.replace('__METHOD__', method)

with tempfile.TemporaryDirectory(prefix='tex2img-tab-width-') as tmp:
    work = Path(tmp)
    (work / 'main.swift').write_text(MAIN)
    subprocess.run(['xcrun', 'swiftc', str(ROOT / 'Sources/Extensions/Foundation/String-Extension.swift'),
                    str(ROOT / 'Sources/NSString/NSString-Extension.swift'), str(work / 'main.swift'), '-o', str(work / 'tab')], check=True)
    result = subprocess.run([str(work / 'tab')], capture_output=True, text=True, timeout=60)
    print(result.stdout + result.stderr, end='')
    sys.exit(0 if result.returncode == 0 else 1)
