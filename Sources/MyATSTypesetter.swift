import Foundation

class MyATSTypesetter: NSATSTypesetter {
    override func actionForControlCharacter(at index: Int) -> NSTypesetterControlCharacterAction {
        let action = super.actionForControlCharacter(at: index)
        
        if action.contains(.zeroAdvancementAction),
           let character = (self.attributedString?.string as NSString?)?.character(at: index),
           !CFStringIsSurrogateLowCharacter(character) {
            return .whitespaceAction
        }
    
        return action
    }
    
    override func boundingBox(forControlGlyphAt glyphIndex: Int,
                              for textContainer: NSTextContainer,
                              proposedLineFragment proposedRect: NSRect,
                              glyphPosition: NSPoint,
                              characterIndex charIndex: Int) -> NSRect {
        var rect = proposedRect
        if let width = (self.layoutManager as? MyLayoutManager)?.replacementGlyphWidth() {
            rect.size.width = width
        }
        return rect
    }
}


