#import "TeXTextView.h"
#import "NSDictionary-Extension.h"
#import "NSString-Extension.h"
#import "NSString-Normalization.h"
#import "NSMutableString-Extension.h"
#import "MyLayoutManager.h"
#import "MyGlyphPopoverController.h"
#import "UtilityG.h"

#define CommentOutTag 1
#define UncommentTag 2
#define ShiftRightTag 3
#define ShiftLeftTag 4

#define NFC_Tag 1
#define Modified_NFC_Tag 2
#define NFD_Tag 3
#define Modified_NFD_Tag 4
#define NFKC_Tag 5
#define NFKD_Tag 6
#define NFKC_CF_Tag 7

@implementation TeXTextView
- (void)awakeFromNib
{
    NSString* autoCompletionPath = @"~/Library/TeXShop/Keyboard/autocompletion.plist".stringByStandardizingPath;
    if ([NSFileManager.defaultManager fileExistsAtPath:autoCompletionPath]) {
        autocompletionDictionary = [NSDictionary dictionaryWithContentsOfFile:autoCompletionPath];
    } else {
        autocompletionDictionary = nil;
    }
    lastCursorLocation = 0;
    lastStringLength = 0;
    autoCompleting = NO;
    contentHighlighting = NO;
    braceHighlighting = NO;
    MyLayoutManager *layoutManager = [MyLayoutManager new];
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
    
    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    NSUndoManager *undoManager = self.undoManager;
    [defaultCenter addObserver:self
                      selector:@selector(colorizeAfterUndoAndRedo)
                          name:NSUndoManagerDidUndoChangeNotification
                        object:undoManager];
    [defaultCenter addObserver:self
                      selector:@selector(colorizeAfterUndoAndRedo)
                          name:NSUndoManagerDidRedoChangeNotification
                        object:undoManager];
    
    NSMenu* aMenu = self.menu;
    if ([aMenu indexOfItemWithTitle:localizedString(@"Character Info")] == -1) {
        [aMenu addItemWithTitle:localizedString(@"Character Info") action:@selector(showCharacterInfo:) keyEquivalent:@""];
    }
    
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    if ((menuItem.action == @selector(normalizeSelectedString:)) ||
        (menuItem.action == @selector(showCharacterInfo:))){
        return (self.selectedRange.length > 0);
    }
    
    return [super validateMenuItem:menuItem];
}

