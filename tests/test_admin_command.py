#!/usr/bin/env python3
"""Checks the command that installs the tex2img command-line tool with administrator privileges.

Paths with spaces, quotes, backslashes and $ must stay one argument each. The AppleScript is not run with
administrator privileges: osascript only reads its string literal, and the shell script is run as the user.
"""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PREFIX = 'do shell script "'
SUFFIX = '" with administrator privileges'

MAIN = r'''
import Foundation
let args = CommandLine.arguments
let (dir, app, link) = (args[1], args[2], args[3])
let script = "mkdir -p \(link.deletingLastPathComponent.quotingForShell()) && ln -sf \(app.quotingForShell()) \(link.quotingForShell())"
print(String.administratorShellAppleScript(command: "/bin/sh", directory: dir, arguments: ["-c", script]), terminator: "")
'''


def main():
    work = tempfile.mkdtemp(prefix="tex2img-admin-")
    try:
        main_file = os.path.join(work, "main.swift")
        with open(main_file, "w") as f:
            f.write(MAIN)
        binary = os.path.join(work, "admin")
        subprocess.run(["xcrun", "swiftc", os.path.join(ROOT, "Sources/Extensions/Foundation/String-Extension.swift"),
                        os.path.join(ROOT, "Sources/NSString/NSString-Extension.swift"), main_file, "-o", binary], check=True)
        odd = "TeX2img's \"app\" $HOME \\ `x` 日本語"
        directory = os.path.join(work, "work dir")
        os.makedirs(directory)
        app = os.path.join(work, odd, "TeX2img.app/Contents/Resources/bin/tex2img")
        link = os.path.join(work, "usr local", odd, "bin/tex2img")
        applescript = subprocess.run([binary, directory, app, link], capture_output=True, text=True, check=True).stdout
        if not (applescript.startswith(PREFIX) and applescript.endswith(SUFFIX)):
            print("FAIL: unexpected AppleScript: " + applescript, file=sys.stderr)
            return 1
        literal = applescript[len(PREFIX) - 1:-len(SUFFIX) + 1]
        shell = subprocess.run(["osascript", "-e", "return " + literal], capture_output=True, text=True, check=True).stdout[:-1]
        subprocess.run(["/bin/sh", "-c", shell], check=True)
        if os.readlink(link) != app:
            print("FAIL: the link points to %r, not %r" % (os.readlink(link), app), file=sys.stderr)
            return 1
        print("Administrator command tests passed")
        return 0
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
