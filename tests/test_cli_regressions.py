#!/usr/bin/env python3
"""Checks the command-line tool against what TeX2img 2.x (Objective-C, getopt) did.

Needs pdflatex and gs on PATH.
Usage: python3 tests/test_cli_regressions.py --app path/to/TeX2img.app
"""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from pypdf import PdfReader, PdfWriter
from pypdf.generic import RectangleObject
from PIL import Image

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

    # A CropBox outside the MediaBox is an empty box (it crashed with --keep-page-size --pagebox crop): the EPS file
    # gets the empty bounding box, and the PDF and PNG files keep the whole page, as for any page box that would vanish.
    writer = PdfWriter()
    page = writer.add_blank_page(200, 200)
    page.cropbox = RectangleObject([500, 500, 600, 600])
    writer.write(root / 'outside.pdf')
    for output in ('outside-out.pdf', 'outside-out.eps', 'outside-out.png'):
        result = run('--keep-page-size', '--pagebox', 'crop', 'outside.pdf', output, cwd=root)
        check(result.returncode == 0 and '1 file was generated' in result.stdout and (root / output).exists(),
              f'a CropBox outside the MediaBox to {output}', result)
    eps = (root / 'outside-out.eps').read_bytes() if (root / 'outside-out.eps').exists() else b''
    check(b'%%BoundingBox: 0 0 0 0\n' in eps and b'%%HiResBoundingBox: 0.000000 0.000000 0.000000 0.000000\n' in eps,
          'the EPS file of a CropBox outside the MediaBox has the empty bounding box')
    if (root / 'outside-out.pdf').exists():
        size = [float(v) for v in PdfReader(root / 'outside-out.pdf').pages[0].mediabox]
        check(size == [0, 0, 200, 200], f'the PDF file of a CropBox outside the MediaBox keeps the page: {size}')
    # The PNG image is that of the whole page: as large as the one made with the MediaBox.
    result = run('--keep-page-size', '--pagebox', 'media', 'outside.pdf', 'outside-media.png', cwd=root)
    check(result.returncode == 0 and (root / 'outside-media.png').exists(), 'the PNG image of the MediaBox', result)

    def image_size(name):
        try:
            with Image.open(root / name) as image:
                image.load()
                return image.size
        except Exception:
            return None
    check(image_size('outside-out.png') is not None and image_size('outside-out.png') == image_size('outside-media.png'),
          f'the PNG image of a CropBox outside the MediaBox: {image_size("outside-out.png")}, '
          f'the MediaBox: {image_size("outside-media.png")}')

    # A resolution level that is not a finite number, or too large, does not crash the speed priority mode: Ghostscript
    # gets the resolution of the quality priority mode. The page has text, so it is converted, not left out as empty.
    (root / 'text.tex').write_text('\\documentclass{article}\\pagestyle{empty}\\begin{document}Text\\end{document}\n')
    result = run('--latex', 'pdflatex', '--num', '1', '--no-guess-compile', 'text.tex', 'text.pdf', cwd=root)
    check(result.returncode == 0, 'text.pdf', result)
    for level, resolution in (('nan', 20016), ('inf', 20016), ('1e30', 20016), ('15', 2160)):
        output = root / f'quick-{level}.pdf'
        result = run('--quick', '--resolution', level, 'text.pdf', output.name, cwd=root)
        check(result.returncode == 0 and f'-r{resolution} ' in result.stdout and '1 file was generated' in result.stdout
              and output.exists() and len(PdfReader(output).pages) == 1,
              f'--quick --resolution {level} converts with -r{resolution}', result)

    # Margins whose sum does not fit in Int (it crashed): too large an image is an error, and a bounding box that the
    # margins take out of Int is left as it is.
    huge = str(2 ** 63 - 1)
    result = run('--left-margin', huge, '--right-margin', '1', 'text.pdf', 'huge.png', cwd=root)
    check(result.returncode == 1 and 'error' in (result.stdout + result.stderr).lower() and not (root / 'huge.png').exists(),
          'margins out of Int to PNG end with an error', result)

    def boxes(name):
        """The four numbers of %%BoundingBox and of %%HiResBoundingBox, or None for a file without both."""
        if not (root / name).exists():
            return None
        text = (root / name).read_text(errors='replace')
        integer = re.search(r'^%%BoundingBox: (-?\d+) (-?\d+) (-?\d+) (-?\d+)$', text, re.M)
        hires = re.search(r'^%%HiResBoundingBox: (-?[\d.]+) (-?[\d.]+) (-?[\d.]+) (-?[\d.]+)$', text, re.M)
        if not integer or not hires:
            return None
        return [int(v) for v in integer.groups()], [float(v) for v in hires.groups()]
    result = run('--transparent', 'text.pdf', 'plain.eps', cwd=root)
    check(result.returncode == 0 and boxes('plain.eps') is not None and boxes('plain.eps')[0][2] > boxes('plain.eps')[0][0],
          f'a transparent EPS file: {boxes("plain.eps")}', result)
    result = run('--transparent', '--top-margin', '3', '--left-margin', '2', 'text.pdf', 'margins.eps', cwd=root)
    if boxes('plain.eps') and boxes('margins.eps'):
        (l, b, r, t), (hl, hb, hr, ht) = boxes('plain.eps')
        expected = ([l - 2, b, r, t + 3], [hl - 2, hb, hr, ht + 3])
        check(result.returncode == 0 and boxes('margins.eps') == expected,
              f'margins of a transparent EPS file: {boxes("margins.eps")}, expected {expected}', result)
    else:
        check(False, 'margins of a transparent EPS file', result)
    result = run('--transparent', '--top-margin', huge, '--bottom-margin', '1', 'text.pdf', 'huge.eps', cwd=root)
    check(result.returncode == 0 and boxes('huge.eps') is not None and boxes('huge.eps') == boxes('plain.eps'),
          f'margins out of Int leave both boxes of a transparent EPS file: {boxes("huge.eps")}, plain {boxes("plain.eps")}',
          result)

    # A Ghostscript step that fails fails the conversion; what it wrote is not the output (an EPS file was made).
    fake_gs = root / 'failing-eps-gs'
    fake_gs.write_text('#!/bin/sh\n"%s" "$@"\nstatus=$?\ncase " $* " in *DEVICE=eps2write*|*DEVICE=epswrite*) exit 1 ;; esac\n'
                       'exit $status\n' % shutil.which('gs'))
    fake_gs.chmod(0o755)
    result = run('--gs', str(fake_gs), 'text.pdf', 'failed.eps', cwd=root)
    check(result.returncode == 1 and not (root / 'failed.eps').exists() and '1 file was generated' not in result.stdout,
          'a failed Ghostscript step to EPS ends with 1 and makes no file', result)
    result = run('--gs', str(fake_gs), 'text.pdf', 'not-failed.png', cwd=root)
    check(result.returncode == 0 and image_size('not-failed.png') is not None,
          'the same Ghostscript makes a PNG image (no EPS step)', result)

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
