#!/usr/bin/env python3
import re
from collections import Counter

m_path = "Sources/NSString-Conversion.m"
with open(m_path, "r", encoding="utf-8") as f:
    content = f.read()

pattern = re.compile(r'\[self replaceCID:(\d+) withUnicodePoint:(0x[0-9A-Fa-f]+) ofString:str\]')
matches = pattern.findall(content)
print(f"Found {len(matches)} CID mappings")

cids = [int(m[0]) for m in matches]
dups = [k for k, v in Counter(cids).items() if v > 1]
if dups:
    print(f"Duplicate CIDs: {dups[:10]}... total {len(dups)}")
else:
    print("No duplicate CIDs")

lines = ["import Foundation", "", "let cidToUnicode: [Int: UInt32] = ["]
for cid, code in matches:
    lines.append(f"    {cid}: {code},")
lines.append("]")
out_path = "Sources/NSString-Conversion+CIDTable.swift"
with open(out_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
print(f"Wrote {out_path} ({len(lines)} lines)")