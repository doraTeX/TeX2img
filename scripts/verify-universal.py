#!/usr/bin/env python3
"""Mach-O の両CPU、最低OS、同梱依存の解決を検証する。メタデータは変更しない。"""
import argparse
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys

PROJECT = Path(__file__).resolve().parents[1]

def output(*cmd):
    return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)

def version(s):
    return tuple((list(map(int, s.split('.'))) + [0, 0])[:3])

def verify(target, limit):
    errors = []
    files = [target] if target.is_file() else sorted(target.rglob('*'))
    count = 0
    for path in files:
        if path.is_symlink() or not path.is_file():
            continue
        if 'Mach-O' not in output('file', '-b', str(path)):
            continue
        count += 1
        arches = output('lipo', '-archs', str(path)).split()
        missing = {'arm64', 'x86_64'} - set(arches)
        if missing:
            errors.append(f'{path}: missing {", ".join(sorted(missing))}')
        for arch in ('arm64', 'x86_64'):
            if arch not in arches:
                continue
            load = output('otool', '-arch', arch, '-l', str(path))
            minimum = re.search(r'\bminos ([\d.]+)', load)
            if not minimum:
                minimum = re.search(r'cmd LC_VERSION_MIN_MACOSX\s+cmdsize \d+\s+version ([\d.]+)', load)
            if not minimum:
                errors.append(f'{path} ({arch}): missing minimum OS')
            elif version(minimum[1]) > version(limit):
                errors.append(f'{path} ({arch}): macOS {minimum[1]} > {limit}')
            # システム以外の絶対パス・未解決の依存は配布先で動かない。
            for block in re.split(r'Load command \d+\n', load):
                if not re.search(r'cmd LC_(?:LOAD_DYLIB|LOAD_WEAK_DYLIB|REEXPORT_DYLIB)\n', block):
                    continue
                match = re.search(r'\n\s+name (.+?) \(offset', block)
                if not match:
                    continue
                dep = match[1]
                if dep.startswith(('/usr/lib/', '/System/Library/')):
                    continue
                resolved = []
                if dep.startswith('@loader_path/'):
                    resolved = [path.parent / dep.removeprefix('@loader_path/')]
                elif dep.startswith('@executable_path/'):
                    resolved = [path.parent / dep.removeprefix('@executable_path/')]
                elif dep.startswith('@rpath/'):
                    # Sparkle の各実行ファイルから見えるフレームワークを同梱ツリー内で探す。
                    rel = dep.removeprefix('@rpath/')
                    resolved = [parent / rel for parent in [path.parent, *path.parents]]
                    for block2 in re.split(r'Load command \d+\n', load):
                        if 'cmd LC_RPATH\n' in block2:
                            rp = re.search(r'\n\s+path (.+?) \(offset', block2)
                            if rp:
                                base = rp[1].replace('@loader_path', str(path.parent)).replace('@executable_path', str(path.parent))
                                resolved.append(Path(base) / rel)
                existing = [p for p in resolved if p.is_file() and (p.resolve() == target.resolve() or target.resolve() in p.resolve().parents)]
                if not existing:
                    errors.append(f'{path} ({arch}): unresolved dependency {dep}')
                elif not any(arch in output('lipo', '-archs', str(p)).split() for p in existing):
                    errors.append(f'{path} ({arch}): dependency lacks slice: {dep}')
        print(f'{path}: {" ".join(arches)}')
    if not count:
        errors.append(f'{target}: no Mach-O files')
    for p in (target.rglob('Info.plist') if target.is_dir() else []):
        if p.is_symlink():
            continue
        info = plistlib.loads(p.read_bytes())
        versions = {'LSMinimumSystemVersion': info.get('LSMinimumSystemVersion')}
        versions.update(info.get('LSMinimumSystemVersionByArchitecture', {}))
        for key, value in versions.items():
            if value and version(value) > version(limit):
                errors.append(f'{p}: {key} {value} > {limit}')
    for error in errors:
        print('ERROR:', error, file=sys.stderr)
    if errors:
        return 1
    print(f'OK: {count} Mach-O files; arm64 + x86_64; macOS <= {limit}')
    return 0

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('target', type=Path)
    parser.add_argument('--minimum-os', default=None)
    args = parser.parse_args()
    targets = set(re.findall(r'MACOSX_DEPLOYMENT_TARGET = ([\d.]+);', (PROJECT / 'TeX2img.xcodeproj/project.pbxproj').read_text()))
    if len(targets) != 1:
        parser.error('本体の deployment target が統一されていません')
    limit = args.minimum_os or targets.pop()
    sys.exit(verify(args.target.resolve(), limit))
