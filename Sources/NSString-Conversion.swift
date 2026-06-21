import AppKit
import CoreFoundation
import Foundation

@objc extension NSString {
    // MARK: - UTF / CID

    @objc func stringByReplacingUnicodeCharactersWithUTF() -> String {
        let iso2022jp = String.Encoding.iso2022JP.rawValue
        let newString = NSMutableString()
        let texChar: unichar = 0x5C
        var charRange = NSRange(location: 0, length: 1)
        var startLine = 0
        var endLine = 0
        var contentsEnd = 0

        while charRange.location < length {
            if charRange.location == endLine {
                getLineStart(&startLine, end: &endLine, contentsEnd: &contentsEnd, for: charRange)
            }
            charRange = rangeOfComposedCharacterSequence(at: charRange.location)
            let subString = substring(with: charRange)

            if !(subString as NSString).canBeConverted(to: iso2022jp) {
                let textView = NSTextView()
                textView.textStorage?.setAttributedString(NSAttributedString(string: subString))

                var effectiveRange = NSRange()
                let glyph = textView.textStorage?.attribute(.glyphInfo, at: 0, effectiveRange: &effectiveRange) as? NSGlyphInfo

                let utfString: NSMutableString
                if let glyph {
                    utfString = NSMutableString(format: "%CID{%ld}", texChar, glyph.characterIdentifier)
                } else if charRange.length > 1, let layout = textView.layoutManager {
                    utfString = NSMutableString(format: "%CID{%d}", texChar, layout.glyph(at: 0))
                } else if (subString as NSString).character(at: 0) == 0x2015 {
                    utfString = NSMutableString(format: "%C", 0x2014)
                } else {
                    utfString = NSMutableString(format: "%CUTF{%04X}", texChar, (subString as NSString).character(at: 0))
                }

                if charRange.location + charRange.length == contentsEnd, charRange.location + charRange.length < length {
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

    @objc func stringByReplacingUTFWithUnicodeCharacters() -> String {
        let str = NSMutableString(string: self)

        str.replaceAllOccurrences(ofPattern: #"\\UTF\{([0-9A-Fa-z]{4})\}"#) { match, groups in
            let hex = groups[0]
            guard hex.count == 4,
                  let high = UInt8(hex.prefix(2), radix: 16),
                  let low = UInt8(hex.suffix(2), radix: 16) else { return match }
            let codePoint = UInt32(high) * 256 + UInt32(low)
            return Self.string(fromCodePoint: codePoint)
        }

        for (cid, codePoint) in cidToUnicode {
            replaceCID(cid, codePoint: codePoint, in: str)
        }

        return str as String
    }

    // MARK: - Hiragana / Katakana

    @objc func stringByReplacingHiraganaWithKatakana() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0x3040, destinationOffset: 0x30A0, range: 0x0001...0x0056, addingPercent: false)
        return str as String
    }

    @objc func stringByReplacingKatakanaWithHiragana() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0x30A0, destinationOffset: 0x3040, range: 0x0001...0x0056, addingPercent: false)
        return str as String
    }

    // MARK: - Digits

