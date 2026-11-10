import AppKit

/// One category of the settings sidebar.
struct SettingsCategory {
    let identifier: String
    let title: String
    let summary: String
    let symbol: String
    let color: NSColor
    /// Leaves a gap above this category in the sidebar.
    let startsGroup: Bool
    let view: NSView

    static func rgb(_ value: Int) -> NSColor {
        NSColor(srgbRed: CGFloat((value >> 16) & 255) / 255, green: CGFloat((value >> 8) & 255) / 255, blue: CGFloat(value & 255) / 255, alpha: 1)
    }
}

/// A setting found by the search field.
struct SettingsSearchResult {
    let category: String
    let title: String
    weak var row: SettingsRowView?
    /// A menu command found in the Keyboard category.
    var command: String? = nil
}

/// The settings window in the manner of System Settings: a sidebar with search,
/// back and forward in the toolbar, and the selected category on the right.
final class SettingsWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, NSToolbarDelegate, NSSearchFieldDelegate, NSWindowDelegate {
    static let selectedCategoryKey = "SettingsSelectedCategory"
    private static let dividerItem = NSToolbarItem.Identifier("settings.divider")
    private static let navigationItem = NSToolbarItem.Identifier("settings.navigation")

    let categories: [SettingsCategory]
    private let splitController = NSSplitViewController()
    private let categoryTable = NSTableView()
    private let searchField = NSSearchField()
    private let searchStatus = NSTextField(wrappingLabelWithString: "")
    private var searchStatusHeight: NSLayoutConstraint!
    private let contentScroll = NSScrollView()
    private let navigationControl: NSSegmentedControl
    private var history: [String] = []
    private var historyIndex = -1
    private var searchQuery = ""
    private var searchResults: [SettingsSearchResult] = []
    private var selectedResult: Int?
    private var highlights: [NSView] = []
    private var synchronizingSelection = false
    /// Gets every key press first while a pane records keys (search by key).
    var keyEventHandler: ((NSEvent) -> Bool)?
    /// Called before another category is shown.
    var willDisplayCategory: ((String) -> Void)?
    /// Menu command names offered by the search field, in the given category.
    var commandSearch: (category: String, names: () -> [String], show: (String) -> Void)?

    var currentIdentifier: String? { history.indices.contains(historyIndex) ? history[historyIndex] : nil }

