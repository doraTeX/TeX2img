import AppKit

/// The Themes category (identifier "Appearance"): choosing the light and dark themes and editing theme files.
/// Follows TeXShop's theme settings (TSPreferences-Color): a color change is written to the edited theme file at once
/// (the changes of one drag in the color panel together). The themes are listed as in TeXShop 6.00 (TSSettingsThemeList):
/// ＋, − and the actions menu under the list, and the same actions in each row's contextual menu. A theme that comes with
/// TeX2img cannot be renamed or deleted; one whose colors differ from TeX2img's copy can be restored.
final class ThemeSettingsController: NSObject {
    let library: ThemeLibrary
    let lightPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    let darkPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    /// The list of themes and the bar under it.
    let themeTable = ThemeListTable()
    private(set) var addButton: NSButton!
    private(set) var removeButton: NSButton!
    let actionsButton = NSPopUpButton(frame: .zero, pullsDown: true)
    private let contextMenu = NSMenu()
    private(set) var listView: NSView!
    /// The themes of the list, and the one whose colors the wells show.
    private(set) var listTitles: [String] = []
    private(set) var editingTitle: String?
    private var reloadingList = false
    private(set) var wells: [ThemeRole: NSColorWell] = [:]
    /// "Use system color" under the wells of the cursor and the selection (ThemeSystemColor).
    private(set) var systemColorSwitches: [ThemeRole: NSButton] = [:]
    private var editingColors: ThemeColors?
    /// Colors changed in the color panel and not yet written: a drag in the panel changes the color many times
    /// a second, and each write rereads and recolors the source.
    private var pendingColors: [ThemeRole: NSColor] = [:]
    private var pendingTitle: String?
    private static let saveDelay: TimeInterval = 0.2
    private static let visibleRows = 8, rowHeight: CGFloat = 24
    private var colorLabels: [SettingsLabel] = []
    /// The narrowest pane that shows the three columns of colors, known once the groups are made.
    private(set) var minimumPaneWidth: CGFloat = 0

    /// Called after the selected themes or the colors of a selected theme change.
    var colorsChanged: (() -> Void)?
    /// Called after a theme is renamed in the list: the saved profiles that name it follow.
    var themeRenamed: ((_ old: String, _ new: String) -> Void)?
    weak var window: NSWindow?

    var lightTitle: String { lightPopup.titleOfSelectedItem ?? ThemeStore.defaultLightTitle }
    var darkTitle: String { darkPopup.titleOfSelectedItem ?? ThemeStore.defaultDarkTitle }

