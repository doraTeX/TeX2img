import CoreFoundation
import Foundation

extension NSString {
    static func UUIDString() -> String {
        let uuid = CFUUIDCreate(kCFAllocatorDefault)!
        return CFUUIDCreateString(kCFAllocatorDefault, uuid)! as String
    }

    var programPath: String {
        return components(separatedBy: " ").first ?? ""
    }

    var programName: String {
        return (programPath as NSString).lastPathComponent
    }

    var argumentsString: String {
        var components = self.components(separatedBy: " ")
        if !components.isEmpty {
            components.removeFirst()
        }
        return components.joined(separator: " ")
    }

    func pathStringByAppendingPageNumber(_ page: UInt) -> String {
        if page == 1 { return self as String }
        let path = self as String
        let directory = (path as NSString).deletingLastPathComponent
        let basename = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        let ext = (path as NSString).pathExtension
        let suffix = ext.isEmpty ? "" : ".\(ext)"
        return (directory as NSString).appendingPathComponent("\(basename)-\(page)\(suffix)")
    }

    func stringByReplacingPathExtension(_ extension: String) -> String {
        return ((self as String as NSString).deletingPathExtension as NSString).appendingPathExtension(`extension`) ?? (self as String)
    }

    func stringByAppendingStringSepareted(bySpace string: String) -> String {
        if string.isEmpty { return self as String }
        return "\(self) \(string)"
    }

    func stringByDeletingLastReturnCharacters() -> String {
        guard let regex = try? NSRegularExpression(pattern: "^(.*?)(?:\\r|\\n|\\r\\n)*$", options: .dotMatchesLineSeparators) else { return self as String }
        let range = NSRange(location: 0, length: length)
        guard let match = regex.firstMatch(in: self as String, range: range) else { return self as String }
        return substring(with: match.range(at: 1))
    }

    func stringByQuotingWithDoubleQuotations() -> String {
        return "\"\(self)\""
    }

    func dataUsingUTF8StringEncoding() -> Data {
        return (self as String).data(using: .utf8) ?? Data()
    }

    func numberOfComposedCharacters() -> UInt {
        let normalized = (self as String).precomposedStringWithCanonicalMapping
        var count: UInt = 0
        normalized.enumerateSubstrings(in: normalized.startIndex..<normalized.endIndex, options: [.byComposedCharacterSequences, .substringNotRequired]) { _, _, _, _ in
            count += 1
        }
        return count
    }

    func utf32char() -> UTF32Char {
        var outputChar: UTF32Char = 0
        var usedLength = 0
        let success = getBytes(&outputChar,
                               maxLength: MemoryLayout<UTF32Char>.size,
                               usedLength: &usedLength,
                               encoding: String.Encoding.utf32LittleEndian.rawValue,
                               options: [],
                               range: NSRange(location: 0, length: length),
                               remaining: nil)
        if success {
            outputChar = CFSwapInt32LittleToHost(outputChar)
        }
        return outputChar
    }

    static func stringWithUTF32Char(_ character: UTF32Char) -> String {
        var littleEndianCharacter = CFSwapInt32HostToLittle(character)
        return String(data: Data(bytes: &littleEndianCharacter, count: MemoryLayout<UTF32Char>.size), encoding: .utf32LittleEndian) ?? ""
    }

