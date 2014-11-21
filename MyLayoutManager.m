#import "MyLayoutManager.h"
#import "NSDictionary-Extension.h"

@implementation MyLayoutManager
- (void)setController:(ControllerG*)aController
{
	controller = aController;
}

- (id)init
{
	[super init];
	unichar _tabCharacter = 0x2023; // 他の候補：0x00AC, 0x21E5, 0x25B9
	unichar _newLineCharacter = 0x21B5; // 他の候補：0x00B6, 0x21A9, 0x23CE
	unichar _fullwidthSpaceCharacter = 0x25A1; // 他の候補：0x22A0, 0x25A0, 0x2022
	unichar _spaceCharacter = 0x2423; // 他の候補：0x00B7, 0x00B0, 0x02D0
	tabCharacter = [[NSString stringWithCharacters:&_tabCharacter length:1] retain];
    newLineCharacter = [[NSString stringWithCharacters:&_newLineCharacter length:1] retain];
    fullwidthSpaceCharacter = [[NSString stringWithCharacters:&_fullwidthSpaceCharacter length:1] retain];
	spaceCharacter = [[NSString stringWithCharacters:&_spaceCharacter length:1] retain];
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
    NSString *theCompleteStr = [[self textStorage] string];
    unsigned int theLengthToRedraw = NSMaxRange(inGlyphRange);
    unsigned int theGlyphIndex, theCharIndex = 0;
    unichar theCharacter;
    NSPoint thePointToDraw;
	
	float theInsetWidth = 0.0;
	float theInsetHeight = 4.0;
	NSSize theSize = NSMakeSize(theInsetWidth, theInsetHeight);
	
    NSFont *theFont = [[self textStorage] font];
    NSColor *theColor = [NSColor orangeColor];
    NSDictionary* _attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								 theFont, NSFontAttributeName, 
								 theColor, NSForegroundColorAttributeName,  nil];
	
	NSDictionary* currentProfile = [controller currentProfile];
	
	for (theGlyphIndex = inGlyphRange.location; theGlyphIndex < theLengthToRedraw; theGlyphIndex++) {
		theCharIndex = [self characterIndexForGlyphAtIndex:theGlyphIndex];
		theCharacter = [theCompleteStr characterAtIndex:theCharIndex];
		
		if (theCharacter == '\t' && [currentProfile boolForKey:@"showTabCharacter"]) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[tabCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		} else if (theCharacter == '\n' && [currentProfile boolForKey:@"showNewLineCharacter"]) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[newLineCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		} else if (theCharacter == 0x3000 && [currentProfile boolForKey:@"showFullwidthSpaceCharacter"]) { // Fullwidth-space (JP)
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[fullwidthSpaceCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		} else if (theCharacter == ' ' && [currentProfile boolForKey:@"showSpaceCharacter"]) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[spaceCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		}
	}
	[super drawGlyphsForGlyphRange:inGlyphRange atPoint:inContainerOrigin];
}

@end