- (BOOL)isValidTeXCommandChar:(unichar)c
{
    if ((c >= 'A') && (c <= 'Z')) {
        return YES;
    } else if ((c >= 'a') && (c <= 'z')) {
        return YES;
    } else if (c == '@' && controller && [controller.currentProfile boolForKey:MakeatletterEnabledKey]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)changeFont:(id)sender
{
    [super changeFont:sender];
    [self fixupTabs];
}

- (void)fixupTabs
{
    NSDictionary *currentProfile = controller.currentProfile;
    
    NSMutableParagraphStyle* paragraphStyle = [self.defaultParagraphStyle mutableCopy];
    
    if (!paragraphStyle) {
        paragraphStyle = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
    }
    
    CGFloat charWidth = [self.font advancementForGlyph:(NSGlyph)' '].width;
    paragraphStyle.defaultTabInterval = charWidth * [currentProfile integerForKey:TabWidthKey];
    paragraphStyle.tabStops = @[];
    
    self.defaultParagraphStyle = paragraphStyle;
    
    NSMutableDictionary* typingAttributes = [self.typingAttributes mutableCopy];
    typingAttributes[NSParagraphStyleAttributeName] = paragraphStyle;
    typingAttributes[NSFontAttributeName] = self.font;
    self.typingAttributes = typingAttributes;
    
    NSRange rangeOfChange = NSMakeRange(0, self.string.length);
    [self shouldChangeTextInRange:rangeOfChange replacementString:nil];
    [self.textStorage setAttributes:typingAttributes range:rangeOfChange];
    [self didChangeText];
}

- (void)refreshWordWrap
{
    NSDictionary *currentProfile = controller.currentProfile;
    BOOL wrap = [currentProfile boolForKey:WrapLineKey];
    
    if (wrap) {
        self.enclosingScrollView.hasHorizontalScroller = NO;
        self.horizontallyResizable = NO;
        self.autoresizingMask = NSViewWidthSizable;
        self.textContainer.widthTracksTextView = YES;
        self.frameSize = self.enclosingScrollView.contentSize;
    } else {
        NSSize maximumSize = NSMakeSize(FLT_MAX, FLT_MAX);
        self.enclosingScrollView.contentView.autoresizesSubviews = YES;
        self.enclosingScrollView.hasHorizontalScroller = YES;
        self.textContainer.containerSize = maximumSize;
        self.textContainer.widthTracksTextView = NO;
        self.maxSize = maximumSize;
        self.horizontallyResizable = YES;
    }
}

- (void)colorizeAfterUndoAndRedo
{
    [self colorizeText];
}

- (void)registerUndoWithString:(NSString*)oldString
                      location:(unsigned)oldLocation
                        length:(unsigned)newLength
                           key:(NSString*)key
{
    NSUndoManager *myManager = self.undoManager;
    [myManager registerUndoWithTarget:self
                             selector:@selector(undoSpecial:)
                               object:@{
                                        @"oldString": oldString,
                                        @"oldLocation": @(oldLocation),
                                        @"oldLength": @(newLength),
                                        @"undoKey": key
                                        }];
    myManager.actionName = key;
}

- (void)undoSpecial:(id)theDictionary
{
    NSRange undoRange;
    NSString *oldString, *newString, *undoKey;
    
    undoRange.location = [theDictionary[@"oldLocation"] unsignedIntValue];
    undoRange.length = [theDictionary[@"oldLength"] unsignedIntValue];
    newString = theDictionary[@"oldString"];
    undoKey = theDictionary[@"undoKey"];
    
    if (undoRange.location + undoRange.length > self.string.length) {
        return;
    }
    
    oldString = [self.string substringWithRange:undoRange];
    
    [self replaceCharactersInRange:undoRange withString:newString];
    [self registerUndoWithString:oldString
                        location:undoRange.location
                          length:newString.length
                             key:undoKey];
    
    [self resetBackgroundColor:nil];
}

- (void)insertSpecialNonStandard:(NSString*)theString undoKey:(NSString*)key
{
    NSRange oldRange, searchRange;
    NSMutableString *stringBuf;
    NSString *oldString, *newString;
    unsigned from, to;
    
    stringBuf = [NSMutableString stringWithString:theString];
    
    oldRange = self.selectedRange;
    oldString = [self.string substringWithRange:oldRange];
    
    [stringBuf replaceOccurrencesOfString:@"#SEL#"
                               withString:oldString
                                  options:0
                                    range:NSMakeRange(0, stringBuf.length)];
    
    searchRange = [stringBuf rangeOfString:@"#INS#" options:NSLiteralSearch];
    if (searchRange.location != NSNotFound)
        [stringBuf replaceCharactersInRange:searchRange withString:@""];
    
    newString = stringBuf;

    [self replaceCharactersInRange:oldRange withString:newString];
    
    [self registerUndoWithString:oldString
                        location:oldRange.location
                          length:newString.length
                             key:key];
    
    from = oldRange.location;
    to = from + newString.length;
    [self colorizeText];
    
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
                [self.string characterAtIndex:self.selectedRange.location-1] != texChar ) {
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
    [self colorizeText];
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
        if (string) {
            [string replaceYenWithBackSlash];
            
            NSRange selectedRange = self.selectedRange;
            if ([self shouldChangeTextInRange:selectedRange replacementString:string]) {
                [self replaceCharactersInRange:selectedRange withString:string];
                [self didChangeText];
            }
            // by returning YES, "Undo Paste" menu item will be set up by system
            [self colorizeText];
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
        [self colorizeText];
    } else {
        self.textColor = NSColor.disabledControlTextColor;
    }
}

// コメントアウト・アンコメント・左右シフト
- (IBAction)doCommentOrIndent:(id)sender
{
    NSString *text, *oldString;
    NSRange modifyRange;
    NSUInteger blockStart, blockEnd, lineStart, lineContentsEnd, lineEnd;
    NSInteger theChar = 0, increment = 0, rangeIncrement;
    NSString *theCommand = nil;
    NSUInteger tabWidth, i;
    NSString *indentString;
    NSDictionary *aProfile = controller.currentProfile;
    BOOL useTabForIndent = [aProfile boolForKey:TabIndentKey];
    tabWidth = [aProfile integerForKey:TabWidthKey];
    
    text = self.string;
    NSRange oldRange = self.selectedRange;
    
    [text getLineStart:&blockStart end:&blockEnd contentsEnd:NULL forRange:self.selectedRange];
    
    modifyRange.location = blockStart;
    modifyRange.length = blockEnd - blockStart;
    oldString = [self.string substringWithRange:modifyRange];
    
    lineStart = blockStart;
    BOOL firstLine = YES;
    BOOL fixRangeStart = NO;
    
    do {
        modifyRange.location = lineStart;
        modifyRange.length = 0;
        [text getLineStart:NULL end:&lineEnd contentsEnd:&lineContentsEnd forRange:modifyRange];
        
        switch ([sender tag]) {
            case CommentOutTag:
                [self replaceCharactersInRange:modifyRange withString:@"%"];
                blockEnd++;
                lineEnd++;
                increment++;
                theCommand = localizedString(@"CommentOut");
                break;
                
            case UncommentTag:
                if (lineStart < lineContentsEnd) {
                    theChar = [text characterAtIndex:lineStart];
                } else if (firstLine) {
                    fixRangeStart = YES;
                    break;
                } else {
                    break;
                }
                if (theChar == '%') {
                    modifyRange.length = 1;
                    [self replaceCharactersInRange:modifyRange withString:@""];
                    blockEnd--;
                    lineEnd--;
                    increment--;
                    if (oldRange.location == blockStart && firstLine) {
                        fixRangeStart = YES;
                    }
                    theCommand = localizedString(@"Uncomment");
                } else if (firstLine) {
                    fixRangeStart = YES;
                }
                break;
                
            case ShiftRightTag:
                indentString = @"";
                if (tabWidth > 0) {
                    for (i = 1; i <= tabWidth; i++) {
                        indentString = [indentString stringByAppendingString:@" "];
                    }
                }
                if (useTabForIndent) {
                    [self replaceCharactersInRange:modifyRange withString:@"\t"];
                    blockEnd++;
                    lineEnd++;
                    increment++;
                } else {
                    [self replaceCharactersInRange:modifyRange withString:indentString];
                    blockEnd = blockEnd + tabWidth;
                    lineEnd = lineEnd + tabWidth;
                    increment = increment + tabWidth;
                }
                
                theCommand = localizedString(@"Indent");
                break;
                
            case ShiftLeftTag:
                if (lineStart < lineContentsEnd) {
                    theChar = [text characterAtIndex:lineStart];
                } else if (firstLine) {
                    fixRangeStart = YES;
                    break;
                } else {
                    break;
                }
                
                if (!useTabForIndent && theChar == ' ') {
                    modifyRange.location = lineStart;
                    modifyRange.length = 1;
                    [self replaceCharactersInRange:modifyRange withString:@""];
                    blockEnd--;
                    lineEnd--;
                    increment--;
                    i = 1;
                    theChar = [text characterAtIndex:lineStart+1];
                    while (((lineStart + i) < lineContentsEnd) && (i < tabWidth) && (theChar == ' ')) {
                        modifyRange.location = lineStart;
                        modifyRange.length = 1;
                        [self replaceCharactersInRange:modifyRange withString:@""];
                        blockEnd--;
                        lineEnd--;
                        increment--;
                        i++;
                    }
                    if (oldRange.location == blockStart && firstLine) {
                        fixRangeStart = YES;
                    }
                    theCommand = localizedString(@"Unindent");
                } else if (useTabForIndent && theChar == '\t') {
                    modifyRange.length = 1;
                    [self replaceCharactersInRange:modifyRange withString:@""];
                    blockEnd--;
                    lineEnd--;
                    increment--;
                    
                    if (oldRange.location == blockStart && firstLine) {
                        fixRangeStart = YES;
                    }
                    theCommand = localizedString(@"Unindent");
                } else if (firstLine) {
                    fixRangeStart = YES;
                }
                break;
        }
        lineStart = lineEnd;
        firstLine = NO;
    } while (lineStart < blockEnd);
    
    if (!theCommand) {
        return; // If no change was made, do nothing.
    }
    
    modifyRange.location = blockStart;
    modifyRange.length = blockEnd - blockStart;
    self.selectedRange = modifyRange;
    
    [self registerUndoWithString:oldString
                        location:modifyRange.location
                          length:modifyRange.length
                             key:theCommand];
    
    rangeIncrement = increment + ((increment > 0) ? (-1) : 1);
    if (fixRangeStart) {
        rangeIncrement--;
    } else {
        oldRange.location += (increment > 0) ? 1 : -1;
    }
    if (!(oldRange.length == 0 && rangeIncrement < 0)) {
        oldRange.length += rangeIncrement;
    }
    
    self.selectedRange = oldRange;
    
    text = self.string;
    [text getLineStart:&blockStart end:&blockEnd contentsEnd:NULL forRange:self.selectedRange];
    modifyRange.location = blockStart;
    modifyRange.length = blockEnd - blockStart;
    self.selectedRange = modifyRange;
    
    [self colorizeText];
}


- (void)replaceEntireContentsWithString:(NSString*)contents
{
    [self insertText:contents replacementRange:NSMakeRange(0, self.textStorage.mutableString.length)];
    [self colorizeText];
    self.selectedRange = NSMakeRange(0, 0);
    [self scrollRangeToVisible: NSMakeRange(0, 0)];
}

- (IBAction)closeCurrentEnvironment:(id)sender
{
    autoCompleting = YES;
    
    NSRange oldRange = self.selectedRange;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\\\(begin|end)\\{(.*?)\\}"
                                                                           options:0
                                                                             error:nil];
    NSString *target = [self.textStorage.string substringToIndex:oldRange.location];
    NSEnumerator* enumerator = [regex matchesInString:target options:0 range:NSMakeRange(0, target.length)].reverseObjectEnumerator;
    
    NSRange range1, range2;
    NSString *newString, *environment, *prefix;
    NSInteger increment, count_value;
    NSNumber *count;
    NSMutableDictionary *environmentStack = [NSMutableDictionary dictionary];
    NSTextCheckingResult *match;
    
    while ((match = (NSTextCheckingResult*)[enumerator nextObject])) {
        range1 = [match rangeAtIndex:1];
        range2 = [match rangeAtIndex:2];
        
        prefix = (range1.location == NSNotFound) ? nil : [target substringWithRange:range1];
        environment = (range2.location == NSNotFound) ? nil : [target substringWithRange:range2];
        
        increment = [prefix isEqualToString:@"end"] ? 1 : -1;
        
        count = environmentStack[environment];
        if (count) {
            count_value = count.integerValue;
            if (increment == 1) {
                environmentStack[environment] = @(count_value+1);
            } else if (count_value > 0) {
                environmentStack[environment] = @(count_value-1);
            } else {
                newString = environment;
                break;
            }
        } else {
            if (increment == 1) {
                environmentStack[environment] = @(1);
            } else {
                newString = environment;
                break;
            }
        }
    }
    
    if (newString) {
        newString = [NSString stringWithFormat:@"\\end{%@}", newString];
        
        if ([self shouldChangeTextInRange:oldRange replacementString:newString]) {
            [self replaceCharactersInRange:oldRange withString:newString];
            [self didChangeText];
            self.undoManager.actionName = localizedString(@"Close Current Environment");
        }
    } else {
        NSBeep();
    }
    
    autoCompleting = NO;
}