    init(library: ThemeLibrary) {
        self.library = library
        super.init()
        for popup in [lightPopup, darkPopup] {
            popup.target = self
            popup.action = #selector(themeSelectionChanged(_:))
        }
        for role in ThemeRole.allCases {
            let well = SettingsUI.makeColorWell(target: self, action: #selector(colorChanged(_:)))
            if #available(macOS 14.0, *) { well.supportsAlpha = role.usesOpacity }
            wells[role] = well
        }
        for role in ThemeSystemColor.roles {
            systemColorSwitches[role] = SettingsUI.makeColorSwitch(NSLocalizedString("Use system color", comment: ""),
                                                                    target: self, action: #selector(systemColorSwitchChanged(_:)))
        }
        buildList()
        reloadThemeMenus()
        // The accent or highlight color changed in System Settings: the wells of the switches that are on show it.
        NotificationCenter.default.addObserver(self, selector: #selector(systemColorsChanged(_:)),
                                               name: NSColor.systemColorsDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(savePendingColors),
                                               name: NSApplication.willTerminateNotification, object: nil)
    }

    // MARK: Groups

    func groups() -> [NSView] {
        let themes = SettingsUI.group(NSLocalizedString("Theme", comment: ""), [
            SettingsUI.row(NSLocalizedString("Theme in Light Mode", comment: ""), lightPopup),
            SettingsUI.row(NSLocalizedString("Theme in Dark Mode", comment: ""), darkPopup),
        ])
        // The list takes the width of the card; the colors below edit the theme chosen in it.
        let listRow = SettingsUI.contentRow(listView, searchTitle: [
            NSLocalizedString("New Theme", comment: ""), NSLocalizedString("Duplicate", comment: ""),
            NSLocalizedString("Rename", comment: ""), NSLocalizedString("Restore", comment: ""),
            NSLocalizedString("Delete", comment: ""), NSLocalizedString("Move to Trash", comment: ""),
            NSLocalizedString("Export…", comment: ""), NSLocalizedString("Import…", comment: ""),
            NSLocalizedString("Show in Finder", comment: ""), NSLocalizedString("Import from TeXShop", comment: ""),
        ].joined(separator: "\n"))
        listView.trailingAnchor.constraint(equalTo: listRow.trailingAnchor, constant: -12).isActive = true
        let editing = SettingsUI.group(NSLocalizedString("Editing Themes", comment: ""), [listRow])
        let colorGroups: [(String, [(ThemeRole, String)])] = [
            // The cursor and the selection, with their switches, on the second row together.
            (NSLocalizedString("Colors: Source", comment: ""), [
                (.text, NSLocalizedString("Text", comment: "")),
                (.background, NSLocalizedString("Background", comment: "")),
                (.flash, NSLocalizedString("Flashing Background", comment: "")),
                (.cursor, NSLocalizedString("Cursor", comment: "")),
                (.selection, NSLocalizedString("Selection", comment: "")),
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
        // A switch in a column of its own (the cursor's) must fit the column too.
        let switchWidth = systemColorSwitches.values.map { ceil($0.intrinsicContentSize.width) }.max() ?? 0
        let columnWidth = max(SettingsUI.colorColumnWidth(names), switchWidth)
        minimumPaneWidth = ceil(SettingsUI.colorGridWidth(columnWidth: columnWidth) + SettingsUI.paneContentInsets)
        let switchTitle = NSLocalizedString("Use system color", comment: "")
        return [themes, editing] + colorGroups.map { title, items in
            var switches: [Int: NSButton] = [:]
            for (index, item) in items.enumerated() { switches[index] = systemColorSwitches[item.0] }
            let (grid, labels) = SettingsUI.colorGrid(items.map { (wells[$0.0]!, $0.1) }, columnWidth: columnWidth, switches: switches)
            colorLabels += labels
            let names = items.map(\.1) + (switches.isEmpty ? [] : [switchTitle])
            let row = SettingsUI.contentRow(grid, searchTitle: names.joined(separator: "\n"))
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
        for popup in [lightPopup, darkPopup] {
            popup.removeAllItems()
            popup.addItems(withTitles: titles)
        }
        select(light: light, dark: dark)
        if let editing = editingTitle, !titles.contains(editing) { editingTitle = nil }
        reloadList()
    }

    /// Selects the themes of a profile. Missing themes fall back to TeX2img's defaults.
    func select(light: String, dark: String) {
        lightPopup.selectItem(withTitle: lightPopup.item(withTitle: light) != nil ? light : ThemeStore.defaultLightTitle)
        darkPopup.selectItem(withTitle: darkPopup.item(withTitle: dark) != nil ? dark : ThemeStore.defaultDarkTitle)
        reloadListMarks()
    }

    /// Shows the theme of the current appearance in the editor, as TeXShop does when Settings opens.
    func prepareForDisplay(dark: Bool) {
        reloadThemeMenus()
        chooseTheme(dark ? darkTitle : lightTitle)
    }

    @objc private func themeSelectionChanged(_ sender: NSPopUpButton) {
        reloadListMarks()
        colorsChanged?()
    }

    /// Edits the colors of a theme of the list (nil: none).
    func chooseTheme(_ title: String?) {
        savePendingColors()
        editingTitle = title.flatMap { listTitles.contains($0) ? $0 : nil }
        selectListRow(editingTitle)
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
        refreshSystemColorControls()
        updateListButtons()
    }

    /// The switches of the edited theme, and their wells: a well whose switch is on cannot be changed and shows the
    /// system's color as the Settings window draws it; the theme's color stays in the theme.
    private func refreshSystemColorControls() {
        let enabled = editingColors != nil
        for role in ThemeSystemColor.roles {
            guard let box = systemColorSwitches[role], let well = wells[role] else { continue }
            let on = ThemeSystemColor.uses(role, in: editingColors)
            box.state = on ? .on : .off
            box.isEnabled = enabled
            well.isEnabled = enabled && !on
            if on, let system = ThemeSystemColor.systemColor(role) {
                well.color = settingsWindowColor(system)
            } else {
                well.color = ThemePalette.color(role, in: editingColors, dark: editingIsDark)
            }
        }
    }

    /// A system color as the Settings window draws it.
    private func settingsWindowColor(_ color: NSColor) -> NSColor {
        let appearance = window?.effectiveAppearance ?? NSApp.effectiveAppearance
        var resolved = color
        appearance.performAsCurrentDrawingAppearance { resolved = color.usingColorSpace(.sRGB) ?? color }
        return resolved
    }

    @objc private func systemColorsChanged(_ notification: Notification) {
        if editingColors != nil { refreshSystemColorControls() }
    }

    /// Turns a switch on or off; the theme's color stays. A theme without a selection color turned off gets one, so
    /// that what is drawn does not change at once: the color of the bundled theme of the same name, or else the
    /// system's as it is drawn now.
    @objc private func systemColorSwitchChanged(_ sender: NSButton) {
        guard let role = systemColorSwitches.first(where: { $0.value === sender })?.key, let key = ThemeSystemColor.key(role) else { return }
        // The state clicked, taken before the colors still waiting are saved: saving them shows the switches as the
        // file has them.
        let on = sender.state == .on
        savePendingColors()
        guard let title = editingTitle, var colors = library.store.read(title: title) ?? editingColors else {
            refreshSystemColorControls()
            return
        }
        colors[key] = on
        if !on, role == .selection, ThemePalette.color(colors, key: role.key) == nil {
            if let bundled = bundledColors(title: title), let color = ThemePalette.components(bundled, key: role.key) {
                colors[role.key] = [color[0], color[1], color[2], 1].map { NSNumber(value: $0) }
            } else if let system = ThemeSystemColor.systemColor(role) {
                ThemePalette.set(settingsWindowColor(system).withAlphaComponent(1), for: role.key, in: &colors)
            }
        }
        library.invalidate(title: title)
        save(colors, title: title)
        refreshSystemColorControls()
    }

    private func bundledColors(title: String) -> ThemeColors? {
        guard let directory = ThemeStore.bundledDirectory else { return nil }
        return ThemeStore(directory: directory).read(title: title)
    }

    /// The theme comes with TeX2img.
    func isBundled(_ title: String) -> Bool { bundledColors(title: title) != nil }

    /// The theme comes with TeX2img and its colors differ from TeX2img's copy: it can be restored.
    func isChanged(_ title: String) -> Bool {
        guard let original = bundledColors(title: title), let colors = library.store.read(title: title) else { return false }
        return !ThemePalette.sameSharedColors(colors, original)
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
        // A theme renamed or deleted elsewhere meanwhile is not made again (save tells it is missing).
        for (role, color) in changed {
            ThemePalette.set(color, for: role.key, in: &colors)
        }
        save(colors, title: title)
        if title == editingTitle {
            for (role, well) in wells where changed[role] == nil {
                well.color = ThemePalette.color(role, in: colors, dark: editingIsDark)
            }
            refreshSystemColorControls()
        }
    }

    private func save(_ colors: ThemeColors, title: String) {
        do {
            // Only over the theme's own file: a theme renamed or deleted elsewhere is not made again under its old name.
            try library.store.write(colors, title: title, existing: true)
            editingColors = colors
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            library.invalidate(title: title)
            themeWentMissing(title)
            return
        } catch {
            library.invalidate(title: title)
            loadEditingTheme()
            showError(NSLocalizedString("The theme could not be saved. Its last saved colors have been restored.", comment: ""))
            return
        }
        library.invalidate(title: title)
        refreshListRow(title)
        if title == lightTitle || title == darkTitle { colorsChanged?() }
    }

    // MARK: List

    private func buildList() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("title"))
        column.resizingMask = .autoresizingMask
        column.minWidth = 40
        column.width = 40
        themeTable.addTableColumn(column)
        themeTable.headerView = nil
        if #available(macOS 11.0, *) { themeTable.style = .inset }
        themeTable.rowHeight = Self.rowHeight
        themeTable.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        themeTable.allowsEmptySelection = false
        themeTable.backgroundColor = .clear
        themeTable.dataSource = self
        themeTable.delegate = self
        themeTable.identifier = NSUserInterfaceItemIdentifier("settings.theme-list.table")
        themeTable.setAccessibilityLabel(NSLocalizedString("Editing Themes", comment: ""))
        themeTable.registerForDraggedTypes([.fileURL])
        themeTable.setDraggingSourceOperationMask(.copy, forLocal: false)
        contextMenu.delegate = self
        themeTable.menu = contextMenu

        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.hasHorizontalScroller = false
        scroll.automaticallyAdjustsContentInsets = false
        scroll.horizontalScrollElasticity = .none
        scroll.documentView = themeTable
        // The names take the visible width of the list, never more: the list never scrolls sideways.
        scroll.contentView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(fitListColumn), name: NSView.frameDidChangeNotification, object: scroll.contentView)

        func barButton(_ symbol: String, _ toolTip: String, _ action: Selector) -> NSButton {
            let image = NSImage(systemSymbolName: symbol, accessibilityDescription: toolTip) ?? NSImage()
            let button = NSButton(image: image, target: self, action: action)
            button.isBordered = false
            button.imageScaling = .scaleProportionallyDown
            button.toolTip = toolTip
            button.widthAnchor.constraint(equalToConstant: 24).isActive = true
            button.heightAnchor.constraint(equalToConstant: 22).isActive = true
            return button
        }
        addButton = barButton("plus", NSLocalizedString("New Theme", comment: ""), #selector(addTheme(_:)))
        removeButton = barButton("minus", NSLocalizedString("Move the Theme to the Trash", comment: ""), #selector(deleteTheme(_:)))
        addButton.identifier = NSUserInterfaceItemIdentifier("settings.theme-list.add")
        removeButton.identifier = NSUserInterfaceItemIdentifier("settings.theme-list.remove")
        let left = NSStackView(views: [addButton, removeButton])
        left.spacing = 4
        left.alignment = .centerY
        left.translatesAutoresizingMaskIntoConstraints = false
        actionsButton.isBordered = false
        actionsButton.toolTip = NSLocalizedString("Theme Actions", comment: "")
        actionsButton.identifier = NSUserInterfaceItemIdentifier("settings.theme-list.actions")
        let icon = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        icon.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: actionsButton.toolTip)
        actionsButton.menu?.addItem(icon)
        actionsButton.menu?.delegate = self
        actionsButton.translatesAutoresizingMaskIntoConstraints = false
        actionsButton.heightAnchor.constraint(equalToConstant: 22).isActive = true
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        let bar = NSView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        for child in [separator, left, actionsButton] { bar.addSubview(child) }

        let frame = ThemeListFrame()
        frame.translatesAutoresizingMaskIntoConstraints = false
        frame.identifier = NSUserInterfaceItemIdentifier("settings.theme-list.frame")
        frame.addSubview(scroll)
        frame.addSubview(bar)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: frame.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: frame.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: frame.trailingAnchor),
            scroll.heightAnchor.constraint(equalToConstant: CGFloat(Self.visibleRows) * Self.rowHeight + 12),
            bar.topAnchor.constraint(equalTo: scroll.bottomAnchor),
            bar.leadingAnchor.constraint(equalTo: frame.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: frame.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: frame.bottomAnchor),
            separator.topAnchor.constraint(equalTo: bar.topAnchor),
            separator.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: left.topAnchor, constant: -6),
            left.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 12),
            left.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -8),
            actionsButton.centerYAnchor.constraint(equalTo: left.centerYAnchor),
            actionsButton.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -12),
            actionsButton.leadingAnchor.constraint(greaterThanOrEqualTo: left.trailingAnchor, constant: 8),
        ])
        listView = frame
    }

    @objc private func fitListColumn() {
        guard let column = themeTable.tableColumns.first, let clip = themeTable.enclosingScrollView?.contentView else { return }
        let visible = clip.bounds.width
        var inset: CGFloat = 0
        if #available(macOS 11.0, *), themeTable.effectiveStyle == .inset { inset = 10 }
        let width = max(column.minWidth, visible - themeTable.intercellSpacing.width - 2 * inset)
        if abs(column.width - width) > 0.5 { column.width = width }
        if abs(themeTable.frame.width - visible) > 0.5 { themeTable.setFrameSize(NSSize(width: visible, height: themeTable.frame.height)) }
    }

    /// Reads the folder again and selects the theme being edited.
    private func reloadList() {
        reloadingList = true
        listTitles = library.store.titles()
        themeTable.reloadData()
        selectListRow(editingTitle)
        reloadingList = false
        updateListButtons()
    }

    private func reloadListMarks() {
        guard !listTitles.isEmpty else { return }
        themeTable.reloadData(forRowIndexes: IndexSet(integersIn: 0..<listTitles.count), columnIndexes: IndexSet(integer: 0))
    }

    private func refreshListRow(_ title: String) {
        guard let row = listTitles.firstIndex(of: title) else { return }
        themeTable.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        updateListButtons()
    }

    private func selectListRow(_ title: String?) {
        let wasReloading = reloadingList
        reloadingList = true
        if let title, let row = listTitles.firstIndex(of: title) {
            themeTable.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            themeTable.scrollRowToVisible(row)
        } else {
            themeTable.deselectAll(nil)
        }
        reloadingList = wasReloading
    }

    private var selectedListTitle: String? {
        let row = themeTable.selectedRow
        return listTitles.indices.contains(row) ? listTitles[row] : nil
    }

    /// The row of the contextual menu, else the selected row.
    private var targetListTitle: String? {
        let row = themeTable.clickedRow
        return listTitles.indices.contains(row) ? listTitles[row] : selectedListTitle
    }

    private func updateListButtons() {
        removeButton?.isEnabled = selectedListTitle.map { !isBundled($0) } ?? false
    }

    /// The popups and the list learn of a theme added (old nil), renamed, or moved to the Trash (new nil): the themes of
    /// Light and Dark Mode follow a rename, and fall back to TeX2img's defaults when theirs is deleted.
    private func themeListChanged(from old: String?, to new: String?, choose: String?) {
        savePendingColors()
        var light = lightTitle, dark = darkTitle
        if let old, old == light { light = new ?? ThemeStore.defaultLightTitle }
        if let old, old == dark { dark = new ?? ThemeStore.defaultDarkTitle }
        let usedChanged = light != lightTitle || dark != darkTitle || (old != nil && (old == lightTitle || old == darkTitle))
        library.invalidate()
        if let old, old == editingTitle { editingTitle = nil }
        let titles = library.store.titles()
        for popup in [lightPopup, darkPopup] {
            popup.removeAllItems()
            popup.addItems(withTitles: titles)
        }
        select(light: light, dark: dark)
        reloadList()
        chooseTheme(choose.flatMap { listTitles.contains($0) ? $0 : nil } ?? editingTitle ?? (listTitles.contains(light) ? light : listTitles.first))
        if usedChanged { colorsChanged?() }
    }

    /// The theme being edited is no longer in the folder (renamed or deleted elsewhere): says so, and edits another.
    private func themeWentMissing(_ title: String) {
        showError(String(format: NSLocalizedString("“%@” is no longer in the Themes folder.", comment: ""), title))
        themeListChanged(from: title, to: nil, choose: nil)
    }

    private func showListError(_ error: Error, title: String) {
        let code = (error as? CocoaError)?.code
        let format: String?
        switch code {
        case .fileWriteFileExists?: format = NSLocalizedString("A theme named “%@” already exists.", comment: "")
        case .fileWriteInvalidFileName?: format = NSLocalizedString("“%@” cannot be the name of a theme.", comment: "")
        case .fileReadCorruptFile?: format = NSLocalizedString("“%@” is not a theme.", comment: "")
        case .fileNoSuchFile?, .fileReadNoSuchFile?:
            format = errorIsAboutTheme(error, title: title) ? NSLocalizedString("“%@” is no longer in the Themes folder.", comment: "") : nil
        default: format = nil
        }
        showError(format.map { String(format: $0, title) } ?? error.localizedDescription)
    }

    /// The error is about the theme's own file in the Themes folder, not a file elsewhere (where it was to be exported, or a
    /// file to import).
    private func errorIsAboutTheme(_ error: Error, title: String) -> Bool {
        let info = (error as NSError).userInfo
        guard let path = info[NSFilePathErrorKey] as? String ?? (info[NSURLErrorKey] as? URL)?.path else { return false }
        if path == title { return true }
        return library.store.url(forTitle: title).map { $0.standardizedFileURL.path == (path as NSString).standardizingPath } ?? false
    }

    // MARK: List actions

    /// A new theme has the colors of TeX2img's theme for the appearance of the Settings window.
    @objc func addTheme(_ sender: Any?) {
        let dark = (window?.effectiveAppearance ?? NSApp.effectiveAppearance).bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        guard let colors = bundledColors(title: dark ? ThemeStore.defaultDarkTitle : ThemeStore.defaultLightTitle)
                ?? library.store.read(title: dark ? ThemeStore.defaultDarkTitle : ThemeStore.defaultLightTitle) else { return }
        let untitled = NSLocalizedString("Untitled", comment: "")
        do {
            let title = try library.store.add(colors, title: untitled)
            themeListChanged(from: nil, to: title, choose: title)
            beginEditingName(title)
        } catch {
            showListError(error, title: untitled)
        }
    }

    @objc func duplicateTheme(_ sender: Any?) {
        // A color changed a moment ago is in the theme before it is copied.
        savePendingColors()
        guard let title = targetListTitle, let colors = library.store.read(title: title) else { return }
        let proposed = String(format: NSLocalizedString("%@ copy", comment: ""), title)
        do {
            let copy = try library.store.add(colors, title: proposed)
            themeListChanged(from: nil, to: copy, choose: copy)
        } catch {
            showListError(error, title: proposed)
        }
    }

    @objc func renameTheme(_ sender: Any?) {
        guard let title = targetListTitle, !isBundled(title) else { return }
        chooseTheme(title)
        beginEditingName(title)
    }

    /// Renames a theme's file; the themes of Light and Dark Mode follow it. Says why when it cannot.
    @discardableResult
    func renameTheme(_ old: String, to new: String) -> Bool {
        savePendingColors()
        do {
            try library.store.rename(old, to: new)
        } catch {
            showListError(error, title: new)
            return false
        }
        themeListChanged(from: old, to: new, choose: new)
        themeRenamed?(old, new)
        return true
    }

    private func beginEditingName(_ title: String) {
        guard let row = listTitles.firstIndex(of: title), themeTable.window != nil else { return }
        themeTable.editColumn(0, row: row, with: nil, select: true)
    }

    /// Puts back the colors of the theme that comes with TeX2img, after asking.
    @objc func restoreTheme(_ sender: Any?) {
        savePendingColors()
        guard let title = targetListTitle, let original = bundledColors(title: title), let window else { return }
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("Restore the original colors of “%@”?", comment: ""), title)
        alert.addButton(withTitle: NSLocalizedString("Restore", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn, let self else { return }
            self.save(original, title: title)
            if title == self.editingTitle { self.loadEditingTheme() }
            self.refreshListRow(title)
        }
    }

    @objc func deleteTheme(_ sender: Any?) {
        guard let title = targetListTitle, !isBundled(title), let window, window.attachedSheet == nil else { return }
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("Move “%@” to the Trash?", comment: ""), title)
        alert.addButton(withTitle: NSLocalizedString("Move to Trash", comment: "")).hasDestructiveAction = true
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            self?.trashTheme(title)
        }
    }

    func trashTheme(_ title: String) {
        savePendingColors()
        let row = listTitles.firstIndex(of: title)
        do {
            try library.store.trash(title)
        } catch {
            showListError(error, title: title)
            return
        }
        // The theme after it takes its place, or the one before it at the end of the list.
        let remaining = library.store.titles()
        let next = row.flatMap { remaining.isEmpty ? nil : remaining[min($0, remaining.count - 1)] }
        themeListChanged(from: title, to: nil, choose: editingTitle == title ? next : editingTitle)
    }

    /// Exported is what can be imported again: a theme that is gone, cannot be opened, or is not one is not offered, and
    /// the reason is told.
    @objc func exportTheme(_ sender: Any?) {
        savePendingColors()
        guard let title = targetListTitle, let window else { return }
        guard let colors = library.store.read(title: title), ThemeStore.isTheme(colors) else {
            if library.store.contains(title: title) {
                showError(String(format: NSLocalizedString("“%@” is not a theme.", comment: ""), title))
            } else {
                showError(String(format: NSLocalizedString("“%@” is no longer in the Themes folder.", comment: ""), title))
            }
            return
        }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = title + ".plist"
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            do { try self.library.store.export(title, to: url) } catch { self.showListError(error, title: title) }
        }
    }

    @objc func importThemes(_ sender: Any?) {
        guard let window else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.beginSheetModal(for: window) { [weak self] response in
            if response == .OK { _ = self?.importURLs(panel.urls) }
        }
    }

    /// Adds the theme files under their names (with a number when a name is taken); returns the titles given.
    @discardableResult
    func importURLs(_ urls: [URL]) -> [String] {
        var imported: [String] = []
        for url in urls {
            do {
                imported.append(try library.store.importFile(at: url))
            } catch {
                showListError(error, title: url.lastPathComponent)
            }
        }
        if let last = imported.last { themeListChanged(from: nil, to: last, choose: last) }
        return imported
    }

    @objc func showThemeInFinder(_ sender: Any?) {
        guard let title = targetListTitle, let url = library.store.url(forTitle: title) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    /// Copies a TeXShop theme, asking before a theme of the same name is replaced.
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
            self.themeListChanged(from: nil, to: title, choose: title)
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
            return !ThemePalette.sameUsedColors(colors, own, bundled: bundledColors(title: title))
        }
    }

    @objc private func importTeXShopTheme(_ sender: NSMenuItem) {
        let title = sender.title
        guard let colors = ThemeStore(directory: ThemeStore.texShopDirectory).read(title: title) else { return }
        store(colors, as: title)
    }

    /// Where messages go instead of an alert (the tests, which show no window).
    var presentMessage: ((String) -> Void)?

    private func showError(_ message: String) {
        if let presentMessage { presentMessage(message); return }
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

extension ThemeSettingsController: NSMenuDelegate, NSMenuItemValidation {
    /// The actions menu names the selected theme; the contextual menu names none, as in Finder and CotEditor. The TeXShop
    /// themes that TeX2img does not have, or has with other colors, are offered in a submenu of the actions menu.
    func menuNeedsUpdate(_ menu: NSMenu) {
        if menu.identifier?.rawValue == "settings.theme-list.texshop" {
            menu.removeAllItems()
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
            return
        }
        let context = menu === contextMenu
        let title = context ? targetListTitle : selectedListTitle
        let icon = context ? nil : menu.items.first
        menu.removeAllItems()
        if let icon { menu.addItem(icon) }
        if context && themeTable.clickedRow < 0 { return }
        func named(_ plain: String, _ format: String) -> String {
            context ? NSLocalizedString(plain, comment: "") : String(format: NSLocalizedString(format, comment: ""), title ?? "")
        }
        func add(_ text: String, _ action: Selector) -> NSMenuItem {
            let item = menu.addItem(withTitle: text, action: action, keyEquivalent: "")
            item.target = self
            return item
        }
        if title != nil {
            _ = add(named("Duplicate", "Duplicate “%@”"), #selector(duplicateTheme(_:)))
            _ = add(named("Rename", "Rename “%@”"), #selector(renameTheme(_:)))
            _ = add(named("Restore", "Restore “%@”"), #selector(restoreTheme(_:)))
            if context { _ = add(NSLocalizedString("Delete", comment: ""), #selector(deleteTheme(_:))) }
            _ = add(named("Export…", "Export “%@”…"), #selector(exportTheme(_:)))
            let finder = add(named("Show in Finder", "Show “%@” in Finder"), #selector(showThemeInFinder(_:)))
            finder.isAlternate = true
            finder.keyEquivalentModifierMask = .option
        }
        if !context {
            if title != nil { menu.addItem(.separator()) }
            _ = add(NSLocalizedString("Import…", comment: ""), #selector(importThemes(_:)))
            let texShop = menu.addItem(withTitle: NSLocalizedString("Import from TeXShop", comment: ""), action: nil, keyEquivalent: "")
            let submenu = NSMenu(title: texShop.title)
            submenu.identifier = NSUserInterfaceItemIdentifier("settings.theme-list.texshop")
            submenu.delegate = self
            texShop.submenu = submenu
        }
    }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        let title = item.menu === contextMenu ? targetListTitle : selectedListTitle
        switch item.action {
        case #selector(importThemes(_:)), #selector(importTeXShopTheme(_:)): return true
        case #selector(renameTheme(_:)), #selector(deleteTheme(_:)): return title.map { !isBundled($0) } ?? false
        case #selector(restoreTheme(_:)): return title.map(isChanged) ?? false
        default: return title != nil
        }
    }
}

extension ThemeSettingsController: NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int { listTitles.count }

    private func mark(_ symbol: String, _ description: String, pointSize: CGFloat) -> NSImageView {
        var image = NSImage(systemSymbolName: symbol, accessibilityDescription: description) ?? NSImage()
        image = image.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)) ?? image
        let view = NSImageView(image: image)
        view.contentTintColor = .secondaryLabelColor
        view.toolTip = description
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard listTitles.indices.contains(row) else { return nil }
        let title = listTitles[row]
        let bundled = isBundled(title)
        let cell = NSTableCellView()
        let field = NSTextField(string: title)
        field.isBordered = false
        field.drawsBackground = false
        field.isEditable = !bundled
        field.delegate = self
        field.lineBreakMode = .byTruncatingTail
        field.allowsExpansionToolTips = true
        field.translatesAutoresizingMaskIntoConstraints = false
        // A theme's name is the user's own: Settings search does not index it.
        field.setAccessibilityIdentifier("settings.user-data")
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cell.textField = field
        cell.addSubview(field)
        var marks: [NSView] = []
        if bundled && isChanged(title) { marks.append(mark("circle.fill", NSLocalizedString("Customized", comment: ""), pointSize: 6)) }
        if title == lightTitle { marks.append(mark("sun.max", NSLocalizedString("Theme in Light Mode", comment: ""), pointSize: 12)) }
        if title == darkTitle { marks.append(mark("moon", NSLocalizedString("Theme in Dark Mode", comment: ""), pointSize: 12)) }
        let stack = NSStackView(views: marks)
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setContentHuggingPriority(.required, for: .horizontal)
        cell.addSubview(stack)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
            field.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: field.trailingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
            stack.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        cell.identifier = NSUserInterfaceItemIdentifier("settings.theme-list.row." + title)
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateListButtons()
        guard !reloadingList, let title = selectedListTitle, title != editingTitle else { return }
        chooseTheme(title)
    }

    /// Renaming in the list renames the theme's file.
    func controlTextDidEndEditing(_ notification: Notification) {
        guard let field = notification.object as? NSTextField else { return }
        let row = themeTable.row(for: field)
        guard listTitles.indices.contains(row) else { return }
        let old = listTitles[row]
        // Composed, as the names of the list.
        let new = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).precomposedStringWithCanonicalMapping
        guard !new.isEmpty, new != old else { field.stringValue = old; return }
        if !renameTheme(old, to: new) { field.stringValue = old }
    }

    /// Theme files dropped on the list are added; a row dragged out is a copy of its file.
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if info.draggingSource as? NSTableView === tableView { return [] }
        let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        guard urls.contains(where: { $0.pathExtension.lowercased() == "plist" }) else { return [] }
        tableView.setDropRow(-1, dropOperation: .on)
        return .copy
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        return !importURLs(urls.filter { $0.pathExtension.lowercased() == "plist" }).isEmpty
    }

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        guard listTitles.indices.contains(row) else { return nil }
        return library.store.url(forTitle: listTitles[row]) as NSURL?
    }
}

/// The list of themes.
final class ThemeListTable: NSTableView {}

/// The rounded frame around the list and its bar, drawn in the separator color of the current appearance.
final class ThemeListFrame: NSView {
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {
        guard let layer else { return }
        layer.cornerRadius = 6
        layer.borderWidth = 1
        layer.masksToBounds = true
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer.borderColor = NSColor.separatorColor.cgColor
            layer.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }
    }
}
