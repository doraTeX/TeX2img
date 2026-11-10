import AppKit

// Settings window parts after TeXShop's settings panel (TSPrefPaneLayout):
// a header card per category, titled groups of rounded cards, and rows with
// the name on the left and the control on the right.

/// The rounded icon tile of a category.
final class SettingsIconView: NSView {
    private let symbolName: String
    private let tileColor: NSColor

    init(symbolName: String, color: NSColor, size: CGFloat) {
        self.symbolName = symbolName
        self.tileColor = color
        super.init(frame: NSRect(x: 0, y: 0, width: size, height: size))
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([widthAnchor.constraint(equalToConstant: size), heightAnchor.constraint(equalToConstant: size)])
        setAccessibilityElement(false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let side = bounds.width
        guard side > 0 else { return }
        let tile = NSBezierPath(roundedRect: bounds, xRadius: side * 0.24, yRadius: side * 0.24)
        let top = tileColor.blended(withFraction: 0.18, of: .white) ?? tileColor
        if let gradient = NSGradient(starting: top, ending: tileColor) {
            gradient.draw(in: tile, angle: 90)
        } else {
            tileColor.setFill()
            tile.fill()
        }
        guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else { return }
        let configuration = NSImage.SymbolConfiguration(pointSize: side * 0.5, weight: .medium)
            .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
        guard let image = symbol.withSymbolConfiguration(configuration), image.size.width > 0, image.size.height > 0 else { return }
        let maxSide = side * 0.66
        let scale = min(1, min(maxSide / image.size.width, maxSide / image.size.height))
        let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        image.draw(in: NSRect(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2, width: size.width, height: size.height),
                   from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }
}

/// A label that dims with its row.
final class SettingsLabel: NSTextField {
    var enabledTextColor: NSColor = .labelColor {
        didSet { textColor = isEnabled ? enabledTextColor : .disabledControlTextColor }
    }

    override var isEnabled: Bool {
        didSet { textColor = isEnabled ? enabledTextColor : .disabledControlTextColor }
    }

    static func make(_ text: String, small: Bool = false) -> SettingsLabel {
        let label = SettingsLabel(wrappingLabelWithString: text)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: small ? NSFont.smallSystemFontSize : NSFont.systemFontSize)
        label.enabledTextColor = small ? .secondaryLabelColor : .labelColor
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(249), for: .horizontal)
        label.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
        return label
    }
}

/// The light fill of a card, with separators between its rows.
final class SettingsCardView: NSView {
    static var cornerRadius: CGFloat {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 ? 12 : 10
    }

    static let fillColor = NSColor(name: "SettingsCardFill") { appearance in
        let dark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        return NSColor(white: dark ? 1 : 0, alpha: dark ? 0.055 : 0.04)
    }

    weak var stack: NSStackView?

    override init(frame: NSRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerCurve = .continuous
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var wantsUpdateLayer: Bool { false }

    override func viewWillDraw() {
        super.viewWillDraw()
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = Self.fillColor.cgColor
        }
        layer?.cornerRadius = Self.cornerRadius
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let rows = stack?.arrangedSubviews.filter({ !$0.isHidden }), rows.count > 1 else { return }
        NSColor.separatorColor.setStroke()
        for row in rows.dropFirst() {
            let rect = row.convert(row.bounds, to: self)
            let y = isFlipped ? rect.minY : rect.maxY
            guard y > 1, y < bounds.height - 1 else { continue }
            let line = NSBezierPath()
            line.lineWidth = 0.5
            line.move(to: NSPoint(x: 12, y: y))
            line.line(to: NSPoint(x: bounds.width - 12, y: y))
            line.stroke()
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let view = super.hitTest(point)
        return view === self ? nil : view
    }
}

/// One setting: the name (and an optional note) on the left, the control on the right.
final class SettingsRowView: NSView {
    let titleLabel: SettingsLabel?
    let noteLabel: SettingsLabel?
    let accessory: NSView?
    var searchTitle: String
    var searchNote: String

