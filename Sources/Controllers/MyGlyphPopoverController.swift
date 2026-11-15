/*
 ==============================================================================
 MyGlyphPopoverController
 Created on 2015-08-10 by Yusuke Terada

 MyGlyphPopoverController is based on TSGlyphPopoverController.
 TSGlyphPopoverController is based on CEGlyphPopoverController.

 CotEditor
 http://coteditor.github.io

 Created on 2014-05-01 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------

 © 2014 CotEditor Project

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.

 ==============================================================================
 */


// As TeXShop 6.00 (after CotEditor's character inspector): one character shows the glyph, the name and a table
// of the code point, block, general category and the Unicode version that added it. A character of several code
// points lists them, each with its block and category under a disclosure triangle. A selection of several
// characters shows their number, words and lines, and their code points. The properties come from ICU.

import AppKit
import Foundation

// MARK: - Unicode blocks

/// The names of the Unicode blocks (TeXShop's TSUnicodeBlockNames).
enum UnicodeBlocks {
    /// The names of Blocks.txt of the Unicode Character Database (Unicode 17.0), as TeXShop 6.00 lists them.
    /// ICU names a block by its property value alias ("Latin_1_Supplement"), which matches one of these when spaces,
    /// hyphens, underscores and case are ignored.
    static let names: [String] = [
        "Adlam", "Aegean Numbers", "Ahom", "Alchemical Symbols", "Alphabetic Presentation Forms", "Anatolian Hieroglyphs",
        "Ancient Greek Musical Notation", "Ancient Greek Numbers", "Ancient Symbols", "Arabic", "Arabic Extended-A",
        "Arabic Extended-B", "Arabic Extended-C", "Arabic Mathematical Alphabetic Symbols", "Arabic Presentation Forms-A",
        "Arabic Presentation Forms-B", "Arabic Supplement", "Armenian", "Arrows", "Avestan", "Balinese", "Bamum",
        "Bamum Supplement", "Basic Latin", "Bassa Vah", "Batak", "Bengali", "Beria Erfe", "Bhaiksuki", "Block Elements",
        "Bopomofo", "Bopomofo Extended", "Box Drawing", "Brahmi", "Braille Patterns", "Buginese", "Buhid",
        "Byzantine Musical Symbols", "Carian", "Caucasian Albanian", "Chakma", "Cham", "Cherokee", "Cherokee Supplement",
        "Chess Symbols", "Chorasmian", "CJK Compatibility", "CJK Compatibility Forms", "CJK Compatibility Ideographs",
        "CJK Compatibility Ideographs Supplement", "CJK Radicals Supplement", "CJK Strokes", "CJK Symbols and Punctuation",
        "CJK Unified Ideographs", "CJK Unified Ideographs Extension A", "CJK Unified Ideographs Extension B",
        "CJK Unified Ideographs Extension C", "CJK Unified Ideographs Extension D", "CJK Unified Ideographs Extension E",
        "CJK Unified Ideographs Extension F", "CJK Unified Ideographs Extension G", "CJK Unified Ideographs Extension H",
        "CJK Unified Ideographs Extension I", "CJK Unified Ideographs Extension J", "Combining Diacritical Marks",
        "Combining Diacritical Marks Extended", "Combining Diacritical Marks for Symbols",
        "Combining Diacritical Marks Supplement", "Combining Half Marks", "Common Indic Number Forms", "Control Pictures",
        "Coptic", "Coptic Epact Numbers", "Counting Rod Numerals", "Cuneiform", "Cuneiform Numbers and Punctuation",
        "Currency Symbols", "Cypriot Syllabary", "Cypro-Minoan", "Cyrillic", "Cyrillic Extended-A", "Cyrillic Extended-B",
        "Cyrillic Extended-C", "Cyrillic Extended-D", "Cyrillic Supplement", "Deseret", "Devanagari", "Devanagari Extended",
        "Devanagari Extended-A", "Dingbats", "Dives Akuru", "Dogra", "Domino Tiles", "Duployan", "Early Dynastic Cuneiform",
        "Egyptian Hieroglyph Format Controls", "Egyptian Hieroglyphs", "Egyptian Hieroglyphs Extended-A", "Elbasan", "Elymaic",
        "Emoticons", "Enclosed Alphanumeric Supplement", "Enclosed Alphanumerics", "Enclosed CJK Letters and Months",
        "Enclosed Ideographic Supplement", "Ethiopic", "Ethiopic Extended", "Ethiopic Extended-A", "Ethiopic Extended-B",
        "Ethiopic Supplement", "Garay", "General Punctuation", "Geometric Shapes", "Geometric Shapes Extended", "Georgian",
        "Georgian Extended", "Georgian Supplement", "Glagolitic", "Glagolitic Supplement", "Gothic", "Grantha",
        "Greek and Coptic", "Greek Extended", "Gujarati", "Gunjala Gondi", "Gurmukhi", "Gurung Khema",
        "Halfwidth and Fullwidth Forms", "Hangul Compatibility Jamo", "Hangul Jamo", "Hangul Jamo Extended-A",
        "Hangul Jamo Extended-B", "Hangul Syllables", "Hanifi Rohingya", "Hanunoo", "Hatran", "Hebrew",
        "High Private Use Surrogates", "High Surrogates", "Hiragana", "Ideographic Description Characters",
        "Ideographic Symbols and Punctuation", "Imperial Aramaic", "Indic Siyaq Numbers", "Inscriptional Pahlavi",
        "Inscriptional Parthian", "IPA Extensions", "Javanese", "Kaithi", "Kaktovik Numerals", "Kana Extended-A",
        "Kana Extended-B", "Kana Supplement", "Kanbun", "Kangxi Radicals", "Kannada", "Katakana", "Katakana Phonetic Extensions",
        "Kawi", "Kayah Li", "Kharoshthi", "Khitan Small Script", "Khmer", "Khmer Symbols", "Khojki", "Khudawadi", "Kirat Rai",
        "Lao", "Latin Extended Additional", "Latin Extended-A", "Latin Extended-B", "Latin Extended-C", "Latin Extended-D",
        "Latin Extended-E", "Latin Extended-F", "Latin Extended-G", "Latin-1 Supplement", "Lepcha", "Letterlike Symbols",
        "Limbu", "Linear A", "Linear B Ideograms", "Linear B Syllabary", "Lisu", "Lisu Supplement", "Low Surrogates", "Lycian",
        "Lydian", "Mahajani", "Mahjong Tiles", "Makasar", "Malayalam", "Mandaic", "Manichaean", "Marchen", "Masaram Gondi",
        "Mathematical Alphanumeric Symbols", "Mathematical Operators", "Mayan Numerals", "Medefaidrin", "Meetei Mayek",
        "Meetei Mayek Extensions", "Mende Kikakui", "Meroitic Cursive", "Meroitic Hieroglyphs", "Miao",
        "Miscellaneous Mathematical Symbols-A", "Miscellaneous Mathematical Symbols-B", "Miscellaneous Symbols",
        "Miscellaneous Symbols and Arrows", "Miscellaneous Symbols and Pictographs", "Miscellaneous Symbols Supplement",
        "Miscellaneous Technical", "Modi", "Modifier Tone Letters", "Mongolian", "Mongolian Supplement", "Mro", "Multani",
        "Musical Symbols", "Myanmar", "Myanmar Extended-A", "Myanmar Extended-B", "Myanmar Extended-C", "Nabataean",
        "Nag Mundari", "Nandinagari", "New Tai Lue", "Newa", "NKo", "Number Forms", "Nushu", "Nyiakeng Puachue Hmong", "Ogham",
        "Ol Chiki", "Ol Onal", "Old Hungarian", "Old Italic", "Old North Arabian", "Old Permic", "Old Persian", "Old Sogdian",
        "Old South Arabian", "Old Turkic", "Old Uyghur", "Optical Character Recognition", "Oriya", "Ornamental Dingbats",
        "Osage", "Osmanya", "Ottoman Siyaq Numbers", "Pahawh Hmong", "Palmyrene", "Pau Cin Hau", "Phags-pa", "Phaistos Disc",
        "Phoenician", "Phonetic Extensions", "Phonetic Extensions Supplement", "Playing Cards", "Private Use Area",
        "Psalter Pahlavi", "Rejang", "Rumi Numeral Symbols", "Runic", "Samaritan", "Saurashtra", "Sharada", "Sharada Supplement",
        "Shavian", "Shorthand Format Controls", "Siddham", "Sidetic", "Sinhala", "Sinhala Archaic Numbers",
        "Small Form Variants", "Small Kana Extension", "Sogdian", "Sora Sompeng", "Soyombo", "Spacing Modifier Letters",
        "Specials", "Sundanese", "Sundanese Supplement", "Sunuwar", "Superscripts and Subscripts", "Supplemental Arrows-A",
        "Supplemental Arrows-B", "Supplemental Arrows-C", "Supplemental Mathematical Operators", "Supplemental Punctuation",
        "Supplemental Symbols and Pictographs", "Supplementary Private Use Area-A", "Supplementary Private Use Area-B",
        "Sutton SignWriting", "Syloti Nagri", "Symbols and Pictographs Extended-A", "Symbols for Legacy Computing",
        "Symbols for Legacy Computing Supplement", "Syriac", "Syriac Supplement", "Tagalog", "Tagbanwa", "Tags", "Tai Le",
        "Tai Tham", "Tai Viet", "Tai Xuan Jing Symbols", "Tai Yo", "Takri", "Tamil", "Tamil Supplement", "Tangsa", "Tangut",
        "Tangut Components", "Tangut Components Supplement", "Tangut Supplement", "Telugu", "Thaana", "Thai", "Tibetan",
        "Tifinagh", "Tirhuta", "Todhri", "Tolong Siki", "Toto", "Transport and Map Symbols", "Tulu-Tigalari", "Ugaritic",
        "Unified Canadian Aboriginal Syllabics", "Unified Canadian Aboriginal Syllabics Extended",
        "Unified Canadian Aboriginal Syllabics Extended-A", "Vai", "Variation Selectors", "Variation Selectors Supplement",
        "Vedic Extensions", "Vertical Forms", "Vithkuqi", "Wancho", "Warang Citi", "Yezidi", "Yi Radicals", "Yi Syllables",
        "Yijing Hexagram Symbols", "Zanabazar Square", "Znamenny Musical Notation"
    ]

