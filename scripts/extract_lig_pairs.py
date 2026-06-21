#!/usr/bin/env python3
import re

with open("Sources/NSString/NSString-Conversion.m", "r", encoding="utf-8") as f:
    content = f.read()

def decode_objc_string(s):
    out = []
    i = 0
    while i < len(s):
        ch = s[i]
        if ch != "\\":
            out.append(ch)
            i += 1
            continue
        i += 1
        if i >= len(s):
            out.append("\\")
            break
        esc = s[i]
        i += 1
        if esc == "n":
            out.append("\n")
        elif esc == "r":
            out.append("\r")
        elif esc == "t":
            out.append("\t")
        elif esc == '"':
            out.append('"')
        elif esc == "\\":
            out.append("\\")
        else:
            out.append("\\" + esc)
    return "".join(out)

def swift_literal(s):
    result = '"'
    for ch in s:
        o = ord(ch)
        if ch == "\\":
            result += "\\\\"
        elif ch == '"':
            result += '\\"'
        elif ch == "\n":
            result += "\\n"
        elif ch == "\r":
            result += "\\r"
        elif ch == "\t":
            result += "\\t"
        elif o < 0x20 or o == 0x7F:
            result += f"\\u{{{o:04X}}}"
        else:
            result += ch
    result += '"'
    return result

def parse_string_replacements(block):
    pairs = []
    for match in re.finditer(
        r'replaceAllOccurrencesOfString:@"((?:\\.|[^"\\])*)" withString:@"((?:\\.|[^"\\])*)" addingPercentForEndOfLine:(YES|NO)',
        block,
    ):
        src = decode_objc_string(match.group(1))
        dest = decode_objc_string(match.group(2))
        adding = match.group(3) == "YES"
        pairs.append((src, dest, adding))
    return pairs

def parse_pattern_replacements(block):
    pairs = []
    for match in re.finditer(
        r'replaceAllOccurrencesOfPattern:@"((?:\\.|[^"\\])*)" withString:@"((?:\\.|[^"\\])*)"',
        block,
    ):
        pattern = decode_objc_string(match.group(1))
        dest = decode_objc_string(match.group(2))
        pairs.append((pattern, dest))
    return pairs

def extract_method(name):
    marker = f"-(NSString*){name}\n"
    start = content.index(marker) + len(marker)
    depth = 0
    i = start
    while i < len(content):
        if content[i] == "{":
            depth += 1
        elif content[i] == "}":
            depth -= 1
            if depth == 0:
                return content[start + 1 : i]
        i += 1
    raise ValueError(f"method not found: {name}")

def emit_pairs(name, pairs):
    lines = [f"private let {name}: [(String, String, Bool)] = ["]
    for src, dest, adding in pairs:
        lines.append(f"    ({swift_literal(src)}, {swift_literal(dest)}, {'true' if adding else 'false'}),")
    lines.append("]")
    return lines

def emit_pattern_pairs(name, pairs):
    lines = [f'private let {name}: [(String, String)] = [']
    for pattern, dest in pairs:
        lines.append(f"    ({swift_literal(pattern)}, {swift_literal(dest)}),")
    lines.append("]")
    return lines

out = []
out.extend(emit_pairs("ligToAjLigStringReplacements", parse_string_replacements(extract_method("stringByReplacingLigWithAjLig"))))
out.append("")
out.extend(emit_pairs("ajLigToLigStringReplacements", parse_string_replacements(extract_method("stringByReplacingAjLigWithLig"))))
out.append("")
out.extend(emit_pattern_pairs("ajLigToLigPatternReplacements", parse_pattern_replacements(extract_method("stringByReplacingAjLigWithLig"))))

with open("Sources/NSString/NSString-Conversion+LigTable.swift", "w", encoding="utf-8") as f:
    f.write("import Foundation\n\n")
    f.write("\n".join(out))
    f.write("\n")

print(f"Wrote Sources/NSString/NSString-Conversion+LigTable.swift ({len(out)} lines)")
print("ligToAjLig count:", len(parse_string_replacements(extract_method("stringByReplacingLigWithAjLig"))))
print("ajLigToLig count:", len(parse_string_replacements(extract_method("stringByReplacingAjLigWithLig"))))
print("pattern count:", len(parse_pattern_replacements(extract_method("stringByReplacingAjLigWithLig"))))