- (IBAction)showCharacterInfo:(id)sender
{
    NSRange selectedRange = self.selectedRange;
    
    if (selectedRange.length <= 0) {
        NSBeep();
        return;
    }
    
    NSString *selectedString = [self.string substringWithRange:selectedRange];
    MyGlyphPopoverController *popoverController = [[MyGlyphPopoverController alloc] initWithCharacter:selectedString];
    
    if (!popoverController) {
        return;
    }
    
    NSRange glyphRange = [self.layoutManager glyphRangeForCharacterRange:selectedRange actualCharacterRange:NULL];
    NSRect selectedRect = [self.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.textContainer];
    NSPoint containerOrigin = self.textContainerOrigin;
    selectedRect.origin.x += containerOrigin.x;
    selectedRect.origin.y += containerOrigin.y - 6.0;
    selectedRect = [self convertRectToLayer:selectedRect];
    
    [popoverController showPopoverRelativeToRect:selectedRect ofView:self];
    [self showFindIndicatorForRange:selectedRange];
}

- (IBAction)normalizeSelectedString:(id)sender
{
    NSRange selectedRange = self.selectedRange;
    
    if (selectedRange.length <= 0) {
        NSBeep();
        return;
    }
    
    NSString *selectedString = [self.string substringWithRange:selectedRange];
    
    NSString *newString;
    NSString *undoKey;
    
    switch ([sender tag]) {
        case NFC_Tag:
            newString = selectedString.precomposedStringWithCanonicalMapping;
            undoKey = @"NFC";
            break;
        case Modified_NFC_Tag:
            newString = selectedString.normalizedStringWithModifiedNFC;
            undoKey = @"Modified NFC";
            break;
        case NFD_Tag:
            newString = selectedString.decomposedStringWithCanonicalMapping;
            undoKey = @"NFD";
            break;
        case Modified_NFD_Tag:
            newString = selectedString.normalizedStringWithModifiedNFD;
            undoKey = @"Modified NFD";
            break;
        case NFKC_Tag:
            newString = selectedString.precomposedStringWithCompatibilityMapping;
            undoKey = @"NFKC";
            break;
        case NFKD_Tag:
            newString = selectedString.decomposedStringWithCompatibilityMapping;
            undoKey = @"NFKD";
            break;
        case NFKC_CF_Tag:
            newString = selectedString.normalizedStringWithNFKC_CF;
            undoKey = @"NFKC Casefold";
            break;
        default:
            newString = selectedString;
            break;
    }
    
    if (undoKey) {
        [self replaceCharactersInRange:selectedRange withString:newString];
        [self registerUndoWithString:selectedString
                            location:selectedRange.location
                              length:newString.length
                                 key:undoKey];
        self.undoManager.actionName = undoKey;
        self.selectedRange = NSMakeRange(selectedRange.location, newString.length);
        [self showCharacterInfo:nil];
    } else {
        NSBeep();
    }
}

