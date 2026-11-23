import AppKit
import Carbon.HIToolbox

/// The view that has focus while searching by key; every key press is a query.
/// It lies over the search field, so it also handles the field's cancel button (TeXShop 6.00).
private final class KeySearchView: NSView {
    var handleEvent: ((NSEvent) -> Bool)?
    var clearKey: (() -> Void)?
    weak var searchField: NSSearchField?
    private var pressingCancelButton = false

    override var acceptsFirstResponder: Bool { true }
    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .textField }
    override func accessibilityLabel() -> String? { NSLocalizedString("Search by Key", comment: "") }
    override func keyDown(with event: NSEvent) { _ = performKeyEquivalent(with: event) }
    override func performKeyEquivalent(with event: NSEvent) -> Bool { handleEvent?(event) ?? false }

    /// The search field shows its cancel button only while it shows a key.
    private var showsCancelButton: Bool { clearKey != nil && !(searchField?.stringValue.isEmpty ?? true) }

    private func cancelButtonContains(_ event: NSEvent) -> Bool {
        guard let field = searchField, showsCancelButton, let cell = field.cell as? NSSearchFieldCell else { return false }
        let button = field.convert(cell.cancelButtonRect(forBounds: field.bounds), to: self)
        return isMousePoint(convert(event.locationInWindow, from: nil), in: button)
    }

    override func mouseDown(with event: NSEvent) {
        pressingCancelButton = cancelButtonContains(event)
        if !pressingCancelButton { super.mouseDown(with: event) }
    }

    override func mouseUp(with event: NSEvent) {
        let clear = pressingCancelButton && cancelButtonContains(event)
        pressingCancelButton = false
        if clear { clearKey?() } else { super.mouseUp(with: event) }
    }

    override func isAccessibilitySelectorAllowed(_ selector: Selector) -> Bool {
        if selector == #selector(accessibilityPerformCancel) { return showsCancelButton }
        return super.isAccessibilitySelectorAllowed(selector)
    }

    override func accessibilityPerformCancel() -> Bool {
        guard showsCancelButton else { return false }
        clearKey?()
        return true
    }
}

/// The menu shortcut list. As in Xcode's key bindings, a click on the shortcut of the selected row,
/// a double click, or Return records a new shortcut in the row.
private final class ShortcutTableView: NSTableView {
    var beginRecording: ((Int) -> Void)?
    private(set) var rowSelectedAtMouseDown = -1

    override func mouseDown(with event: NSEvent) {
        rowSelectedAtMouseDown = selectedRow
        super.mouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        let key = event.charactersIgnoringModifiers
        if event.modifierFlags.intersection(ShortcutBinding.modifierMask).isEmpty, key == "\r" || key == "\u{3}",
           selectedRow >= 0, let beginRecording {
            beginRecording(selectedRow)
            return
        }
        super.keyDown(with: event)
    }
}

/// A shortcut in the list; assistive technologies press it to record a new one.
private final class ShortcutKeyLabel: NSTextField {
    var press: ((NSTextField) -> Void)?

    override func isAccessibilitySelectorAllowed(_ selector: Selector) -> Bool {
        if selector == #selector(accessibilityPerformPress) { return press != nil }
        return super.isAccessibilitySelectorAllowed(selector)
    }

    override func accessibilityPerformPress() -> Bool {
        guard let press else { return false }
        press(self)
        return true
    }
}

/// The shortcut cell while it records: a field with the key, selected, and a button that removes
/// the shortcut. The pane receives the keys through the settings window.
private final class ShortcutKeyRecorder: NSView {
    // The text 4 points from the leading edge and 2 before the remove button, which is 14 points wide, 3 from the trailing edge.
    static let textInset: CGFloat = 4, textGap: CGFloat = 2, removeSize: CGFloat = 14, removeInset: CGFloat = 3

