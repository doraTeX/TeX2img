#import "TeXTextView.h"
#import "NSDictionary-Extension.h"
#import "NSMutableString-Extension.h"
#import "MyLayoutManager.h"

static BOOL isValidTeXCommandChar(unichar c);

static BOOL isValidTeXCommandChar(unichar c)
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
- (void)awakeFromNib
{
	NSString* autoCompletionPath = @"~/Library/TeXShop/Keyboard/autocompletion.plist".stringByStandardizingPath;
	if ([NSFileManager.defaultManager fileExistsAtPath: autoCompletionPath]){
		autocompletionDictionary = [NSDictionary dictionaryWithContentsOfFile:autoCompletionPath];
	}else {
		autocompletionDictionary = nil;
	}
	lastCursorLocation = 0;
	lastStringLength = 0;
	autoCompleting = NO;
	contentHighlighting = NO;
	braceHighlighting = NO;
	MyLayoutManager *layoutManager = MyLayoutManager.new;
	layoutManager.controller = controller;
	[self.textContainer replaceLayoutManager:layoutManager];

    self.ContinuousSpellCheckingEnabled = NO;
    self.SmartInsertDeleteEnabled = NO;
    self.AutomaticDashSubstitutionEnabled = NO;
    self.AutomaticDataDetectionEnabled = NO;
    self.AutomaticLinkDetectionEnabled = NO;
    self.AutomaticQuoteSubstitutionEnabled = NO;
    self.AutomaticSpellingCorrectionEnabled = NO;
    self.AutomaticTextReplacementEnabled = NO;
}

- (void)registerUndoWithString:(NSString *)oldString location:(unsigned)oldLocation
                        length: (unsigned)newLength key:(NSString *)key
{
    NSUndoManager *myManager = self.undoManager;
    [myManager registerUndoWithTarget:self selector:@selector(undoSpecial:) object: @{
                                                                                      @"oldString": oldString,
                                                                                      @"oldLocation": @(oldLocation),
                                                                                      @"oldLength" : @(newLength),
                                                                                      @"undoKey" : key
                                                                                      }];
    [myManager setActionName:key];
}

- (void)undoSpecial:(id)theDictionary
{
	NSRange		undoRange;
	NSString	*oldString, *newString, *undoKey;
	unsigned	from, to;
	
	// Retrieve undo info
	undoRange.location = [theDictionary[@"oldLocation"] unsignedIntValue];
	undoRange.length = [theDictionary[@"oldLength"] unsignedIntValue];
	newString = theDictionary[@"oldString"];
	undoKey = theDictionary[@"undoKey"];
	
	if (undoRange.location + undoRange.length > self.string.length)
		return; // something wrong happened
	
	oldString = [self.string substringWithRange:undoRange];
	
	// Replace the text
	[self replaceCharactersInRange:undoRange withString:newString];
	[self registerUndoWithString:oldString location:undoRange.location
						  length:newString.length key:undoKey];
	
	from = undoRange.location;
	to = from + newString.length;
	[self colorizeText:[controller.currentProfile boolForKey:@"colorizeText"]];
}


// to be used in AutoCompletion
- (void)insertSpecialNonStandard:(NSString *)theString undoKey:(NSString *)key
{
	NSRange		oldRange, searchRange;
	NSMutableString	*stringBuf;
	NSString *oldString, *newString;
	unsigned from, to;
	
	// mutably copy the replacement text
	stringBuf = [NSMutableString stringWithString:theString];
	
	// Determine the curent selection range and text
	oldRange = self.selectedRange;
	oldString = [self.string substringWithRange:oldRange];
	
	// Substitute all occurances of #SEL# with the original text
	[stringBuf replaceOccurrencesOfString: @"#SEL#" withString: oldString
								  options: 0 range: NSMakeRange(0, stringBuf.length)];
	
	// Now search for #INS#, remember its position, and remove it. We will
	// Later position the insertion mark there. Defaults to end of string.
	searchRange = [stringBuf rangeOfString:@"#INS#" options:NSLiteralSearch];
	if (searchRange.location != NSNotFound)
		[stringBuf replaceCharactersInRange:searchRange withString:@""];
	
	// Filtering for Japanese
	//newString = [self filterBackslashes:stringBuf];
	newString = stringBuf;
	
	// Insert the new text
	[self replaceCharactersInRange:oldRange withString:newString];
	
	// register undo
	[self registerUndoWithString:oldString location:oldRange.location
						  length:newString.length key:key];
	//[textView registerUndoWithString:oldString location:oldRange.location
	//					length:[newString length] key:key];
	
	from = oldRange.location;
	to = from + newString.length;
	[self colorizeText:[controller.currentProfile boolForKey:@"colorizeText"]];
	
	// Place insertion mark
	if (searchRange.location != NSNotFound) {
		searchRange.location += oldRange.location;
		searchRange.length = 0;
		self.SelectedRange = searchRange;
	}
}

- (void)insertText:(id)aString
{
    if (![aString isKindOfClass:NSString.class]) {
        [super insertText:aString];
        return;
    }
    NSString* theString = (NSString*)aString;

	NSDictionary* currentProfile = controller.currentProfile;

	unichar texChar = 0x5c;
	
	if ([theString isEqualToString:@"¥"] && [currentProfile boolForKey:@"convertYenMark"]) {
		[super insertText:@"\\"];
	} else {
        if (theString.length == 1 && [currentProfile boolForKey:@"autoComplete"] && autocompletionDictionary) {
            if ([theString characterAtIndex:0] >= 128 ||
                self.selectedRange.location == 0 ||
                [self.string characterAtIndex:self.selectedRange.location - 1 ] != texChar ) {
                NSString *completionString = autocompletionDictionary[theString];
                if (completionString) {
                    autoCompleting = YES;
                    [self insertSpecialNonStandard:completionString
                                           undoKey:@"Autocompletion"];
                    autoCompleting = NO;
                    return;
                }
            }
        }	
        
		[super insertText:aString];
	}
	[self colorizeText:[currentProfile boolForKey:@"colorizeText"]];
}


// クリップボードから貼り付けられる円マークをバックスラッシュに置き換えて貼り付ける
- (BOOL)readSelectionFromPasteboard:(NSPasteboard*)pboard type:(NSString*)type
{
	NSDictionary* currentProfile = controller.currentProfile;

	if ([type isEqualToString:NSStringPboardType] && [currentProfile boolForKey:@"convertYenMark"]) {
		NSMutableString *string = [NSMutableString stringWithString:[pboard stringForType:NSStringPboardType]];
		if (string)	{
			[string replaceYenWithBackSlash];
			
			// Replace the text--imitate what happens in ordinary editing
			NSRange	selectedRange = self.selectedRange;
			if ([self shouldChangeTextInRange:selectedRange replacementString:string]) {
				[self replaceCharactersInRange:selectedRange withString:string];
				[self didChangeText];
			}
			// by returning YES, "Undo Paste" menu item will be set up by system
			[self colorizeText:[currentProfile boolForKey:@"colorizeText"]];
			return YES;
		} else {
			return NO;
		}
	}
	return [super readSelectionFromPasteboard:pboard type:type];
}
@end
