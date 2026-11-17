import AppKit

/// The Themes category (identifier "Appearance"): choosing the light and dark themes and editing theme files.
/// Follows TeXShop's theme settings (TSPreferences-Color): a color change is written to the edited theme file at once
/// (the changes of one drag in the color panel together).
final class ThemeSettingsController: NSObject {
    let library: ThemeLibrary
    let lightPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    let darkPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    let editingPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    let importButton = NSPopUpButton(frame: .zero, pullsDown: true)
    private(set) var resetButton: NSButton!
    private(set) var newButton: NSButton!
    private(set) var wells: [ThemeRole: NSColorWell] = [:]
    private var editingColors: ThemeColors?
    /// Colors changed in the color panel and not yet written: a drag in the panel changes the color many times
    /// a second, and each write rereads and recolors the source.
    private var pendingColors: [ThemeRole: NSColor] = [:]
    private var pendingTitle: String?
    private static let saveDelay: TimeInterval = 0.2
    private var colorLabels: [SettingsLabel] = []
    /// The narrowest pane that shows the three columns of colors, known once the groups are made.
    private(set) var minimumPaneWidth: CGFloat = 0

    /// Called after the selected themes or the colors of a selected theme change.
    var colorsChanged: (() -> Void)?
    weak var window: NSWindow?

    var lightTitle: String { lightPopup.titleOfSelectedItem ?? ThemeStore.defaultLightTitle }
    var darkTitle: String { darkPopup.titleOfSelectedItem ?? ThemeStore.defaultDarkTitle }
    private var editingTitle: String? { editingPopup.titleOfSelectedItem }

