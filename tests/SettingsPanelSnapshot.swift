import AppKit

// Builds the settings window with the product code and a stand-in for ControllerG,
// checks its structure, and renders every category off screen. No window is shown.
// Run through tests/test_settings_panel.py.

final class ControllerG: NSObject {
    var flashInMovingCheckBox: NSSwitch!
    var highlightContentCheckBox: NSSwitch!
    var beepCheckBox: NSSwitch!
    var flashBackgroundCheckBox: NSSwitch!
    var checkBraceCheckBox: NSButton!
    var checkBracketCheckBox: NSButton!
    var checkSquareCheckBox: NSButton!
    var checkParenCheckBox: NSButton!
    var fontTextField: NSTextField!
    var tabWidthTextField: NSTextField!
    var tabWidthStepper: NSStepper!
    var tabIndentCheckBox: NSSwitch!
    var wrapLineCheckBox: NSSwitch!
    var showTabCharacterCheckBox: NSSwitch!
    var showSpaceCharacterCheckBox: NSSwitch!
    var showNewLineCharacterCheckBox: NSSwitch!
    var showFullwidthSpaceCharacterCheckBox: NSSwitch!
    var commandCompletionKeyPopUp: NSPopUpButton!
    var autoRestoreCheckBox: NSSwitch!
    var transparentCheckBox: NSSwitch!
    var plainTextCheckBox: NSSwitch!
    var deleteDisplaySizeCheckBox: NSSwitch!
    var mergeOutputsCheckBox: NSSwitch!
    var keepPageSizeCheckBox: NSSwitch!
    var showOutputWindowCheckBox: NSSwitch!
    var sendNotificationCheckBox: NSSwitch!
    var previewCheckBox: NSSwitch!
    var deleteTmpFileCheckBox: NSSwitch!
    var toClipboardCheckBox: NSSwitch!
    var embedSourceCheckBox: NSSwitch!
    var autoPasteCheckBox: NSSwitch!
    var autoPasteDestinationPopUpButton: NSPopUpButton!
    var embedInIllustratorCheckBox: NSSwitch!
    var ungroupCheckBox: NSSwitch!
    var resolutionTextField: NSTextField!
    var dpiTextField: NSTextField!
    var leftMarginTextField: NSTextField!
    var rightMarginTextField: NSTextField!
    var topMarginTextField: NSTextField!
    var bottomMarginTextField: NSTextField!
    var resolutionStepper: NSStepper!
    var dpiStepper: NSStepper!
    var leftMarginStepper: NSStepper!
    var rightMarginStepper: NSStepper!
    var topMarginStepper: NSStepper!
    var bottomMarginStepper: NSStepper!
    var latexPathTextField: NSTextField!
    var dviDriverPathTextField: NSTextField!
    var gsPathTextField: NSTextField!
    var guessCompilationButton: NSSwitch!
    var numberOfCompilationTextField: NSTextField!
    var numberOfCompilationStepper: NSStepper!
    var textPdfCheckBox: NSSwitch!
    var ignoreErrorCheckBox: NSSwitch!
    var utfExportCheckBox: NSSwitch!
    var encodingPopUpButton: NSPopUpButton!
    var unitPopUp: NSPopUpButton!
    var priorityPopUp: NSPopUpButton!
    var workInInputFileDirectoryCheckBox: NSSwitch!
    var fillColorWell: NSColorWell!
    var makeatletterEnabledCheckBox: NSSwitch!
    var autoDetectionTargetPopUp: NSPopUpButton!
    var spaceCharacterKindPopUp: NSPopUpButton!
    var fullwidthSpaceCharacterKindPopUp: NSPopUpButton!
    var returnCharacterKindPopUp: NSPopUpButton!
    var tabCharacterKindPopUp: NSPopUpButton!
    var pageBoxPopUp: NSPopUpButton!
    var delayTextField: NSTextField!
    var delayStepper: NSStepper!
    var loopCountTextField: NSTextField!
    var loopCountStepper: NSStepper!
    var settingsWindowController: SettingsWindowController!
    var themeSettings: ThemeSettingsController!
    var updateCheckSwitch: NSSwitch!
    var settingsDependentRows: [SettingsDependentRow: SettingsRowView] = [:]
    var shortcutPane: ShortcutPaneController!
    var cuiToolInstallButton: NSButton!
    var cuiToolStatusView: NSImageView!
    var cuiToolStatusTextField: NSTextField!
    var themeChanges = 0

    @objc func preferencesChanged(_ sender: Any) { updateSettingsDependencies() }
    @objc func refreshTextView(_ sender: Any) {}
    @objc func colorSettingChanged(_ sender: Any) {}
    @objc func installCUITool(_ sender: Any) {}
    @objc func showProfilesWindow(_ sender: Any) {}
    @objc func searchPrograms(_ sender: Any) {}
    @objc func openTempDir(_ sender: Any) {}
    @objc func openSystemPreferencePane(_ sender: Any) {}
    @objc func showFontPanelOfSource(_ sender: Any) {}
    @objc func tabWidthStepperPressed(_ sender: Any) {}
    @objc func invisibleCharacterKindChanged(_ sender: Any?) {}
    func themeColorsChanged() { themeChanges += 1 }
}

func check(_ condition: Bool, _ message: String) {
    if !condition {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}

func all<T>(_ type: T.Type, in view: NSView) -> [T] {
    ((view as? T).map { [$0] } ?? []) + view.subviews.flatMap { all(type, in: $0) }
}

/// Lays a view out by its constraints at a width and its fitting height, as the settings window does.
func layOut(_ view: NSView, width: CGFloat) -> NSView {
    let host = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 100))
    view.removeFromSuperview()
    view.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(view)
    NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
        view.topAnchor.constraint(equalTo: host.topAnchor),
    ])
    host.layoutSubtreeIfNeeded()
    let height = ceil(view.fittingSize.height)
    host.setFrameSize(NSSize(width: width, height: height))
    host.layoutSubtreeIfNeeded()
    return host
}

