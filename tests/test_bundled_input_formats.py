#!/usr/bin/env python3
"""TeX/PS/EPS入力、SVGZ出力、不正入力を両CPUのCLIで検査する。"""
import argparse
import gzip
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pypdf import PdfReader, PdfWriter

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--app', type=Path, required=True)
parser.add_argument('--arch', choices=['all', 'arm64', 'x86_64'], default='all')
args = parser.parse_args()
cli = args.app.resolve() / 'Contents/SharedSupport/bin/tex2img'
project = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='tex2img-input-tests-') as tmp:
    root = Path(tmp) / '日本語 入力'
    root.mkdir()
    (root / '数式.tex').write_text(r'\pdfoutput=1\nopagenumbers $$\int_0^1 x^2\,dx={1\over3}$$\bye' + '\n')
    drawing = '/Times-Roman findfont 24 scalefont setfont 100 100 moveto (TeX2img input test) show showpage\n'
    (root / 'input.ps').write_text('%!PS-Adobe-3.0\n' + drawing)
    (root / 'input.eps').write_text('%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 95 95 350 130\n' + drawing)
    (root / 'invalid.pdf').write_bytes(b'not a PDF\n')
    writer = PdfWriter()
    writer.add_page(PdfReader(project / 'te st/in put.pdf').pages[1])
    writer.write(root / 'input.pdf')
    cases = [('tex', '数式.tex', 'pdf', ['--latex', 'pdftex']),
             ('ps', 'input.ps', 'pdf', []), ('eps', 'input.eps', 'pdf', []),
             ('svgz', 'input.pdf', 'svgz', ['--delete-display-size'])]
    for arch in (['arm64', 'x86_64'] if args.arch == 'all' else [args.arch]):
        for name, source, ext, flags in cases:
            output = root / (arch + '-' + name + '.' + ext)
            result = subprocess.run(['/usr/bin/arch', '-' + arch, str(cli), '--no-preview',
                                     *flags, str(root / source), str(output)],
                                    capture_output=True, text=True, timeout=120)
            assert result.returncode == 0, result.stdout + result.stderr
            if ext == 'pdf':
                assert len(PdfReader(output).pages) == 1
            else:
                svg = ET.fromstring(gzip.decompress(output.read_bytes()))
                assert 'width' not in svg.attrib and 'height' not in svg.attrib
            print(f'PASS: {arch} {name}', flush=True)
        for source in ['invalid.pdf', 'missing.pdf']:
            output = root / (arch + '-' + source + '.png')
            result = subprocess.run(['/usr/bin/arch', '-' + arch, str(cli),
                                     str(root / source), str(output)],
                                    capture_output=True, text=True, timeout=30)
            assert result.returncode > 0 and not output.exists(), result.stdout + result.stderr
            print(f'PASS: {arch} {source}: controlled failure', flush=True)
