#!/usr/bin/env python3
"""Checks the selection color of themes and the "Use system color" switches of the cursor and the selection (TeXShop
6.00): a switch is read as its number and otherwise as before the switches (the theme's cursor, the system's selection);
the color drawn; that an earlier copy of a bundled theme is not counted as changed; and the switches and selection colors
of the bundled themes. ThemeStore.swift is compiled as it is. --mutations changes key parts and the test must fail."""
import os
import re
import subprocess
import sys
import tempfile

import defaults_guard

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORE = os.path.join(ROOT, "Sources/Settings/ThemeStore.swift")
EXTENSIONS = sorted(os.path.join(ROOT, "Sources/Extensions/AppKit", n) for n in os.listdir(os.path.join(ROOT, "Sources/Extensions/AppKit")) if n.endswith(".swift"))


def run(store_source, label):
    with tempfile.TemporaryDirectory(prefix="tex2img-theme-system-colors-") as work:
        store = os.path.join(work, "ThemeStore.swift")
        with open(store, "w", encoding="utf-8") as f:
            f.write(store_source)
        main = os.path.join(work, "main.swift")
        with open(main, "w", encoding="utf-8") as f:
            f.write(open(os.path.join(ROOT, "tests/ThemeSystemColorRegression.swift"), encoding="utf-8").read())
        name = defaults_guard.unique_tool_name("theme-system-colors")
        binary = os.path.join(work, name)
        subprocess.run(["xcrun", "swiftc", "-module-name", "TeX2img", "-import-objc-header",
                        os.path.join(ROOT, "Sources/Core/Bridging-Header-G.h"), store, *EXTENSIONS, main, "-o", binary], check=True)
        home = os.path.join(work, "home")
        os.makedirs(os.path.join(home, "Library"))
        result = subprocess.run([binary, os.path.join(ROOT, "Resources/Themes")], capture_output=True, text=True,
                                env=dict(os.environ, CFFIXED_USER_HOME=home, HOME=home))
        untouched = defaults_guard.check_untouched(name)
        return result, untouched


def main():
    source = open(STORE, encoding="utf-8").read()
    result, untouched = run(source, "production")
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    if result.returncode or untouched:
        return 1
    if "--mutations" in sys.argv:
        mutations = {
            "no switch: the selection as the cursor": ("        return role == .selection\n", "        return false\n"),
            "switches ignored when drawing": ("        if ThemeSystemColor.uses(role, in: theme), let system = ThemeSystemColor.systemColor(role) { return system }\n", ""),
            "every key compared": ("        for key in keysAddedWithSelection where copy[key] == nil { bundled[key] = nil }\n", ""),
            "only shared keys compared": ("        return sameColors(copy, bundled)\n    }", "        return Set(copy.keys).intersection(bundled.keys).subtracting([\"Title\"]).allSatisfy { NSDictionary(dictionary: [$0: copy[$0]!]).isEqual(to: [$0: bundled[$0]!]) }\n    }"),
            "bundled color not used for a missing one": ("                    x = x ?? components(bundled, key: role.key)\n                    y = y ?? components(bundled, key: role.key)\n", ""),
            "every color filled in from the bundled theme": ("                if role == .selection, ThemeSystemColor.uses(role, in: a)", "                if ThemeSystemColor.uses(role, in: a)"),
            "a missing color taken as the same": ("                return x == y\n", "                return x == y || x == nil || y == nil\n"),
        }
        for name, (old, new) in mutations.items():
            assert source.count(old) == 1, name
            mutated, _ = run(source.replace(old, new), name)
            if mutated.returncode == 0 or "FAIL" not in mutated.stderr:
                print(f"FAIL: the mutation went unnoticed: {name}", file=sys.stderr)
                return 1
            print("DETECTED", name, mutated.stderr.strip().splitlines()[0])
    return 0


if __name__ == "__main__":
    sys.exit(main())
