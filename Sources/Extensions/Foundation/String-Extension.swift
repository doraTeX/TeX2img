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

    /// One shell word with exactly this text: in single quotes, with each single quote written as '\''.
    func quotingForShell() -> String {
        "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// An AppleScript that runs a command with administrator privileges. Every argument stays one word,
    /// whatever spaces or quotes it has.
    static func administratorShellAppleScript(command: String, directory: String, arguments: [String]) -> String {
        let shellScript = "cd \(directory.quotingForShell()) && " + ([command] + arguments).map { $0.quotingForShell() }.joined(separator: " ")
        let literal = shellScript.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        return "do shell script \"\(literal)\" with administrator privileges"
    }

    func pathStringByAppendingPageNumber(_ page: UInt) -> String {
        if page == 1 { return self }
        let basename = lastPathComponent.deletingPathExtension
        let ext = pathExtension
        let suffix = ext.isEmpty ? "" : ".\(ext)"
        return deletingLastPathComponent.appendingPathComponent("\(basename)-\(page)\(suffix)")
    }

    func replacingPathExtension(_ extension: String) -> String {
        // deletingPathExtension は親フォルダも保持するため、再連結しない。
        (deletingPathExtension as NSString).appendingPathExtension(`extension`) ?? deletingPathExtension
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

    var length: Int {
        nsLength
    }

    func substring(with range: NSRange) -> String {
        guard range.location != NSNotFound,
              range.location >= 0,
              range.length >= 0,
              range.location <= nsLength,
              range.length <= nsLength - range.location else { return "" }
        return (self as NSString).substring(with: range)
    }

    func substring(from offset: Int) -> String {
        guard offset >= 0, offset <= nsLength else { return "" }
        return (self as NSString).substring(from: offset)
    }

    func substring(to offset: Int) -> String {
        guard offset >= 0, offset <= nsLength else { return "" }
        return (self as NSString).substring(to: offset)
    }

    func getLineStart(
        _ start: UnsafeMutablePointer<Int>?,
        end: UnsafeMutablePointer<Int>?,
        contentsEnd: UnsafeMutablePointer<Int>?,
        for range: NSRange
    ) {
        let location = min(max(range.location, 0), nsLength)
        let length = min(max(range.length, 0), nsLength - location)
        (self as NSString).getLineStart(start, end: end, contentsEnd: contentsEnd,
                                        for: NSRange(location: location, length: length))
    }

    func rangeOfCharacter(
        from searchSet: CharacterSet,
        options: NSString.CompareOptions = [],
        range searchRange: NSRange
    ) -> NSRange {
        guard searchRange.location != NSNotFound,
              searchRange.location >= 0,
              searchRange.length >= 0,
              searchRange.location <= nsLength,
              searchRange.length <= nsLength - searchRange.location else {
            return NSRange(location: NSNotFound, length: 0)
        }
        return (self as NSString).rangeOfCharacter(from: searchSet, options: options, range: searchRange)
    }

    func range(of searchString: String, options: NSString.CompareOptions = [], range searchRange: NSRange? = nil) -> NSRange {
        if let searchRange {
            guard searchRange.location != NSNotFound,
                  searchRange.location >= 0,
                  searchRange.length >= 0,
                  searchRange.location <= nsLength,
                  searchRange.length <= nsLength - searchRange.location else {
                return NSRange(location: NSNotFound, length: 0)
            }
            return (self as NSString).range(of: searchString, options: options, range: searchRange)
        }
        return (self as NSString).range(of: searchString, options: options)
    }

    func character(at index: Int) -> unichar {
        guard index >= 0, index < nsLength else { return 0 }
        return (self as NSString).character(at: index)
    }

    func lineRange(for range: NSRange) -> NSRange {
        guard range.location != NSNotFound,
              range.location >= 0,
              range.length >= 0,
              range.location <= nsLength,
              range.length <= nsLength - range.location else {
            return NSRange(location: min(max(range.location, 0), nsLength), length: 0)
        }
        return (self as NSString).lineRange(for: range)
    }

    func replacingCharacters(in range: NSRange, with replacement: String) -> String {
        guard range.location != NSNotFound,
              range.location >= 0,
              range.length >= 0,
              range.location <= nsLength,
              range.length <= nsLength - range.location else { return self }
        return (self as NSString).replacingCharacters(in: range, with: replacement)
    }

    func canBeConverted(to encoding: UInt) -> Bool {
        (self as NSString).canBeConverted(to: encoding)
    }

    // MARK: - UUID / encoding detection

    static func uuidString() -> String {
        UUID().uuidString
    }

}