func render(_ view: NSView, width: CGFloat, appearance: NSAppearance.Name, to url: URL) {
    let host = layOut(view, width: width)
    host.appearance = NSAppearance(named: appearance)
    host.wantsLayer = true
    host.layoutSubtreeIfNeeded()
    let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
    host.appearance!.performAsCurrentDrawingAppearance {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        (appearance == .darkAqua ? NSColor(white: 0.12, alpha: 1) : NSColor.white).setFill()
        host.bounds.fill()
        NSGraphicsContext.restoreGraphicsState()
        host.cacheDisplay(in: host.bounds, to: rep)
    }
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
    view.removeFromSuperview()
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let language = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "en"
_ = NSApplication.shared
NSApp.setActivationPolicy(.prohibited)
check(ThemeStore.userDirectory.path.hasPrefix(NSTemporaryDirectory()) || ThemeStore.userDirectory.path.contains("/settings-home/"),
      "the theme directory must be inside the test home: \(ThemeStore.userDirectory.path)")
ThemeLibrary.shared.prepare()
let controller = ControllerG()
controller.buildSettingsWindow()
let settings = controller.settingsWindowController!

// A fresh installation starts with the values of the settings window of TeX2img 2.x (its MainMenu.xib).
let defaultFields: [NSTextField] = [controller.resolutionTextField, controller.dpiTextField, controller.numberOfCompilationTextField,
    controller.tabWidthTextField, controller.delayTextField, controller.loopCountTextField, controller.topMarginTextField, controller.leftMarginTextField]
let defaultNumbers: [Double] = defaultFields.map { $0.doubleValue }
check(defaultNumbers == [5, 72, 3, 4, 1, 0, 0, 0], "default numbers: \(defaultNumbers)")
check(controller.resolutionStepper.doubleValue == 5 && controller.numberOfCompilationStepper.doubleValue == 3, "default stepper values")
check(controller.autoDetectionTargetPopUp.titleOfSelectedItem == "pLaTeX + dvipdfmx", "default compiler")
check(controller.pageBoxPopUp.titleOfSelectedItem == "CropBox", "default page box")
check(controller.unitPopUp.titleOfSelectedItem == "px" && controller.priorityPopUp.selectedTag() == 1, "default unit and priority")
let defaultOn: [NSSwitch] = [controller.transparentCheckBox, controller.previewCheckBox, controller.sendNotificationCheckBox,
    controller.deleteTmpFileCheckBox, controller.embedSourceCheckBox, controller.showOutputWindowCheckBox, controller.guessCompilationButton,
    controller.autoRestoreCheckBox, controller.wrapLineCheckBox, controller.tabIndentCheckBox, controller.showSpaceCharacterCheckBox,
    controller.showTabCharacterCheckBox, controller.showNewLineCharacterCheckBox, controller.showFullwidthSpaceCharacterCheckBox,
    controller.makeatletterEnabledCheckBox, controller.flashInMovingCheckBox, controller.highlightContentCheckBox, controller.beepCheckBox,
    controller.flashBackgroundCheckBox]
check(defaultOn.allSatisfy { $0.state == .on }, "switches on by default")
let defaultBrackets: [NSButton] = [controller.checkBraceCheckBox, controller.checkBracketCheckBox, controller.checkParenCheckBox,
    controller.checkSquareCheckBox]
check(defaultBrackets.allSatisfy { $0.state == .on }, "brackets to match by default")
let defaultOff: [NSSwitch] = [controller.toClipboardCheckBox, controller.mergeOutputsCheckBox, controller.textPdfCheckBox,
    controller.ignoreErrorCheckBox, controller.utfExportCheckBox, controller.keepPageSizeCheckBox]
check(defaultOff.allSatisfy { $0.state == .off }, "switches off by default")
check(controller.fillColorWell.color.usingColorSpace(.sRGB).map { $0.redComponent > 0.99 && $0.greenComponent > 0.99 && $0.blueComponent > 0.99 } == true,
      "white fill by default")
check(settings.window?.isVisible == false, "the settings window stays hidden")
check(settings.categories.map(\.identifier) == ["General", "Image", "Conversion", "After Generation", "Editor", "Keyboard", "Appearance"],
      "category order: Keyboard after Editor, as in TeXShop 6.00")

controller.themeSettings.prepareForDisplay(dark: false)
// The theme colors stand three to a row, in columns that line up from group to group (TeXShop 6.00); the window is
// never too narrow for them.
let colorGrids = all(NSGridView.self, in: settings.category("Appearance")!.view).filter { $0.identifier?.rawValue == "settings.color-grid" }
check(colorGrids.count == 4 && colorGrids.allSatisfy { $0.numberOfColumns == 3 }, "four color groups of three columns")
check(Set(colorGrids.map { $0.column(at: 0).width }).count == 1, "the columns line up from group to group")
let paneWidth = max(640, settings.minimumContentWidth)
check(settings.minimumContentWidth >= SettingsUI.colorGridWidth(columnWidth: colorGrids[0].column(at: 0).width) + SettingsUI.paneContentInsets,
      "the narrowest pane holds three columns: \(settings.minimumContentWidth)")
check(settings.window!.contentMinSize.width >= settings.minimumContentWidth + SettingsWindowController.sidebarMinimumWidth,
      "the window is wide enough for the narrowest sidebar and pane: \(settings.window!.contentMinSize.width)")
print("Narrowest pane: \(settings.minimumContentWidth), window: \(settings.window!.contentMinSize.width)")

// Structure: a header card in each pane, every group has a heading and a card, toggles are switches.
var report: [String] = []
for category in settings.categories {
    let pane = category.view
    let headers = all(NSView.self, in: pane).filter { $0.identifier?.rawValue == "category.header" }
    check(headers.count == 1, "\(category.identifier): one header card")
    let groups = all(NSView.self, in: pane).filter { $0.identifier?.rawValue == "group" }
    let headings = all(NSTextField.self, in: pane).filter { $0.identifier?.rawValue == "group.heading" }
    check(groups.count == headings.count && !groups.isEmpty, "\(category.identifier): every group has a heading")
    let switches = all(NSSwitch.self, in: pane)
    check(switches.allSatisfy { $0.controlSize == .small }, "\(category.identifier): small switches")
    let rows = all(SettingsRowView.self, in: pane)
    report.append("\(category.identifier): groups=\(groups.count) rows=\(rows.count) switches=\(switches.count)")
    for appearance in [NSAppearance.Name.aqua, .darkAqua] {
        if category.identifier == "Appearance" { controller.themeSettings.prepareForDisplay(dark: appearance == .darkAqua) }
        let name = "\(language)-\(category.identifier.replacingOccurrences(of: " ", with: "_"))-\(appearance == .aqua ? "light" : "dark").png"
        render(pane, width: paneWidth, appearance: appearance, to: output.appendingPathComponent(name))
    }
}
// Every label of the cards shows its whole text, at the default width and at the narrowest the window allows (TeXShop 6.00):
// a one-line label is as wide as its text, a wrapping one as tall. Labels that are meant to truncate, and the lists, are left out.
for width in [settings.minimumContentWidth + SettingsWindowController.sidebarWidth - SettingsWindowController.sidebarMinimumWidth,
              settings.minimumContentWidth] {
    for category in settings.categories {
        if category.identifier == "Appearance" { controller.themeSettings.prepareForDisplay(dark: false) }
        _ = layOut(category.view, width: width)
        for label in all(NSTextField.self, in: category.view) where !label.isEditable && !label.isBezeled && !label.isHiddenOrHasHiddenAncestor {
            var ancestor = label.superview
            while let view = ancestor, !(view is NSTableView) { ancestor = view.superview }
            guard ancestor == nil, label.lineBreakMode != .byTruncatingTail, label.lineBreakMode != .byTruncatingMiddle,
                  let cell = label.cell, !label.stringValue.isEmpty else { continue }
            let place = "\(category.identifier) at \(width): “\(label.stringValue)”"
            if cell.wraps {
                let needed = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: label.frame.width, height: .greatestFiniteMagnitude)).height
                check(label.frame.height >= needed - 1, "\(place) is \(label.frame.height) high for \(needed)")
            } else {
                check(label.frame.width >= cell.cellSize.width - 1, "\(place) is \(label.frame.width) wide for \(cell.cellSize.width)")
            }
            let frame = label.convert(label.bounds, to: category.view)
            check(category.view.bounds.insetBy(dx: -0.5, dy: -0.5).contains(frame), "\(place) stays inside its pane")
        }
        category.view.removeFromSuperview()
    }
}

