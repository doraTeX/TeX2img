import AppKit
import Carbon.HIToolbox

/// The view that has focus while searching by key; every key press is a query.
private final class KeySearchView: NSView {
    var handleEvent: ((NSEvent) -> Bool)?
    override var acceptsFirstResponder: Bool { true }
    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .textField }
    override func accessibilityLabel() -> String? { NSLocalizedString("Search by Key", comment: "") }
    override func keyDown(with event: NSEvent) { _ = performKeyEquivalent(with: event) }
    override func performKeyEquivalent(with event: NSEvent) -> Bool { handleEvent?(event) ?? false }
}

/// Records the key pressed in the Change Shortcut sheet. Return applies, Escape cancels, Tab moves the focus.
private final class ShortcutRecorder: NSView {
    var record: ((NSEvent) -> Void)?
    var accept: (() -> Void)?
    var cancel: (() -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .textField }
    override func accessibilityLabel() -> String? { NSLocalizedString("Change Shortcut", comment: "") }
    override func accessibilityHelp() -> String? { NSLocalizedString("New shortcut", comment: "") }
    override func keyDown(with event: NSEvent) { _ = performKeyEquivalent(with: event) }
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let key = event.charactersIgnoringModifiers ?? ""
        let flags = event.modifierFlags.intersection(ShortcutBinding.modifierMask)
        if key == "\r" && flags.isEmpty { accept?(); return true }
        if key == "\u{1b}" && flags.isEmpty { cancel?(); return true }
        if (key == "\t" || key == "\u{19}") && flags.subtracting(.shift).isEmpty {
            if flags.contains(.shift) || key == "\u{19}" { window?.selectPreviousKeyView(self) } else { window?.selectNextKeyView(self) }
            return true
        }
        record?(event)
        return true
    }
}

private final class ShortcutCapturePanel: NSPanel {
    var recorder: ShortcutRecorder?
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let key = event.charactersIgnoringModifiers ?? ""
        let flags = event.modifierFlags.intersection(ShortcutBinding.modifierMask)
        let buttonNavigation = ((key == "\t" || key == "\u{19}") && flags.subtracting(.shift).isEmpty) || ((key == "\r" || key == " ") && flags.isEmpty)
        if firstResponder !== recorder && buttonNavigation { return super.performKeyEquivalent(with: event) }
        return recorder?.performKeyEquivalent(with: event) ?? false
    }
}

