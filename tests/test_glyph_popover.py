#!/usr/bin/env python3
"""Builds Character Info off screen in English and Japanese and checks what it shows, its counts and its layout.

Usage: python3 tests/test_glyph_popover.py [output-directory]
Images of the popover (light and dark) are written to the output directory. No window is shown.
"""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = [
    "Sources/Controllers/MyGlyphPopoverController.swift",
    "Sources/NSString/NSString-Unicode.swift",
    "Sources/NSString/NSString-Extension.swift",
    "Sources/Extensions/Foundation/String-Extension.swift",
]


def main():
    work = tempfile.mkdtemp(prefix="tex2img-glyph-")
    output = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(work, "images")
    os.makedirs(output, exist_ok=True)
    try:
        binary_dir = os.path.join(work, "bin")
        os.makedirs(binary_dir)
        binary = os.path.join(binary_dir, "glyph-popover")
        main_file = os.path.join(work, "main.swift")
        shutil.copy(os.path.join(ROOT, "tests/GlyphPopoverRegression.swift"), main_file)
        subprocess.run(["xcrun", "swiftc", "-O", "-import-objc-header", os.path.join(ROOT, "Sources/Core/Bridging-Header-G.h"),
                        *[os.path.join(ROOT, s) for s in SOURCES], main_file, "-licucore", "-o", binary], check=True)
        # Bundle.main of a command-line tool is its directory: give it the localizations.
        for language in ("en", "ja"):
            shutil.copytree(os.path.join(ROOT, f"Resources/{language}.lproj"), os.path.join(binary_dir, f"{language}.lproj"),
                            ignore=shutil.ignore_patterns("*.xib"))
        for language in ("en", "ja"):
            result = subprocess.run([binary, output, language, "-AppleLanguages", f"({language})"], capture_output=True, text=True)
            sys.stdout.write(result.stdout)
            sys.stderr.write(result.stderr)
            if result.returncode != 0:
                return result.returncode
        print("Images:", output)
        return 0
    finally:
        shutil.rmtree(os.path.join(work, "bin"), ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