let invisibleWidths = Set([controller.spaceCharacterKindPopUp, controller.fullwidthSpaceCharacterKindPopUp,
                            controller.returnCharacterKindPopUp, controller.tabCharacterKindPopUp].map { $0!.frame.width })
check(invisibleWidths.count == 1, "the invisible-character menus share one width")
// Check boxes remain only for the brackets to match, as in TeXShop.
let editorBoxes = all(NSButton.self, in: settings.category("Editor")!.view).filter { ["{ }", "( )", "[ ]", "< >"].contains($0.title) }
check(editorBoxes.count == 4, "bracket check boxes")

// Dependencies dim the child rows.
controller.keepPageSizeCheckBox.state = .off
controller.mergeOutputsCheckBox.state = .on
controller.toClipboardCheckBox.state = .off
controller.embedInIllustratorCheckBox.state = .off
controller.updateSettingsDependencies()
check(controller.settingsDependentRows[.pageBox]?.isEnabled == false && !controller.pageBoxPopUp.isEnabled, "page box follows keep page size")
check(controller.settingsDependentRows[.animationDelay]?.isEnabled == true && controller.delayTextField.isEnabled, "animation follows merge")
check(controller.settingsDependentRows[.autoPaste]?.isEnabled == false && !controller.autoPasteCheckBox.isEnabled, "auto paste follows clipboard")
check(controller.settingsDependentRows[.ungroup]?.isEnabled == false, "ungroup follows Illustrator")

// Search finds rows by name, note, group and category, across width and kana differences.
settings.setSearchQuery(language == "ja" ? "ゴースト" : "ghostscript")
let entries = settings.categories.flatMap { SettingsWindowController.searchEntries(in: $0.view) }
check(entries.contains { $0.title == "Ghostscript" }, "search entries include Ghostscript")
let hits = { (query: String) -> [String] in
    let tokens = SettingsWindowController.tokens(query)
    return settings.categories.flatMap { category in
        SettingsWindowController.searchEntries(in: category.view).filter { entry in
            let text = SettingsWindowController.normalized([entry.title, entry.note, entry.group, category.title].joined(separator: " "))
            return tokens.allSatisfy { text.contains($0) }
        }.map(\.title)
    }
}
check(hits("ＧＨＯＳＴＳＣＲＩＰＴ") == ["Ghostscript"], "width-insensitive search")
check(hits("svgz").count >= 3, "notes are searchable")

// Navigation history.
check(settings.select("Editor") && settings.currentIdentifier == "Editor", "select a category")
settings.select("Appearance")
settings.goBack(nil)
check(settings.currentIdentifier == "Editor", "back")
settings.goForward(nil)
check(settings.currentIdentifier == "Appearance", "forward")