/// The menu shortcuts group of the Keyboard category (TeXShop's TSShortcutPaneController without macros).
final class ShortcutPaneController: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    var store: ShortcutStore? { didSet { reloadCommands() } }
    /// Tab is reserved when it completes commands.
    var completionUsesTab: () -> Bool = { false }
    weak var window: NSWindow?

    let view = NSView()
    private(set) var searchingByKey = false
    private let search = NSSearchField()
    private let searchMode: NSSegmentedControl
    private let keySearchView = KeySearchView()
    private let hint = NSTextField(wrappingLabelWithString: "")
    private let table = NSTableView()
    private var selectionButtons: [NSButton] = []
    private var textQuery = ""
    private var searchEvent: NSEvent?
    private var searchMatches: [ShortcutMatch] = []
    private var visibleCommands: [ShortcutCommand] = []
    private var capturePanel: ShortcutCapturePanel?
    private var editingCommand: ShortcutCommand?
    private let captureDisplay = NSTextField(labelWithString: "")
    private let captureError = NSTextField(wrappingLabelWithString: "")
    private var applyButton: NSButton!
    private var capturedBindings: [ShortcutBinding] = []
    private var capturedBinding: ShortcutBinding?

    override init() {
        searchMode = NSSegmentedControl(labels: [NSLocalizedString("Search by Function", comment: ""), NSLocalizedString("Search by Key", comment: "")],
                                        trackingMode: .selectOne, target: nil, action: nil)
        super.init()
        buildView()
    }

    private func buildView() {
        search.placeholderString = NSLocalizedString("Search commands", comment: "")
        search.delegate = self
        searchMode.target = self
        searchMode.action = #selector(changeSearchMode(_:))
        searchMode.selectedSegment = 0
        searchMode.setContentHuggingPriority(.required, for: .horizontal)
        searchMode.setContentCompressionResistancePriority(.required, for: .horizontal)
        keySearchView.isHidden = true
        keySearchView.handleEvent = { [weak self] event in self?.handleKeySearchEvent(event) ?? false }
        hint.textColor = .secondaryLabelColor
        hint.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.automaticallyAdjustsContentInsets = false
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 22
        table.style = .inset
        table.usesAlternatingRowBackgroundColors = false
        table.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        table.target = self
        table.doubleAction = #selector(editShortcut(_:))
        let command = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("command"))
        command.title = NSLocalizedString("Command", comment: "")
        command.width = 330
        command.minWidth = 200
        let shortcut = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("shortcut"))
        shortcut.title = NSLocalizedString("Shortcut", comment: "")
        shortcut.width = 110
        shortcut.minWidth = 90
        table.addTableColumn(command)
        table.addTableColumn(shortcut)
        scroll.documentView = table
        let edit = smallButton("Change…", #selector(editShortcut(_:)))
        let remove = smallButton("Remove Shortcut", #selector(removeShortcut(_:)))
        let restore = smallButton("Restore Default", #selector(restoreShortcut(_:)))
        let all = smallButton("Restore All…", #selector(restoreAll(_:)))
        selectionButtons = [edit, remove, restore]
        let spacer = NSView()
        spacer.setContentHuggingPriority(NSLayoutConstraint.Priority(249), for: .horizontal)
        let buttons = NSStackView(views: [edit, remove, restore, spacer, all])
        buttons.orientation = .horizontal
        buttons.spacing = 8
        for subview in [search, searchMode, keySearchView, hint, scroll, buttons] as [NSView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            search.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            search.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            search.trailingAnchor.constraint(equalTo: searchMode.leadingAnchor, constant: -8),
            search.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            searchMode.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            searchMode.centerYAnchor.constraint(equalTo: search.centerYAnchor),
            keySearchView.leadingAnchor.constraint(equalTo: search.leadingAnchor),
            keySearchView.trailingAnchor.constraint(equalTo: search.trailingAnchor),
            keySearchView.topAnchor.constraint(equalTo: search.topAnchor),
            keySearchView.bottomAnchor.constraint(equalTo: search.bottomAnchor),
            hint.topAnchor.constraint(equalTo: search.bottomAnchor, constant: 6),
            hint.leadingAnchor.constraint(equalTo: search.leadingAnchor),
            hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            scroll.topAnchor.constraint(equalTo: hint.bottomAnchor, constant: 4),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            scroll.heightAnchor.constraint(equalToConstant: 320),
            buttons.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 6),
            buttons.leadingAnchor.constraint(equalTo: search.leadingAnchor),
            buttons.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            buttons.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
        ])
        reloadCommands()
    }

    private func smallButton(_ title: String, _ action: Selector) -> NSButton {
        let button = NSButton(title: NSLocalizedString(title, comment: ""), target: self, action: action)
        button.controlSize = .small
        button.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        return button
    }

    // MARK: Listing

    private func reloadFunctionCommands() {
        if let unavailable = store?.unavailableCommands, !unavailable.isEmpty {
            hint.stringValue = "\(NSLocalizedString("Shortcut Unavailable", comment: "")): \(unavailable.joined(separator: ", "))"
        } else {
            hint.stringValue = ""
        }
        let tokens = SettingsWindowController.tokens(search.stringValue)
        visibleCommands = (store?.commands ?? []).filter { command in
            guard !command.item.isHidden || command.item.allowsKeyEquivalentWhenHidden else { return false }
            let text = SettingsWindowController.normalized(command.path)
            return tokens.allSatisfy { text.contains($0) }
        }
        table.reloadData()
        updateSelectionButtons()
    }

    func reloadCommands() {
        if searchingByKey { updateKeyResults() } else { reloadFunctionCommands() }
    }

    /// Shows the commands matching a settings search, as TeXShop does for menu command names.
    func showCommand(_ path: String) {
        stopKeySearch()
        search.stringValue = path
        reloadFunctionCommands()
        if let index = visibleCommands.firstIndex(where: { $0.path == path }) {
            table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            table.scrollRowToVisible(index)
        }
    }

    func commandPaths() -> [String] {
        (store?.commands ?? []).filter { !$0.item.isHidden || $0.item.allowsKeyEquivalentWhenHidden }.map(\.path)
    }

    func controlTextDidChange(_ notification: Notification) {
        if !searchingByKey { reloadCommands() }
    }

    // MARK: Search by key

    @objc private func changeSearchMode(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 || searchingByKey { stopKeySearch(); return }
        textQuery = search.stringValue
        searchingByKey = true
        search.isEditable = false
        searchEvent = nil
        keySearchView.isHidden = false
        search.stringValue = ""
        reloadFunctionCommands()
        search.placeholderString = NSLocalizedString("Press a key", comment: "")
        updateKeyResults()
        window?.makeFirstResponder(keySearchView)
    }

    func stopKeySearch() {
        guard searchingByKey else { return }
        searchingByKey = false
        searchMode.selectedSegment = 0
        searchEvent = nil
        searchMatches = []
        keySearchView.isHidden = true
        search.isEditable = true
        search.stringValue = textQuery
        search.placeholderString = NSLocalizedString("Search commands", comment: "")
        reloadCommands()
    }

    /// While searching by key, the settings window passes every key press here first.
    func handleKeySearchEvent(_ event: NSEvent) -> Bool {
        guard searchingByKey else { return false }
        guard event.type == .keyDown else { return true }
        if event.modifierFlags.intersection(ShortcutBinding.modifierMask).isEmpty && event.charactersIgnoringModifiers == "\u{1b}" {
            stopKeySearch()
            if window?.isKeyWindow == true { window?.makeFirstResponder(search) }
            return true
        }
        searchEvent = event
        updateKeyResults()
        return true
    }

    private func updateKeyResults() {
        searchMatches = []
        var message = NSLocalizedString("Press a key", comment: "")
        if let store, let event = searchEvent {
            let binding = ShortcutKeys.recordedBinding(event, unshifted: event.characters(byApplyingModifiers: []))
            search.stringValue = ShortcutKeys.display(key: binding.key, modifiers: binding.modifiers)
            searchMatches = store.matches(for: event)
            if binding.modifiers.isEmpty && binding.key == "\t" && completionUsesTab() {
                searchMatches = []
                message = NSLocalizedString("This key is reserved for command completion.", comment: "")
            } else if binding.key.isEmpty || !ShortcutKeys.isAllowed(key: binding.key, modifiers: binding.modifiers) {
                message = searchMatches.isEmpty
                    ? NSLocalizedString("This key cannot be used as a shortcut. Use Command or Control with a key, or F1–F20.", comment: "")
                    : NSLocalizedString("This key cannot be assigned to a new shortcut.", comment: "")
            } else {
                message = searchMatches.isEmpty ? NSLocalizedString("No command uses this key.", comment: "") : ""
            }
        }
        hint.stringValue = message
        var value = search.stringValue.isEmpty ? message : "\(search.stringValue). \(message)"
        if searchEvent != nil {
            value += ". " + String.localizedStringWithFormat(NSLocalizedString("Matches: %ld", comment: ""), searchMatches.count)
        }
        keySearchView.setAccessibilityValue(value)
        NSAccessibility.post(element: keySearchView, notification: .valueChanged)
        if window?.isKeyWindow == true {
            NSAccessibility.post(element: keySearchView, notification: .announcementRequested,
                                 userInfo: [.announcement: value, .priority: NSAccessibilityPriorityLevel.medium.rawValue])
        }
        table.reloadData()
        if !searchMatches.isEmpty {
            table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            table.scrollRowToVisible(0)
        }
        updateSelectionButtons()
    }

    // MARK: Table

    private var showsKeyResults: Bool { searchingByKey && searchEvent != nil }

    func numberOfRows(in tableView: NSTableView) -> Int {
        showsKeyResults ? searchMatches.count : visibleCommands.count
    }

    /// Why a key-search match does not run for the searched key; nil for the match that runs.
    private func inactiveReason(for match: ShortcutMatch) -> String? {
        guard !match.winner, let owner = searchMatches.first(where: \.winner) else { return nil }
        return String(format: NSLocalizedString("This shortcut is inactive because it conflicts with “%@” (%@).", comment: ""),
                      owner.path, ShortcutKeys.display(key: owner.item.keyEquivalent, modifiers: owner.item.keyEquivalentModifierMask))
    }

    // Ordinary rows draw their text 2pt inside the cell; the warning row lines up with them.
    private static let warningIndent: CGFloat = 2, warningGap: CGFloat = 2, warningBottom: CGFloat = 4, warningSpacing: CGFloat = 4

    /// The warning line used elsewhere in the settings: yellow triangle, small label-colored text.
    private func warningLine(_ text: String) -> NSStackView {
        let font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = font
        label.textColor = .labelColor
        label.identifier = NSUserInterfaceItemIdentifier("shortcut.inactive-reason")
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(249), for: .horizontal)
        let configuration = NSImage.SymbolConfiguration(pointSize: font.pointSize, weight: .regular)
            .applying(.preferringMulticolor())
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
        icon.setAccessibilityElement(false)
        let warning = NSStackView(views: [icon, label])
        warning.orientation = .horizontal
        warning.alignment = .firstBaseline
        warning.spacing = Self.warningSpacing
        warning.translatesAutoresizingMaskIntoConstraints = false
        warning.identifier = NSUserInterfaceItemIdentifier("shortcut.inactive-warning")
        return warning
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard showsKeyResults, searchMatches.indices.contains(row), let reason = inactiveReason(for: searchMatches[row]) else {
            return tableView.rowHeight
        }
        let warning = warningLine(reason)
        guard let note = warning.arrangedSubviews.last as? NSTextField, let cell = note.cell else { return tableView.rowHeight }
        let path = NSTextField(labelWithString: " ")
        // The command cell is as wide as its column; the note's frame adds its own alignment insets.
        let insets = note.alignmentRectInsets
        let width = (tableView.tableColumns.first?.width ?? 0) - Self.warningIndent
            - warning.arrangedSubviews[0].intrinsicContentSize.width - Self.warningSpacing + insets.left + insets.right
        let height = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: max(width, 1), height: .greatestFiniteMagnitude)).height
        return ceil(path.intrinsicContentSize.height + Self.warningGap + height + Self.warningBottom + tableView.intercellSpacing.height)
    }

    func tableViewColumnDidResize(_ notification: Notification) {
        guard showsKeyResults, table.numberOfRows > 0 else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            table.noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: 0..<table.numberOfRows))
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let isCommand = tableColumn?.identifier.rawValue == "command"
        let text: String
        var reason: String?
        if showsKeyResults {
            guard searchMatches.indices.contains(row) else { return nil }
            let match = searchMatches[row]
            reason = inactiveReason(for: match)
            text = !isCommand ? ShortcutKeys.display(key: match.item.keyEquivalent, modifiers: match.item.keyEquivalentModifierMask)
                : reason == nil ? "\(match.path) — \(NSLocalizedString("Assigned", comment: ""))" : match.path
        } else {
            guard visibleCommands.indices.contains(row) else { return nil }
            let command = visibleCommands[row]
            text = isCommand ? command.path : ShortcutKeys.display(key: command.item.keyEquivalent, modifiers: command.item.keyEquivalentModifierMask)
        }
        let label = NSTextField(labelWithString: text)
        label.lineBreakMode = .byTruncatingMiddle
        label.toolTip = text
        guard isCommand, let reason else { return label }
        let cell = NSView()
        cell.identifier = NSUserInterfaceItemIdentifier("shortcut.inactive-command")
        let warning = warningLine(reason)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(249), for: .horizontal)
        cell.addSubview(label)
        cell.addSubview(warning)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: cell.topAnchor),
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: Self.warningIndent),
            label.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
            warning.topAnchor.constraint(equalTo: label.bottomAnchor, constant: Self.warningGap),
            warning.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: Self.warningIndent),
            warning.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
        ])
        return cell
    }

    private var selectedCommand: ShortcutCommand? {
        let row = table.selectedRow
        if showsKeyResults { return searchMatches.indices.contains(row) ? searchMatches[row].command : nil }
        return visibleCommands.indices.contains(row) ? visibleCommands[row] : nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) { updateSelectionButtons() }

    private func updateSelectionButtons() {
        for button in selectionButtons { button.isEnabled = selectedCommand != nil }
    }

    // MARK: Changing

    private func showError(_ error: String?) {
        guard let error, let parent = capturePanel ?? window, parent.attachedSheet == nil else { return }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Shortcut Unavailable", comment: "")
        alert.informativeText = error
        alert.beginSheetModal(for: parent)
    }

    @objc private func removeShortcut(_ sender: Any?) {
        guard let command = selectedCommand, let store else { return }
        showError(store.setKey("", modifiers: [], for: command))
        reloadCommands()
    }

    @objc private func restoreShortcut(_ sender: Any?) {
        guard let command = selectedCommand, let store else { return }
        showError(store.restore(command))
        reloadCommands()
    }

    @objc private func restoreAll(_ sender: Any?) {
        guard let window, window.attachedSheet == nil, let store else { return }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Restore all keyboard shortcuts?", comment: "")
        alert.informativeText = NSLocalizedString("Custom menu shortcuts will be removed.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Restore All", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            store.restoreAll()
            self?.reloadCommands()
        }
    }

    @objc private func editShortcut(_ sender: Any?) {
        guard let parent = window, let command = selectedCommand, parent.attachedSheet == nil else { return }
        stopKeySearch()
        editingCommand = command
        capturedBinding = nil
        capturedBindings = []
        let panel = ShortcutCapturePanel(contentRect: NSRect(x: 0, y: 0, width: 640, height: 240), styleMask: [.titled], backing: .buffered, defer: false)
        capturePanel = panel
        panel.title = NSLocalizedString("Change Shortcut", comment: "")
        let recorder = ShortcutRecorder(frame: panel.contentView?.bounds ?? .zero)
        recorder.autoresizingMask = [.width, .height]
        panel.contentView = recorder
        panel.recorder = recorder
        let title = NSTextField(labelWithString: command.path)
        title.frame = NSRect(x: 20, y: 195, width: 600, height: 25)
        title.lineBreakMode = .byTruncatingMiddle
        title.toolTip = command.path
        captureDisplay.stringValue = NSLocalizedString("New shortcut", comment: "")
        captureDisplay.frame = NSRect(x: 20, y: 145, width: 600, height: 40)
        captureDisplay.font = .systemFont(ofSize: 18)
        captureDisplay.alignment = .center
        captureError.stringValue = ""
        captureError.frame = NSRect(x: 20, y: 65, width: 600, height: 70)
        captureError.textColor = .secondaryLabelColor
        applyButton = NSButton(title: NSLocalizedString("Apply", comment: ""), target: self, action: #selector(applyCapturedShortcut(_:)))
        applyButton.isEnabled = false
        applyButton.keyEquivalent = "\r"
        let cancel = NSButton(title: NSLocalizedString("Cancel", comment: ""), target: self, action: #selector(cancelCapture(_:)))
        cancel.keyEquivalent = "\u{1b}"
        recorder.nextKeyView = applyButton
        applyButton.nextKeyView = cancel
        cancel.nextKeyView = recorder
        applyButton.sizeToFit()
        cancel.sizeToFit()
        applyButton.frame = NSRect(x: 620 - applyButton.frame.width, y: 18, width: applyButton.frame.width, height: 32)
        cancel.frame = NSRect(x: applyButton.frame.minX - cancel.frame.width - 12, y: 18, width: cancel.frame.width, height: 32)
        for subview in [title, captureDisplay, captureError, applyButton!, cancel] { recorder.addSubview(subview) }
        recorder.record = { [weak self] event in self?.record(event) }
        recorder.accept = { [weak self] in self?.applyCapturedShortcut(nil) }
        recorder.cancel = { [weak self] in self?.cancelCapture(nil) }
        parent.beginSheet(panel) { [weak self] _ in
            panel.recorder?.record = nil
            panel.recorder?.accept = nil
            panel.recorder?.cancel = nil
            self?.capturePanel = nil
            self?.editingCommand = nil
            self?.reloadCommands()
        }
        panel.makeFirstResponder(recorder)
        panel.initialFirstResponder = recorder
    }

    private func record(_ event: NSEvent) {
        let key = ShortcutKeys.character(for: event)
        let flags = event.modifierFlags.intersection(ShortcutBinding.modifierMask)
        captureError.stringValue = ""
        applyButton.isEnabled = !key.isEmpty && ShortcutKeys.isAllowed(key: key, modifiers: flags)
        if applyButton.isEnabled {
            capturedBindings = ShortcutKeys.eventBindings(event, unshifted: event.characters(byApplyingModifiers: []))
            capturedBinding = capturedBindings.first
            captureDisplay.stringValue = capturedBinding.map { ShortcutKeys.display(key: $0.key, modifiers: $0.modifiers) } ?? ""
        } else {
            capturedBinding = nil
            capturedBindings = []
            captureDisplay.stringValue = NSLocalizedString("New shortcut", comment: "")
            captureError.stringValue = NSLocalizedString("This key cannot be used as a shortcut. Use Command or Control with a key, or F1–F20.", comment: "")
        }
        capturePanel?.recorder?.setAccessibilityValue(captureDisplay.stringValue)
    }

    @objc private func cancelCapture(_ sender: Any?) {
        guard let parent = window, let panel = capturePanel, panel.attachedSheet == nil else { return }
        parent.endSheet(panel, returnCode: .cancel)
    }

    private func conflictForCapturedShortcut() -> String? {
        guard let store, let binding = capturedBinding else { return nil }
        var conflicts: [String] = []
        for spelling in capturedBindings.isEmpty ? [binding] : capturedBindings {
            if let path = store.conflict(for: spelling, except: editingCommand?.item), !conflicts.contains(path) { conflicts.append(path) }
        }
        if conflicts.isEmpty { return nil }
        if conflicts.count == 1 { return String(format: NSLocalizedString("This shortcut is already used by “%@”.", comment: ""), conflicts[0]) }
        return String(format: NSLocalizedString("This shortcut is already used by:\n%@", comment: ""), conflicts.joined(separator: "\n"))
    }

    @objc private func applyCapturedShortcut(_ sender: Any?) {
        guard let store, let binding = capturedBinding, let command = editingCommand, applyButton.isEnabled else { return }
        if let conflict = conflictForCapturedShortcut() {
            captureError.stringValue = conflict
            return
        }
        if let error = store.setKey(binding.key, modifiers: binding.modifiers, for: command) {
            captureError.stringValue = error
            if let panel = capturePanel { panel.makeFirstResponder(panel.recorder) }
            reloadCommands()
            return
        }
        if let parent = window, let panel = capturePanel { parent.endSheet(panel, returnCode: .OK) }
    }
}