    var isEnabled = true {
        didSet {
            titleLabel?.isEnabled = isEnabled
            noteLabel?.isEnabled = isEnabled
            if let accessory { SettingsUI.setEnabled(isEnabled, in: accessory) }
        }
    }

    init(title: String?, note: String?, accessory: NSView?, indent: Int, wideAccessory: Bool) {
        titleLabel = title.map { SettingsLabel.make($0) }
        noteLabel = (note?.isEmpty == false) ? SettingsLabel.make(note!, small: true) : nil
        self.accessory = accessory
        searchTitle = title ?? ""
        searchNote = note ?? ""
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        identifier = NSUserInterfaceItemIdentifier("row")
        let leading = 12 + 24 * CGFloat(indent)
        var constraints = [heightAnchor.constraint(greaterThanOrEqualToConstant: 38)]
        let labels = NSStackView(views: [titleLabel, noteLabel].compactMap { $0 })
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 2
        labels.translatesAutoresizingMaskIntoConstraints = false
        labels.setHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
        labels.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(249), for: .horizontal)
        if !labels.arrangedSubviews.isEmpty {
            addSubview(labels)
            constraints += [
                labels.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leading),
                labels.centerYAnchor.constraint(equalTo: centerYAnchor),
                labels.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 9),
                labels.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -9),
            ]
            // Labels take the width left by the control and wrap in it.
            for label in labels.arrangedSubviews {
                constraints.append(label.widthAnchor.constraint(equalTo: labels.widthAnchor))
            }
        }
        if let accessory {
            accessory.translatesAutoresizingMaskIntoConstraints = false
            addSubview(accessory)
            constraints += [
                accessory.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                accessory.centerYAnchor.constraint(equalTo: centerYAnchor),
                accessory.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 6),
                accessory.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6),
            ]
            if labels.arrangedSubviews.isEmpty {
                constraints.append(accessory.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: leading))
            } else {
                constraints.append(accessory.leadingAnchor.constraint(equalTo: labels.trailingAnchor, constant: 16))
                if wideAccessory {
                    // Paths and commands: a fixed name column, then the field to the trailing edge.
                    constraints.append(labels.widthAnchor.constraint(equalToConstant: 170))
                }
            }
            accessory.setContentCompressionResistancePriority(wideAccessory ? NSLayoutConstraint.Priority(249) : NSLayoutConstraint.Priority(751), for: .horizontal)
            accessory.setContentHuggingPriority(wideAccessory ? NSLayoutConstraint.Priority(1) : NSLayoutConstraint.Priority(752), for: .horizontal)
        } else if !labels.arrangedSubviews.isEmpty {
            constraints.append(labels.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12))
        }
        if let title, let accessory { SettingsUI.labelControls(in: accessory, title: title) }
        let fit = heightAnchor.constraint(equalToConstant: 38)
        fit.priority = NSLayoutConstraint.Priority(249)
        constraints.append(fit)
        NSLayoutConstraint.activate(constraints)
        setAccessibilityElement(false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

/// A rounded accent frame over the row found by the settings search.
final class SettingsSearchHighlight: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func isAccessibilityElement() -> Bool { false }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlAccentColor.setStroke()
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 5, yRadius: 5)
        path.lineWidth = 2
        path.stroke()
    }
}

/// A flipped document view so that panes start at the top of the scroll view.
final class SettingsDocumentView: NSView {
    override var isFlipped: Bool { true }
}

enum SettingsUI {
    static func setEnabled(_ enabled: Bool, in view: NSView) {
        if let label = view as? NSTextField, !label.isEditable, !(label is SettingsLabel) {
            label.textColor = enabled ? .secondaryLabelColor : .disabledControlTextColor
        } else if let control = view as? NSControl {
            control.isEnabled = enabled
        }
        view.subviews.forEach { setEnabled(enabled, in: $0) }
    }

    /// Controls of a row are announced by the row's name.
    static func labelControls(in view: NSView, title: String) {
        if let control = view as? NSControl, !(control is NSTextField && !(control as! NSTextField).isEditable),
           (control.accessibilityLabel() ?? "").isEmpty {
            control.setAccessibilityLabel(title)
        }
        view.subviews.forEach { labelControls(in: $0, title: title) }
    }