    @objc func stringByReplacingHalfwidthDigitsWithFullwidthDigits() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0x0030, destinationOffset: 0xFF10, range: 0...9, addingPercent: false)
        return str as String
    }

    @objc func stringByReplacingFullwidthDigitsWithHalfwidthDigits() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0xFF10, destinationOffset: 0x0030, range: 0...9, addingPercent: true)
        return str as String
    }

    // MARK: - Alphabets

    @objc func stringByReplacingHalfwidthAlphabetsWithFullwidthAlphabets() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0x0040, destinationOffset: 0xFF20, range: 1...26, addingPercent: false)
        replaceMappedCharacters(in: str, offset: 0x0060, destinationOffset: 0xFF40, range: 1...26, addingPercent: false)
        return str as String
    }

    @objc func stringByReplacingFullwidthAlphabetsWithHalfwidthAlphabets() -> String {
        let str = NSMutableString(string: self)
        replaceMappedCharacters(in: str, offset: 0xFF20, destinationOffset: 0x0040, range: 1...26, addingPercent: true)
        replaceMappedCharacters(in: str, offset: 0xFF40, destinationOffset: 0x0060, range: 1...26, addingPercent: true)
        return str as String
    }

    // MARK: - ajmacros (aggregate)

    @objc func stringByReplacingUnicodeCharactersWithAjMacros() -> String {
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

    @objc func stringByReplacingAjMacrosWithUnicodeCharacters() -> String {
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

    @objc func stringByReplacingMaruSujiWithAjMaru() -> String {
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

    @objc func stringByReplacingAjMaruWithMaruSuji() -> String {
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

    @objc func stringByReplacingKuroMaruSujiWithAjKuroMaru() -> String {
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

    @objc func stringByReplacingAjKuroMaruWithKuroMaruSuji() -> String {
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

    @objc func stringByReplacingKakkoSujiWithAjKakko() -> String {
        let str = NSMutableString(string: self)
        for index in 1...20 {
            replaceSingleCharacter(in: str, source: UInt32(0x2474 + index - 1), destination: "\\ajKakko{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjKakkoWithMakkoSuji() -> String {
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

    @objc func stringByReplacingMaruAlphWithAjMaruAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            replaceSingleCharacter(in: str, source: UInt32(0x24B6 + index - 1), destination: "\\ajMaruAlph{\(index)}", addingPercent: true)
        }
        for index in 1...26 {
            replaceSingleCharacter(in: str, source: UInt32(0x24D0 + index - 1), destination: "\\ajMarualph{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjMaruAlphWithMaruAlph() -> String {
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

    @objc func stringByReplacingKakkoAlphWithAjKakkoAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let source = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD10 + index - 1))
            replaceAll(in: str, source: source, destination: "\\ajKakkoAlph{\(index)}", addingPercent: true)
        }
        for index in 1...26 {
            replaceSingleCharacter(in: str, source: UInt32(0x249C + index - 1), destination: "\\ajKakkoalph{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjKakkoAlphWithKakkoAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let destination = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD10 + index - 1))
            replaceAll(in: str, source: "\\ajKakkoAlph{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD10 + index - 1))
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

    @objc func stringByReplacingKuroMaruAlphWithAjKuroMaruAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let source = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD50 + index - 1))
            replaceAll(in: str, source: source, destination: "\\ajKuroMaruAlph{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjKuroMaruAlphWithKuroMaruAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let destination = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD50 + index - 1))
            replaceAll(in: str, source: "\\ajKuroMaruAlph{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD50 + index - 1))
            replaceAll(in: str, source: "\\ajKuroMaruAlph\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajKakuAlph

    @objc func stringByReplacingKakuAlphWithAjKakuAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let source = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD30 + index - 1))
            replaceAll(in: str, source: source, destination: "\\ajKakuAlph{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjKakuAlphWithKakuAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let destination = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD30 + index - 1))
            replaceAll(in: str, source: "\\ajKakuAlph{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD30 + index - 1))
            replaceAll(in: str, source: "\\ajKakuAlph\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajKuroKakuAlph

    @objc func stringByReplacingKuroKakuAlphWithAjKuroKakuAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let source = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD70 + index - 1))
            replaceAll(in: str, source: source, destination: "\\ajKuroKakuAlph{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjKuroKakuAlphWithKuroKakuAlph() -> String {
        let str = NSMutableString(string: self)
        for index in 1...26 {
            let destination = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD70 + index - 1))
            replaceAll(in: str, source: "\\ajKuroKakuAlph{\(index)}", destination: destination, addingPercent: false)
        }
        for index in 1...9 {
            let destination = Self.string(fromCodePoint: 0xD83C) + Self.string(fromCodePoint: UInt32(0xDD70 + index - 1))
            replaceAll(in: str, source: "\\ajKuroKakuAlph\(index)", destination: destination, addingPercent: false)
        }
        return str as String
    }

    // MARK: - ajRoman / ajroman

    @objc func stringByReplacingRomanWithAjRoman() -> String {
        let str = NSMutableString(string: self)
        for index in 1...12 {
            replaceSingleCharacter(in: str, source: UInt32(0x2160 + index - 1), destination: "\\ajRoman{\(index)}", addingPercent: true)
        }
        for index in 1...12 {
            replaceSingleCharacter(in: str, source: UInt32(0x2170 + index - 1), destination: "\\ajroman{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjRomanWithRoman() -> String {
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

    @objc func stringByReplacingPeriodWithAjPeriod() -> String {
        let str = NSMutableString(string: self)
        for index in 1...9 {
            replaceSingleCharacter(in: str, source: UInt32(0x2488 + index - 1), destination: "\\ajPeriod{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjPeriodWithPeriod() -> String {
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

    @objc func stringByReplacingKakkoYobiWithAjKakkoYobi() -> String {
        let str = NSMutableString(string: self)
        replaceSingleCharacter(in: str, source: 0x3230, destination: "\\ajKakkoYobi{1}", addingPercent: true)
        for index in 2...7 {
            replaceSingleCharacter(in: str, source: UInt32(0x322A + index - 2), destination: "\\ajKakkoYobi{\(index)}", addingPercent: true)
        }
        replaceSingleCharacter(in: str, source: 0x3237, destination: "\\ajKakkoYobi{8}", addingPercent: true)
        replaceSingleCharacter(in: str, source: 0x3241, destination: "\\ajKakkoYobi{9}", addingPercent: true)
        return str as String
    }

    @objc func stringByReplacingAjKakkoYobiWithKakkoYobi() -> String {
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

    @objc func stringByReplacingMaruYobiWithAjMaruYobi() -> String {
        let str = NSMutableString(string: self)
        replaceSingleCharacter(in: str, source: 0x3290, destination: "\\ajKakkoYobi{1}", addingPercent: true)
        for index in 2...7 {
            replaceSingleCharacter(in: str, source: UInt32(0x328A + index - 2), destination: "\\ajKakkoYobi{\(index)}", addingPercent: true)
        }
        replaceSingleCharacter(in: str, source: 0x3297, destination: "\\ajKakkoYobi{8}", addingPercent: true)
        replaceSingleCharacter(in: str, source: 0x3297, destination: "\\ajKakkoYobi{9}", addingPercent: true)
        return str as String
    }

    @objc func stringByReplacingAjMaruYobiWithMaruYobi() -> String {
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

    @objc func stringByReplacingNijuMaruWithAjNijuMaru() -> String {
        let str = NSMutableString(string: self)
        for index in 1...10 {
            replaceSingleCharacter(in: str, source: UInt32(0x24F5 + index - 1), destination: "\\ajNijuMaru{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjNijuMaruWithNijuMaru() -> String {
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

    @objc func stringByReplacingRecycleWithAjRecycle() -> String {
        let str = NSMutableString(string: self)
        for index in 0...11 {
            replaceSingleCharacter(in: str, source: UInt32(0x2672 + index), destination: "\\ajRecycle{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjRecycleWithRecycle() -> String {
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

    @objc func stringByReplacingMaruKataWithAjMaruKata() -> String {
        let str = NSMutableString(string: self)
        for index in 1...47 {
            replaceSingleCharacter(in: str, source: UInt32(0x32D0 + index - 1), destination: "\\ajMaruKata{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjMaruKataWithMaruKata() -> String {
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

    @objc func stringByReplacingKakkoKansujiWithAjKakkoKansuji() -> String {
        let str = NSMutableString(string: self)
        for index in 1...10 {
            replaceSingleCharacter(in: str, source: UInt32(0x3220 + index - 1), destination: "\\ajKakkoKansuji{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjKakkoKansujiWithKakkoKansuji() -> String {
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

    @objc func stringByReplacingMaruKansujiWithAjMaruKansuji() -> String {
        let str = NSMutableString(string: self)
        for index in 1...10 {
            replaceSingleCharacter(in: str, source: UInt32(0x3280 + index - 1), destination: "\\ajMaruKansuji{\(index)}", addingPercent: true)
        }
        return str as String
    }

    @objc func stringByReplacingAjMaruKansujiWithMaruKansuji() -> String {
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

    @objc func stringByReplacingLigWithAjLig() -> String {
        let str = NSMutableString(string: self)
        for (source, destination, addingPercent) in ligToAjLigStringReplacements {
            replaceAll(in: str, source: source, destination: destination, addingPercent: addingPercent)
        }
        return str as String
    }

    @objc func stringByReplacingAjLigWithLig() -> String {
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

    @objc func stringByReplacingFullwidthQuotesWithHalfwidthQuotes() -> String {
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

private extension NSString {
    static func string(fromCodePoint codePoint: UInt32) -> String {
        if codePoint <= 0xFFFF, let scalar = UnicodeScalar(codePoint) {
            return String(scalar)
        }
        let value = codePoint - 0x10000
        let high = UInt32(value / 0x400 + 0xD800)
        let low = UInt32(value % 0x400 + 0xDC00)
        guard let highScalar = UnicodeScalar(high), let lowScalar = UnicodeScalar(low) else { return "" }
        return String(highScalar) + String(lowScalar)
    }

    func replaceCID(_ cid: Int, codePoint: UInt32, in string: NSMutableString) {
        let source = "\\CID{\(cid)}"
        let destination = Self.string(fromCodePoint: codePoint)
        string.replaceAllOccurrences(ofString: source, withString: destination, addingPercentForEndOfLine: false)
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