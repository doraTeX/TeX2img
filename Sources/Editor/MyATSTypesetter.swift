import AppKit

/// Gives the control characters drawn as U+FFFD the width of that marker (TeXShop's TSControlCharacterTypesetter).
/// A form feed or another control character no longer breaks the line or hides the rest of the text.
class MyATSTypesetter: NSATSTypesetter {
    override func actionForControlCharacter(at index: Int) -> NSTypesetterControlCharacterAction {
        if let string = attributedString?.string as NSString?, index < string.length,
           InvisibleCharacters.isShownControlCharacter(string.character(at: index)) {
            return .whitespaceAction
        }
        return super.actionForControlCharacter(at: index)
    }

    override func boundingBox(forControlGlyphAt glyphIndex: Int,
                              for textContainer: NSTextContainer,
                              proposedLineFragment proposedRect: NSRect,
                              glyphPosition: NSPoint,
                              characterIndex charIndex: Int) -> NSRect {
        var rect = super.boundingBox(forControlGlyphAt: glyphIndex, for: textContainer, proposedLineFragment: proposedRect,
                                     glyphPosition: glyphPosition, characterIndex: charIndex)
        if let attributed = attributedString, charIndex < attributed.length,
           InvisibleCharacters.isShownControlCharacter((attributed.string as NSString).character(at: charIndex)) {
            let font = attributed.attribute(.font, at: charIndex, effectiveRange: nil) as? NSFont
                ?? NSFont.userFixedPitchFont(ofSize: 12) ?? NSFont.systemFont(ofSize: 12)
            rect.size.width = (InvisibleCharacters.controlCharacterMarker as NSString).size(withAttributes: [.font: font]).width
        }
        return rect
    }
}