    // MARK: Controls

    static func makeSwitch(target: AnyObject?, action: Selector?) -> NSSwitch {
        let control = NSSwitch()
        control.controlSize = .small
        control.target = target
        control.action = action
        return control
    }

    static func makeCheckbox(_ title: String, target: AnyObject?, action: Selector?) -> NSButton {
        NSButton(checkboxWithTitle: title, target: target, action: action)
    }

    static func makeButton(_ title: String, target: AnyObject?, action: Selector?) -> NSButton {
        let button = NSButton(title: title, target: target, action: action)
        button.bezelStyle = .rounded
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }

    static func makePopUp(_ items: [(String, Int)], target: AnyObject? = nil, action: Selector? = nil) -> NSPopUpButton {
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        for (title, tag) in items {
            popup.addItem(withTitle: title)
            popup.lastItem?.tag = tag
        }
        popup.target = target
        popup.action = action
        return popup
    }

    static func makeColorWell(target: AnyObject?, action: Selector?) -> NSColorWell {
        let well = NSColorWell(frame: NSRect(x: 0, y: 0, width: 44, height: 24))
        if #available(macOS 13.0, *) { well.colorWellStyle = .default }
        well.target = target
        well.action = action
        well.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([well.widthAnchor.constraint(equalToConstant: 44), well.heightAnchor.constraint(equalToConstant: 24)])
        return well
    }

    /// A short right-aligned number field with an optional stepper and unit.
    static func makeNumberField(minimum: Double, maximum: Double, fractionDigits: Int = 0, width: CGFloat = 56) -> NSTextField {
        let field = AutoSelectTextField(string: "0")
        field.alignment = .right
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimum = NSNumber(value: minimum)
        formatter.maximum = NSNumber(value: maximum)
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumIntegerDigits = 1
        field.formatter = formatter
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(equalToConstant: width).isActive = true
        return field
    }

    static func makeStepper(minimum: Double, maximum: Double, increment: Double = 1) -> NSStepper {
        let stepper = NSStepper()
        stepper.minValue = minimum
        stepper.maxValue = maximum
        stepper.increment = increment
        stepper.valueWraps = false
        stepper.autorepeat = true
        return stepper
    }

    static func numberAccessory(field: NSTextField, stepper: NSStepper?, unit: String?) -> NSView {
        var views: [NSView] = [field]
        if let stepper { views.append(stepper) }
        if let unit {
            let label = NSTextField(labelWithString: unit)
            label.textColor = .secondaryLabelColor
            label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            views.append(label)
        }
        return hstack(views, spacing: 4)
    }