// Themes: bundled themes are installed, defaults are selected, and editing writes the file.
let store = ThemeLibrary.shared.store
check(store.titles().contains(ThemeStore.defaultLightTitle) && store.titles().contains("SolarizedDark"), "bundled themes installed")
let themes = controller.themeSettings!
themes.prepareForDisplay(dark: false)
check(themes.lightTitle == ThemeStore.defaultLightTitle && themes.darkTitle == ThemeStore.defaultDarkTitle, "default themes selected")
check(themes.editingPopup.titleOfSelectedItem == ThemeStore.defaultLightTitle, "the light theme is edited in light mode")
let blackText = ThemePalette.color(.text, in: store.read(title: ThemeStore.defaultLightTitle), dark: false).usingColorSpace(.sRGB)!
check(blackText.redComponent < 0.01 && blackText.greenComponent < 0.01, "TeX2img Lite keeps black text")
check(!themes.resetButton.isEnabled, "nothing to restore before editing")
check(ThemePalette.components(["SyntaxMarker": [0.1, 0.2, 0.3, 1]], key: "SyntaxMarkerCurly") == [0.1, 0.2, 0.3, 1], "brace color inherits SyntaxMarker")
check(ThemePalette.components(["EditorInvisibleChar": [1.235, 0.013, 0.011, 1]], key: "EditorInvisibleChar")?.first == 1, "out-of-range components are clamped")
check(ThemePalette.components(["EditorText": [Double.nan, 0, 0]], key: "EditorText") == nil, "invalid components are ignored")
let solarized = store.read(title: "SolarizedDark") ?? [:]
var withExpl = solarized
withExpl["explFunction"] = [0.1, 0.2, 0.3, 1]
check(ThemePalette.sameUsedColors(solarized, withExpl) && !ThemePalette.sameColors(solarized, withExpl), "colors TeX2img does not draw are ignored")
var otherComment = solarized
otherComment["SyntaxComment"] = [0.9, 0.1, 0.1, 1]
check(!ThemePalette.sameUsedColors(solarized, otherComment), "a different comment color counts")
// TeXShop's themes with expl3 colors are not offered again when TeX2img draws them the same.
let texShopThemes = ThemeStore(directory: ThemeStore.texShopDirectory)
try? FileManager.default.createDirectory(at: ThemeStore.texShopDirectory, withIntermediateDirectories: true)
check(ThemeStore.texShopDirectory.path.contains("/settings-home/"), "the TeXShop theme folder is in the test home")
try? texShopThemes.write(withExpl, title: "SolarizedDark")
try? texShopThemes.write(otherComment, title: "Solarized Comment")
check(themes.importableTeXShopThemes() == ["Solarized Comment"], "importable TeXShop themes: \(themes.importableTeXShopThemes())")
// Fullwidth letters and symbols are colored only by themes that define them.
check(ThemeLibrary.isHighlightedFullwidthCharacter(0xFF21) && ThemeLibrary.isHighlightedFullwidthCharacter(0x2212)
      && !ThemeLibrary.isHighlightedFullwidthCharacter(0xFF0C) && !ThemeLibrary.isHighlightedFullwidthCharacter(0x3042), "fullwidth characters")
check(ThemeLibrary.shared.fullwidthAttributes(lightTitle: ThemeStore.defaultLightTitle, darkTitle: nil, dark: false)?[.backgroundColor] != nil,
      "TeX2img Lite colors fullwidth characters")
try! store.write(["EditorText": [0, 0, 0, 1]], title: "No Fullwidth")
check(ThemeLibrary.shared.fullwidthAttributes(lightTitle: "No Fullwidth", darkTitle: nil, dark: false) == nil, "a theme without the keys colors nothing")
let translucent: ThemeColors = ["EditorText": [1, 0, 0, 0.5], "EditorFlash": [0, 0, 1, 0.5]]
check(ThemePalette.color(.text, in: translucent, dark: false).alphaComponent == 1, "opaque colors are drawn opaque")
check(abs(ThemePalette.color(.flash, in: translucent, dark: false).alphaComponent - 0.5) < 0.001, "the flash keeps its opacity")
if #available(macOS 14.0, *) {
    check(themes.wells.allSatisfy { $0.value.supportsAlpha == $0.key.usesOpacity }, "only the flash well offers opacity")
}
check(store.url(forTitle: "../evil") == nil && store.url(forTitle: ".hidden") == nil && store.url(forTitle: "a:b") == nil, "unsafe theme names are refused")