    static let characterViewerTable = "/System/Library/Input Methods/CharacterPalette.app/Contents/Resources/UnicodeBlocks_Title.loctable"

    private static func looseName(_ name: String) -> String {
        String(name.filter { $0 != " " && $0 != "_" && $0 != "-" }).lowercased()
    }

    private static let namesByLooseName: [String: String] = Dictionary(names.map { (looseName($0), $0) }, uniquingKeysWith: { a, _ in a })

    /// The name in Blocks.txt of the block of a code point, such as "Latin-1 Supplement", or nil outside every block.
    static func name(of codePoint: UInt32) -> String? {
        guard codePoint <= 0x10FFFF else { return nil }
        let block = u_getIntPropertyValue(Int32(codePoint), UCHAR_BLOCK)
        // UBLOCK_NO_BLOCK is 0; -1 is an invalid code.
        guard block > 0, let alias = u_getPropertyValueName(UCHAR_BLOCK, block, U_LONG_PROPERTY_NAME) else { return nil }
        let icuName = String(cString: alias)
        // A block newer than the list keeps ICU's name, with spaces.
        return namesByLooseName[looseName(icuName)] ?? icuName.replacingOccurrences(of: "_", with: " ")
    }

    /// The key under which a table holds a block name: letters and digits in lower case, with the abbreviations
    /// spelled out ("CJK Unified Ideographs Ext. J" and "CJK Unified Ideographs Extension J" have one key).
    static func key(_ name: String) -> String {
        var spelled = name.lowercased()
        for (pattern, replacement) in [("\\bext\\.", "extension"), ("\\bsupp\\.", "supplement"), ("\\bdesc\\.", "description"), ("\\bmath\\b", "mathematical")] {
            spelled = spelled.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        return String(spelled.unicodeScalars.filter { ("a"..."z").contains($0) || ("0"..."9").contains($0) }.map(Character.init))
    }

    /// The names of a language in a table of the Character Viewer's format ({language: {block name: name}}), by key;
    /// empty for a missing or unreadable file or language.
    static func translations(path: String, language: String) -> [String: String] {
        let languages = ["Base": "en", "en": "en", "pt": "pt_BR", "pt-BR": "pt_BR", "pt-PT": "pt_PT", "zh-Hans": "zh_CN", "zh-CN": "zh_CN"]
        guard let data = FileManager.default.contents(atPath: path),
              let table = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any],
              let names = table[languages[language] ?? language.replacingOccurrences(of: "-", with: "_")] as? [String: Any] else { return [:] }
        return keyed(names)
    }

