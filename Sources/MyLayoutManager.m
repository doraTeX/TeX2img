#import "MyLayoutManager.h"
#import "NSDictionary-Extension.h"
#import "global.h"

@interface MyLayoutManager()
@property NSString *tabCharacter;
@property NSString *returnCharacter;
@property NSString *fullwidthSpaceCharacter;
@property NSString *spaceCharacter;
@end

@implementation MyLayoutManager
- (id)init
{
    if (!(self = super.init)) {
        return nil;
    }
	unichar u_tabCharacter = 0x2023; // 他の候補：0x00AC, 0x21E5, 0x25B9
	unichar u_returnCharacter = 0x21B5; // 他の候補：0x00B6, 0x21A9, 0x23CE
	unichar u_fullwidthSpaceCharacter = 0x25A1; // 他の候補：0x22A0, 0x25A0, 0x2022
	unichar u_spaceCharacter = 0x2423; // 他の候補：0x00B7, 0x00B0, 0x02D0
	_tabCharacter = [NSString stringWithCharacters:&u_tabCharacter length:1];
    _returnCharacter = [NSString stringWithCharacters:&u_returnCharacter length:1];
    _fullwidthSpaceCharacter = [NSString stringWithCharacters:&u_fullwidthSpaceCharacter length:1];
	_spaceCharacter = [NSString stringWithCharacters:&u_spaceCharacter length:1];
	return self;
}

- (NSPoint)pointToDrawGlyphAtIndex:(unsigned int)inGlyphIndex adjust:(NSSize)inSize
{
    NSPoint outPoint = [self locationForGlyphAtIndex:inGlyphIndex];
    NSRect theGlyphRect = [self lineFragmentRectForGlyphAtIndex:inGlyphIndex effectiveRange:NULL];
	
    outPoint.x += inSize.width;
    outPoint.y = theGlyphRect.origin.y - inSize.height;
	
    return outPoint;
}

- (void)drawGlyphsForGlyphRange:(NSRange)inGlyphRange atPoint:(NSPoint)inContainerOrigin
{
    NSString *theCompleteStr = self.textStorage.string;
    NSUInteger theLengthToRedraw = NSMaxRange(inGlyphRange);
    NSUInteger theGlyphIndex, theCharIndex = 0;
    unichar theCharacter;
    NSPoint thePointToDraw;
	
	float theInsetWidth = 0.0;
	float theInsetHeight = 4.0;
	NSSize theSize = NSMakeSize(theInsetWidth, theInsetHeight);
	
    NSFont *theFont = self.textStorage.font;
    NSColor *theColor = NSColor.orangeColor;
    NSDictionary* _attributes = @{NSFontAttributeName: theFont, 
								 NSForegroundColorAttributeName: theColor};
	
	NSDictionary* currentProfile = _controller.currentProfile;
	
	for (theGlyphIndex = inGlyphRange.location; theGlyphIndex < theLengthToRedraw; theGlyphIndex++) {
		theCharIndex = [self characterIndexForGlyphAtIndex:theGlyphIndex];
		theCharacter = [theCompleteStr characterAtIndex:theCharIndex];
		
		if (theCharacter == '\t' && [currentProfile boolForKey:ShowTabCharacterKey]) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[_tabCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		} else if (theCharacter == '\n' && [currentProfile boolForKey:ShowNewLineCharacterKey]) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[_returnCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		} else if (theCharacter == 0x3000 && [currentProfile boolForKey:ShowFullwidthSpaceCharacterKey]) { // Fullwidth-space (JP)
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[_fullwidthSpaceCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		} else if (theCharacter == ' ' && [currentProfile boolForKey:ShowSpaceCharacterKey]) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[_spaceCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		}
	}
	[super drawGlyphsForGlyphRange:inGlyphRange atPoint:inContainerOrigin];
}

@end