// The bundled themes have the colors of TeXShop 6.00, and earlier copies get them once (TeXShop's updateBundledThemeColors).
let bundledStore = ThemeStore(directory: ThemeStore.bundledDirectory!)
func near(_ value: Any?, _ expected: [Double]) -> Bool {
    guard let array = value as? [NSNumber], array.count >= 3 else { return false }
    return (0..<3).allSatisfy { abs(array[$0].doubleValue - expected[$0]) < 0.0005 }
}
// The last change of each color is the color of the bundled theme (a color can change in more than one update).
var lastChanges: [String: BundledThemeColorChange] = [:]
for change in ThemeStore.bundledColorChanges { lastChanges[change.theme + "/" + change.key] = change }
for change in lastChanges.values {
    check(near(bundledStore.read(title: change.theme)?[change.key], change.to), "bundled \(change.theme) has the new \(change.key)")
}
// Every color TeX2img draws as text is readable on its background (contrast 4.5 or more, as in TeXShop 6.00), in all the
// bundled themes; in TeX2img's own themes, the matching braces too.
func luminance(_ value: Any?) -> Double {
    let c = (value as! [NSNumber]).prefix(3).map { min(max($0.doubleValue, 0), 1) }.map { $0 <= 0.03928 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
}
func contrast(_ a: Any?, _ b: Any?) -> Double {
    let (x, y) = (luminance(a), luminance(b))
    return (max(x, y) + 0.05) / (min(x, y) + 0.05)
}
for title in bundledStore.titles() {
    let theme = bundledStore.read(title: title)!
    var keys = ["EditorText", "SyntaxComment", "SyntaxCommand", "SyntaxMarkerCurly"]
    if title == ThemeStore.defaultLightTitle || title == ThemeStore.defaultDarkTitle { keys.append("EditorHighlightBraces") }
    for key in keys {
        let value = ThemePalette.components(theme, key: key)
        check(contrast(value, theme["EditorBackground"]) >= 4.5, "\(title) \(key) contrast \(contrast(value, theme["EditorBackground"]))")
    }
    check(contrast(theme["ConsoleText"], theme["ConsoleBackground"]) >= 4.5, "\(title) console contrast")
}
check(near(bundledStore.read(title: "Dracula")?["SyntaxMarkerCurly"], [0.9725490196078431, 0.9725490196078431, 0.9490196078431372]),
      "Dracula's braces are in its text color")
// Copies as earlier versions installed them: the old colors, one of them changed by the user.
// The earliest color wins when a color changed in more than one update.
func earlierCopy(_ theme: String, before update: Int = 1) -> ThemeColors {
    var colors = bundledStore.read(title: theme)!
    for change in ThemeStore.bundledColorChanges.reversed() where change.theme == theme && change.update >= update {
        var color = colors[change.key] as! [Any]
        for index in 0..<3 { color[index] = NSNumber(value: change.from[index]) }
        colors[change.key] = color
    }
    return colors
}
var oldDracula = earlierCopy("Dracula")
oldDracula["SyntaxMarkerParen"] = [0.5, 0.25, 0.125, 1.0]
try! store.write(oldDracula, title: "Dracula")
try! store.write(earlierCopy("Dracula"), title: "My Dracula")
try! store.write(earlierCopy("Manteuffel"), title: "Manteuffel")
check(store.updateBundledThemeColors(after: 0) == 2, "the updates are done")
let updatedDracula = store.read(title: "Dracula")!
check(near(updatedDracula["SyntaxMarkerCurly"], [0.9725490196078431, 0.9725490196078431, 0.9490196078431372])
      && near(updatedDracula["EditorHighlightContent"], [0.25098, 0.243137, 0.172549]), "a copy gets the new colors")
check(near(updatedDracula["SyntaxMarkerParen"], [0.5, 0.25, 0.125]), "a color the user chose stays")
check(near(store.read(title: "My Dracula")?["SyntaxMarkerCurly"], [0, 0, 0]), "a renamed copy stays")
check(near(store.read(title: "Manteuffel")?["SyntaxCommand"], [0.039216, 0.466667, 0.623529]), "Manteuffel's commands: both updates in turn")
check(near(store.read(title: "Manteuffel")?["SyntaxComment"], [0.243137, 0.490196, 0.243137]), "Manteuffel's comments are readable")
check(ThemeStore.applyBundledColorChanges(to: &oldDracula, theme: "Dracula", after: 2) == false, "nothing after the last update")
// Copies that the first update (TeX2img 3.0.x of 11-16) left: the second update gives them the readable colors once.
var afterFirst = earlierCopy("SolarizedLite", before: 2)
afterFirst["SyntaxCommand"] = [0.25, 0.5, 0.75, 1.0]
try! store.write(afterFirst, title: "SolarizedLite")
try! store.write(earlierCopy(ThemeStore.defaultLightTitle, before: 2), title: ThemeStore.defaultLightTitle)
check(store.updateBundledThemeColors(after: 1) == 2, "the second update is done")
let updatedSolarized = store.read(title: "SolarizedLite")!
check(near(updatedSolarized["EditorText"], [0.372549, 0.447059, 0.478431]) && near(updatedSolarized["SyntaxComment"], [0.376471, 0.396078, 0.74902]),
      "a copy of the first update gets the second")
check(near(updatedSolarized["SyntaxCommand"], [0.25, 0.5, 0.75]), "a color the user chose stays in the second update")
let updatedLite = store.read(title: ThemeStore.defaultLightTitle)!
check(near(updatedLite["SyntaxComment"], [0.921569, 0, 0]) && near(updatedLite["EditorHighlightBraces"], [0.752941, 0, 0.752941]),
      "TeX2img Lite's comments and braces become readable")
check(ThemePalette.sameColors(updatedLite, bundledStore.read(title: ThemeStore.defaultLightTitle)!), "the updated TeX2img Lite is the bundled one")
// A theme that is there but cannot be read leaves the update for the next launch.
try! Data("not a property list".utf8).write(to: store.url(forTitle: "LiteTheme")!)
check(store.updateBundledThemeColors(after: 0) == 0, "an unreadable theme keeps the update pending")
try! FileManager.default.removeItem(at: store.url(forTitle: "LiteTheme")!)
let themeDefaults = UserDefaults(suiteName: "tex2img.shortcut.test")!
themeDefaults.removeObject(forKey: ThemeStore.bundledColorsUpdateKey)
try! store.write(earlierCopy("SolarizedDark"), title: "SolarizedDark")
ThemeLibrary.shared.prepare(defaults: themeDefaults)
check(themeDefaults.integer(forKey: ThemeStore.bundledColorsUpdateKey) == 2
      && near(store.read(title: "SolarizedDark")?["EditorHighlightContent"], [0.2, 0.188235, 0.039216]), "launch updates the copies once")
themeDefaults.removeObject(forKey: ThemeStore.bundledColorsUpdateKey)

// Migration of customized colors from an earlier profile.
var legacy: Profile = [:]
legacy[CommentColorForLightModeKey] = NSColor(deviceRed: 0, green: 0.5, blue: 0, alpha: 1).serializedString
legacy[CommandColorForLightModeKey] = NSColor.defaultCommandColorForLightMode.serializedString
legacy[CommentColorForDarkModeKey] = NSColor.defaultCommentColorForDarkMode.serializedString
controller.migrateLegacyColors(from: legacy)
check(themes.darkTitle == ThemeStore.defaultDarkTitle, "untouched dark colors keep the default theme")
check(themes.lightTitle != ThemeStore.defaultLightTitle, "customized light colors become a theme")
let migrated = store.read(title: themes.lightTitle)
let comment = ThemePalette.color(.comment, in: migrated, dark: false).usingColorSpace(.deviceRGB)!
check(comment.greenComponent > 0.4 && comment.redComponent < 0.1, "migrated comment color")
controller.migrateLegacyColors(from: legacy)
check(store.titles().filter { $0.hasPrefix(themes.lightTitle) }.count == 1, "migration does not duplicate themes")

// The whole window (sidebar, toolbar area and the selected category), drawn off screen.
settings.setSearchQuery("")
settings.select("Editor")
if let content = settings.window?.contentView {
    // Only light: off screen, the window background of dark mode is not drawn.
    for appearance in [NSAppearance.Name.aqua] {
        settings.window?.appearance = NSAppearance(named: appearance)
        content.layoutSubtreeIfNeeded()
        let rep = content.bitmapImageRepForCachingDisplay(in: content.bounds)!
        content.cacheDisplay(in: content.bounds, to: rep)
        try! rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("\(language)-window-\(appearance == .aqua ? "light" : "dark").png"))
    }
}

