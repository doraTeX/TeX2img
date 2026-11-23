#!/usr/bin/env python3
"""Menu shortcuts on French and German keyboard layouts, matched by AppKit's own dispatch (TeXShop 6.00).

The probe (tests/ShortcutLayoutDispatch.swift) switches keyboard layouts, so it never runs on this Mac: it is built here
and run over ssh on the Mac named by TEX2IMG_LAYOUT_VM (for example user@192.168.0.32), which must have this Mac's key.
Without TEX2IMG_LAYOUT_VM the fixture and the build are checked, and the probe must refuse to run here. --mutations also
checks that the probe catches the double-adapted keys and a conflict check that misses the keys a layout shows.
"""
from pathlib import Path
import os
import plistlib
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
STORE = ROOT / "Sources/Settings/KeyboardShortcuts.swift"
vm = os.environ.get("TEX2IMG_LAYOUT_VM", "")

# The menu commands of MainMenu.xib with the keys the xib gives them, named as ShortcutKeys.prepareIdentifiers names them.
MASKS = {"shift": 1 << 17, "control": 1 << 18, "option": 1 << 19, "command": 1 << 20}
items, seen = [], set()
for element in ET.parse(ROOT / "Resources/Base.lproj/MainMenu.xib").getroot().iter("menuItem"):
    key = element.get("keyEquivalent", "")
    action = element.find("connections/action")
    if not key or action is None:
        continue
    mask = element.find("modifierMask")
    modifiers = MASKS["command"] if mask is None else sum(v for k, v in MASKS.items() if mask.get(k) == "YES")
    identifier = f"TSShortcut.{action.get('selector')}.{element.get('tag', '0')}"
    if (key, modifiers) in seen or identifier in {i["identifier"] for i in items}:
        continue
    seen.add((key, modifiers))
    items.append({"identifier": identifier, "key": key, "modifiers": modifiers})
fixture = {i["identifier"]: i for i in items}
assert fixture["TSShortcut.placeBullet:.0"]["key"] == "8", "Insert Mark is Command-8 in the xib"
assert ("j", MASKS["command"] | MASKS["control"]) not in seen and ("k", MASKS["command"] | MASKS["control"]) not in seen
print(f"PASS: fixture has {len(items)} menu commands with their xib keys", flush=True)


def build(directory, store_source, name):
    store = directory / f"{name}-KeyboardShortcuts.swift"
    store.write_text(store_source)
    binary = directory / name
    subprocess.run(["xcrun", "swiftc", "-parse-as-library", "-target", "arm64-apple-macos13", "-module-name", "Probe",
                    str(ROOT / "tests/ShortcutLayoutDispatch.swift"), str(ROOT / "tests/MemoryDefaults.swift"), str(store),
                    "-o", str(binary)], check=True)
    return binary


def run(directory, binary):
    remote = f"tex2img-layout-{os.getpid()}-{binary.name}"
    subprocess.run(["ssh", "-o", "BatchMode=yes", vm, f"mkdir -p {remote}"], check=True)
    subprocess.run(["scp", "-q", str(binary), str(directory / "menu.plist"), f"{vm}:{remote}/"], check=True)
    try:
        result = subprocess.run(["ssh", "-o", "BatchMode=yes", vm,
                                 f"TEX2IMG_ALLOW_LAYOUT_SWITCH=1 {remote}/{binary.name} {remote}/menu.plist"],
                                capture_output=True, text=True, timeout=900)
    finally:
        subprocess.run(["ssh", "-o", "BatchMode=yes", vm, f"rm -rf {remote}"], check=False)
    # The probe selects ABC again and turns off the layouts it turned on; check that it did.
    selected = subprocess.run(["ssh", "-o", "BatchMode=yes", vm, "defaults read com.apple.HIToolbox AppleSelectedInputSources"],
                              capture_output=True, text=True)
    enabled = subprocess.run(["ssh", "-o", "BatchMode=yes", vm, "defaults read com.apple.HIToolbox AppleEnabledInputSources"],
                             capture_output=True, text=True)
    if "ABC" not in selected.stdout or "French" in enabled.stdout or "German" in enabled.stdout:
        result = subprocess.CompletedProcess(result.args, 1, result.stdout,
                                             result.stderr + "FAIL: the probe left the VM on another layout or with French or German on\n")
    return result


def main():
    source = STORE.read_text()
    with tempfile.TemporaryDirectory(prefix="tex2img-layout-") as name:
        directory = Path(name)
        (directory / "menu.plist").write_bytes(plistlib.dumps(items))
        binary = build(directory, source, "probe")
        local = subprocess.run([str(binary), str(directory / "menu.plist")], capture_output=True, text=True,
                               env={k: v for k, v in os.environ.items() if k != "TEX2IMG_ALLOW_LAYOUT_SWITCH"})
        assert local.returncode == 2 and "Refusing" in local.stderr, ("the probe must refuse to switch layouts here", local)
        print("PASS: the probe refuses to switch keyboard layouts outside a VM", flush=True)
        if not vm:
            print("SKIP: set TEX2IMG_LAYOUT_VM=user@host to run the probe in a VM", flush=True)
            return 0
        result = run(directory, binary)
        print(result.stdout, end="")
        print(result.stderr, end="", file=sys.stderr)
        if result.returncode:
            return 1
        if "--mutations" in sys.argv:
            for label, old, new, expected in MUTATIONS:
                assert source.count(old) == 1, label
                mutant = build(directory, source.replace(old, new), "mutant")
                result = run(directory, mutant)
                if result.returncode == 0 or expected not in result.stderr:
                    print(f"FAIL: the mutation went unnoticed: {label}\n{result.stderr[-2000:]}", file=sys.stderr)
                    return 1
                print("DETECTED", label, "—", next(line for line in result.stderr.splitlines() if expected in line))
    return 0


MUTATIONS = [
    ("default read as AppKit shows it",
     "        item.allowsAutomaticKeyEquivalentLocalization = false\n        defaultKey = item.keyEquivalent\n        defaultModifiers = item.keyEquivalentModifierMask\n",
     "        defaultKey = item.keyEquivalent\n        defaultModifiers = item.keyEquivalentModifierMask\n",
     "AppKit shows"),
    ("every item assigned again",
     "            return !self.command(command, hasKey: target, localized: saved ? false : command.defaultLocalization)",
     "            return target == target",
     "right after another command is assigned"),
    ("conflicts only with given keys",
     "                  ShortcutKeys.shownBinding(item) == binding || itemBindings.object(forKey: item)?.bindings.contains(binding) == true else { return }",
     "                  ShortcutKeys.givenBinding(item) == binding else { return }",
     "given to Jump to Selection too"),
    ("the shown default does not restore the command",
     "        if defaultBindings(for: command).contains(binding) { return restore(command) }",
     "        if binding == ShortcutBinding(command.defaultKey, command.defaultModifiers) { return restore(command) }",
     "kept an override instead of the default"),
    ("layout keys of Command applied to every modifier as they are",
     "        return ShortcutBinding(base.key, given.modifiers.subtracting(.shift).union(base.modifiers.intersection(.shift)))",
     "        return base",
     "the layout's keys give"),
]

if __name__ == "__main__":
    sys.exit(main())
