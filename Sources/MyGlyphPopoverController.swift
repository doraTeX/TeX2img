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

import AppKit
import Foundation

private let textSequenceChar: unichar = 0xFE0E
private let emojiSequenceChar: unichar = 0xFE0F
private let type12EmojiModifierChar: UTF32Char = 0x1F3FB
private let type3EmojiModifierChar: UTF32Char = 0x1F3FC
private let type4EmojiModifierChar: UTF32Char = 0x1F3FD
private let type5EmojiModifierChar: UTF32Char = 0x1F3FE
private let type6EmojiModifierChar: UTF32Char = 0x1F3FF

private final class MyGlyphPopoverUnicodesTextStorage: NSTextStorage {
    private var contents: NSMutableAttributedString

    override init() {
        contents = NSMutableAttributedString()
        super.init()
    }

    init(copying attrStr: NSAttributedString?) {
        contents = attrStr.map { NSMutableAttributedString(attributedString: $0) } ?? NSMutableAttributedString()
        super.init()
    }

    required init?(coder: NSCoder) {
        contents = NSMutableAttributedString()
        super.init(coder: coder)
    }

    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        contents = NSMutableAttributedString()
        super.init(pasteboardPropertyList: propertyList, ofType: type)
    }

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

    override func lineBreak(before index: Int, within aRange: NSRange) -> Int {
        let breakIndex = super.lineBreak(before: index, within: aRange)
        if breakIndex >= 2, (string as NSString).character(at: breakIndex) == UInt16(("+" as UnicodeScalar).value) {
            return breakIndex - 2
        }
        return breakIndex
    }
}

private final class UnicodeInfo: NSObject {
    let unicodeChar: UTF32Char
    let unicodeString: String
    let surrogate: Bool
    let highSurrogate: unichar
    let lowSurrogate: unichar

    init(unichar unicodePoint: unichar) {
        unicodeChar = UTF32Char(unicodePoint)
        unicodeString = NSString.stringWithUTF32Char(unicodeChar)
        surrogate = false
        highSurrogate = 0
        lowSurrogate = 0
        super.init()
    }

    init(highSurrogate: unichar, lowSurrogate: unichar) {
        self.surrogate = true
        self.highSurrogate = highSurrogate
        self.lowSurrogate = lowSurrogate
        unicodeChar = CFStringGetLongCharacterForSurrogatePair(highSurrogate, lowSurrogate)
        unicodeString = NSString.stringWithUTF32Char(unicodeChar)
        super.init()
    }

    var stringExpression: String {
        String(format: "U+%04X", unicodeChar)
    }

    var stringExpressionWithSurrogatePairInfomation: String {
        if surrogate {
            return String(format: "U+%04X (U+%04X U+%04X)", unicodeChar, highSurrogate, lowSurrogate)
        }
        return stringExpression
    }

    var stringExpressionWithUnicodeName: String {
        "\(stringExpressionWithSurrogatePairInfomation) \((unicodeString as NSString).unicodeName())"
    }
}

@objc(MyGlyphPopoverController)
class MyGlyphPopoverController: NSViewController {
    @objc dynamic var glyph = ""
    @objc dynamic var unicodeName = ""
    @objc dynamic var unicodeBlockName = ""
    @objc dynamic var unicode = ""

    @IBOutlet private var unicodesTextView: NSTextView!
    @IBOutlet private var unicodeBlockNameField: NSTextField!

