#import "MyLayoutManager.h"
#import "NSDictionary-Extension.h"
#import "NSColor-Extension.h"
#import "NSColor-DefaultColor.h"
#import "MyATSTypesetter.h"

@implementation MyLayoutManager
@synthesize controller;

- (instancetype)init
{
    self = [super init];
    self.typesetter = [MyATSTypesetter new];
    return self;
}

- (NSPoint)pointToDrawGlyphAtIndex:(NSUInteger)inGlyphIndex adjust:(NSSize)inSize
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
    Profile *currentProfile = [controller currentProfile];
	
    NSFont *theFont = self.textStorage.font;
    NSColor *theColor = [currentProfile colorForKey:InvisibleColorKey];
    if (!theColor) {
        theColor = NSColor.defaultInvisibleColor;
    }
    NSDictionary<NSString*,id> *attributes = @{
                                               NSFontAttributeName: theFont,
                                               NSForegroundColorAttributeName: theColor
                                               };
	
    NSString *replacementCharacter = [NSString stringWithFormat:@"%C", 0xFFFD]; // Replacement Character

    for (theGlyphIndex = inGlyphRange.location; theGlyphIndex < theLengthToRedraw; theGlyphIndex++) {
		theCharIndex = [self characterIndexForGlyphAtIndex:theGlyphIndex];
		theCharacter = [theCompleteStr characterAtIndex:theCharIndex];
		
		if (theCharacter == '\t' && [currentProfile boolForKey:ShowTabCharacterKey]) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[controller.tabCharacter drawAtPoint:thePointToDraw withAttributes:attributes];
		} else if (theCharacter == '\n' && [currentProfile boolForKey:ShowNewLineCharacterKey]) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[controller.returnCharacter drawAtPoint:thePointToDraw withAttributes:attributes];
		} else if (theCharacter == 0x3000 && [currentProfile boolForKey:ShowFullwidthSpaceCharacterKey]) { // Fullwidth-space (JP)
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[controller.fullwidthSpaceCharacter drawAtPoint:thePointToDraw withAttributes:attributes];
		} else if (theCharacter == ' ' && [currentProfile boolForKey:ShowSpaceCharacterKey]) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[controller.spaceCharacter drawAtPoint:thePointToDraw withAttributes:attributes];
        } else if ((theCharacter >= 0x0000 && theCharacter <= 0x0008) || (theCharacter >= 0x000B && theCharacter <= 0x001F)) { // other control characters
            thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
            [replacementCharacter drawAtPoint:thePointToDraw withAttributes:attributes];
        }
	}
	[super drawGlyphsForGlyphRange:inGlyphRange atPoint:inContainerOrigin];
}

-(CGFloat)replacementGlyphWidth
{
    NSFont *textFont = self.textStorage.font;
    NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:textFont.pointSize];
    if (!font) {
        font = textFont;
    }
    NSGlyph glyph = [font glyphWithName:@"replacement"];
    NSRect rect = [font boundingRectForGlyph:glyph];
    return rect.size.width;
}

@end
