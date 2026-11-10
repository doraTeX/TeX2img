import Foundation

// Checks EncodingDetector (TeXShop's encoding detection). Run through tests/test_encoding_detection.py.

func check(_ condition: Bool, _ message: String) {
    if !condition {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}

let cp932 = EncodingDetector.ns(.dosJapanese)
let ja = ["ja-JP", "en-US"]
func read(_ data: Data, url: URL? = nil, preferred: String.Encoding = .utf8, languages: [String] = ja) -> (String.Encoding, String?) {
    let encoding = EncodingDetector.detect(data, url: url, preferred: preferred, languages: languages)
    return (encoding, String(data: data, encoding: encoding).map { EncodingDetector.textForEditing($0, encoding: encoding) })
}

// Shift JIS: the Windows variant reads 0x5C and 0x7E as the backslash and the tilde.
let source = "\\documentclass{jsarticle}\n\\textbf{日本語}~と\\ref{a}。かなと漢字の文章です。\n"
let sjis = source.data(using: cp932)!
let (sjisEncoding, sjisText) = read(sjis)
check(sjisEncoding == cp932, "Shift JIS is read as CP932, not \(sjisEncoding)")
check(sjisText == source, "backslash and tilde survive")
check(read(sjis, preferred: cp932).0 == cp932, "with Shift JIS preferred")
// EUC-JP, including bytes that also read as half-width katakana in Shift JIS.
let euc = "完璧な牛丼をいただきました。\\section{見出し}\n".data(using: .japaneseEUC)!
check(read(euc).0 == EncodingDetector.ns(.EUC_JP), "EUC-JP")
// ISO-2022-JP is 7-bit text that switches to kanji.
let jis = "日本語のテキスト\n".data(using: .iso2022JP)!
check(read(jis).0 == .iso2022JP, "ISO-2022-JP")
// UTF-8 and the byte order mark.
check(read(Data("Grüße, 日本\n".utf8)).0 == .utf8, "UTF-8")
check(read(Data([0xEF, 0xBB, 0xBF]) + Data("abc".utf8)).0 == .utf8, "UTF-8 byte order mark")
check(read(Data("plain ascii {}%".utf8), preferred: cp932).0 == cp932, "7-bit text keeps the preferred encoding")
// Russian in Windows Cyrillic for a Russian user.
let russian = "Привет, мир! Это проверка кодировки текста.\n".data(using: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.windowsCyrillic.rawValue))))!
check(read(russian, languages: ["ru-RU"]).0 == EncodingDetector.ns(.windowsCyrillic), "Windows Cyrillic")
// The encoding declared to inputenc.
let latin1 = "\\usepackage[latin1]{inputenc}\nCaf\u{E9} na\u{EF}ve r\u{E9}sum\u{E9}\n".data(using: .isoLatin1)!
check(read(latin1, languages: ["en-US"]).0 == .isoLatin1, "inputenc declaration")
// The encoding recorded by the application that wrote the file.
let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: directory) }
let file = directory.appendingPathComponent("recorded.tex")
let macRoman = "Caf\u{E9}\n".data(using: .macOSRoman)!
try! macRoman.write(to: file)
_ = file.withUnsafeFileSystemRepresentation { path in
    setxattr(path!, "com.apple.TextEncoding", "macintosh;0", 11, 0, 0)
}
check(read(macRoman, url: file).0 == .macOSRoman, "recorded encoding")
// Writing back: the yen sign becomes a backslash in encodings without one.
check(EncodingDetector.textForSaving("¥section~", encoding: cp932) == "\\section~", "yen sign written as a backslash")
check(EncodingDetector.textForSaving("\\section~", encoding: EncodingDetector.ns(.shiftJIS_X0213)) == "¥section‾", "X0213 spells 0x5C and 0x7E")
print("Encoding detection regression tests passed")
