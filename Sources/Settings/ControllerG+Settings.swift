import AppKit

/// Rows whose availability follows another setting.
enum SettingsDependentRow: Hashable {
    case pageBox, animationDelay, animationLoop, autoPaste, ungroup
}

extension ControllerG {
    /// Creates the controls of the settings window. ControllerG reads and writes profiles through them.
    func buildSettingsWindow() {
        func label(_ key: String) -> String { NSLocalizedString(key, comment: "") }
        let changed = #selector(preferencesChanged(_:))
        let refresh = #selector(refreshTextView(_:))

        func makeSwitch(_ action: Selector? = nil) -> NSSwitch {
            SettingsUI.makeSwitch(target: action == nil ? nil : self, action: action)
        }
        // The name is shown when the value is invalid at generation.
        func numberPair(_ name: String, min: Double, max: Double, fraction: Int = 0, increment: Double = 1) -> (NSTextField, NSStepper) {
            let field = SettingsUI.makeNumberField(minimum: min, maximum: max, fractionDigits: fraction)
            field.toolTip = name
            let stepper = SettingsUI.makeStepper(minimum: min, maximum: max, increment: increment)
            let integer = fraction == 0
            stepper.target = field
            stepper.action = integer ? #selector(NSControl.takeIntValueFrom(_:)) : #selector(NSControl.takeFloatValueFrom(_:))
            field.target = stepper
            field.action = integer ? #selector(NSControl.takeIntValueFrom(_:)) : #selector(NSControl.takeFloatValueFrom(_:))
            return (field, stepper)
        }

        // MARK: General
        autoRestoreCheckBox = makeSwitch()
        updateCheckSwitch = makeSwitch(#selector(automaticUpdateCheckChanged(_:)))
        updateCheckSwitch.state = UserDefaults.standard.bool(forKey: "SUEnableAutomaticChecks") ? .on : .off
        cuiToolStatusView = NSImageView()
        cuiToolStatusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([cuiToolStatusView.widthAnchor.constraint(equalToConstant: 14), cuiToolStatusView.heightAnchor.constraint(equalToConstant: 14)])
        cuiToolStatusTextField = NSTextField(labelWithString: "")
        cuiToolStatusTextField.textColor = .secondaryLabelColor
        cuiToolStatusTextField.lineBreakMode = .byTruncatingMiddle
        cuiToolStatusTextField.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(250), for: .horizontal)
        cuiToolInstallButton = SettingsUI.makeButton(label("Install..."), target: self, action: #selector(installCUITool(_:)))
        let general = SettingsUI.pane(header: header("General"), groups: [
            SettingsUI.group(label("Launch"), [SettingsUI.row(label("Restore the source of the last session"), autoRestoreCheckBox)]),
            SettingsUI.group(label("Software Update"), [SettingsUI.row(label("Automatically check for updates"), updateCheckSwitch)]),
            SettingsUI.group(label("Command Line Tool"), [
                SettingsUI.row("tex2img", SettingsUI.hstack([cuiToolStatusView, cuiToolStatusTextField, cuiToolInstallButton], spacing: 6)),
            ]),
            SettingsUI.group(label("Settings Profiles"), [
                SettingsUI.row(label("Saved settings"), note: label("Save the current settings under a name and load them later."),
                               SettingsUI.makeButton(label("Manage Profiles…"), target: self, action: #selector(showProfilesWindow(_:)))),
            ]),
        ])

        // MARK: Image
        unitPopUp = SettingsUI.makePopUp([("px", 1), ("bp", 2)])
        var marginRows = [SettingsUI.row(label("Unit"), note: label("Vector images always use bp (big point)."), unitPopUp)]
        (topMarginTextField, topMarginStepper) = numberPair(label("Margins") + " (" + label("Top") + ")", min: 0, max: 1000)
        (bottomMarginTextField, bottomMarginStepper) = numberPair(label("Margins") + " (" + label("Bottom") + ")", min: 0, max: 1000)
        (leftMarginTextField, leftMarginStepper) = numberPair(label("Margins") + " (" + label("Left") + ")", min: 0, max: 1000)
        (rightMarginTextField, rightMarginStepper) = numberPair(label("Margins") + " (" + label("Right") + ")", min: 0, max: 1000)
        for (title, field, stepper) in [("Top", topMarginTextField!, topMarginStepper!), ("Bottom", bottomMarginTextField!, bottomMarginStepper!),
                                        ("Left", leftMarginTextField!, leftMarginStepper!), ("Right", rightMarginTextField!, rightMarginStepper!)] {
            marginRows.append(SettingsUI.row(label(title), SettingsUI.numberAccessory(field: field, stepper: stepper, unit: nil)))
        }
        keepPageSizeCheckBox = makeSwitch(changed)
        pageBoxPopUp = SettingsUI.makePopUp([("MediaBox", 0), ("CropBox", 1), ("BleedBox", 2), ("TrimBox", 3), ("ArtBox", 4)])
        let pageBoxRow = SettingsUI.row(label("Page box"), pageBoxPopUp, indent: 1)
        (resolutionTextField, resolutionStepper) = numberPair(label("Resolution level"), min: 1, max: 100, fraction: 3)
        (dpiTextField, dpiStepper) = numberPair(label("Resolution"), min: 1, max: 10000, fraction: 3)
        fillColorWell = SettingsUI.makeColorWell(target: self, action: #selector(colorSettingChanged(_:)))
        transparentCheckBox = makeSwitch()
        textPdfCheckBox = makeSwitch()
        deleteDisplaySizeCheckBox = makeSwitch()
        plainTextCheckBox = makeSwitch()
        mergeOutputsCheckBox = makeSwitch(changed)
        (delayTextField, delayStepper) = numberPair(label("Delay between frames"), min: 0, max: 9999, fraction: 3, increment: 0.1)
        (loopCountTextField, loopCountStepper) = numberPair(label("Loop count"), min: 0, max: 9999)
        let delayRow = SettingsUI.row(label("Delay between frames"), SettingsUI.numberAccessory(field: delayTextField, stepper: delayStepper, unit: label("sec")), indent: 1)
        let loopRow = SettingsUI.row(label("Loop count"), note: label("0 repeats forever."), SettingsUI.numberAccessory(field: loopCountTextField, stepper: loopCountStepper, unit: nil), indent: 1)
        let image = SettingsUI.pane(header: header("Image"), groups: [
            SettingsUI.group(label("Margins"), marginRows),
            SettingsUI.group(label("Page Size"), [SettingsUI.row(label("Keep the original page size"), keepPageSizeCheckBox), pageBoxRow]),
            SettingsUI.group(label("Bitmap Images"), [
                SettingsUI.row(label("Resolution level"), note: "1–100", SettingsUI.numberAccessory(field: resolutionTextField, stepper: resolutionStepper, unit: nil)),
                SettingsUI.row(label("Resolution"), SettingsUI.numberAccessory(field: dpiTextField, stepper: dpiStepper, unit: "dpi")),
            ]),
            SettingsUI.group(label("Background"), [
                SettingsUI.row(label("Background color"), fillColorWell),
                SettingsUI.row(label("Transparent background (if possible)"), transparentCheckBox),
            ]),
            SettingsUI.group(label("Format-specific Settings"), [
                SettingsUI.row(label("Keep text"), note: "PDF / SVG / SVGZ", textPdfCheckBox),
                SettingsUI.row(label("Remove width and height attributes"), note: "SVG / SVGZ", deleteDisplaySizeCheckBox),
                SettingsUI.row(label("Output as plain text"), note: "EPS", plainTextCheckBox),
                SettingsUI.row(label("Make a single file or an animation"), note: "PDF / TIFF / GIF / SVG / SVGZ", mergeOutputsCheckBox),
                delayRow, loopRow,
            ]),
        ])

        // MARK: Conversion
        latexPathTextField = pathField()
        dviDriverPathTextField = pathField()
        gsPathTextField = pathField()
        autoDetectionTargetPopUp = SettingsUI.makePopUp(["pdfLaTeX", "pLaTeX + dvipdfmx", "upLaTeX + dvipdfmx", "XeLaTeX (Japanese)", "LuaLaTeX (Japanese)",
                                                         "LaTeX + dvips + gs", "pLaTeX + dvips + gs", "upLaTeX + dvips + gs"].enumerated().map { ($1, $0 + 1) })
        let detectButton = SettingsUI.makeButton(label("Detect…"), target: self, action: #selector(searchPrograms(_:)))
        (numberOfCompilationTextField, numberOfCompilationStepper) = numberPair(label("Maximum number of compilations"), min: 1, max: 10)
        guessCompilationButton = makeSwitch()
        ignoreErrorCheckBox = makeSwitch()
        encodingPopUpButton = SettingsUI.makePopUp([(label("Not specified"), 0), ("UTF-8", 1), ("Shift_JIS", 2), ("JIS", 3), ("EUC-JP", 4)])
        utfExportCheckBox = makeSwitch()
        priorityPopUp = SettingsUI.makePopUp([(label("Quality (recommended)"), 1), (label("Speed"), 2)])
        workInInputFileDirectoryCheckBox = makeSwitch()
        let conversion = SettingsUI.pane(header: header("Conversion"), groups: [
            SettingsUI.group(label("Programs"), [
                SettingsUI.row("LaTeX", latexPathTextField, wide: true),
                SettingsUI.row(label("DVI driver"), dviDriverPathTextField, wide: true),
                SettingsUI.row("Ghostscript", gsPathTextField, wide: true),
                SettingsUI.row(label("Detect programs for"), SettingsUI.hstack([autoDetectionTargetPopUp, detectButton])),
            ]),
            SettingsUI.group(label("Compilation"), [
                SettingsUI.row(label("Maximum number of compilations"), SettingsUI.numberAccessory(field: numberOfCompilationTextField, stepper: numberOfCompilationStepper, unit: nil)),
                SettingsUI.row(label("Guess the number of compilations"), guessCompilationButton),
                SettingsUI.row(label("Force conversion by ignoring minor compilation errors"), note: label("Not recommended."), ignoreErrorCheckBox),
            ]),
            SettingsUI.group(label("Characters"), [
                SettingsUI.row(label("Kanji encoding"), encodingPopUpButton),
                SettingsUI.row(label("Substitute \\UTF / \\CID for characters outside JIS X 0208"), utfExportCheckBox),
            ]),
            SettingsUI.group(label("Processing"), [
                SettingsUI.row(label("Priority in conversion"), priorityPopUp),
                SettingsUI.row(label("Work in the folder of the input file"), note: label("When a source file is used as input."), workInInputFileDirectoryCheckBox),
            ]),
        ])

        // MARK: After Generation
        sendNotificationCheckBox = makeSwitch()
        showOutputWindowCheckBox = makeSwitch()
        previewCheckBox = makeSwitch()
        deleteTmpFileCheckBox = makeSwitch()
        embedSourceCheckBox = makeSwitch()
        toClipboardCheckBox = makeSwitch(changed)
        autoPasteCheckBox = makeSwitch(changed)
        autoPasteDestinationPopUpButton = SettingsUI.makePopUp(["Microsoft Word", "Microsoft PowerPoint", "Pages", "Numbers", "Keynote"].enumerated().map { ($1, $0 + 1) })
        embedInIllustratorCheckBox = makeSwitch(changed)
        ungroupCheckBox = makeSwitch()
        let autoPasteRow = SettingsUI.row(label("Paste automatically into"), note: label("PDF is recommended."),
                                          SettingsUI.hstack([autoPasteDestinationPopUpButton, autoPasteCheckBox]), indent: 1)
        let ungroupRow = SettingsUI.row(label("Ungroup after placing"), ungroupCheckBox, indent: 1)
        let afterGeneration = SettingsUI.pane(header: header("After Generation"), groups: [
            SettingsUI.group(label("Results"), [
                SettingsUI.row(label("Send a notification"), sendNotificationCheckBox),
                SettingsUI.row(label("Show the output window"), showOutputWindowCheckBox),
                SettingsUI.row(label("Preview generated files"), previewCheckBox),
            ]),
            SettingsUI.group(label("Generated Files"), [
                SettingsUI.row(label("Embed the source to restore it from generated files"), embedSourceCheckBox),
                SettingsUI.row(label("Delete temporary files"), deleteTmpFileCheckBox),
                SettingsUI.row(label("Temporary folder"), SettingsUI.makeButton(label("Open in Finder"), target: self, action: #selector(openTempDir(_:)))),
            ]),
            SettingsUI.group(label("Other Applications"), [
                SettingsUI.row(label("Copy generated files to the clipboard"), toClipboardCheckBox),
                autoPasteRow,
                SettingsUI.row(label("Place generated files in Illustrator"), note: label("EPS is recommended."), embedInIllustratorCheckBox),
                ungroupRow,
                SettingsUI.row(label("Permission to control other applications"), note: label("Pasting and placing need this permission."),
                               SettingsUI.makeButton(label("Open System Settings…"), target: self, action: #selector(openSystemPreferencePane(_:)))),
            ]),
        ])

        // MARK: Editor
        fontTextField = NSTextField(labelWithString: "")
        fontTextField.textColor = .secondaryLabelColor
        fontTextField.lineBreakMode = .byTruncatingTail
        fontTextField.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(250), for: .horizontal)
        let fontButton = SettingsUI.makeButton(label("Select…"), target: self, action: #selector(showFontPanelOfSource(_:)))
        wrapLineCheckBox = makeSwitch(refresh)
        tabWidthTextField = SettingsUI.makeNumberField(minimum: 1, maximum: 100)
        tabWidthTextField.toolTip = label("Tab width")
        tabWidthStepper = SettingsUI.makeStepper(minimum: 1, maximum: 100)
        tabWidthStepper.target = self
        tabWidthStepper.action = #selector(tabWidthStepperPressed(_:))
        tabIndentCheckBox = makeSwitch()
        commandCompletionKeyPopUp = SettingsUI.makePopUp([("Escape", 1), ("Tab", 2)])
        makeatletterEnabledCheckBox = makeSwitch(refresh)
        checkBraceCheckBox = SettingsUI.makeCheckbox("{ }", target: self, action: refresh)
        checkParenCheckBox = SettingsUI.makeCheckbox("( )", target: self, action: refresh)
        checkSquareCheckBox = SettingsUI.makeCheckbox("[ ]", target: self, action: refresh)
        checkBracketCheckBox = SettingsUI.makeCheckbox("< >", target: self, action: refresh)
        flashInMovingCheckBox = makeSwitch(refresh)
        highlightContentCheckBox = makeSwitch(refresh)
        beepCheckBox = makeSwitch(refresh)
        flashBackgroundCheckBox = makeSwitch(refresh)
        func invisible(_ glyphs: [String]) -> NSPopUpButton {
            SettingsUI.makePopUp(glyphs.enumerated().map { ($1, $0 + 1) }, target: self, action: #selector(invisibleCharacterKindChanged(_:)))
        }
        spaceCharacterKindPopUp = invisible(["␣", "·", "°", "ː"])
        fullwidthSpaceCharacterKindPopUp = invisible(["□", "■", "•", "⊠"])
        returnCharacterKindPopUp = invisible(["↵", "↩", "⏎", "¶"])
        tabCharacterKindPopUp = invisible(["‣", "▹", "⇥", "¬"])
        showSpaceCharacterCheckBox = makeSwitch(refresh)
        showFullwidthSpaceCharacterCheckBox = makeSwitch(refresh)
        showNewLineCharacterCheckBox = makeSwitch(refresh)
        showTabCharacterCheckBox = makeSwitch(refresh)
        let editor = SettingsUI.pane(header: header("Editor"), groups: [
            SettingsUI.group(label("Display"), [
                SettingsUI.row(label("Font"), SettingsUI.hstack([fontTextField, fontButton])),
                SettingsUI.row(label("Wrap lines"), wrapLineCheckBox),
            ]),
            SettingsUI.group(label("Formatting"), [
                SettingsUI.row(label("Tab width"), SettingsUI.numberAccessory(field: tabWidthTextField, stepper: tabWidthStepper, unit: label("characters"))),
                SettingsUI.row(label("Indent with tabs"), tabIndentCheckBox),
            ]),
            SettingsUI.group(label("Input"), [SettingsUI.row(label("Command completion key"), commandCompletionKeyPopUp)]),
            SettingsUI.group(label("Syntax Coloring"), [SettingsUI.row(label("Treat @ as part of command names"), note: label("As after \\makeatletter."), makeatletterEnabledCheckBox)]),
            SettingsUI.group(label("Matching Brackets"), [
                SettingsUI.row(label("Brackets to match"), SettingsUI.hstack([checkBraceCheckBox, checkParenCheckBox, checkSquareCheckBox, checkBracketCheckBox], spacing: 14)),
                SettingsUI.row(label("Highlight while moving the cursor"), flashInMovingCheckBox),
                SettingsUI.row(label("Highlight enclosed contents"), highlightContentCheckBox),
                SettingsUI.row(label("Beep for unmatched brackets"), beepCheckBox),
                SettingsUI.row(label("Flash the background for unmatched brackets"), flashBackgroundCheckBox),
            ]),
            SettingsUI.group(label("Invisible Characters"), [
                SettingsUI.row(label("Space"), SettingsUI.hstack([spaceCharacterKindPopUp, showSpaceCharacterCheckBox])),
                SettingsUI.row(label("Fullwidth space"), SettingsUI.hstack([fullwidthSpaceCharacterKindPopUp, showFullwidthSpaceCharacterCheckBox])),
                SettingsUI.row(label("Line break"), SettingsUI.hstack([returnCharacterKindPopUp, showNewLineCharacterCheckBox])),
                SettingsUI.row(label("Tab"), SettingsUI.hstack([tabCharacterKindPopUp, showTabCharacterCheckBox])),
            ]),
        ])

        // MARK: Appearance
        themeSettings = ThemeSettingsController(library: ThemeLibrary.shared)
        themeSettings.colorsChanged = { [weak self] in self?.themeColorsChanged() }
        let appearance = SettingsUI.pane(header: header("Appearance"), groups: themeSettings.groups())

        settingsDependentRows = [.pageBox: pageBoxRow, .animationDelay: delayRow, .animationLoop: loopRow, .autoPaste: autoPasteRow, .ungroup: ungroupRow]
        let views: [String: NSView] = ["General": general, "Image": image, "Conversion": conversion, "After Generation": afterGeneration,
                                       "Editor": editor, "Appearance": appearance]
        settingsWindowController = SettingsWindowController(categories: Self.settingsCategoryDesign.map { design in
            SettingsCategory(identifier: design.identifier, title: label(design.identifier), summary: label(design.identifier + " summary"),
                             symbol: design.symbol, color: SettingsCategory.rgb(design.color), startsGroup: design.startsGroup,
                             view: views[design.identifier]!)
        })
        themeSettings.window = settingsWindowController.window
    }

    /// Sidebar order, symbols and colors; the palette is TeXShop's.
    static let settingsCategoryDesign: [(identifier: String, symbol: String, color: Int, startsGroup: Bool)] = [
        ("General", "gearshape", 0x888780, false),
        ("Image", "photo", 0x378ADD, true),
        ("Conversion", "hammer", 0x534AB7, false),
        ("After Generation", "square.and.arrow.up", 0x1D9E75, false),
        ("Editor", "character.cursor.ibeam", 0xBA7517, true),
        ("Appearance", "paintpalette", 0x7F77DD, false),
    ]

    private func header(_ identifier: String) -> NSView {
        let design = Self.settingsCategoryDesign.first { $0.identifier == identifier }!
        return SettingsUI.header(title: NSLocalizedString(identifier, comment: ""), summary: NSLocalizedString(identifier + " summary", comment: ""),
                                 symbol: design.symbol, color: SettingsCategory.rgb(design.color))
    }

    private func pathField() -> NSTextField {
        let field = NSTextField(string: "")
        field.translatesAutoresizingMaskIntoConstraints = false
        field.lineBreakMode = .byTruncatingMiddle
        field.cell?.isScrollable = true
        field.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        return field
    }

    /// Dims rows that have no effect with the current values.
    func updateSettingsDependencies() {
        settingsDependentRows[.pageBox]?.isEnabled = keepPageSizeCheckBox.state == .on
        settingsDependentRows[.animationDelay]?.isEnabled = mergeOutputsCheckBox.state == .on
        settingsDependentRows[.animationLoop]?.isEnabled = mergeOutputsCheckBox.state == .on
        settingsDependentRows[.ungroup]?.isEnabled = embedInIllustratorCheckBox.state == .on
        let autoPaste = settingsDependentRows[.autoPaste]
        autoPaste?.isEnabled = toClipboardCheckBox.state == .on
        if toClipboardCheckBox.state == .on {
            autoPasteDestinationPopUpButton.isEnabled = autoPasteCheckBox.state == .on
        }
    }

    @objc func automaticUpdateCheckChanged(_ sender: NSSwitch) {
        UserDefaults.standard.set(sender.state == .on, forKey: "SUEnableAutomaticChecks")
    }
}

extension ControllerG {
    /// Earlier versions kept the editor colors in the profile. Customized colors become themes.
    func migrateLegacyColors(from profile: Profile) {
        let lightKeys: [(String, ThemeRole)] = [
            (ForegroundColorForLightModeKey, .text), (BackgroundColorForLightModeKey, .background), (CursorColorForLightModeKey, .cursor),
            (BraceColorForLightModeKey, .marker), (CommentColorForLightModeKey, .comment), (CommandColorForLightModeKey, .command),
            (InvisibleColorForLightModeKey, .invisible), (HighlightedBraceColorForLightModeKey, .highlightedBrace),
            (EnclosedContentBackgroundColorForLightModeKey, .enclosedContent), (FlashingBackgroundColorForLightModeKey, .flash),
            (ConsoleForegroundColorForLightModeKey, .consoleText), (ConsoleBackgroundColorForLightModeKey, .consoleBackground),
        ]
        let darkKeys: [(String, ThemeRole)] = [
            (ForegroundColorForDarkModeKey, .text), (BackgroundColorForDarkModeKey, .background), (CursorColorForDarkModeKey, .cursor),
            (BraceColorForDarkModeKey, .marker), (CommentColorForDarkModeKey, .comment), (CommandColorForDarkModeKey, .command),
            (InvisibleColorForDarkModeKey, .invisible), (HighlightedBraceColorForDarkModeKey, .highlightedBrace),
            (EnclosedContentBackgroundColorForDarkModeKey, .enclosedContent), (FlashingBackgroundColorForDarkModeKey, .flash),
            (ConsoleForegroundColorForDarkModeKey, .consoleText), (ConsoleBackgroundColorForDarkModeKey, .consoleBackground),
        ]
        let library = ThemeLibrary.shared
        func migrate(_ keys: [(String, ThemeRole)], base: String, title: String) -> String {
            guard var colors = library.store.read(title: base) else { return base }
            var changed = false
            for (key, role) in keys {
                // Untouched colors were saved as the device RGB form of the defaults.
                guard let color = profile.colorForKey(key)?.usingColorSpace(.deviceRGB),
                      let original = ThemePalette.defaultColor(role, dark: keys.first?.0 == ForegroundColorForDarkModeKey).usingColorSpace(.deviceRGB) else { continue }
                if abs(color.redComponent - original.redComponent) < 0.004, abs(color.greenComponent - original.greenComponent) < 0.004,
                   abs(color.blueComponent - original.blueComponent) < 0.004 { continue }
                ThemePalette.set(color.withAlphaComponent(1), for: role.key, in: &colors)
                if role == .marker { ThemePalette.set(color.withAlphaComponent(1), for: "SyntaxMarker", in: &colors) }
                changed = true
            }
            guard changed else { return base }
            if let existing = library.store.read(title: title), ThemePalette.sameColors(existing, colors) { return title }
            var unique = title, number = 2
            while library.store.contains(title: unique) {
                unique = "\(title) \(number)"
                number += 1
            }
            guard (try? library.store.write(colors, title: unique)) != nil else { return base }
            return unique
        }
        let light = migrate(lightKeys, base: ThemeStore.defaultLightTitle, title: NSLocalizedString("Previous Light Mode Colors", comment: ""))
        let dark = migrate(darkKeys, base: ThemeStore.defaultDarkTitle, title: NSLocalizedString("Previous Dark Mode Colors", comment: ""))
        themeSettings.reloadThemeMenus()
        themeSettings.select(light: light, dark: dark)
        themeColorsChanged()
    }
}
