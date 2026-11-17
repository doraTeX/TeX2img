#!/usr/bin/env python3
"""Converts a PDF to EPS with "preview" on, through the real Converter with a controller that records what would
be previewed (nothing is opened). Needs gs on PATH.

- The preview PDF is not written next to the input (K6), nor over a file in the temporary folder that has the
  output's name, such as the input itself (F1 of the 1st audit): it goes to a new folder of its own.
- A preview PDF that epstopdf does not make is not previewed (an older file could be opened), and the failure is
  reported.

The converter takes the temporary folder from FileManager.temporaryDirectory, which ignores TMPDIR. The test compiles
Converter.swift with that one expression replaced by a folder of the test's own; nothing else is changed, and no
file is written outside the test's folder.
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
SYSTEM_TMP_EXPRESSION = 'fileManager.temporaryDirectory.path'


def cli_sources(work):
    """The sources of the command-line tool except its main file; Converter.swift with the temporary folder injected."""
    project = (ROOT / 'TeX2img.xcodeproj/project.pbxproj').read_text()
    target = re.search(r'/\* tex2img \*/ = \{\s*isa = PBXNativeTarget;.*?buildPhases = \((.*?)\);', project, re.S).group(1)
    phase = re.search(r'(\w+) /\* Sources \*/', target).group(1)
    files = re.findall(r'/\* (\S+) in Sources \*/', re.search(phase + r' /\* Sources \*/ = \{.*?files = \((.*?)\);', project, re.S).group(1))
    paths = {p.name: p for p in (ROOT / 'Sources').rglob('*.swift')}
    result = []
    for name in files:
        if name == 'mainc.swift':
            continue
        if name == 'Converter.swift':
            text = paths[name].read_text()
            assert SYSTEM_TMP_EXPRESSION in text
            injected = work / 'Converter.swift'
            injected.write_text(text.replace(SYSTEM_TMP_EXPRESSION, 'ProcessInfo.processInfo.environment["TEX2IMG_TEST_SYSTEM_TMP"]!'))
            result.append(str(injected))
        else:
            result.append(str(paths[name]))
    return result


MAIN = r'''
import AppKit

final class RecordingController: ControllerC {
    var previewed: [String]?
    override func previewFiles(_ files: [String], withApplication app: String) { previewed = files }
    override func showFileGenerationError(_ aPath: String) { print("generation error:", aPath) }
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
        print("preview called:", controller.previewed != nil)
        for path in controller.previewed ?? [] { print("previewed:", path) }
    }
}
'''

failures = []
with tempfile.TemporaryDirectory(prefix='tex2img-eps-preview-') as tmp:
    root = Path(tmp).resolve()
    system_tmp = root / 'system-tmp'   # what FileManager.temporaryDirectory gives the converter
    system_tmp.mkdir()
    (root / 'main.swift').write_text(MAIN)
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', '-module-name', 'EpsPreview', *cli_sources(root),
                    str(root / 'main.swift'), '-o', str(root / 'convert')], check=True)
    gs = shutil.which('gs')
    if not gs:
        sys.exit('gs is needed on PATH')
    writer = PdfWriter()
    writer.add_page(PdfReader(ROOT / 'te st/in put.pdf').pages[1])
    page_pdf = root / 'page.pdf'
    writer.write(page_pdf)
    output_dir = root / 'out'
    output_dir.mkdir()
    env = dict(os.environ, TEX2IMG_TEST_SYSTEM_TMP=str(system_tmp))
    good_epstopdf = str(ROOT / 'Resources/epstopdf')
    failing_epstopdf = root / 'failing-epstopdf'
    failing_epstopdf.write_text('exit 1\n')

    def convert(source, output, epstopdf=good_epstopdf):
        for path in (source, output):
            assert Path(path).resolve().is_relative_to(root), path
        result = subprocess.run([str(root / 'convert'), str(source), str(output), gs, str(epstopdf)],
                                capture_output=True, text=True, timeout=300, env=env)
        previewed = re.findall(r'^previewed: (.+)$', result.stdout, re.M)
        for path in previewed:
            assert Path(path).resolve().is_relative_to(root), path
        return result, previewed

    def is_pdf_page(path):
        return Path(path).is_file() and len(PdfReader(path).pages) == 1

    # K6: a PDF next to the input with the output's name is kept.
    source = root / 'src folder'
    source.mkdir()
    shutil.copy(page_pdf, source / 'input.pdf')
    precious = source / 'fig.pdf'
    precious.write_bytes(b"%PDF-1.4 the user's own fig.pdf\n")
    result, previewed = convert(source / 'input.pdf', output_dir / 'fig.eps')
    log = result.stdout + result.stderr
    if 'success: true' not in result.stdout or not (output_dir / 'fig.eps').is_file():
        failures.append('K6: the conversion to EPS failed\n' + log)
    if precious.read_bytes() != b"%PDF-1.4 the user's own fig.pdf\n":
        failures.append('K6: the PDF next to the input was replaced by the preview PDF')
    if len(previewed) != 1 or not is_pdf_page(previewed[0]) or Path(previewed[0]).resolve().parent == source.resolve():
        failures.append(f'K6: the preview PDF was not made apart from the input: {previewed}\n' + log)

    # F1: the input is in the temporary folder, with the output's name: it is kept, and another PDF is previewed.
    same = system_tmp / 'same.pdf'
    shutil.copy(page_pdf, same)
    original = same.read_bytes()
    result, previewed = convert(same, output_dir / 'same.eps')
    log = result.stdout + result.stderr
    if 'success: true' not in result.stdout:
        failures.append('F1: the conversion failed\n' + log)
    if same.read_bytes() != original:
        failures.append('F1: the input in the temporary folder was replaced by the preview PDF')
    if len(previewed) != 1 or Path(previewed[0]).resolve() == same.resolve() or not is_pdf_page(previewed[0]):
        failures.append(f'F1: the preview PDF is the input or was not made: {previewed}\n' + log)

    # A preview PDF that epstopdf does not make: nothing is previewed (not an older file), and an error is shown.
    stale = system_tmp / 'stale.pdf'
    stale.write_bytes(b'%PDF-1.4 an older preview\n')
    result, previewed = convert(source / 'input.pdf', output_dir / 'stale.eps', failing_epstopdf)
    log = result.stdout + result.stderr
    if previewed or 'preview called: true' in result.stdout:
        failures.append(f'failed epstopdf: something was previewed: {previewed}\n' + log)
    if 'generation error:' not in result.stdout:
        failures.append('failed epstopdf: no error was reported\n' + log)
    if stale.read_bytes() != b'%PDF-1.4 an older preview\n':
        failures.append('failed epstopdf: an older PDF in the temporary folder was changed')

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: the EPS preview PDF is a new file of its own; files next to the input and in the temporary folder are kept')