// The sidebar list fits its column at every sidebar width and cannot be scrolled sideways
// (as in TeXShop: a narrow sidebar used to leave the list wider than its column).
if let window = settings.window, let split = window.contentViewController as? NSSplitViewController,
   let table = all(NSTableView.self, in: split.splitViewItems[0].viewController.view).first,
   let listScroll = table.enclosingScrollView {
    let listClip = listScroll.contentView
    // Resizing must not be saved as the window's frame: the next run would start at that size.
    let autosaveName = window.frameAutosaveName
    window.setFrameAutosaveName("")
    let originalFrame = window.frame
    defer { window.setFrame(originalFrame, display: false); window.setFrameAutosaveName(autosaveName) }
    for windowWidth in [window.contentMinSize.width, 1040.0] {
        for sidebarWidth in [190.0, 300.0, 190.0, 250.0] {
            window.setContentSize(NSSize(width: windowWidth, height: 700))
            split.splitView.setPosition(sidebarWidth, ofDividerAt: 0)
            window.contentView?.layoutSubtreeIfNeeded()
            let place = "sidebar \(sidebarWidth), window \(windowWidth)"
            check(table.frame.width <= listClip.bounds.width + 0.5,
                  "sidebar list \(table.frame.width) fits its \(listClip.bounds.width)-point column, \(place)")
            check(!listScroll.hasHorizontalScroller && listScroll.horizontalScrollElasticity == .none,
                  "sidebar list has no horizontal scroller or horizontal bounce")
            var shifted = listClip.bounds
            shifted.origin.x = 60
            check(abs(listClip.constrainBoundsRect(shifted).origin.x) < 0.5,
                  "sidebar list cannot be scrolled sideways (\(listClip.constrainBoundsRect(shifted).origin.x)), \(place)")
        }
    }
} else {
    check(false, "the sidebar list is found")
}

