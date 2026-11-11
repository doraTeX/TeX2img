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

func render(_ view: NSView, width: CGFloat, appearance: NSAppearance.Name, to url: URL) {
    let host = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 100))
    host.appearance = NSAppearance(named: appearance)
    host.wantsLayer = true
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
check(settings.categories.map(\.identifier) == ["General", "Image", "Conversion", "After Generation", "Editor", "Appearance", "Keyboard"], "category order")

controller.themeSettings.prepareForDisplay(dark: false)

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
        render(pane, width: 640, appearance: appearance, to: output.appendingPathComponent(name))
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
defaults.removePersistentDomain(forName: "tex2img.shortcut.test")

print(report.joined(separator: "\n"))
print("Settings panel checks passed")
