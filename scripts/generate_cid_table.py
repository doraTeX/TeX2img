#!/usr/bin/env python3
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SWIFT_TABLE = ROOT / "Sources/NSString/NSString-Conversion+CIDTable.swift"
JSON_OUT = ROOT / "Resources/cidToUnicode.json"
LOADER_OUT = ROOT / "Sources/NSString/NSString-Conversion+CIDTable.swift"

pattern = re.compile(r"^\s*(\d+):\s*(0x[0-9A-Fa-f]+),?\s*$")


def parse_swift_table(path: Path) -> dict[int, int]:
    mappings: dict[int, int] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if not match:
            continue
        cid = int(match.group(1))
        code = int(match.group(2), 16)
        mappings[cid] = code
    return mappings


def parse_objc_source(path: Path) -> dict[int, int]:
    content = path.read_text(encoding="utf-8")
    objc_pattern = re.compile(
        r"\[self replaceCID:(\d+) withUnicodePoint:(0x[0-9A-Fa-f]+) ofString:str\]"
    )
    mappings: dict[int, int] = {}
    for cid, code in objc_pattern.findall(content):
        mappings[int(cid)] = int(code, 16)
    return mappings


def load_mappings() -> dict[int, int]:
    objc_path = ROOT / "Sources/NSString/NSString-Conversion.m"
    if objc_path.exists():
        return parse_objc_source(objc_path)
    if SWIFT_TABLE.exists():
        return parse_swift_table(SWIFT_TABLE)
    print("No CID table source found", file=sys.stderr)
    sys.exit(1)


def write_json(mappings: dict[int, int]) -> None:
    JSON_OUT.parent.mkdir(parents=True, exist_ok=True)
    payload = {str(cid): code for cid, code in sorted(mappings.items())}
    JSON_OUT.write_text(json.dumps(payload, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {JSON_OUT} ({len(payload)} entries)")


def write_loader() -> None:
    loader = """import Foundation

private let cidTableLock = NSLock()
private var cachedCIDToUnicode: [Int: UInt32]?

var cidToUnicode: [Int: UInt32] {
    cidTableLock.lock()
    defer { cidTableLock.unlock() }
    if let cached = cachedCIDToUnicode {
        return cached
    }
    let table = loadCIDToUnicodeTable()
    cachedCIDToUnicode = table
    return table
}

private func loadCIDToUnicodeTable() -> [Int: UInt32] {
    guard let url = Bundle.main.url(forResource: "cidToUnicode", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let raw = try? JSONSerialization.jsonObject(with: data) as? [String: NSNumber] else {
        return [:]
    }

    var result: [Int: UInt32] = [:]
    result.reserveCapacity(raw.count)
    for (key, value) in raw {
        guard let cid = Int(key) else { continue }
        result[cid] = value.uint32Value
    }
    return result
}
"""
    LOADER_OUT.write_text(loader, encoding="utf-8")
    print(f"Wrote {LOADER_OUT}")


def main() -> None:
    mappings = load_mappings()
    print(f"Found {len(mappings)} CID mappings")

    if len(mappings) != len(set(mappings)):
        print("Duplicate CIDs detected", file=sys.stderr)
        sys.exit(1)

    write_json(mappings)
    write_loader()


if __name__ == "__main__":
    main()