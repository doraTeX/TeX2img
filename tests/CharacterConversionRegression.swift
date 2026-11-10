import AppKit

// Checks the Unicode/\UTF/\CID and ajmacros conversions (TeXShop 5.60 beta-5 audit M-1–M-4, and TeX2img's own
// crashes). Run through tests/test_character_conversion.py.

func check(_ condition: Bool, _ message: String) {
    if !condition {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}
func hex(_ s: String) -> String { s.unicodeScalars.map { String(format: "%04X", $0.value) }.joined(separator: " ") }

// M-1: the glyph number of a fallback font is not an Adobe-Japan1 CID; such sequences are kept.
for kept in ["😀", "👨‍👩‍👧‍👦", "🇯🇵"] {
    check(kept.stringByReplacingUnicodeCharactersWithUTF() == kept, "\(kept) is kept, not \(kept.stringByReplacingUnicodeCharactersWithUTF())")
}
// A sequence that Hiragino draws as one glyph gets its CID, written as \CID (not \ID).
check("𠮷".stringByReplacingUnicodeCharactersWithUTF() == "\\CID{13706}", "𠮷 is \\CID{13706}")
check("葛\u{E0100}".stringByReplacingUnicodeCharactersWithUTF().hasPrefix("\\CID{"), "an IVS sequence becomes \\CID")
check("髙".stringByReplacingUnicodeCharactersWithUTF() == "\\UTF{9AD9}", "a BMP character outside JIS X 0208 is \\UTF")
// \CID back to a character beyond the BMP (it was deleted before).
check("\\CID{13706}".stringByReplacingUTFWithUnicodeCharacters() == "𠮷", "\\CID{13706} reads back as 𠮷")
// M-3: surrogate code points are not characters.
for value in ["D800", "DBFF", "DC00", "DFFF"] {
    let source = "\\UTF{\(value)}"
    check(source.stringByReplacingUTFWithUnicodeCharacters() == source, "\(source) is kept")
}
check(hex("\\UTF{D7FF}\\UTF{E000}".stringByReplacingUTFWithUnicodeCharacters()) == "D7FF E000", "D7FF and E000 are converted")
check("\\UTF{00zz}".stringByReplacingUTFWithUnicodeCharacters() == "\\UTF{00zz}", "only hexadecimal digits")
// M-4: an escaped backslash does not start the command.
check("\\\\UTF{0041}".stringByReplacingUTFWithUnicodeCharacters() == "\\\\UTF{0041}", "\\\\UTF is kept")
check("\\\\\\UTF{0041}".stringByReplacingUTFWithUnicodeCharacters() == "\\\\A", "\\\\\\UTF converts its command")
check("x\\UTF{0041}".stringByReplacingUTFWithUnicodeCharacters() == "xA", "a command is converted")
// M-2: Modified NFD keeps every leading U+FEFF.
for count in 0...3 {
    let source = String(repeating: "\u{FEFF}", count: count) + "\u{304C}\u{F9F1}"
    check(hex(source.normalizedStringWithModifiedNFD()) == ([String](repeating: "FEFF", count: count) + ["304B", "3099", "F9F1"]).joined(separator: " "),
          "Modified NFD with \(count) leading U+FEFF")
}
check(hex("\u{FEFF}\u{FEFF}".normalizedStringWithModifiedNFD()) == "FEFF FEFF", "Modified NFD of U+FEFF only")
// ajmacros: characters beyond the BMP in the tables (they crashed before).
check("\\ajMaru{1}".stringByReplacingAjMacrosWithUnicodeCharacters() == "①", "\\ajMaru{1}")
check("\u{1F110}".stringByReplacingUnicodeCharactersWithAjMacros() != "\u{1F110}", "U+1F110 becomes an ajmacro")
check("\u{1F110}".stringByReplacingUnicodeCharactersWithAjMacros().stringByReplacingAjMacrosWithUnicodeCharacters() == "\u{1F110}",
      "U+1F110 round trip")
print("Character conversion regression tests passed")