    init(categories: [SettingsCategory]) {
        self.categories = categories
        let back = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: NSLocalizedString("Back", comment: "")) ?? NSImage()
        let forward = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: NSLocalizedString("Forward", comment: "")) ?? NSImage()
        navigationControl = NSSegmentedControl(images: [back, forward], trackingMode: .momentary, target: nil, action: nil)
        let window = SettingsWindow(contentRect: NSRect(x: 0, y: 0, width: 860, height: 640),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: true)
        super.init(window: window)
        window.settingsController = self
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.toolbarStyle = .unified
        window.titlebarSeparatorStyle = .automatic
        window.contentMinSize = NSSize(width: 780, height: 480)
        window.tabbingMode = .disallowed
        window.collectionBehavior.insert(.fullScreenNone)
        buildContent()
        window.setContentSize(NSSize(width: 860, height: 640))
        window.center()
        window.setFrameAutosaveName("SettingsWindow")
        let saved = UserDefaults.standard.string(forKey: Self.selectedCategoryKey)
        let first = categories.contains { $0.identifier == saved } ? saved! : categories[0].identifier
        visit(first)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: Building

    private func buildContent() {
        guard let window else { return }
        let sidebar = NSViewController()
        sidebar.view = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 600))
        let listScroll = NSScrollView()
        listScroll.translatesAutoresizingMaskIntoConstraints = false
        listScroll.drawsBackground = false
        listScroll.hasVerticalScroller = true
        categoryTable.style = .sourceList
        categoryTable.headerView = nil
        categoryTable.rowHeight = 30
        categoryTable.intercellSpacing = NSSize(width: 0, height: 2)
        categoryTable.allowsEmptySelection = true
        categoryTable.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        categoryTable.dataSource = self
        categoryTable.delegate = self
        categoryTable.setAccessibilityLabel(NSLocalizedString("Settings Categories", comment: ""))
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("category"))
        column.width = 200
        categoryTable.addTableColumn(column)
        listScroll.documentView = categoryTable
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = NSLocalizedString("Search Settings", comment: "")
        searchField.setAccessibilityLabel(searchField.placeholderString)
        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(searchChanged(_:))
        searchField.sendsSearchStringImmediately = true
        searchStatus.translatesAutoresizingMaskIntoConstraints = false
        searchStatus.textColor = .secondaryLabelColor
        searchStatus.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        searchStatus.isHidden = true
        searchStatusHeight = searchStatus.heightAnchor.constraint(equalToConstant: 0)
        searchStatusHeight.isActive = true
        for view in [searchField, searchStatus, listScroll] { sidebar.view.addSubview(view) }
        NSLayoutConstraint.activate([
            searchField.leadingAnchor.constraint(equalTo: sidebar.view.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: sidebar.view.trailingAnchor, constant: -10),
            searchField.topAnchor.constraint(equalTo: sidebar.view.safeAreaLayoutGuide.topAnchor, constant: 6),
            searchStatus.leadingAnchor.constraint(equalTo: searchField.leadingAnchor),
            searchStatus.trailingAnchor.constraint(equalTo: searchField.trailingAnchor),
            searchStatus.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 4),
            listScroll.topAnchor.constraint(equalTo: searchStatus.bottomAnchor, constant: 4),
            listScroll.leadingAnchor.constraint(equalTo: sidebar.view.leadingAnchor),
            listScroll.trailingAnchor.constraint(equalTo: sidebar.view.trailingAnchor),
            listScroll.bottomAnchor.constraint(equalTo: sidebar.view.bottomAnchor),
        ])
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebar)
        sidebarItem.minimumThickness = 190
        sidebarItem.maximumThickness = 300
        sidebarItem.canCollapse = false
        splitController.addSplitViewItem(sidebarItem)

        let content = NSViewController()
        content.view = NSView(frame: NSRect(x: 0, y: 0, width: 640, height: 600))
        contentScroll.translatesAutoresizingMaskIntoConstraints = false
        contentScroll.hasVerticalScroller = true
        contentScroll.autohidesScrollers = true
        contentScroll.drawsBackground = false
        // As in System Settings, the content scrolls under the toolbar; AppKit insets it by the
        // titlebar height and draws the scroll edge effect (macOS 26 and later).
        contentScroll.automaticallyAdjustsContentInsets = true
        content.view.addSubview(contentScroll)
        NSLayoutConstraint.activate([
            contentScroll.leadingAnchor.constraint(equalTo: content.view.leadingAnchor),
            contentScroll.trailingAnchor.constraint(equalTo: content.view.trailingAnchor),
            contentScroll.topAnchor.constraint(equalTo: content.view.topAnchor),
            contentScroll.bottomAnchor.constraint(equalTo: content.view.bottomAnchor),
        ])
        let contentItem = NSSplitViewItem(viewController: content)
        contentItem.minimumThickness = 560
        splitController.addSplitViewItem(contentItem)
        window.contentViewController = splitController

        navigationControl.target = self
        navigationControl.action = #selector(navigate(_:))
        navigationControl.setToolTip(NSLocalizedString("Back", comment: ""), forSegment: 0)
        navigationControl.setToolTip(NSLocalizedString("Forward", comment: ""), forSegment: 1)
        navigationControl.setAccessibilityLabel(NSLocalizedString("Navigation History", comment: ""))
        let toolbar = NSToolbar(identifier: "TeX2imgSettingsToolbar")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
        categoryTable.reloadData()
    }

    // MARK: Showing

    func show() {
        guard let window else { return }
        if !window.isVisible {
            clearSearch()
            displayCurrentCategory()
        }
        window.makeKeyAndOrderFront(nil)
    }

    func category(_ identifier: String) -> SettingsCategory? {
        categories.first { $0.identifier == identifier }
    }

    /// Shows a category and adds it to the history.
    @discardableResult
    func select(_ identifier: String) -> Bool {
        guard category(identifier) != nil, window?.attachedSheet == nil else { return false }
        if identifier == currentIdentifier {
            applyHighlight()
            return true
        }
        guard window?.makeFirstResponder(nil) ?? true else { return false }
        visit(identifier)
        return true
    }

    private func visit(_ identifier: String) {
        if historyIndex < history.count - 1 { history.removeSubrange((historyIndex + 1)...) }
        history.append(identifier)
        historyIndex = history.count - 1
        displayCurrentCategory()
    }

    @objc func goBack(_ sender: Any?) {
        guard historyIndex > 0, window?.attachedSheet == nil, window?.makeFirstResponder(nil) ?? true else { return }
        historyIndex -= 1
        displayCurrentCategory()
    }

    @objc func goForward(_ sender: Any?) {
        guard historyIndex < history.count - 1, window?.attachedSheet == nil, window?.makeFirstResponder(nil) ?? true else { return }
        historyIndex += 1
        displayCurrentCategory()
    }

    @objc private func navigate(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 { goBack(sender) } else { goForward(sender) }
    }

    private func displayCurrentCategory() {
        guard let identifier = currentIdentifier, let category = category(identifier) else { return }
        willDisplayCategory?(identifier)
        clearHighlights()
        let pane = category.view
        let document = SettingsDocumentView()
        document.translatesAutoresizingMaskIntoConstraints = false
        pane.removeFromSuperview()
        pane.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(pane)
        contentScroll.documentView = document
        let width = document.widthAnchor.constraint(equalTo: contentScroll.contentView.widthAnchor)
        NSLayoutConstraint.activate([
            width,
            pane.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            pane.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            pane.topAnchor.constraint(equalTo: document.topAnchor),
            pane.bottomAnchor.constraint(equalTo: document.bottomAnchor),
        ])
        window?.title = category.title
        document.setAccessibilityLabel(category.title)
        scrollContentToTop()
        UserDefaults.standard.set(identifier, forKey: Self.selectedCategoryKey)
        synchronizeSidebarSelection()
        updateNavigation()
        window?.recalculateKeyViewLoop()
        applyHighlight()
    }

    /// The top of the content is below the toolbar: the clip view starts above the document by the top inset.
    private func scrollContentToTop() {
        contentScroll.layoutSubtreeIfNeeded()
        contentScroll.contentView.scroll(to: NSPoint(x: 0, y: -contentScroll.contentInsets.top))
        contentScroll.reflectScrolledClipView(contentScroll.contentView)
    }

    private func updateNavigation() {
        navigationControl.setEnabled(historyIndex > 0, forSegment: 0)
        navigationControl.setEnabled(historyIndex < history.count - 1, forSegment: 1)
    }

    // MARK: Sidebar

    /// Category identifiers with "" for the gaps between sidebar groups.
    private var sidebarRows: [String] {
        categories.flatMap { $0.startsGroup ? ["", $0.identifier] : [$0.identifier] }
    }

    private func synchronizeSidebarSelection() {
        var index: Int?
        if searchQuery.isEmpty {
            index = currentIdentifier.flatMap { sidebarRows.firstIndex(of: $0) }
        } else if let selectedResult, searchResults[selectedResult].category == currentIdentifier {
            index = selectedResult
        }
        synchronizingSelection = true
        categoryTable.selectRowIndexes(index.map { IndexSet(integer: $0) } ?? IndexSet(), byExtendingSelection: false)
        synchronizingSelection = false
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        searchQuery.isEmpty ? sidebarRows.count : searchResults.count
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        searchQuery.isEmpty ? !sidebarRows[row].isEmpty : true
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if !searchQuery.isEmpty { return 44 }
        return sidebarRows[row].isEmpty ? 8 : 30
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSTableCellView()
        if !searchQuery.isEmpty {
            let result = searchResults[row]
            let name = NSTextField(labelWithString: result.title)
            name.lineBreakMode = .byTruncatingTail
            let place = NSTextField(labelWithString: category(result.category)?.title ?? "")
            place.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            place.textColor = .secondaryLabelColor
            for label in [name, place] {
                label.translatesAutoresizingMaskIntoConstraints = false
                label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(249), for: .horizontal)
                cell.addSubview(label)
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
                    label.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -8),
                ])
            }
            NSLayoutConstraint.activate([
                name.topAnchor.constraint(equalTo: cell.topAnchor, constant: 5),
                place.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 2),
            ])
            cell.textField = name
            cell.toolTip = "\(result.title) — \(place.stringValue)"
            return cell
        }
        let identifier = sidebarRows[row]
        guard let category = category(identifier) else {
            let space = NSView()
            space.setAccessibilityElement(false)
            return space
        }
        let icon = SettingsIconView(symbolName: category.symbol, color: category.color, size: 22)
        let label = NSTextField(labelWithString: category.title)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        cell.addSubview(icon)
        cell.addSubview(label)
        cell.textField = label
        cell.toolTip = category.summary
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 6),
            icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -4),
            label.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
        ])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !synchronizingSelection else { return }
        let row = categoryTable.selectedRow
        if searchQuery.isEmpty {
            guard sidebarRows.indices.contains(row), !select(sidebarRows[row]) else { return }
        } else {
            guard searchResults.indices.contains(row) else { return }
            let previous = selectedResult
            selectedResult = row
            guard !select(searchResults[row].category) else { return }
            selectedResult = previous
        }
        synchronizeSidebarSelection()
    }

    // MARK: Toolbar

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.dividerItem, Self.navigationItem]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.dividerItem, Self.navigationItem]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == Self.dividerItem {
            return NSTrackingSeparatorToolbarItem(identifier: itemIdentifier, splitView: splitController.splitView, dividerIndex: 0)
        }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.view = navigationControl
        item.isNavigational = true
        item.label = NSLocalizedString("Navigation History", comment: "")
        return item
    }

    // MARK: Search

    @objc private func searchChanged(_ sender: NSSearchField) {
        if (sender.currentEditor() as? NSTextView)?.hasMarkedText() == true { return }
        setSearchQuery(sender.stringValue)
    }

    func controlTextDidChange(_ notification: Notification) {
        guard notification.object as? NSSearchField === searchField else { return }
        searchChanged(searchField)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard control === searchField, commandSelector == #selector(NSResponder.cancelOperation(_:)), !textView.hasMarkedText() else { return false }
        setSearchQuery("")
        searchField.stringValue = ""
        return true
    }

    private func clearSearch() {
        searchField.stringValue = ""
        setSearchQuery("")
    }

    static func normalized(_ text: String) -> String {
        let folded = text.precomposedStringWithCompatibilityMapping
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
        return folded.applyingTransform(.hiraganaToKatakana, reverse: false) ?? folded
    }

    static func tokens(_ query: String) -> [String] {
        normalized(query).components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }

    func setSearchQuery(_ query: String) {
        let tokens = Self.tokens(query)
        searchQuery = tokens.isEmpty ? "" : query
        selectedResult = nil
        searchResults = []
        clearHighlights()
        if !tokens.isEmpty {
            for category in categories {
                for entry in Self.searchEntries(in: category.view) {
                    let haystack = Self.normalized([entry.title, entry.note, entry.group, category.title].joined(separator: " "))
                    guard tokens.allSatisfy({ haystack.contains($0) }) else { continue }
                    searchResults.append(SettingsSearchResult(category: category.identifier, title: entry.title, row: entry.row))
                }
            }
            if let commandSearch, let category = category(commandSearch.category) {
                for name in commandSearch.names() {
                    let haystack = Self.normalized(name + " " + category.title)
                    guard tokens.allSatisfy({ haystack.contains($0) }) else { continue }
                    searchResults.append(SettingsSearchResult(category: category.identifier, title: name, row: nil, command: name))
                }
            }
        }
        searchStatus.isHidden = tokens.isEmpty
        searchStatusHeight.isActive = tokens.isEmpty
        searchStatus.stringValue = tokens.isEmpty ? "" : searchResults.isEmpty
            ? NSLocalizedString("No Settings Found", comment: "")
            : String.localizedStringWithFormat(NSLocalizedString("Settings results: %ld", comment: ""), searchResults.count)
        synchronizingSelection = true
        categoryTable.reloadData()
        synchronizingSelection = false
        synchronizeSidebarSelection()
        NSAccessibility.post(element: searchStatus, notification: .valueChanged)
    }

    struct SearchEntry {
        let title: String
        let note: String
        let group: String
        let row: SettingsRowView
    }

    static func searchEntries(in view: NSView, group: String = "") -> [SearchEntry] {
        var group = group
        if view.identifier?.rawValue == "group",
           let heading = view.subviews.first(where: { $0.identifier?.rawValue == "group.heading" }) as? NSTextField {
            group = heading.stringValue
        }
        if let row = view as? SettingsRowView {
            return row.searchTitle.components(separatedBy: "\n").filter { !$0.isEmpty }
                .map { SearchEntry(title: $0, note: row.searchNote, group: group, row: row) }
        }
        return view.subviews.flatMap { searchEntries(in: $0, group: group) }
    }

    private func clearHighlights() {
        highlights.forEach { $0.removeFromSuperview() }
        highlights.removeAll()
    }

    private func applyHighlight() {
        clearHighlights()
        guard let selectedResult, searchResults.indices.contains(selectedResult),
              searchResults[selectedResult].category == currentIdentifier else { return }
        if let command = searchResults[selectedResult].command {
            commandSearch?.show(command)
            return
        }
        guard let row = searchResults[selectedResult].row else { return }
        row.superview?.layoutSubtreeIfNeeded()
        let overlay = SettingsSearchHighlight(frame: row.bounds)
        overlay.autoresizingMask = [.width, .height]
        row.addSubview(overlay)
        highlights.append(overlay)
        row.scrollToVisible(row.bounds.insetBy(dx: 0, dy: -24))
    }

    // MARK: Window

    func windowWillClose(_ notification: Notification) {
        clearHighlights()
        NotificationCenter.default.post(name: Self.willCloseNotification, object: self)
    }

    static let willCloseNotification = Notification.Name("TeX2imgSettingsWindowWillClose")
}

/// ⌘[ and ⌘] go back and forward, as in System Settings.
final class SettingsWindow: NSWindow {
    weak var settingsController: SettingsWindowController?

    // While a pane searches by key, it gets keys before the table's type selection and the menus.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, isKeyWindow, attachedSheet == nil, settingsController?.keyEventHandler?(event) == true { return }
        super.sendEvent(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if isKeyWindow, attachedSheet == nil, settingsController?.keyEventHandler?(event) == true { return true }
        if flags == .command, attachedSheet == nil, let controller = settingsController {
            switch event.charactersIgnoringModifiers {
            case "[": controller.goBack(self); return true
            case "]": controller.goForward(self); return true
            default: break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
