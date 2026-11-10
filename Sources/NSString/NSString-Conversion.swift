import AppKit
import CoreFoundation
import CoreText
import Foundation

extension String {
    // MARK: - UTF / CID

    /// Characters outside JIS X 0208 become \UTF{xxxx}, and sequences with an Adobe-Japan1 CID become \CID{n}.
    /// A sequence without one is kept as is, except when it is written in `outputEncoding` and that encoding
    /// cannot hold it: then a variation sequence that Hiragino does not register is written as its base character
    /// alone, and another sequence as the glyph number of the default font, as before TeXShop 5.60, so that the
    /// file can still be written.
    func stringByReplacingUnicodeCharactersWithUTF(outputEncoding: String.Encoding? = nil) -> String {
        let nsSelf = self as NSString
        let iso2022jp = String.Encoding.iso2022JP.rawValue
        let newString = NSMutableString()
        let texChar: unichar = 0x5C
        var charRange = NSRange(location: 0, length: 1)
        var startLine = 0
        var endLine = 0
        var contentsEnd = 0

        while charRange.location < nsSelf.length {
            if charRange.location >= endLine {
                nsSelf.getLineStart(&startLine, end: &endLine, contentsEnd: &contentsEnd, for: charRange)
            }
            charRange = nsSelf.rangeOfComposedCharacterSequence(at: charRange.location)
            // A line break (CR LF too), tab or other control character takes a following combining mark into its
            // sequence. The control characters are kept as they are, and the marks are converted on their own.
            if charRange.length > 1, Self.isControlOrSeparator(nsSelf.character(at: charRange.location)) {
                let end = NSMaxRange(charRange)
                var marks = charRange.location
                while marks < end && Self.isControlOrSeparator(nsSelf.character(at: marks)) { marks += 1 }
                newString.append(nsSelf.substring(with: NSRange(location: charRange.location, length: marks - charRange.location)))
                if marks == end {
                    charRange = NSRange(location: end, length: 1)
                    continue
                }
                charRange = NSRange(location: marks, length: end - marks)
                if charRange.location >= endLine {
                    nsSelf.getLineStart(&startLine, end: &endLine, contentsEnd: &contentsEnd, for: charRange)
                }
            }
            let subString = nsSelf.substring(with: charRange)

            if !subString.canBeConverted(to: iso2022jp) {
                let utfString: NSMutableString
                if charRange.length > 1 {
                    // A sequence (a surrogate pair, a variation sequence) becomes \CID{n} only when it has an
                    // Adobe-Japan1 CID; otherwise it is kept as is, unless the output encoding cannot hold it
                    // (TeXShop 5.60).
                    var command: String?
                    if let cid = Self.adobeJapan1CID(for: subString) {
                        command = "\\CID{\(cid)}"
                    } else if let outputEncoding, !subString.canBeConverted(to: outputEncoding) {
                        if let base = Self.baseOfVariationSequence(subString) {
                            // Hiragino does not register this variation sequence, and the encoding cannot keep the
                            // selector: the base character alone is written, and pTeX's font draws it (TeXShop 5.60).
                            if base.canBeConverted(to: iso2022jp) {
                                // An ordinary character: no command, so no "%" at the line end.
                                newString.append(base)
                                charRange.location += charRange.length
                                charRange.length = 1
                                continue
                            } else if (base as NSString).length == 1 {
                                command = String(format: "%CUTF{%04X}", texChar, (base as NSString).character(at: 0))
                            } else if let cid = Self.adobeJapan1CID(for: base) {
                                command = "\\CID{\(cid)}"
                            }
                        }
                        if command == nil, let glyph = Self.defaultFontGlyph(for: subString) {
                            command = "\\CID{\(glyph)}"
                        }
                    }
                    guard let command else {
                        newString.append(subString)
                        charRange.location += charRange.length
                        charRange.length = 1
                        continue
                    }
                    utfString = NSMutableString(string: command)
                } else if subString.character(at: 0) == 0x2015 {
                    utfString = NSMutableString(format: "%C", 0x2014)
                } else {
                    utfString = NSMutableString(format: "%CUTF{%04X}", texChar, subString.character(at: 0))
                }

                if charRange.location + charRange.length == contentsEnd, charRange.location + charRange.length < nsSelf.length {
                    utfString.append("%")
                }
                newString.append(utfString as String)
            } else {
                newString.append(subString)
            }

            charRange.location += charRange.length
            charRange.length = 1
        }

        return newString as String
    }