    let label = NSTextField(labelWithString: "")
    let removeButton: NSButton
    var resigned: (() -> Void)?
    var shortcut = "" {
        didSet {
            let centered = NSMutableParagraphStyle()
            centered.alignment = .center
            centered.lineBreakMode = .byTruncatingMiddle
            let text = NSMutableAttributedString(string: shortcut, attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize), .foregroundColor: NSColor.labelColor, .paragraphStyle: centered,
            ])
            // The key is selected, as text in a field that waits for a replacement.
            if !shortcut.isEmpty { text.addAttribute(.backgroundColor, value: NSColor.selectedTextBackgroundColor, range: NSRange(location: 0, length: text.length)) }
            label.attributedStringValue = text
            NSAccessibility.post(element: self, notification: .valueChanged)
        }
    }

    override init(frame: NSRect) {
        let remove = NSLocalizedString("Remove Shortcut", comment: "")
        removeButton = NSButton(image: NSImage(systemSymbolName: "minus.circle.fill", accessibilityDescription: remove) ?? NSImage(),
                                target: nil, action: nil)
        super.init(frame: frame)
        label.alignment = .center
        label.lineBreakMode = .byTruncatingMiddle
        label.setAccessibilityElement(false)
        label.identifier = NSUserInterfaceItemIdentifier("shortcut.recorder-text")
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(249), for: .horizontal)
        removeButton.isBordered = false
        removeButton.imageScaling = .scaleProportionallyDown
        removeButton.contentTintColor = .secondaryLabelColor
        removeButton.refusesFirstResponder = true
        removeButton.toolTip = remove
        removeButton.identifier = NSUserInterfaceItemIdentifier("shortcut.recorder-remove")
        for view in [label, removeButton] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.textInset),
            label.trailingAnchor.constraint(equalTo: removeButton.leadingAnchor, constant: -Self.textGap),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            removeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.removeInset),
            removeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: Self.removeSize),
            removeButton.heightAnchor.constraint(equalToConstant: Self.removeSize),
        ])
        focusRingType = .exterior
        identifier = NSUserInterfaceItemIdentifier("shortcut.recorder")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.textBackgroundColor.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4).fill()
    }

    override var focusRingMaskBounds: NSRect { bounds }
    override func drawFocusRingMask() { NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4).fill() }
    override var acceptsFirstResponder: Bool { true }

    override func resignFirstResponder() -> Bool {
        guard super.resignFirstResponder() else { return false }
        resigned?()
        return true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hit = super.hitTest(point) else { return nil }
        return hit === removeButton ? hit : self
    }

    override func mouseDown(with event: NSEvent) {
        if window?.firstResponder !== self { window?.makeFirstResponder(self) }
    }

    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .textField }
    override func accessibilityLabel() -> String? { NSLocalizedString("Change Shortcut", comment: "") }
    override func accessibilityValue() -> Any? { shortcut.isEmpty ? NSLocalizedString("Press a key", comment: "") : shortcut }
    override func accessibilityHelp() -> String? { NSLocalizedString("Press a key", comment: "") }
}

/// What a recording row shows in its shortcut cell: the field, and at the cell's trailing edge the room
/// for the warning triangle, which shows while a key is refused.
private final class ShortcutRecordingCell: NSView {
    // The field 18 points high in the middle of the cell, 20 points of the cell after it for the triangle.
    static let warningRoom: CGFloat = 20, warningInset: CGFloat = 2, fieldHeight: CGFloat = 18

    let recorder = ShortcutKeyRecorder(frame: NSRect(x: 0, y: 0, width: 120, height: 20))
    let warning = ShortcutPaneController.warningSymbol()

    override init(frame: NSRect) {
        super.init(frame: frame)
        warning.identifier = NSUserInterfaceItemIdentifier("shortcut.recording-warning")
        identifier = NSUserInterfaceItemIdentifier("shortcut.recording")
        for view in [recorder, warning] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            recorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            recorder.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.warningRoom),
            recorder.centerYAnchor.constraint(equalTo: centerYAnchor),
            recorder.heightAnchor.constraint(equalToConstant: Self.fieldHeight),
            warning.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.warningInset),
            warning.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