    private static func keyed(_ table: [String: Any]) -> [String: String] {
        var translations: [String: String] = [:]
        for (name, value) in table {
            if let value = value as? String, !value.isEmpty { translations[key(name)] = value }
        }
        return translations
    }

    /// For tests: the table and the language to read instead of the Character Viewer's and the interface's.
    static var tablePath: String? { didSet { cachedTranslations = nil } }
    static var tableLanguage: String? { didSet { cachedTranslations = nil } }
    private static var cachedTranslations: [String: String]?

    /// The name of a block in the language of the interface, as the Character Viewer of macOS names it, read once.
    /// Where the Character Viewer has no table (earlier macOS), TeX2img's own Japanese names (UnicodeBlocks.strings)
    /// are used; the name itself where neither has the block.
    static func localizedName(_ block: String) -> String {
        if cachedTranslations == nil {
            let language = tableLanguage ?? Bundle.main.preferredLocalizations.first ?? "en"
            var table = translations(path: tablePath ?? characterViewerTable, language: language)
            if table.isEmpty, tablePath == nil, let path = Bundle.main.path(forResource: "UnicodeBlocks", ofType: "strings"),
               let own = NSDictionary(contentsOfFile: path) as? [String: Any] {
                table = keyed(own)
            }
            cachedTranslations = table
        }
        return cachedTranslations?[key(block)] ?? block
    }
}

// MARK: - Counting

/// Characters, words and lines of a selection, counted as TeXShop 6.00's status bar counts them (TSStatusBarCounting).
enum SelectionCounting {
    /// User-perceived characters (CR LF is one).
    static func characters(_ text: NSString, _ range: NSRange) -> Int {
        guard range.length > 0 else { return 0 }
        return (text.substring(with: range) as String).count
    }

    /// Marks and selectors that belong to the character before them, and do not make a word of their own.
    private static func isAttached(_ scalar: Unicode.Scalar) -> Bool {
        guard scalar.value >= 0xAD else { return false }
        let properties = scalar.properties
        return properties.isVariationSelector || properties.isGraphemeExtend || properties.isDefaultIgnorableCodePoint
            || properties.generalCategory == .format
    }

    /// An emoji: a presentation emoji or flag, or an emoji drawn as one by a selector, a skin tone or a keycap.
    private static func isEmoji(_ character: Character) -> Bool {
        let scalars = Array(character.unicodeScalars)
        guard let first = scalars.first else { return false }
        let rest = scalars.dropFirst()
        if rest.contains(where: { $0.value == 0xFE0E }) { return false }
        if first.properties.isEmojiPresentation || (0x1F1E6...0x1F1FF).contains(first.value) { return true }
        return first.properties.isEmoji
            && rest.contains { $0.value == 0xFE0F || $0.value == 0x20E3 || $0.properties.isEmojiModifier }
    }