    func stringByReplacingUTFWithUnicodeCharacters() -> String {
        // One pass over the original text for both commands, as TeXShop does: what a replacement gives is not read
        // again, and a command after an escaped backslash (\\UTF{...}, \\CID{...}) is left as it is. A surrogate
        // code point is not a character, and an unknown CID has no character (TeXShop 5.60).
        let source = self as NSString
        let str = NSMutableString()
        var offset = 0
        let pattern = try! NSRegularExpression(pattern: #"\\(?:UTF\{([0-9A-Fa-f]{4})\}|CID\{([0-9]+)\})"#)
        for match in pattern.matches(in: self, range: NSRange(location: 0, length: source.length)) {
            str.append(source.substring(with: NSRange(location: offset, length: match.range.location - offset)))
            var character: String?
            if Self.startsCommand(source, at: match.range.location) {
                if match.range(at: 1).location != NSNotFound {
                    character = UInt32(source.substring(with: match.range(at: 1)), radix: 16).flatMap(Self.scalarString)
                } else if let cid = Int(source.substring(with: match.range(at: 2))), let codePoint = cidToUnicode[cid] {
                    character = Self.scalarString(codePoint)
                }
            }
            str.append(character ?? source.substring(with: match.range))
            offset = NSMaxRange(match.range)
        }
        str.append(source.substring(from: offset))
        return str as String
    }

    // MARK: - Hiragana / Katakana

    func stringByReplacingHiraganaWithKatakana() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0x3040, destinationOffset: 0x30A0, range: 0x0001...0x0056, addingPercent: false)
        return str as String
    }

    func stringByReplacingKatakanaWithHiragana() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0x30A0, destinationOffset: 0x3040, range: 0x0001...0x0056, addingPercent: false)
        return str as String
    }

    // MARK: - Digits

    func stringByReplacingHalfwidthDigitsWithFullwidthDigits() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0x0030, destinationOffset: 0xFF10, range: 0...9, addingPercent: false)
        return str as String
    }

    func stringByReplacingFullwidthDigitsWithHalfwidthDigits() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0xFF10, destinationOffset: 0x0030, range: 0...9, addingPercent: true)
        return str as String
    }

    // MARK: - Alphabets

    func stringByReplacingHalfwidthAlphabetsWithFullwidthAlphabets() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0x0040, destinationOffset: 0xFF20, range: 1...26, addingPercent: false)
        replaceMappedCharacters(in: str, offset: 0x0060, destinationOffset: 0xFF40, range: 1...26, addingPercent: false)
        return str as String
    }

    func stringByReplacingFullwidthAlphabetsWithHalfwidthAlphabets() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0xFF20, destinationOffset: 0x0040, range: 1...26, addingPercent: true)
        replaceMappedCharacters(in: str, offset: 0xFF40, destinationOffset: 0x0060, range: 1...26, addingPercent: true)
        return str as String
    }

    // MARK: - ajmacros (aggregate)

    func stringByReplacingUnicodeCharactersWithAjMacros() -> String {
        return stringByReplacingMaruSujiWithAjMaru()
            .stringByReplacingKuroMaruSujiWithAjKuroMaru()
            .stringByReplacingKakkoSujiWithAjKakko()
            .stringByReplacingMaruAlphWithAjMaruAlph()
            .stringByReplacingKakkoAlphWithAjKakkoAlph()
            .stringByReplacingKuroMaruAlphWithAjKuroMaruAlph()
            .stringByReplacingKakuAlphWithAjKakuAlph()
            .stringByReplacingKuroKakuAlphWithAjKuroKakuAlph()
            .stringByReplacingRomanWithAjRoman()
            .stringByReplacingPeriodWithAjPeriod()
            .stringByReplacingKakkoYobiWithAjKakkoYobi()
            .stringByReplacingMaruYobiWithAjMaruYobi()
            .stringByReplacingNijuMaruWithAjNijuMaru()
            .stringByReplacingRecycleWithAjRecycle()
            .stringByReplacingMaruKataWithAjMaruKata()
            .stringByReplacingKakkoKansujiWithAjKakkoKansuji()
            .stringByReplacingMaruKansujiWithAjMaruKansuji()
            .stringByReplacingLigWithAjLig()
    }

    func stringByReplacingAjMacrosWithUnicodeCharacters() -> String {
        return stringByReplacingAjMaruWithMaruSuji()
            .stringByReplacingAjKuroMaruWithKuroMaruSuji()
            .stringByReplacingAjKakkoWithMakkoSuji()
            .stringByReplacingAjMaruAlphWithMaruAlph()
            .stringByReplacingAjKakkoAlphWithKakkoAlph()
            .stringByReplacingAjKuroMaruAlphWithKuroMaruAlph()
            .stringByReplacingAjKakuAlphWithKakuAlph()
            .stringByReplacingAjKuroKakuAlphWithKuroKakuAlph()
            .stringByReplacingAjRomanWithRoman()
            .stringByReplacingAjPeriodWithPeriod()
            .stringByReplacingAjKakkoYobiWithKakkoYobi()
            .stringByReplacingAjMaruYobiWithMaruYobi()
            .stringByReplacingAjNijuMaruWithNijuMaru()
            .stringByReplacingAjRecycleWithRecycle()
            .stringByReplacingAjMaruKataWithMaruKata()
            .stringByReplacingAjKakkoKansujiWithKakkoKansuji()
            .stringByReplacingAjMaruKansujiWithMaruKansuji()
            .stringByReplacingAjLigWithLig()
    }

    // MARK: - ajMaru

    func stringByReplacingMaruSujiWithAjMaru() -> String {
        let str = NSMutableString(string: self)
        replaceSingleCharacter(in: str, source: 0x24EA, destination: "\\ajMaru{0}", addingPercent: true)
        for index in 1...20 {
            replaceSingleCharacter(in: str, source: UInt32(0x2460 + index - 1), destination: "\\ajMaru{\(index)}", addingPercent: true)
        }
        for index in 21...35 {
            replaceSingleCharacter(in: str, source: UInt32(0x3251 + index - 21), destination: "\\ajMaru{\(index)}", addingPercent: true)
        }
        for index in 36...50 {
            replaceSingleCharacter(in: str, source: UInt32(0x32B1 + index - 36), destination: "\\ajMaru{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjMaruWithMaruSuji() -> String {
        let str = NSMutableString(string: self)
        replaceAll(in: str, source: "\\ajMaru{0}", destination: Self.string(fromCodePoint: 0x24EA), addingPercent: false)
        replaceAll(in: str, source: "\\ajMaru0", destination: Self.string(fromCodePoint: 0x24EA), addingPercent: false)
        for index in 1...20 {
            let destination = Self.string(fromCodePoint: UInt32(0x2460 + index - 1))
            replaceAll(in: str, source: "\\ajMaru{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x2460 + index - 1))
            replaceAll(in: str, source: "\\ajMaru\(index)", destination: destination, addingPercent: false)
        }
        for index in 21...35 {
            let destination = Self.string(fromCodePoint: UInt32(0x3251 + index - 21))
            replaceAll(in: str, source: "\\ajMaru{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 36...50 {
            let destination = Self.string(fromCodePoint: UInt32(0x32B1 + index - 36))
            replaceAll(in: str, source: "\\ajMaru{\(index)}", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajKuroMaru

    func stringByReplacingKuroMaruSujiWithAjKuroMaru() -> String {
        let str = NSMutableString(string: self)
        replaceSingleCharacter(in: str, source: 0x24FF, destination: "\\ajKuroMaru{0}", addingPercent: true)
        for index in 1...10 {
            replaceSingleCharacter(in: str, source: UInt32(0x2776 + index - 1), destination: "\\ajKuroMaru{\(index)}", addingPercent: true)
        }
        for index in 11...20 {
            replaceSingleCharacter(in: str, source: UInt32(0x24EB + index - 11), destination: "\\ajKuroMaru{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjKuroMaruWithKuroMaruSuji() -> String {
        let str = NSMutableString(string: self)
        replaceAll(in: str, source: "\\ajKuroMaru{0}", destination: Self.string(fromCodePoint: 0x24FF), addingPercent: false)
        replaceAll(in: str, source: "\\ajKuroMaru0", destination: Self.string(fromCodePoint: 0x24FF), addingPercent: false)
        for index in 1...10 {
            let destination = Self.string(fromCodePoint: UInt32(0x2776 + index - 1))
            replaceAll(in: str, source: "\\ajKuroMaru{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x2776 + index - 1))
            replaceAll(in: str, source: "\\ajKuroMaru\(index)", destination: destination, addingPercent: false)
        }
        for index in 11...20 {
            let destination = Self.string(fromCodePoint: UInt32(0x24EB + index - 11))
            replaceAll(in: str, source: "\\ajKuroMaru{\(index)}", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajKakko

    func stringByReplacingKakkoSujiWithAjKakko() -> String {
        let str = NSMutableString(string: self)
        for index in 1...20 {
            replaceSingleCharacter(in: str, source: UInt32(0x2474 + index - 1), destination: "\\ajKakko{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjKakkoWithMakkoSuji() -> String {
        let str = NSMutableString(string: self)
        for index in 1...20 {
            let destination = Self.string(fromCodePoint: UInt32(0x2474 + index - 1))
            replaceAll(in: str, source: "\\ajKakko{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x2474 + index - 1))
            replaceAll(in: str, source: "\\ajKakko\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajMaruAlph / ajMarualph

    func stringByReplacingMaruAlphWithAjMaruAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            replaceSingleCharacter(in: str, source: UInt32(0x24B6 + index - 1), destination: "\\ajMaruAlph{\(index)}", addingPercent: true)
        }
        for index in 1...26 {
            replaceSingleCharacter(in: str, source: UInt32(0x24D0 + index - 1), destination: "\\ajMarualph{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjMaruAlphWithMaruAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let destination = Self.string(fromCodePoint: UInt32(0x24B6 + index - 1))
            replaceAll(in: str, source: "\\ajMaruAlph{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x24B6 + index - 1))
            replaceAll(in: str, source: "\\ajMaruAlph\(index)", destination: destination, addingPercent: false)
        }
        for index in 1...26 {
            let destination = Self.string(fromCodePoint: UInt32(0x24D0 + index - 1))
            replaceAll(in: str, source: "\\ajMarualph{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x24D0 + index - 1))
            replaceAll(in: str, source: "\\ajMarualph\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajKakkoAlph / ajKakkoalph

    func stringByReplacingKakkoAlphWithAjKakkoAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let source = Self.string(fromCodePoint: UInt32(0x1F110 + index - 1))
            replaceAll(in: str, source: source, destination: "\\ajKakkoAlph{\(index)}", addingPercent: true)
        }
        for index in 1...26 {
            replaceSingleCharacter(in: str, source: UInt32(0x249C + index - 1), destination: "\\ajKakkoalph{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjKakkoAlphWithKakkoAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let destination = Self.string(fromCodePoint: UInt32(0x1F110 + index - 1))
            replaceAll(in: str, source: "\\ajKakkoAlph{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x1F110 + index - 1))
            replaceAll(in: str, source: "\\ajKakkoAlph\(index)", destination: destination, addingPercent: false)
        }
        for index in 1...26 {
            let destination = Self.string(fromCodePoint: UInt32(0x249C + index - 1))
            replaceAll(in: str, source: "\\ajKakkoalph{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x249C + index - 1))
            replaceAll(in: str, source: "\\ajKakkoalph\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajKuroMaruAlph

    func stringByReplacingKuroMaruAlphWithAjKuroMaruAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let source = Self.string(fromCodePoint: UInt32(0x1F150 + index - 1))
            replaceAll(in: str, source: source, destination: "\\ajKuroMaruAlph{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjKuroMaruAlphWithKuroMaruAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let destination = Self.string(fromCodePoint: UInt32(0x1F150 + index - 1))
            replaceAll(in: str, source: "\\ajKuroMaruAlph{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x1F150 + index - 1))
            replaceAll(in: str, source: "\\ajKuroMaruAlph\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajKakuAlph

    func stringByReplacingKakuAlphWithAjKakuAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let source = Self.string(fromCodePoint: UInt32(0x1F130 + index - 1))
            replaceAll(in: str, source: source, destination: "\\ajKakuAlph{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjKakuAlphWithKakuAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let destination = Self.string(fromCodePoint: UInt32(0x1F130 + index - 1))
            replaceAll(in: str, source: "\\ajKakuAlph{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x1F130 + index - 1))
            replaceAll(in: str, source: "\\ajKakuAlph\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajKuroKakuAlph

    func stringByReplacingKuroKakuAlphWithAjKuroKakuAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let source = Self.string(fromCodePoint: UInt32(0x1F170 + index - 1))
            replaceAll(in: str, source: source, destination: "\\ajKuroKakuAlph{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjKuroKakuAlphWithKuroKakuAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let destination = Self.string(fromCodePoint: UInt32(0x1F170 + index - 1))
            replaceAll(in: str, source: "\\ajKuroKakuAlph{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x1F170 + index - 1))
            replaceAll(in: str, source: "\\ajKuroKakuAlph\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajRoman / ajroman

    func stringByReplacingRomanWithAjRoman() -> String {
        let str = NSMutableString(string: self)
        for index in 1...12 {
            replaceSingleCharacter(in: str, source: UInt32(0x2160 + index - 1), destination: "\\ajRoman{\(index)}", addingPercent: true)
        }
        for index in 1...12 {
            replaceSingleCharacter(in: str, source: UInt32(0x2170 + index - 1), destination: "\\ajroman{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjRomanWithRoman() -> String {
        let str = NSMutableString(string: self)
        for index in 1...12 {
            let destination = Self.string(fromCodePoint: UInt32(0x2160 + index - 1))
            replaceAll(in: str, source: "\\ajRoman{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x2160 + index - 1))
            replaceAll(in: str, source: "\\ajRoman\(index)", destination: destination, addingPercent: false)
        }
        for index in 1...12 {
            let destination = Self.string(fromCodePoint: UInt32(0x2170 + index - 1))
            replaceAll(in: str, source: "\\ajroman{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x2170 + index - 1))
            replaceAll(in: str, source: "\\ajroman\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajPeriod

    func stringByReplacingPeriodWithAjPeriod() -> String {
        let str = NSMutableString(string: self)
        for index in 1...9 {
            replaceSingleCharacter(in: str, source: UInt32(0x2488 + index - 1), destination: "\\ajPeriod{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjPeriodWithPeriod() -> String {
        let str = NSMutableString(string: self)
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x2488 + index - 1))
            replaceAll(in: str, source: "\\ajPeriod{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x2488 + index - 1))
            replaceAll(in: str, source: "\\ajPeriod\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajKakkoYobi

    func stringByReplacingKakkoYobiWithAjKakkoYobi() -> String {
        let str = NSMutableString(string: self)
        replaceSingleCharacter(in: str, source: 0x3230, destination: "\\ajKakkoYobi{1}", addingPercent: true)
        for index in 2...7 {
            replaceSingleCharacter(in: str, source: UInt32(0x322A + index - 2), destination: "\\ajKakkoYobi{\(index)}", addingPercent: true)
        }
        replaceSingleCharacter(in: str, source: 0x3237, destination: "\\ajKakkoYobi{8}", addingPercent: true)
        replaceSingleCharacter(in: str, source: 0x3241, destination: "\\ajKakkoYobi{9}", addingPercent: true)
        return str as String
    }

    func stringByReplacingAjKakkoYobiWithKakkoYobi() -> String {
        let str = NSMutableString(string: self)
        let firstDestination = Self.string(fromCodePoint: 0x3230)
        replaceAll(in: str, source: "\\ajKakkoYobi{1}", destination: firstDestination, addingPercent: false)
        replaceAll(in: str, source: "\\ajKakkoYobi1", destination: firstDestination, addingPercent: false)
        for index in 2...7 {
            let destination = Self.string(fromCodePoint: UInt32(0x322A + index - 2))
            replaceAll(in: str, source: "\\ajKakkoYobi{\(index)}", destination: destination, addingPercent: false)
            replaceAll(in: str, source: "\\ajKakkoYobi\(index)", destination: destination, addingPercent: false)
        }
        let eighthDestination = Self.string(fromCodePoint: 0x3237)
        replaceAll(in: str, source: "\\ajKakkoYobi{8}", destination: eighthDestination, addingPercent: false)
        replaceAll(in: str, source: "\\ajKakkoYobi8", destination: eighthDestination, addingPercent: false)
        let ninthDestination = Self.string(fromCodePoint: 0x3241)
        replaceAll(in: str, source: "\\ajKakkoYobi{9}", destination: ninthDestination, addingPercent: false)
        replaceAll(in: str, source: "\\ajKakkoYobi9", destination: ninthDestination, addingPercent: false)
        return str as String
    }

    // MARK: - ajMaruYobi

    func stringByReplacingMaruYobiWithAjMaruYobi() -> String {
        let str = NSMutableString(string: self)
        replaceSingleCharacter(in: str, source: 0x3290, destination: "\\ajMaruYobi{1}", addingPercent: true)
        for index in 2...7 {
            replaceSingleCharacter(in: str, source: UInt32(0x328A + index - 2), destination: "\\ajMaruYobi{\(index)}", addingPercent: true)
        }
        replaceSingleCharacter(in: str, source: 0x3297, destination: "\\ajMaruYobi{8}", addingPercent: true)
        replaceSingleCharacter(in: str, source: 0x32A1, destination: "\\ajMaruYobi{9}", addingPercent: true)
        return str as String
    }

    func stringByReplacingAjMaruYobiWithMaruYobi() -> String {
        let str = NSMutableString(string: self)
        let firstDestination = Self.string(fromCodePoint: 0x3290)
        replaceAll(in: str, source: "\\ajMaruYobi{1}", destination: firstDestination, addingPercent: false)
        replaceAll(in: str, source: "\\ajMaruYobi1", destination: firstDestination, addingPercent: false)
        for index in 2...7 {
            let destination = Self.string(fromCodePoint: UInt32(0x328A + index - 2))
            replaceAll(in: str, source: "\\ajMaruYobi{\(index)}", destination: destination, addingPercent: false)
            replaceAll(in: str, source: "\\ajMaruYobi\(index)", destination: destination, addingPercent: false)
        }
        let eighthDestination = Self.string(fromCodePoint: 0x3297)
        replaceAll(in: str, source: "\\ajMaruYobi{8}", destination: eighthDestination, addingPercent: false)
        replaceAll(in: str, source: "\\ajMaruYobi8", destination: eighthDestination, addingPercent: false)
        let ninthDestination = Self.string(fromCodePoint: 0x32A1)
        replaceAll(in: str, source: "\\ajMaruYobi{9}", destination: ninthDestination, addingPercent: false)
        replaceAll(in: str, source: "\\ajMaruYobi9", destination: ninthDestination, addingPercent: false)
        return str as String
    }

    // MARK: - ajNijuMaru

    func stringByReplacingNijuMaruWithAjNijuMaru() -> String {
        let str = NSMutableString(string: self)
        for index in 1...10 {
            replaceSingleCharacter(in: str, source: UInt32(0x24F5 + index - 1), destination: "\\ajNijuMaru{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjNijuMaruWithNijuMaru() -> String {
        let str = NSMutableString(string: self)
        for index in 1...10 {
            let destination = Self.string(fromCodePoint: UInt32(0x24F5 + index - 1))
            replaceAll(in: str, source: "\\ajNijuMaru{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x24F5 + index - 1))
            replaceAll(in: str, source: "\\ajNijuMaru\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajRecycle

    func stringByReplacingRecycleWithAjRecycle() -> String {
        let str = NSMutableString(string: self)
        for index in 0...11 {
            replaceSingleCharacter(in: str, source: UInt32(0x2672 + index), destination: "\\ajRecycle{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjRecycleWithRecycle() -> String {
        let str = NSMutableString(string: self)
        for index in 0...11 {
            let destination = Self.string(fromCodePoint: UInt32(0x2672 + index))
            replaceAll(in: str, source: "\\ajRecycle{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 0...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x2672 + index))
            replaceAll(in: str, source: "\\ajRecycle\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajMaruKata

    func stringByReplacingMaruKataWithAjMaruKata() -> String {
        let str = NSMutableString(string: self)
        for index in 1...47 {
            replaceSingleCharacter(in: str, source: UInt32(0x32D0 + index - 1), destination: "\\ajMaruKata{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjMaruKataWithMaruKata() -> String {
        let str = NSMutableString(string: self)
        for index in 1...47 {
            let destination = Self.string(fromCodePoint: UInt32(0x32D0 + index - 1))
            replaceAll(in: str, source: "\\ajMaruKata{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x32D0 + index - 1))
            replaceAll(in: str, source: "\\ajMaruKata\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajKakkoKansuji

    func stringByReplacingKakkoKansujiWithAjKakkoKansuji() -> String {
        let str = NSMutableString(string: self)
        for index in 1...10 {
            replaceSingleCharacter(in: str, source: UInt32(0x3220 + index - 1), destination: "\\ajKakkoKansuji{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjKakkoKansujiWithKakkoKansuji() -> String {
        let str = NSMutableString(string: self)
        for index in 1...10 {
            let destination = Self.string(fromCodePoint: UInt32(0x3220 + index - 1))
            replaceAll(in: str, source: "\\ajKakkoKansuji{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x3220 + index - 1))
            replaceAll(in: str, source: "\\ajKakkoKansuji\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajMaruKansuji

    func stringByReplacingMaruKansujiWithAjMaruKansuji() -> String {
        let str = NSMutableString(string: self)
        for index in 1...10 {
            replaceSingleCharacter(in: str, source: UInt32(0x3280 + index - 1), destination: "\\ajMaruKansuji{\(index)}", addingPercent: true)
        }
        return str as String
    }

    func stringByReplacingAjMaruKansujiWithMaruKansuji() -> String {
        let str = NSMutableString(string: self)
        for index in 1...10 {
            let destination = Self.string(fromCodePoint: UInt32(0x3280 + index - 1))
            replaceAll(in: str, source: "\\ajMaruKansuji{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: UInt32(0x3280 + index - 1))
            replaceAll(in: str, source: "\\ajMaruKansuji\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajLig

    func stringByReplacingLigWithAjLig() -> String {
        let str = NSMutableString(string: self)
        for (source, destination, addingPercent) in ligToAjLigStringReplacements {
            replaceAll(in: str, source: source, destination: destination, addingPercent: addingPercent)
        }
        return str as String
    }

    func stringByReplacingAjLigWithLig() -> String {
        let str = NSMutableString(string: self)
        for (source, destination, addingPercent) in ajLigToLigStringReplacements {
            replaceAll(in: str, source: source, destination: destination, addingPercent: addingPercent)
        }
        for (pattern, destination) in ajLigToLigPatternReplacements {
            str.replaceAllOccurrences(ofPattern: pattern, withString: destination)
        }
        return str as String
    }

    // MARK: - Quotes

    func stringByReplacingFullwidthQuotesWithHalfwidthQuotes() -> String {
        let str = NSMutableString(string: self)
        replaceAll(in: str, source: "\u{2018}\u{201C}", destination: "`\\,``", addingPercent: false)
        replaceAll(in: str, source: "\u{201D}\u{2019}", destination: "''\\,'", addingPercent: false)
        replaceAll(in: str, source: "\u{201C}\u{2018}", destination: "``\\,`", addingPercent: false)
        replaceAll(in: str, source: "\u{2019}\u{201D}", destination: "'\\,''", addingPercent: false)
        replaceAll(in: str, source: "\u{2018}", destination: "`", addingPercent: false)
        replaceAll(in: str, source: "\u{2019}", destination: "'", addingPercent: false)
        replaceAll(in: str, source: "\u{201C}", destination: "``", addingPercent: false)
        replaceAll(in: str, source: "\u{201D}", destination: "''", addingPercent: false)
        return str as String
    }
}

// MARK: - Helpers

private extension String {
    /// The character of a Unicode scalar value; nil for surrogate code points and values beyond U+10FFFF.
    static func scalarString(_ codePoint: UInt32) -> String? {
        UnicodeScalar(codePoint).map { String($0) }
    }

    /// The character of a code point in the conversion tables, which are all Unicode scalars.
    static func string(fromCodePoint codePoint: UInt32) -> String {
        scalarString(codePoint) ?? ""
    }

    /// A control character or a line or paragraph separator.
    static func isControlOrSeparator(_ unit: unichar) -> Bool {
        unit < 0x20 || (0x7F...0x9F).contains(unit) || unit == 0x2028 || unit == 0x2029
    }

    /// Whether the backslash at location starts a command: it follows an even number of backslashes.
    static func startsCommand(_ string: NSString, at location: Int) -> Bool {
        var count = 0
        while location - count - 1 >= 0 && string.character(at: location - count - 1) == 0x5C { count += 1 }
        return count % 2 == 0
    }

    static func isVariationSelector(_ value: UInt32) -> Bool {
        (0xFE00...0xFE0F).contains(value) || (0xE0100...0xE01EF).contains(value)
    }

    /// The base of a sequence made of one character and one variation selector, or nil.
    static func baseOfVariationSequence(_ sequence: String) -> String? {
        let scalars = Array(sequence.unicodeScalars)
        guard scalars.count == 2, !isVariationSelector(scalars[0].value), isVariationSelector(scalars[1].value) else { return nil }
        return String(scalars[0])
    }

    /// The bytes of the cmap table of Hiragino, read once.
    static let hiraginoCmap: [UInt8] = hiraginoFont.flatMap {
        (CTFontCopyTable($0 as CTFont, CTFontTableTag(kCTFontTableCmap), []) as Data?).map { [UInt8]($0) }
    } ?? []

    /// The glyph that the format 14 cmap subtable of Hiragino registers for base + selector: a non-default UVS
    /// glyph, `fallback` for a default UVS, or nil when the font does not register the sequence (the text system
    /// would then ignore the selector).
    static func variationGlyph(base: UInt32, selector: UInt32, fallback: Int?) -> Int? {
        let bytes = hiraginoCmap
        let n = bytes.count
        func u16(_ o: Int) -> UInt32 { o + 2 <= n ? UInt32(bytes[o]) << 8 | UInt32(bytes[o + 1]) : 0 }
        func u24(_ o: Int) -> UInt32 { o + 3 <= n ? UInt32(bytes[o]) << 16 | UInt32(bytes[o + 1]) << 8 | UInt32(bytes[o + 2]) : 0 }
        func u32(_ o: Int) -> UInt32 { o + 4 <= n ? UInt32(bytes[o]) << 24 | UInt32(bytes[o + 1]) << 16 | UInt32(bytes[o + 2]) << 8 | UInt32(bytes[o + 3]) : 0 }
        guard n >= 4 else { return nil }
        var subtable = 0
        for i in 0..<Int(u16(2)) {
            let record = 4 + 8 * i
            if u16(record) == 0 && u16(record + 2) == 5 { subtable = Int(u32(record + 4)); break }
        }
        guard subtable != 0, u16(subtable) == 14 else { return nil }
        for i in 0..<Int(u32(subtable + 6)) {
            let record = subtable + 10 + 11 * i
            guard u24(record) == selector else { continue }
            let defaults = Int(u32(record + 3)), nondefaults = Int(u32(record + 7))
            if defaults != 0 {
                let table = subtable + defaults
                for r in 0..<Int(u32(table)) {
                    let first = u24(table + 4 + 4 * r)
                    let extra = table + 4 + 4 * r + 3 < n ? UInt32(bytes[table + 4 + 4 * r + 3]) : 0
                    if base >= first && base <= first + extra { return fallback }
                }
            }
            if nondefaults != 0 {
                let table = subtable + nondefaults
                for m in 0..<Int(u32(table)) where u24(table + 4 + 5 * m) == base {
                    return Int(u16(table + 4 + 5 * m + 3))
                }
            }
            return nil
        }
        return nil
    }

    /// The Adobe-Japan1 CID of a character sequence, or nil. Hiragino is CID-keyed Adobe-Japan1, so its glyph
    /// numbers are CIDs. A sequence has a CID when Hiragino draws it as one glyph of its own: a variation sequence
    /// only when the font registers it, other sequences only when they become one glyph without help from another
    /// font and without leaving out characters other than combining marks. The glyph number of another font
    /// (emoji, joined sequences) is not a CID (TeXShop 5.60).
    static func adobeJapan1CID(for sequence: String) -> Int? {
        guard let font = hiraginoFont, !sequence.isEmpty else { return nil }
        let scalars = Array(sequence.unicodeScalars)
        if scalars.contains(where: { isVariationSelector($0.value) }) {
            guard let base = baseOfVariationSequence(sequence) else { return nil }
            var baseCID = adobeJapan1CID(for: base)
            if baseCID == nil, (base as NSString).length == 1 {
                // A BMP base drawn by Hiragino on its own: its glyph is its CID.
                var character = (base as NSString).character(at: 0)
                var glyph: CGGlyph = 0
                if CTFontGetGlyphsForCharacters(font as CTFont, &character, &glyph, 1), glyph != 0 { baseCID = Int(glyph) }
            }
            let cid = variationGlyph(base: scalars[0].value, selector: scalars[1].value, fallback: baseCID)
            return cid == 0 ? nil : cid
        }
        let length = (sequence as NSString).length
        let storage = NSTextStorage(string: sequence, attributes: [.font: font])
        let layout = NSLayoutManager()
        let container = NSTextContainer(size: NSSize(width: 1000, height: 1000))
        layout.addTextContainer(container)
        storage.addLayoutManager(layout)
        layout.ensureLayout(forCharacterRange: NSRange(location: 0, length: length))
        storage.fixAttributes(in: NSRange(location: 0, length: length))
        var run = NSRange()
        let used = storage.attribute(.font, at: 0, effectiveRange: &run) as? NSFont
        guard used?.fontName == font.fontName, run.length >= length else { return nil }
        let glyphs = layout.glyphRange(forCharacterRange: NSRange(location: 0, length: length), actualCharacterRange: nil)
        let marks = CharacterSet.nonBaseCharacters as NSCharacterSet
        var cid: Int?
        for index in glyphs.location..<NSMaxRange(glyphs) {
            let glyph = layout.cgGlyph(at: index)
            let property = layout.propertyForGlyph(at: index)
            if glyph == 0 || property.contains(.null) || property.contains(.controlCharacter) {
                // Only the second half of a surrogate pair, or a combining mark composed into the preceding glyph,
                // may be left out.
                let character = (sequence as NSString).character(at: layout.characterIndexForGlyph(at: index))
                if !CFStringIsSurrogateLowCharacter(character) && !marks.characterIsMember(character) { return nil }
                continue
            }
            if cid != nil { return nil } // more than one glyph
            cid = Int(glyph)
        }
        return cid == 0 ? nil : cid
    }

    /// The glyph number that the default font of a text view gives to the first character of a sequence:
    /// what \UTF output wrote for every sequence before TeXShop 5.60. It is not a CID in general.
    static func defaultFontGlyph(for sequence: String) -> Int? {
        let length = (sequence as NSString).length
        guard length > 0 else { return nil }
        let storage = NSTextStorage(string: sequence)
        let layout = NSLayoutManager()
        layout.addTextContainer(NSTextContainer(size: NSSize(width: 1000, height: 1000)))
        storage.addLayoutManager(layout)
        guard layout.numberOfGlyphs > 0 else { return nil }
        return Int(layout.cgGlyph(at: layout.glyphIndexForCharacter(at: 0)))
    }

    static let hiraginoFont = NSFont(name: "HiraginoSans-W3", size: 12) ?? NSFont(name: "HiraKakuProN-W3", size: 12)

    func replaceMappedCharacters(
        in string: NSMutableString,
        offset: UInt32,
        destinationOffset: UInt32,
        range: ClosedRange<Int>,
        addingPercent: Bool
    ) {
        for index in range {
            let source = Self.string(fromCodePoint: offset + UInt32(index))
            let destination = Self.string(fromCodePoint: destinationOffset + UInt32(index))
            string.replaceAllOccurrences(ofString: source, withString: destination, addingPercentForEndOfLine: addingPercent)
        }
    }

    func replaceSingleCharacter(
        in string: NSMutableString,
        source: UInt32,
        destination: String,
        addingPercent: Bool
    ) {
        replaceAll(in: string, source: Self.string(fromCodePoint: source), destination: destination, addingPercent: addingPercent)
    }

    func replaceAll(
        in string: NSMutableString,
        source: String,
        destination: String,
        addingPercent: Bool
    ) {
        string.replaceAllOccurrences(ofString: source, withString: destination, addingPercentForEndOfLine: addingPercent)
    }
}