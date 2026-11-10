#!/usr/bin/env python3
"""Checks that invisible-character markers sit on the text baseline and that control characters are shown.

Usage: python3 tests/test_invisible_characters.py [image.png]
No window is shown.
"""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    work = tempfile.mkdtemp(prefix="tex2img-invisible-")
    try:
        main_file = os.path.join(work, "main.swift")
        shutil.copy(os.path.join(ROOT, "tests/InvisibleCharacterBaseline.swift"), main_file)
        binary = os.path.join(work, "invisible")
        subprocess.run(["xcrun", "swiftc", "-module-name", "InvisibleCharacters",
                        os.path.join(ROOT, "Sources/Editor/MyLayoutManager.swift"),
                        os.path.join(ROOT, "Sources/Editor/MyATSTypesetter.swift"),
                        main_file, "-o", binary], check=True)
        arguments = [binary] + ([os.path.abspath(sys.argv[1])] if len(sys.argv) > 1 else [])
        return subprocess.run(arguments).returncode
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
