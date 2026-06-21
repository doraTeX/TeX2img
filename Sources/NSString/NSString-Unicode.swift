import CoreFoundation
import Foundation

private let compositionExclusionRegex = #"([\x{0340}\x{0341}\x{0343}\x{0344}\x{0374}\x{037E}\x{0387}\x{0958}-\x{095F}\x{09DC}\x{09DD}\x{09DF}\x{0A33}\x{0A36}\x{0A59}-\x{0A5B}\x{0A5E}\x{0B5C}\x{0B5D}\x{0F43}\x{0F4D}\x{0F52}\x{0F57}\x{0F5C}\x{0F69}\x{0F73}\x{0F75}\x{0F76}\x{0F78}\x{0F81}\x{0F93}\x{0F9D}\x{0FA2}\x{0FA7}\x{0FAC}\x{0FB9}\x{1F71}\x{1F73}\x{1F75}\x{1F77}\x{1F79}\x{1F7B}\x{1F7D}\x{1FBB}\x{1FBE}\x{1FC9}\x{1FCB}\x{1FD3}\x{1FDB}\x{1FE3}\x{1FEB}\x{1FEE}\x{1FEF}\x{1FF9}\x{1FFB}\x{1FFD}\x{2000}\x{2001}\x{2126}\x{212A}\x{212B}\x{2329}\x{232A}\x{2ADC}\x{F900}-\x{FA0D}\x{FA10}\x{FA12}\x{FA15}-\x{FA1E}\x{FA20}\x{FA22}\x{FA25}\x{FA26}\x{FA2A}-\x{FA6D}\x{FA70}-\x{FAD9}\x{FB1D}\x{FB1F}\x{FB2A}-\x{FB36}\x{FB38}-\x{FB3C}\x{FB3E}\x{FB40}\x{FB41}\x{FB43}\x{FB44}\x{FB46}-\x{FB4E}\x{1D15E}-\x{1D164}\x{1D1BB}-\x{1D1C0}\x{2F800}-\x{2FA1D}]*)([^\x{0340}\x{0341}\x{0343}\x{0344}\x{0374}\x{037E}\x{0387}\x{0958}-\x{095F}\x{09DC}\x{09DD}\x{09DF}\x{0A33}\x{0A36}\x{0A59}-\x{0A5B}\x{0A5E}\x{0B5C}\x{0B5D}\x{0F43}\x{0F4D}\x{0F52}\x{0F57}\x{0F5C}\x{0F69}\x{0F73}\x{0F75}\x{0F76}\x{0F78}\x{0F81}\x{0F93}\x{0F9D}\x{0FA2}\x{0FA7}\x{0FAC}\x{0FB9}\x{1F71}\x{1F73}\x{1F75}\x{1F77}\x{1F79}\x{1F7B}\x{1F7D}\x{1FBB}\x{1FBE}\x{1FC9}\x{1FCB}\x{1FD3}\x{1FDB}\x{1FE3}\x{1FEB}\x{1FEE}\x{1FEF}\x{1FF9}\x{1FFB}\x{1FFD}\x{2000}\x{2001}\x{2126}\x{212A}\x{212B}\x{2329}\x{232A}\x{2ADC}\x{F900}-\x{FA0D}\x{FA10}\x{FA12}\x{FA15}-\x{FA1E}\x{FA20}\x{FA22}\x{FA25}\x{FA26}\x{FA2A}-\x{FA6D}\x{FA70}-\x{FAD9}\x{FB1D}\x{FB1F}\x{FB2A}-\x{FB36}\x{FB38}-\x{FB3C}\x{FB3E}\x{FB40}\x{FB41}\x{FB43}\x{FB44}\x{FB46}-\x{FB4E}\x{1D15E}-\x{1D164}\x{1D1BB}-\x{1D1C0}\x{2F800}-\x{2FA1D}]+)([\x{0340}\x{0341}\x{0343}\x{0344}\x{0374}\x{037E}\x{0387}\x{0958}-\x{095F}\x{09DC}\x{09DD}\x{09DF}\x{0A33}\x{0A36}\x{0A59}-\x{0A5B}\x{0A5E}\x{0B5C}\x{0B5D}\x{0F43}\x{0F4D}\x{0F52}\x{0F57}\x{0F5C}\x{0F69}\x{0F73}\x{0F75}\x{0F76}\x{0F78}\x{0F81}\x{0F93}\x{0F9D}\x{0FA2}\x{0FA7}\x{0FAC}\x{0FB9}\x{1F71}\x{1F73}\x{1F75}\x{1F77}\x{1F79}\x{1F7B}\x{1F7D}\x{1FBB}\x{1FBE}\x{1FC9}\x{1FCB}\x{1FD3}\x{1FDB}\x{1FE3}\x{1FEB}\x{1FEE}\x{1FEF}\x{1FF9}\x{1FFB}\x{1FFD}\x{2000}\x{2001}\x{2126}\x{212A}\x{212B}\x{2329}\x{232A}\x{2ADC}\x{F900}-\x{FA0D}\x{FA10}\x{FA12}\x{FA15}-\x{FA1E}\x{FA20}\x{FA22}\x{FA25}\x{FA26}\x{FA2A}-\x{FA6D}\x{FA70}-\x{FAD9}\x{FB1D}\x{FB1F}\x{FB2A}-\x{FB36}\x{FB38}-\x{FB3C}\x{FB3E}\x{FB40}\x{FB41}\x{FB43}\x{FB44}\x{FB46}-\x{FB4E}\x{1D15E}-\x{1D164}\x{1D1BB}-\x{1D1C0}\x{2F800}-\x{2FA1D}]*)"#

