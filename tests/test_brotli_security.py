#!/usr/bin/env python3
"""固定済みソースをASan/UBSanで検査。--work-rootには同梱ツールのビルド先を指定。"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tarfile
import re

project = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--work-root', type=Path, required=True)
a = p.parse_args()
root = a.work_root.resolve()
spec = json.loads((project / 'ThirdParty/bundled-sources.json').read_text())['brotli']
archive = root / 'downloads' / spec['archive']
assert hashlib.sha256(archive.read_bytes()).hexdigest() == spec['sha256']
src = root / 'src' / spec['source']
# テスト対象が、ハッシュ固定したリリースそのものか確認する。
with tarfile.open(archive) as tar:
    for member in tar.getmembers():
        rel = Path(member.name).parts[1:]
        if member.isfile() and rel and rel[0] == 'c':
            assert (src.joinpath(*rel)).read_bytes() == tar.extractfile(member).read(), member.name
out = root / 'security-tests'
out.mkdir(exist_ok=True)
common = sorted((src / 'c/common').glob('*.c'))
decoder = sorted((src / 'c/dec').glob('*.c'))
for arch in ['arm64', 'x86_64']:
    flags = ['/usr/bin/clang', '-arch', arch, '-mmacosx-version-min=12.0', '-g', '-O1',
             '-fsanitize=address,undefined', '-fno-sanitize-recover=all', '-fno-omit-frame-pointer',
             '-I'+str(src/'c/include'), '-I'+str(src/'c')]
    for name in ['block-switch', 'stream-corpus']:
        sources = [project / 'tests/brotli' / (name+'.c'), *common,
                   *(x for x in decoder if name != 'block-switch' or x.name != 'decode.c')]
        exe = out / (name+'-'+arch)
        subprocess.run([*flags, *map(str, sources), '-o', str(exe)], check=True)
        inputs = sorted((src/'tests/testdata').glob('*.compressed')) if name == 'stream-corpus' else []
        subprocess.run(['/usr/bin/arch', '-'+arch, str(exe), *map(str, inputs)], check=True, timeout=120)
print('PASS: both architectures, ASan + UBSan')

# 実際に配布する2実行ファイル×2スライスのバージョン関数を確認する。
for binary in [project/'Resources/pdftops/pdftops', project/'Resources/mupdf/mudraw']:
    for arch in ['arm64', 'x86_64']:
        symbols = subprocess.check_output(['nm', '-arch', arch, str(binary)], text=True)
        assert len(re.findall(r' T _BrotliDecoderVersion$', symbols, re.M)) == 1
        proc = subprocess.Popen(['otool', '-arch', arch, '-tvV', str(binary)], stdout=subprocess.PIPE, text=True)
        body = []
        try:
            found = False
            for line in proc.stdout:
                if line.strip() == '_BrotliDecoderVersion:': found = True
                if found: body.append(line.strip())
                if found and ('ret' in line or len(body) > 12): break
        finally:
            proc.stdout.close()
            proc.terminate()
            proc.wait()
        text = '\n'.join(body)
        if arch == 'arm64':
            assert re.search(r'mov\s+w0, #0x2001', text) and re.search(r'movk\s+w0, #0x100, lsl #16', text), text
        else:
            assert re.search(r'movl\s+\$0x1002001, %eax', text), text
        print(f'PASS: {binary.name} {arch}: embedded BrotliDecoderVersion = 0x01002001')
