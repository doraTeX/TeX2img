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
marker = f'/bin/sleep {4000 + os.getpid() % 1000}'


def tex_running():
    return subprocess.run(['pgrep', '-f', marker], capture_output=True).returncode == 0


failures = []
with tempfile.TemporaryDirectory(prefix='tex2img-interrupt-') as tmp:
    root = Path(tmp)
    fake = root / 'fake-latex'
    fake.write_text(f'#!/bin/sh\n{marker}\nexit 0\n')
    fake.chmod(0o755)
    (root / 'a.tex').write_text('\\documentclass{article}\\begin{document}x\\end{document}\n')
    for signal_number in (signal.SIGINT, signal.SIGTERM):
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
            failures.append(f'TeX is still running after {signal_number.name} to tex2img')
            subprocess.run(['pkill', '-f', marker])
        if process.returncode == 0:
            failures.append(f'tex2img ended with 0 after {signal_number.name}')

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: Ctrl-C and SIGTERM to tex2img stop the TeX it runs')
