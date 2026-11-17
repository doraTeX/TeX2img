#!/usr/bin/env python3
"""Checks that paths reach the shell and AppleScript as they are: with $, `, ", \\, ' and a quote that a
combining mark follows. Nothing is run with administrator privileges; osascript only reads string literals.
"""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MAIN = r'''
import Foundation
let text = CommandLine.arguments[1]
print(text.quotingWithDoubleQuotations())
print(text.quotingForShell())
print(AutoPasteScript.word([text]).components(separatedBy: "\n").first { $0.contains("POSIX file") }!)
print(AutoPasteScript.powerPoint([text]).components(separatedBy: "\n").first { $0.contains("POSIX file") }!)
print("\u{00A5}\u{0301}".replacingYenWithBackslash() == "\\\u{0301}")
'''

ODD = "dir$HOME `echo x` \"q\" \\ back 'single' it'́s ¥"
failures = []
with tempfile.TemporaryDirectory(prefix='tex2img-quoting-') as tmp:
    work = Path(tmp)
    (work / 'main.swift').write_text(MAIN)
    sources = ['Sources/Extensions/Foundation/String-Extension.swift', 'Sources/NSString/NSString-Extension.swift',
               'Sources/Converter/AutoPasteScript.swift']
    subprocess.run(['xcrun', 'swiftc', *[str(ROOT / s) for s in sources], str(work / 'main.swift'), '-o', str(work / 'quote')],
                   check=True)
    lines = subprocess.run([str(work / 'quote'), ODD], capture_output=True, text=True, check=True).stdout.split('\n')
    double, single, word, powerpoint, yen = lines[:5]
    for name, word_text in (('double quotes', double), ('single quotes', single)):
        result = subprocess.run(['/bin/sh', '-c', 'printf %s ' + word_text], capture_output=True, text=True)
        if result.stdout != ODD:
            failures.append(f'{name}: the shell read {result.stdout!r}{result.stderr}')
    for name, line in (('Word', word), ('PowerPoint', powerpoint)):
        literal = re.search(r'\(POSIX file (.*)\) as Unicode text', line).group(1)
        result = subprocess.run(['osascript', '-e', 'return ' + literal], capture_output=True, text=True)
        if result.stdout[:-1] != ODD:
            failures.append(f'{name} auto-paste: AppleScript read {result.stdout!r}{result.stderr}')
    if yen != 'true':
        failures.append('a yen sign that a combining mark follows is not replaced')

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: shell and AppleScript quoting')
