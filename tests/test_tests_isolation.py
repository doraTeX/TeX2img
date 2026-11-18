#!/usr/bin/env python3
"""Checks that the tests touch only what they make themselves (F3 of the 1st audit of the TeXShop port):

- no test removes or changes a user defaults domain (`defaults delete|write|import`, `removePersistentDomain`), or
  uses a suite with a fixed name: settings are in memory (tests/MemoryDefaults.swift);
- the code under test is given those defaults where it would use the standard ones (`ThemeLibrary.shared.prepare()`
  without defaults wrote BundledThemeColorsUpdate to the standard domain of the test tool), and the tools that it
  compiles get a name of their own for each run, whose domain the test checks was never made (tests/defaults_guard.py);
- the tests that look for processes by their command line (`pgrep -f`, `pkill -f`) run a waiting program of their own,
  compiled under a unique name (`tex2img-test-waiter-…`), and look for that name only.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
failures = []
for path in sorted((ROOT / 'tests').glob('*')):
    if path.suffix not in ('.py', '.swift', '.in', '.sh') or path.name == Path(__file__).name:
        continue
    text = path.read_text()
    if re.search(r'removePersistentDomain\(', text):
        failures.append(f'{path.name}: removes a user defaults domain')
    if re.search(r'prepare\(\)', text) and 'ThemeLibrary' in text:
        failures.append(f'{path.name}: ThemeLibrary.prepare() without defaults writes to the standard user defaults')
    for match in re.finditer(r'UserDefaults\(suiteName:\s*"([^"]*)"', text):
        if path.name != 'MemoryDefaults.swift':
            failures.append(f'{path.name}: uses the suite {match.group(1)!r}')
    if re.search(r'''["']defaults["']\s*,\s*["'](?:delete|write|import|rename)["']''', text):
        failures.append(f'{path.name}: changes a user defaults domain')
    if re.search(r'''pgrep|pkill''', text) and 'tex2img-test-waiter-' not in text:
        failures.append(f'{path.name}: looks for processes without a waiting program of its own')
    if re.search(r'''/bin/sleep''', text) and re.search(r'pgrep|pkill', text):
        failures.append(f'{path.name}: looks for /bin/sleep, which other programs run too')

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: the tests touch only their own defaults and processes')