    /// Words as the system finds them, without words made only of marks, and the emoji between them.
    static func words(_ text: NSString, _ range: NSRange) -> Int {
        guard range.length > 0 else { return 0 }
        var count = 0
        var gap = range.location
        func countEmoji(upTo end: Int) {
            guard end > gap else { return }
            count += (text.substring(with: NSRange(location: gap, length: end - gap)) as String).filter(isEmoji).count
        }
        text.enumerateSubstrings(in: range, options: [.byWords, .localized]) { word, wordRange, _, _ in
            countEmoji(upTo: wordRange.location)
            gap = max(gap, NSMaxRange(wordRange))
            if let word, !word.unicodeScalars.allSatisfy(isAttached) { count += 1 }
        }
        countEmoji(upTo: NSMaxRange(range))
        return count
    }

    private static func isLineEnd(_ c: unichar) -> Bool {
        c == 0x0A || c == 0x0D || c == 0x85 || c == 0x2028 || c == 0x2029
    }

    /// The line (from 1) of a location; CR LF ends one line, and a location between them is on the line of the CR.
    static func line(_ text: NSString, at location: Int) -> Int {
        var line = 1
        var index = 0
        let end = min(location, text.length)
        while index < end {
            let c = text.character(at: index)
            if c == 0x0D, index + 1 < text.length, text.character(at: index + 1) == 0x0A {
                if index + 1 < end { line += 1 }
                index += 2
                continue
            }
            if isLineEnd(c) { line += 1 }
            index += 1
        }
        return line
    }

    /// The number of lines that hold characters of the non-empty ranges, each line counted once.
    static func selectedLines(_ text: NSString, _ ranges: [NSRange]) -> Int {
        var lines = IndexSet()
        for range in ranges where range.length > 0 && range.location < text.length {
            let first = line(text, at: range.location)
            let last = line(text, at: min(NSMaxRange(range), text.length) - 1)
            lines.insert(integersIn: first...last)
        }
        return lines.count
    }
}

// MARK: - Unicode properties

private func codePointString(_ c: UInt32) -> String { String(format: "U+%04X", c) }

/// "(U+D83D U+DE00)" for a code point that UTF-16 writes as a surrogate pair.
private func surrogatesString(_ c: UInt32) -> String? {
    guard (0x10000...0x10FFFF).contains(c) else { return nil }
    let value = c - 0x10000
    return String(format: "(U+%04X U+%04X)", 0xD800 + (value >> 10), 0xDC00 + (value & 0x3FF))
}

/// The names of the control characters (NameAliases.txt), which have no Unicode name.
private func controlCharacterName(_ c: UInt32) -> String? {
    guard c < 0x20 || c == 0x7F || (0x80...0x9F).contains(c) else { return nil }
    return NSString.controlCharacterName(withCharacter: unichar(c))
}

private func icuName(_ c: UInt32, _ choice: UCharNameChoice) -> String? {
    var buffer = [CChar](repeating: 0, count: 256)
    var error = U_ZERO_ERROR
    let length = u_charName(Int32(c), choice, &buffer, Int32(buffer.count), &error)
    guard error.rawValue <= U_ZERO_ERROR.rawValue, length > 0 else { return nil }
    return String(cString: buffer)
}

/// The Unicode name (its correction, where Unicode corrected it), the name of a control character, or nil,
/// as for a private-use or unassigned code point.
private func scalarName(_ c: UInt32) -> String? {
    guard c <= 0x10FFFF else { return nil }
    return icuName(c, U_CHAR_NAME_ALIAS) ?? icuName(c, U_UNICODE_CHAR_NAME) ?? controlCharacterName(c)
}

/// What a variation selector or an emoji skin tone modifier does to the code point before it.
private func variantDescription(_ c: UInt32) -> String? {
    switch c {
    case 0xFE0E: return NSLocalizedString("Text Style", comment: "")
    case 0xFE0F: return NSLocalizedString("Emoji Style", comment: "")
    case 0x1F3FB: return NSLocalizedString("Skin Tone I-II", comment: "")
    case 0x1F3FC: return NSLocalizedString("Skin Tone III", comment: "")
    case 0x1F3FD: return NSLocalizedString("Skin Tone IV", comment: "")
    case 0x1F3FE: return NSLocalizedString("Skin Tone V", comment: "")
    case 0x1F3FF: return NSLocalizedString("Skin Tone VI", comment: "")
    default:
        guard c <= 0x10FFFF, u_hasBinaryProperty(Int32(c), UCHAR_VARIATION_SELECTOR) != 0 else { return nil }
        return NSLocalizedString("Variant", comment: "")
    }
}

/// The control picture (U+2400...) that stands for an invisible control character or the space.
private func pictureCharacter(_ c: UInt32) -> String? {
    if c <= 0x20 { return String(UnicodeScalar(0x2400 + c)!) }
    if c == 0x7F { return "␡" }
    return nil
}

/// "Lowercase Letter (Ll)": the general category, by its long and short names.
private func categoryString(_ c: UInt32) -> String? {
    let category = Int32(u_charType(Int32(c)))
    guard let long = u_getPropertyValueName(UCHAR_GENERAL_CATEGORY, category, U_LONG_PROPERTY_NAME),
          let short = u_getPropertyValueName(UCHAR_GENERAL_CATEGORY, category, U_SHORT_PROPERTY_NAME) else { return nil }
    return "\(String(cString: long).replacingOccurrences(of: "_", with: " ")) (\(String(cString: short)))"
}

/// "Unicode 1.1": the version of Unicode that added the code point, or nil if none did.
private func versionString(_ c: UInt32) -> String? {
    var age = [UInt8](repeating: 0, count: 4)
    u_charAge(Int32(c), &age)
    guard age[0] != 0 || age[1] != 0 else { return nil }
    return "Unicode \(age[0]).\(age[1])"
}