// Menu shortcuts: a menu that is never shown, and defaults in the test home.
let menu = NSMenu(title: "Main")
func add(_ title: String, _ submenu: NSMenu) -> NSMenu {
    let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
    item.submenu = submenu
    submenu.title = title
    menu.addItem(item)
    return submenu
}
let file = add("File", NSMenu())
let save = file.addItem(withTitle: "Save", action: #selector(NSDocument.save(_:)), keyEquivalent: "s")
let open = file.addItem(withTitle: "Open", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o")
let edit = add("Edit", NSMenu())
let copy = edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
let print_ = file.addItem(withTitle: "Print", action: #selector(NSView.printView(_:)), keyEquivalent: "P")
let defaults = UserDefaults(suiteName: "tex2img.shortcut.test")!
defaults.removeObject(forKey: ShortcutStore.overridesKey)
// A new store reads the defaults from the menu, as at launch.
func relaunch() -> ShortcutStore {
    for (item, key) in [(save, "s"), (open, "o"), (copy, "c")] {
        item.keyEquivalent = key
        item.keyEquivalentModifierMask = .command
    }
    return ShortcutStore(menu: menu, defaults: defaults)
}
var shortcutStore = relaunch()
check(shortcutStore.commands.count == 4, "customizable commands")
check(save.identifier?.rawValue == "TSShortcut.saveDocument:.0", "TeXShop's identifier scheme")
check(shortcutStore.commands.first { $0.item === print_ }.map { ShortcutBinding($0.defaultKey, $0.defaultModifiers) } == ShortcutBinding("p", [.command, .shift]),
      "an upper-case key is Shift and the letter")
let saveCommand = shortcutStore.commands.first { $0.item === save }!
check(shortcutStore.setKey("o", modifiers: .command, for: saveCommand) != nil && save.keyEquivalent == "s", "a key used by another command is refused")
check(shortcutStore.setKey("x", modifiers: [], for: saveCommand) != nil, "a plain key is refused")
check(ShortcutKeys.isAllowed(key: String(UnicodeScalar(UInt8(0))), modifiers: .command) == false, "control characters are refused")
check(shortcutStore.setKey("k", modifiers: [.command, .option], for: saveCommand) == nil && save.keyEquivalent == "k"
      && save.keyEquivalentModifierMask == [.command, .option], "a new key is applied to the menu")
check(defaults.dictionary(forKey: ShortcutStore.overridesKey)?["TSShortcut.saveDocument:.0"] != nil, "the assignment is saved")
shortcutStore = relaunch()
check(save.keyEquivalent == "k", "a saved assignment is applied at launch")
check(ShortcutKeys.display(key: "k", modifiers: [.command, .option]) == "⌥⌘K" && ShortcutKeys.display(key: "P", modifiers: .command) == "⇧⌘P",
      "displayed keys")
// A saved key that a menu item now uses stays inactive and is listed as unavailable.
for (item, key) in [(save, "s"), (open, "o")] { item.keyEquivalent = key; item.keyEquivalentModifierMask = .command }
copy.keyEquivalent = "k"
copy.keyEquivalentModifierMask = [.command, .option]
shortcutStore = ShortcutStore(menu: menu, defaults: defaults)
check(save.keyEquivalent == "s" && shortcutStore.unavailableCommands == ["File › Save"], "a colliding saved key is inactive")
shortcutStore = relaunch()
let restored = shortcutStore.commands.first { $0.item === save }!
check(shortcutStore.restore(restored) == nil && save.keyEquivalent == "s" && defaults.object(forKey: ShortcutStore.overridesKey) == nil,
      "restore the default")
_ = shortcutStore.setKey("", modifiers: [], for: shortcutStore.commands.first { $0.item === open }!)
check(open.keyEquivalent == "" && shortcutStore.hasCustomShortcuts, "remove a shortcut")
shortcutStore.restoreAll()
check(open.keyEquivalent == "o" && !shortcutStore.hasCustomShortcuts, "restore all")
let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0, windowNumber: 0, context: nil,
                             characters: "c", charactersIgnoringModifiers: "c", isARepeat: false, keyCode: 8)!
check(shortcutStore.matches(for: event).map(\.path) == ["Edit › Copy"] && shortcutStore.matches(for: event).first?.winner == true, "search by key")
// A match that does not run for the key shows its path and, below it, the reason as a settings warning.
let copyAgain = edit.addItem(withTitle: "Copy Again", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
let pane = ShortcutPaneController()
pane.store = shortcutStore
let paneWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 400), styleMask: [.titled], backing: .buffered, defer: true)
paneWindow.contentView = pane.view
pane.window = paneWindow
pane.view.frame = paneWindow.contentView!.bounds
paneWindow.contentView!.layoutSubtreeIfNeeded()
_ = all(NSSegmentedControl.self, in: pane.view).first.map { control in
    control.selectedSegment = 1
    _ = control.target?.perform(control.action, with: control)
}
check(pane.searchingByKey && pane.handleKeySearchEvent(event), "start a key search")
let keyTable = all(NSTableView.self, in: pane.view).first!
check(keyTable.numberOfRows == 2, "two matches for the key: \(keyTable.numberOfRows)")
let winnerCell = pane.tableView(keyTable, viewFor: keyTable.tableColumns[0], row: 0) as? NSTextField
check(winnerCell?.stringValue.hasPrefix("Edit › Copy — ") == true && pane.tableView(keyTable, heightOfRow: 0) == keyTable.rowHeight,
      "the match that runs keeps one line")
let loserCell = pane.tableView(keyTable, viewFor: keyTable.tableColumns[0], row: 1)
check(loserCell?.identifier?.rawValue == "shortcut.inactive-command", "the inactive match is a warning cell")
let loserTexts = loserCell.map { all(NSTextField.self, in: $0).map(\.stringValue) } ?? []
check(loserTexts.first == "Edit › Copy Again" && loserTexts.last?.contains("Edit › Copy") == true && loserTexts.count == 2,
      "path above the reason: \(loserTexts)")
check(loserCell.map { !all(NSImageView.self, in: $0).isEmpty } == true, "the warning has the triangle")
let wideHeight = pane.tableView(keyTable, heightOfRow: 1)
keyTable.tableColumns[0].width = 120
let narrowHeight = pane.tableView(keyTable, heightOfRow: 1)
check(wideHeight > keyTable.rowHeight && narrowHeight > wideHeight, "the row grows with the wrapped reason: \(wideHeight) \(narrowHeight)")
keyTable.tableColumns[0].width = 330
keyTable.noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: 0..<keyTable.numberOfRows))
for appearance in [NSAppearance.Name.aqua, .darkAqua] {
    render(pane.view, width: 560, appearance: appearance, to: output.appendingPathComponent("key-search-\(language)-\(appearance == .aqua ? "light" : "dark").png"))
}
edit.removeItem(copyAgain)

// Recording in the list, as in Xcode and TeXShop 6.00: no sheet, the key goes into the row.
// render() took the pane out of its window.
func putPaneInWindow() {
    paneWindow.contentView = pane.view
    pane.view.frame = paneWindow.contentView!.bounds
    paneWindow.contentView!.layoutSubtreeIfNeeded()
}
putPaneInWindow()
pane.stopKeySearch()
pane.reloadCommands()
check(!all(NSButton.self, in: pane.view).contains { ["Change…", "Remove Shortcut", "変更…"].contains($0.title) }, "the recording sheet's buttons are gone")
check(keyTable.usesAlternatingRowBackgroundColors, "the list has striped rows")
func key(_ characters: String, _ flags: NSEvent.ModifierFlags = [], code: UInt16 = 0) -> NSEvent {
    NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: paneWindow.windowNumber, context: nil,
                     characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code)!
}
func statusText() -> String {
    (all(NSTextField.self, in: pane.view).first { $0.identifier?.rawValue == "shortcut.status-text" })?.stringValue ?? "<missing>"
}
func statusWarns() -> Bool {
    (all(NSStackView.self, in: pane.view).first { $0.identifier?.rawValue == "shortcut.status" })?.arrangedSubviews.first?.isHidden == false
}
func rowOf(_ item: NSMenuItem) -> Int {
    (0..<keyTable.numberOfRows).first { (pane.tableView(keyTable, viewFor: keyTable.tableColumns[0], row: $0) as? NSTextField)?.stringValue.hasSuffix(item.title) == true } ?? -1
}
let saveRow = rowOf(save)
check(saveRow >= 0, "Save is listed")
keyTable.selectRowIndexes(IndexSet(integer: saveRow), byExtendingSelection: false)
check(statusText() == String(format: NSLocalizedString("Default shortcut: %@", comment: ""), "⌘S") && !statusWarns(),
      "the line under the list shows the default shortcut: \(statusText())")
