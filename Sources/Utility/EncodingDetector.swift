import Foundation

/// Chooses the encoding of a TeX source without an encoding declaration, ported from TeXShop 5.60
/// (TSEncodingSupport detectedEncodingForData:fileURL:preferredEncoding: and textForEditing:encoding:).
///
/// Order: a byte order mark; 7-bit text (ISO-2022-JP when it switches to kanji); the encoding recorded by
/// the application that wrote the file; UTF-8; then Foundation's guess among the preferred encoding and the
/// encodings of the user's languages, corrected by how Japanese or how much like words each reading looks.
/// Among the Shift JIS variants the Windows one (CP932), which TeX's Japanese engines read, is preferred.
enum EncodingDetector {
    static func ns(_ cf: CFStringEncodings) -> String.Encoding {
        String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cf.rawValue)))
    }

    static func ns(_ cf: CFStringBuiltInEncodings) -> String.Encoding {
        String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cf.rawValue))
    }

    /// TeXShop's list of encodings.
    static let availableEncodings: [String.Encoding] = {
        let list: [String.Encoding] = [
            ns(.macRoman), ns(.isoLatin1), ns(CFStringEncodings.isoLatin2), ns(.isoLatin5), ns(.isoLatin9), ns(.isoLatinGreek),
            ns(.macCentralEurRoman), ns(.macJapanese), ns(.dosJapanese), ns(.shiftJIS_X0213), ns(.EUC_JP), ns(.ISO_2022_JP),
            ns(.macKorean), ns(.dosKorean), .utf8, .unicode, ns(.macCyrillic), ns(.dosCyrillic), ns(.dosRussian),
            ns(.windowsLatin1), ns(.windowsLatin2), ns(.windowsCyrillic), ns(.KOI8_R), ns(.macChineseTrad), ns(.macChineseSimp),
            ns(.dosChineseTrad), ns(.dosChineseSimplif), ns(.GBK_95), ns(.EUC_CN), ns(.GB_2312_80), ns(.GB_18030_2000), .ascii,
        ]
        return list.filter { CFStringIsEncodingAvailable(CFStringConvertNSStringEncodingToEncoding($0.rawValue)) }
    }()

    static func isAvailable(_ encoding: String.Encoding) -> Bool { availableEncodings.contains(encoding) }

    static func decodes(_ data: Data, _ encoding: String.Encoding) -> Bool { String(data: data, encoding: encoding) != nil }

    /// Whether data decodes and encodes back to the same bytes, so that saving the file unchanged writes the same file.
    static func roundTrips(_ data: Data, _ encoding: String.Encoding) -> Bool {
        guard let text = String(data: data, encoding: encoding) else { return false }
        return text.data(using: encoding, allowLossyConversion: false) == data
    }

    /// The encoding that TextEdit and other applications record in com.apple.TextEncoding ("utf-8;134217984").
    static func recordedEncoding(_ url: URL?) -> String.Encoding? {
        guard let url, url.isFileURL else { return nil }
        var buffer = [CChar](repeating: 0, count: 256)
        let length = url.withUnsafeFileSystemRepresentation { path in
            path.map { getxattr($0, "com.apple.TextEncoding", &buffer, 255, 0, 0) } ?? -1
        }
        guard length > 0, let value = String(validatingUTF8: Array(buffer[..<length]) + [0]) else { return nil }
        let parts = value.components(separatedBy: ";")
        var cf = CFStringEncoding(kCFStringEncodingInvalidId)
        if parts.count > 1, let number = UInt32(parts[1]) {
            cf = number
        } else {
            cf = CFStringConvertIANACharSetNameToEncoding(parts[0] as CFString)
        }
        guard cf != kCFStringEncodingInvalidId, CFStringIsEncodingAvailable(cf) else { return nil }
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cf))
    }

    /// The encodings of a group of languages, most likely first.
    static func family(_ name: String) -> [String.Encoding] {
        switch name {
        case "ja": return [ns(.EUC_JP), ns(.dosJapanese), ns(.macJapanese), ns(.shiftJIS_X0213)]
        case "ko": return [ns(.dosKorean), ns(.macKorean)]
        case "zh-Hans": return [ns(.GB_18030_2000), ns(.macChineseSimp)]
        case "zh-Hant": return [ns(.dosChineseTrad), ns(.macChineseTrad)]
        case "cyrillic": return [ns(.windowsCyrillic), ns(.KOI8_R), ns(.macCyrillic), ns(.dosRussian), ns(.dosCyrillic)]
        case "central": return [ns(.windowsLatin2), ns(CFStringEncodings.isoLatin2), ns(.macCentralEurRoman)]
        case "el": return [ns(.isoLatinGreek)]
        case "tr": return [ns(.isoLatin5)]
        default: return [ns(.windowsLatin1), ns(.isoLatin1), ns(.isoLatin9), ns(.macRoman)]
        }
    }

    /// Encodings that read the same text from the same bytes except for a few characters.
    static func variants(_ encoding: String.Encoding) -> [String.Encoding] {
        let groups: [[String.Encoding]] = [
            [ns(.dosJapanese), ns(.shiftJIS_X0213), ns(.macJapanese)],
            [ns(.GB_18030_2000), ns(.GBK_95), ns(.EUC_CN), ns(.dosChineseSimplif), ns(.macChineseSimp)],
            [ns(.dosChineseTrad), ns(.macChineseTrad)],
            [ns(.dosKorean), ns(.macKorean)],
        ]
        return groups.first { $0.contains(encoding) } ?? []
    }

    static func families(forLanguage language: String) -> [String] {
        let code = language.components(separatedBy: "-").first ?? ""
        if ["ja", "ko", "el", "tr"].contains(code) { return [code] }
        if code == "zh" {
            let traditional = language.contains("Hant") || language.hasSuffix("-TW") || language.hasSuffix("-HK") || language.hasSuffix("-MO")
            return [traditional ? "zh-Hant" : "zh-Hans"]
        }
        // Serbian and Bosnian are written in Cyrillic and in Latin letters.
        if code == "sr" || code == "bs" { return ["cyrillic", "central"] }
        if ["ru", "uk", "be", "bg", "mk", "kk"].contains(code) { return ["cyrillic"] }
        if ["cs", "pl", "hu", "sk", "sl", "hr", "ro"].contains(code) { return ["central"] }
        return []
    }

    static func isSingleByte(_ encoding: String.Encoding) -> Bool {
        ["western", "cyrillic", "central", "el", "tr"].contains { family($0).contains(encoding) } || encoding == .ascii
    }

    // MARK: Scores

    struct JapaneseScore { var score = 0.0; var kana = 0; var japanese = 0; var unlikely = 0 }

    /// How much a text looks like Japanese: kana, common (JIS level 1) kanji and Japanese punctuation count for it;
    /// half-width katakana, private use and control characters against it.
    static func scoreJapanese(_ text: String) -> JapaneseScore {
        var result = JapaneseScore()
        var examined = 0
        for unit in text.utf16 where unit >= 0x80 {
            if examined >= 4000 { break }
            examined += 1
            let c = unit
            if (0x3041...0x3096).contains(c) || (0x30A1...0x30FA).contains(c) || c == 0x30FC {
                result.score += 2; result.kana += 1; result.japanese += 1
            } else if (0x3000...0x303F).contains(c) || (0xFF01...0xFF5E).contains(c) {
                result.score += 1; result.japanese += 1
            } else if (0x4E00...0x9FFF).contains(c) {
                let euc = String(utf16CodeUnits: [c], count: 1).data(using: .japaneseEUC).map(Array.init) ?? []
                let levelOne = euc.count == 2 && (0xB0...0xCF).contains(euc[0])
                result.score += levelOne ? 1.5 : 0.5
                if levelOne { result.japanese += 1 }
            } else if (0xFF61...0xFF9F).contains(c) {
                result.score -= 2; result.unlikely += 1
            } else if (0xE000...0xF8FF).contains(c) || c < 0xA0 {
                result.score -= 3; result.unlikely += 1
            } else {
                result.score -= 0.5
            }
        }
        return result
    }

    /// The most plausible Japanese reading; readings that write the file back unchanged win, and on a tie
    /// the earlier encoding of the family.
    static func bestJapanese(_ data: Data) -> (encoding: String.Encoding, score: JapaneseScore)? {
        var best: (encoding: String.Encoding, score: JapaneseScore, roundTrips: Bool)?
        for encoding in family("ja") where isAvailable(encoding) {
            guard let text = String(data: data, encoding: encoding) else { continue }
            let roundTrips = text.data(using: encoding, allowLossyConversion: false) == data
            let score = scoreJapanese(text)
            if best == nil || (roundTrips && !best!.roundTrips) || (roundTrips == best!.roundTrips && score.score > best!.score.score) {
                best = (encoding, score, roundTrips)
            }
        }
        return best.map { ($0.encoding, $0.score) }
    }

    struct AlphabeticScore { var score = 0.0; var suspicious = 0 }

    /// How much a text read in a one-byte encoding looks like words.
    static func scoreAlphabetic(_ text: String) -> AlphabeticScore {
        let lower = CharacterSet.lowercaseLetters, upper = CharacterSet.uppercaseLetters, letters = CharacterSet.letters
        let neutral = Set("\u{00A0}\u{00AB}\u{00BB}\u{201E}\u{201C}\u{201D}\u{2018}\u{2019}\u{201A}\u{2013}\u{2014}\u{2026}\u{20AC}\u{00A7}\u{00B0}\u{00A9}\u{00AE}\u{00B7}\u{00BF}\u{00A1}\u{00A2}\u{00A3}\u{00A4}\u{00A5}\u{2116}".utf16)
        func member(_ set: CharacterSet, _ c: UInt16) -> Bool { Unicode.Scalar(c).map { set.contains($0) } ?? false }
        var result = AlphabeticScore()
        var previous: UInt16 = 0x20
        var examined = 0
        for c in text.utf16 {
            if examined >= 20000 { break }
            let asciiLetter = (0x41...0x5A).contains(c) || (0x61...0x7A).contains(c)
            let previousAsciiLetter = (0x41...0x5A).contains(previous) || (0x61...0x7A).contains(previous)
            let greekOrCyrillic = (0x0370..<0x0530).contains(c)
            let previousGreekOrCyrillic = (0x0370..<0x0530).contains(previous)
            if c < 0x80 {
                if ((0x41...0x5A).contains(c) && previous >= 0x80 && member(lower, previous)) || (asciiLetter && previousGreekOrCyrillic) {
                    result.score -= 1; result.suspicious += 1
                }
                previous = c
                continue
            }
            examined += 1
            if greekOrCyrillic && previousAsciiLetter && member(letters, c) {
                result.score -= 1; result.suspicious += 1
                previous = c
                continue
            }
            if (0x00C0..<0x0250).contains(c) && (0x00C0..<0x0250).contains(previous) && member(letters, c) && member(letters, previous) {
                result.score -= 1
                previous = c
                continue
            }
            if member(lower, c) {
                result.score += 1
            } else if member(upper, c) {
                if member(lower, previous) { result.score -= 1; result.suspicious += 1 } else { result.score += 0.5 }
            } else if member(letters, c) {
                result.score += 0.5
            } else if !neutral.contains(c) {
                result.score -= 2; result.suspicious += 1
            }
            previous = c
        }
        return result
    }

    /// The one-byte encoding that \usepackage[...]{inputenc} declares; the last option is the one used.
    static func inputencEncoding(_ data: Data) -> String.Encoding? {
        guard let text = String(data: data.prefix(65536), encoding: .isoLatin1),
              let pattern = try? NSRegularExpression(pattern: "^[^%\\n]*\\\\usepackage\\s*\\[([^\\]]*)\\]\\s*\\{inputenc\\}", options: .anchorsMatchLines),
              let match = pattern.firstMatch(in: text, range: NSRange(location: 0, length: (text as NSString).length)) else { return nil }
        let option = (text as NSString).substring(with: match.range(at: 1)).components(separatedBy: ",").last?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let encodings: [String: String.Encoding] = [
            "latin1": ns(.isoLatin1), "latin2": ns(CFStringEncodings.isoLatin2), "latin5": ns(.isoLatin5), "latin9": ns(.isoLatin9),
            "cp1250": ns(.windowsLatin2), "cp1251": ns(.windowsCyrillic), "cp1252": ns(.windowsLatin1), "ansinew": ns(.windowsLatin1),
            "koi8-r": ns(.KOI8_R), "cp866": ns(.dosRussian), "cp855": ns(.dosCyrillic), "applemac": ns(.macRoman),
            "macce": ns(.macCentralEurRoman), "maccyr": ns(.macCyrillic), "macukr": ns(.macCyrillic),
        ]
        return encodings[option]
    }

    // MARK: Detection

    static func detect(_ data: Data, url: URL? = nil, preferred: String.Encoding = .utf8,
                       languages: [String] = Locale.preferredLanguages) -> String.Encoding {
        let bytes = [UInt8](data)
        // A byte order mark.
        if bytes.starts(with: [0xEF, 0xBB, 0xBF]) { return .utf8 }
        if bytes.count >= 2, (bytes[0] == 0xFE && bytes[1] == 0xFF) || (bytes[0] == 0xFF && bytes[1] == 0xFE), decodes(data, .unicode) {
            return .unicode
        }
        // 7-bit text reads the same in the preferred encoding, unless it is ISO-2022-JP (ESC $ B).
        if bytes.allSatisfy({ $0 < 0x80 }) {
            let kanjiEscape = bytes.indices.contains { i in
                bytes[i] == 0x1B && i + 2 < bytes.count && bytes[i + 1] == 0x24 && (bytes[i + 2] == 0x42 || bytes[i + 2] == 0x40)
            }
            if kanjiEscape && decodes(data, .iso2022JP) { return .iso2022JP }
            // The preferred encoding is kept if it writes ASCII letters as ASCII; UTF-16 does not.
            return "Az09{}%".data(using: preferred) == Data("Az09{}%".utf8) ? preferred : .utf8
        }
        // The encoding recorded by the application that wrote the file.
        if let recorded = recordedEncoding(url), isAvailable(recorded), decodes(data, recorded) { return recorded }
        // Text with 8-bit bytes that is valid UTF-8 is almost certainly UTF-8.
        if decodes(data, .utf8) { return .utf8 }

        var families = ["ja", "ko", "zh-Hans", "zh-Hant", "cyrillic", "central", "el", "tr"].filter { family($0).contains(preferred) }
        for language in languages {
            for name in Self.families(forLanguage: language) where !families.contains(name) { families.append(name) }
        }
        families.append("western")
        var suggested: [String.Encoding] = []
        for encoding in [preferred] + families.flatMap(family) + availableEncodings where isAvailable(encoding) && !suggested.contains(encoding) {
            suggested.append(encoding)
        }

        // Let Foundation weigh the candidates by how plausible the decoded text is.
        var options: [StringEncodingDetectionOptionsKey: Any] = [
            .suggestedEncodingsKey: suggested.map { NSNumber(value: $0.rawValue) },
            .useOnlySuggestedEncodingsKey: true,
            .allowLossyKey: false,
        ]
        if let language = languages.first?.components(separatedBy: "-").first, !language.isEmpty {
            options[.likelyLanguageKey] = language
        }
        var converted: NSString?
        var lossy: ObjCBool = false
        var guessValue = NSString.stringEncoding(for: data, encodingOptions: options, convertedString: &converted, usedLossyConversion: &lossy)
        var guess: String.Encoding? = guessValue == 0 ? nil : String.Encoding(rawValue: guessValue)
        // For very short data the guess may not even read the file.
        if lossy.boolValue || (guess != nil && !(isAvailable(guess!) && decodes(data, guess!))) { guess = nil }
        guessValue = 0

        // Among the Japanese encodings, the reading that looks most like Japanese.
        let japanese = bestJapanese(data)
        if let g = guess, family("ja").contains(g), let japanese {
            guess = japanese.encoding
        } else if let japanese, guess == nil || isSingleByte(guess!), japanese.score.kana > 0, japanese.score.score > 0,
                  4 * japanese.score.unlikely <= japanese.score.japanese {
            // A one-byte guess, or none, gives way to clearly Japanese text.
            guess = japanese.encoding
        } else if let japanese, guess == nil, families.contains("ja"), japanese.score.score > 0, japanese.score.unlikely == 0,
                  roundTrips(data, japanese.encoding) {
            // No guess at all, for a Japanese user: a Japanese reading that looks like Japanese, even without kana.
            guess = japanese.encoding
        }

        // GB 18030 reads almost any bytes; a Japanese or Korean user who does not use Chinese gets their own encodings.
        if let g = guess, variants(ns(.GB_18030_2000)).contains(g), !families.contains("zh-Hans"), !families.contains("zh-Hant") {
            if families.contains("ja"), let japanese, roundTrips(data, japanese.encoding) {
                guess = japanese.encoding
            } else if families.contains("ko"), let korean = family("ko").first(where: { isAvailable($0) && roundTrips(data, $0) }) {
                guess = korean
            }
        }

        // Among one-byte encodings, compare the readings of the user's groups, the preferred encoding and the guess.
        if guess == nil || isSingleByte(guess!) {
            var oneByte: [String.Encoding] = []
            func add(_ encoding: String.Encoding) { if !oneByte.contains(encoding) { oneByte.append(encoding) } }
            if isSingleByte(preferred) { add(preferred) }
            if let guess { add(guess) }
            for name in families { family(name).filter(isSingleByte).forEach(add) }
            if guess == nil { guess = oneByte.first { isAvailable($0) && decodes(data, $0) } }
            // An ISO encoding whose reading has C1 control characters is usually the Windows encoding.
            let windows: [String.Encoding: String.Encoding] = [ns(.isoLatin1): ns(.windowsLatin1), ns(.isoLatin9): ns(.windowsLatin1),
                                                               ns(CFStringEncodings.isoLatin2): ns(.windowsLatin2)]
            if let g = guess, let w = windows[g], isAvailable(w), let reading = String(data: data, encoding: g),
               let windowsReading = String(data: data, encoding: w) {
                let c1 = CharacterSet(charactersIn: Unicode.Scalar(0x80)!...Unicode.Scalar(0x9F)!)
                if reading.rangeOfCharacter(from: c1) != nil && windowsReading.rangeOfCharacter(from: c1) == nil { guess = w }
            }
            // A guess of the user's groups that reads as clean words is kept.
            let guessReading = guess.flatMap { String(data: data, encoding: $0) }.map(scoreAlphabetic) ?? AlphabeticScore(score: 0, suspicious: 1)
            if let g = guess, guessReading.suspicious == 0, oneByte.contains(g) { oneByte.removeAll() }
            var best: (encoding: String.Encoding, score: Double)?
            for candidate in oneByte where isAvailable(candidate) {
                guard let text = String(data: data, encoding: candidate) else { continue }
                let score = scoreAlphabetic(text).score
                if best == nil || score > best!.score { best = (candidate, score) }
            }
            if let best { guess = best.encoding }
            // The encoding declared to inputenc, unless its reading looks clearly worse.
            if let declared = inputencEncoding(data), let g = guess, declared != g, isAvailable(declared),
               let declaredText = String(data: data, encoding: declared), let guessText = String(data: data, encoding: g) {
                let declaredScore = scoreAlphabetic(declaredText).score, guessScore = scoreAlphabetic(guessText).score
                if declaredScore >= guessScore - max(2.0, 0.1 * abs(guessScore)) { guess = declared }
            }
        }

        if var g = guess {
            // GB 18030 includes GBK and GB 2312; use it whenever it writes the file back unchanged.
            let gb18030 = ns(.GB_18030_2000)
            if variants(gb18030).contains(g), g != gb18030, isAvailable(gb18030), roundTrips(data, gb18030) { g = gb18030 }
            let group = variants(g)
            // A variant that is the preferred encoding is kept.
            if preferred != g, group.contains(preferred), roundTrips(data, preferred) { return preferred }
            // If the guess does not write the file back unchanged, a variant that does is used.
            if !roundTrips(data, g), let variant = group.first(where: { isAvailable($0) && roundTrips(data, $0) }) { return variant }
            return g
        }
        return suggested.first { decodes(data, $0) } ?? preferred
    }

    /// Text for editing: Shift JIS X0213 reads 0x7E as an overline and, like MacJapanese, 0x5C as a yen sign;
    /// in TeX both are the tilde and the backslash.
    static func textForEditing(_ text: String, encoding: String.Encoding) -> String {
        var text = text
        if encoding == ns(.shiftJIS_X0213) { text = text.replacingOccurrences(of: "\u{203E}", with: "~") }
        if encoding == ns(.macJapanese) || encoding == ns(.shiftJIS_X0213) { text = text.replacingOccurrences(of: "\u{00A5}", with: "\\") }
        return text
    }

    /// Text to write, so that backslashes, yen signs and tildes become 0x5C and 0x7E (TeXShop's TSTextForSaving).
    /// The Windows Shift JIS, EUC-JP and ISO-2022-JP have no yen sign: it is written as a backslash.
    static func textForSaving(_ text: String, encoding: String.Encoding) -> String {
        var text = text
        if encoding == ns(.macJapanese) || encoding == ns(.shiftJIS_X0213) { text = text.replacingOccurrences(of: "\\", with: "\u{00A5}") }
        if encoding == ns(.shiftJIS_X0213) { text = text.replacingOccurrences(of: "~", with: "\u{203E}") }
        if [ns(.dosJapanese), ns(.EUC_JP), ns(.ISO_2022_JP)].contains(encoding) { text = text.replacingOccurrences(of: "\u{00A5}", with: "\\") }
        return text
    }

    /// The preferred encoding for a profile's kanji encoding.
    static func preferredEncoding(forKanji kanji: String?) -> String.Encoding {
        switch kanji {
        case PTEX_ENCODING_SJIS: return ns(.dosJapanese)
        case PTEX_ENCODING_EUC: return ns(.EUC_JP)
        case PTEX_ENCODING_JIS: return ns(.ISO_2022_JP)
        default: return .utf8
        }
    }
}

extension String {
    /// Reads a TeX source in the encoding that TeXShop would choose for it (EncodingDetector).
    static func stringWithAutoEncodingDetectionOfData(_ data: Data, detectedEncoding encoding: UnsafeMutablePointer<UInt>,
                                                      url: URL? = nil, preferred: String.Encoding = .utf8) -> String? {
        let detected = EncodingDetector.detect(data, url: url, preferred: preferred)
        encoding.pointee = detected.rawValue
        guard let text = String(data: data, encoding: detected) else { return nil }
        return EncodingDetector.textForEditing(text, encoding: detected)
    }
}