    static func hstack(_ views: [NSView], spacing: CGFloat = 8) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.detachesHiddenViews = true
        return stack
    }

    // MARK: Structure

    static func row(_ title: String?, note: String? = nil, _ accessory: NSView?, indent: Int = 0, wide: Bool = false) -> SettingsRowView {
        SettingsRowView(title: title, note: note, accessory: accessory, indent: indent, wideAccessory: wide)
    }

    /// A row whose content is laid out from the leading edge (check box grids, color grids).
    static func contentRow(_ content: NSView, searchTitle: String = "", indent: Int = 0) -> SettingsRowView {
        let row = SettingsRowView(title: nil, note: nil, accessory: nil, indent: indent, wideAccessory: false)
        row.searchTitle = searchTitle
        content.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12 + 24 * CGFloat(indent)),
            content.trailingAnchor.constraint(lessThanOrEqualTo: row.trailingAnchor, constant: -12),
            content.topAnchor.constraint(equalTo: row.topAnchor, constant: 10),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -10),
        ])
        return row
    }

    /// A row whose content spans the whole width of the card.
    static func fillRow(_ content: NSView, searchTitle: String = "") -> SettingsRowView {
        let row = SettingsRowView(title: nil, note: nil, accessory: nil, indent: 0, wideAccessory: false)
        row.searchTitle = searchTitle
        content.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            content.topAnchor.constraint(equalTo: row.topAnchor),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])
        return row
    }

    /// Buttons aligned to the trailing edge of a row.
    static func buttonRow(_ buttons: [NSView], searchTitle: String = "") -> SettingsRowView {
        let row = SettingsRowView(title: nil, note: nil, accessory: hstack(buttons), indent: 0, wideAccessory: false)
        row.searchTitle = searchTitle
        return row
    }

    static func header(title: String, summary: String, symbol: String, color: NSColor) -> NSView {
        let card = SettingsCardView()
        card.identifier = NSUserInterfaceItemIdentifier("category.header")
        let tile = SettingsIconView(symbolName: symbol, color: color, size: 44)
        let name = NSTextField(wrappingLabelWithString: title)
        name.font = .boldSystemFont(ofSize: 15)
        let description = NSTextField(wrappingLabelWithString: summary)
        description.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        description.textColor = .secondaryLabelColor
        for view in [tile, name, description] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(view)
        }
        let height = card.heightAnchor.constraint(equalToConstant: 72)
        height.priority = NSLayoutConstraint.Priority(249)
        NSLayoutConstraint.activate([
            tile.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            tile.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            tile.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -14),
            name.leadingAnchor.constraint(equalTo: tile.trailingAnchor, constant: 12),
            name.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            name.topAnchor.constraint(equalTo: tile.topAnchor, constant: 3),
            description.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            description.trailingAnchor.constraint(equalTo: name.trailingAnchor),
            description.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 3),
            description.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -14),
            height,
        ])
        return card
    }

    /// A group: a bold heading above a rounded card holding the rows.
    static func group(_ title: String?, _ rows: [NSView]) -> NSView {
        let stack = NSStackView(views: rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.detachesHiddenViews = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        let card = SettingsCardView()
        card.stack = stack
        card.addSubview(stack)
        var constraints = [
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ]
        constraints += rows.map { $0.widthAnchor.constraint(equalTo: stack.widthAnchor) }
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 6
        container.translatesAutoresizingMaskIntoConstraints = false
        container.identifier = NSUserInterfaceItemIdentifier("group")
        if let title {
            let heading = NSTextField(wrappingLabelWithString: title)
            heading.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
            heading.identifier = NSUserInterfaceItemIdentifier("group.heading")
            container.addArrangedSubview(heading)
            constraints.append(heading.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor))
            container.setAccessibilityLabel(title)
        }
        container.addArrangedSubview(card)
        constraints.append(card.widthAnchor.constraint(equalTo: container.widthAnchor))
        NSLayoutConstraint.activate(constraints)
        container.setAccessibilityElement(true)
        container.setAccessibilityRole(.group)
        return container
    }

    /// The whole pane: header card and groups, 18 points between groups.
    static func pane(header: NSView, groups: [NSView]) -> NSView {
        let stack = NSStackView(views: [header] + groups)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        stack.setCustomSpacing(14, after: header)
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 24, bottom: 24, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        for view in stack.arrangedSubviews {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -48).isActive = true
        }
        return stack
    }

    /// Color wells in two columns, each followed by its name (TeXShop's theme groups).
    static func colorGrid(_ items: [(NSColorWell, String)]) -> (NSView, [SettingsLabel]) {
        var cells: [[NSView]] = []
        var labels: [SettingsLabel] = []
        var current: [NSView] = []
        for (well, title) in items {
            let label = SettingsLabel(labelWithString: title)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.enabledTextColor = .labelColor
            labels.append(label)
            current.append(hstack([well, label], spacing: 10))
            if current.count == 2 { cells.append(current); current = [] }
        }
        if !current.isEmpty { cells.append(current + [NSGridCell.emptyContentView]) }
        let grid = NSGridView(views: cells)
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 10
        grid.columnSpacing = 24
        grid.xPlacement = .leading
        grid.yPlacement = .center
        for index in 0..<grid.numberOfColumns { grid.column(at: index).width = 220 }
        return (grid, labels)
    }
}
