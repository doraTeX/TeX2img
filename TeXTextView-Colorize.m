#import "TeXTextView.h"
#import "NSDictionary-Extension.h"

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

@implementation TeXTextView (Colorize)
- (void)colorizeText:(BOOL)colorize
{
	NSLayoutManager *layoutManager;
	NSString		*textString;
	NSUInteger		length;
	NSRange			colorRange;
	NSUInteger		location;
	int				theChar;
	NSUInteger		aLineStart;
	NSUInteger		aLineEnd;
	NSUInteger		end;
	
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

- (void)resetHighlight:(id)sender
{
	[self colorizeText:[[controller currentProfile] boolForKey:@"colorizeText"]];
	braceHighlighting = NO;
}

- (void)showIndicator:(NSString*)range
{
	[self showFindIndicatorForRange:NSRangeFromString(range)];
}

- (void)resetBackgroundColorOfTextView:(id)sender
{
	[self setBackgroundColor:[NSColor controlBackgroundColor]];
}

- (void)resetBackgroundColor:(id)sender
{
	[[self layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, [[self textStorage] length])];
	contentHighlighting = NO;
}

- (void)highlightContent:(NSString*)range
{
	contentHighlighting = YES;
	[[self layoutManager] addTemporaryAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
												   [NSColor colorWithDeviceRed:1 green:1 blue:0.5 alpha:1],
												   NSBackgroundColorAttributeName, nil ]	 // added by Taylor
							   forCharacterRange:NSRangeFromString(range)];
}

- (void)textViewDidChangeSelection:(NSNotification *)inNotification
{
	NSLayoutManager* layoutManager = [self layoutManager];
	NSDictionary* profile = [controller currentProfile];

	// Notification の処理で色づけの変更を行うと，delete を押したときにバグるので，performSelector で別途呼び出して処理する
	if(contentHighlighting){
		[self performSelector:@selector(resetBackgroundColor:) 
				   withObject:nil afterDelay:0]; // 既存の背景色の消去
	}
	
	HighlightPattern highlightPattern = [profile integerForKey:@"highlightPattern"];

	if(highlightPattern == SOLID || braceHighlighting){
		[self resetHighlight:nil];
	}

	highlightBracesColorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSColor magentaColor], NSForegroundColorAttributeName, nil ];
	unichar k_braceCharList[] = {0x0028, 0x0029, 0x005B, 0x005D, 0x007B, 0x007D, 0x003C, 0x003E}; // == ()[]{}<>
    
	NSString *theString = [[self textStorage] string];
    NSUInteger theStringLength = [theString length];
    if (theStringLength == 0) { return; }
    NSRange theSelectedRange = [self selectedRange];
    NSInteger theLocation = theSelectedRange.location;
    NSInteger theDifference = theLocation - lastCursorLocation;
    lastCursorLocation = theLocation;

	if (theStringLength - lastStringLength == -1) {
		lastStringLength = theStringLength;
		return;
	}
	lastStringLength = theStringLength;
	
    if (theDifference != 1 && theDifference != -1) { // != 1 の方だけだと，キャレットを後方移動した場合にのみ強調表示させる
        return; // If the difference is more than one, they've moved the cursor with the mouse or it has been moved by resetSelectedRange below and we shouldn't check for matching braces then
    }
    
    if (theDifference == 1) { // Check if the cursor has moved forward
        theLocation--;
    }
	
    if (theLocation == theStringLength) {
        return;
    }
	NSInteger originalLocation = theLocation;
	
	BOOL checkBrace = [profile boolForKey:@"checkBrace"];
	BOOL checkBracket = [profile boolForKey:@"checkBracket"];
	BOOL checkSquareBracket = [profile boolForKey:@"checkSquareBracket"];
	BOOL checkParen = [profile boolForKey:@"checkParen"];
	
    unichar theUnichar = [theString characterAtIndex:theLocation];
	unichar previousChar = (theLocation > 0) ? [theString characterAtIndex:theLocation-1] : 0;
	BOOL notCS = ((previousChar != '\\') && (previousChar != 0x00a5));
    unichar theCurChar, theBraceChar;
	int inc;
    if (theUnichar == ')' && checkParen && notCS) {
        theBraceChar = k_braceCharList[0];
		inc = -1;
    } else if (theUnichar == '(' && checkParen && notCS) {
        theBraceChar = k_braceCharList[1];
		inc = 1;
    } else if (theUnichar == ']' && checkSquareBracket && notCS) {
        theBraceChar = k_braceCharList[2];
		inc = -1;
    } else if (theUnichar == '[' && checkSquareBracket && notCS) {
        theBraceChar = k_braceCharList[3];
		inc = 1;
    } else if (theUnichar == '}' && checkBrace && notCS) {
        theBraceChar = k_braceCharList[4];
		inc = -1;
    } else if (theUnichar == '{' && checkBrace && notCS) {
        theBraceChar = k_braceCharList[5];
		inc = 1;
    } else if (theUnichar == '>' && checkBracket && notCS) {
        theBraceChar = k_braceCharList[6];
		inc = -1;
    } else if (theUnichar == '<' && checkBracket && notCS) {
        theBraceChar = k_braceCharList[7];
		inc = 1;
    } else {
        return;
    }
    NSUInteger theSkipMatchingBrace = 0;
    theCurChar = theUnichar;
	
    while ((theLocation += inc) >= 0 && (theLocation < theStringLength)) {
        theUnichar = [theString characterAtIndex:theLocation];
		previousChar = (theLocation > 0) ? [theString characterAtIndex:theLocation-1] : 0;
		notCS = ((previousChar != '\\') && (previousChar != 0x00a5));
        if (theUnichar == theBraceChar && notCS) {
            if (!theSkipMatchingBrace) {
				// 一瞬選択する方式での強調表示
				/*
				 [self setSelectedRange: NSMakeRange(theLocation, 1)
				 affinity: NSSelectByCharacter stillSelecting: YES];
				 [self display];
				 NSDate* myDate = [NSDate date];
				 while ([myDate timeIntervalSinceNow] > - 0.075);
				 [self setSelectedRange: theSelectedRange];
				 */
				
				if (highlightPattern != NOHIGHLIGHT){
					// 色づけ方式での強調表示
					braceHighlighting = YES;
					[layoutManager addTemporaryAttributes:highlightBracesColorDict 
										forCharacterRange:NSMakeRange(theLocation, 1)];
					[layoutManager addTemporaryAttributes:highlightBracesColorDict 
										forCharacterRange:NSMakeRange(originalLocation, 1)];
					[self display];
				}

                if([profile boolForKey:@"highlightContent"]){
					[self performSelector:@selector(highlightContent:) 
							   withObject:NSStringFromRange(NSMakeRange(MIN(originalLocation, theLocation), ABS(originalLocation - theLocation)+1)) afterDelay:0];
				}
				
				if (!autoCompleting && [profile boolForKey:@"flashInMoving"]) {
					[self performSelector:@selector(showIndicator:) 
							   withObject:NSStringFromRange(NSMakeRange(theLocation, 1)) 
							   afterDelay:0];
				}
				
				if (highlightPattern == FLASH) {
					[self performSelector:@selector(resetHighlight:) 
							   withObject:NSStringFromRange(NSMakeRange(theLocation, 1)) afterDelay:0.30];
				}
                return;
            } else {
                theSkipMatchingBrace += inc;
            }
        } else if (theUnichar == theCurChar && notCS) {
            theSkipMatchingBrace -= inc;
        }
    }
	// 対応する開始括弧がなかったときの処理
    if([profile boolForKey:@"beep"]) NSBeep();
	if([profile boolForKey:@"flashBackground"]) {
		[self setBackgroundColor:[NSColor colorWithDeviceRed:1 green:0.95 blue:1 alpha:1]];
		[self performSelector:@selector(resetBackgroundColorOfTextView:) 
				   withObject:nil afterDelay:0.20];
	}
}

- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	[super shouldChangeTextInRange:affectedCharRange replacementString:replacementString];
	
	NSRange			matchRange;
	NSString		*textString;
	int				i, j, count, uchar, leftpar, rightpar;
//	NSDate			*myDate;
	
	if ([replacementString length] != 1)
		return YES;
	
	rightpar = [replacementString characterAtIndex:0];

	NSDictionary* profile = [controller currentProfile];

	HighlightPattern highlightPattern = [profile integerForKey:@"highlightPattern"];
	BOOL checkBrace = [profile boolForKey:@"checkBrace"];
	BOOL checkBracket = [profile boolForKey:@"checkBracket"];
	BOOL checkSquareBracket = [profile boolForKey:@"checkSquareBracket"];
	BOOL checkParen = [profile boolForKey:@"checkParen"];
	
	if (highlightPattern != NOHIGHLIGHT) {
		if (!(   ((rightpar == '}') && checkBrace)
			  || ((rightpar == ')') && checkParen)
			  || ((rightpar == '>') && checkBracket)
			  || ((rightpar == ']') && checkSquareBracket ))){
			return YES;
		}
		
		if (rightpar == '}')
			leftpar = '{';
		else if (rightpar == ')')
			leftpar = '(';
		else if (rightpar == '>')
			leftpar = '<';
		else
			leftpar = '[';
		
		textString = [self string];
		i = affectedCharRange.location;
		j = 1;
		count = 1;
		
		unichar previousChar = (i > 0) ? [textString characterAtIndex:i-1] : 0;
		BOOL notCS = ((previousChar != '\\') && (previousChar != 0x00a5));
		if (!notCS) {
			return YES;
		}
		
		while ((i > 0) && (j < 5000)) {
			i--; j++;
			uchar = [textString characterAtIndex:i];
			previousChar = (i > 0) ? [textString characterAtIndex:i-1] : 0;
			notCS = ((previousChar != '\\') && (previousChar != 0x00a5));
			if (uchar == rightpar && notCS)
				count++;
			else if (uchar == leftpar && notCS)
				count--;
			if (count == 0) {
				matchRange.location = i;
				matchRange.length = 1;
				
//				if (NSFoundationVersionNumber > LEOPARD) {
					[self performSelector:@selector(showIndicator:) 
							   withObject:NSStringFromRange(matchRange)
							   afterDelay:0.0];
//				}
//				else {
//					[self setSelectedRange: matchRange
//								  affinity: NSSelectByCharacter stillSelecting: YES];
//					[self display];
//					myDate = [NSDate date];
//					while ([myDate timeIntervalSinceNow] > - 0.075);
//					[self setSelectedRange: affectedCharRange];
//				}
				
				break;
			}
		}
	}
	
	return YES;
}

@end
