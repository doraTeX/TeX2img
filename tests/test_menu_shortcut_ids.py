#!/usr/bin/env python3
"""Builds the menus of MainMenu.xib (English and Japanese) off screen and reads them with the real ShortcutStore:
every menu command must be listed in Settings › Keyboard. Commands with the same action and tag got the same
identifier, and all but the first were dropped (Auto Complete, Replace Inserted ¥ with \\, Copy as Rich Text).
No window is shown; the defaults are in memory (tests/MemoryDefaults.swift).
"""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def menu_items(xib):
    """[(path, action, tag, key)] of the main menu's commands."""
    tree = ET.parse(xib)
    main = next(m for m in tree.iter('menu') if m.get('systemMenu') == 'main')
    result = []

    def visit(menu, path):
        items = menu.find('items')
        for item in ([] if items is None else items.findall('menuItem')):
            if item.get('isSeparatorItem') == 'YES':
                continue
            title = item.get('title', '')
            full = f'{path} › {title}' if path else title
            submenu = item.find('menu')
            if submenu is not None:
                visit(submenu, full)
                continue
            action = item.find('connections/action')
            if action is not None:
                result.append((full, action.get('selector'), int(item.get('tag', '0')), item.get('keyEquivalent', '')))
    visit(main, '')
    return result


MAIN = r'''
import AppKit
_ = NSApplication.shared
let items = try! JSONSerialization.jsonObject(with: Data(CommandLine.arguments[1].utf8)) as! [[Any]]
let main = NSMenu()
var submenus: [String: NSMenu] = [:]
for entry in items {
    let parts = (entry[0] as! String).components(separatedBy: " › ")
    var menu = main
    for depth in 0..<(parts.count - 1) {
        let key = parts[0...depth].joined(separator: " › ")
        if let existing = submenus[key] { menu = existing; continue }
        let holder = NSMenuItem(title: parts[depth], action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: parts[depth])
        holder.submenu = submenu
        menu.addItem(holder)
        submenus[key] = submenu
        menu = submenu
    }
    let item = NSMenuItem(title: parts.last!, action: NSSelectorFromString(entry[1] as! String), keyEquivalent: entry[3] as! String)
    item.tag = entry[2] as! Int
    menu.addItem(item)
}
let defaults = MemoryDefaults()
let store = ShortcutStore(menu: main, defaults: defaults)
for command in store.commands { print(command.path) }
'''

failures = []
with tempfile.TemporaryDirectory(prefix='tex2img-menu-ids-') as tmp:
    work = Path(tmp)
    (work / 'main.swift').write_text(MAIN)
    subprocess.run(['xcrun', 'swiftc', '-module-name', 'MenuIDs', str(ROOT / 'Sources/Settings/KeyboardShortcuts.swift'),
                    str(ROOT / 'tests/MemoryDefaults.swift'),
                    str(work / 'main.swift'), '-o', str(work / 'menu')], check=True)
    for language in ('Base', 'ja'):
        items = menu_items(ROOT / f'Resources/{language}.lproj/MainMenu.xib')
        listed = subprocess.run([str(work / 'menu'), json.dumps(items)], capture_output=True, text=True, check=True).stdout.splitlines()
        toggles = [path for path, action, _, _ in items if action == 'toggleMenuItem:']
        if len(toggles) != 4:
            failures.append(f'{language}: {len(toggles)} toggle commands in the xib, not 4')
        missing = [path for path in toggles if path not in listed]
        if missing:
            failures.append(f'{language}: not in Settings › Keyboard: {missing}')
        seen = {}
        for path, action, tag, _ in items:
            if (action, tag) in seen and not action.startswith('_'):
                failures.append(f'{language}: {path} and {seen[(action, tag)]} share {action} tag {tag}')
            seen.setdefault((action, tag), path)

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: every menu command has its own shortcut identifier')
