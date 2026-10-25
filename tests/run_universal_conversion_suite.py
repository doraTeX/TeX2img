#!/usr/bin/env python3
"""同梱CLIと変換ツールを指定CPUに固定し、既存80件を隔離実行する。"""
import argparse
import importlib.util
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--app', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True, help='未作成のテスト出力ディレクトリ')
parser.add_argument('--arch', choices=['arm64', 'x86_64'], required=True)
args = parser.parse_args()
app = args.app.resolve()
work = args.output.resolve()
work.mkdir(parents=True, exist_ok=False)
project = Path(__file__).resolve().parents[1]
for name in ['in put.pdf', 'in put.tex', 'pgfplots-surf.pdf', 'test.sh',
             'mesh-shading-known-issue.sh', 'run_verified_tests.py']:
    shutil.copy2(project/'te st'/name, work/name)
copy = work/'TeX2img.app'
subprocess.run(['ditto', '--norsrc', '--noextattr', str(app), str(copy)], check=True)
# archで親だけを指定しても子プロセスがnativeに戻り得るため、テスト用コピーをthin化。
for relative in ['SharedSupport/bin/tex2img', 'Resources/pdftops/pdftops', 'Resources/mupdf/mudraw']:
    binary = copy/'Contents'/relative
    subprocess.run(['lipo', str(app/'Contents'/relative), '-thin', args.arch,
                    '-output', str(binary)], check=True)
    subprocess.run(['codesign', '--force', '-s', '-', str(binary)], check=True)
(work/'tex2img').symlink_to(copy/'Contents/SharedSupport/bin/tex2img')
resources = copy/'Contents/Resources'
logs = work/'logs'
logs.mkdir()
spec = importlib.util.spec_from_file_location('suite', work/'run_verified_tests.py')
suite = importlib.util.module_from_spec(spec)
sys.modules['suite'] = suite
spec.loader.exec_module(suite)

def prepare():
    os.environ['PATH'] = ':'.join(str(resources/p) for p in ['pdftops', 'mupdf', '']) + ':' + os.environ['PATH']

counter = 0

def run(command):
    global counter
    counter += 1
    result = subprocess.run(command, shell=True, cwd=work, text=True,
                            capture_output=True, timeout=300)
    log = result.stdout + result.stderr
    (logs/f'{counter:02}.log').write_text(log)
    if result.returncode == 0:
        for name, relative in [('mudraw', 'mupdf/mudraw'), ('pdftops', 'pdftops/pdftops'), ('epstopdf', 'epstopdf')]:
            match = re.search(r'^'+name+r': (.+)$', log, re.M)
            if not match or Path(match[1]).resolve() != (resources/relative).resolve():
                return 99, 'Unexpected helper path: '+name+'\n'+log
    return result.returncode, log

suite.prepare_environment = prepare
suite.run_command = run
sys.exit(suite.main())
