#!/usr/bin/env python3
"""Checks the RGB components that the color palette writes (NSColor.rgbComponentsForColorCommand)."""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    work = tempfile.mkdtemp(prefix="tex2img-color-")
    try:
        main_file = os.path.join(work, "main.swift")
        shutil.copy(os.path.join(ROOT, "tests/ColorCommandRegression.swift"), main_file)
        binary = os.path.join(work, "color")
        subprocess.run(["xcrun", "swiftc", os.path.join(ROOT, "Sources/Extensions/AppKit/NSColor-Extension.swift"),
                        main_file, "-o", binary], check=True)
        return subprocess.run([binary]).returncode
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
