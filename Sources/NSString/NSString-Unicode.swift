import CoreFoundation
import Foundation

// Runs outside Full_Composition_Exclusion. ICU supplies the property from the OS Unicode data,
// so the set follows new Unicode versions (CotEditor uses the same property).
private let composableRunRegex = try? NSRegularExpression(pattern: #"\P{Full_Composition_Exclusion}+"#, options: [])

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
        guard let firstMatch = regex?.firstMatch(in: mutableUnicodeName as String, options: [], range: range) else { return self as String }
        return mutableUnicodeName.substring(with: firstMatch.range(at: 1))
    }

    func blockName() -> String {
        let utf32char = utf32char()
        let prop = u_getIntPropertyValue(Int32(utf32char), UCHAR_BLOCK)
        guard let blockNameChars = u_getPropertyValueName(UCHAR_BLOCK, prop, U_LONG_PROPERTY_NAME) else { return "" }
        return String(cString: blockNameChars).replacingOccurrences(of: "_", with: " ")
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

    /// Apple modified NFC, as in CotEditor's `precomposedStringWithHFSPlusMapping`: only runs outside
    /// Full_Composition_Exclusion are composed; excluded characters such as CJK compatibility
    /// ideographs stay as they are. Text made only of excluded characters is returned unchanged.
    func normalizedStringWithModifiedNFC() -> String {
        guard let regex = composableRunRegex else { return self as String }
        let result = NSMutableString(string: self)
        let matches = regex.matches(in: self as String, options: [], range: NSRange(location: 0, length: length))
        for match in matches.reversed() {
            result.replaceCharacters(in: match.range, with: self.substring(with: match.range).precomposedStringWithCanonicalMapping)
        }
        return result as String
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
