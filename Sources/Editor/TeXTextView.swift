import AppKit
import Foundation
import Quartz

private let importExtensions = ["eps", "pdf", "svg", "svgz", "jpg", "png", "gif", "tiff", "bmp", "tex"]
private let legacyFilenamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")

private func localizedString(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

class TeXTextView: NSTextView {
    @IBOutlet weak var controller: ControllerG!

    weak var dropDelegate: DnDDelegate?

    var autoCompleting = false
    var contentHighlighting = false
    var braceHighlighting = false
    var highlightBracesColorDict: [NSAttributedString.Key: Any]?
    var lastCursorLocation: UInt = 0
    var lastStringLength: UInt = 0
    var autocompletionDictionary: [String: String]?
    var dragging = false
    var currentDragOperation: NSDragOperation = []

    // Command completion state (converted from static variables in the original implementation)
    var wasCompleted = false
    var latexSpecial = false
    var originalString: String?
    var currentString: String?
    var replaceLocation = NSNotFound
    var completionListLocation: UInt = 0
    var textLocation = NSNotFound
    private var selectionChangeObserver: NSObjectProtocol?

    func refreshSelectionHighlighting() {
        textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: self))
    }

    override func awakeFromNib() {
        let autoCompletionPath = "~/Library/TeXShop/Keyboard/autocompletion.plist".expandingTildeInPath
        if FileManager.default.fileExists(atPath: autoCompletionPath) {
            if let dict = NSDictionary(contentsOfFile: autoCompletionPath) as? [String: String] {
                autocompletionDictionary = dict
            }
        } else {
            autocompletionDictionary = nil
        }

        lastCursorLocation = 0
        lastStringLength = 0
        autoCompleting = false
        contentHighlighting = false
        braceHighlighting = false
        dropDelegate = controller
        dragging = false
        currentDragOperation = []

        let layoutManager = MyLayoutManager(controller: controller)
        textContainer?.replaceLayoutManager(layoutManager)

        isContinuousSpellCheckingEnabled = false
        smartInsertDeleteEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticDataDetectionEnabled = false
        isAutomaticLinkDetectionEnabled = false
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isAutomaticTextReplacementEnabled = false

        registerForDraggedTypes([legacyFilenamesType, .pdf])

        selectionChangeObserver = NotificationCenter.default.addObserver(
            forName: NSTextView.didChangeSelectionNotification,
            object: self,
            queue: .main
        ) { [weak self] notification in
            self?.textViewDidChangeSelection(notification)
        }

        if let undoManager = undoManager {
            NotificationCenter.default.addObserver(
                forName: .NSUndoManagerDidUndoChange,
                object: undoManager,
                queue: .main
            ) { [weak self] _ in
                self?.colorizeAfterUndoAndRedo()
            }
            NotificationCenter.default.addObserver(
                forName: .NSUndoManagerDidRedoChange,
                object: undoManager,
                queue: .main
            ) { [weak self] _ in
                self?.colorizeAfterUndoAndRedo()
            }
        }

        guard let menu = menu else { return }

        let index = menu.items.firstIndex { $0.title.isEmpty } ?? menu.items.count
        addUnicodeNormalizationMenu(to: menu, at: index)
        addCharacterInfoMenu(to: menu, at: index)
        addCharacterTypeConversionMenu(to: menu, at: index)
        menu.insertItem(.separator(), at: index)
    }

    private func addUnicodeNormalizationMenu(to menu: NSMenu, at index: Int) {
        guard menu.indexOfItem(withTitle: localizedString("Unicode Normalization")) == -1 else { return }

        let submenu = NSMenu()
        submenu.autoenablesItems = true

        let items: [(Int, String)] = [
            (Int(NFC_Tag), "NFC"),
            (Int(Modified_NFC_Tag), "Modified NFC"),
            (Int(NFD_Tag), "NFD"),
            (Int(Modified_NFD_Tag), "Modified NFD"),
            (Int(NFKC_Tag), "NFKC"),
            (Int(NFKD_Tag), "NFKD"),
            (Int(NFKC_CF_Tag), "NFKC Casefold"),
        ]

        for (tag, title) in items {
            let menuItem = NSMenuItem(title: title, action: #selector(normalizeSelectedString(_:)), keyEquivalent: "")
            menuItem.tag = tag
            submenu.addItem(menuItem)
        }

        let itemWithSubmenu = NSMenuItem(title: localizedString("Unicode Normalization"), action: nil, keyEquivalent: "")
        itemWithSubmenu.submenu = submenu
        menu.insertItem(itemWithSubmenu, at: index)
    }

    private func addCharacterInfoMenu(to menu: NSMenu, at index: Int) {
        guard menu.indexOfItem(withTitle: localizedString("Character Info")) == -1 else { return }
        menu.insertItem(
            withTitle: localizedString("Character Info"),
            action: #selector(showCharacterInfo(_:)),
            keyEquivalent: "",
            at: index
        )
    }

    private func addCharacterTypeConversionMenu(to menu: NSMenu, at index: Int) {
        guard menu.indexOfItem(withTitle: localizedString("Character Type Conversion")) == -1 else { return }

        let submenu = NSMenu()
        submenu.autoenablesItems = true

        let items: [(Int, String)] = [
            (Int(HiraganaToKatakana_Tag), localizedString("Hiragana to Katakana")),
            (Int(KatakanaToHiragana_Tag), localizedString("Katakana to Hiragana")),
            (Int(FullwidthDigitsToHalfwidthDigits_Tag), localizedString("Fullwidth Digits to Halfwidth Digits")),
            (Int(HalfwidthDigitsToFullwidthDigits_Tag), localizedString("Halfwidth Digits to Halfwidth Digits")),
            (Int(FullwidthAlphabetsToHalfwidthAlphabets_Tag), localizedString("Fullwidth Alphabets to Halfwidth Alphabets")),
            (Int(HalfwidthAlphabetsToFullwidthAlphabets_Tag), localizedString("Halfwidth Alphabets to Fullwidth Alphabets")),
            (Int(UnicodeCharactersToAJMacros_Tag), localizedString("Unicode Characters to AJ Macros")),
            (Int(AJMacrosToUnicodeCharacters_Tag), localizedString("AJ Macros to Unicode Characters")),
            (Int(UnicodeCharactersToUTF_Tag), localizedString("Unicode Characters to UTF")),
            (Int(UTFToUnicodeCharacters_Tag), localizedString("UTF to Unicode Characters")),
            (Int(FullwidthQuotesToHalfwidthQuotes_Tag), localizedString("Fullwidth Quotes to Halfwidth Quotes")),
        ]

        for (idx, pair) in items.enumerated() {
            let menuItem = NSMenuItem(title: pair.1, action: #selector(convertCharacterType(_:)), keyEquivalent: "")
            menuItem.tag = pair.0
            submenu.addItem(menuItem)
            if idx % 2 == 1 {
                submenu.addItem(.separator())
            }
        }

        let itemWithSubmenu = NSMenuItem(title: localizedString("Character Type Conversion"), action: nil, keyEquivalent: "")
        itemWithSubmenu.submenu = submenu
        menu.insertItem(itemWithSubmenu, at: index)
    }

    override func viewDidChangeEffectiveAppearance() {
        colorizeText()
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(showCharacterInfo(_:)) {
            return selectedRange.length > 0
        }
        return super.validateMenuItem(menuItem)
    }

    func isValidTeXCommandChar(_ c: unichar) -> Bool {
        if c >= 65 && c <= 90 { return true }
        if c >= 97 && c <= 122 { return true }
        if c == 64, let controller, controller.currentProfile().boolForKey(MakeatletterEnabledKey) { return true }
        return false
    }

    override func copy(_ sender: Any?) {
        let profile = controller.currentProfile()
        let copyAsRichText = profile.boolForKey(RichTextKey)

        guard copyAsRichText else {
            super.copy(sender)
            return
        }

        let foregroundColor = UtilityG.foregroundColor(inProfile: profile)
        let backgroundColor = UtilityG.backgroundColor(inProfile: profile)

        let destStr = NSMutableAttributedString()
        let selectedRange = self.selectedRange
        guard let textStorage else { return }
        destStr.setAttributedString(textStorage.attributedSubstring(from: selectedRange))
        let entireDestLength = destStr.length

        let entireSrcRange = NSRange(location: 0, length: textStorage.length)
        var srcLocation = selectedRange.location
        var destLocation = 0

        while destLocation < entireDestLength {
            var srcRange = NSRange()
            var fgColor = layoutManager?.temporaryAttribute(
                .foregroundColor,
                atCharacterIndex: srcLocation,
                longestEffectiveRange: &srcRange,
                in: entireSrcRange
            ) as? NSColor

            srcRange = NSRange(
                location: srcLocation,
                length: srcRange.length - (srcLocation - srcRange.location)
            )

            if fgColor == nil {
                fgColor = foregroundColor
            }

            let attr: [NSAttributedString.Key: Any] = [
                .foregroundColor: fgColor!,
                .backgroundColor: backgroundColor,
            ]

            let length = srcRange.length
            let destRange = NSRange(
                location: destLocation,
                length: min(length, entireDestLength - destLocation)
            )
            destStr.addAttributes(attr, range: destRange)
            srcLocation += length
            destLocation += length
        }

        let rtfData = destStr.rtf(
            from: NSRange(location: 0, length: destStr.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )

        let pboard = NSPasteboard.general
        pboard.declareTypes([.rtf], owner: nil)
        pboard.clearContents()
        pboard.setData(rtfData, forType: .rtf)
    }

    override func changeFont(_ sender: Any?) {
        super.changeFont(sender)
        fixupTabs()
    }

    func fixupTabs() {
        let currentProfile = controller.currentProfile()

        var paragraphStyle = defaultParagraphStyle?.mutableCopy() as? NSMutableParagraphStyle
        if paragraphStyle == nil {
            paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        }

        guard let paragraphStyle, let font else { return }

        let charWidth = font.advancement(forGlyph: NSGlyph(" ".utf16.first!)).width
        paragraphStyle.defaultTabInterval = charWidth * CGFloat(currentProfile.integerForKey(TabWidthKey))
        paragraphStyle.tabStops = []

        defaultParagraphStyle = paragraphStyle

        var typingAttributes = self.typingAttributes
        typingAttributes[.paragraphStyle] = paragraphStyle
        typingAttributes[.font] = font
        self.typingAttributes = typingAttributes

        let rangeOfChange = NSRange(location: 0, length: string.count)
        shouldChangeText(in: rangeOfChange, replacementString: nil)
        textStorage?.setAttributes(typingAttributes, range: rangeOfChange)
        didChangeText()
    }

    func refreshWordWrap() {
        let currentProfile = controller.currentProfile()
        let wrap = currentProfile.boolForKey(WrapLineKey)

        if wrap {
            enclosingScrollView?.hasHorizontalScroller = false
            isHorizontallyResizable = false
            autoresizingMask = [.width]
            textContainer?.widthTracksTextView = true
            if let contentSize = enclosingScrollView?.contentSize {
                setFrameSize(contentSize)
            }
        } else {
            let maximumSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            enclosingScrollView?.contentView.autoresizesSubviews = true
            enclosingScrollView?.hasHorizontalScroller = true
            textContainer?.containerSize = maximumSize
            textContainer?.widthTracksTextView = false
            maxSize = maximumSize
            isHorizontallyResizable = true
        }
    }

    private func colorizeAfterUndoAndRedo() {
        colorizeText()
    }

    func registerUndo(with oldString: String, location oldLocation: UInt, length newLength: UInt, key: String) {
        guard let undoManager = undoManager else { return }
        let dictionary: [String: Any] = [
            "oldString": oldString,
            "oldLocation": oldLocation,
            "oldLength": newLength,
            "undoKey": key,
        ]
        undoManager.registerUndo(withTarget: self) { target in
            (target as? TeXTextView)?.undoSpecial(dictionary)
        }
        undoManager.setActionName(key)
    }

    private func undoSpecial(_ theDictionary: [String: Any]) {
        guard let oldLocation = theDictionary["oldLocation"] as? UInt,
              let oldLength = theDictionary["oldLength"] as? UInt,
              let newString = theDictionary["oldString"] as? String,
              let undoKey = theDictionary["undoKey"] as? String else { return }

        var undoRange = NSRange(location: Int(oldLocation), length: Int(oldLength))
        if undoRange.location + undoRange.length > string.count { return }

        let oldString = string.substring(with: undoRange)
        replaceCharacters(in: undoRange, with: newString)
        registerUndo(with: oldString, location: UInt(undoRange.location), length: UInt(newString.count), key: undoKey)
        resetBackgroundColor(nil)
    }

    private func insertSpecialNonStandard(_ theString: String, undoKey key: String) {
        var stringBuf = theString
        let oldRange = selectedRange
        let oldString = string.substring(with: oldRange)

        stringBuf = stringBuf.replacingOccurrences(of: "#SEL#", with: oldString)

        var searchRange = stringBuf.range(of: "#INS#", options: .literal)
        if searchRange.location != NSNotFound {
            stringBuf = stringBuf.replacingCharacters(in: searchRange, with: "")
        }

        let newString = stringBuf
        replaceCharacters(in: oldRange, with: newString)
        registerUndo(with: oldString, location: UInt(oldRange.location), length: UInt(newString.count), key: key)

        colorizeText()

        if searchRange.location != NSNotFound {
            searchRange.location += oldRange.location
            searchRange.length = 0
            selectedRange = searchRange
        }
    }

    override func insertText(_ string: Any, replacementRange: NSRange) {
        guard let theString = string as? String else {
            super.insertText(string, replacementRange: replacementRange)
            return
        }

        let currentProfile = controller.currentProfile()
        let texChar: unichar = 0x5c

        if theString == "¥", currentProfile.boolForKey(ConvertYenMarkKey) {
            super.insertText("\\", replacementRange: replacementRange)
        } else if theString.count == 1,
                  currentProfile.boolForKey(AutoCompleteKey),
                  let autocompletionDictionary,
                  let firstChar = theString.utf16.first {
            if firstChar >= 128
                || selectedRange.location == 0
                || self.string.character(at: selectedRange.location - 1) != texChar {
                if let completionString = autocompletionDictionary[theString] {
                    autoCompleting = true
                    insertSpecialNonStandard(completionString, undoKey: localizedString("Auto Completion"))
                    autoCompleting = false
                    return
                }
            }
            super.insertText(string, replacementRange: replacementRange)
        } else {
            super.insertText(string, replacementRange: replacementRange)
        }
        colorizeText()
    }

    func insertText(withIndicator aString: Any) {
        insertText(aString, replacementRange: selectedRange)

        guard let theString = aString as? String else { return }
        let length = theString.count
        showFindIndicator(for: NSRange(location: selectedRange.location - length, length: length))
    }

    override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        let currentProfile = controller.currentProfile()

        if type == .string, currentProfile.boolForKey(ConvertYenMarkKey) {
            guard let pasteboardString = pboard.string(forType: .string) else { return false }
            let string = NSMutableString(string: pasteboardString)
            string.replaceYenWithBackSlash()

            let selectedRange = self.selectedRange
            if shouldChangeText(in: selectedRange, replacementString: string as String) {
                replaceCharacters(in: selectedRange, with: string as String)
                didChangeText()
            }
            colorizeText()
            return true
        }

        if type == .pdf, self === controller.sourceTextView {
            guard let data = pboard.data(forType: .pdf),
                  let doc = PDFDocument(data: data) else { return false }
            return controller.importSource(fromFilePathOrPDFDocument: doc, skipConfirm: false)
        }

        return super.readSelection(from: pboard, type: type)
    }

    func setEnabled(_ enabled: Bool) {
        isSelectable = enabled
        isEditable = enabled

        if enabled {
            colorizeText()
        } else {
            textColor = .disabledControlTextColor
        }
    }

    @IBAction func doCommentOrIndent(_ sender: NSMenuItem) {
        let text = string
        let oldRange = selectedRange

        var blockStart: Int = 0
        var blockEnd: Int = 0
        text.getLineStart(&blockStart, end: &blockEnd, contentsEnd: nil, for: oldRange)

        var modifyRange = NSRange(location: blockStart, length: blockEnd - blockStart)
        let oldString = string.substring(with: modifyRange)

        var lineStart = blockStart
        var firstLine = true
        var fixRangeStart = false
        var increment = 0
        var theCommand: String?

        let aProfile = controller.currentProfile()
        let useTabForIndent = aProfile.boolForKey(TabIndentKey)
        let tabWidth = aProfile.integerForKey(TabWidthKey)

        repeat {
            modifyRange = NSRange(location: lineStart, length: 0)
            var lineEnd = 0
            var lineContentsEnd = 0
            text.getLineStart(nil, end: &lineEnd, contentsEnd: &lineContentsEnd, for: modifyRange)

            switch sender.tag {
            case Int(CommentOutTag):
                replaceCharacters(in: modifyRange, with: "%")
                blockEnd += 1
                lineEnd += 1
                increment += 1
                theCommand = localizedString("CommentOut")

            case Int(UncommentTag):
                var theChar: unichar = 0
                if lineStart < lineContentsEnd {
                    theChar = text.character(at: lineStart)
                } else if firstLine {
                    fixRangeStart = true
                    break
                } else {
                    break
                }

                if theChar == "%".utf16.first! {
                    modifyRange.length = 1
                    replaceCharacters(in: modifyRange, with: "")
                    blockEnd -= 1
                    lineEnd -= 1
                    increment -= 1
                    if oldRange.location == blockStart && firstLine {
                        fixRangeStart = true
                    }
                    theCommand = localizedString("Uncomment")
                } else if firstLine {
                    fixRangeStart = true
                }

            case Int(ShiftRightTag):
                var indentString = ""
                if tabWidth > 0 {
                    indentString = String(repeating: " ", count: tabWidth)
                }
                if useTabForIndent {
                    replaceCharacters(in: modifyRange, with: "\t")
                    blockEnd += 1
                    lineEnd += 1
                    increment += 1
                } else {
                    replaceCharacters(in: modifyRange, with: indentString)
                    blockEnd += tabWidth
                    lineEnd += tabWidth
                    increment += tabWidth
                }
                theCommand = localizedString("Indent")

            case Int(ShiftLeftTag):
                var theChar: unichar = 0
                if lineStart < lineContentsEnd {
                    theChar = text.character(at: lineStart)
                } else if firstLine {
                    fixRangeStart = true
                    break
                } else {
                    break
                }

                if !useTabForIndent, theChar == " ".utf16.first! {
                    modifyRange = NSRange(location: lineStart, length: 1)
                    replaceCharacters(in: modifyRange, with: "")
                    blockEnd -= 1
                    lineEnd -= 1
                    increment -= 1

                    var i = 1
                    var nextChar = text.character(at: lineStart + 1)
                    while lineStart + i < lineContentsEnd, i < tabWidth, nextChar == " ".utf16.first! {
                        modifyRange = NSRange(location: lineStart, length: 1)
                        replaceCharacters(in: modifyRange, with: "")
                        blockEnd -= 1
                        lineEnd -= 1
                        increment -= 1
                        i += 1
                        if lineStart + 1 < text.length {
                            nextChar = text.character(at: lineStart + 1)
                        }
                    }
                    if oldRange.location == blockStart && firstLine {
                        fixRangeStart = true
                    }
                    theCommand = localizedString("Unindent")
                } else if useTabForIndent, theChar == "\t".utf16.first! {
                    modifyRange.length = 1
                    replaceCharacters(in: modifyRange, with: "")
                    blockEnd -= 1
                    lineEnd -= 1
                    increment -= 1
                    if oldRange.location == blockStart && firstLine {
                        fixRangeStart = true
                    }
                    theCommand = localizedString("Unindent")
                } else if firstLine {
                    fixRangeStart = true
                }

            default:
                break
            }

            lineStart = lineEnd
            firstLine = false
        } while lineStart < blockEnd

        guard let theCommand else { return }

        modifyRange = NSRange(location: blockStart, length: blockEnd - blockStart)
        selectedRange = modifyRange

        registerUndo(with: oldString, location: UInt(modifyRange.location), length: UInt(modifyRange.length), key: theCommand)

        var rangeIncrement = increment + (increment > 0 ? -1 : 1)
        var updatedOldRange = oldRange

        if fixRangeStart {
            rangeIncrement -= 1
        } else {
            updatedOldRange.location += increment > 0 ? 1 : -1
        }

        if !(updatedOldRange.length == 0 && rangeIncrement < 0) {
            updatedOldRange.length += rangeIncrement
        }

        selectedRange = updatedOldRange

        let updatedText = self.string
        updatedText.getLineStart(&blockStart, end: &blockEnd, contentsEnd: nil, for: selectedRange)
        modifyRange = NSRange(location: blockStart, length: blockEnd - blockStart)
        selectedRange = modifyRange

        colorizeText()
    }

    func replaceEntireContents(with contents: String) {
        insertText(contents, replacementRange: NSRange(location: 0, length: textStorage!.length))
        selectedRange = NSRange(location: 0, length: 0)
        scrollRangeToVisible(NSRange(location: 0, length: 0))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.colorizeText()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.colorizeText()
        }
    }

    @IBAction func closeCurrentEnvironment(_ sender: Any?) {
        autoCompleting = true

        let oldRange = selectedRange
        let regex = try? NSRegularExpression(pattern: #"\\(begin|end)\{(.*?)\}"#, options: [])
        let target = textStorage!.string.substring(to: oldRange.location)
        let matches = regex?.matches(in: target, options: [], range: NSRange(location: 0, length: target.count)) ?? []

        var newString: String?
        var environmentStack = [String: Int]()

        for match in matches.reversed() {
            let range1 = match.range(at: 1)
            let range2 = match.range(at: 2)

            let prefix = range1.location == NSNotFound ? "" : target.substring(with: range1)
            let environment = range2.location == NSNotFound ? "" : target.substring(with: range2)
            let increment = prefix == "end" ? 1 : -1

            if let count = environmentStack[environment] {
                if increment == 1 {
                    environmentStack[environment] = count + 1
                } else if count > 0 {
                    environmentStack[environment] = count - 1
                } else {
                    newString = environment
                    break
                }
            } else if increment == 1 {
                environmentStack[environment] = 1
            } else {
                newString = environment
                break
            }
        }

        if let newString {
            let insertion = "\\end{\(newString)}"
            if shouldChangeText(in: oldRange, replacementString: insertion) {
                replaceCharacters(in: oldRange, with: insertion)
                didChangeText()
                undoManager?.setActionName(localizedString("Close Current Environment"))
            }
        } else {
            NSSound.beep()
        }

        autoCompleting = false
    }

    @IBAction func showCharacterInfo(_ sender: Any?) {
        let selectedRange = self.selectedRange
        guard selectedRange.length > 0 else {
            NSSound.beep()
            return
        }

        let selectedString = string.substring(with: selectedRange)
        guard let popoverController = MyGlyphPopoverController(character: selectedString) else { return }

        let glyphRange = layoutManager!.glyphRange(forCharacterRange: selectedRange, actualCharacterRange: nil)
        var selectedRect = layoutManager!.boundingRect(forGlyphRange: glyphRange, in: textContainer!)
        let containerOrigin = textContainerOrigin
        selectedRect.origin.x += containerOrigin.x
        selectedRect.origin.y += containerOrigin.y - 6.0
        selectedRect = convertToLayer(selectedRect)

        popoverController.showPopover(relativeTo: selectedRect, of: self)
        showFindIndicator(for: selectedRange)
    }

    @IBAction func convertCharacterType(_ sender: NSMenuItem) {
        var selectedRange = self.selectedRange

        if selectedRange.length <= 0 {
            guard UtilityG.runConfirmPanel(message: localizedString("Do you apply it to the entire document?")) else { return }
            selectAll(sender)
            selectedRange = self.selectedRange
        }

        let selectedString = string.substring(with: selectedRange)
        let newString: String
        let undoKey: String?

        switch sender.tag {
        case Int(HiraganaToKatakana_Tag):
            newString = selectedString.stringByReplacingHiraganaWithKatakana()
            undoKey = localizedString("Hiragana to Katakana")
        case Int(KatakanaToHiragana_Tag):
            newString = selectedString.stringByReplacingKatakanaWithHiragana()
            undoKey = localizedString("Katakana to Hiragana")
        case Int(FullwidthDigitsToHalfwidthDigits_Tag):
            newString = selectedString.stringByReplacingFullwidthDigitsWithHalfwidthDigits()
            undoKey = localizedString("Fullwidth Digits to Halfwidth Digits")
        case Int(HalfwidthDigitsToFullwidthDigits_Tag):
            newString = selectedString.stringByReplacingHalfwidthDigitsWithFullwidthDigits()
            undoKey = localizedString("Halfwidth Digits to Fullwidth Digits")
        case Int(FullwidthAlphabetsToHalfwidthAlphabets_Tag):
            newString = selectedString.stringByReplacingFullwidthAlphabetsWithHalfwidthAlphabets()
            undoKey = localizedString("Fullwidth Alphabets to Halfwidth Alphabets")
        case Int(HalfwidthAlphabetsToFullwidthAlphabets_Tag):
            newString = selectedString.stringByReplacingHalfwidthAlphabetsWithFullwidthAlphabets()
            undoKey = localizedString("Halfwidth Alphabets to Fullwidth Alphabets")
        case Int(UnicodeCharactersToAJMacros_Tag):
            newString = selectedString.stringByReplacingUnicodeCharactersWithAjMacros()
            undoKey = localizedString("Unicode Characters to AJ Macros")
        case Int(AJMacrosToUnicodeCharacters_Tag):
            newString = selectedString.stringByReplacingAjMacrosWithUnicodeCharacters()
            undoKey = localizedString("AJ Macros to Unicode Characters")
        case Int(UnicodeCharactersToUTF_Tag):
            newString = selectedString.stringByReplacingUnicodeCharactersWithUTF()
            undoKey = localizedString("Unicode Characters to UTF")
        case Int(UTFToUnicodeCharacters_Tag):
            newString = selectedString.stringByReplacingUTFWithUnicodeCharacters()
            undoKey = localizedString("UTF to Unicode Characters")
        case Int(FullwidthQuotesToHalfwidthQuotes_Tag):
            newString = selectedString.stringByReplacingFullwidthQuotesWithHalfwidthQuotes()
            undoKey = localizedString("Fullwidth Quotes to Halfwidth Quotes")
        default:
            newString = selectedString as String
            undoKey = nil
        }

        guard let undoKey else {
            NSSound.beep()
            return
        }

        replaceCharacters(in: selectedRange, with: newString)
        registerUndo(with: selectedString as String, location: UInt(selectedRange.location), length: UInt(newString.count), key: undoKey)
        undoManager?.setActionName(undoKey)
        self.selectedRange = NSRange(location: selectedRange.location, length: newString.count)
    }

    @IBAction func normalizeSelectedString(_ sender: NSMenuItem) {
        var selectedRange = self.selectedRange

        if selectedRange.length <= 0 {
            guard UtilityG.runConfirmPanel(message: localizedString("Do you apply it to the entire document?")) else { return }
            selectAll(sender)
            selectedRange = self.selectedRange
        }

        let selectedString = string.substring(with: selectedRange)
        let newString: String
        let undoKey: String?

        switch sender.tag {
        case Int(NFC_Tag):
            newString = selectedString.precomposedStringWithCanonicalMapping
            undoKey = "NFC"
        case Int(Modified_NFC_Tag):
            newString = selectedString.normalizedStringWithModifiedNFC()
            undoKey = "Modified NFC"
        case Int(NFD_Tag):
            newString = selectedString.decomposedStringWithCanonicalMapping
            undoKey = "NFD"
        case Int(Modified_NFD_Tag):
            newString = selectedString.normalizedStringWithModifiedNFD()
            undoKey = "Modified NFD"
        case Int(NFKC_Tag):
            newString = selectedString.precomposedStringWithCompatibilityMapping
            undoKey = "NFKC"
        case Int(NFKD_Tag):
            newString = selectedString.decomposedStringWithCompatibilityMapping
            undoKey = "NFKD"
        case Int(NFKC_CF_Tag):
            newString = selectedString.normalizedStringWithNFKC_CF()
            undoKey = "NFKC Casefold"
        default:
            newString = selectedString as String
            undoKey = nil
        }

        guard let undoKey else {
            NSSound.beep()
            return
        }

        replaceCharacters(in: selectedRange, with: newString)
        registerUndo(with: selectedString as String, location: UInt(selectedRange.location), length: UInt(newString.count), key: undoKey)
        undoManager?.setActionName(undoKey)
        self.selectedRange = NSRange(location: selectedRange.location, length: newString.count)
        showCharacterInfo(nil)
    }

    @IBAction func insertNewpage(_ sender: NSMenuItem) {
        let textToInsert = "\\newpage\n\n"
        let actionName = localizedString("Insert Newpage")
        let currentRange = selectedRange
        let oldString = string.substring(with: currentRange)

        replaceCharacters(in: currentRange, with: textToInsert)
        registerUndo(with: oldString, location: UInt(currentRange.location), length: UInt(textToInsert.count), key: actionName)
        colorizeText()
    }

    override func insertNewline(_ sender: Any?) {
        let autoIndent = controller.currentProfile().boolForKey(AutoIndentKey)

        if autoIndent {
            let indentString = indentStringForCurrentLocation()
            super.insertNewline(sender)
            insertText(indentString, replacementRange: selectedRange)
        } else {
            super.insertNewline(sender)
        }
    }

    func indentStringForCurrentLocation() -> String {
        let selectedRange = self.selectedRange
        let stringToCurrentLocation = "\n" + textStorage!.string.substring(to: selectedRange.location)
        let regex = try? NSRegularExpression(pattern: "\\n([ \t]*)[^\\n]*$", options: [])
        let match = regex?.firstMatch(in: stringToCurrentLocation, options: [], range: NSRange(location: 0, length: stringToCurrentLocation.count))
        guard let match else { return "" }
        return stringToCurrentLocation.substring(with: match.range(at: 1))
    }

    override func selectionRange(
        forProposedRange proposedSelRange: NSRange,
        granularity: NSSelectionGranularity
    ) -> NSRange {
        let textString = string

        var replacementRange = super.selectionRange(forProposedRange: proposedSelRange, granularity: granularity)
        let makeatletterEnabled = controller?.currentProfile().boolForKey(MakeatletterEnabledKey) ?? true
        let backslash: unichar = 0x5c

        if granularity == .selectByWord {
            if replacementRange.location < textString.length {
                let c = textString.character(at: replacementRange.location)
                if c != "{".utf16.first! && c != "(".utf16.first! && c != "[".utf16.first!
                    && c != "<".utf16.first! && c != " ".utf16.first! {
                    var flag = false
                    repeat {
                        if replacementRange.location >= 1 {
                            let prev = textString.character(at: replacementRange.location - 1)
                            if (prev >= 65 && prev <= 90) || (prev >= 97 && prev <= 122)
                                || (prev == "@".utf16.first! && makeatletterEnabled) {
                                replacementRange.location -= 1
                                replacementRange.length += 1
                                flag = true
                            } else {
                                flag = false
                            }
                        } else {
                            flag = false
                        }
                    } while flag

                    repeat {
                        if replacementRange.location + replacementRange.length < textString.length {
                            let next = textString.character(at: replacementRange.location + replacementRange.length)
                            if (next >= 65 && next <= 90) || (next >= 97 && next <= 122)
                                || (next == "@".utf16.first! && makeatletterEnabled) {
                                replacementRange.length += 1
                                flag = true
                            } else {
                                flag = false
                            }
                        } else {
                            flag = false
                        }
                    } while flag
                }
            }

            if replacementRange.location >= 1,
               textString.character(at: replacementRange.location - 1) == backslash {
                replacementRange.location -= 1
                replacementRange.length += 1
                return replacementRange
            }
        }

        if proposedSelRange.length != 0 || granularity != .selectByWord {
            return replacementRange
        }

        let length = textString.length
        var i = proposedSelRange.location
        guard i < length else { return replacementRange }

        var uchar = textString.character(at: i)

        if uchar == "}".utf16.first! || uchar == ")".utf16.first!
            || uchar == "]".utf16.first! || uchar == ">".utf16.first! {
            let j = i
            let rightpar = uchar
            let leftpar: unichar
            switch rightpar {
            case "}".utf16.first!: leftpar = "{".utf16.first!
            case ")".utf16.first!: leftpar = "(".utf16.first!
            case ">".utf16.first!: leftpar = "<".utf16.first!
            default: leftpar = "[".utf16.first!
            }

            var nestingLevel = 1
            var done = false
            while i > 0 && !done {
                i -= 1
                uchar = textString.character(at: i)
                if uchar == rightpar {
                    nestingLevel += 1
                } else if uchar == leftpar {
                    nestingLevel -= 1
                }
                if nestingLevel == 0 {
                    done = true
                    replacementRange = NSRange(location: i, length: j - i + 1)
                }
            }
        } else if uchar == "{".utf16.first! || uchar == "(".utf16.first!
            || uchar == "[".utf16.first! || uchar == "<".utf16.first! {
            let j = i
            let leftpar = uchar
            let rightpar: unichar
            switch leftpar {
            case "{".utf16.first!: rightpar = "}".utf16.first!
            case "(".utf16.first!: rightpar = ")".utf16.first!
            case "<".utf16.first!: rightpar = ">".utf16.first!
            default: rightpar = "]".utf16.first!
            }

            var nestingLevel = 1
            var done = false
            while i < length - 1 && !done {
                i += 1
                uchar = textString.character(at: i)
                if uchar == leftpar {
                    nestingLevel += 1
                } else if uchar == rightpar {
                    nestingLevel -= 1
                }
                if nestingLevel == 0 {
                    done = true
                    replacementRange = NSRange(location: j, length: i - j + 1)
                }
            }
        }

        return replacementRange
    }

    override var readablePasteboardTypes: [NSPasteboard.PasteboardType] {
        var types = super.readablePasteboardTypes
        types.append(.pdf)
        return types
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if dragging {
            NSColor.selectedControlColor.set()
            let path = NSBezierPath(rect: dirtyRect)
            path.lineWidth = 2.0
            path.stroke()
        }
    }

    override func prepareForDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        true
    }

    private func filelist(in info: any NSDraggingInfo) -> [String] {
        info.draggingPasteboard.propertyList(forType: legacyFilenamesType) as? [String] ?? []
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard self === controller.sourceTextView else { return [] }

        let pboard = sender.draggingPasteboard

        if pboard.types?.contains(.pdf) == true {
            guard let data = pboard.data(forType: .pdf),
                  let doc = PDFDocument(data: data),
                  let page = doc.page(at: 0) else { return [] }

            for annotation in page.annotations where Utility.isTeX2imgAnnotation(annotation) {
                draggingState = true
                return currentDragOperation
            }
            return []
        }

        let draggedFiles = filelist(in: sender)
        guard draggedFiles.count == 1 else { return [] }

        let draggedFilePath = draggedFiles[0]
        let fileURL = URL(fileURLWithPath: draggedFilePath)
        guard FileManager.default.fileExists(atPath: draggedFilePath) else { return [] }
        guard !FileManager.default.isDirectory(atPath: draggedFilePath) else { return [] }

        let ext = fileURL.pathExtension
        guard importExtensions.contains(ext) else { return [] }

        draggingState = true
        return currentDragOperation
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        draggingState = false
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        currentDragOperation
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard

        if pboard.types?.contains(.pdf) == true {
            guard let data = pboard.data(forType: .pdf),
                  let doc = PDFDocument(data: data) else { return false }
            dropDelegate?.textViewDroppedFile(doc)
        } else {
            dropDelegate?.textViewDroppedFile(filelist(in: sender)[0])
        }
        return true
    }

    override func concludeDragOperation(_ sender: (any NSDraggingInfo)?) {
        draggingState = false
    }

    var draggingState: Bool {
        get { dragging }
        set { setDraggingState(newValue) }
    }

    private func setDraggingState(_ draggingState: Bool) {
        if draggingState {
            dragging = true
            currentDragOperation = .copy
        } else {
            dragging = false
            currentDragOperation = []
        }
        needsDisplay = true
    }
}