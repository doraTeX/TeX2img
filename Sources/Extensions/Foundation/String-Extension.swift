import CoreFoundation
import Foundation

extension String {
    var deletingLastPathComponent: String {
        (self as NSString).deletingLastPathComponent
    }

    var lastPathComponent: String {
        (self as NSString).lastPathComponent
    }

    var pathExtension: String {
        (self as NSString).pathExtension
    }

    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }

    var standardizingPath: String {
        (self as NSString).standardizingPath
    }

    var expandingTildeInPath: String {
        (self as NSString).expandingTildeInPath
    }

    var programPath: String {
        components(separatedBy: " ").first ?? ""
    }

    var programName: String {
        programPath.lastPathComponent
    }

    var argumentsString: String {
        var components = self.components(separatedBy: " ")
        if !components.isEmpty {
            components.removeFirst()
        }
        return components.joined(separator: " ")
    }

    func appendingPathComponent(_ component: String) -> String {
        (self as NSString).appendingPathComponent(component)
    }

    func appendingPathExtension(_ extension: String) -> String? {
        (self as NSString).appendingPathExtension(`extension`)
    }

    func appendingStringSeparatedBySpace(_ string: String) -> String {
        if string.isEmpty { return self }
        return "\(self) \(string)"
    }

    func quotingWithDoubleQuotations() -> String {
        "\"\(self)\""
    }

    func pathStringByAppendingPageNumber(_ page: UInt) -> String {
        if page == 1 { return self }
        let basename = lastPathComponent.deletingPathExtension
        let ext = pathExtension
        let suffix = ext.isEmpty ? "" : ".\(ext)"
        return deletingLastPathComponent.appendingPathComponent("\(basename)-\(page)\(suffix)")
    }

    func replacingPathExtension(_ extension: String) -> String {
        deletingLastPathComponent.appendingPathExtension(`extension`) ?? self
    }

    func replacingYenWithBackslash() -> String {
        replacingOccurrences(of: "\u{00A5}", with: "\\")
    }

    func deletingLastReturnCharacters() -> String {
        (self as NSString).stringByDeletingLastReturnCharacters()
    }

    // MARK: - NSRange helpers (NSTextView / NSRegularExpression interop)

    var nsLength: Int {
        (self as NSString).length
    }

    func substring(with range: NSRange) -> String {
        (self as NSString).substring(with: range)
    }

    func substring(from offset: Int) -> String {
        (self as NSString).substring(from: offset)
    }

    func range(of searchString: String, options: NSString.CompareOptions = [], range searchRange: NSRange? = nil) -> NSRange {
        if let searchRange {
            return (self as NSString).range(of: searchString, options: options, range: searchRange)
        }
        return (self as NSString).range(of: searchString, options: options)
    }

    func character(at index: Int) -> unichar {
        (self as NSString).character(at: index)
    }

    func lineRange(for range: NSRange) -> NSRange {
        (self as NSString).lineRange(for: range)
    }

    func replacingCharacters(in range: NSRange, with replacement: String) -> String {
        (self as NSString).replacingCharacters(in: range, with: replacement)
    }

    func canBeConverted(to encoding: UInt) -> Bool {
        (self as NSString).canBeConverted(to: encoding)
    }

    // MARK: - UUID / encoding detection

    static func uuidString() -> String {
        let uuid = CFUUIDCreate(kCFAllocatorDefault)!
        return CFUUIDCreateString(kCFAllocatorDefault, uuid)! as String
    }

    static func stringWithAutoEncodingDetectionOfData(_ data: Data, detectedEncoding encoding: UnsafeMutablePointer<UInt>) -> String? {
        let stringEncodingList: [CFStringEncoding] = [
            0x0800_0100,
            0xFFFF_FFFF,
            CFStringEncoding(CFStringEncodings.shiftJIS.rawValue),
            CFStringEncoding(CFStringEncodings.EUC_JP.rawValue),
            CFStringEncoding(CFStringEncodings.dosJapanese.rawValue),
            CFStringEncoding(CFStringEncodings.shiftJIS_X0213.rawValue),
            CFStringEncoding(CFStringEncodings.macJapanese.rawValue),
            CFStringEncoding(CFStringEncodings.ISO_2022_JP.rawValue),
            0xFFFF_FFFF,
            0x0100,
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