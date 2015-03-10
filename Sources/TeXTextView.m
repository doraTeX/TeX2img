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
	if ([NSFileManager.defaultManager fileExistsAtPath: autoCompletionPath]) {
		autocompletionDictionary = [NSDictionary dictionaryWithContentsOfFile:autoCompletionPath];
	} else {
		autocompletionDictionary = nil;
	}
	lastCursorLocation = 0;
	lastStringLength = 0;
	autoCompleting = NO;
	contentHighlighting = NO;
	braceHighlighting = NO;
	MyLayoutManager *layoutManager = MyLayoutManager.new;
	layoutManager.controller = controller;
    self.dropDelegate = controller;
    dragging = NO;
    currentDragOperation = NSDragOperationNone;
    
	[self.textContainer replaceLayoutManager:layoutManager];

    self.continuousSpellCheckingEnabled = NO;
    self.smartInsertDeleteEnabled = NO;
    self.automaticDashSubstitutionEnabled = NO;
    self.automaticDataDetectionEnabled = NO;
    self.automaticLinkDetectionEnabled = NO;
    self.automaticQuoteSubstitutionEnabled = NO;
    self.automaticSpellingCorrectionEnabled = NO;
    self.automaticTextReplacementEnabled = NO;
    
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (void)registerUndoWithString:(NSString*)oldString location:(unsigned)oldLocation
                        length: (unsigned)newLength key:(NSString*)key
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
	[self colorizeText:[controller.currentProfile boolForKey:ColorizeTextKey]];
}


// to be used in AutoCompletion
- (void)insertSpecialNonStandard:(NSString*)theString undoKey:(NSString*)key
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
	newString = stringBuf;
	
	// Insert the new text
	[self replaceCharactersInRange:oldRange withString:newString];
	
	// register undo
	[self registerUndoWithString:oldString location:oldRange.location
						  length:newString.length key:key];
	
	from = oldRange.location;
	to = from + newString.length;
	[self colorizeText:[controller.currentProfile boolForKey:ColorizeTextKey]];
	
	// Place insertion mark
	if (searchRange.location != NSNotFound) {
		searchRange.location += oldRange.location;
		searchRange.length = 0;
		self.selectedRange = searchRange;
	}
}

- (void)insertText:(id)aString
{
    if (![aString isKindOfClass:NSString.class]) {
        [super insertText:aString];
        return;
    }
    NSString *theString = (NSString*)aString;

	NSDictionary *currentProfile = controller.currentProfile;

	unichar texChar = 0x5c;
	
	if ([theString isEqualToString:@"¥"] && [currentProfile boolForKey:ConvertYenMarkKey]) {
		[super insertText:@"\\"];
	} else {
        if (theString.length == 1 && [currentProfile boolForKey:AutoCompleteKey] && autocompletionDictionary) {
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
	[self colorizeText:[currentProfile boolForKey:ColorizeTextKey]];
}

- (void)insertTextWithIndicator:(id)aString {
    [self insertText:aString];

    if (![aString isKindOfClass:NSString.class]) {
        return;
    }
    
    NSUInteger length = ((NSString*)aString).length;
    [self showFindIndicatorForRange:NSMakeRange(self.selectedRange.location - length, length)];

}


// クリップボードから貼り付けられる円マークをバックスラッシュに置き換えて貼り付ける
- (BOOL)readSelectionFromPasteboard:(NSPasteboard*)pboard type:(NSString*)type
{
	NSDictionary *currentProfile = controller.currentProfile;

	if ([type isEqualToString:NSStringPboardType] && [currentProfile boolForKey:ConvertYenMarkKey]) {
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
			[self colorizeText:[currentProfile boolForKey:ColorizeTextKey]];
			return YES;
		} else {
			return NO;
		}
	}
	return [super readSelectionFromPasteboard:pboard type:type];
}

- (void)setEnabled:(BOOL)enabled
{
    self.selectable = enabled;
    self.editable = enabled;
    
    if (enabled) {
        self.textColor = NSColor.controlTextColor;
    } else {
        self.textColor = NSColor.disabledControlTextColor;
    }
}

- (void)replaceEntireContentsWithString:(NSString*)contents colorize:(BOOL)colorize
{
    [self insertText:contents replacementRange:NSMakeRange(0, self.textStorage.mutableString.length)];
    [self colorizeText:colorize];
    [self setSelectedRange:NSMakeRange(0, 0)];
    [self scrollRangeToVisible: NSMakeRange(0, 0)];
}

#pragma mark - Drag & Drop

// ドラッグ中のフィールド枠の強調表示用にオーバーライド
- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    
    if (dragging) {
        // ドラッギング中はフレーム枠を強調表示
        [NSColor.selectedControlColor set];
        NSFrameRectWithWidth(rect, 2.0);
    }
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)info
{
    return YES;
}

- (NSArray*)filelistInDraggingInfo:(id<NSDraggingInfo>)info
{
    return [info.draggingPasteboard propertyListForType:NSFilenamesPboardType];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)info
{
    NSArray *draggedFiles = [self filelistInDraggingInfo:info];
    
    // sourceTextView へのドロップのみ可
    if (self != controller.sourceTextView) {
        return NSDragOperationNone;
    }
    
    // 複数のドラッグは受付不可
    if (draggedFiles.count > 1) {
        return NSDragOperationNone;
    }
    
    // ドラッグされたパスが受付可能であるかチェック
    NSString *draggedFilePath = (NSString*)(draggedFiles[0]);
    BOOL isDir;
    
    BOOL fileExists = [NSFileManager.defaultManager fileExistsAtPath:draggedFilePath isDirectory:&isDir];
    
    // 非存在ファイルやディレクトリのドラッグは受付不可
    if (!fileExists || isDir) {
        return NSDragOperationNone;
    }
    
    // 拡張子 .tex / .pdf / .eps / .jpg / .png / .svg 以外は受付不可
    NSString *ext = draggedFilePath.pathExtension;
    if (![ext isEqualToString:@"tex"] && ![ext isEqualToString:@"pdf"] && ![ext isEqualToString:@"eps"] && ![ext isEqualToString:@"jpg"] && ![ext isEqualToString:@"png"] && ![ext isEqualToString:@"svg"]) {
        return NSDragOperationNone;
    }

    [self setDraggingState:YES];
    
    return currentDragOperation;
}

- (void)draggingExited:(id <NSDraggingInfo>)info
{
    [self setDraggingState:NO];
    return;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)info
{
    return currentDragOperation;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)info
{
    [self.dropDelegate textViewDroppedFile:[self filelistInDraggingInfo:info][0]];
    return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)info
{
    [self setDraggingState:NO];
}

- (void)setDraggingState:(BOOL)draggingState
{
    if (draggingState) {
        dragging = YES;
        currentDragOperation = NSDragOperationCopy;
    } else {
        dragging = NO;
        currentDragOperation = NSDragOperationNone;
    }
    self.needsDisplay = YES;
}

@end