/// The code points of a string; a lone surrogate is a code point of its own.
private func codePoints(_ string: String) -> [UInt32] {
    let text = string as NSString
    var points: [UInt32] = []
    var index = 0
    while index < text.length {
        let c = text.character(at: index)
        if CFStringIsSurrogateHighCharacter(c), index + 1 < text.length, CFStringIsSurrogateLowCharacter(text.character(at: index + 1)) {
            points.append(CFStringGetLongCharacterForSurrogatePair(c, text.character(at: index + 1)))
            index += 2
        } else {
            points.append(UInt32(c))
            index += 1
        }
    }
    return points
}

private func string(ofCodePoint c: UInt32) -> String {
    if let scalar = UnicodeScalar(c) { return String(scalar) }
    return NSString(characters: [unichar(truncatingIfNeeded: c)], length: 1) as String
}

// MARK: - Views

/// The large glyph, centered on what it draws, as CotEditor's CharacterField does: a tall stack of marks is not
/// cut off by the line height.
private final class GlyphView: NSView {
    var glyph = NSAttributedString()
    var bordered = false

    override var isFlipped: Bool { true }
    private var typographicBounds: NSRect { glyph.boundingRect(with: .zero, options: []) }
    private var inkBounds: NSRect { glyph.boundingRect(with: .zero, options: .usesDeviceMetrics) }

    override var intrinsicContentSize: NSSize {
        let ink = inkBounds
        return NSSize(width: ceil(ink.width), height: ceil(max(ink.height, typographicBounds.height)))
    }

    override func draw(_ dirtyRect: NSRect) {
        if bordered {
            NSColor.separatorColor.setStroke()
            NSBezierPath.stroke(bounds.insetBy(dx: 0.5, dy: 0.5))
        }
        let ink = inkBounds, typographic = typographicBounds
        let point: NSPoint
        if ink.isEmpty {
            // Nothing to center on, such as a space: center the line.
            point = NSPoint(x: bounds.midX - typographic.width / 2, y: bounds.midY - typographic.height / 2)
        } else {
            // The top left of the line, from the top left of the ink centered in the view.
            point = NSPoint(x: bounds.midX - ink.width / 2 - ink.minX, y: bounds.midY - ink.height / 2 + ink.maxY - typographic.maxY)
        }
        glyph.draw(at: point)
    }

    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .staticText }
    override func accessibilityValue() -> Any? { glyph.string }
}

/// "deprecated", outlined, after the code point of a character that Unicode deprecates.
private final class Badge: NSView {
    let label: NSTextField

    init(title: String, font: NSFont) {
        label = NSTextField(labelWithString: title)
        super.init(frame: .zero)
        label.font = font
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var firstBaselineOffsetFromTop: CGFloat { label.firstBaselineOffsetFromTop }
    override var lastBaselineOffsetFromBottom: CGFloat { label.lastBaselineOffsetFromBottom }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.secondaryLabelColor.setStroke()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 3, yRadius: 3).stroke()
    }
}

/// The code points of several characters, broken into lines between them, not inside "U+...".
private final class CodePointsTextStorage: NSTextStorage {
    private let contents: NSMutableAttributedString

    init(codePoints attributedString: NSAttributedString) {
        contents = NSMutableAttributedString(attributedString: attributedString)
        super.init()
    }

    override init() {
        contents = NSMutableAttributedString()
        super.init()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) { fatalError("not supported") }

    override var string: String { contents.string }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        contents.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        contents.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        contents.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
    }

    // Lines break only after the two spaces between code points, so that "U+1F600 (U+D83D U+DE00)" stays on one line.
    override func lineBreak(before index: Int, within aRange: NSRange) -> Int {
        let separator = (string as NSString).range(of: "  ", options: .backwards, range: NSRange(location: aRange.location, length: index - aRange.location))
        if separator.location != NSNotFound, NSMaxRange(separator) > aRange.location { return NSMaxRange(separator) }
        return super.lineBreak(before: index, within: aRange)
    }
}

// MARK: - Controller

final class MyGlyphPopoverController: NSViewController {
    private static let inset: CGFloat = 14
    private static let glyphFontSize: CGFloat = 64, glyphMinWidth: CGFloat = 64
    private static let scalarGlyphFontSize: CGFloat = 28, scalarGlyphMinWidth: CGFloat = 30
    // Longer names and values wrap at these widths, so that the popover stays narrow.
    private static let nameMaxWidth: CGFloat = 360, scalarNameMaxWidth: CGFloat = 260, valueMaxWidth: CGFloat = 300
    private static let tableColumnSpacing: CGFloat = 6
    // The selection of several characters.
    private static let multiWidth: CGFloat = 320, multiMaxCodePointsHeight: CGFloat = 300

    /// The characters shown: those of every selected range, in order.
    let character: String
    let isSingleLetter: Bool
    let counts: (characters: Int, words: Int, lines: Int)
    private weak var popover: NSPopover?
    // What a click changed, kept while the views are built again: the code points opened ("scalar.N.") and the
    // block names shown as Unicode names them (the identifiers of their fields).
    private var openCodePoints = Set<String>()
    private var unicodeBlockNames = Set<String>()

