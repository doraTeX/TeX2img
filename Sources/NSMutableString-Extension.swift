import Foundation

@objc extension NSMutableString {
    @objc func replaceYenWithBackSlash() -> NSMutableString {
        let yenMark = "\u{00A5}"
        let backslash = "\\"
        replaceOccurrences(of: yenMark, with: backslash, options: [], range: NSRange(location: 0, length: length))
        return self
    }

    @objc(replaceFirstOccuarnceOfString:replacment:)
    func replaceFirstOccuarnce(ofString target: String, replacment replacement: String) -> NSMutableString {
        let range = self.range(of: target)
        if range.location != NSNotFound {
            replaceCharacters(in: range, with: replacement)
        }
        return self
    }

    @objc(replaceAllOccurrencesOfPattern:withString:)
    func replaceAllOccurrences(ofPattern pattern: String, withString replacement: String) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let matches = regex.matches(in: self as String, range: NSRange(location: 0, length: length))
        for match in matches.reversed() {
            replaceCharacters(in: match.range, with: replacement)
        }
    }

    @objc(replaceAllOccurrencesOfPattern:usingBlock:)
    func replaceAllOccurrences(ofPattern pattern: String, usingBlock replace: @escaping (String, [String]) -> String) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let matches = regex.matches(in: self as String, range: NSRange(location: 0, length: length))
        for match in matches.reversed() {
            var groups = [String]()
            if match.numberOfRanges > 1 {
                for index in 1..<match.numberOfRanges {
                    groups.append(substring(with: match.range(at: index)))
                }
            }
            replaceCharacters(in: match.range, with: replace(substring(with: match.range), groups))
        }
    }

    @objc(replaceAllOccurrencesOfString:withString:addingPercentForEndOfLine:)
    func replaceAllOccurrences(ofString target: String, withString replacement: String, addingPercentForEndOfLine addingPercent: Bool) {
        if addingPercent {
            let pairs: [(String, String)] = [
                ("\(target)\r\n", "\(replacement)%\r\n"),
                ("\(target)\r", "\(replacement)%\r"),
                ("\(target)\n", "\(replacement)%\n"),
            ]
            for (source, destination) in pairs {
                replaceOccurrences(of: source, with: destination, options: [], range: NSRange(location: 0, length: length))
            }
        }
        replaceOccurrences(of: target, with: replacement, options: [], range: NSRange(location: 0, length: length))
    }
}