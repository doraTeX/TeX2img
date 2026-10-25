#!/usr/bin/env python3
"""ページ構成を保つクロップでメッシュとTeX原稿の再編集情報を保持する。"""
import argparse
import re
from pathlib import Path
import subprocess
import tempfile
from pypdf import PdfReader, PdfWriter, Transformation
from pypdf.generic import ArrayObject, DictionaryObject, IndirectObject, RectangleObject

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--app', type=Path, required=True)
parser.add_argument('--arch', choices=['all', 'arm64', 'x86_64'], default='all')
args = parser.parse_args()
project = Path(__file__).resolve().parents[1]
cli = args.app.resolve()/'Contents/SharedSupport/bin/tex2img'
fixture = project/'te st/pgfplots-surf.pdf'

def shading_count(path):
    doc = PdfReader(path)
    seen = set()
    count = 0
    def visit(value):
        nonlocal count
        if isinstance(value, IndirectObject):
            key = (value.generation, value.idnum)
            if key not in seen:
                seen.add(key)
                visit(value.get_object())
        elif isinstance(value, DictionaryObject):
            count += value.get('/ShadingType') == 4
            for item in value.values():
                visit(item)
        elif isinstance(value, ArrayObject):
            for item in value:
                visit(item)
    visit(doc.trailer)
    return count

expected_shadings = shading_count(fixture)
assert expected_shadings > 0
with tempfile.TemporaryDirectory(prefix='tex2img-pdfkit-preserve-') as tmp:
    root = Path(tmp)
    (root/'mesh.pdf').write_bytes(fixture.read_bytes())
    source = root/'source.tex'
    source.write_text(r"""% 日本語の原稿: 再編集テスト
\pdfoutput=1
\pdfminorversion=7
\pdfpagewidth=146.162bp
\pdfpageheight=91.331bp
\pdfhorigin=0pt
\pdfvorigin=0pt
\pdfximage{mesh.pdf}
\shipout\hbox{\pdfrefximage\pdflastximage}
\end
""")
    for arch in (['arm64','x86_64'] if args.arch == 'all' else [args.arch]):
        cases = [('mesh', fixture, ['--with-text']),
                 ('margins', fixture, ['--with-text','--margins','10']),
                 ('outline', fixture, ['--no-with-text']),
                 ('source', source, ['--latex','pdftex','--with-text'])]
        for rotation in [0, 90, 180, 270]:
            writer = PdfWriter()
            page = writer.add_page(PdfReader(fixture).pages[0])
            page.add_transformation(Transformation().translate(20,30))
            box = page.mediabox
            page.mediabox = RectangleObject([box.left+20,box.bottom+30,box.right+20,box.top+30])
            page.cropbox = page.mediabox
            page.rotate(rotation)
            path = root/f'rotated-{rotation}.pdf'
            writer.write(path)
            cases.append((f'rotation-{rotation}',path,['--with-text','--margins','10']))
        for label, input_path, flags in cases:
            output = root/f'{arch}-{label}.pdf'
            result = subprocess.run(['/usr/bin/arch','-'+arch,str(cli),'--resolution','6',
                                     *flags,str(input_path),str(output)],capture_output=True,text=True,timeout=120)
            assert result.returncode == 0, result.stdout+result.stderr
            assert shading_count(output) == expected_shadings, label
            doc = PdfReader(output)
            assert len(doc.pages)==1 and doc.pages[0].mediabox.width>0 and doc.pages[0].mediabox.height>0
            if label.startswith('rotation-'):
                assert doc.pages[0].get('/Rotate',0)==int(label.split('-')[1])
                reference=PdfWriter()
                page=reference.add_page(PdfReader(input_path).pages[0])
                page.mediabox=doc.pages[0].mediabox
                page.cropbox=doc.pages[0].cropbox
                reference_path=root/'reference.pdf'
                reference.write(reference_path)
                hashes=[]
                for path in [reference_path,output]:
                    rendering=subprocess.run([str(args.app.resolve()/'Contents/Resources/mupdf/mudraw'),
                                              '-s5','-r72','-F','png','-o','/dev/null',str(path)],
                                             capture_output=True,text=True,timeout=60)
                    assert rendering.returncode==0,rendering.stderr
                    hashes.append(re.findall(r'[0-9a-f]{32}',rendering.stdout+rendering.stderr)[-1])
                assert hashes[0]==hashes[1],(label,hashes)
            if label=='source':
                annotations = [item.get_object() for item in doc.pages[0]['/Annots']]
                notes = [a for a in annotations if a.get('/Contents','').startswith('%%TeX2img Document\n')]
                assert len(notes)==1 and notes[0]['/Contents']=='%%TeX2img Document\n'+source.read_text()
                assert notes[0]['/F'] & 32 and not notes[0]['/F'] & 4
                value=subprocess.check_output(['/usr/bin/xattr','-px','com.loveinequality.TeX2img',str(output)],text=True)
                assert bytes.fromhex(value).decode()==source.read_text()
            print(f'PASS: {arch} {label}; {expected_shadings} meshes preserved',flush=True)