    /// Character Info for the characters of the ranges of a text (the selected ranges of a text view); nil when
    /// the ranges hold no character.
    init?(text: String, ranges: [NSRange]) {
        let text = text as NSString
        var characters = 0, words = 0
        var selected = ""
        for range in ranges {
            guard range.location <= text.length, range.length <= text.length - range.location else { return nil }
            guard range.length > 0 else { continue }
            characters += SelectionCounting.characters(text, range)
            words += SelectionCounting.words(text, range)
            selected += text.substring(with: range)
        }
        guard characters > 0 else { return nil }
        character = selected
        isSingleLetter = characters == 1
        counts = (characters, words, SelectionCounting.selectedLines(text, ranges))
        super.init(nibName: nil, bundle: nil)
    }

    /// Character Info for the whole string.
    convenience init?(character: String) {
        self.init(text: character, ranges: [NSRange(location: 0, length: (character as NSString).length)])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: Building

    private static var smallFont: NSFont { .systemFont(ofSize: NSFont.smallSystemFontSize) }
    private static var codePointFont: NSFont { .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular) }

    /// A label that shows its whole text: on one line, or wrapped at maxWidth when longer.
    private static func label(_ text: String, font: NSFont, color: NSColor, maxWidth: CGFloat, selectable: Bool, identifier: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = font
        field.textColor = color
        field.isSelectable = selectable
        field.identifier = NSUserInterfaceItemIdentifier(identifier)
        field.translatesAutoresizingMaskIntoConstraints = false
        let wraps = (text as NSString).size(withAttributes: [.font: font]).width > maxWidth
        field.lineBreakMode = wraps ? .byWordWrapping : .byClipping
        field.usesSingleLineMode = !wraps
        field.cell?.isScrollable = !wraps
        field.cell?.wraps = wraps
        field.maximumNumberOfLines = wraps ? 0 : 1
        field.preferredMaxLayoutWidth = wraps ? maxWidth : 0
        field.setContentCompressionResistancePriority(.required, for: .horizontal)
        field.setContentCompressionResistancePriority(.required, for: .vertical)
        return field
    }

    private static func glyphString(_ text: String, size: CGFloat, color: NSColor) -> NSAttributedString {
        let system = NSFont.systemFont(ofSize: size)
        let font = system.fontDescriptor.withDesign(.serif).flatMap { NSFont(descriptor: $0, size: size) } ?? system
        return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    }

    private static func stack(_ orientation: NSUserInterfaceLayoutOrientation, _ views: [NSView], spacing: CGFloat,
                              alignment: NSLayoutConstraint.Attribute) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = orientation
        stack.spacing = spacing
        stack.alignment = alignment
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private static func glyphView(_ text: String, size: CGFloat, color: NSColor, minWidth: CGFloat, identifier: String) -> GlyphView {
        let glyph = GlyphView()
        glyph.glyph = glyphString(text, size: size, color: color)
        glyph.identifier = NSUserInterfaceItemIdentifier(identifier)
        glyph.translatesAutoresizingMaskIntoConstraints = false
        glyph.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
        for orientation in [NSLayoutConstraint.Orientation.horizontal, .vertical] {
            glyph.setContentHuggingPriority(.required, for: orientation)
            glyph.setContentCompressionResistancePriority(.required, for: orientation)
        }
        return glyph
    }

