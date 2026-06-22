#!/usr/bin/env python3
"""Run test.sh commands one-by-one and verify outputs."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

WORKDIR = Path(__file__).resolve().parent
TEX2IMG = WORKDIR / "tex2img"
TEST_SH = WORKDIR / "test.sh"
RESULTS_JSON = WORKDIR / "test_results.json"
RESULTS_MD = WORKDIR / "test_results.md"

# Without margins: empty pages 1,3,5 are skipped.
EXPECTED_PAGES_NO_MARGIN = [2, 4, 6, 7, 8]
# With margins: all pages are emitted; 1,3,5 become white placeholder pages.
EXPECTED_PAGES_WITH_MARGIN = [1, 2, 3, 4, 5, 6, 7, 8]
BG_COLOR = (204, 255, 204)


@dataclass
class TestCase:
    number: int
    command: str
    output_path: Path
    flags: dict = field(default_factory=dict)


def parse_tests() -> list[TestCase]:
    lines = TEST_SH.read_text().splitlines()
    tests: list[TestCase] = []
    for i, line in enumerate(lines, start=1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        cmd = line.split(";")[0].strip()
        if not cmd.startswith("./tex2img"):
            continue
        m = re.search(r'\./(\d+)/"sam ple"\.(\w+)\s*$', cmd)
        if not m:
            raise ValueError(f"Cannot parse output path from test {i}: {cmd}")
        dir_num, ext = int(m.group(1)), m.group(2)
        output = WORKDIR / str(dir_num) / f"sam ple.{ext}"
        flags = {
            "merge": "--merge-output-files" in cmd and "--no-merge-output-files" not in cmd,
            "transparent": "--transparent" in cmd and "--no-transparent" not in cmd,
            "background": "--background-color CCFFCC" in cmd,
            "margins": "--margins 10" in cmd,
            "with_text": "--with-text" in cmd and "--no-with-text" not in cmd,
            "outline": "--no-with-text" in cmd,
            "plain_text": "--plain-text" in cmd,
            "no_plain_text": "--no-plain-text" in cmd,
            "delete_display_size": "--delete-display-size" in cmd,
            "quick": "--quick" in cmd and "--no-quick" not in cmd,
            "animated": "--animation-delay" in cmd,
            "ext": ext,
        }
        tests.append(TestCase(dir_num, cmd, output, flags))
    return tests


def prepare_environment() -> None:
    app = WORKDIR / "TeX2img.app"
    pdftops_dir = app / "Contents/Resources/pdftops"
    mupdf_dir = app / "Contents/Resources/mupdf"
    for pattern in ("*.dylib", "pdftops", "xpdf-pdftops"):
        for path in pdftops_dir.rglob(pattern):
            if path.is_file():
                subprocess.run(["codesign", "-s", "-", "--force", str(path)], capture_output=True)
    os.environ["PATH"] = f"{pdftops_dir}:{mupdf_dir}:{os.environ.get('PATH', '')}"


def run_command(cmd: str) -> tuple[int, str]:
    env = os.environ.copy()
    proc = subprocess.run(
        cmd,
        shell=True,
        cwd=WORKDIR,
        text=True,
        capture_output=True,
        env=env,
    )
    out = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode, out


def expected_pages(test: TestCase) -> list[int]:
    if test.flags["margins"]:
        return EXPECTED_PAGES_WITH_MARGIN
    return EXPECTED_PAGES_NO_MARGIN


def page_numbers_from_files(files: list[Path], base: str, ext: str) -> list[int]:
    nums = []
    for f in files:
        if f.name == f"{base}.{ext}":
            nums.append(1)
            continue
        m = re.search(r"-(\d+)\.", f.name)
        if m:
            nums.append(int(m.group(1)))
    return sorted(nums)


def list_outputs(test: TestCase) -> list[Path]:
    out_dir = test.output_path.parent
    base = test.output_path.stem  # "sam ple"
    ext = test.output_path.suffix.lstrip(".")
    if test.flags["merge"]:
        if test.output_path.exists():
            return [test.output_path]
        return []
    pattern = re.compile(rf"^{re.escape(base)}(-\d+)?\.{re.escape(ext)}$")
    files = []
    for p in sorted(out_dir.glob(f"{base}*.{ext}")):
        if pattern.match(p.name):
            files.append(p)
    return files


def pdf_page_count(path: Path) -> int | None:
    script = f'''
import PDFKit
let doc = PDFDocument(url: URL(fileURLWithPath: "{path}"))!
print(doc.pageCount)
'''
    proc = subprocess.run(["swift", "-e", script], capture_output=True, text=True)
    if proc.returncode != 0:
        return None
    try:
        return int(proc.stdout.strip())
    except ValueError:
        return None


def verify_pdf(files: list[Path], test: TestCase) -> list[str]:
    issues = []
    if not files:
        return ["no output files"]
    for f in files:
        if f.stat().st_size < 500:
            issues.append(f"{f.name}: suspiciously small")
        pages = pdf_page_count(f)
        if pages is None or pages < 1:
            issues.append(f"{f.name}: invalid pdf")
    if not test.flags["merge"]:
        base = test.output_path.stem
        ext = test.flags["ext"]
        nums = page_numbers_from_files(files, base, ext)
        expected = expected_pages(test)
        if sorted(nums) != sorted(expected):
            issues.append(f"unexpected pages {nums}, expected {expected}")
    elif len(files) == 1:
        pages = pdf_page_count(files[0])
        expected_count = len(expected_pages(test))
        if pages != expected_count:
            issues.append(f"merged page count {pages} != {expected_count}")
    return issues or ["ok"]


def sample_pixels_image(path: Path):
    script = f'''
import AppKit
let path = "{path}"
guard let img = NSImage(contentsOfFile: path),
      let rep = img.representations.first as? NSBitmapImageRep else {{ print("null"); exit(1) }}
let w = rep.pixelsWide, h = rep.pixelsHigh
var opaque = 0, transparent = 0
for y in 0..<h {{ for x in 0..<w {{
  if let c = rep.colorAt(x: x, y: y) {{
    if c.alphaComponent > 0.5 {{ opaque += 1 }}
    else if c.alphaComponent < 0.1 {{ transparent += 1 }}
  }}
}}}}
var samples: [String] = []
for (x,y) in [(0,0),(1,0),(0,1),(w-1,0),(0,h-1)] {{
  if let c = rep.colorAt(x:x,y:y)?.usingColorSpace(.deviceRGB) {{
    samples.append("\\(Int(c.redComponent*255)),\\(Int(c.greenComponent*255)),\\(Int(c.blueComponent*255)),\\(c.alphaComponent)")
  }}
}}
print("opaque=\\(opaque) transparent=\\(transparent) samples=\\(samples.joined(separator:"|"))")
'''
    proc = subprocess.run(["swift", "-e", script], capture_output=True, text=True)
    if proc.returncode != 0:
        return None
    m = re.search(r"opaque=(\d+) transparent=(\d+) samples=(.*)", proc.stdout.strip())
    if not m:
        return None
    samples = []
    for part in m.group(3).split("|"):
        if not part:
            continue
        vals = part.split(",")
        if len(vals) == 4:
            samples.append((int(vals[0]), int(vals[1]), int(vals[2]), float(vals[3])))
    return {"samples": samples, "opaque": int(m.group(1)), "transparent": int(m.group(2))}


def color_close(c, target, tol=40):
    return all(abs(c[i] - target[i]) <= tol for i in range(3))


def bitmap_has_content(path: Path) -> bool:
    script = f'''
import AppKit
let img = NSImage(contentsOfFile: "{path}")!
for rep in img.representations {{
  guard let bmp = rep as? NSBitmapImageRep else {{ continue }}
  let w = bmp.pixelsWide, h = bmp.pixelsHigh
  for y in stride(from: 0, to: h, by: max(1, h / 40)) {{
    for x in stride(from: 0, to: w, by: max(1, w / 40)) {{
      if let c = bmp.colorAt(x: x, y: y), c.alphaComponent > 0.5 {{ print("yes"); exit(0) }}
    }}
  }}
}}
print("no")
'''
    proc = subprocess.run(["swift", "-e", script], capture_output=True, text=True)
    return proc.returncode == 0 and proc.stdout.strip() == "yes"


def verify_bitmap(files: list[Path], test: TestCase) -> list[str]:
    issues = []
    if not files:
        return ["no output files"]
    base = test.output_path.stem
    ext = test.flags["ext"]
    for f in files:
        if f.stat().st_size < 80:
            issues.append(f"{f.name}: too small ({f.stat().st_size} bytes)")
            continue
        page_num = 1 if f.name == f"{base}.{ext}" else int(re.search(r"-(\d+)\.", f.name).group(1))
        is_white_margin_page = test.flags["margins"] and page_num in {1, 3, 5}
        info = sample_pixels_image(f)
        if info is None:
            if f.stat().st_size < 200:
                issues.append(f"{f.name}: too small")
            continue
        if info["opaque"] == 0 and not is_white_margin_page:
            if test.flags["merge"] and bitmap_has_content(f):
                pass
            else:
                issues.append(f"{f.name}: no opaque pixels (likely blank)")
        if test.flags["transparent"] and not is_white_margin_page:
            if info["transparent"] == 0 and test.flags["ext"] in {"png", "gif", "tiff"}:
                if test.flags["ext"] == "gif" and info["opaque"] > 0:
                    pass
                elif test.flags["ext"] != "gif":
                    issues.append(f"{f.name}: expected transparency, found none")
        if test.flags["background"]:
            bg_hits = sum(1 for s in info["samples"] if color_close(s, BG_COLOR))
            if bg_hits == 0 and test.flags["ext"] in {"png", "bmp", "gif", "tiff"} and not is_white_margin_page:
                issues.append(f"{f.name}: background CCFFCC not detected in samples {info['samples']}")
    if not test.flags["merge"]:
        nums = page_numbers_from_files(files, base, ext)
        expected = expected_pages(test)
        if sorted(nums) != sorted(expected):
            issues.append(f"unexpected pages {nums}, expected {expected}")
    elif test.flags["merge"] and not bitmap_has_content(files[0]):
        issues.append(f"{files[0].name}: merged file has no visible content")
    return issues or ["ok"]


def verify_svg(files: list[Path], test: TestCase) -> list[str]:
    issues = []
    if not files:
        return ["no output files"]
    for f in files:
        text = f.read_text(encoding="utf-8", errors="replace")
        if not text.startswith("<?xml") and "<svg" not in text:
            issues.append(f"{f.name}: not valid svg")
        if f.stat().st_size < 100:
            issues.append(f"{f.name}: too small")
        if test.flags["delete_display_size"] and 'width="' in text.split("<svg", 1)[-1][:200]:
            issues.append(f"{f.name}: width attribute still present")
        if test.flags["background"] and "CCFFCC" not in text.upper() and "#CCFFCC" not in text.upper():
            if len(text) < 300:
                issues.append(f"{f.name}: too small for filled svg")
        if test.flags["animated"] and test.flags["merge"]:
            if "<animate" not in text and "values=" not in text:
                issues.append(f"{f.name}: animation elements missing")
    if not test.flags["merge"]:
        base = test.output_path.stem
        ext = test.flags["ext"]
        nums = page_numbers_from_files(files, base, ext)
        expected = expected_pages(test)
        if sorted(nums) != sorted(expected):
            issues.append(f"unexpected pages {nums}, expected {expected}")
    return issues or ["ok"]


def verify_eps(files: list[Path], test: TestCase) -> list[str]:
    issues = []
    if not files:
        return ["no output files"]
    for f in files:
        head = f.read_bytes()[:128]
        if not head.startswith(b"%!"):
            issues.append(f"{f.name}: missing EPS header")
        if f.stat().st_size < 200:
            issues.append(f"{f.name}: too small")
    if not test.flags["merge"]:
        base = test.output_path.stem
        ext = test.flags["ext"]
        nums = page_numbers_from_files(files, base, ext)
        expected = expected_pages(test)
        if sorted(nums) != sorted(expected):
            issues.append(f"unexpected pages {nums}, expected {expected}")
    return issues or ["ok"]


def verify_outputs(test: TestCase, files: list[Path]) -> list[str]:
    ext = test.flags["ext"]
    if ext == "pdf":
        return verify_pdf(files, test)
    if ext in {"png", "jpg", "bmp", "gif", "tiff"}:
        return verify_bitmap(files, test)
    if ext == "svg":
        return verify_svg(files, test)
    if ext == "eps":
        return verify_eps(files, test)
    return ["unknown ext"]


def main() -> int:
    prepare_environment()
    tests = parse_tests()
    results = []
    failures = 0

    for test in tests:
        out_dir = test.output_path.parent
        out_dir.mkdir(parents=True, exist_ok=True)
        for old in out_dir.glob("sam ple*"):
            old.unlink()

        rc, log_tail = run_command(test.command)
        log_tail = "\n".join(log_tail.splitlines()[-12:])
        files = list_outputs(test)
        issues = [] if rc != 0 else verify_outputs(test, files)
        if rc != 0:
            issues = [f"exit code {rc}"]
            failures += 1
        elif issues != ["ok"]:
            failures += 1

        results.append(
            {
                "number": test.number,
                "command": test.command,
                "exit_code": rc,
                "files": [str(f.relative_to(WORKDIR)) for f in files],
                "issues": issues,
                "log_tail": log_tail,
            }
        )
        status = "FAIL" if issues != ["ok"] or rc != 0 else "OK"
        print(f"[{status}] test {test.number:02d} ({test.flags['ext']}) -> {issues}")

    RESULTS_JSON.write_text(json.dumps(results, ensure_ascii=False, indent=2))

    lines = ["# tex2img verified test results", "", f"Total: {len(results)}, Failures: {failures}", ""]
    for r in results:
        status = "OK" if r["issues"] == ["ok"] and r["exit_code"] == 0 else "FAIL"
        lines.append(f"## Test {r['number']} — {status}")
        lines.append("```")
        lines.append(r["command"])
        lines.append("```")
        lines.append(f"- files: {', '.join(r['files']) or '(none)'}")
        lines.append(f"- issues: {', '.join(r['issues'])}")
        if status == "FAIL":
            lines.append("```")
            lines.append(r["log_tail"])
            lines.append("```")
        lines.append("")
    RESULTS_MD.write_text("\n".join(lines))

    print(f"\nSummary: {len(results) - failures}/{len(results)} passed, {failures} failed")
    print(f"Results: {RESULTS_MD}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())