#!/usr/bin/env python3
"""Checks the reading of TeX output for the output window (ConsoleOutputDecoder)."""
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    work = tempfile.mkdtemp(prefix="tex2img-console-")
    try:
        main_file = os.path.join(work, "main.swift")
        shutil.copy(os.path.join(ROOT, "tests/ConsoleOutputRegression.swift"), main_file)
        constants = os.path.join(work, "constants.swift")
        with open(os.path.join(ROOT, "Sources/Core/GlobalConstants.swift")) as source, open(constants, "w") as target:
            for line in source:
                if re.match(r'let PTEX_ENCODING_\w+ = "[^"]*"', line):
                    target.write(line)
        binary = os.path.join(work, "console")
        subprocess.run(["xcrun", "swiftc", "-module-name", "ConsoleOutput",
                        os.path.join(ROOT, "Sources/Utility/ConsoleOutputDecoder.swift"), constants, main_file, "-o", binary], check=True)
        return subprocess.run([binary]).returncode
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
