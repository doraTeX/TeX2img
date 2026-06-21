#!/usr/bin/env python3
"""Reorganize Sources/ into subdirectories and update project.pbxproj groups."""
from __future__ import annotations

import re
import subprocess
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / "Sources"
PBXPROJ = ROOT / "TeX2img.xcodeproj" / "project.pbxproj"

FILE_DIRS: dict[str, str] = {
    "AppDelegate.swift": "App",
    "ControllerG.swift": "Controllers",
    "ControllerG-Extension.swift": "Controllers",
    "ControllerG-UserNotification.swift": "Controllers",
    "ControllerC.swift": "Controllers",
    "ProfileController.swift": "Controllers",
    "MyGlyphPopoverController.swift": "Controllers",
    "Converter.swift": "Converter",
    "Converter-BoundingBox.swift": "Converter",
    "TeXTextView.swift": "Editor",
    "TeXTextView-Colorize.swift": "Editor",
    "TeXTextView-CommandCompletion.swift": "Editor",
    "TeXTextView-Bullet.swift": "Editor",
    "MyATSTypesetter.swift": "Editor",
    "MyLayoutManager.swift": "Editor",
    "AutoSelectTextField.swift": "Editor",
    "NSString-Extension.swift": "NSString",
    "NSString-Conversion.swift": "NSString",
    "NSString-Conversion+CIDTable.swift": "NSString",
    "NSString-Conversion+LigTable.swift": "NSString",
    "NSString-Unicode.swift": "NSString",
    "NSMutableString-Extension.swift": "NSString",
    "NSArray-Extension.swift": "Extensions/Foundation",
    "NSDictionary-Extension.swift": "Extensions/Foundation",
    "NSIndexSet-Extension.swift": "Extensions/Foundation",
    "NSDate-Extension.swift": "Extensions/Foundation",
    "Data-Extension.swift": "Extensions/Foundation",
    "FileManager-Extension.swift": "Extensions/Foundation",
    "Pipe-Extension.swift": "Extensions/Foundation",
    "BidirectionalCollection.swift": "Extensions/Foundation",
    "LosslessStringConvertible.swift": "Extensions/Foundation",
    "StringProtocol-Extension.swift": "Extensions/Foundation",
    "NSApplication-Extension.swift": "Extensions/AppKit",
    "NSApperance-Extension.swift": "Extensions/AppKit",
    "NSColor-Extension.swift": "Extensions/AppKit",
    "NSColor-DefaultColor.swift": "Extensions/AppKit",
    "NSColorWell-Extension.swift": "Extensions/AppKit",
    "NSWindow-Extension.swift": "Extensions/AppKit",
    "NSBitmapImageRep-Extension.swift": "Extensions/AppKit",
    "NSMatrix-Extension.swift": "Extensions/AppKit",
    "NSPopover-Extension.swift": "Extensions/AppKit",
    "PDFDocument-Extension.swift": "Extensions/PDF",
    "PDFPage-Extension.swift": "Extensions/PDF",
    "PDFPageBox.swift": "Extensions/PDF",
    "Utility.swift": "Utility",
    "UtilityC.swift": "Utility",
    "UtilityG.swift": "Utility",
    "UserNotificationDelegate.swift": "Utility",
    "mainc.swift": "CLI",
    "GlobalConstants.swift": "Core",
    "Types.swift": "Core",
    "Bridging-Header-C.h": "Core",
    "Bridging-Header-G.h": "Core",
}

ICU_FILES = [
    "localpointer.h", "platform.h", "ptypes.h", "putil.h", "uchar.h", "uconfig.h",
    "uiter.h", "umachine.h", "unorm2.h", "urename.h", "uset.h", "ustring.h",
    "utf_old.h", "utf.h", "utf8.h", "utf16.h", "utypes.h", "uvernum.h", "uversion.h",
]