/// The menu shortcuts group of the Keyboard category (TeXShop's TSShortcutPaneController without macros).
final class ShortcutPaneController: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    var store: ShortcutStore? {
        didSet {
            if let observer = shownKeysObserver { NotificationCenter.default.removeObserver(observer) }
            // The keys AppKit shows change a little after an assignment or a change of keyboard layout.
            shownKeysObserver = store.map { store in
                NotificationCenter.default.addObserver(forName: ShortcutStore.shownKeysChangedNotification, object: store, queue: .main) { [weak self] _ in
                    self?.shownKeysChanged()
                }
            }
            reloadCommands()
        }
    }
    private var shownKeysObserver: NSObjectProtocol?

    /// The keys AppKit shows changed (another keyboard layout): the list, the recording field and the default under the
    /// list show them, and recording goes on.
    private func shownKeysChanged() {
        guard let editing = editingCommand else { reloadCommands(); return }
        let column = table.column(withIdentifier: NSUserInterfaceItemIdentifier("shortcut"))
        let rows = IndexSet((0..<table.numberOfRows).filter { command(at: $0) !== editing })
        if column >= 0, !rows.isEmpty { table.reloadData(forRowIndexes: rows, columnIndexes: IndexSet(integer: column)) }
        updateRecorder()
        updateStatus()
    }

    /// A key as the list shows it: for a command, its key as AppKit shows it on the current keyboard layout.
    private func shownKey(_ item: NSMenuItem, command: ShortcutCommand?) -> String {
        let binding = command.flatMap { store?.shownBinding(for: $0) } ?? ShortcutKeys.shownBinding(item)
        return ShortcutKeys.display(key: binding.key, modifiers: binding.modifiers)
    }
    /// Tab is reserved when it completes commands.
    var completionUsesTab: () -> Bool = { false }
    weak var window: NSWindow?

    let view = NSView()
    private(set) var searchingByKey = false
    private let search = NSSearchField()
    private let searchMode: NSSegmentedControl
    private let keySearchView = KeySearchView()
    private let hint = NSTextField(wrappingLabelWithString: "")
    private let table = ShortcutTableView()
    private var selectionButtons: [NSButton] = []
    private var textQuery = ""
    private var searchEvent: NSEvent?
    private var searchMatches: [ShortcutMatch] = []
    private var visibleCommands: [ShortcutCommand] = []
    // Recording in the list.
    private let recordingCell = ShortcutRecordingCell()
    private var recorder: ShortcutKeyRecorder { recordingCell.recorder }
    private(set) var editingCommand: ShortcutCommand?
    private var recordingError: String?
    private var endingRecording = false
    private var capturedBindings: [ShortcutBinding] = []
    private var capturedBinding: ShortcutBinding?
    // Under the list, as in Xcode: the selected command's default shortcut, or why a recorded key was refused.
    private var status: NSStackView!
    private var statusText: NSTextField!

    override init() {
        searchMode = NSSegmentedControl(labels: [NSLocalizedString("Search by Function", comment: ""), NSLocalizedString("Search by Key", comment: "")],
                                        trackingMode: .selectOne, target: nil, action: nil)
        super.init()
        buildView()
    }

    private func buildView() {
        search.placeholderString = NSLocalizedString("Search commands", comment: "")
        search.delegate = self
        search.identifier = NSUserInterfaceItemIdentifier("shortcut.function")
        searchMode.target = self
        searchMode.action = #selector(changeSearchMode(_:))
        searchMode.selectedSegment = 0
        searchMode.identifier = NSUserInterfaceItemIdentifier("shortcut.mode")
        searchMode.setContentHuggingPriority(.required, for: .horizontal)
        searchMode.setContentCompressionResistancePriority(.required, for: .horizontal)
        keySearchView.isHidden = true
        keySearchView.identifier = NSUserInterfaceItemIdentifier("shortcut.key")
        keySearchView.handleEvent = { [weak self] event in self?.handleKeySearchEvent(event) ?? false }
        keySearchView.searchField = search
        keySearchView.clearKey = { [weak self] in self?.clearKeySearch() }
        hint.textColor = .secondaryLabelColor
        hint.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        hint.identifier = NSUserInterfaceItemIdentifier("shortcut.hint")
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.automaticallyAdjustsContentInsets = false
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 22
        table.style = .inset
        // Striped, as the lists of TeXShop's Settings › Keyboard.
        table.usesAlternatingRowBackgroundColors = true
        table.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        table.target = self
        table.doubleAction = #selector(editShortcut(_:))
        table.action = #selector(tableClicked(_:))
        table.beginRecording = { [weak self] row in self?.beginRecording(at: row) }
        let command = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("command"))
        command.title = NSLocalizedString("Command", comment: "")
        command.width = 300
        command.minWidth = 200
        let shortcut = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("shortcut"))
        shortcut.title = NSLocalizedString("Shortcut", comment: "")
        shortcut.width = 150
        shortcut.minWidth = 130
        table.addTableColumn(command)
        table.addTableColumn(shortcut)
        scroll.documentView = table
        let restore = smallButton("Restore Default", #selector(restoreShortcut(_:)))
        restore.identifier = NSUserInterfaceItemIdentifier("shortcut.restore")
        let all = smallButton("Restore All…", #selector(restoreAll(_:)))
        all.identifier = NSUserInterfaceItemIdentifier("shortcut.restore-all")
        selectionButtons = [restore]
        let spacer = NSView()
        spacer.setContentHuggingPriority(NSLayoutConstraint.Priority(249), for: .horizontal)
        let buttons = NSStackView(views: [restore, spacer, all])
        buttons.orientation = .horizontal
        buttons.spacing = 8
        recorder.removeButton.target = self
        recorder.removeButton.action = #selector(removeShortcut(_:))
        // A click elsewhere ends the recording and keeps the shortcut; the focus goes where it was going.
        recorder.resigned = { [weak self] in self?.finishRecording(focusingList: false) }
        status = Self.warningLine(" ")
        status.identifier = NSUserInterfaceItemIdentifier("shortcut.status")
        statusText = status.arrangedSubviews.last as? NSTextField
        statusText.identifier = NSUserInterfaceItemIdentifier("shortcut.status-text")
        statusText.alignment = .center
        // The line takes the width of its text, up to the width of the pane, and wraps beyond it.
        statusText.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        status.arrangedSubviews[0].isHidden = true
        for subview in [search, searchMode, keySearchView, hint, scroll, status, buttons] as [NSView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.identifier = NSUserInterfaceItemIdentifier("shortcut.commands")
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
            status.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 4),
            status.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            status.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 12),
            status.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -12),
            buttons.topAnchor.constraint(equalTo: status.bottomAnchor, constant: 6),
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

    private func reloadTable() {
        if editingCommand != nil { endRecording() }
        table.reloadData()
        updateStatus()
    }

    private func reloadFunctionCommands() {
        if let unavailable = store?.unavailableCommands, !unavailable.isEmpty {
            hint.stringValue = "\(NSLocalizedString("Shortcut Unavailable", comment: "")): \(unavailable.joined(separator: ", "))"
        } else {
            hint.stringValue = ""
        }
        let previous = searchingByKey ? nil : selectedCommand
        let tokens = SettingsWindowController.tokens(search.stringValue)
        visibleCommands = (store?.commands ?? []).filter { command in
            guard !command.item.isHidden || command.item.allowsKeyEquivalentWhenHidden else { return false }
            let text = SettingsWindowController.normalized(command.path)
            return tokens.allSatisfy { text.contains($0) }
        }
        reloadTable()
        // The selected command stays selected when the list is filled again.
        if let previous, let row = visibleCommands.firstIndex(where: { $0.item === previous.item }), table.selectedRow != row {
            table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
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

    /// Key search lasts while the focus stays in the menu shortcut controls; the button there acts on the selected match.
    /// Clicking the settings search field or another control ends it, so that typing there edits again (TeXShop 6.00).
    func windowFirstResponderChanged(_ responder: NSResponder?) {
        guard searchingByKey else { return }
        var view = responder as? NSView
        if let text = view as? NSTextView, text.isFieldEditor, let owner = text.delegate as? NSView { view = owner }
        guard let view, !view.isDescendant(of: self.view) else { return }
        stopKeySearch()
    }

    /// Forgets the searched key and waits for the next one, as on entering key search.
    private func clearKeySearch() {
        guard searchingByKey else { return }
        searchEvent = nil
        search.stringValue = ""
        table.deselectAll(nil)
        reloadFunctionCommands()
        updateKeyResults()
        window?.makeFirstResponder(keySearchView)
    }

    /// The settings window passes every key press of the Keyboard category here first:
    /// to the shortcut being recorded, or to the key search.
    func handleKeySearchEvent(_ event: NSEvent) -> Bool {
        if editingCommand != nil, window?.firstResponder === recorder { return handleRecordingEvent(event) }
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
        reloadTable()
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
                      owner.path, shownKey(owner.item, command: owner.command))
    }

    // Ordinary rows draw their text 2pt inside the cell; the warning row lines up with them.
    private static let warningIndent: CGFloat = 2, warningGap: CGFloat = 2, warningBottom: CGFloat = 4, warningSpacing: CGFloat = 4

    /// The yellow triangle of the warnings in the settings, at the size of small text.
    static func warningSymbol() -> NSImageView {
        let configuration = NSImage.SymbolConfiguration(pointSize: NSFont.smallSystemFontSize, weight: .regular)
            .applying(.preferringMulticolor())
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
        icon.setAccessibilityElement(false)
        return icon
    }

    /// The warning line used elsewhere in the settings: yellow triangle, small label-colored text.
    static func warningLine(_ text: String) -> NSStackView {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .labelColor
        label.identifier = NSUserInterfaceItemIdentifier("shortcut.inactive-reason")
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(249), for: .horizontal)
        let warning = NSStackView(views: [warningSymbol(), label])
        warning.orientation = .horizontal
        warning.alignment = .firstBaseline
        warning.spacing = warningSpacing
        warning.translatesAutoresizingMaskIntoConstraints = false
        warning.identifier = NSUserInterfaceItemIdentifier("shortcut.inactive-warning")
        return warning
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard showsKeyResults, searchMatches.indices.contains(row), let reason = inactiveReason(for: searchMatches[row]) else {
            return tableView.rowHeight
        }
        let warning = Self.warningLine(reason)
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
        let command: ShortcutCommand?
        if showsKeyResults {
            guard searchMatches.indices.contains(row) else { return nil }
            let match = searchMatches[row]
            command = match.command
            reason = inactiveReason(for: match)
            text = !isCommand ? shownKey(match.item, command: match.command)
                : reason == nil ? "\(match.path) — \(NSLocalizedString("Assigned", comment: ""))" : match.path
        } else {
            guard visibleCommands.indices.contains(row) else { return nil }
            command = visibleCommands[row]
            text = isCommand ? command!.path : shownKey(command!.item, command: command)
        }
        if !isCommand, let command, command === editingCommand { return recordingCell }
        let label = !isCommand && command != nil ? shortcutLabel(text) : NSTextField(labelWithString: text)
        label.lineBreakMode = .byTruncatingMiddle
        label.toolTip = isCommand ? text : command?.path ?? text
        guard isCommand, let reason else { return label }
        let cell = NSView()
        cell.identifier = NSUserInterfaceItemIdentifier("shortcut.inactive-command")
        let warning = Self.warningLine(reason)
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

    private func shortcutLabel(_ text: String) -> NSTextField {
        let label = ShortcutKeyLabel(labelWithString: text)
        label.press = { [weak self] pressed in
            guard let self else { return }
            self.beginRecording(at: self.table.row(for: pressed))
        }
        return label
    }

    private func command(at row: Int) -> ShortcutCommand? {
        if showsKeyResults { return searchMatches.indices.contains(row) ? searchMatches[row].command : nil }
        return visibleCommands.indices.contains(row) ? visibleCommands[row] : nil
    }

    private var selectedCommand: ShortcutCommand? { command(at: table.selectedRow) }

    func tableViewSelectionDidChange(_ notification: Notification) { updateSelectionButtons() }

    private func updateSelectionButtons() {
        for button in selectionButtons { button.isEnabled = selectedCommand != nil }
        updateStatus()
    }

    // MARK: Changing

    private func showError(_ error: String?) {
        guard let error, let window, window.attachedSheet == nil else { return }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Shortcut Unavailable", comment: "")
        alert.informativeText = error
        alert.beginSheetModal(for: window)
    }

    @objc private func removeShortcut(_ sender: Any?) {
        guard let command = editingCommand ?? selectedCommand, let store else { return }
        endRecording()
        showError(store.setKey("", modifiers: [], for: command))
        reloadCommands()
    }

    @objc private func restoreShortcut(_ sender: Any?) {
        endRecording()
        guard let command = selectedCommand, let store else { return }
        // Right after a change of keyboard layout, the keys it shows are worked out first (TeXShop 6.00).
        store.whenKeysOfCurrentLayoutAreKnown { [weak self] in
            guard let self, store.commands.contains(where: { $0 === command }) else { return }
            self.showError(store.restore(command))
            self.reloadCommands()
        }
    }

    @objc private func restoreAll(_ sender: Any?) {
        endRecording()
        guard let window, window.attachedSheet == nil, let store else { return }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Restore all keyboard shortcuts?", comment: "")
        alert.informativeText = NSLocalizedString("Custom menu shortcuts will be removed.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Restore All", comment: "")).hasDestructiveAction = true
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            store.restoreAll()
            self?.reloadCommands()
        }
    }

    // MARK: Recording in the list

    private func row(for command: ShortcutCommand?) -> Int {
        guard let command else { return -1 }
        return (0..<table.numberOfRows).first { self.command(at: $0) === command } ?? -1
    }

    private func reloadShortcutCell(at row: Int) {
        let column = table.column(withIdentifier: NSUserInterfaceItemIdentifier("shortcut"))
        guard row >= 0, row < table.numberOfRows, column >= 0 else { return }
        table.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
    }

    /// The double action, and Return in the list.
    @objc private func editShortcut(_ sender: Any?) {
        beginRecording(at: (sender as AnyObject?) === table ? table.clickedRow : table.selectedRow)
    }

    /// A single click on the shortcut of the row that was already selected.
    @objc private func tableClicked(_ sender: Any?) {
        let row = table.clickedRow
        guard row >= 0, row == table.rowSelectedAtMouseDown,
              table.clickedColumn == table.column(withIdentifier: NSUserInterfaceItemIdentifier("shortcut")) else { return }
        beginRecording(at: row)
    }

    func beginRecording(at row: Int) {
        guard let command = command(at: row), let window, window.attachedSheet == nil else { return }
        if editingCommand !== command {
            endRecording()
            // A row whose recording ended by a click elsewhere may still hold the field.
            let stale = table.row(for: recordingCell)
            if stale >= 0 && stale != row { reloadShortcutCell(at: stale) }
            if table.selectedRow != row { table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false) }
            editingCommand = command
            capturedBinding = nil
            capturedBindings = []
            recordingError = nil
            updateRecorder()
            reloadShortcutCell(at: row)
            table.scrollRowToVisible(row)
        }
        // The field is in the row before it takes the keys.
        let column = table.column(withIdentifier: NSUserInterfaceItemIdentifier("shortcut"))
        if recorder.window !== window && column >= 0 { _ = table.view(atColumn: column, row: row, makeIfNecessary: true) }
        if recorder.window !== window { endRecording(); return }
        window.makeFirstResponder(recorder)
        updateStatus()
    }

    /// Ends recording and keeps the shortcut as it is now; the list takes the focus the recorder had.
    func endRecording() { finishRecording(focusingList: true) }

    private func finishRecording(focusingList: Bool) {
        guard let command = editingCommand, !endingRecording else { return }
        endingRecording = true
        defer { endingRecording = false }
        editingCommand = nil
        capturedBinding = nil
        capturedBindings = []
        recordingError = nil
        if focusingList {
            if let window, window.firstResponder === recorder { window.makeFirstResponder(table) }
            reloadShortcutCell(at: row(for: command))
            recordingCell.removeFromSuperview()
        } else {
            // The recorder is resigning: the row shows its shortcut again once the focus has moved.
            DispatchQueue.main.async { [weak self] in
                guard let self, self.editingCommand !== command else { return }
                self.reloadShortcutCell(at: self.row(for: command))
                if self.editingCommand == nil { self.recordingCell.removeFromSuperview() }
            }
        }
        updateStatus()
    }

    var isRecording: Bool { editingCommand != nil }

    /// Escape and Return end recording, Tab moves on, Delete removes the shortcut; any other key may become it.
    private func handleRecordingEvent(_ event: NSEvent) -> Bool {
        guard event.type == .keyDown else { return true }
        let key = event.charactersIgnoringModifiers ?? ""
        let c = key.utf16.count == 1 ? Int(key.utf16.first!) : 0
        let flags = event.modifierFlags.intersection(ShortcutBinding.modifierMask)
        if flags.isEmpty && (c == 27 || c == 13 || c == 3) { endRecording(); return true }
        if (c == 9 || c == 25) && flags.subtracting(.shift).isEmpty {
            let window = self.window
            endRecording()
            if c == 25 || flags.contains(.shift) { window?.selectPreviousKeyView(nil) } else { window?.selectNextKeyView(nil) }
            return true
        }
        if flags.isEmpty && (c == 127 || c == 8 || c == NSDeleteFunctionKey) { removeShortcut(nil); return true }
        record(event)
        return true
    }

    private func updateRecorder() {
        guard let command = editingCommand else { return }
        // An empty field, as in Xcode, for a command without a shortcut (the list shows a dash).
        let current = command.item.keyEquivalent.isEmpty ? "" : shownKey(command.item, command: command)
        recorder.shortcut = capturedBinding.map { ShortcutKeys.display(key: $0.key, modifiers: $0.modifiers) } ?? current
        recorder.removeButton.isHidden = command.item.keyEquivalent.isEmpty
        recordingCell.warning.isHidden = recordingError == nil
    }

    /// The line under the list: why a recorded key was refused, otherwise the selected command's default.
    private func updateStatus() {
        guard let statusText else { return }
        let error = editingCommand != nil ? recordingError : nil
        var text = error
        if text == nil, let command = editingCommand ?? selectedCommand {
            // The default as the current keyboard layout shows it (on a French layout, Command-& for Command-1).
            let shown = store?.shownDefault(for: command) ?? ShortcutBinding(command.defaultKey, command.defaultModifiers)
            text = command.defaultKey.isEmpty ? NSLocalizedString("Default shortcut: None", comment: "")
                : String(format: NSLocalizedString("Default shortcut: %@", comment: ""), ShortcutKeys.display(key: shown.key, modifiers: shown.modifiers))
        }
        // A blank line keeps the list and the buttons where they are.
        statusText.stringValue = text?.isEmpty == false ? text! : " "
        let room = view.bounds.width - 24 - (error == nil ? 0 : status.arrangedSubviews[0].fittingSize.width + status.spacing)
        statusText.preferredMaxLayoutWidth = max(room, 120)
        status.arrangedSubviews[0].isHidden = error == nil
    }

    private func showRecordingError(_ error: String) {
        recordingError = error
        updateRecorder()
        updateStatus()
        if window?.isKeyWindow == true {
            NSAccessibility.post(element: recorder, notification: .announcementRequested,
                                 userInfo: [.announcement: error, .priority: NSAccessibilityPriorityLevel.high.rawValue])
        }
    }

    /// A key pressed while recording becomes the shortcut at once when it can; otherwise the reason shows under the list.
    private func record(_ event: NSEvent) {
        let key = ShortcutKeys.character(for: event)
        let flags = event.modifierFlags.intersection(ShortcutBinding.modifierMask)
        guard !key.isEmpty, ShortcutKeys.isAllowed(key: key, modifiers: flags) else {
            capturedBinding = nil
            capturedBindings = []
            showRecordingError(NSLocalizedString("This key cannot be used as a shortcut. Use Command or Control with a key, or F1–F20.", comment: ""))
            return
        }
        capturedBindings = ShortcutKeys.eventBindings(event, unshifted: event.characters(byApplyingModifiers: []))
        capturedBinding = capturedBindings.first
        recordingError = nil
        updateRecorder()
        applyCapturedShortcut()
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

    /// A key in use by another command is refused and recording goes on.
    private func applyCapturedShortcut() {
        guard let store, let binding = capturedBinding, let command = editingCommand else { return }
        // Right after a change of keyboard layout, the keys it shows are worked out first (TeXShop 6.00): the key is then
        // judged as the menu shows the other keys.
        guard store.knowsKeysOfCurrentLayout else {
            store.whenKeysOfCurrentLayoutAreKnown { [weak self] in
                guard let self, self.editingCommand === command, self.capturedBinding == binding else { return }
                self.assignCapturedShortcut()
            }
            return
        }
        assignCapturedShortcut()
    }

    private func assignCapturedShortcut() {
        guard let store, let binding = capturedBinding, let command = editingCommand else { return }
        if let conflict = conflictForCapturedShortcut() {
            showRecordingError(conflict)
            return
        }
        if let error = store.setKey(binding.key, modifiers: binding.modifiers, for: command) {
            showRecordingError(error)
            return
        }
        endRecording()
        reloadCommands()
    }
}
