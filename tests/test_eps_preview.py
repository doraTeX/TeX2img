#!/usr/bin/env python3
"""Converts a PDF to EPS with "preview" on and the input file's folder as the working folder, through the real
Converter with a controller that records what would be previewed (nothing is opened).

The PDF that previews the EPS goes to the temporary folder; a PDF with that name next to the input is kept.
Needs gs on PATH.
"""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from pypdf import PdfReader, PdfWriter

ROOT = Path(__file__).resolve().parents[1]


def cli_sources():
    """The sources of the command-line tool except its main file."""
    project = (ROOT / 'TeX2img.xcodeproj/project.pbxproj').read_text()
    target = re.search(r'/\* tex2img \*/ = \{\s*isa = PBXNativeTarget;.*?buildPhases = \((.*?)\);', project, re.S).group(1)
    phase = re.search(r'(\w+) /\* Sources \*/', target).group(1)
    files = re.findall(r'/\* (\S+) in Sources \*/', re.search(phase + r' /\* Sources \*/ = \{.*?files = \((.*?)\);', project, re.S).group(1))
    paths = {p.name: p for p in (ROOT / 'Sources').rglob('*.swift')}
    return [str(paths[name]) for name in files if name != 'mainc.swift']


MAIN = r'''
import AppKit

final class RecordingController: ControllerC {
    var previewed: [String] = []
    override func previewFiles(_ files: [String], withApplication app: String) { previewed = files }
}

@main struct Main {
    static func main() {
        _ = NSApplication.shared
        let arguments = CommandLine.arguments
        let (input, output, gs, epstopdf) = (arguments[1], arguments[2], arguments[3], arguments[4])
        let controller = RecordingController()
        var profile: Profile = [:]
        profile[LatexPathKey] = "/usr/bin/true"
        profile[DviDriverPathKey] = "/usr/bin/true"
        profile[GsPathKey] = gs
        profile[EpstopdfPathKey] = epstopdf
        profile[OutputFileKey] = output
        profile[EncodingKey] = PTEX_ENCODING_NONE
        profile[NumberOfCompilationKey] = 1
        profile[ResolutionKey] = 15
        profile[DPIKey] = 72
        profile[GetOutlineKey] = true
        profile[TransparentKey] = true
        profile[FillColorKey] = NSColor.white.serializedString
        profile[PreviewKey] = true
        profile[DeleteTmpFileKey] = true
        profile[QuietKey] = true
        profile[ControllerKey] = controller
        profile[WorkingDirectoryTypeKey] = Int(WorkingDirectoryFile)
        let converter = Converter(profile: profile)
        let success = withExtendedLifetime(controller) { converter.compileAndConvert(withInputPath: input) }
        print("success:", success)
        for path in controller.previewed { print("previewed:", path) }
    }
}
'''

failures = []
with tempfile.TemporaryDirectory(prefix='tex2img-eps-preview-') as tmp:
    root = Path(tmp)
    (root / 'main.swift').write_text(MAIN)
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', '-module-name', 'EpsPreview', *cli_sources(),
                    str(root / 'main.swift'), '-o', str(root / 'convert')], check=True)
    source = root / 'src folder'
    source.mkdir()
    writer = PdfWriter()
    writer.add_page(PdfReader(ROOT / 'te st/in put.pdf').pages[1])
    writer.write(source / 'input.pdf')
    precious = source / 'fig.pdf'
    precious.write_bytes(b'%PDF-1.4 the user\'s own fig.pdf\n')
    output_dir = root / 'out'
    output_dir.mkdir()
    gs = shutil.which('gs')
    if not gs:
        sys.exit('gs is needed on PATH')
    result = subprocess.run([str(root / 'convert'), str(source / 'input.pdf'), str(output_dir / 'fig.eps'), gs,
                             str(ROOT / 'Resources/epstopdf')], capture_output=True, text=True, timeout=300)
    log = result.stdout + result.stderr
    if 'success: true' not in result.stdout or not (output_dir / 'fig.eps').is_file():
        failures.append('the conversion to EPS failed\n' + log)
    if precious.read_bytes() != b'%PDF-1.4 the user\'s own fig.pdf\n':
        failures.append('fig.pdf next to the input was replaced by the preview PDF')
    previewed = re.findall(r'^previewed: (.+)$', result.stdout, re.M)
    if len(previewed) != 1 or not Path(previewed[0]).is_file() or Path(previewed[0]).suffix != '.pdf' \
            or len(PdfReader(previewed[0]).pages) != 1:
        failures.append(f'the preview PDF was not made: {previewed}\n' + log)
    elif Path(previewed[0]).resolve().parent == source.resolve():
        failures.append('the preview PDF is next to the input')
    for path in previewed:
        if Path(path).exists() and Path(path).resolve().parent != source.resolve():
            os.remove(path)

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: the EPS preview PDF goes to the temporary folder; files next to the input are kept')