GROUP_TREE: dict[str, list[str] | dict[str, list[str]]] = {
    "App": ["AppDelegate.swift"],
    "Controllers": [
        "ControllerG.swift", "ControllerG-Extension.swift", "ControllerG-UserNotification.swift",
        "ControllerC.swift", "ProfileController.swift", "MyGlyphPopoverController.swift",
    ],
    "Converter": ["Converter.swift", "Converter-BoundingBox.swift"],
    "Editor": [
        "TeXTextView.swift", "TeXTextView-Colorize.swift", "TeXTextView-CommandCompletion.swift",
        "TeXTextView-Bullet.swift", "MyATSTypesetter.swift", "MyLayoutManager.swift",
        "AutoSelectTextField.swift",
    ],
    "NSString": [
        "NSString-Extension.swift", "NSString-Conversion.swift", "NSString-Conversion+CIDTable.swift",
        "NSString-Conversion+LigTable.swift", "NSString-Unicode.swift", "NSMutableString-Extension.swift",
    ],
    "Extensions": {
        "Foundation": [
            "NSArray-Extension.swift", "NSDictionary-Extension.swift", "NSIndexSet-Extension.swift",
            "NSDate-Extension.swift", "Data-Extension.swift", "FileManager-Extension.swift",
            "Pipe-Extension.swift", "BidirectionalCollection.swift", "LosslessStringConvertible.swift",
            "StringProtocol-Extension.swift",
        ],
        "AppKit": [
            "NSApplication-Extension.swift", "NSApperance-Extension.swift", "NSColor-Extension.swift",
            "NSColor-DefaultColor.swift", "NSColorWell-Extension.swift", "NSWindow-Extension.swift",
            "NSBitmapImageRep-Extension.swift", "NSMatrix-Extension.swift", "NSPopover-Extension.swift",
        ],
        "PDF": ["PDFDocument-Extension.swift", "PDFPage-Extension.swift", "PDFPageBox.swift"],
    },
    "Utility": ["Utility.swift", "UtilityC.swift", "UtilityG.swift", "UserNotificationDelegate.swift"],
    "CLI": ["mainc.swift"],
    "Core": ["GlobalConstants.swift", "Types.swift", "Bridging-Header-C.h", "Bridging-Header-G.h"],
    "icu": ICU_FILES,
}


def new_id(key: str) -> str:
    return "34SRC" + uuid.uuid5(uuid.NAMESPACE_DNS, key).hex[:20].upper()


def move_files() -> None:
    for filename, subdir in FILE_DIRS.items():
        src = SOURCES / filename
        dest = SOURCES / subdir / filename
        if dest.exists():
            continue
        if not src.exists():
            raise SystemExit(f"Missing file: {src}")
        dest.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "mv", str(src), str(dest)], cwd=ROOT, check=True)


def build_file_ref_map(text: str) -> dict[str, str]:
    refs: dict[str, str] = {}
    for line in text.splitlines():
        m = re.match(r"\s+([0-9A-Za-z]+) /\* (.+?) \*/ = \{isa = PBXFileReference;", line)
        if m:
            refs[m.group(2)] = m.group(1)
    return refs


def group_block(gid: str, name: str, path: str, child_lines: list[str], indent: str = "\t\t") -> str:
    kids = ",\n".join(child_lines)
    return (
        f"{indent}{gid} /* {name} */ = {{\n"
        f"{indent}\tisa = PBXGroup;\n"
        f"{indent}\tchildren = (\n{kids},\n{indent}\t);\n"
        f"{indent}\tpath = {path};\n"
        f"{indent}\tsourceTree = \"<group>\";\n"
        f"{indent}}};"
    )


def render_groups(file_refs: dict[str, str]) -> tuple[str, str]:
    group_ids: dict[str, str] = {}

    def gid(key: str) -> str:
        group_ids.setdefault(key, new_id(f"group:{key}"))
        return group_ids[key]

    def file_line(name: str, indent: str) -> str:
        ref = file_refs.get(name)
        if not ref:
            raise SystemExit(f"No PBXFileReference for {name}")
        return f"{indent}\t\t{ref} /* {name} */"

    blocks: list[str] = []

    def render_list_group(key: str, display_name: str, files: list[str], indent: str = "\t\t") -> None:
        children = [file_line(f, indent) for f in files]
        blocks.append(group_block(gid(key), display_name, display_name, children, indent))

    def render_tree(name: str, node: list[str] | dict[str, list[str]], indent: str = "\t\t") -> None:
        if isinstance(node, list):
            render_list_group(name, name, node, indent)
            return
        child_group_refs = [f"{indent}\t\t{gid(f'{name}/{sub}')} /* {sub} */" for sub in node]
        blocks.append(group_block(gid(name), name, name, child_group_refs, indent))
        for sub, files in node.items():
            render_list_group(f"{name}/{sub}", sub, files, indent + "\t")

    for top, node in GROUP_TREE.items():
        render_tree(top, node)

    sources_id = new_id("group:Sources")
    sources_children = [f"\t\t\t{gid(name)} /* {name} */" for name in GROUP_TREE]
    sources_block = (
        f"\t\t{sources_id} /* Sources */ = {{\n"
        f"\t\t\tisa = PBXGroup;\n"
        f"\t\t\tchildren = (\n" + ",\n".join(sources_children) + ",\n\t\t\t);\n"
        f"\t\t\tpath = Sources;\n"
        f"\t\t\tsourceTree = \"<group>\";\n"
        f"\t\t}};"
    )
    return sources_id, sources_block + "\n" + "\n".join(blocks)