    static func stringWithAutoEncodingDetectionOfData(_ data: Data, detectedEncoding encoding: UnsafeMutablePointer<UInt>) -> String? {
        let stringEncodingList: [CFStringEncoding] = [
            0x0800_0100, // UTF-8
            0xFFFF_FFFF, // separator
            CFStringEncoding(CFStringEncodings.shiftJIS.rawValue),
            CFStringEncoding(CFStringEncodings.EUC_JP.rawValue),
            CFStringEncoding(CFStringEncodings.dosJapanese.rawValue),
            CFStringEncoding(CFStringEncodings.shiftJIS_X0213.rawValue),
            CFStringEncoding(CFStringEncodings.macJapanese.rawValue),
            CFStringEncoding(CFStringEncodings.ISO_2022_JP.rawValue),
            0xFFFF_FFFF,
            0x0100, // Unicode (UTF-16)
            0xFFFF_FFFF,
            CFStringEncoding(CFStringBuiltInEncodings.macRoman.rawValue),
            CFStringEncoding(CFStringBuiltInEncodings.windowsLatin1.rawValue),
            0xFFFF_FFFF,
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue),
            CFStringEncoding(CFStringEncodings.big5_HKSCS_1999.rawValue),
            CFStringEncoding(CFStringEncodings.big5_E.rawValue),
            CFStringEncoding(CFStringEncodings.big5.rawValue),
            CFStringEncoding(CFStringEncodings.macChineseTrad.rawValue),
            CFStringEncoding(CFStringEncodings.macChineseSimp.rawValue),
            CFStringEncoding(CFStringEncodings.EUC_TW.rawValue),
            CFStringEncoding(CFStringEncodings.EUC_CN.rawValue),
            CFStringEncoding(CFStringEncodings.dosChineseTrad.rawValue),
            CFStringEncoding(CFStringEncodings.dosChineseSimplif.rawValue),
            0xFFFF_FFFF,
            CFStringEncoding(CFStringEncodings.macKorean.rawValue),
            CFStringEncoding(CFStringEncodings.EUC_KR.rawValue),
            CFStringEncoding(CFStringEncodings.dosKorean.rawValue),
            0xFFFF_FFFF,
            CFStringEncoding(CFStringEncodings.macArabic.rawValue),
            CFStringEncoding(CFStringEncodings.macHebrew.rawValue),
            CFStringEncoding(CFStringEncodings.macGreek.rawValue),
            CFStringEncoding(CFStringEncodings.isoLatinGreek.rawValue),
            CFStringEncoding(CFStringEncodings.macCyrillic.rawValue),
            CFStringEncoding(CFStringEncodings.isoLatinCyrillic.rawValue),
            CFStringEncoding(CFStringEncodings.macCentralEurRoman.rawValue),
            CFStringEncoding(CFStringEncodings.macTurkish.rawValue),
            CFStringEncoding(CFStringEncodings.macIcelandic.rawValue),
            0xFFFF_FFFF,
            CFStringEncoding(CFStringBuiltInEncodings.isoLatin1.rawValue),
            CFStringEncoding(CFStringEncodings.isoLatin2.rawValue),
            CFStringEncoding(CFStringEncodings.isoLatin3.rawValue),
            CFStringEncoding(CFStringEncodings.isoLatin4.rawValue),
            CFStringEncoding(CFStringEncodings.isoLatin5.rawValue),
            CFStringEncoding(CFStringEncodings.dosLatinUS.rawValue),
            CFStringEncoding(CFStringEncodings.windowsLatin2.rawValue),
            CFStringEncoding(CFStringBuiltInEncodings.nextStepLatin.rawValue),
            CFStringEncoding(CFStringBuiltInEncodings.ASCII.rawValue),
            CFStringEncoding(CFStringBuiltInEncodings.nonLossyASCII.rawValue),
            0xFFFF_FFFF,
            CFStringEncoding(CFStringBuiltInEncodings.UTF16BE.rawValue),
            CFStringEncoding(CFStringBuiltInEncodings.UTF16LE.rawValue),
            CFStringEncoding(CFStringBuiltInEncodings.UTF32.rawValue),
            CFStringEncoding(CFStringBuiltInEncodings.UTF32BE.rawValue),
            CFStringEncoding(CFStringBuiltInEncodings.UTF32LE.rawValue),
        ]

        var string: String?
        var shouldSkipISO2022JP = false
        var shouldSkipUTF8 = false
        var shouldSkipUTF16 = false
        encoding.pointee = 0

        if !data.isEmpty {
            let bytes = [UInt8](data)
            let utf8BOM: [UInt8] = [0xEF, 0xBB, 0xBF]
            if bytes.count >= 3 && bytes[0] == utf8BOM[0] && bytes[1] == utf8BOM[1] && bytes[2] == utf8BOM[2] {
                shouldSkipUTF8 = true
                string = String(data: data, encoding: .utf8)
                if string != nil {
                    encoding.pointee = String.Encoding.utf8.rawValue
                }
            } else if bytes.count >= 2 && ((bytes[0] == 0xFF && bytes[1] == 0xFE) || (bytes[0] == 0xFE && bytes[1] == 0xFF)) {
                shouldSkipUTF16 = true
                string = String(data: data, encoding: .unicode)
                if string != nil {
                    encoding.pointee = String.Encoding.unicode.rawValue
                }
            } else if bytes.contains(0x1B) {
                shouldSkipISO2022JP = true
                string = String(data: data, encoding: .iso2022JP)
                if string != nil {
                    encoding.pointee = String.Encoding.iso2022JP.rawValue
                }
            }
        }

        if string == nil {
            for cfEncoding in stringEncodingList {
                let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
                encoding.pointee = nsEncoding
                if nsEncoding == String.Encoding.iso2022JP.rawValue && shouldSkipISO2022JP {
                    break
                } else if nsEncoding == String.Encoding.utf8.rawValue && shouldSkipUTF8 {
                    break
                } else if nsEncoding == String.Encoding.unicode.rawValue && shouldSkipUTF16 {
                    break
                } else if nsEncoding == UInt(NSProprietaryStringEncoding) {
                    break
                }
                if let candidate = String(data: data, encoding: String.Encoding(rawValue: nsEncoding)) {
                    string = candidate
                    break
                }
            }
        }

        return string
    }
}