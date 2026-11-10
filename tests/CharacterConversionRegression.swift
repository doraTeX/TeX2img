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
// Writing the source (\UTF output): a sequence without a CID is kept when the output encoding can hold it;
// otherwise it falls back to the glyph number used before, so that a Shift_JIS/EUC/JIS file can still be written.
let shiftJIS = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.dosJapanese.rawValue)))
for encoding in [String.Encoding.utf8, shiftJIS, .japaneseEUC, .iso2022JP] {
    let source = "a😀b\n𠮷髙"
    let output = source.stringByReplacingUnicodeCharactersWithUTF(outputEncoding: encoding)
    check(output.canBeConverted(to: encoding), "\(output) can be written in \(encoding)")
    check(output.hasSuffix("\\CID{13706}\\UTF{9AD9}"), "\(output) keeps the CID of 𠮷 and \\UTF of 髙 in \(encoding)")
    if encoding == .utf8 {
        check(output.hasPrefix("a😀b"), "\(output) keeps 😀 in UTF-8")
    } else {
        check(output.range(of: #"^a\\CID\{[0-9]+\}b"#, options: .regularExpression) != nil, "\(output) falls back to \\CID in \(encoding)")
    }
}
// A line break, tab or other control character before a combining mark is kept (it was lost with the mark in
// a \CID), and the line still gets its % at the end.
for control in ["\n", "\t", "\u{2028}", "\r\n"] {
    for mark in ["\u{0301}", "\u{3099}", "\u{20DD}"] {
        let output = "あ\(control)\(mark)い".stringByReplacingUnicodeCharactersWithUTF()
        check(output == "あ\(control)\\UTF{\(hex(mark))}い", "\(hex(control)) before \(hex(mark)): \(output)")
    }
}
check("a\n\u{0301}b\n髙\nc".stringByReplacingUnicodeCharactersWithUTF().hasSuffix("\\UTF{9AD9}%\nc"), "% after a line that starts with a mark")
// \CID is read in one pass: what one replacement gives is not read again.
check("\\CID{97}CID{17}".stringByReplacingUTFWithUnicodeCharacters() == "\\CID{97}CID{17}".stringByReplacingUTFWithUnicodeCharacters(), "stable")
for _ in 0..<5 {
    // CID 18 is "1": the \\CID{11} that this gives is not read again.
    check("\\CID{1\\CID{18}}".stringByReplacingUTFWithUnicodeCharacters() == "\\CID{11}", "\\CID{1\\CID{18}} is \\CID{11}")
}
check("\\CID{99999}\\CID{999999999999999999999999}".stringByReplacingUTFWithUnicodeCharacters() == "\\CID{99999}\\CID{999999999999999999999999}",
      "unknown CIDs are kept")
// ajmacros: circled days of the week are \ajMaruYobi (they were written as \ajKakkoYobi), and 9 is ㊡.
let maruYobi = "\u{3290}\u{328A}\u{328B}\u{328C}\u{328D}\u{328E}\u{328F}\u{3297}\u{32A1}"
check(maruYobi.stringByReplacingUnicodeCharactersWithAjMacros() == (1...9).map { "\\ajMaruYobi{\($0)}" }.joined(),
      "circled days: \(maruYobi.stringByReplacingUnicodeCharactersWithAjMacros())")
check(maruYobi.stringByReplacingUnicodeCharactersWithAjMacros().stringByReplacingAjMacrosWithUnicodeCharacters() == maruYobi, "circled days back")
let kakkoYobi = "\u{3230}\u{322A}\u{322B}\u{322C}\u{322D}\u{322E}\u{322F}\u{3237}\u{3241}"
check(kakkoYobi.stringByReplacingUnicodeCharactersWithAjMacros().stringByReplacingAjMacrosWithUnicodeCharacters() == kakkoYobi, "days in parentheses back")
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
