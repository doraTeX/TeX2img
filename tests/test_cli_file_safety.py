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

    # The working folder and the output folder are one folder written two ways (a symbolic link): the image is
    # made, also the second time (it was removed with the existing output, exit 1 without a message).
    real = root / 'real'
    real.mkdir()
    (real / 'page.pdf').write_bytes((root / 'page.pdf').read_bytes())
    link = root / 'link'
    link.symlink_to(real)
    for attempt in (1, 2):
        result = run('--quiet', '--workingdir', 'current', 'page.pdf', str(link / 'out.png'), cwd=link)
        check(result.returncode == 0 and (real / 'out.png').is_file(), f'output through a symbolic link, run {attempt}', result)

    # The working folder is the input's folder and the output goes elsewhere: files in the working folder with
    # the output's name are not replaced or removed (they were), the input among them.
    source = root / 'src'
    dest = root / 'dest'
    source.mkdir()
    dest.mkdir()
    precious = b"the user's own file\n"
    (source / 'fig.png').write_bytes(precious)
    (source / 'fig.pdf').write_bytes((root / 'page.pdf').read_bytes())
    original_input = (source / 'fig.pdf').read_bytes()
    for workingdir, cwd in (('file', root), ('current', source)):
        for output in ('fig.png', 'fig.pdf'):
            result = run('--quiet', '--workingdir', workingdir, str(source / 'fig.pdf'), str(dest / output), cwd=cwd)
            check(result.returncode == 0 and (dest / output).is_file(), f'--workingdir {workingdir} to {output}', result)
            check(contents(source / 'fig.png') == precious, f'--workingdir {workingdir} to {output} kept src/fig.png')
            check(contents(source / 'fig.pdf') == original_input, f'--workingdir {workingdir} to {output} kept the input')
            (dest / output).unlink(missing_ok=True)

    # The output file is the input file, however written: an error, and nothing is written.
    for output in ('same.pdf', './same.pdf', 'real/../same.pdf', str(root / 'same.pdf')):
        (root / 'same.pdf').write_bytes(original_input)
        result = run('--quiet', 'same.pdf', output, cwd=root)
        check(result.returncode == 1 and 'is the input file' in result.stderr
              and contents(root / 'same.pdf') == original_input, f'input same.pdf, output {output}', result)
    # A page-numbered output file (page 2 of fig.pdf is fig-2.pdf) that is the input: no page is written.
    two = PdfWriter()
    for _ in range(2):
        two.add_page(PdfReader(root / 'page.pdf').pages[0])
    two.write(root / 'fig-2.pdf')
    two_bytes = (root / 'fig-2.pdf').read_bytes()
    result = run('--quiet', 'fig-2.pdf', 'fig.pdf', cwd=root)
    check(result.returncode == 1 and 'is the input file' in result.stderr and not (root / 'fig.pdf').exists()
          and contents(root / 'fig-2.pdf') == two_bytes, 'a page-numbered output that is the input', result)
    result = run('--quiet', '--merge-output-files', 'fig-2.pdf', 'fig.pdf', cwd=root)
    check(result.returncode == 0 and (root / 'fig.pdf').is_file() and len(PdfReader(root / 'fig.pdf').pages) == 2,
          'merged into fig.pdf', result)

    # An output folder that cannot be written: an error message, not only the exit status.
    locked_dir = root / 'readonly'
    locked_dir.mkdir()
    locked_dir.chmod(0o555)
    try:
        result = run('--quiet', 'page.pdf', str(locked_dir / 'out.png'), cwd=root)
        check(result.returncode == 1 and 'cannot be created' in result.stderr, 'an output folder that cannot be written', result)
    finally:
        locked_dir.chmod(0o755)

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('CLI file safety tests passed')
