import Foundation

/// Reads the output of TeX and the other programs for the output window, ported from TeXShop 5.60
/// (TSEncodingSupport displayStringForData / lengthOfIncompleteCharacterAtEndOfData).
///
/// Output is read line by line, so that bytes in another encoding or broken bytes spoil only their own
/// line, and a line reads the same however the pipe divided the output. TeX breaks long lines after a
/// fixed number of bytes, which can put the line break inside a UTF-8 character; such a break is moved to
/// just before the character. A character that a piece of output does not finish is kept for the next one.
final class ConsoleOutputDecoder {
    let encoding: String.Encoding
    private var pending = Data()
    private let lock = NSLock()

    init(encoding: String.Encoding) {
        self.encoding = encoding == .unicode || encoding == .utf16BigEndian || encoding == .utf16LittleEndian ? .utf8 : encoding
    }

    /// The text of a new piece of output; the end of an unfinished character waits for the next piece.
    func append(_ data: Data) -> String {
        lock.lock()
        defer { lock.unlock() }
        pending.append(data)
        let keep = Self.lengthToKeep(pending, encoding: encoding, line: true)
        let shown = pending.prefix(pending.count - keep)
        pending = Data(pending.suffix(keep))
        return Self.displayString(Data(shown), encoding: encoding)
    }

    /// When no output comes for a while, shows an unfinished line, keeping only an unfinished character.
    func flushPause() -> String {
        lock.lock()
        defer { lock.unlock() }
        let keep = Self.lengthToKeep(pending, encoding: encoding, line: false)
        let shown = pending.prefix(pending.count - keep)
        pending = Data(pending.suffix(keep))
        return Self.displayString(Data(shown), encoding: encoding)
    }

    /// Everything that is left, at the end of the output.
    func finish() -> String {
        lock.lock()
        defer { lock.unlock() }
        let text = Self.displayString(pending, encoding: encoding)
        pending.removeAll()
        return text
    }

