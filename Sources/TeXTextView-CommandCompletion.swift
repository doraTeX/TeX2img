import AppKit
import Foundation

private func localizedCompletionString(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

extension TeXTextView {
    override func keyDown(with event: NSEvent) {
        if hasMarkedText() {
            super.keyDown(with: event)
            return
        }

        let texChar: unichar = 0x5c
        let profile = controller.currentProfile()
        let commandCompletionKeyTag = profile.integerForKey(CommandCompletionKeyKey)
        let esc: unichar = commandCompletionKeyTag == ESCAPE_KEY ? 0x001B : "\t".utf16.first!
        let commandCompletionChar = String(UnicodeScalar(esc)!)
        let commandCompletionList = controller.commandCompletionList as String?

        if event.characters == commandCompletionChar, event.modifierFlags.contains(.option) {
            doNextBullet(self)
            return
        }
        if event.characters == commandCompletionChar, event.modifierFlags.contains(.control) {
            doPreviousBullet(self)
            return
        }

        if event.characters == commandCompletionChar,
           !event.modifierFlags.contains(.option),
           !hasMarkedText(),
           let commandCompletionList {
            handleCommandCompletion(event: event, commandCompletionList: commandCompletionList, texChar: texChar)
            return
        }

        if wasCompleted {
            originalString = nil
            currentString = nil
            wasCompleted = false
        }

        super.keyDown(with: event)
    }

    private func handleCommandCompletion(event: NSEvent, commandCompletionList: String, texChar: unichar) {
        let textString = string as NSString
        var selectedLocation = selectedRange.location
        var latexString: String?

        if selectedLocation > 0,
           textString.character(at: selectedLocation - 1) == "}".utf16.first!,
           !latexSpecial {
            let charSet = CharacterSet(charactersIn: "\n \t.,;;{}()%\(Character(UnicodeScalar(texChar)!))")
            let foundRange = textString.rangeOfCharacter(
                from: charSet,
                options: .backwards,
                range: NSRange(location: 0, length: selectedLocation - 1)
            )
            if foundRange.location != NSNotFound,
               foundRange.location >= 6,
               textString.character(at: foundRange.location - 6) == texChar,
               textString.substring(with: NSRange(location: foundRange.location - 5, length: 6)) == "begin{" {
                latexSpecial = true
                latexString = textString.substring(
                    with: NSRange(location: foundRange.location, length: selectedLocation - foundRange.location)
                )
            }
        } else {
            latexSpecial = false
        }

        if wasCompleted {
            let currentLength = currentString?.count ?? 0
            if selectedLocation == textLocation,
               textString.length >= replaceLocation + currentLength,
               let currentString,
               textString.substring(with: NSRange(location: replaceLocation, length: currentLength)) == currentString,
               undoManager?.undoActionName == localizedCompletionString("Completion") {
                undoManager?.undo()
                selectedLocation = selectedRange.location
                if selectedLocation >= replaceLocation,
                   let originalString,
                   textString.substring(with: NSRange(location: replaceLocation, length: selectedLocation - replaceLocation)) == originalString {
                    if completionListLocation == NSNotFound {
                        wasCompleted = false
                        super.keyDown(with: event)
                        return
                    }
                } else {
                    undoManager?.redo()
                    selectedLocation = selectedRange.location
                    wasCompleted = false
                }
            } else {
                wasCompleted = false
            }
        }

        if !wasCompleted && !latexSpecial {
            let charSet = CharacterSet(charactersIn: "\n \t.,;;{}()%\(Character(UnicodeScalar(texChar)!))")
            let foundRange = textString.rangeOfCharacter(
                from: charSet,
                options: .backwards,
                range: NSRange(location: 0, length: selectedLocation)
            )

            if foundRange.location != NSNotFound {
                if foundRange.location + 1 == selectedLocation {
                    super.keyDown(with: event)
                    return
                }
                let c = textString.character(at: foundRange.location)
                if c == texChar || c == "{".utf16.first! {
                    replaceLocation = foundRange.location
                } else {
                    replaceLocation = foundRange.location + 1
                }
            } else if selectedLocation == 0 {
                super.keyDown(with: event)
                return
            } else {
                replaceLocation = 0
            }

            originalString = textString.substring(
                with: NSRange(location: replaceLocation, length: selectedLocation - replaceLocation)
            )
            completionListLocation = 0
        }

        var foundCandidate = false
        var newString = ""
        var insRange = NSRange(location: NSNotFound, length: 0)
        var selectlength = 0

        if !latexSpecial {
            while true {
                let searchRange: NSRange
                if !event.modifierFlags.isEmpty && wasCompleted {
                    searchRange = NSRange(location: 0, length: Int(completionListLocation) - 1)
                } else {
                    searchRange = NSRange(
                        location: Int(completionListLocation),
                        length: commandCompletionList.count - Int(completionListLocation)
                    )
                }

                let searchTarget = "\n" + (originalString ?? "")
                let foundRange = (commandCompletionList as NSString).range(
                    of: searchTarget,
                    options: event.modifierFlags.isEmpty ? [] : .backwards,
                    range: searchRange
                )

                if foundRange.location == NSNotFound {
                    foundCandidate = false
                    break
                }

                foundCandidate = true
                var lineRange = foundRange
                lineRange.location += 1
                lineRange.length -= 1
                lineRange = (commandCompletionList as NSString).lineRange(for: lineRange)
                lineRange.length -= 1

                var foundString = (commandCompletionList as NSString).substring(with: lineRange)
                completionListLocation = UInt(lineRange.location)

                let spaceRange = (foundString as NSString).range(of: ":=")
                if spaceRange.location != NSNotFound {
                    foundString = (foundString as NSString).substring(
                        with: NSRange(location: spaceRange.location + 2, length: foundString.count - spaceRange.location - 2)
                    )
                }

                var mutableString = NSMutableString(string: foundString)
                mutableString.replaceOccurrences(
                    of: "#RET#",
                    with: "\n",
                    options: [],
                    range: NSRange(location: 0, length: mutableString.length)
                )

                insRange = mutableString.range(of: "#INS#")
                if insRange.location != NSNotFound {
                    mutableString.replaceCharacters(in: insRange, with: "")
                    let ins2Range = mutableString.range(of: "#INS#")
                    if ins2Range.location != NSNotFound {
                        mutableString.replaceCharacters(in: ins2Range, with: "")
                        selectlength = ins2Range.location - insRange.location
                    }
                }

                newString = mutableString as String
                if newString != originalString {
                    break
                }
            }
        } else if let latexString {
            foundCandidate = true
            let indentString = indentStringForCurrentLocation()
            if !wasCompleted {
                originalString = ""
                replaceLocation = selectedLocation
                newString = "\n\(indentString)\(Character(UnicodeScalar(texChar)!))end\(latexString)\n"
                insRange = NSRange(location: 0, length: 0)
                completionListLocation = UInt(NSNotFound)
            } else if let currentString {
                newString = "\(currentString)\n\(indentString)\(Character(UnicodeScalar(texChar)!))end\(latexString)\n"
                insRange = NSRange(location: currentString.count, length: 0)
            }
        }

        if foundCandidate {
            let replaceRange = NSRange(location: replaceLocation, length: selectedLocation - replaceLocation)
            replaceCharacters(in: replaceRange, with: newString)
            registerUndo(
                with: originalString ?? "",
                location: UInt(replaceLocation),
                length: UInt(newString.count),
                key: localizedCompletionString("Completion")
            )
            resetBackgroundColor(nil)
            currentString = newString
            wasCompleted = true

            selectedRange = NSRange(location: replaceLocation, length: newString.count)
            display()
            Thread.sleep(forTimeInterval: 0.05)

            if insRange.location != NSNotFound {
                textLocation = replaceLocation + insRange.location
            } else {
                textLocation = replaceLocation + newString.count
            }
            selectedRange = NSRange(location: textLocation, length: selectlength)
            scrollRangeToVisible(NSRange(location: textLocation, length: selectlength))
        } else {
            originalString = nil
            currentString = nil
            if !wasCompleted {
                super.keyDown(with: event)
            }
            wasCompleted = false
        }
    }
}