pane.beginRecording(at: saveRow)
check(pane.isRecording && paneWindow.firstResponder?.isKind(of: NSView.self) == true
      && (paneWindow.firstResponder as? NSView)?.identifier?.rawValue == "shortcut.recorder", "recording starts in the row")
check(pane.tableView(keyTable, viewFor: keyTable.tableColumns[1], row: saveRow)?.identifier?.rawValue == "shortcut.recording",
      "the shortcut cell is the recording field")
// A key used by another command is refused; recording goes on with the reason under the list and the triangle in the row.
check(pane.handleKeySearchEvent(key("o", .command, code: 31)) && pane.isRecording && save.keyEquivalent == "s", "a used key is refused")
check(statusText().contains("File › Open") && statusWarns(), "the refusal names the command: \(statusText())")
// Laid out by its constraints, as in the settings window, the line keeps its whole text.
let statusPaneFrame = pane.view.frame
_ = layOut(pane.view, width: 560)
let statusField = all(NSTextField.self, in: pane.view).first { $0.identifier?.rawValue == "shortcut.status-text" }!
check(statusField.frame.width >= ceil(statusField.attributedStringValue.size().width) - 1,
      "the refusal shows its whole text: \(statusField.frame.width) for \(statusField.attributedStringValue.size().width)")
pane.view.removeFromSuperview()
paneWindow.contentView = pane.view
pane.view.frame = statusPaneFrame
paneWindow.makeFirstResponder(all(NSView.self, in: pane.view).first { $0.identifier?.rawValue == "shortcut.recorder" })
let recordingWarning = all(NSImageView.self, in: pane.view).first { $0.identifier?.rawValue == "shortcut.recording-warning" }
check(recordingWarning?.isHidden == false, "the row shows the triangle while a key is refused")
check(pane.handleKeySearchEvent(key("x", code: 7)) && pane.isRecording && statusText().contains("F1"), "a plain key is refused")
// A free key is assigned at once and ends recording.
check(pane.handleKeySearchEvent(key("j", [.command, .option], code: 38)) && !pane.isRecording, "a free key ends recording")
check(save.keyEquivalent == "j" && save.keyEquivalentModifierMask == [.command, .option], "a free key is assigned at once")
check(!statusWarns() && statusText().contains("⌘S"), "the line shows the default again: \(statusText())")
// Escape keeps the shortcut; Delete removes it.
pane.beginRecording(at: rowOf(save))
check(pane.handleKeySearchEvent(key("\u{1b}", code: 53)) && !pane.isRecording && save.keyEquivalent == "j", "Escape ends recording")
pane.beginRecording(at: rowOf(save))
check(pane.handleKeySearchEvent(key("\u{7f}", code: 51)) && !pane.isRecording && save.keyEquivalent == "", "Delete removes the shortcut")
pane.beginRecording(at: rowOf(save))
check(recordingWarning?.superview.flatMap { all(NSButton.self, in: $0).first { $0.identifier?.rawValue == "shortcut.recorder-remove" } }?.isHidden == true,
      "no remove button for a command without a shortcut")
// A click elsewhere ends recording.
paneWindow.makeFirstResponder(keyTable)
check(!pane.isRecording, "moving the focus ends recording")
_ = shortcutStore.restore(shortcutStore.commands.first { $0.item === save }!)
check(save.keyEquivalent == "s", "restored for the next checks")

// Key search ends when the focus leaves the menu shortcut controls, and the field's cancel button forgets the key.
let keyView = all(NSView.self, in: pane.view).first { $0.identifier?.rawValue == "shortcut.key" }!
_ = all(NSSegmentedControl.self, in: pane.view).first.map { control in
    control.selectedSegment = 1
    _ = control.target?.perform(control.action, with: control)
}
check(pane.handleKeySearchEvent(event) && keyTable.numberOfRows == 1, "a key is searched")
check(keyView.isAccessibilitySelectorAllowed(#selector(NSView.accessibilityPerformCancel)) && keyView.accessibilityPerformCancel(),
      "the cancel button is offered while a key is shown")
check(pane.searchingByKey && keyTable.numberOfRows == keyTable.numberOfRows && !keyView.isAccessibilitySelectorAllowed(#selector(NSView.accessibilityPerformCancel)),
      "clearing forgets the key and stays in key search")
pane.windowFirstResponderChanged(keyTable)
check(pane.searchingByKey, "the list keeps key search")
// The settings search field of the sidebar, outside the pane.
pane.windowFirstResponderChanged(NSSearchField())
check(!pane.searchingByKey, "another control ends key search")
for appearance in [NSAppearance.Name.aqua, .darkAqua] {
    putPaneInWindow()
    keyTable.selectRowIndexes(IndexSet(integer: rowOf(save)), byExtendingSelection: false)
    pane.beginRecording(at: rowOf(save))
    _ = pane.handleKeySearchEvent(key("o", .command, code: 31))
    render(pane.view, width: 560, appearance: appearance, to: output.appendingPathComponent("recording-\(language)-\(appearance == .aqua ? "light" : "dark").png"))
    pane.endRecording()
    putPaneInWindow()
}
defaults.removePersistentDomain(forName: "tex2img.shortcut.test")
// The window remembers its category in the standard domain of this tool; leave nothing behind.
UserDefaults.standard.removePersistentDomain(forName: ProcessInfo.processInfo.processName)

print(report.joined(separator: "\n"))
print("Settings panel checks passed")
