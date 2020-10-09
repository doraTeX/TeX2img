import Cocoa

class MyLayoutManager: NSLayoutManager {
    private let controller: ControllerG?
    private let replacementCharacter = "\u{FFFD}" // Replacement Character
    
    required init?(coder: NSCoder) {
        controller = nil
        super.init(coder: coder)
        self.typesetter = MyATSTypesetter()
    }
    
    @objc init(controller: ControllerG) {
        self.controller = controller
        super.init()
        self.typesetter = MyATSTypesetter()
    }
    
    func point(toDrawGlyphAt inGlyphIndex: Int, adjust inSize: NSSize) -> NSPoint {
        var outPoint = self.location(forGlyphAt: inGlyphIndex)
        let theGlyphRect = self.lineFragmentRect(forGlyphAt: inGlyphIndex, effectiveRange: nil)
        
        outPoint.x += inSize.width
        outPoint.y = theGlyphRect.origin.y - inSize.height
        
        return outPoint
    }
    
    override func drawGlyphs(forGlyphRange inGlyphRange: NSRange, at inContainerOrigin: NSPoint) {
        
        guard let controller = self.controller,
              let invisibleColor = controller.invisibleColor(),
              let textStorage = self.textStorage,
              let theFont = textStorage.font else {
            super.drawGlyphs(forGlyphRange: inGlyphRange, at: inContainerOrigin)
            return
        }
        
        let theCompleteStr = textStorage.string
        let theLengthToRedraw = NSMaxRange(inGlyphRange)
        
        let theInsetWidth = 0.0
        let theInsetHeight = 4.0
        let theSize = NSSize(width: theInsetWidth, height: theInsetHeight)
        
        let attributes = [NSAttributedString.Key.font: theFont,
                          NSAttributedString.Key.foregroundColor: invisibleColor]
        
        
        for theGlyphIndex in inGlyphRange.location..<theLengthToRedraw  {
            let theCharIndex = self.characterIndexForGlyph(at: theGlyphIndex)
            let theCharacter = theCompleteStr.utf16[safe: theCharIndex]!
            let thePointToDraw = self.point(toDrawGlyphAt: theGlyphIndex, adjust: theSize)
            
            if theCharacter == "\t".utf16.first,
               controller.showTabCharacterEnabled() {
                controller.tabCharacter().draw(at: thePointToDraw, withAttributes: attributes)
            } else if theCharacter == "\n".utf16.first,
                      controller.showNewLineCharacterEnabled() {
                controller.returnCharacter().draw(at: thePointToDraw, withAttributes: attributes)
            } else if theCharacter == 0x3000,
                      controller.showFullwidthSpaceCharacterEnabled() { // Fullwidth-space (JP)
                controller.fullwidthSpaceCharacter().draw(at: thePointToDraw, withAttributes: attributes)
            } else if theCharacter == " ".utf16.first,
                      controller.showSpaceCharacterEnabled() {
                controller.spaceCharacter().draw(at: thePointToDraw, withAttributes: attributes)
            } else if (theCharacter >= 0x0000 && theCharacter <= 0x0008) || (theCharacter >= 0x000B && theCharacter <= 0x001F) { // other control characters
                replacementCharacter.draw(at: thePointToDraw, withAttributes: attributes)
            }
        }
        
        super.drawGlyphs(forGlyphRange: inGlyphRange, at: inContainerOrigin)
        
    }
    
    var replacementGlyphWidth: CGFloat? {
        guard let textFont = self.textStorage?.font else { return nil }
        let font = NSFont(name: "Lucida Grande", size: textFont.pointSize) ?? textFont
        let glyph = font.glyph(withName: "replacement")
        let rect = font.boundingRect(forGlyph: glyph)
        
        return rect.size.width
    }
    
}