private let c0ControlCharNames = [
    "NULL",
    "START OF HEADING",
    "START OF TEXT",
    "END OF TEXT",
    "END OF TRANSMISSION",
    "ENQUIRY",
    "ACKNOWLEDGE",
    "BELL",
    "BACKSPACE",
    "HORIZONTAL TABULATION",
    "LINE FEED",
    "VERTICAL TABULATION",
    "FORM FEED",
    "CARRIAGE RETURN",
    "SHIFT OUT",
    "SHIFT IN",
    "DATA LINK ESCAPE",
    "DEVICE CONTROL ONE",
    "DEVICE CONTROL TWO",
    "DEVICE CONTROL THREE",
    "DEVICE CONTROL FOUR",
    "NEGATIVE ACKNOWLEDGE",
    "SYNCHRONOUS IDLE",
    "END OF TRANSMISSION BLOCK",
    "CANCEL",
    "END OF MEDIUM",
    "SUBSTITUTE",
    "ESCAPE",
    "FILE SEPARATOR",
    "GROUP SEPARATOR",
    "RECORD SEPARATOR",
    "UNIT SEPARATOR",
    "SPACE",
]

private let c1ControlCharNames = [
    "PADDING CHARACTER",
    "HIGH OCTET PRESET",
    "BREAK PERMITTED HERE",
    "NO BREAK HERE",
    "INDEX",
    "NEXT LINE",
    "START OF SELECTED AREA",
    "END OF SELECTED AREA",
    "CHARACTER TABULATION SET",
    "CHARACTER TABULATION WITH JUSTIFICATION",
    "LINE TABULATION SET",
    "PARTIAL LINE FORWARD",
    "PARTIAL LINE BACKWARD",
    "REVERSE LINE FEED",
    "SINGLE SHIFT TWO",
    "SINGLE SHIFT THREE",
    "DEVICE CONTROL STRING",
    "PRIVATE USE ONE",
    "PRIVATE USE TWO",
    "SET TRANSMIT STATE",
    "CANCEL CHARACTER",
    "MESSAGE WAITING",
    "START OF PROTECTED AREA",
    "END OF PROTECTED AREA",
    "START OF STRING",
    "SINGLE GRAPHIC CHARACTER INTRODUCER",
    "SINGLE CHARACTER INTRODUCER",
    "CONTROL SEQUENCE INTRODUCER",
    "STRING TERMINATOR",
    "OPERATING SYSTEM COMMAND",
    "PRIVACY MESSAGE",
    "APPLICATION PROGRAM COMMAND",
]

private let normalizationFactor = 256

extension NSString {
    func unicodeName() -> String {
        let mutableUnicodeName = NSMutableString(string: self)
        CFStringTransform(mutableUnicodeName, nil, "Any-Name" as CFString, false)

        let regex = try? NSRegularExpression(pattern: "\\{(.+?)\\}", options: [])
        let range = NSRange(location: 0, length: mutableUnicodeName.length)
        let firstMatch = regex?.firstMatch(in: mutableUnicodeName as String, options: [], range: range)
        return mutableUnicodeName.substring(with: firstMatch!.range(at: 1))
    }

    func blockName() -> String {
        let utf32char = utf32char()
        let prop = u_getIntPropertyValue(Int32(utf32char), UCHAR_BLOCK)
        let blockNameChars = u_getPropertyValueName(UCHAR_BLOCK, prop, U_LONG_PROPERTY_NAME)
        return String(cString: blockNameChars!).replacingOccurrences(of: "_", with: " ")
    }