    /// The table of a code point: the headings right-aligned in the secondary color, the values in the label color.
    private func table(for c: UInt32, prefix: String, codePoint withCodePoint: Bool, version withVersion: Bool) -> NSGridView {
        let font = Self.smallFont
        // The values wrap where the table would be wider than the name may be.
        let headings = ["Code Point:", "Block:", "Category:", "Version:"].map { NSLocalizedString($0, comment: "") }
        let headingWidth = headings.map { ceil(($0 as NSString).size(withAttributes: [.font: font]).width) }.max() ?? 0
        let valueMaxWidth = min(Self.valueMaxWidth, Self.nameMaxWidth - headingWidth - Self.tableColumnSpacing)
        var rows: [[NSView]] = []
        func addRow(_ key: String, _ heading: String, _ value: NSView) {
            let label = Self.label(NSLocalizedString(heading, comment: ""), font: font, color: .secondaryLabelColor, maxWidth: .greatestFiniteMagnitude,
                                   selectable: false, identifier: prefix + key + ".label")
            label.alignment = .right
            rows.append([label, value])
        }

        if withCodePoint {
            let text = [codePointString(c), surrogatesString(c)].compactMap { $0 }.joined(separator: " ")
            var value: NSView = Self.label(text, font: Self.codePointFont, color: .labelColor, maxWidth: .greatestFiniteMagnitude,
                                           selectable: true, identifier: prefix + "codePoint")
            if c <= 0x10FFFF, u_hasBinaryProperty(Int32(c), UCHAR_DEPRECATED) != 0 {
                let badge = Badge(title: NSLocalizedString("deprecated", comment: ""), font: font)
                badge.identifier = NSUserInterfaceItemIdentifier(prefix + "deprecated")
                badge.translatesAutoresizingMaskIntoConstraints = false
                value = Self.stack(.horizontal, [value, badge], spacing: 6, alignment: .lastBaseline)
            }
            addRow("codePoint", "Code Point:", value)
        }

        let blockField: NSTextField
        if let block = UnicodeBlocks.name(of: c) {
            let localized = UnicodeBlocks.localizedName(block), identifier = prefix + "block"
            // As in CotEditor, a click shows the name of Unicode, and another the translation again.
            let showsUnicodeName = unicodeBlockNames.contains(identifier)
            blockField = Self.label(showsUnicodeName ? block : localized, font: font, color: .labelColor, maxWidth: valueMaxWidth,
                                    selectable: false, identifier: identifier)
            if localized != block {
                blockField.toolTip = showsUnicodeName ? localized : block
                blockField.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(toggleBlockName(_:))))
            }
        } else {
            blockField = Self.label(NSLocalizedString("No Block", comment: ""), font: font, color: .secondaryLabelColor, maxWidth: valueMaxWidth,
                                    selectable: false, identifier: prefix + "block")
        }
        addRow("block", "Block:", blockField)

        if let category = categoryString(c) {
            addRow("category", "Category:", Self.label(category, font: font, color: .labelColor, maxWidth: valueMaxWidth,
                                                        selectable: true, identifier: prefix + "category"))
        }
        if withVersion, let version = versionString(c) {
            addRow("version", "Version:", Self.label(version, font: font, color: .labelColor, maxWidth: valueMaxWidth,
                                                      selectable: true, identifier: prefix + "version"))
        }

        let grid = NSGridView(views: rows)
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 3
        grid.columnSpacing = Self.tableColumnSpacing
        grid.rowAlignment = .lastBaseline
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).xPlacement = .leading
        // As wide as its columns, at the leading edge below the name.
        grid.setContentHuggingPriority(NSLayoutConstraint.Priority(NSLayoutConstraint.Priority.defaultHigh.rawValue + 1), for: .horizontal)
        return grid
    }

    @objc private func toggleBlockName(_ click: NSClickGestureRecognizer) {
        guard let identifier = click.view?.identifier?.rawValue else { return }
        if unicodeBlockNames.remove(identifier) == nil { unicodeBlockNames.insert(identifier) }
        rebuild()
    }

    /// A row of the code points of a character: the disclosure triangle, the code point and its name; opened,
    /// the glyph of the code point with its block and category.
    private func row(for c: UInt32, index: Int) -> NSView {
        let prefix = "scalar.\(index)."
        let open = openCodePoints.contains(prefix)
        let disclosure = NSButton(title: "", target: self, action: #selector(toggleCodePoint(_:)))
        disclosure.bezelStyle = .disclosure
        disclosure.setButtonType(.pushOnPushOff)
        disclosure.state = open ? .on : .off
        disclosure.controlSize = .small
        disclosure.identifier = NSUserInterfaceItemIdentifier(prefix + "disclosure")
        disclosure.translatesAutoresizingMaskIntoConstraints = false

        let codePointField = Self.label(codePointString(c), font: Self.codePointFont, color: .labelColor, maxWidth: .greatestFiniteMagnitude,
                                        selectable: true, identifier: prefix + "codePoint")
        codePointField.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        var header: [NSView] = [disclosure, codePointField]
        if let surrogates = surrogatesString(c) {
            header.append(Self.label(surrogates, font: Self.codePointFont, color: .secondaryLabelColor, maxWidth: .greatestFiniteMagnitude,
                                     selectable: true, identifier: prefix + "surrogates"))
        }
        if let name = scalarName(c) {
            header.append(Self.label(name, font: .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium), color: .labelColor,
                                     maxWidth: Self.scalarNameMaxWidth, selectable: true, identifier: prefix + "name"))
        } else {
            header.append(Self.label(NSLocalizedString("Unknown", comment: ""), font: Self.smallFont, color: .secondaryLabelColor,
                                     maxWidth: .greatestFiniteMagnitude, selectable: false, identifier: prefix + "name"))
        }
        let headerStack = Self.stack(.horizontal, header, spacing: 4, alignment: .firstBaseline)
        guard open else { return headerStack }

        let picture = pictureCharacter(c)
        let glyph = Self.glyphView(picture ?? string(ofCodePoint: c), size: Self.scalarGlyphFontSize,
                                   color: picture != nil ? .tertiaryLabelColor : .labelColor, minWidth: Self.scalarGlyphMinWidth, identifier: prefix + "glyph")
        glyph.bordered = true
        let detail = Self.stack(.horizontal, [glyph, table(for: c, prefix: prefix, codePoint: false, version: false)], spacing: 8, alignment: .top)
        detail.identifier = NSUserInterfaceItemIdentifier(prefix + "detail")
        detail.edgeInsets = NSEdgeInsets(top: 2, left: 20, bottom: 6, right: 0)
        return Self.stack(.vertical, [headerStack, detail], spacing: 0, alignment: .leading)
    }

    @objc private func toggleCodePoint(_ disclosure: NSButton) {
        guard let identifier = disclosure.identifier?.rawValue else { return }
        let prefix = String(identifier.dropLast("disclosure".count))
        if disclosure.state == .on { openCodePoints.insert(prefix) } else { openCodePoints.remove(prefix) }
        rebuild()
    }

    private func singleCharacterView() -> NSView {
        let points = codePoints(character)
        let first = points.first ?? 0
        let variant = points.count == 2 ? variantDescription(points[1]) : nil
        let complex = points.count > 1 && variant == nil

        // The glyph, or the picture of an invisible control character or space.
        let picture = points.count == 1 ? pictureCharacter(first) : nil
        let glyph = Self.glyphView(picture ?? character, size: Self.glyphFontSize, color: picture != nil ? .tertiaryLabelColor : .labelColor,
                                   minWidth: Self.glyphMinWidth, identifier: "glyph")

        // The name of the code point, with what a variation selector or skin tone adds,
        // or the number of code points of a character made of several.
        let nameField: NSTextField
        if complex {
            let name = String(format: NSLocalizedString("<a letter consisting of %d characters>", comment: ""), Int32(points.count))
            nameField = Self.label(name, font: .systemFont(ofSize: NSFont.systemFontSize), color: .labelColor, maxWidth: Self.nameMaxWidth,
                                   selectable: true, identifier: "name")
        } else if var name = scalarName(first) {
            if let variant { name = "\(name) (\(variant))" }
            nameField = Self.label(name, font: .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold), color: .labelColor,
                                   maxWidth: Self.nameMaxWidth, selectable: true, identifier: "name")
        } else {
            nameField = Self.label(NSLocalizedString("Unknown", comment: ""), font: .systemFont(ofSize: NSFont.systemFontSize),
                                   color: .secondaryLabelColor, maxWidth: Self.nameMaxWidth, selectable: false, identifier: "name")
        }

        let details = Self.stack(.vertical, [nameField], spacing: 0, alignment: .leading)
        if !complex {
            details.addArrangedSubview(table(for: first, prefix: "", codePoint: true, version: true))
            details.setCustomSpacing(4, after: nameField)
        }
        if points.count > 1 {
            // A little room between the rows, so that their lines of text do not touch.
            let list = Self.stack(.vertical, points.enumerated().map { row(for: $1, index: $0) }, spacing: 1, alignment: .leading)
            list.identifier = NSUserInterfaceItemIdentifier("scalars")
            if let last = details.arrangedSubviews.last { details.setCustomSpacing(6, after: last) }
            details.addArrangedSubview(list)
        }
        return Self.stack(.horizontal, [glyph, details], spacing: 8, alignment: .top)
    }

    private func multipleCharactersView() -> NSView {
        let text = String(format: NSLocalizedString("%lu letters, %lu words, %lu lines", comment: ""), counts.characters, counts.words, counts.lines)
        let countsField = Self.label(text, font: .systemFont(ofSize: NSFont.systemFontSize), color: .labelColor, maxWidth: Self.multiWidth,
                                     selectable: true, identifier: "counts")
        let list = codePoints(character).map { c in [codePointString(c), surrogatesString(c)].compactMap { $0 }.joined(separator: " ") }
        let codes = NSAttributedString(string: list.joined(separator: "  "), attributes: [.font: Self.codePointFont, .foregroundColor: NSColor.labelColor])

        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: Self.multiWidth, height: 30))
        scroll.identifier = NSUserInterfaceItemIdentifier("codePointsScroll")
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: Self.multiWidth, height: 30))
        textView.identifier = NSUserInterfaceItemIdentifier("codePoints")
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isRichText = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        textView.textContainer?.widthTracksTextView = true
        textView.layoutManager?.replaceTextStorage(CodePointsTextStorage(codePoints: codes))
        scroll.documentView = textView
        var used: CGFloat = 0
        if let layoutManager = textView.layoutManager, let container = textView.textContainer {
            layoutManager.ensureLayout(for: container)
            used = ceil(layoutManager.usedRect(for: container).height)
        }
        let height = min(used, Self.multiMaxCodePointsHeight)
        scroll.hasVerticalScroller = used > Self.multiMaxCodePointsHeight
        NSLayoutConstraint.activate([
            scroll.widthAnchor.constraint(equalToConstant: Self.multiWidth),
            scroll.heightAnchor.constraint(equalToConstant: height),
        ])
        textView.setFrameSize(NSSize(width: Self.multiWidth, height: max(used, height)))

        let content = Self.stack(.vertical, [countsField, scroll], spacing: 6, alignment: .leading)
        content.widthAnchor.constraint(equalToConstant: Self.multiWidth).isActive = true
        return content
    }

    override func loadView() {
        view = NSView(frame: .zero)
        rebuild()
    }

    /// Builds the views for the character, with the code points opened and the block names chosen so far.
    private func rebuild() {
        let root = view
        root.subviews.forEach { $0.removeFromSuperview() }
        let content = isSingleLetter ? singleCharacterView() : multipleCharactersView()
        root.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: Self.inset),
            content.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -Self.inset),
            content.topAnchor.constraint(equalTo: root.topAnchor, constant: Self.inset),
            content.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -Self.inset),
        ])
        fitToContents()
    }

    /// The popover takes the size of what it shows, also after a disclosure triangle or a block name is clicked.
    private func fitToContents() {
        // The size the contents need, measured on them: the view itself is held at the preferred content size it had.
        let root = view
        let inner = root.subviews.first?.fittingSize ?? .zero
        let size = NSSize(width: ceil(inner.width + 2 * Self.inset), height: ceil(inner.height + 2 * Self.inset))
        preferredContentSize = size
        root.setFrameSize(size)
        root.layoutSubtreeIfNeeded()
        popover?.contentSize = size
    }

    func showPopover(relativeTo positioningRect: NSRect, of parentView: NSView) {
        let popover = NSPopover()
        popover.contentViewController = self
        popover.behavior = .semitransient
        self.popover = popover
        fitToContents()
        popover.show(relativeTo: positioningRect, of: parentView, preferredEdge: .minY)
        parentView.window?.makeFirstResponder(parentView)
    }
}
