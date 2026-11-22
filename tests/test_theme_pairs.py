#!/usr/bin/env python3
"""Checks the colors a theme lacks of text and what it is drawn on (TeXShop 6.00): they are chosen so that the text,
the cursor and the output window's text read on their backgrounds, nearest the default colors, and the theme's own
colors stay as they are. ThemeStore.swift is compiled as it is. --mutations changes key parts and the test must fail."""
import os
import subprocess
import sys
import tempfile

import defaults_guard

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORE = os.path.join(ROOT, "Sources/Settings/ThemeStore.swift")
EXTENSIONS = sorted(os.path.join(ROOT, "Sources/Extensions/AppKit", n) for n in os.listdir(os.path.join(ROOT, "Sources/Extensions/AppKit")) if n.endswith(".swift"))


def run(store_source):
    with tempfile.TemporaryDirectory(prefix="tex2img-theme-pairs-") as work:
        store = os.path.join(work, "ThemeStore.swift")
        with open(store, "w", encoding="utf-8") as f:
            f.write(store_source)
        main = os.path.join(work, "main.swift")
        with open(main, "w", encoding="utf-8") as f:
            f.write(open(os.path.join(ROOT, "tests/ThemePairsRegression.swift"), encoding="utf-8").read())
        name = defaults_guard.unique_tool_name("theme-pairs")
        binary = os.path.join(work, name)
        subprocess.run(["xcrun", "swiftc", "-module-name", "TeX2img", "-import-objc-header",
                        os.path.join(ROOT, "Sources/Core/Bridging-Header-G.h"), store, *EXTENSIONS, main, "-o", binary], check=True)
        home = os.path.join(work, "home")
        os.makedirs(os.path.join(home, "Library"))
        result = subprocess.run([binary, os.path.join(ROOT, "Resources/Themes")], capture_output=True, text=True,
                                env=dict(os.environ, CFFIXED_USER_HOME=home, HOME=home), timeout=120)
        untouched = defaults_guard.check_untouched(name)
        return result, untouched


def main():
    source = open(STORE, encoding="utf-8").read()
    result, untouched = run(source)
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    if result.returncode or untouched:
        return 1
    if "--mutations" in sys.argv:
        mutations = {
            "missing colors are the defaults": (" ?? ThemePairs.missingColor(role, in: theme, dark: dark) ?? ", " ?? "),
            "no grays of any lightness": ("        if best < 4.5 - 1e-9 {\n            gray =", "        if false {\n            gray ="),
            "white and black before the defaults": ("var cost: [Double] = [0, 10, 20, 20]", "var cost: [Double] = [20, 10, 0, 0]"),
            "pairs of own colors counted": ("|| (!missing[a] && !missing[b]) { return 4.5 }", "{ return 4.5 }"),
            "the cursor left out": ("[[nil, .text, .background, .cursor], [nil", "[[nil, .text, .background, nil], [nil"),
            "the output window left out": (", [nil, .consoleText, .consoleBackground, nil]]", "]"),
            "no text first when nothing reads": ("let text = solve(enough, 0) != nil ? enough : greatest { solve($0, 0) != nil }",
                                                 "let text = 0.0"),
        }
        for name, (old, new) in mutations.items():
            assert source.count(old) == 1, name
            mutated, _ = run(source.replace(old, new))
            if mutated.returncode == 0 or "FAIL" not in mutated.stderr:
                print(f"FAIL: the mutation went unnoticed: {name}", file=sys.stderr)
                return 1
            print("DETECTED", name, mutated.stderr.strip().splitlines()[0])
    return 0


if __name__ == "__main__":
    sys.exit(main())
