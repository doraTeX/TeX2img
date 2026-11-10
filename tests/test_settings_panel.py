#!/usr/bin/env python3
"""Builds the settings window off screen and checks its structure, search, history and themes.

Usage: python3 tests/test_settings_panel.py [output-directory]
Images of every category (light and dark, English and Japanese) are written to the output directory.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = [
    "Sources/Settings/SettingsUI.swift",
    "Sources/Settings/SettingsWindowController.swift",
    "Sources/Settings/ThemeStore.swift",
    "Sources/Settings/ThemeSettingsController.swift",
    "Sources/Settings/ControllerG+Settings.swift",
    "Sources/Settings/KeyboardShortcuts.swift",
    "Sources/Settings/ShortcutPaneController.swift",
    "Sources/Editor/AutoSelectTextField.swift",
    "Sources/Extensions/AppKit/NSColor-DefaultColor.swift",
    "Sources/Extensions/AppKit/NSColor-Extension.swift",
    "Sources/Extensions/AppKit/NSApplication-Extension.swift",
    "Sources/Extensions/AppKit/NSApperance-Extension.swift",
    "Sources/Extensions/Foundation/NSDictionary-Extension.swift",
]


def main():
    work = tempfile.mkdtemp(prefix="tex2img-settings-")
    output = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(work, "images")
    os.makedirs(output, exist_ok=True)
    try:
        binary_dir = os.path.join(work, "bin")
        os.makedirs(binary_dir)
        binary = os.path.join(binary_dir, "settings-snapshot")
        # Top-level code must be in main.swift.
        main_file = os.path.join(work, "main.swift")
        shutil.copy(os.path.join(ROOT, "tests/SettingsPanelSnapshot.swift"), main_file)
        # Only the setting keys of GlobalConstants.swift; the rest needs the whole app.
        constants = os.path.join(work, "constants.swift")
        with open(os.path.join(ROOT, "Sources/Core/GlobalConstants.swift")) as source, open(constants, "w") as target:
            target.write("import Foundation\n")
            for line in source:
                if re.match(r'(let \w+Key = "[^"]*"|typealias Profile|let (PX_UNIT_TAG|QUALITY_PRIORITY_TAG) = )', line):
                    target.write(line)
        subprocess.run(["xcrun", "swiftc", "-O", "-module-name", "SettingsSnapshot",
                        *[os.path.join(ROOT, s) for s in SOURCES], main_file, constants, "-o", binary], check=True)
        # Bundle.main of a command-line tool is its directory: give it the themes and the localizations.
        shutil.copytree(os.path.join(ROOT, "Resources/Themes"), os.path.join(binary_dir, "Themes"))
        for language in ("en", "ja"):
            shutil.copytree(os.path.join(ROOT, f"Resources/{language}.lproj"), os.path.join(binary_dir, f"{language}.lproj"),
                            ignore=shutil.ignore_patterns("*.xib"))
        for language in ("en", "ja"):
            home = os.path.join(work, f"settings-home/{language}")
            os.makedirs(os.path.join(home, "Library/Application Support"))
            env = dict(os.environ, CFFIXED_USER_HOME=home, HOME=home)
            result = subprocess.run([binary, output, language, "-AppleLanguages", f"({language})"], env=env,
                                    capture_output=True, text=True)
            sys.stdout.write(result.stdout)
            sys.stderr.write(result.stderr)
            if result.returncode != 0:
                return result.returncode
        print("Images:", output)
        return 0
    finally:
        shutil.rmtree(os.path.join(work, "bin"), ignore_errors=True)
        shutil.rmtree(os.path.join(work, "settings-home"), ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
