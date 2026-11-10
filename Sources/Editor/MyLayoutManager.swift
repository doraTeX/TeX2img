import Cocoa

/// Control characters other than tab, line feed and carriage return take no space and would be invisible;
/// they are drawn as U+FFFD whether or not invisible characters are shown (TeXShop's TSInvisibleCharacters).
enum InvisibleCharacters {
    static let controlCharacterMarker = "\u{FFFD}"

    static func isShownControlCharacter(_ character: unichar) -> Bool {
        character <= 0x08 || (character >= 0x0B && character <= 0x1F && character != 0x0D)
    }
}

class MyLayoutManager: NSLayoutManager {
    private let controller: ControllerG?

    required init?(coder: NSCoder) {
        controller = nil
        super.init(coder: coder)
        self.typesetter = MyATSTypesetter()
    }

    init(controller: ControllerG) {
        self.controller = controller
        super.init()
        self.typesetter = MyATSTypesetter()
    }

    private struct MarkerKey: Hashable {
        let marker: String
        let font: NSFont
    }

    /// Draws a marker so that its baseline matches the baseline of the text it stands for.
    /// Markers are laid out by their own layout manager, so the result does not depend on fixed offsets
    /// that changed between macOS versions (TeXShop's TSLayoutManager).
    private func drawMarker(_ marker: String, atGlyphIndex glyphIndex: Int, containerOrigin: NSPoint,
                            attributes: [NSAttributedString.Key: Any], cache: inout [MarkerKey: NSTextStorage]) {
        guard !marker.isEmpty, let font = attributes[.font] as? NSFont else { return }
        let key = MarkerKey(marker: marker, font: font)
        // The text storage owns its layout manager, so the cache keeps the storage.
        let storage: NSTextStorage
        if let cached = cache[key] {
            storage = cached
        } else {
            storage = NSTextStorage(string: marker, attributes: attributes)
            let layout = NSLayoutManager()
            let container = NSTextContainer(containerSize: NSSize(width: 10000, height: 10000))
            container.lineFragmentPadding = 0
            storage.addLayoutManager(layout)
            layout.addTextContainer(container)
            layout.ensureLayout(for: container)
            cache[key] = storage
        }
        guard let markerLayout = storage.layoutManagers.first, markerLayout.numberOfGlyphs > 0 else { return }
        let textBaseline = location(forGlyphAt: glyphIndex)
        let textLine = lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        let markerBaseline = markerLayout.location(forGlyphAt: 0)
        let markerLine = markerLayout.lineFragmentRect(forGlyphAt: 0, effectiveRange: nil)
        let origin = NSPoint(x: containerOrigin.x + textLine.origin.x + textBaseline.x - markerLine.origin.x - markerBaseline.x,
                             y: containerOrigin.y + textLine.origin.y + textBaseline.y - markerLine.origin.y - markerBaseline.y)
        markerLayout.drawGlyphs(forGlyphRange: NSRange(location: 0, length: markerLayout.numberOfGlyphs), at: origin)
    }

    override func drawGlyphs(forGlyphRange inGlyphRange: NSRange, at inContainerOrigin: NSPoint) {
        guard let controller, let textStorage else {
            super.drawGlyphs(forGlyphRange: inGlyphRange, at: inContainerOrigin)
            return
        }
        // Read the settings once per drawing pass, not once per glyph.
        let showTab = controller.showTabCharacterEnabled()
        let showNewLine = controller.showNewLineCharacterEnabled()
        let showFullwidthSpace = controller.showFullwidthSpaceCharacterEnabled()
        let showSpace = controller.showSpaceCharacterEnabled()
        let tabMarker = controller.tabCharacter()
        let newLineMarker = controller.returnCharacter()
        let fullwidthSpaceMarker = controller.fullwidthSpaceCharacter()
        let spaceMarker = controller.spaceCharacter()
        let color = controller.invisibleColor()
        let string = textStorage.string as NSString
        var cache: [MarkerKey: NSTextStorage] = [:]

        for glyphIndex in inGlyphRange.location..<NSMaxRange(inGlyphRange) {
            let characterIndex = characterIndexForGlyph(at: glyphIndex)
            guard characterIndex < string.length else { continue }
            let character = string.character(at: characterIndex)
            let marker: String?
            switch character {
            case 0x09 where showTab: marker = tabMarker
            case 0x0A where showNewLine: marker = newLineMarker
            case 0x3000 where showFullwidthSpace: marker = fullwidthSpaceMarker
            case 0x20 where showSpace: marker = spaceMarker
            default: marker = InvisibleCharacters.isShownControlCharacter(character) ? InvisibleCharacters.controlCharacterMarker : nil
            }
            guard let marker else { continue }
            // Follow inline font changes.
            let font = textStorage.attribute(.font, at: characterIndex, effectiveRange: nil) as? NSFont
                ?? NSFont.userFixedPitchFont(ofSize: 12) ?? NSFont.systemFont(ofSize: 12)
            drawMarker(marker, atGlyphIndex: glyphIndex, containerOrigin: inContainerOrigin,
                       attributes: [.font: font, .foregroundColor: color], cache: &cache)
        }
        super.drawGlyphs(forGlyphRange: inGlyphRange, at: inContainerOrigin)
    }
}
