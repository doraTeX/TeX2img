#!/usr/bin/env python3
"""Checks menu titles of MainMenu.xib by their actions: the Japanese titles use the terms of macOS and TeXShop
(クリップボードと交換, スペルと文法を表示, …), and the two spelling switches are named after what they do (their titles
were swapped in both languages).
"""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    'ja': {
        'exchangePaste:': 'クリップボードと交換',
        'showGuessPanel:': 'スペルと文法を表示',
        'checkSpelling:': '書類を今すぐチェック',
        'toggleContinuousSpellChecking:': '入力中にスペルチェック',
        'toggleGrammarChecking:': '文法とスペルをチェック',
        'toggleSmartInsertDelete:': 'スマートコピー/ペースト',
        'startSpeaking:': '読み上げを開始',
        'stopSpeaking:': '読み上げを停止',
    },
    'Base': {
        'exchangePaste:': 'Swap with Clipboard',
        'toggleContinuousSpellChecking:': 'Check Spelling While Typing',
        'toggleGrammarChecking:': 'Check Grammar With Spelling',
    },
}

failures = []
for language, expected in EXPECTED.items():
    titles = {}
    for item in ET.parse(ROOT / f'Resources/{language}.lproj/MainMenu.xib').iter('menuItem'):
        action = item.find('connections/action')
        if action is not None and action.get('selector') in expected:
            titles.setdefault(action.get('selector'), []).append(item.get('title'))
    for selector, title in expected.items():
        if titles.get(selector) != [title]:
            failures.append(f'{language}: {selector} is {titles.get(selector)}, not {title!r}')

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: menu titles')
