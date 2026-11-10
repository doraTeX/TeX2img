import AppKit
import CoreFoundation
import Foundation

extension String {
    // MARK: - UTF / CID

    /// Characters outside JIS X 0208 become \UTF{xxxx}, and sequences with an Adobe-Japan1 CID become \CID{n}.
    /// A sequence without one is kept as is, except when it is written in `outputEncoding` and that encoding
    /// cannot hold it: then the glyph number of the default font is used, as before TeXShop 5.60, so that the
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
            if charRange.location == endLine {
                nsSelf.getLineStart(&startLine, end: &endLine, contentsEnd: &contentsEnd, for: charRange)
            }
            charRange = nsSelf.rangeOfComposedCharacterSequence(at: charRange.location)
            let subString = nsSelf.substring(with: charRange)

            if !subString.canBeConverted(to: iso2022jp) {
                let utfString: NSMutableString
                if charRange.length > 1 {
                    // A sequence (a surrogate pair, a variation sequence) becomes \CID{n} only when it has an
                    // Adobe-Japan1 CID; otherwise it is kept as is, unless the output encoding cannot hold it
                    // (TeXShop 5.60).
                    if let cid = Self.adobeJapan1CID(for: subString) {
                        utfString = NSMutableString(string: "\\CID{\(cid)}")
                    } else if let outputEncoding, !subString.canBeConverted(to: outputEncoding),
                              let glyph = Self.defaultFontGlyph(for: subString) {
                        utfString = NSMutableString(string: "\\CID{\(glyph)}")
                    } else {
                        newString.append(subString)
                        charRange.location += charRange.length
                        charRange.length = 1
                        continue
                    }
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
        // Only a command is converted: not an escaped backslash (\\UTF{...}), and not a surrogate code point,
        // which is not a character (TeXShop 5.60).
        let source = self as NSString
        let str = NSMutableString()
        var offset = 0
        let pattern = try! NSRegularExpression(pattern: #"\\UTF\{([0-9A-Fa-f]{4})\}"#)
        for match in pattern.matches(in: self, range: NSRange(location: 0, length: source.length)) {
            str.append(source.substring(with: NSRange(location: offset, length: match.range.location - offset)))
            let value = UInt32(source.substring(with: match.range(at: 1)), radix: 16) ?? 0xD800
            if Self.startsCommand(source, at: match.range.location), let character = Self.scalarString(value) {
                str.append(character)
            } else {
                str.append(source.substring(with: match.range))
            }
            offset = NSMaxRange(match.range)
        }
        str.append(source.substring(from: offset))

        for (cid, codePoint) in cidToUnicode {
            replaceCID(cid, codePoint: codePoint, in: str)
        }

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
        replaceSingleCharacter(in: str, source: 0x3290, destination: "\\ajKakkoYobi{1}", addingPercent: true)
        for index in 2...7 {
            replaceSingleCharacter(in: str, source: UInt32(0x328A + index - 2), destination: "\\ajKakkoYobi{\(index)}", addingPercent: true)
        }
        replaceSingleCharacter(in: str, source: 0x3297, destination: "\\ajKakkoYobi{8}", addingPercent: true)
        replaceSingleCharacter(in: str, source: 0x3297, destination: "\\ajKakkoYobi{9}", addingPercent: true)
        return str as String
    }

    func stringByReplacingAjMaruYobiWithMaruYobi() -> String {
        let str = NSMutableString(string: self)
        let firstDestination = Self.string(fromCodePoint: 0x3290)
        replaceAll(in: str, source: "\\ajKakkoYobi{1}", destination: firstDestination, addingPercent: false)
        replaceAll(in: str, source: "\\ajKakkoYobi1", destination: firstDestination, addingPercent: false)
        for index in 2...7 {
            let destination = Self.string(fromCodePoint: UInt32(0x328A + index - 2))
            replaceAll(in: str, source: "\\ajKakkoYobi{\(index)}", destination: destination, addingPercent: false)
            replaceAll(in: str, source: "\\ajKakkoYobi\(index)", destination: destination, addingPercent: false)
        }
        let eighthDestination = Self.string(fromCodePoint: 0x3297)
        replaceAll(in: str, source: "\\ajKakkoYobi{8}", destination: eighthDestination, addingPercent: false)
        replaceAll(in: str, source: "\\ajKakkoYobi8", destination: eighthDestination, addingPercent: false)
        let ninthDestination = Self.string(fromCodePoint: 0x3297)
        replaceAll(in: str, source: "\\ajKakkoYobi{9}", destination: ninthDestination, addingPercent: false)
        replaceAll(in: str, source: "\\ajKakkoYobi9", destination: ninthDestination, addingPercent: false)
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

    /// Whether the backslash at location starts a command: it follows an even number of backslashes.
    static func startsCommand(_ string: NSString, at location: Int) -> Bool {
        var count = 0
        while location - count - 1 >= 0 && string.character(at: location - count - 1) == 0x5C { count += 1 }
        return count % 2 == 0
    }

    /// The Adobe-Japan1 CID of a character sequence, or nil. Hiragino is CID-keyed Adobe-Japan1, so its glyph
    /// numbers are CIDs. A sequence that Hiragino does not draw as one glyph of its own (emoji, joined sequences,
    /// combining marks it cannot compose) has no CID; the glyph number of another font is not one (TeXShop 5.60).
    static func adobeJapan1CID(for sequence: String) -> Int? {
        guard let font = hiraginoFont, !sequence.isEmpty else { return nil }
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
        var cid: Int?
        for index in glyphs.location..<NSMaxRange(glyphs) {
            let glyph = layout.cgGlyph(at: index)
            let property = layout.propertyForGlyph(at: index)
            if property.contains(.null) || property.contains(.controlCharacter) { continue }
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

    func replaceCID(_ cid: Int, codePoint: UInt32, in string: NSMutableString) {
        guard let destination = Self.scalarString(codePoint) else { return }
        string.replaceAllOccurrences(ofString: "\\CID{\(cid)}", withString: destination, addingPercentForEndOfLine: false)
    }

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