#!/usr/bin/env python3
"""最低OSを片CPUだけ引き上げた実バイナリやthinバイナリを拒否する回帰テスト。"""
from pathlib import Path
import subprocess
import tempfile
import sys

verify = Path(__file__).resolve().parents[1] / 'scripts/verify-universal.py'
with tempfile.TemporaryDirectory(prefix='tex2img-verify-') as temp:
    root = Path(temp)
    (root/'main.c').write_text('int main(void) { return 0; }\n')
    for arch in ['arm64', 'x86_64']:
        for minimum in ['12.0', '13.0']:
            subprocess.run(['clang', '-arch', arch, '-mmacosx-version-min='+minimum,
                            str(root/'main.c'), '-o', str(root/(arch+minimum))], check=True)
    for arm, intel, success in [('12.0','12.0',True), ('12.0','13.0',False), ('13.0','12.0',False)]:
        fat = root/('universal-'+arm+'-'+intel)
        subprocess.run(['lipo','-create',str(root/('arm64'+arm)),str(root/('x86_64'+intel)),'-output',str(fat)],check=True)
        p = subprocess.run([sys.executable,str(verify),str(fat)],capture_output=True,text=True)
        assert (p.returncode == 0) == success, p.stdout+p.stderr
    for name in ['arm6412.0','x86_6412.0','does-not-exist']:
        p = subprocess.run([sys.executable,str(verify),str(root/name)],capture_output=True,text=True)
        assert p.returncode != 0, p.stdout+p.stderr
print('PASS: universal verifier accepts macOS 12 and rejects either elevated slice, thin and missing binaries')
