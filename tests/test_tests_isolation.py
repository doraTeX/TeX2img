#!/usr/bin/env python3
"""Checks that the tests touch only what they make themselves (F3 of the 1st audit of the TeXShop port):

- no test removes, writes or reads a user defaults domain with a fixed name (`defaults delete …`,
  `removePersistentDomain(forName: "…")`, `UserDefaults(suiteName: "…")`): settings are in memory
  (tests/MemoryDefaults.swift), and a tool's own standard domain has a name of its own for each run;
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
    for match in re.finditer(r'removePersistentDomain\(forName:\s*"', text):
        failures.append(f'{path.name}: removes a domain with a fixed name')
    for match in re.finditer(r'UserDefaults\(suiteName:\s*"([^"]*)"', text):
        if path.name != 'MemoryDefaults.swift':
            failures.append(f'{path.name}: uses the suite {match.group(1)!r}')
    for match in re.finditer(r'''\[\s*["']defaults["']\s*,\s*["'](?:delete|write|import)["']\s*,\s*["']''', text):
        failures.append(f'{path.name}: changes a domain with a fixed name')
    if re.search(r'''pgrep|pkill''', text) and 'tex2img-test-waiter-' not in text:
        failures.append(f'{path.name}: looks for processes without a waiting program of its own')
    if re.search(r'''/bin/sleep''', text) and re.search(r'pgrep|pkill', text):
        failures.append(f'{path.name}: looks for /bin/sleep, which other programs run too')

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: the tests touch only their own defaults and processes')
