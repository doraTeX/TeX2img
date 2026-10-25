#!/usr/bin/env python3
"""旧アプリやPATHに同名ツールがあっても、自身の同梱版を使う実行テスト。"""
from pathlib import Path
import os
import subprocess
import tempfile

project = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='bundled tool paths ') as tmp:
    root = Path(tmp)
    resources = root/'TeX2img.app/Contents/Resources'
    exe = root/'TeX2img.app/Contents/SharedSupport/bin/probe'
    exe.parent.mkdir(parents=True)
    for name in ['mupdf/mudraw','pdftops/pdftops','epstopdf']:
        file=resources/name;file.parent.mkdir(parents=True,exist_ok=True)
        file.write_text('#!/bin/sh\nexit 0\n');file.chmod(0o755)
    stale=root/'old-bin';stale.mkdir()
    for name in ['mudraw','pdftops','xpdf-pdftops','epstopdf']:
        file=stale/name;file.write_text('#!/bin/sh\nexit 99\n');file.chmod(0o755)
    code=root/'Probe.swift'
    code.write_text('''import Foundation
@main struct Probe {
    static func main() {
        let expected = CommandLine.arguments[1]
        for (name, relative) in [("mudraw","mupdf/mudraw"), ("pdftops","pdftops/pdftops"), ("xpdf-pdftops","pdftops/pdftops"), ("epstopdf","epstopdf")] {
            precondition(UtilityC.getPath(name) == expected + "/" + relative, name)
            precondition(UtilityC.checkWhich(name), name)
        }
        precondition(UtilityC.getPath("/usr/bin/true") == "/usr/bin/true")
        precondition(!UtilityC.checkWhich("tex2img-nonexistent-command-128"))
        print("PASS: own bundled tools take precedence; explicit paths retained")
    }
}
''')
    files=['Sources/Utility/UtilityC.swift','Sources/Extensions/Foundation/String-Extension.swift','Sources/Extensions/Foundation/Pipe-Extension.swift','Sources/NSString/NSString-Extension.swift']
    subprocess.run(['swiftc','-parse-as-library',str(code),*[str(project/f) for f in files],'-o',str(exe)],check=True)
    env=os.environ.copy();env['PATH']=str(stale)+':/usr/bin:/bin'
    subprocess.run([str(exe),str(resources)],env=env,check=True)
    link=root/'probe-link';link.symlink_to(exe)
    subprocess.run([str(link),str(resources)],env=env,check=True)