def update_pbxproj(sources_group_id: str, new_group_blocks: str) -> None:
    text = PBXPROJ.read_text()

    text = re.sub(
        r"(29B97314FDCFA39411CA2CEA /\* TeX2img \*/ = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n)"
        r"\t\t\t080E96DDFE201D6D7F000001 /\* Classes \*/,\n"
        r"\t\t\t348F295D1B848951009AA3CF /\* Extensions \*/,\n"
        r"\t\t\t29B97315FDCFA39411CA2CEA /\* Other Sources \*/,\n"
        r"\t\t\t347314F41B89CD9500F285A3 /\* ICU Headers \*/,\n",
        rf"\1\t\t\t{sources_group_id} /* Sources */,\n",
        text,
        count=1,
    )
    if f"{sources_group_id} /* Sources */," not in text:
        text = text.replace(
            "080E96DDFE201D6D7F000001 /* Classes */,",
            f"{sources_group_id} /* Sources */,",
        )
        for stale in [
            "348F295D1B848951009AA3CF /* Extensions */,",
            "29B97315FDCFA39411CA2CEA /* Other Sources */,",
            "347314F41B89CD9500F285A3 /* ICU Headers */,",
        ]:
            text = text.replace(f"\t\t\t{stale}\n", "")

    for old in [
        r"\t\t080E96DDFE201D6D7F000001 /\* Classes \*/ = \{.*?\n\t\t\};\n",
        r"\t\t29B97315FDCFA39411CA2CEA /\* Other Sources \*/ = \{.*?\n\t\t\};\n",
        r"\t\t348F295D1B848951009AA3CF /\* Extensions \*/ = \{.*?\n\t\t\};\n",
        r"\t\t347314F41B89CD9500F285A3 /\* ICU Headers \*/ = \{.*?\n\t\t\};\n",
    ]:
        text = re.sub(old, "", text, flags=re.S)

    text = text.replace(
        "/* End PBXGroup section */",
        new_group_blocks + "\n/* End PBXGroup section */",
    )

    text = text.replace("Sources/Bridging-Header-C.h", "Sources/Core/Bridging-Header-C.h")
    text = text.replace("Sources/Bridging-Header-G.h", "Sources/Core/Bridging-Header-G.h")
    text = text.replace("Sources/mainc.swift", "Sources/CLI/mainc.swift")

    PBXPROJ.write_text(text)


def update_bridging_header() -> None:
    path = SOURCES / "Core" / "Bridging-Header-G.h"
    text = path.read_text()
    if '../icu/' not in text:
        text = text.replace('#import "icu/', '#import "../icu/')
        path.write_text(text)


def update_scripts() -> None:
    for script in ["scripts/generate_cid_table.py", "scripts/extract_lig_pairs.py"]:
        p = ROOT / script
        t = p.read_text()
        t = t.replace("Sources/NSString-Conversion", "Sources/NSString/NSString-Conversion")
        p.write_text(t)


def main() -> None:
    move_files()
    text = PBXPROJ.read_text()
    file_refs = build_file_ref_map(text)
    sources_id, blocks = render_groups(file_refs)
    update_pbxproj(sources_id, blocks)
    update_bridging_header()
    update_scripts()
    print("Reorganization complete.")


if __name__ == "__main__":
    main()