    init(library: ThemeLibrary) {
        self.library = library
        super.init()
        for popup in [lightPopup, darkPopup] {
            popup.target = self
            popup.action = #selector(themeSelectionChanged(_:))
        }
        editingPopup.target = self
        editingPopup.action = #selector(editingThemeChanged(_:))
        importButton.addItem(withTitle: NSLocalizedString("Import from TeXShop", comment: ""))
        importButton.menu?.delegate = self
        resetButton = SettingsUI.makeButton(NSLocalizedString("Restore Original Colors…", comment: ""), target: self, action: #selector(restoreBundledTheme(_:)))
        newButton = SettingsUI.makeButton(NSLocalizedString("New Theme…", comment: ""), target: self, action: #selector(newTheme(_:)))
        for role in ThemeRole.allCases {
            let well = SettingsUI.makeColorWell(target: self, action: #selector(colorChanged(_:)))
            if #available(macOS 14.0, *) { well.supportsAlpha = role.usesOpacity }
            wells[role] = well
        }
        reloadThemeMenus()
        NotificationCenter.default.addObserver(self, selector: #selector(savePendingColors),
                                               name: NSApplication.willTerminateNotification, object: nil)
    }

    // MARK: Groups

    func groups() -> [NSView] {
        let themes = SettingsUI.group(NSLocalizedString("Theme", comment: ""), [
            SettingsUI.row(NSLocalizedString("Theme in Light Mode", comment: ""), lightPopup),
            SettingsUI.row(NSLocalizedString("Theme in Dark Mode", comment: ""), darkPopup),
        ])
        let editing = SettingsUI.group(NSLocalizedString("Editing Themes", comment: ""), [
            SettingsUI.row(NSLocalizedString("Theme to Edit", comment: ""), editingPopup),
            SettingsUI.buttonRow([importButton, resetButton, newButton],
                                 searchTitle: [NSLocalizedString("Import from TeXShop", comment: ""),
                                               NSLocalizedString("Restore Original Colors…", comment: ""),
                                               NSLocalizedString("New Theme…", comment: "")].joined(separator: "\n")),
        ])
        let colorGroups: [(String, [(ThemeRole, String)])] = [
            (NSLocalizedString("Colors: Source", comment: ""), [
                (.text, NSLocalizedString("Text", comment: "")),
                (.background, NSLocalizedString("Background", comment: "")),
                (.cursor, NSLocalizedString("Cursor", comment: "")),
                (.flash, NSLocalizedString("Flashing Background", comment: "")),
            ]),
            (NSLocalizedString("Colors: Syntax Highlighting", comment: ""), [
                (.comment, NSLocalizedString("% Comment", comment: "")),
                (.command, NSLocalizedString("\\command", comment: "")),
                (.marker, NSLocalizedString("{ } and $", comment: "")),
            ]),
            (NSLocalizedString("Colors: Highlighting", comment: ""), [
                (.highlightedBrace, NSLocalizedString("Highlighted Brackets", comment: "")),
                (.enclosedContent, NSLocalizedString("Enclosed Contents", comment: "")),
                (.invisible, NSLocalizedString("Invisible Characters", comment: "")),
                (.fullwidthSymbol, NSLocalizedString("Fullwidth Letters and Symbols", comment: "")),
                (.fullwidthBackground, NSLocalizedString("Fullwidth Letters and Symbols Background", comment: "")),
            ]),
            (NSLocalizedString("Colors: Output Window", comment: ""), [
                (.consoleText, NSLocalizedString("Text", comment: "")),
                (.consoleBackground, NSLocalizedString("Background", comment: "")),
            ]),
        ]
        // The columns line up from group to group: as wide as the longest name that does not take the empty columns
        // after it.
        let names = colorGroups.flatMap { _, items in
            items.enumerated().filter { !SettingsUI.colorItemIsMerged($0.offset, count: items.count) }.map(\.element.1)
        }
        let columnWidth = SettingsUI.colorColumnWidth(names)
        minimumPaneWidth = ceil(SettingsUI.colorGridWidth(columnWidth: columnWidth) + SettingsUI.paneContentInsets)
        return [themes, editing] + colorGroups.map { title, items in
            let (grid, labels) = SettingsUI.colorGrid(items.map { (wells[$0.0]!, $0.1) }, columnWidth: columnWidth)
            colorLabels += labels
            let row = SettingsUI.contentRow(grid, searchTitle: items.map(\.1).joined(separator: "\n"))
            return SettingsUI.group(title, [row])
        }
    }

    // MARK: Selection

    func reloadThemeMenus() {
        savePendingColors()
        library.invalidate()
        let titles = library.store.titles()
        let light = lightPopup.titleOfSelectedItem ?? ThemeStore.defaultLightTitle
        let dark = darkPopup.titleOfSelectedItem ?? ThemeStore.defaultDarkTitle
        let editing = editingPopup.titleOfSelectedItem
        for popup in [lightPopup, darkPopup, editingPopup] {
            popup.removeAllItems()
            popup.addItems(withTitles: titles)
        }
        select(light: light, dark: dark)
        if let editing, editingPopup.item(withTitle: editing) != nil {
            editingPopup.selectItem(withTitle: editing)
        }
    }

    /// Selects the themes of a profile. Missing themes fall back to TeX2img's defaults.
    func select(light: String, dark: String) {
        lightPopup.selectItem(withTitle: lightPopup.item(withTitle: light) != nil ? light : ThemeStore.defaultLightTitle)
        darkPopup.selectItem(withTitle: darkPopup.item(withTitle: dark) != nil ? dark : ThemeStore.defaultDarkTitle)
    }

    /// Shows the theme of the current appearance in the editor, as TeXShop does when Settings opens.
    func prepareForDisplay(dark: Bool) {
        reloadThemeMenus()
        editingPopup.selectItem(withTitle: dark ? darkTitle : lightTitle)
        loadEditingTheme()
    }

    @objc private func themeSelectionChanged(_ sender: NSPopUpButton) {
        colorsChanged?()
    }

    @objc private func editingThemeChanged(_ sender: NSPopUpButton) {
        loadEditingTheme()
    }

    private var editingIsDark: Bool {
        guard let title = editingTitle else { return false }
        if title == darkTitle && title != lightTitle { return true }
        if title == lightTitle { return false }
        // Themes not in use: judge by the background.
        let background = ThemePalette.color(editingColors, key: ThemeRole.background.key)?.usingColorSpace(.sRGB)
        return (background?.brightnessComponent ?? 1) < 0.5
    }

    private func loadEditingTheme() {
        savePendingColors()
        editingColors = editingTitle.flatMap { library.store.read(title: $0) }
        let enabled = editingColors != nil
        let dark = editingIsDark
        for (role, well) in wells {
            well.color = ThemePalette.color(role, in: editingColors, dark: dark)
            well.isEnabled = enabled
        }
        for label in colorLabels { label.isEnabled = enabled }
        newButton.isEnabled = enabled
        updateResetButton()
    }

    private func bundledColors(title: String) -> ThemeColors? {
        guard let directory = ThemeStore.bundledDirectory else { return nil }
        return ThemeStore(directory: directory).read(title: title)
    }

    private func updateResetButton() {
        guard let title = editingTitle, let original = bundledColors(title: title), let editingColors else {
            resetButton.isEnabled = false
            return
        }
        resetButton.isEnabled = !ThemePalette.sameColors(original, editingColors)
    }

    // MARK: Editing

    @objc private func colorChanged(_ sender: NSColorWell) {
        guard let role = wells.first(where: { $0.value === sender })?.key else { return }
        // A color panel left open for another window must not change a theme.
        let panelIsKey = NSColorPanel.sharedColorPanelExists && NSColorPanel.shared.isKeyWindow
        guard var colors = editingColors, let title = editingTitle, window?.isKeyWindow == true || panelIsKey else {
            sender.deactivate()
            sender.color = ThemePalette.color(role, in: editingColors, dark: editingIsDark)
            return
        }
        if pendingTitle != title { savePendingColors() }
        let color = role.usesOpacity ? sender.color : sender.color.withAlphaComponent(1)
        ThemePalette.set(color, for: role.key, in: &colors)
        editingColors = colors
        pendingTitle = title
        pendingColors[role] = color
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(savePendingColors), object: nil)
        perform(#selector(savePendingColors), with: nil, afterDelay: Self.saveDelay)
    }

    /// Writes the changed colors into the theme file as it is now: the file may have changed since it was read
    /// (another TeX2img, the one-time update of the bundled colors), and only the changed colors replace its own.
    @objc private func savePendingColors() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(savePendingColors), object: nil)
        guard let title = pendingTitle, !pendingColors.isEmpty else { return }
        let changed = pendingColors
        pendingColors = [:]
        pendingTitle = nil
        library.invalidate(title: title)
        guard var colors = library.store.read(title: title) ?? (title == editingTitle ? editingColors : nil) else { return }
        for (role, color) in changed {
            ThemePalette.set(color, for: role.key, in: &colors)
        }
        save(colors, title: title)
        if title == editingTitle {
            for (role, well) in wells where changed[role] == nil {
                well.color = ThemePalette.color(role, in: colors, dark: editingIsDark)
            }
        }
    }

    private func save(_ colors: ThemeColors, title: String) {
        do {
            try library.store.write(colors, title: title)
            editingColors = colors
        } catch {
            library.invalidate(title: title)
            loadEditingTheme()
            showError(NSLocalizedString("The theme could not be saved. Its last saved colors have been restored.", comment: ""))
            return
        }
        library.invalidate(title: title)
        updateResetButton()
        if title == lightTitle || title == darkTitle { colorsChanged?() }
    }

    @objc private func restoreBundledTheme(_ sender: Any?) {
        savePendingColors()
        guard let title = editingTitle, let original = bundledColors(title: title), let window else { return }
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("Restore the original colors of “%@”?", comment: ""), title)
        alert.addButton(withTitle: NSLocalizedString("Restore", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn, let self else { return }
            self.save(original, title: title)
            self.loadEditingTheme()
        }
    }

    @objc private func newTheme(_ sender: Any?) {
        savePendingColors()
        guard let colors = editingColors else { return }
        requestTitle(for: colors)
    }

    private func requestTitle(for colors: ThemeColors, suggested: String = "") {
        guard let window, window.attachedSheet == nil else { return }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("New Theme", comment: "")
        alert.informativeText = String(format: NSLocalizedString("Enter a name for the copy of “%@”.", comment: ""), editingTitle ?? "")
        let field = NSTextField(string: suggested)
        field.frame = NSRect(x: 0, y: 0, width: 260, height: 24)
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        alert.addButton(withTitle: NSLocalizedString("Create", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn, let self else { return }
            let title = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return }
            self.store(colors, as: title)
        }
    }

    /// Saves a new theme file, asking before an existing theme is replaced.
    private func store(_ colors: ThemeColors, as title: String) {
        savePendingColors()
        guard library.store.url(forTitle: title) != nil else {
            DispatchQueue.main.async {
                self.showError(NSLocalizedString("Choose another theme name. Names beginning with a dot, path separators, control characters, and symbolic links are not allowed.", comment: ""))
            }
            return
        }
        let write = { [weak self] in
            guard let self else { return }
            do {
                try self.library.store.write(colors, title: title)
            } catch {
                self.showError(NSLocalizedString("The new theme could not be saved. The original theme is unchanged.", comment: ""))
                return
            }
            self.library.invalidate(title: title)
            self.reloadThemeMenus()
            self.editingPopup.selectItem(withTitle: title)
            self.loadEditingTheme()
            if title == self.lightTitle || title == self.darkTitle { self.colorsChanged?() }
        }
        guard library.store.contains(title: title), let window else { write(); return }
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = String(format: NSLocalizedString("The theme “%@” already exists. Replace it?", comment: ""), title)
            alert.addButton(withTitle: NSLocalizedString("Replace", comment: "")).hasDestructiveAction = true
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn { write() }
            }
        }
    }

    // MARK: TeXShop

    /// TeXShop themes that TeX2img does not have, or has with other colors.
    func importableTeXShopThemes() -> [String] {
        let texShop = ThemeStore(directory: ThemeStore.texShopDirectory)
        return texShop.titles().filter { title in
            guard let colors = texShop.read(title: title) else { return false }
            guard let own = library.store.read(title: title) else { return true }
            return !ThemePalette.sameUsedColors(colors, own)
        }
    }

    @objc private func importTeXShopTheme(_ sender: NSMenuItem) {
        let title = sender.title
        guard let colors = ThemeStore(directory: ThemeStore.texShopDirectory).read(title: title) else { return }
        store(colors, as: title)
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        if let window, window.attachedSheet == nil {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}

extension ThemeSettingsController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        while menu.items.count > 1 { menu.removeItem(at: 1) }
        let titles = importableTeXShopThemes()
        if titles.isEmpty {
            let item = NSMenuItem(title: NSLocalizedString("No TeXShop Themes to Import", comment: ""), action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }
        for title in titles {
            let item = NSMenuItem(title: title, action: #selector(importTeXShopTheme(_:)), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
    }
}