    @objc(initWithCharacter:)
    init?(character: String) {
        let numberOfComposedCharacters = character.numberOfComposedCharacters()
        guard numberOfComposedCharacters > 0 else { return nil }

        let singleLetter = numberOfComposedCharacters == 1
        let nibName = singleLetter ? "GlyphPopoverSingle" : "GlyphPopoverMulti"

        super.init(nibName: nibName, bundle: nil)

        if singleLetter {
            glyph = character
        }

        let nsCharacter = character as NSString
        let length = nsCharacter.length
        var firstChar: String?
        var firstCode: String?
        var unicodes = [UnicodeInfo]()

        var index = 0
        while index < length {
            let theChar = nsCharacter.character(at: index)
            let nextChar = (length > index + 1) ? nsCharacter.character(at: index + 1) : unichar(0)
            let unicodeInfo: UnicodeInfo

            if CFStringIsSurrogateHighCharacter(theChar), CFStringIsSurrogateLowCharacter(nextChar) {
                unicodeInfo = UnicodeInfo(highSurrogate: theChar, lowSurrogate: nextChar)
                if firstChar == nil {
                    firstChar = unicodeInfo.unicodeString
                }
                index += 1
            } else {
                unicodeInfo = UnicodeInfo(unichar: theChar)
                if firstChar == nil {
                    firstChar = NSString.stringWithUTF32Char(UTF32Char(theChar))
                }
            }

            if firstCode == nil {
                firstCode = unicodeInfo.stringExpression
            }

            unicodes.append(unicodeInfo)
            index += 1
        }

        var multiCodePoints = unicodes.count > 1
        var variationSelectorAdditional: String?

        if unicodes.count == 2 {
            let lastChar = nsCharacter.character(at: length - 1)
            if lastChar == emojiSequenceChar {
                variationSelectorAdditional = "Emoji Style"
                multiCodePoints = false
            } else if lastChar == textSequenceChar {
                variationSelectorAdditional = "Text Style"
                multiCodePoints = false
            } else if (lastChar >= 0x180B && lastChar <= 0x180D) || (lastChar >= 0xFE00 && lastChar <= 0xFE0D) {
                variationSelectorAdditional = "Variant"
                multiCodePoints = false
            } else {
                let highSurrogate = nsCharacter.character(at: length - 2)
                let lowSurrogate = nsCharacter.character(at: length - 1)
                if CFStringIsSurrogateHighCharacter(highSurrogate), CFStringIsSurrogateLowCharacter(lowSurrogate) {
                    let pair = CFStringGetLongCharacterForSurrogatePair(highSurrogate, lowSurrogate)
                    switch pair {
                    case type12EmojiModifierChar:
                        variationSelectorAdditional = "Skin Tone I-II"
                        multiCodePoints = false
                    case type3EmojiModifierChar:
                        variationSelectorAdditional = "Skin Tone III"
                        multiCodePoints = false
                    case type4EmojiModifierChar:
                        variationSelectorAdditional = "Skin Tone IV"
                        multiCodePoints = false
                    case type5EmojiModifierChar:
                        variationSelectorAdditional = "Skin Tone V"
                        multiCodePoints = false
                    case type6EmojiModifierChar:
                        variationSelectorAdditional = "Skin Tone VI"
                        multiCodePoints = false
                    default:
                        if pair >= 0xE0100 && pair <= 0xE01EF {
                            variationSelectorAdditional = "Variant"
                            multiCodePoints = false
                        }
                    }
                }
            }
        }

        if multiCodePoints {
            if singleLetter {
                unicode = unicodes.map { $0.stringExpressionWithUnicodeName }.joined(separator: "\n")
                if let firstChar, let firstCode {
                    unicodeName = String(format: NSLocalizedString("Base: %@ (%@ %@) <combining character sequence consisting of %lu characters>", comment: ""),
                                         firstChar, firstCode, (firstChar as NSString).unicodeName(), unicodes.count)
                    unicodeBlockName = (firstChar as NSString).localizedBlockName()
                }
            } else {
                unicode = unicodes.map { $0.stringExpressionWithSurrogatePairInfomation }.joined(separator: "  ")

                var numberOfWords = NSSpellChecker.shared.countWords(in: character, language: nil)
                if numberOfWords == -1 {
                    numberOfWords = NSSpellChecker.shared.countWords(in: character, language: "English")
                }
                let numberOfLines = character.components(separatedBy: "\n").count

                unicodeName = String(format: NSLocalizedString("%lu letters, %lu words, %lu lines", comment: ""),
                                     numberOfComposedCharacters, numberOfWords, numberOfLines)

                let originalFrame = view.frame
                let oldHeight = originalFrame.size.height

                unicodesTextView.isHorizontallyResizable = true
                unicodesTextView.isVerticallyResizable = true
                let aStr = unicodesTextView.textStorage?.attributedSubstring(from: NSRange(location: 0, length: unicodesTextView.textStorage?.length ?? 0))
                let newStorage = MyGlyphPopoverUnicodesTextStorage(copying: aStr)
                unicodesTextView.layoutManager?.replaceTextStorage(newStorage)

                unicodesTextView.sizeToFit()
                let rect = unicodesTextView.layoutManager?.usedRect(for: unicodesTextView.textContainer!) ?? .zero
                var newHeight = rect.size.height + 50
                newHeight = newHeight < oldHeight ? oldHeight : min(newHeight, 300)

                view.frame = NSRect(x: originalFrame.origin.x,
                                    y: originalFrame.origin.y,
                                    width: originalFrame.size.width,
                                    height: newHeight)
            }
        } else {
            let theChar = nsCharacter.character(at: 0)

            if let controlName = NSString.controlCharacterName(withCharacter: theChar) {
                unicodeName = controlName
                glyph = ""
            } else {
                unicodeName = (character as NSString).unicodeName()
            }

            if let variationSelectorAdditional {
                unicodeName = "\(unicodeName) (\(NSLocalizedString(variationSelectorAdditional, comment: "")))"
            }

            if unicodes.count > 1 {
                unicode = unicodes.map { $0.stringExpressionWithUnicodeName }.joined(separator: "\n")
            } else {
                unicode = unicodes[0].stringExpressionWithSurrogatePairInfomation
            }
            unicodeBlockName = (character as NSString).localizedBlockName()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func loadView() {
        super.loadView()

        if unicodeBlockName.isEmpty {
            unicodeBlockNameField?.removeFromSuperview()
        }
    }

    @objc func showPopoverRelativeToRect(_ positioningRect: NSRect, ofView parentView: NSView) {
        let popover = NSPopover()
        popover.contentViewController = self
        popover.behavior = .semitransient
        popover.show(relativeTo: positioningRect, of: parentView, preferredEdge: .minY)
        parentView.window?.makeFirstResponder(parentView)
    }
}