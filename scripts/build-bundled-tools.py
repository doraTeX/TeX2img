#!/usr/bin/env python3
"""同一ソースから両CPU向けのPDF変換ツールをビルドする（ホストのライブラリは使わない）。"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

PROJECT = Path(__file__).resolve().parents[1]
SOURCES = json.loads((PROJECT / 'ThirdParty/bundled-sources.json').read_text())
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--work-root', type=Path, default=None)
parser.add_argument('--arch', choices=['arm64', 'x86_64', 'all'], default='all')
parser.add_argument('--install', action='store_true')
args = parser.parse_args()
if args.install and args.arch != 'all':
    parser.error('--install には --arch all が必要です')
ROOT = (args.work_root or Path(tempfile.mkdtemp(prefix='tex2img-deps-'))).resolve()
# MuPDF の Makefile は空白を含むビルドパスに対応しない。
if any(c.isspace() for c in str(ROOT)):
    parser.error('--work-root は空白を含まないパスにしてください')
ROOT.mkdir(parents=True, exist_ok=True)
MIN_OS = '12.0'
JOBS = str(min(os.cpu_count() or 4, 8))
BASE_ENV = os.environ.copy()
BASE_ENV.update(MACOSX_DEPLOYMENT_TARGET=MIN_OS, CC='/usr/bin/clang', CXX='/usr/bin/clang++')
for k in ('CFLAGS', 'CPPFLAGS', 'CXXFLAGS', 'LDFLAGS', 'CPATH', 'LIBRARY_PATH', 'CPLUS_INCLUDE_PATH', 'C_INCLUDE_PATH', 'PKG_CONFIG_PATH', 'CMAKE_PREFIX_PATH'):
    BASE_ENV.pop(k, None)

def run(cmd, **kw):
    print('+', ' '.join(map(str, cmd)), flush=True)
    subprocess.run(list(map(str, cmd)), check=True, **kw)

def source(name):
    spec = SOURCES[name]
    archive = ROOT / 'downloads' / spec['archive']
    archive.parent.mkdir(exist_ok=True)
    if not archive.exists():
        run(['curl', '-fL', '--retry', '3', spec['url'], '-o', archive])
    if hashlib.sha256(archive.read_bytes()).hexdigest() != spec['sha256']:
        raise RuntimeError(f'SHA-256 mismatch: {archive}')
    src = ROOT / 'src' / spec['source']
    if not src.exists():
        src.parent.mkdir(exist_ok=True)
        run(['tar', '-xf', archive, '-C', src.parent])
    if name == 'poppler':
        patch = PROJECT / 'ThirdParty/patches/poppler-fontconfig.patch'
        marker = src / '.tex2img-fontconfig-patch'
        digest = hashlib.sha256(patch.read_bytes()).hexdigest()
        if marker.exists() and marker.read_text() != digest:
            raise RuntimeError('Poppler patch changed; use a fresh work directory')
        if not marker.exists():
            run(['patch', '-p1', '-i', patch], cwd=src)
            marker.write_text(digest)
    return src

def build(arch):
    prefix = ROOT / arch / 'prefix'
    prefix.mkdir(parents=True, exist_ok=True)
    env = BASE_ENV | {'PKG_CONFIG_LIBDIR': f'{prefix}/lib/pkgconfig', 'PKG_CONFIG_PATH': '',
                      'CFLAGS': f'-arch {arch} -mmacosx-version-min={MIN_OS}',
                      'CXXFLAGS': f'-arch {arch} -mmacosx-version-min={MIN_OS}',
                      'LDFLAGS': f'-arch {arch} -mmacosx-version-min={MIN_OS}'}
    def cmake(name, options=(), target=None):
        b = ROOT / arch / name
        config = ['cmake', '-S', source(name), '-B', b, '-G', 'Unix Makefiles',
                  '-DCMAKE_BUILD_TYPE=Release', f'-DCMAKE_INSTALL_PREFIX={prefix}',
                  '-DCMAKE_INSTALL_LIBDIR=lib', '-DCMAKE_C_COMPILER=/usr/bin/clang',
                  '-DCMAKE_CXX_COMPILER=/usr/bin/clang++', f'-DCMAKE_OSX_ARCHITECTURES={arch}',
                  f'-DCMAKE_OSX_DEPLOYMENT_TARGET={MIN_OS}', f'-DCMAKE_PREFIX_PATH={prefix}',
                  '-DCMAKE_C_FLAGS=-Werror=unguarded-availability -Werror=unguarded-availability-new',
                  '-DCMAKE_CXX_FLAGS=-Werror=unguarded-availability -Werror=unguarded-availability-new',
                  '-DCMAKE_IGNORE_PREFIX_PATH=/opt/local;/opt/homebrew;/usr/local',
                  '-DCMAKE_FIND_FRAMEWORK=NEVER', '-DBUILD_SHARED_LIBS=OFF', '-DBUILD_TESTING=OFF', *options]
        if name in ('freetype', 'poppler'):
            config += [f'-DPNG_LIBRARY_RELEASE={prefix}/lib/libpng16.a']
        run(config, env=env)
        run(['cmake', '--build', b, '--parallel', JOBS, *(['--target', target] if target else [])], env=env)
        if not target:
            run(['cmake', '--install', b], env=env)
        return b
    cmake('brotli', ['-DBROTLI_DISABLE_TESTS=OFF'])
    run(['ctest', '--test-dir', ROOT / arch / 'brotli', '--output-on-failure'], env=env)
    cmake('zlib', ['-DZLIB_BUILD_TESTING=OFF', '-DZLIB_BUILD_SHARED=OFF'])
    cmake('libpng', ['-DPNG_FRAMEWORK=OFF', '-DPNG_SHARED=OFF', '-DPNG_TESTS=OFF', '-DPNG_TOOLS=OFF'])
    cmake('freetype', ['-DFT_DISABLE_HVF=ON', '-DFT_DISABLE_HARFBUZZ=ON', '-DFT_DISABLE_BZIP2=ON', '-DFT_REQUIRE_BROTLI=ON', '-DFT_REQUIRE_PNG=ON'])
    cmake('expat', ['-DEXPAT_SHARED_LIBS=OFF', '-DEXPAT_BUILD_TOOLS=OFF', '-DEXPAT_BUILD_EXAMPLES=OFF', '-DEXPAT_BUILD_TESTS=OFF', '-DEXPAT_BUILD_DOCS=OFF'])
    fc = ROOT / arch / 'fontconfig'
    native = ROOT / arch / 'meson.ini'
    native.write_text("[binaries]\nc = '/usr/bin/clang'\ncpp = '/usr/bin/clang++'\npkg-config = 'pkg-config'\n[properties]\n[built-in options]\nc_args = ['-arch', '"+arch+"', '-mmacosx-version-min=12.0']\nc_link_args = ['-arch', '"+arch+"', '-mmacosx-version-min=12.0']\n")
    run(['meson', 'setup', *(['--reconfigure'] if (fc / 'meson-private/coredata.dat').exists() else []), fc, source('fontconfig'), '--native-file', native, '--prefix', prefix,
         '--libdir=lib', '--default-library=static', '--buildtype=release', '--wrap-mode=nofallback',
         '-Ddoc=disabled', '-Dnls=disabled', '-Dtests=disabled', '-Dtools=disabled',
         '-Dcache-build=disabled', '-Dxml-backend=expat', '-Dtests-external-fonts=disabled'], env=env)
    run(['meson', 'compile', '-C', fc, '-j', JOBS], env=env)
    run(['meson', 'install', '-C', fc], env=env)
    cmake('jpeg', ['-DENABLE_SHARED=OFF', '-DENABLE_STATIC=ON', '-DWITH_TURBOJPEG=OFF', '-DWITH_SIMD=OFF'])
    cmake('openjpeg', ['-DBUILD_CODEC=OFF'])
    lc = ROOT / arch / 'lcms2'
    lc.mkdir(exist_ok=True)
    run([source('lcms2') / 'configure', f'--prefix={prefix}', '--disable-shared', '--enable-static', '--without-jpeg', '--without-tiff'], cwd=lc, env=env)
    run(['make', '-j', JOBS], cwd=lc, env=env)
    run(['make', 'install'], cwd=lc, env=env)
    # FindFontconfig.cmake は static の依存を伝播しないため、最終リンクで明示する。
    extra = ' '.join(str(prefix / 'lib' / f'lib{x}.a') for x in ['expat', 'freetype', 'png16', 'brotlidec', 'brotlicommon', 'z'])
    pop = cmake('poppler', [f'-DCMAKE_CXX_STANDARD_LIBRARIES={extra}', f"-DCMAKE_EXE_LINKER_FLAGS=-Wl,-map,{ROOT / arch / 'poppler/link.map'}",
        '-DENABLE_BOOST=OFF', '-DENABLE_CPP=OFF', '-DENABLE_GLIB=OFF', '-DENABLE_QT5=OFF', '-DENABLE_QT6=OFF',
        '-DENABLE_NSS3=OFF', '-DENABLE_GPGME=OFF', '-DENABLE_LIBCURL=OFF', '-DENABLE_LIBTIFF=OFF',
        '-DENABLE_HARFBUZZ=OFF', '-DBUILD_MANUAL_TESTS=OFF', '-DCMAKE_DISABLE_FIND_PACKAGE_Cairo=ON'], 'pdftops')
    out = ROOT / arch / 'stage'
    out.mkdir(exist_ok=True)
    shutil.copy2(pop / 'utils/pdftops', out / 'pdftops')
    mupdf = source('mupdf')
    mout = ROOT / arch / 'mupdf'
    common = ['make', '-j', JOBS, f'OUT={mout}', 'build=release', 'HAVE_X11=no', 'HAVE_GLUT=no', 'HAVE_CURL=no',
              'HAVE_LIBCRYPTO=no', 'HAVE_OBJCOPY=no', 'html=no', 'mujs=no', 'extract=no',
              f'XCFLAGS=-arch {arch} -mmacosx-version-min={MIN_OS} -Werror=unguarded-availability -Werror=unguarded-availability-new', f'XLDFLAGS=-arch {arch} -mmacosx-version-min={MIN_OS} -Wl,-u,_BrotliDecoderVersion -Wl,-map,{mout}/link.map']
    for key, inc, libs in [('FREETYPE','freetype2',['freetype','png16','brotlidec','brotlicommon','z']),
                            ('LIBJPEG','',['jpeg']), ('OPENJPEG','openjpeg-2.5',['openjp2']),
                            ('LCMS2','',['lcms2']), ('ZLIB','',['z']), ('BROTLI','',['brotlidec','brotlienc','brotlicommon'])]:
        common += [f'USE_SYSTEM_{key}=yes', f'SYS_{key}_CFLAGS=-I{prefix}/include/{inc}',
                   f'SYS_{key}_LIBS='+ ' '.join(str(prefix / 'lib' / f'lib{x}.a') for x in libs)]
    stamp = mout / '.tex2img-flags'
    if mout.exists() and (not stamp.exists() or stamp.read_text() != repr(common)):
        shutil.rmtree(mout)
    run([*common, mout / 'mutool'], cwd=mupdf, env=env)
    stamp.write_text(repr(common))
    # mutool は argv[0]=mudraw の互換呼び出しを公式にサポートする。
    shutil.copy2(mout / 'mutool', out / 'mudraw')
    return out

print(f'Work directory: {ROOT}', flush=True)
arches = ['arm64', 'x86_64'] if args.arch == 'all' else [args.arch]
for arch in arches:
    build(arch)
if args.arch == 'all':
    out = ROOT / 'universal'
    out.mkdir(exist_ok=True)
    for tool in ['pdftops', 'mudraw']:
        run(['lipo', '-create', ROOT / 'arm64/stage' / tool, ROOT / 'x86_64/stage' / tool, '-output', out / tool])
        run(['codesign', '--force', '--sign', '-', out / tool])
    maps = source('poppler-data')
    if (out / 'poppler-data').exists():
        shutil.rmtree(out / 'poppler-data')
    for sub in ['cMap', 'cidToUnicode', 'nameToUnicode', 'unicodeMap']:
        shutil.copytree(maps / sub, out / 'poppler-data' / sub, dirs_exist_ok=True)
    for sub in ['COPYING', 'COPYING.adobe', 'COPYING.gpl2', 'README']:
        shutil.copy2(maps / sub, out / 'poppler-data' / sub)
    licenses = out / 'licenses'
    if licenses.exists():
        shutil.rmtree(licenses)
    for name, spec in SOURCES.items():
        for rel in spec['licenses']:
            dest = licenses / name / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source(name) / rel, dest)
    run([PROJECT / 'scripts/verify-universal.sh', out])
    provenance = {
        'minimum_macos': MIN_OS, 'architectures': arches, 'sources': SOURCES,
        'compiler': subprocess.check_output(['/usr/bin/clang', '--version'], text=True),
        'patch_sha256': hashlib.sha256((PROJECT / 'ThirdParty/patches/poppler-fontconfig.patch').read_bytes()).hexdigest(),
        'binary_sha256': {name: hashlib.sha256((out / name).read_bytes()).hexdigest() for name in ['pdftops', 'mudraw']},
        'brotli_static_sha256': {arch: hashlib.sha256((ROOT / arch / 'prefix/lib/libbrotlidec.a').read_bytes()).hexdigest() for arch in arches},
    }
    (out / 'build-info.json').write_text(json.dumps(provenance, indent=2) + '\n')
    if args.install:
        for name in ['licenses', 'poppler-data']:
            dest = PROJECT / 'Resources/pdftops' / name
            if dest.exists():
                shutil.rmtree(dest)
            shutil.copytree(out / name, dest)
        shutil.copy2(out / 'build-info.json', PROJECT / 'Resources/pdftops/build-info.json')
        shutil.copy2(source('mupdf') / 'COPYING', PROJECT / 'Resources/mupdf/MuPDF.license')
        shutil.copy2(out / 'pdftops', PROJECT / 'Resources/pdftops/pdftops')
        shutil.copy2(out / 'mudraw', PROJECT / 'Resources/mupdf/mudraw')
        old = PROJECT / 'Resources/pdftops/pdftops-lib'
        if old.exists():
            shutil.rmtree(old)
