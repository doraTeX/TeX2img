#!/usr/bin/env python3
"""Checks that a change of the theme or of one of its colors, and of the appearance, keeps the highlight of braces and of
enclosed contents in both editors, drawn in the new colors, with the switch of fullwidth letters and symbols on and off;
and that ControllerG.themeColorsChanged recolors both editors that way, without ending the highlights. No window is shown."""
import glob
import os
import shutil
import subprocess
import sys
import tempfile

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


def check_theme_action():
    """ControllerG.themeColorsChanged keeps the highlights: it recolors both editors and ends nothing."""
    source = open(os.path.join(ROOT, "Sources/Controllers/ControllerG.swift"), encoding="utf-8").read()
    start = source.index("func themeColorsChanged(")
    body = source[start:source.index("\n    }\n", start)]
    ok = ("sourceTextView.recolorForThemeChange()" in body and "preambleTextView.recolorForThemeChange()" in body
          and "resetBackgroundColor" not in body and "refreshSelectionHighlighting" not in body)
    if not ok:
        print("FAIL: themeColorsChanged ends the highlights or does not recolor both editors", file=sys.stderr)
    return ok


def main():
    if not check_theme_action():
        return 1
    work = tempfile.mkdtemp(prefix="tex2img-theme-change-")
    try:
        main_file = os.path.join(work, "main.swift")
        shutil.copy(os.path.join(ROOT, "tests/ThemeChangeHighlightRegression.swift"), main_file)
        binary_dir = os.path.join(work, "bin")
        os.makedirs(binary_dir)
        name = defaults_guard.unique_tool_name("theme-change")
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