    func localizedBlockName() -> String {
        var blockName = blockName()
        blockName = NSString.sanitizeBlockName(blockName)
        return NSLocalizedString(blockName, tableName: "UnicodeBlocks", bundle: .main, value: "", comment: "")
    }

    private static func sanitizeBlockName(_ blockName: String) -> String {
        var sanitized = blockName
        let fullRange = NSRange(location: 0, length: sanitized.utf16.count)
        sanitized = (sanitized as NSString).replacingOccurrences(
            of: " ([A-Z])$",
            with: "-$1",
            options: .regularExpression,
            range: fullRange
        )
        sanitized = sanitized.replacingOccurrences(of: "Extension-", with: "Ext. ")
        sanitized = sanitized.replacingOccurrences(of: " And ", with: " and ")
        sanitized = sanitized.replacingOccurrences(of: " For ", with: " for ")
        sanitized = sanitized.replacingOccurrences(of: " Mathematical ", with: " Math ")
        sanitized = sanitized.replacingOccurrences(of: "Latin 1", with: "Latin-1")
        return sanitized
    }

    private func normalizedStringConsideringCompositionExclusions(baseNormalization: (String) -> String) -> String {
        guard let regexp = try? NSRegularExpression(pattern: compositionExclusionRegex, options: []) else { return self as String }

        let result = NSMutableString()
        let fullRange = NSRange(location: 0, length: length)
        regexp.enumerateMatches(in: self as String, options: [], range: fullRange) { match, _, _ in
            guard let match else { return }
            let prefix = self.substring(with: match.range(at: 1))
            let middle = self.substring(with: match.range(at: 2))
            let suffix = self.substring(with: match.range(at: 3))
            result.appendFormat("%@%@%@", prefix, baseNormalization(middle), suffix)
        }
        return result as String
    }

    func normalizedStringWithModifiedNFC() -> String {
        return normalizedStringConsideringCompositionExclusions { $0.precomposedStringWithCanonicalMapping }
    }

    func normalizedStringWithModifiedNFD() -> String {
        let sourceStr = self as CFString
        let bufferLength = CFStringGetMaximumSizeOfFileSystemRepresentation(sourceStr)
        let destStr = UnsafeMutablePointer<CChar>.allocate(capacity: bufferLength)
        defer { destStr.deallocate() }

        let success = CFStringGetFileSystemRepresentation(sourceStr, destStr, bufferLength)
        if success {
            return String(cString: destStr)
        }
        return self as String
    }

    func normalizedStringWithNFKC_CF() -> String {
        var error = U_ZERO_ERROR

        guard let normalizer = unorm2_getInstance(UnsafeMutablePointer<CChar>(bitPattern: 0), "nfkc_cf", UNORM2_COMPOSE, &error) else {
            NSLog("unorm2_getInstance failed - %s", u_errorName(error))
            return self as String
        }

        if error.rawValue > 0 {
            NSLog("unorm2_getInstance failed - %s", u_errorName(error))
            return self as String
        }

        return (self as String).withCString { utf8Src in
            let length = Int(strlen(utf8Src)) * normalizationFactor

            let utf16Src = UnsafeMutablePointer<UChar>.allocate(capacity: length)
            defer { utf16Src.deallocate() }

            u_strFromUTF8(utf16Src, Int32(length), UnsafeMutablePointer<Int32>(bitPattern: 0), utf8Src, -1, &error)
            if error.rawValue > 0 {
                NSLog("u_strFromUTF8 failed - %s", u_errorName(error))
                return self as String
            }

            let utf16Dest = UnsafeMutablePointer<UChar>.allocate(capacity: length)
            defer { utf16Dest.deallocate() }

            unorm2_normalize(normalizer, utf16Src, -1, utf16Dest, Int32(length), &error)
            if error.rawValue > 0 {
                NSLog("unorm2_normalize failed - %s", u_errorName(error))
                return self as String
            }

            let utf8Dest = UnsafeMutablePointer<CChar>.allocate(capacity: length)
            defer { utf8Dest.deallocate() }

            u_strToUTF8(utf8Dest, Int32(length), UnsafeMutablePointer<Int32>(bitPattern: 0), utf16Dest, -1, &error)
            if error.rawValue > 0 {
                NSLog("u_strToUTF8 failed - %s", u_errorName(error))
                return self as String
            }

            return String(cString: utf8Dest)
        }
    }

    static func controlCharacterName(withCharacter character: unichar) -> String? {
        if character <= 0x0020 {
            return c0ControlCharNames[Int(character)]
        }
        if character == 0x007F {
            return "DELETE"
        }
        if character >= 0x0080 && character <= 0x009F {
            return c1ControlCharNames[Int(character) - 0x0080]
        }
        return nil
    }
}