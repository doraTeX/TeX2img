#!/usr/bin/env python3
"""Checks the character conversions (Unicode, \\UTF, \\CID, ajmacros, Modified NFD)."""
import glob
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def check_import_decodes_utf():
    """Importing a source (from an image or a .tex file) decodes the \\UTF commands that \\UTF output wrote."""
    with open(os.path.join(ROOT, "Sources/Controllers/ControllerG.swift"), encoding="utf-8") as f:
        source = f.read()
    start = source.index("private func placeImportedSource(")
    body = source[start:source.index("\n    }\n", start)]
    if "stringByDecodingUTFCommandsForReading()" not in body:
        print("FAIL: placeImportedSource does not decode \\UTF commands", file=sys.stderr)
        return False
    return True


def main():
    if not check_import_decodes_utf():
        return 1
    work = tempfile.mkdtemp(prefix="tex2img-conversion-")
    try:
        main_file = os.path.join(work, "main.swift")
        shutil.copy(os.path.join(ROOT, "tests/CharacterConversionRegression.swift"), main_file)
        binary = os.path.join(work, "conversion")
        sources = sorted(glob.glob(os.path.join(ROOT, "Sources/NSString/*.swift"))) + sorted(
            glob.glob(os.path.join(ROOT, "Sources/Extensions/Foundation/*.swift"))) + [
            os.path.join(ROOT, "Sources/Extensions/AppKit/NSColor-Extension.swift")]
        subprocess.run(["xcrun", "swiftc", "-module-name", "Conversion",
                        "-import-objc-header", os.path.join(ROOT, "Sources/Core/Bridging-Header-G.h"), "-licucore",
                        *sources, main_file, "-o", binary], check=True)
        # Bundle.main of a command-line tool is its directory: the CID table is read from there.
        shutil.copy(os.path.join(ROOT, "Resources/cidToUnicode.json"), work)
        return subprocess.run([binary]).returncode
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
