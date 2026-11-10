#!/usr/bin/env python3
"""Checks command completion (Tab/Escape) in the real TeXTextView, off screen."""
import glob
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    work = tempfile.mkdtemp(prefix="tex2img-completion-")
    try:
        binary_dir = os.path.join(work, "bin")
        os.makedirs(binary_dir)
        main_file = os.path.join(work, "main.swift")
        shutil.copy(os.path.join(ROOT, "tests/CommandCompletionRegression.swift"), main_file)
        sources = []
        for pattern in ["Sources/Editor/*.swift", "Sources/NSString/*.swift", "Sources/Extensions/Foundation/*.swift",
                        "Sources/Extensions/AppKit/*.swift"]:
            sources += sorted(glob.glob(os.path.join(ROOT, pattern)))
        sources += [os.path.join(ROOT, p) for p in ["Sources/Settings/ThemeStore.swift", "Sources/Utility/UtilityG.swift",
                                                    "Sources/Utility/Utility.swift", "Sources/Core/Types.swift",
                                                    "Sources/Core/GlobalConstants.swift",
                                                    "Sources/Controllers/MyGlyphPopoverController.swift"]]
        binary = os.path.join(binary_dir, "completion")
        subprocess.run(["xcrun", "swiftc", "-module-name", "TeX2img",
                        "-import-objc-header", os.path.join(ROOT, "Sources/Core/Bridging-Header-G.h"), "-licucore",
                        *sources, main_file, "-o", binary], check=True)
        shutil.copytree(os.path.join(ROOT, "Resources/Themes"), os.path.join(binary_dir, "Themes"))
        home = os.path.join(work, "home")
        os.makedirs(os.path.join(home, "Library/Application Support"))
        env = dict(os.environ, CFFIXED_USER_HOME=home, HOME=home)
        return subprocess.run([binary], env=env, timeout=120).returncode
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
