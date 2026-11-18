#!/usr/bin/env python3
"""Checks the highlight of matching braces (not for composed text; kept after typing) and the background of fullwidth
characters that a deleted line end puts into a comment, in the real TeXTextView. No window is shown."""
import glob
import os
import shutil
import subprocess
import sys
import tempfile

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


def main():
    work = tempfile.mkdtemp(prefix="tex2img-brace-highlight-")
    try:
        main_file = os.path.join(work, "main.swift")
        shutil.copy(os.path.join(ROOT, "tests/BraceHighlightRegression.swift"), main_file)
        binary_dir = os.path.join(work, "bin")
        os.makedirs(binary_dir)
        binary = os.path.join(binary_dir, "brace-highlight")
        subprocess.run(["xcrun", "swiftc", "-module-name", "TeX2img",
                        "-import-objc-header", os.path.join(ROOT, "Sources/Core/Bridging-Header-G.h"), "-licucore",
                        *SOURCES, main_file, "-o", binary], check=True)
        shutil.copytree(os.path.join(ROOT, "Resources/Themes"), os.path.join(binary_dir, "Themes"))
        home = os.path.join(work, "home")
        os.makedirs(os.path.join(home, "Library/Application Support"))
        env = dict(os.environ, CFFIXED_USER_HOME=home, HOME=home)
        return subprocess.run([binary], env=env).returncode
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
