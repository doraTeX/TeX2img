#!/usr/bin/env python3
"""Ctrl-C on the command-line tool stops the TeX that it runs (TeX runs in a process group of its own, which
Ctrl-C to tex2img's group does not reach). The "TeX" here is a script that waits; nothing is typeset.

The GUI's Abort is checked by test_abort_process_group.py.
Usage: python3 tests/test_cli_interrupt.py --app path/to/TeX2img.app
"""
import argparse
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--app', type=Path, required=True)
args = parser.parse_args()
cli = str(args.app.resolve() / 'Contents/SharedSupport/bin/tex2img')
base = 4000 + os.getpid() % 500 * 2


def tex_running():
    return subprocess.run(['pgrep', '-f', marker], capture_output=True).returncode == 0


marker = ''


failures = []
with tempfile.TemporaryDirectory(prefix='tex2img-interrupt-') as tmp:
    root = Path(tmp)
    (root / 'a.tex').write_text('\\documentclass{article}\\begin{document}x\\end{document}\n')
    # The "TeX" also runs as a program that ignores SIGTERM, as one run by shell escape may (TeXShop 1c7c4a81:
    # SIGTERM to the group, then SIGKILL).
    for signal_number, ignores in ((signal.SIGINT, False), (signal.SIGTERM, False), (signal.SIGINT, True)):
        marker = f'/bin/sleep {base + ignores}'
        fake = root / f'fake-latex-{int(ignores)}'
        fake.write_text('#!/bin/sh\n' + ("trap '' TERM\n" if ignores else '') + f'{marker}\nexit 0\n')
        fake.chmod(0o755)
        # --workingdir current: the files of the stopped run stay in the test's folder, not the shared temporary one.
        process = subprocess.Popen([cli, '--no-preview', '--workingdir', 'current', '--latex', str(fake), '--dvidriver', str(fake),
                                    'a.tex', 'a.png'],
                                   cwd=root, start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(100):
            if tex_running():
                break
            time.sleep(0.1)
        if not tex_running():
            failures.append('the fake TeX did not start')
            os.killpg(process.pid, signal.SIGKILL)
            continue
        os.killpg(process.pid, signal_number)  # Ctrl-C signals the terminal's foreground process group
        process.wait(timeout=20)
        for _ in range(30):
            if not tex_running():
                break
            time.sleep(0.1)
        if tex_running():
            failures.append(f'TeX{" (ignoring SIGTERM)" if ignores else ""} is still running after {signal_number.name} to tex2img')
            subprocess.run(['pkill', '-9', '-f', marker])
        if process.returncode == 0:
            failures.append(f'tex2img ended with 0 after {signal_number.name}')

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: Ctrl-C and SIGTERM to tex2img stop the TeX it runs, also one that ignores SIGTERM')