#pragma mark - ダブルクリック時の挙動
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
{
    NSRange replacementRange = NSMakeRange(0, 0);
    NSString *textString;
    NSInteger length, i, j, leftpar, rightpar, nestingLevel, uchar;
    BOOL done;
    unichar BACKSLASH = 0x5c;
    BOOL makeatletterEnabled = controller ? [controller.currentProfile boolForKey:MakeatletterEnabledKey] : YES;
    
    textString = self.string;
    if (textString == nil) {
        return replacementRange;
    }
    
    replacementRange = [super selectionRangeForProposedRange: proposedSelRange granularity: granularity];
    
    // Extend word selection to cover an initial backslash (TeX command)
    if (granularity == NSSelectByWord) {
        BOOL flag;
        unichar c;
        
        if (replacementRange.location < textString.length) {
            c = [textString characterAtIndex:replacementRange.location];
            if ((c != '{') && (c != '(') && (c != '[') && (c != '<') && (c != ' ')) {
                do {
                    if (replacementRange.location >= 1) {
                        c = [textString characterAtIndex: replacementRange.location - 1];
                        if (((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z')) || ((c == '@') && makeatletterEnabled)) {
                            replacementRange.location--;
                            replacementRange.length++;
                            flag = YES;
                        } else {
                            flag = NO;
                        }
                    } else {
                        flag = NO;
                    }
                } while (flag);
                
                do {
                    if (replacementRange.location + replacementRange.length  < textString.length) {
                        c = [textString characterAtIndex: replacementRange.location + replacementRange.length];
                        if (((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z')) || ((c == '@') && makeatletterEnabled)) {
                            replacementRange.length++;
                            flag = YES;
                        } else {
                            flag = NO;
                        }
                    } else {
                        flag = NO;
                    }
                } while (flag);
            }
        }
        
        if (replacementRange.location >= 1 && [textString characterAtIndex: replacementRange.location - 1] == BACKSLASH) {
            replacementRange.location--;
            replacementRange.length++;
            return replacementRange;
        }
    }
    
    if ((proposedSelRange.length != 0) || (granularity != NSSelectByWord)) {
        return replacementRange;
    }
    
    length = textString.length;
    i = proposedSelRange.location;
    if (i >= length) {
        return replacementRange;
    }
    uchar = [textString characterAtIndex:i];
    
    if ((uchar == '}') || (uchar == ')') || (uchar == ']') || (uchar == '>')) {
        j = i;
        rightpar = uchar;
        if (rightpar == '}') {
            leftpar = '{';
        } else if (rightpar == ')') {
            leftpar = '(';
        } else if (rightpar == '>') {
            leftpar = '<';
        } else {
            leftpar = '[';
        }
        nestingLevel = 1;
        done = NO;
        // Try searching to the left to find a match...
        while ((i > 0) && !done) {
            i--;
            uchar = [textString characterAtIndex:i];
            if (uchar == rightpar) {
                nestingLevel++;
            } else if (uchar == leftpar) {
                nestingLevel--;
            }
            if (nestingLevel == 0) {
                done = YES;
                replacementRange.location = i;
                replacementRange.length = j - i + 1;
            }
        }
    } else if ((uchar == '{') || (uchar == '(') || (uchar == '[') ||  (uchar == '<') ) {
        j = i;
        leftpar = uchar;
        if (leftpar == '{') {
            rightpar = '}';
        } else if (leftpar == '(') {
            rightpar = ')';
        } else if (leftpar == '<') {
            rightpar = '>';
        } else {
            rightpar = ']';
        }
        nestingLevel = 1;
        done = NO;
        while ((i < length-1) && !done) {
            i++;
            uchar = [textString characterAtIndex:i];
            if (uchar == leftpar) {
                nestingLevel++;
            } else if (uchar == rightpar) {
                nestingLevel--;
            }
            if (nestingLevel == 0) {
                done = YES;
                replacementRange.location = j;
                replacementRange.length = i - j + 1;
            }
        }
    }
    
    return replacementRange;
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
    
    // 指定拡張子以外は受付不可
    NSString *ext = draggedFilePath.pathExtension;
    if (![ImportExtensionsArray containsObject:ext]) {
        return NSDragOperationNone;
    }
    
    self.draggingState = YES;
    
    return currentDragOperation;
}

- (void)draggingExited:(id <NSDraggingInfo>)info
{
    self.draggingState = NO;
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
    self.draggingState = NO;
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
