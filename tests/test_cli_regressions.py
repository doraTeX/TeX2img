#!/usr/bin/env python3
"""Checks the command-line tool against what TeX2img 2.x (Objective-C, getopt) did.

Needs pdflatex and gs on PATH.
Usage: python3 tests/test_cli_regressions.py --app path/to/TeX2img.app
"""
import argparse
from pathlib import Path
import subprocess
import sys
import tempfile
from pypdf import PdfReader, PdfWriter
from pypdf.generic import RectangleObject

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--app', type=Path, required=True)
args = parser.parse_args()
cli = str(args.app.resolve() / 'Contents/SharedSupport/bin/tex2img')
failures = []


def run(*arguments, cwd):
    return subprocess.run([cli, '--no-preview', *arguments], capture_output=True, text=True, timeout=300, cwd=cwd)


def check(condition, message, result=None):
    if not condition:
        failures.append(message + ('' if result is None else '\n' + result.stdout + result.stderr))


with tempfile.TemporaryDirectory(prefix='tex2img-cli-regressions-') as tmp:
    root = Path(tmp)
    (root / 'two.tex').write_text('\\documentclass{article}\\pagestyle{empty}\\begin{document}One\\newpage Two\\end{document}\n')
    result = run('--latex', 'pdflatex', '--num', '1', '--no-guess-compile', '--merge-output-files', 'two.tex', 'two.pdf', cwd=root)
    check(result.returncode == 0 and len(PdfReader(root / 'two.pdf').pages) == 2, 'a two-page PDF', result)

    # A text-keeping SVG merged into one file is the animated SVG (it failed without a message).
    result = run('--with-text', '--merge-output-files', 'two.pdf', 'anim.svg', cwd=root)
    check(result.returncode == 0 and (root / 'anim.svg').exists(), '--with-text --merge-output-files to SVG', result)

    # --pagebox sets the page size kept with --keep-page-size (it was always the MediaBox).
    writer = PdfWriter()
    page = writer.add_blank_page(596, 842)
    page.cropbox = RectangleObject([100, 500, 300, 700])
    writer.write(root / 'crop.pdf')
    for box, expected in (('crop', [100, 500, 300, 700]), ('media', [0, 0, 596, 842])):
        output = root / f'out-{box}.pdf'
        result = run('--keep-page-size', '--pagebox', box, 'crop.pdf', output.name, cwd=root)
        size = [float(v) for v in PdfReader(output).pages[0].mediabox] if output.exists() else None
        check(size == expected, f'--pagebox {box}: {size}', result)

    # --num 0 compiles once (it crashed).
    (root / 'one.tex').write_text('\\documentclass{article}\\pagestyle{empty}\\begin{document}X\\end{document}\n')
    result = run('--latex', 'pdflatex', '--num', '0', 'one.tex', 'one.png', cwd=root)
    check(result.returncode == 0, '--num 0', result)

    # Guessing stops when the aux file stops changing (the first aux was kept as the reference).
    (root / 'aux.tex').write_text(
        '\\documentclass{article}\\pagestyle{empty}\\makeatletter\n'
        '\\AtBeginDocument{\\@ifundefined{foo}{\\immediate\\write\\@auxout{\\gdef\\string\\foo{1}}}'
        '{\\immediate\\write\\@auxout{\\gdef\\string\\foo{2}}}}\n'
        '\\makeatother\\begin{document}X\\end{document}\n')
    result = run('--latex', 'pdflatex', '--num', '5', 'aux.tex', 'aux.png', cwd=root)
    compilations = sum(1 for line in result.stdout.splitlines() if line.startswith('$ ') and 'pdflatex' in line)
    check(result.returncode == 0 and compilations == 3, f'aux guessing compiles 3 times, not {compilations}', result)

    # Options apply in order, abbreviations and negative values are read as getopt did.
    def status(*options):
        return run(*options, 'two.pdf', 'o.png', cwd=root).stdout
    check('Left   margin: 20px' in status('--margins', '0', '--left-margin', '20'), 'a margin after --margins wins')
    check('Left   margin: 0px' in status('--left-margin', '20', '--margins', '0'), '--margins after a margin wins')
    check('Transparent: enabled' in status('--background-color', 'red', '--transparent'), '--transparent after --background-color')
    check('Transparent: disabled' in status('--transparent', '--background-color', 'red'), '--background-color after --transparent')
    check('Resolution level: 3.000000' in status('--res', '3'), 'an abbreviated option')
    result = run('--left-margin', '-5', 'two.pdf', 'o.png', cwd=root)
    check(result.returncode == 1 and 'Margins must not be negative' in result.stderr, 'a negative value is a value', result)
    result = run('--bogus', 'two.pdf', 'o.png', cwd=root)
    check(result.returncode == 1 and 'Usage: tex2img' in result.stdout, 'an unknown option prints the usage and ends with 1', result)
    result = run('--with-text', '--merge-output-files', 'two.pdf', cwd=root)
    check(result.returncode == 1, 'a missing output file ends with 1', result)

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('CLI regression tests passed')
