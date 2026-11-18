#!/usr/bin/env python3
"""The intermediate files of a conversion in the temporary folder ($TMPDIR) are kept afterwards, so that a conversion
can be traced: whether it succeeded or failed, and with "Delete temporary files" on. In a working folder outside the
temporary folder, "Delete temporary files" removes them as before.

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
        let (input, output, gs, workingDirectory) = (arguments[1], arguments[2], arguments[3], arguments[4])
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
        profile[DeleteTmpFileKey] = true
        profile[QuietKey] = true
        profile[ControllerKey] = controller
        if workingDirectory == "tmp" {
            profile[WorkingDirectoryTypeKey] = Int(WorkingDirectoryTmp)
        } else {
            profile[WorkingDirectoryTypeKey] = Int(WorkingDirectoryCurrent)
            profile[WorkingDirectoryPathKey] = workingDirectory
        }
        let converter = Converter(profile: profile)
        let success = withExtendedLifetime(controller) { converter.compileAndConvert(withInputPath: input) }
        // The application calls this whenever a generation finishes (succeeded, failed or aborted).
        if arguments.count > 5 && arguments[5] == "finish" { converter.deleteTemporaryFiles() }
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

    def convert(output, working_directory, gs_path=gs, finish=True):
        for path in (output, page_pdf):
            assert Path(path).resolve().is_relative_to(root), path
        if working_directory != 'tmp':
            assert Path(working_directory).resolve().is_relative_to(root), working_directory
        result = subprocess.run([str(root / 'convert'), str(page_pdf), str(output), str(gs_path), str(working_directory)]
                                + (['finish'] if finish else []),
                                capture_output=True, text=True, timeout=300, env=env)
        return result, result.stdout + result.stderr

    def intermediates(folder):
        """The converter's files (temp<pid>-<uuid>…) in a folder of the test."""
        return sorted(p.name for p in Path(folder).iterdir() if p.name.startswith('temp'))

    # In the temporary folder, with "Delete temporary files" on: the intermediates of a conversion that succeeded
    # remain, among them the bounding box and gs version files that were removed as soon as they were read.
    for extension in ['eps', 'png']:
        before = set(intermediates(system_tmp))
        result, log = convert(output_dir / f'ok.{extension}', 'tmp')
        left = sorted(set(intermediates(system_tmp)) - before)
        if 'success: true' not in result.stdout or not (output_dir / f'ok.{extension}').is_file():
            failures.append(f'{extension}: the conversion failed\n' + log)
        if not any(name.endswith('.pdf') for name in left):
            failures.append(f'{extension}: the intermediate PDF in the temporary folder was removed: {left}')
        if not any(name.endswith('-bbox') for name in left) or not any(name.endswith('-gsver') for name in left):
            failures.append(f'{extension}: the bounding box / gs version files were removed: {left}')

    # A conversion that failed, then finished as the application does: its intermediates remain in the temporary folder.
    before = set(intermediates(system_tmp))
    result, log = convert(output_dir / 'failed.eps', 'tmp', failing_gs)
    left = sorted(set(intermediates(system_tmp)) - before)
    if 'success: true' in result.stdout or (output_dir / 'failed.eps').exists():
        failures.append('failed: the conversion with a failing gs succeeded\n' + log)
    if not any(name.endswith('.pdf') for name in left):
        failures.append(f'failed: the intermediates of the failed conversion were removed: {left}\n' + log)

    # A working folder outside the temporary folder: "Delete temporary files" removes the intermediates there, as before.
    elsewhere = root / 'working folder'
    elsewhere.mkdir()
    result, log = convert(output_dir / 'elsewhere.eps', str(elsewhere))
    if 'success: true' not in result.stdout or not (output_dir / 'elsewhere.eps').is_file():
        failures.append('elsewhere: the conversion failed\n' + log)
    if intermediates(elsewhere):
        failures.append(f'elsewhere: intermediates were left outside the temporary folder: {intermediates(elsewhere)}')

if failures:
    print('\n'.join('FAIL: ' + f for f in failures), file=sys.stderr)
    sys.exit(1)
print('PASS: the intermediates in the temporary folder are kept (succeeded or failed); elsewhere they are removed')