    /// The encoding of TeX's output for a profile's kanji encoding.
    static func encoding(forKanji kanji: String?) -> String.Encoding {
        func convert(_ value: CFStringEncodings) -> String.Encoding {
            String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(value.rawValue)))
        }
        switch kanji {
        case PTEX_ENCODING_SJIS: return convert(.dosJapanese)
        case PTEX_ENCODING_EUC: return convert(.EUC_JP)
        case PTEX_ENCODING_JIS: return convert(.ISO_2022_JP)
        default: return .utf8
        }
    }

    // MARK: Decoding

    private static func decodes(_ bytes: ArraySlice<UInt8>, _ encoding: String.Encoding) -> Bool {
        bytes.isEmpty || String(bytes: bytes, encoding: encoding) != nil
    }

    /// UTF-8 with each byte that is not UTF-8 replaced by U+FFFD, with the numbers of valid characters and invalid bytes.
    static func lenientUTF8(_ bytes: ArraySlice<UInt8>) -> (text: String, valid: Int, invalid: Int) {
        var result = ""
        var i = bytes.startIndex, segment = bytes.startIndex, valid = 0, invalid = 0
        while i < bytes.endIndex {
            let c = bytes[i]
            if c < 0x80 { i += 1; continue }
            var size = 0
            var minimum: UInt32 = 0
            if c >= 0xC2 && c <= 0xDF { size = 2; minimum = 0x80 }
            else if c >= 0xE0 && c <= 0xEF { size = 3; minimum = 0x800 }
            else if c >= 0xF0 && c <= 0xF4 { size = 4; minimum = 0x10000 }
            var ok = size > 0 && i + size <= bytes.endIndex
            if ok {
                var code = UInt32(c) & (0x7F >> UInt32(size))
                for k in 1..<size where ok {
                    if bytes[i + k] & 0xC0 != 0x80 { ok = false } else { code = (code << 6) | UInt32(bytes[i + k] & 0x3F) }
                }
                if ok && (code < minimum || code > 0x10FFFF || (0xD800...0xDFFF).contains(code)) { ok = false }
            }
            if ok {
                valid += 1
                i += size
                continue
            }
            if i > segment { result += String(decoding: bytes[segment..<i], as: UTF8.self) }
            result += "\u{FFFD}"
            invalid += 1
            i += 1
            segment = i
        }
        if bytes.endIndex > segment { result += String(decoding: bytes[segment..<bytes.endIndex], as: UTF8.self) }
        return (result, valid, invalid)
    }

    /// The number of bytes at the end that start a UTF-8 character without finishing it, and the size of that character.
    private static func unfinishedUTF8Character(_ bytes: ArraySlice<UInt8>) -> (count: Int, size: Int) {
        var k = 1
        while k <= 3 && k <= bytes.count {
            let c = bytes[bytes.endIndex - k]
            if c & 0xC0 == 0x80 { k += 1; continue }
            let whole = (0xC2...0xDF).contains(c) ? 2 : (0xE0...0xEF).contains(c) ? 3 : (0xF0...0xF4).contains(c) ? 4 : 0
            return whole > k ? (k, whole) : (0, 0)
        }
        return (0, 0)
    }

    private static func leadingContinuations(_ bytes: ArraySlice<UInt8>, limit: Int) -> Int {
        var n = 0
        while n < bytes.count && n < limit && bytes[bytes.startIndex + n] & 0xC0 == 0x80 { n += 1 }
        return n
    }

    /// The first line break (LF, CRLF or CR) at or after from, and its length (0 when there is none).
    private static func nextLineBreak(_ b: [UInt8], from: Int) -> (index: Int, length: Int) {
        var i = from
        while i < b.count {
            if b[i] == 0x0A { return (i, 1) }
            if b[i] == 0x0D { return (i, i + 1 < b.count && b[i + 1] == 0x0A ? 2 : 1) }
            i += 1
        }
        return (b.count, 0)
    }

    private static func lineStart(_ b: [UInt8], end: Int) -> Int {
        var end = end
        while end > 0 && b[end - 1] != 0x0A && b[end - 1] != 0x0D { end -= 1 }
        return end
    }

    /// Whether a line looks like a UTF-8 line that TeX broke inside a character.
    private static func lineBreakInsideCharacter(_ b: [UInt8], start: Int, end: Int, breakLength: Int,
                                                 encoding: String.Encoding) -> (unfinished: Int, needed: Int, present: Int)? {
        let (k, size) = unfinishedUTF8Character(b[start..<end])
        guard k > 0 else { return nil }
        if encoding != .utf8 && !decodes(b[start..<(end - k)], .utf8) { return nil }
        let present = leadingContinuations(b[min(b.count, end + breakLength)...], limit: size - k)
        return (k, size - k, present)
    }

    /// One line: UTF-8 first (a UTF-8 file name often also reads in Shift JIS, but Japanese encodings
    /// almost never read as UTF-8), then the encoding, then lenient UTF-8 when most of it is UTF-8, then Latin 9.
    /// A line of ASCII is read in the encoding, which may give its escape sequences a meaning (ISO-2022-JP).
    private static func displayLine(_ bytes: ArraySlice<UInt8>, encoding: String.Encoding) -> String {
        if bytes.isEmpty { return "" }
        if bytes.allSatisfy({ $0 < 0x80 }), let text = String(bytes: bytes, encoding: encoding) { return text }
        if let text = String(bytes: bytes, encoding: .utf8) { return text }
        if encoding != .utf8, let text = String(bytes: bytes, encoding: encoding) { return text }
        let lenient = lenientUTF8(bytes)
        if lenient.valid > 0 && lenient.valid >= lenient.invalid { return lenient.text }
        let latin9 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.isoLatin9.rawValue)))
        return String(bytes: bytes, encoding: latin9) ?? ""
    }

    static func displayString(_ data: Data, encoding: String.Encoding) -> String {
        if data.isEmpty { return "" }
        if encoding == .utf8, let text = String(data: data, encoding: .utf8) { return text }
        var b = [UInt8](data)
        var result = ""
        var start = 0
        while start <= b.count {
            var (end, breakLength) = nextLineBreak(b, from: start)
            if breakLength > 0, let split = lineBreakInsideCharacter(b, start: start, end: end, breakLength: breakLength, encoding: encoding),
               split.present == split.needed {
                let character = Array(b[(end - split.unfinished)..<end]) + Array(b[(end + breakLength)..<(end + breakLength + split.needed)])
                if decodes(character[...], .utf8) {
                    // Move the line break from inside the character to before it.
                    let lineBreak = Array(b[end..<(end + breakLength)])
                    let head = Array(b[(end - split.unfinished)..<end])
                    b.replaceSubrange((end - split.unfinished)..<(end + breakLength), with: lineBreak + head)
                    end -= split.unfinished
                }
            }
            result += displayLine(b[start..<end], encoding: encoding)
            if breakLength == 0 { break }
            result += breakLength == 2 ? "\r\n" : (b[end] == 0x0D ? "\r" : "\n")
            start = end + breakLength
        }
        return result
    }

    /// Unfinished lines with bytes beyond ASCII in another encoding wait for the rest; longer lines do not.
    private static let longestKeptLine = 4096

    /// The number of bytes at the end to keep for the next piece of output.
    static func lengthToKeep(_ data: Data, encoding: String.Encoding, line: Bool) -> Int {
        let b = [UInt8](data)
        let length = b.count
        if length == 0 { return 0 }
        if encoding == .utf8 && decodes(b[...], .utf8) { return 0 }
        var start = lineStart(b, end: length)
        if start > 0 {
            let breakLength = b[start - 1] == 0x0A && start >= 2 && b[start - 2] == 0x0D ? 2 : 1
            let previousEnd = start - breakLength
            let previousStart = lineStart(b, end: previousEnd)
            if let split = lineBreakInsideCharacter(b, start: previousStart, end: previousEnd, breakLength: breakLength, encoding: encoding) {
                // Keep a character TeX broke by a line break, with the break, until the rest of it has come.
                if split.present < split.needed && start + split.present == length { return split.unfinished + breakLength + split.present }
                // Once it has all come, the character is joined when the output is shown.
                if split.present == split.needed { start += split.needed }
            }
        }
        if line && encoding != .utf8 && length - start <= longestKeptLine && b[start...].contains(where: { $0 >= 0x80 }) {
            return length - start
        }
        // The start of a UTF-8 character at the end of a line that is otherwise UTF-8.
        let unfinished = unfinishedUTF8Character(b[start...]).count
        if unfinished > 0 && decodes(b[start..<(length - unfinished)], .utf8) { return unfinished }
        // The start of a character in the encoding or in UTF-8: at most three bytes.
        if decodes(b[start...], .utf8) || decodes(b[start...], encoding) { return 0 }
        var k = 1
        while k <= 3 && k <= length - start {
            if decodes(b[start..<(length - k)], encoding) { return k }
            k += 1
        }
        return unfinished
    }
}

/// Shows an unfinished line when no output comes for a while (TeXShop keeps a divided character across pauses).
final class ConsolePauseTimer {
    private let queue = DispatchQueue(label: "TeX2img.console.pause")
    private var work: DispatchWorkItem?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    func restart() {
        queue.async {
            self.work?.cancel()
            let work = DispatchWorkItem(block: self.action)
            self.work = work
            self.queue.asyncAfter(deadline: .now() + 0.3, execute: work)
        }
    }

    func cancel() {
        queue.sync {
            work?.cancel()
            work = nil
        }
    }
}
