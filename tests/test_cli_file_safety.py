#!/usr/bin/env python3
"""Checks that the command-line tool fails cleanly and does not destroy files (inputs, outputs, other files).

Needs platex, dvipdfmx and gs on PATH (the default compiler settings are checked before any conversion).
Usage: python3 tests/test_cli_file_safety.py --app path/to/TeX2img.app
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from pypdf import PdfReader, PdfWriter

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--app', type=Path, required=True)
args = parser.parse_args()
cli = str(args.app.resolve() / 'Contents/SharedSupport/bin/tex2img')
failures = []


def run(*arguments, cwd):
    return subprocess.run([cli, '--no-preview', *arguments], capture_output=True, text=True, timeout=300, cwd=cwd)


def contents(path):
    return path.read_bytes() if path.is_file() else None


def check(condition, message, result=None):
    if not condition:
        failures.append(message + ('' if result is None else f'\nexit {result.returncode}\n' + result.stdout[-2000:] + result.stderr))


with tempfile.TemporaryDirectory(prefix='tex2img-file-safety-') as tmp:
    root = Path(tmp)
    writer = PdfWriter()
    writer.add_page(PdfReader(ROOT / 'te st/in put.pdf').pages[1])
    writer.write(root / 'page.pdf')

    # A PDF that needs a password to open: an error, not a crash (exit 133).
    # With its page tree in an encrypted object stream, PDFKit counts no pages.
    qpdf = shutil.which('qpdf')
    check(qpdf is not None, 'qpdf is needed on PATH')
    if qpdf:
        subprocess.run([qpdf, '--object-streams=generate', '--encrypt', 'user', 'owner', '256', '--',
                        str(root / 'page.pdf'), str(root / 'locked.pdf')], check=True)
    locked = PdfWriter(clone_from=root / 'page.pdf')
    locked.encrypt(user_password='user', owner_password='owner', algorithm='RC4-128')
    locked.write(root / 'locked-rc4.pdf')
    for source in ('locked.pdf', 'locked-rc4.pdf'):
        for output in ('out.png', 'out.pdf', 'out.svg', 'out.eps'):
            result = run('--quiet', source, output, cwd=root)
            check(result.returncode == 1 and 'Invalid file format' in result.stderr and not (root / output).exists(),
                  f'{source} to {output} ends with an error', result)

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('CLI file safety tests passed')
