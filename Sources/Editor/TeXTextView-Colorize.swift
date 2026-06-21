import AppKit
import Foundation

extension TeXTextView {
    func colorizeText() {
        guard let controller else { return }
        let profile = controller.currentProfile()

        textColor = UtilityG.foregroundColor(inProfile: profile)
        backgroundColor = UtilityG.backgroundColor(inProfile: profile)
        insertionPointColor = UtilityG.cursorColor(inProfile: profile)

        let commandColorAttribute: [NSAttributedString.Key: Any] = [
            .foregroundColor: UtilityG.commandColor(inProfile: profile),
        ]
        let commentColorAttribute: [NSAttributedString.Key: Any] = [
            .foregroundColor: UtilityG.commentColor(inProfile: profile),
        ]
        let braceColorAttribute: [NSAttributedString.Key: Any] = [
            .foregroundColor: UtilityG.braceColor(inProfile: profile),
        ]

        guard let layoutManager else { return }
        let textString = string
        let length = textString.length

        var aLineStart: Int = 0
        var aLineEnd: Int = 0
        textString.getLineStart(&aLineStart, end: &aLineEnd, contentsEnd: nil, for: NSRange(location: 0, length: length))

        var colorRange = NSRange(location: aLineStart, length: aLineEnd - aLineStart)
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: colorRange)

