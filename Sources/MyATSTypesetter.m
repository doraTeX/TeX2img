#import "MyATSTypesetter.h"
#import "MyLayoutManager.h"

@implementation MyATSTypesetter
-(NSTypesetterControlCharacterAction)actionForControlCharacterAtIndex:(NSUInteger)charIndex
{
    NSTypesetterControlCharacterAction action = [super actionForControlCharacterAtIndex:charIndex];
    
    if (action & NSTypesetterZeroAdvancementAction) {
        unichar character = [self.attributedString.string characterAtIndex:charIndex];
        if (!CFStringIsSurrogateLowCharacter(character)) {
            return NSTypesetterWhitespaceAction;
        }
    }
    
    return action;
}

-(NSRect)boundingBoxForControlGlyphAtIndex:(NSUInteger)glyphIndex
                          forTextContainer:(NSTextContainer*)textContainer
                      proposedLineFragment:(NSRect)proposedRect
                             glyphPosition:(NSPoint)glyphPosition
                            characterIndex:(NSUInteger)charIndex
{
    NSRect rect = proposedRect;
    rect.size.width = ((MyLayoutManager*)(self.layoutManager)).replacementGlyphWidth;
    return rect;
}
@end
