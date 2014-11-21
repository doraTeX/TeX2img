#import "TeXTextView.h"
#import "NSDictionary-Extension.h"
#import "NSMutableString-Extension.h"

static BOOL isValidTeXCommandChar(int c);

static BOOL isValidTeXCommandChar(int c)
{
	if ((c >= 'A') && (c <= 'Z'))
		return YES;
	else if ((c >= 'a') && (c <= 'z'))
		return YES;
	else if (c == '@')
		return YES;
	else
		return NO;
}


@implementation TeXTextView
- (void)colorizeText:(BOOL)colorize
{
	
	NSLayoutManager *layoutManager;
	NSString		*textString;
	unsigned		length;
	NSRange			colorRange;
	unsigned		location;
	int				theChar;
	unsigned		aLineStart;
	unsigned		aLineEnd;
	unsigned		end;
	
	float r,g,b;
	NSColor* color;
	NSDictionary	*commandColorAttribute;
	NSDictionary	*commentColorAttribute;
	NSDictionary	*markerColorAttribute;
	
	color = [NSColor textColor];
	
	r = 0.0;
	g = 0.0;
	b = 1.0;
	if(colorize) color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	commandColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];
	
	r = 1.0;
	g = 0.0;
	b = 0.0;
	if(colorize) color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	commentColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];
	
	r = 0.02;
	g = 0.51;
	b = 0.13;
	if(colorize) color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	markerColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];
	
	
	// Fetch the underlying layout manager and string.
	layoutManager = [self layoutManager];
	textString = [self string];
	length = [textString length];
	
	NSRange range = NSMakeRange(0, length);
	
	
	// We only perform coloring for full lines here, so extend the given range to full lines.
	// Note that aLineStart is the start of *a* line, but not necessarily the same line
	// for which aLineEnd marks the end! We may span many lines.
	[textString getLineStart:&aLineStart end:&aLineEnd contentsEnd:nil forRange:range];
	
	
	
	// We reset the color of all chars in the given range to the regular color; later, we'll
	// then only recolor anything which is supposed to have another color.
	colorRange.location = aLineStart;
	colorRange.length = aLineEnd - aLineStart;
	// WARNING!! The following line has been commented out to restore changing the text color
	// June 27, 2008; Koch; I don't understand the previous warning; the line below fixes cases when removing a comment leaves text red
	[layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:colorRange];
	
	// Now we iterate over the whole text and perform the actual recoloring.
	location = aLineStart;
	while (location < aLineEnd) {
		theChar = [textString characterAtIndex: location];
		
		if ((theChar == '{') || (theChar == '}') || (theChar == '$')) {
			// The three special characters { } $ get an extra color.
			colorRange.location = location;
			colorRange.length = 1;
			[layoutManager addTemporaryAttributes:markerColorAttribute forCharacterRange:colorRange];
			location++;
		} else if (theChar == '%') {
			// Comments are started by %. Everything after that on the same line is a comment.
			colorRange.location = location;
			colorRange.length = 1;
			[textString getLineStart:nil end:nil contentsEnd:&end forRange:colorRange];
			colorRange.length = (end - location);
			[layoutManager addTemporaryAttributes:commentColorAttribute forCharacterRange:colorRange];
			location = end;
		} else if (theChar == '\\' || theChar == 0x00a5) {
			// A backslash (or a yen): a new TeX command starts here.
			// There are two cases: Either a sequence of letters A-Za-z follow, and we color all of them.
			// Or a single non-alpha character follows. Then we color that, too, but nothing else.
			colorRange.location = location;
			colorRange.length = 1;
			location++;
			if ((location < aLineEnd) && (!isValidTeXCommandChar([textString characterAtIndex: location]))) {
				location++;
				colorRange.length = location - colorRange.location;
			} else {
				while ((location < aLineEnd) && (isValidTeXCommandChar([textString characterAtIndex: location]))) {
					location++;
					colorRange.length = location - colorRange.location;
				}
			}
			
			[layoutManager addTemporaryAttributes:commandColorAttribute forCharacterRange:colorRange];
		} else
			location++;
	}
}

- (void)insertText:(id)aString
{
	NSDictionary* currentProfile = [controller currentProfile];

	if([aString isEqualToString:@"¥"] && [currentProfile boolForKey:@"convertYenMark"])
	{
		[super insertText:@"\\"];
	}
	else
	{
		[super insertText:aString];
	}
	[self colorizeText:[currentProfile boolForKey:@"colorizeText"]];
}

// クリップボードから貼り付けられる円マークをバックスラッシュに置き換えて貼り付ける
- (BOOL)readSelectionFromPasteboard:(NSPasteboard*)pboard type:(NSString*)type
{
	NSDictionary* currentProfile = [controller currentProfile];

	if([type isEqualToString:NSStringPboardType] && [currentProfile boolForKey:@"convertYenMark"])
	{
		NSMutableString *string = [NSMutableString stringWithString:[pboard stringForType:NSStringPboardType]];
		if (string)
		{
			[string replaceYenWithBackSlash];
			
			// Replace the text--imitate what happens in ordinary editing
			NSRange	selectedRange = [self selectedRange];
			if ([self shouldChangeTextInRange:selectedRange replacementString:string])
			{
				[self replaceCharactersInRange:selectedRange withString:string];
				[self didChangeText];
			}
			// by returning YES, "Undo Paste" menu item will be set up by system
			[self colorizeText:[currentProfile boolForKey:@"colorizeText"]];
			return YES;
		}
		else
		{
			return NO;
		}
	}
	return [super readSelectionFromPasteboard:pboard type:type];
}
@end
