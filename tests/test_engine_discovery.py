#!/usr/bin/env python3
"""Runs tests/EngineDiscoveryRegression.swift with the product's EnginePathDiscovery (ControllerG-Extension.swift): version
output bounded in time and size, TeX Live releases newest first, and development builds of TeX Live named as the banner
names them, after the release of their year, with the newest release selected first (TeXShop 6.00). --mutations changes
key parts and the test must fail."""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Sources/Controllers/ControllerG-Extension.swift"


def run(source):
    with tempfile.TemporaryDirectory(prefix="tex2img-engine-discovery-") as directory:
        path = Path(directory)
        (path / "Discovery.swift").write_text(source)
        build = subprocess.run(["xcrun", "swiftc", "-parse-as-library", str(ROOT / "tests/EngineDiscoveryRegression.swift"),
                                str(path / "Discovery.swift"), "-o", str(path / "test")], capture_output=True, text=True)
        if build.returncode:
            return subprocess.CompletedProcess(build.args, 1, build.stdout, build.stderr)
        return subprocess.run([str(path / "test")], capture_output=True, text=True, timeout=120, cwd=directory,
                              env={"TMPDIR": directory, "PATH": "/usr/bin:/bin"})


def main():
    source = SOURCE.read_text()
    result = run(source)
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    if result.returncode:
        return 1
    if "--mutations" in sys.argv:
        mutations = {
            "the banner is the first line": ("        if let line = lines.first(where: { banner?.firstMatch(in: $0, range: NSRange($0.startIndex..., in: $0)) != nil }) { return line }\n", ""),
            "the version read from the first line": ("                : capture(#\"^[^\\n]*?\\s([0-9]+(?:[.\\-][0-9]+)*)\"#, in: bannerLine(in: output))",
                                                     "                : capture(#\"^[^\\n]*?\\s([0-9]+(?:[.\\-][0-9]+)*)\"#, in: output)"),
            "development builds sorted as releases": ("            if a.1.dev != b.1.dev { return b.1.dev }\n", ""),
            "the first entry selected": ("        candidates.firstIndex { $0.year > 0 && !$0.dev } ?? 0", "        0"),
            "any dev prefix is a development build": ("(/dev(?=[/)\\s]|$))?", "(/dev)?"),
            "the year read from the whole output": ("        let line = bannerLine(in: output)\n", "        let line = output\n"),
        }
        for name, (old, new) in mutations.items():
            assert source.count(old) == 1, name
            if run(source.replace(old, new)).returncode == 0:
                print(f"FAIL: the mutation went unnoticed: {name}", file=sys.stderr)
                return 1
            print("DETECTED", name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