        var location = aLineStart
        while location < aLineEnd {
            let theChar = textString.character(at: location)

            if theChar == "{".utf16.first! || theChar == "}".utf16.first! || theChar == "$".utf16.first! {
                colorRange = NSRange(location: location, length: 1)
                layoutManager.addTemporaryAttributes(braceColorAttribute, forCharacterRange: colorRange)
                location += 1
            } else if theChar == "%".utf16.first! {
                colorRange = NSRange(location: location, length: 1)
                var end = 0
                textString.getLineStart(nil, end: nil, contentsEnd: &end, for: colorRange)
                colorRange.length = end - location
                layoutManager.addTemporaryAttributes(commentColorAttribute, forCharacterRange: colorRange)
                location = end
            } else if theChar == "\\".utf16.first! || theChar == 0x00a5 {
                colorRange = NSRange(location: location, length: 1)
                location += 1
                if location < aLineEnd, !isValidTeXCommandChar(textString.character(at: location)) {
                    location += 1
                    colorRange.length = location - colorRange.location
                } else {
                    while location < aLineEnd, isValidTeXCommandChar(textString.character(at: location)) {
                        location += 1
                        colorRange.length = location - colorRange.location
                    }
                }
                layoutManager.addTemporaryAttributes(commandColorAttribute, forCharacterRange: colorRange)
            } else {
                location += 1
            }
        }
    }

    func resetBackgroundColor(_ sender: Any?) {
        layoutManager?.removeTemporaryAttribute(
            .backgroundColor,
            forCharacterRange: NSRange(location: 0, length: textStorage!.length)
        )
        contentHighlighting = false
    }

    private func resetHighlight(_ sender: Any?) {
        colorizeText()
        braceHighlighting = false
    }

    private func showIndicator(_ range: NSRange) {
        showFindIndicator(for: range)
    }

    private func resetBackgroundColorOfTextView(_ sender: Any?) {
        backgroundColor = UtilityG.backgroundColor(inProfile: controller.currentProfile())
    }

    private func highlightContent(_ range: NSRange) {
        contentHighlighting = true
        let profile = controller.currentProfile()
        layoutManager?.addTemporaryAttributes(
            [.backgroundColor: UtilityG.enclosedContentBackgroundColor(inProfile: profile)],
            forCharacterRange: range
        )
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard let layoutManager else { return }
        let profile = controller.currentProfile()

        if contentHighlighting {
            DispatchQueue.main.async { [weak self] in
                self?.resetBackgroundColor(nil)
            }
        }

        let highlightPattern = SOLID

        if highlightPattern == SOLID || braceHighlighting {
            resetHighlight(nil)
        }

        highlightBracesColorDict = [.foregroundColor: UtilityG.highlightedBraceColor(inProfile: profile)]
        let braceCharList: [unichar] = [0x0028, 0x0029, 0x005B, 0x005D, 0x007B, 0x007D, 0x003C, 0x003E]

        let theString = textStorage!.string
        let theStringLength = theString.length
        guard theStringLength > 0 else { return }

        let theSelectedRange = selectedRange
        let theLocation = theSelectedRange.location
        let theDifference = theLocation - Int(lastCursorLocation)
        lastCursorLocation = UInt(theLocation)

        if theStringLength - Int(lastStringLength) == -1 {
            lastStringLength = UInt(theStringLength)
            return
        }
        lastStringLength = UInt(theStringLength)

        if theDifference != 1 && theDifference != -1 { return }

        var checkLocation = theLocation
        if theDifference == 1 {
            checkLocation -= 1
        }

        if checkLocation == theStringLength { return }
        let originalLocation = checkLocation

        let checkBrace = profile.boolForKey(CheckBraceKey)
        let checkBracket = profile.boolForKey(CheckBracketKey)
        let checkSquareBracket = profile.boolForKey(CheckSquareBracketKey)
        let checkParen = profile.boolForKey(CheckParenKey)

        let theUnichar = theString.character(at: checkLocation)
        let previousChar: unichar = checkLocation > 0 ? theString.character(at: checkLocation - 1) : 0
        let notCS = previousChar != "\\".utf16.first! && previousChar != 0x00a5

        let theBraceChar: unichar
        let inc: Int
        let theCurChar = theUnichar

        switch theUnichar {
        case ")".utf16.first! where checkParen && notCS:
            theBraceChar = braceCharList[0]
            inc = -1
        case "(".utf16.first! where checkParen && notCS:
            theBraceChar = braceCharList[1]
            inc = 1
        case "]".utf16.first! where checkSquareBracket && notCS:
            theBraceChar = braceCharList[2]
            inc = -1
        case "[".utf16.first! where checkSquareBracket && notCS:
            theBraceChar = braceCharList[3]
            inc = 1
        case "}".utf16.first! where checkBrace && notCS:
            theBraceChar = braceCharList[4]
            inc = -1
        case "{".utf16.first! where checkBrace && notCS:
            theBraceChar = braceCharList[5]
            inc = 1
        case ">".utf16.first! where checkBracket && notCS:
            theBraceChar = braceCharList[6]
            inc = -1
        case "<".utf16.first! where checkBracket && notCS:
            theBraceChar = braceCharList[7]
            inc = 1
        default:
            return
        }

        var location = checkLocation
        var skipMatchingBrace = 0

        while true {
            location += inc
            guard location >= 0 && location < theStringLength else { break }
            let uchar = theString.character(at: location)
            let prev = location > 0 ? theString.character(at: location - 1) : 0
            let notControlSequence = prev != "\\".utf16.first! && prev != 0x00a5

            if uchar == theBraceChar && notControlSequence {
                if skipMatchingBrace == 0 {
                    if highlightPattern != NOHIGHLIGHT {
                        braceHighlighting = true
                        layoutManager.addTemporaryAttributes(
                            highlightBracesColorDict!,
                            forCharacterRange: NSRange(location: location, length: 1)
                        )
                        layoutManager.addTemporaryAttributes(
                            highlightBracesColorDict!,
                            forCharacterRange: NSRange(location: originalLocation, length: 1)
                        )
                        display()
                    }

                    if profile.boolForKey(HighlightContentKey) {
                        let contentRange = NSRange(
                            location: min(originalLocation, location),
                            length: abs(originalLocation - location) + 1
                        )
                        DispatchQueue.main.async { [weak self] in
                            self?.highlightContent(contentRange)
                        }
                    }

                    if !autoCompleting, profile.boolForKey(FlashInMovingKey) {
                        DispatchQueue.main.async { [weak self] in
                            self?.showIndicator(NSRange(location: location, length: 1))
                        }
                    }

                    if highlightPattern == FLASH {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
                            self?.resetHighlight(nil)
                        }
                    }
                    return
                }
                skipMatchingBrace += inc
            } else if uchar == theCurChar && notControlSequence {
                skipMatchingBrace -= inc
            }
        }

        if profile.boolForKey(BeepKey) {
            NSSound.beep()
        }
        if profile.boolForKey(FlashBackgroundKey) {
            backgroundColor = UtilityG.flashingBackgroundColor(inProfile: profile)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { [weak self] in
                self?.resetBackgroundColorOfTextView(nil)
            }
        }
    }

    override func shouldChangeText(in affectedCharRange: NSRange, replacementString: String?) -> Bool {
        _ = super.shouldChangeText(in: affectedCharRange, replacementString: replacementString)

        guard let replacementString, replacementString.count == 1 else { return true }

        let rightpar = replacementString.utf16.first!
        let profile = controller.currentProfile()
        let highlightPattern = SOLID
        let checkBrace = profile.boolForKey(CheckBraceKey)
        let checkBracket = profile.boolForKey(CheckBracketKey)
        let checkSquareBracket = profile.boolForKey(CheckSquareBracketKey)
        let checkParen = profile.boolForKey(CheckParenKey)

        guard highlightPattern != NOHIGHLIGHT else { return true }

        let isClosingBrace = (rightpar == "}".utf16.first! && checkBrace)
            || (rightpar == ")".utf16.first! && checkParen)
            || (rightpar == ">".utf16.first! && checkBracket)
            || (rightpar == "]".utf16.first! && checkSquareBracket)
        guard isClosingBrace else { return true }

        let leftpar: unichar
        switch rightpar {
        case "}".utf16.first!: leftpar = "{".utf16.first!
        case ")".utf16.first!: leftpar = "(".utf16.first!
        case ">".utf16.first!: leftpar = "<".utf16.first!
        default: leftpar = "[".utf16.first!
        }

        let textString = string
        var i = affectedCharRange.location
        var j = 1
        var count = 1

        let prevAtStart: unichar = i > 0 ? textString.character(at: i - 1) : 0
        guard prevAtStart != "\\".utf16.first! && prevAtStart != 0x00a5 else { return true }

        while i > 0 && j < 5000 {
            i -= 1
            j += 1
            let uchar = textString.character(at: i)
            let prev = i > 0 ? textString.character(at: i - 1) : 0
            let notCS = prev != "\\".utf16.first! && prev != 0x00a5
            if uchar == rightpar && notCS {
                count += 1
            } else if uchar == leftpar && notCS {
                count -= 1
            }
            if count == 0 {
                let matchRange = NSRange(location: i, length: 1)
                DispatchQueue.main.async { [weak self] in
                    self?.showIndicator(matchRange)
                }
                break
            }
        }

        return true
    }
}