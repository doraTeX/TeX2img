#!/usr/bin/env python3
"""ReleaseアプリのCLIを両CPUで実行し、使用ツールの絶対パスと変換内容を検査。"""
import argparse
import os
import re
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pypdf import PdfReader, PdfWriter
from PIL import Image

project = Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--app',type=Path,required=True)
a=p.parse_args();app=a.app.resolve();resources=app/'Contents/Resources'
with tempfile.TemporaryDirectory(prefix='tex2img-app-test-') as tmp:
    root=Path(tmp)
    writer=PdfWriter();writer.add_page(PdfReader(project/'te st/in put.pdf').pages[1]);writer.write(root/'input.pdf')
    env=os.environ.copy()
    env['PATH']=':'.join(str(resources/x) for x in ['pdftops','mupdf',''])+':'+env['PATH']
    for arch in ['arm64','x86_64']:
        for label,ext,flags in [('eps','eps',['--plain-text']),('svg','svg',[]),('svg-text','svg',['--with-text']),('pdf','pdf',['--with-text']),('png','png',[])]:
            output=root/(arch+'-'+label+'.'+ext)
            cmd=['/usr/bin/arch','-'+arch,str(app/'Contents/SharedSupport/bin/tex2img'),'--resolution','72',*flags,str(root/'input.pdf'),str(output)]
            result=subprocess.run(cmd,capture_output=True,text=True,env=env,timeout=120)
            log=result.stdout+result.stderr
            assert result.returncode==0,log
            for tool,rel in [('epstopdf','epstopdf'),('mudraw','mupdf/mudraw'),('pdftops','pdftops/pdftops')]:
                match=re.search(r'^'+tool+r': (.+)$',log,re.M)
                assert match and Path(match[1]).resolve()==(resources/rel).resolve(),log
            assert output.is_file() and output.stat().st_size>100
            if ext=='svg':
                tree=ET.parse(output)
                if label=='svg-text':
                    text=''.join(el.attrib.get('data-text','') for el in tree.iter())
                    assert 'こんにちは' in text, text
            elif ext=='pdf':
                assert len(PdfReader(output).pages)==1
            elif ext=='png':
                image=Image.open(output);assert image.width>100 and image.getbbox() is not None
            print(f'PASS: {arch} {label}; all helper paths are inside the tested app')

    # SVGを書いてから失敗する変換ツールでも、成功扱いして後処理を飛ばさない。
    import shlex
    import shutil
    failing_app = root/'Failing.app'
    failing_bin = failing_app/'Contents/SharedSupport/bin'
    failing_resources = failing_app/'Contents/Resources'
    failing_bin.mkdir(parents=True)
    (failing_resources/'mupdf').mkdir(parents=True)
    shutil.copy2(app/'Contents/SharedSupport/bin/tex2img', failing_bin/'tex2img')
    for name in ['pdftops', 'epstopdf']:
        (failing_resources/name).symlink_to(resources/name)
    wrapper = failing_resources/'mupdf/mudraw'
    wrapper.write_text('#!/bin/sh\n'+shlex.quote(str(resources/'mupdf/mudraw'))+' "$@"\nexit 1\n')
    wrapper.chmod(0o755)
    for arch in ['arm64', 'x86_64']:
        output = root/(arch+'-failure.svg')
        result = subprocess.run(['/usr/bin/arch', '-'+arch, str(failing_bin/'tex2img'),
                                 '--no-with-text', str(root/'input.pdf'), str(output)],
                                capture_output=True, text=True, env=env, timeout=120)
        assert result.returncode > 0, result.stdout + result.stderr
        print(f'PASS: {arch} SVG converter failure is propagated')
