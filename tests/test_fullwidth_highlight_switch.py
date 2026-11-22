#!/usr/bin/env python3
"""Checks the switch of the highlight of fullwidth letters, digits and symbols (Settings > Editor > Syntax Highlighting) in
the real TeXTextView: off, these characters look exactly like ordinary text in every context and after every coloring;
on again, they get the theme's colors back; a profile without the switch has it on. Also checks that the switch of the
settings window colors the whole text of both views. No window is shown."""
import glob
import os
import shutil
import subprocess
import sys
import tempfile

import controller_actions
import defaults_guard

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = sorted(glob.glob(os.path.join(ROOT, "Sources/Editor/*.swift"))) + [
    os.path.join(ROOT, p) for p in [
        "Sources/Settings/ThemeStore.swift",
        "Sources/Utility/UtilityG.swift",
        "Sources/Utility/Utility.swift",
        "Sources/Core/Types.swift",
        "Sources/Core/GlobalConstants.swift",
        "Sources/Controllers/MyGlyphPopoverController.swift",
    ]] + sorted(glob.glob(os.path.join(ROOT, "Sources/NSString/*.swift"))) + sorted(
    glob.glob(os.path.join(ROOT, "Sources/Extensions/Foundation/*.swift"))) + sorted(
    glob.glob(os.path.join(ROOT, "Sources/Extensions/AppKit/*.swift")))


def check_switch_action():
    """The switch colors the whole text of both views (lines out of view too), not only the visible lines."""
    source = open(os.path.join(ROOT, "Sources/Controllers/ControllerG.swift"), encoding="utf-8").read()
    start = source.index("func fullwidthHighlightChanged(")
    body = source[start:source.index("\n    }\n", start)]
    settings = open(os.path.join(ROOT, "Sources/Settings/ControllerG+Settings.swift"), encoding="utf-8").read()
    ok = ("sourceTextView.colorizeEntireText()" in body and "preambleTextView.colorizeEntireText()" in body
          and "highlightFullwidthCharactersCheckBox = makeSwitch(#selector(fullwidthHighlightChanged(_:)))" in settings)
    if not ok:
        print("FAIL: the switch does not color the whole text of both views", file=sys.stderr)
    return ok


def main():
    if not check_switch_action():
        return 1
    work = tempfile.mkdtemp(prefix="tex2img-fullwidth-switch-")
    try:
        main_file = os.path.join(work, "main.swift")
        with open(os.path.join(ROOT, "tests/FullwidthHighlightSwitchRegression.swift"), encoding="utf-8") as f:
            fixture = f.read()
        # The real actions: the switch of fullwidth letters and symbols, and the change of the theme or its colors.
        with open(main_file, "w", encoding="utf-8") as f:
            f.write(controller_actions.insert(fixture, ["    @IBAction func fullwidthHighlightChanged(", "    func themeColorsChanged()"]))
        binary_dir = os.path.join(work, "bin")
        os.makedirs(binary_dir)
        name = defaults_guard.unique_tool_name("fullwidth-switch")
        binary = os.path.join(binary_dir, name)
        subprocess.run(["xcrun", "swiftc", "-module-name", "TeX2img",
                        "-import-objc-header", os.path.join(ROOT, "Sources/Core/Bridging-Header-G.h"), "-licucore",
                        *SOURCES, os.path.join(ROOT, "tests/MemoryDefaults.swift"), main_file, "-o", binary], check=True)
        shutil.copytree(os.path.join(ROOT, "Resources/Themes"), os.path.join(binary_dir, "Themes"))
        home = os.path.join(work, "home")
        os.makedirs(os.path.join(home, "Library/Application Support"))
        env = dict(os.environ, CFFIXED_USER_HOME=home, HOME=home)
        code = subprocess.run([binary], env=env).returncode
        return code or defaults_guard.check_untouched(name)
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
