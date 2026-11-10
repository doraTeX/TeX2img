"""Modified NFC/NFD を実装そのものでコンパイルして確かめる（アプリは起動しない）。

Modified NFC は CotEditor と同じく Full_Composition_Exclusion に当たらない区間だけを
NFC にする。除外文字だけの文字列（互換漢字など）が空にならないことも確かめる。
"""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
TEST = r'''
import Foundation
func expect(_ name: String, _ got: String, _ expected: String) {
    guard got == expected else {
        let hex = { (s: String) in s.unicodeScalars.map { String(format: "%04X", $0.value) }.joined(separator: " ") }
        print("FAIL \(name): [\(hex(got))] != [\(hex(expected))]"); exit(1)
    }
}
@main struct Main {
    static func main() {
        let nfc = { (s: String) in (s as NSString).normalizedStringWithModifiedNFC() }
        let nfd = { (s: String) in (s as NSString).normalizedStringWithModifiedNFD() }
        expect("kana", nfc("か\u{3099}は\u{309A}"), "がぱ")
        expect("compatibility ideograph only", nfc("\u{FA19}"), "\u{FA19}")
        expect("Angstrom sign only", nfc("\u{212B}"), "\u{212B}")
        expect("Greek oxia only", nfc("\u{1F71}"), "\u{1F71}")
        expect("mixed", nfc("\u{FA19}か\u{3099}\u{1F71}\u{03B1}\u{0301}"), "\u{FA19}が\u{1F71}\u{03AC}")
        expect("excluded combining mark", nfc("a\u{0340}"), "a\u{0340}")
        expect("controls kept", nfc("a\u{01}\tb\r\u{0C}"), "a\u{01}\tb\r\u{0C}")
        expect("empty", nfc(""), "")
        expect("modified NFD", nfd("が\u{FA19}\u{1F71}"), "か\u{3099}\u{FA19}\u{03B1}\u{0301}")
        expect("modified NFD keeps leading U+FEFF", nfd("\u{FEFF}a"), "\u{FEFF}a")
        let excluded = try! NSRegularExpression(pattern: #"^\p{Full_Composition_Exclusion}$"#)
        var kept = 0
        for value in 1...0x10FFFF {
            guard let scalar = Unicode.Scalar(value) else { continue }
            let one = String(Character(scalar))
            let isExcluded = excluded.numberOfMatches(in: one, range: NSRange(one.startIndex..., in: one)) > 0
            let expected = isExcluded ? one : (one as NSString).precomposedStringWithCanonicalMapping
            if isExcluded { kept += 1 }
            if (one as NSString).normalizedStringWithModifiedNFC() != expected { print("FAIL U+\(String(format: "%04X", value))"); exit(1) }
        }
        guard kept >= 1120 else { print("FAIL Full_Composition_Exclusion has \(kept) code points"); exit(1) }
        print("PASS modified NFC/NFD (\(kept) excluded code points kept)")
    }
}
'''
with tempfile.TemporaryDirectory(prefix="unicode-normalization-") as directory:
    path = Path(directory)
    (path / "Test.swift").write_text(TEST)
    subprocess.run(["swiftc", "-parse-as-library", "-import-objc-header", str(ROOT / "Sources/Core/Bridging-Header-G.h"),
                    str(path / "Test.swift"), str(ROOT / "Sources/NSString/NSString-Unicode.swift"), str(ROOT / "Sources/NSString/NSString-Extension.swift"), str(ROOT / "Sources/Extensions/Foundation/String-Extension.swift"),
                    "-licucore", "-o", str(path / "test")], check=True)
    subprocess.run([str(path / "test")], timeout=120, check=True)
