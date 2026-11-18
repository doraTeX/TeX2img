#!/usr/bin/env python3
"""The program detection panel says once that a missing program keeps its setting (in its explanation); the pop-up
of a missing program says only "Not found" / "見つかりません", as TeXShop's automatic setup does (28e9f2f5).
Reads the source of ControllerG.searchProgramsLogic; the panel itself is checked on the real machine.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
text = (ROOT / 'Sources/Controllers/ControllerG.swift').read_text()
start = text.index('func searchProgramsLogic(')
body = text[start:text.index('@IBAction func searchPrograms(', start)]
failures = []
added = re.findall(r'menu\.addItem\(withTitle: japanese \? "([^"]*)" : "([^"]*)"\)', body)
if added != [('見つかりません', 'Not found')]:
    failures.append(f'the pop-up of a missing program: {added}')
if '見つからない項目は現在の設定を保持します。' not in body or 'Missing programs keep their current settings.' not in body:
    failures.append('the explanation no longer says that missing programs keep their settings')
if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: detection panel texts')
