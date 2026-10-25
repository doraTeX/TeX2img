#!/usr/bin/env python3
"""同梱ツールを両CPUで起動し、日本語/CMapとBrotli PDFストリームを検証する。"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

project = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--work-root', type=Path, required=True)
a = p.parse_args()

def pdf(stream):
    objects = [b'<< /Type /Catalog /Pages 2 0 R >>', b'<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
               b'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 240 100] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
               b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
               b'<< /Length '+str(len(stream)).encode()+b' /Filter /BrotliDecode >>\nstream\n'+stream+b'\nendstream']
    data = b'%PDF-2.0\n'; offsets = [0]
    for n,obj in enumerate(objects,1):
        offsets.append(len(data)); data += str(n).encode()+b' 0 obj\n'+obj+b'\nendobj\n'
    xref=len(data);data += b'xref\n0 6\n0000000000 65535 f \n'
    data += b''.join(f'{offset:010} 00000 n \n'.encode() for offset in offsets[1:])
    return data+f'trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n'.encode()

with tempfile.TemporaryDirectory(prefix='tex2img relocated tools ') as tmp:
    root = Path(tmp)
    # 元のビルド・配布ディレクトリ以外でも動作し、スペースを含むパスも使えること。
    shutil.copytree(project/'Resources/pdftops',root/'pdftops')
    shutil.copytree(project/'Resources/mupdf',root/'mupdf')
    content = b'BT /F1 18 Tf 20 40 Td (Brotli 1.2.1 regression) Tj ET\n'
    encoder = a.work_root.resolve()/'arm64/prefix/bin/brotli'
    compressed = subprocess.check_output([str(encoder),'-c'],input=content)
    valid = root/'brotli.pdf'; valid.write_bytes(pdf(compressed))
    invalid = root/'invalid.pdf'; invalid.write_bytes(pdf(b'\xff'*16))
    env = os.environ.copy()
    for key in ['FONTCONFIG_FILE','FONTCONFIG_PATH','DYLD_LIBRARY_PATH','DYLD_FALLBACK_LIBRARY_PATH']:
        env.pop(key,None)
    for arch in ['arm64','x86_64']:
        def run(tool, args, ok=True):
            cmd=['/usr/bin/arch','-'+arch,str(root/tool),*map(str,args)]
            r=subprocess.run(cmd,capture_output=True,text=True,env=env,timeout=60)
            assert r.returncode >= 0, (cmd,r.stderr)
            if ok:
                assert r.returncode == 0, (cmd,r.stderr)
                assert not any(s in r.stderr for s in ['Syntax Error','Unknown font','Missing language','error:']),r.stderr
            return r
        eps=root/(arch+'.eps')
        run('pdftops/pdftops',['-eps',valid,eps])
        assert b'Brotli' in eps.read_bytes()
        txt=root/(arch+'.txt')
        run('mupdf/mudraw',['-F','txt','-o',txt,valid])
        assert 'Brotli 1.2.1 regression' in txt.read_text()
        run('pdftops/pdftops',['-eps',invalid,root/(arch+'-bad.eps')],False)
        run('mupdf/mudraw',['-F','txt','-o',root/(arch+'-bad.txt'),invalid],False)
        for page in [2,4,6,7,8]:
            run('pdftops/pdftops',['-f',page,'-l',page,'-eps',project/'te st/in put.pdf',eps])
            assert eps.stat().st_size>1000
            svg=root/(arch+str(page)+'.svg')
            run('mupdf/mudraw',['-o',svg,project/'te st/in put.pdf',page])
            tree=ET.parse(svg)
            assert any(el.tag.endswith('path') or el.tag.endswith('image') for el in tree.iter())
        print(f'PASS: {arch}: Brotli PDF decode, malformed stream, 5 Japanese PDF pages to EPS/SVG, relocated bundle')
