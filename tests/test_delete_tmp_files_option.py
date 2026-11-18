#!/usr/bin/env python3
""""Delete temporary files" decides, as it always has, whether the intermediate files of a conversion are removed
(the user's decision of 2026-11-18: the option works as it did before the 2026-11-17 fixes, in the temporary folder
as anywhere else).

- On: the intermediates are removed after a conversion that succeeded, and after one that failed once the
  application finishes the generation (ControllerG calls deleteTemporaryFiles then).
- Off: they are kept (succeeded or failed).
- The bounding box and gs version files are removed as soon as they are read, whatever the option (as before).

Converts a page of a PDF through the real Converter (no TeX is run; gs is needed on PATH). The converter takes the
temporary folder from FileManager.temporaryDirectory, which ignores TMPDIR: as in test_eps_preview.py, Converter.swift
is compiled with that one expression replaced by a folder of the test's own. No file is written, listed or removed
outside the test's folder.
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

final class QuietController: ControllerC {
    override func previewFiles(_ files: [String], withApplication app: String) {}
}

@main struct Main {
    static func main() {
        _ = NSApplication.shared
        let arguments = CommandLine.arguments
        let (input, output, gs) = (arguments[1], arguments[2], arguments[3])
        let controller = QuietController()
        var profile: Profile = [:]
        profile[LatexPathKey] = "/usr/bin/true"
        profile[DviDriverPathKey] = "/usr/bin/true"
        profile[GsPathKey] = gs
        profile[EpstopdfPathKey] = "/usr/bin/false"
        profile[OutputFileKey] = output
        profile[EncodingKey] = PTEX_ENCODING_NONE
        profile[NumberOfCompilationKey] = 1
        profile[ResolutionKey] = 15
        profile[DPIKey] = 72
        profile[GetOutlineKey] = true
        profile[TransparentKey] = true
        profile[FillColorKey] = NSColor.white.serializedString
        profile[PreviewKey] = false
        profile[DeleteTmpFileKey] = arguments[6] == "delete"
        profile[QuietKey] = true
        profile[ControllerKey] = controller
        profile[WorkingDirectoryTypeKey] = Int(WorkingDirectoryTmp)
        let converter = Converter(profile: profile)
        let success = withExtendedLifetime(controller) { converter.compileAndConvert(withInputPath: input) }
        // The application calls this whenever a generation finishes (succeeded, failed or aborted).
        if arguments[5] == "finish" { converter.deleteTemporaryFiles() }
        print("success:", success)
    }
}
'''

failures = []
with tempfile.TemporaryDirectory(prefix='tex2img-keep-intermediate-') as tmp:
    root = Path(tmp).resolve()
    system_tmp = root / 'system-tmp'   # what FileManager.temporaryDirectory gives the converter
    system_tmp.mkdir()
    (root / 'main.swift').write_text(MAIN)
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', '-module-name', 'KeepIntermediate', *cli_sources(root),
                    str(root / 'main.swift'), '-o', str(root / 'convert')], check=True)
    gs = shutil.which('gs')
    if not gs:
        sys.exit('gs is needed on PATH')
    failing_gs = root / 'failing-gs'
    failing_gs.write_text('#!/bin/sh\nexit 1\n')
    failing_gs.chmod(0o755)
    writer = PdfWriter()
    writer.add_page(PdfReader(ROOT / 'te st/in put.pdf').pages[1])
    source = root / 'src'
    source.mkdir()
    page_pdf = source / 'input.pdf'
    writer.write(page_pdf)
    output_dir = root / 'out'
    output_dir.mkdir()
    env = dict(os.environ, TEX2IMG_TEST_SYSTEM_TMP=str(system_tmp))

    def convert(output, delete, gs_path=gs):
        assert Path(output).resolve().is_relative_to(root), output
        result = subprocess.run([str(root / 'convert'), str(page_pdf), str(output), str(gs_path), 'tmp', 'finish',
                                 'delete' if delete else 'keep'],
                                capture_output=True, text=True, timeout=300, env=env)
        return result, result.stdout + result.stderr

    def intermediates():
        """The converter's files (temp<pid>-<uuid>…) in the test's temporary folder."""
        return {p.name for p in system_tmp.iterdir() if p.name.startswith('temp')}

    for delete in [True, False]:
        for succeeds in [True, False]:
            what = f"delete {'on' if delete else 'off'}, {'success' if succeeds else 'failure'}"
            for extension in (['eps', 'png'] if succeeds else ['eps']):
                before = intermediates()
                output = output_dir / f"{'d' if delete else 'k'}{'ok' if succeeds else 'ng'}.{extension}"
                result, log = convert(output, delete, gs if succeeds else failing_gs)
                left = sorted(intermediates() - before)
                if ('success: true' in result.stdout) != succeeds or output.is_file() != succeeds:
                    failures.append(f'{what} ({extension}): unexpected result\n' + log)
                if delete and left:
                    failures.append(f'{what} ({extension}): intermediates were left: {left}')
                if not delete and not any(name.endswith('.pdf') for name in left):
                    failures.append(f'{what} ({extension}): the intermediate PDF was removed: {left}')
                if any(name.endswith('-bbox') or name.endswith('-gsver') for name in left):
                    failures.append(f'{what} ({extension}): a bounding box / gs version file was left: {left}')

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: "Delete temporary files" decides whether the intermediates are removed (succeeded or failed)')
