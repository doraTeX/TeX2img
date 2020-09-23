/*
 ==============================================================================
 MyGlyphPopoverController
 Created on 2015-08-10 by Yusuke Terada
 
 MyGlyphPopoverController is based on TSGlyphPopoverController.
 TSGlyphPopoverController is based on CEGlyphPopoverController.
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-05-01 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 CotEditor Project
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "MyGlyphPopoverController.h"
#import "NSString-Extension.h"
#import "NSString-Unicode.h"
#import "NSArray-Extension.h"
#import "UtilityG.h"

// variation Selectors
static const unichar  kTextSequenceChar = 0xFE0E;
static const unichar kEmojiSequenceChar = 0xFE0F;

// emoji modifiers
static const UTF32Char kType12EmojiModifierChar = 0x1F3FB; // Emoji Modifier Fitzpatrick type-1-2
static const UTF32Char kType3EmojiModifierChar = 0x1F3FC;  // Emoji Modifier Fitzpatrick type-3
static const UTF32Char kType4EmojiModifierChar = 0x1F3FD;  // Emoji Modifier Fitzpatrick type-4
static const UTF32Char kType5EmojiModifierChar = 0x1F3FE;  // Emoji Modifier Fitzpatrick type-5
static const UTF32Char kType6EmojiModifierChar = 0x1F3FF;  // Emoji Modifier Fitzpatrick type-6


//////////////////////////////////////////////////////////////////////////////
#pragma mark - subclass for private use
@interface MyGlyphPopoverUnicodesTextStorage : NSTextStorage
{
    NSMutableAttributedString *contents;
}
- (instancetype)init;
- (instancetype)initWithAttributedString:(NSAttributedString*)attrStr;
@end

@implementation MyGlyphPopoverUnicodesTextStorage
- (instancetype)initWithAttributedString:(NSAttributedString*)attrStr
{
    if ((self = [super init])) {
        contents = attrStr ? [attrStr mutableCopy] : [NSMutableAttributedString new];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        contents = [NSMutableAttributedString new];
    }
    return self;
}

- (NSString*)string
{
    return contents.string;
}

- (NSDictionary<NSString*,id>*)attributesAtIndex:(NSUInteger)location
                                  effectiveRange:(NSRange*)range
{
    return [contents attributesAtIndex:location effectiveRange:range];
}


// customize line-break
- (NSUInteger)lineBreakBeforeIndex:(NSUInteger)index withinRange:(NSRange)aRange
{
    NSUInteger breakIndex = [super lineBreakBeforeIndex:index withinRange:aRange];
    if ((breakIndex >= 2) && ([self.string characterAtIndex:breakIndex] == '+')){
        return breakIndex-2;
    } else {
        return breakIndex;
    }
}
@end
#pragma mark -


//////////////////////////////////////////////////////////////////////////////
@interface UnicodeInfo : NSObject
-(instancetype)initWithUnichar:(unichar)_unicodePoint;
-(instancetype)initWithHighSurrogate:(unichar)_highSurrogate lowSurrogate:(unichar)_lowSurrogate;
-(NSString*)stringExpression;
-(NSString*)stringExpressionWithSurrogatePairInfomation;
-(NSString*)stringExpressionWithUnicodeName;
@property UTF32Char unicodeChar;
@property NSString *unicodeString;
@property BOOL surrogate;
@property unichar highSurrogate;
@property unichar lowSurrogate;
@end

@implementation UnicodeInfo
-(instancetype)initWithUnichar:(unichar)unicodePoint
{
    self = [super init];
    _unicodeChar = unicodePoint;
    _unicodeString = [NSString stringWithUTF32Char:unicodePoint];
    _surrogate = NO;
    _highSurrogate = 0;
    _lowSurrogate = 0;
    
    return self;
}

-(instancetype)initWithHighSurrogate:(unichar)highSurrogate lowSurrogate:(unichar)lowSurrogate
{
    self = [super init];
    _surrogate = YES;
    _highSurrogate = highSurrogate;
    _lowSurrogate = lowSurrogate;
    _unicodeChar = CFStringGetLongCharacterForSurrogatePair(highSurrogate, lowSurrogate);
    _unicodeString = [NSString stringWithUTF32Char:_unicodeChar];

    return self;
}

-(NSString*)stringExpression
{
	return [NSString stringWithFormat:@"U+%04X", _unicodeChar];
}

-(NSString*)stringExpressionWithSurrogatePairInfomation
{
    if (_surrogate) {
        return [NSString stringWithFormat:@"U+%04X (U+%04X U+%04X)", _unicodeChar, _highSurrogate, _lowSurrogate];
    } else {
        return [NSString stringWithFormat:@"U+%04X", _unicodeChar];
    }
}

-(NSString*)stringExpressionWithUnicodeName
{
    return [NSString stringWithFormat:@"%@ %@", [self stringExpressionWithSurrogatePairInfomation], _unicodeString.unicodeName];
}

@end

//////////////////////////////////////////////////////////////////////////////

@interface MyGlyphPopoverController ()

@property (nonatomic, copy) NSString *glyph;
@property (nonatomic, copy) NSString *unicodeName;
@property (nonatomic, copy) NSString *unicodeBlockName;
@property (nonatomic, copy) NSString *unicode;
@property (nonatomic, strong) IBOutlet NSTextView *unicodesTextView;
@property (nonatomic, strong) IBOutlet NSTextField *unicodeBlockNameField;
@end


#pragma mark -

@implementation MyGlyphPopoverController
@synthesize unicodesTextView;

#pragma mark Public Methods

- (instancetype)initWithCharacter:(NSString*)character
{
    BOOL singleLetter;
    NSUInteger numberOfComposedCharacters = character.numberOfComposedCharacters;
    NSString *firstChar;
    NSString *firstCode;
    
    switch (numberOfComposedCharacters) {
        case 0:
            return nil;
            break;
        case 1:
            singleLetter = YES;
            self = [super initWithNibName:@"GlyphPopoverSingle" bundle:nil];
            break;
        default:
            singleLetter = NO;
            self = [super initWithNibName:@"GlyphPopoverMulti" bundle:nil];
            break;
    }
    
    if (self) {
        if (singleLetter) {
            self.glyph = character;
        }
        
        NSUInteger length = character.length;
        
        // unicode hex
        NSMutableArray<UnicodeInfo*> *unicodes = [NSMutableArray<UnicodeInfo*> array];

        for (NSUInteger i = 0; i < length; i++) {
            unichar theChar = [character characterAtIndex:i];
            unichar nextChar = (length > i+1) ? [character characterAtIndex:i+1] : 0;
            UnicodeInfo *unicodeInfo;
            if (CFStringIsSurrogateHighCharacter(theChar) && CFStringIsSurrogateLowCharacter(nextChar)) {
                unicodeInfo = [[UnicodeInfo alloc] initWithHighSurrogate:theChar lowSurrogate:nextChar];
                if (!firstChar) {
                    firstChar = [unicodeInfo unicodeString];
                }
                i++;
            } else {
                unicodeInfo = [[UnicodeInfo alloc] initWithUnichar:theChar];
                if (!firstChar) {
                    firstChar = [NSString stringWithUTF32Char:theChar];
                }
            }

            if (!firstCode) {
                firstCode = unicodeInfo.stringExpression;
            }

            [unicodes addObject:unicodeInfo];
        }
        
        BOOL multiCodePoints = (unicodes.count > 1);

        NSString *variationSelectorAdditional;
        if (unicodes.count == 2) {
            unichar lastChar = [character characterAtIndex:length-1];
            if (lastChar == kEmojiSequenceChar) {
                variationSelectorAdditional = @"Emoji Style";
                multiCodePoints = NO;
            } else if (lastChar == kTextSequenceChar) {
                variationSelectorAdditional = @"Text Style";
                multiCodePoints = NO;
            } else if (((lastChar >= 0x180B) && (lastChar <= 0x180D)) || ((lastChar >= 0xFE00) && (lastChar <= 0xFE0D))) {
                variationSelectorAdditional = @"Variant";
                multiCodePoints = NO;
            } else {
                unichar highSurrogate = [character characterAtIndex:length-2];
                unichar lowSurrogate = [character characterAtIndex:length-1];
                if (CFStringIsSurrogateHighCharacter(highSurrogate) && CFStringIsSurrogateLowCharacter(lowSurrogate)) {
                    UTF32Char pair = CFStringGetLongCharacterForSurrogatePair(highSurrogate, lowSurrogate);
                    
                    switch (pair) {
                        case kType12EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone I-II";  // Light Skin Tone
                            multiCodePoints = NO;
                            break;
                        case kType3EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone III";  // Medium Light Skin Tone
                            multiCodePoints = NO;
                            break;
                        case kType4EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone IV";  // Medium Skin Tone
                            multiCodePoints = NO;
                            break;
                        case kType5EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone V";  // Medium Dark Skin Tone
                            multiCodePoints = NO;
                            break;
                        case kType6EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone VI";  // Dark Skin Tone
                            multiCodePoints = NO;
                            break;
                        default:
                            if ((pair >= 0xE0100) && (pair <= 0xE01EF)) {
                                variationSelectorAdditional = @"Variant";
                                multiCodePoints = NO;
                            }
                            break;
                    }
                }
            }
        }

        
        if (multiCodePoints) {
            if (singleLetter) {
                self.unicode = [(NSArray<NSString*>*)[unicodes mapUsingBlock:^NSString*(UnicodeInfo *unicodeInfo) {
                    return [unicodeInfo stringExpressionWithUnicodeName];
                }] componentsJoinedByString:@"\n"];
                self.unicodeName = [NSString stringWithFormat:localizedString(@"Base: %@ (%@ %@) <combining character sequence consisting of %lu characters>"),
                                    firstChar, firstCode, firstChar.unicodeName, unicodes.count];
                self.unicodeBlockName = firstChar.localizedBlockName;
            } else {
                self.unicode = [(NSArray<NSString*>*)[unicodes mapUsingBlock:^NSString*(UnicodeInfo *unicodeInfo) {
                    return [unicodeInfo stringExpressionWithSurrogatePairInfomation];
                }] componentsJoinedByString:@"  "];

                // display the number of letters, words, lines
                NSInteger numberOfWords = [NSSpellChecker.sharedSpellChecker countWordsInString:character language:nil];
                if (numberOfWords == -1) {
                    numberOfWords = [NSSpellChecker.sharedSpellChecker countWordsInString:character language:@"English"];
                }
                NSUInteger numberOfLines = [character componentsSeparatedByString:@"\n"].count;
                
                self.unicodeName = [NSString stringWithFormat:localizedString(@"%lu letters, %lu words, %lu lines"), numberOfComposedCharacters, numberOfWords, numberOfLines];

                // display Unicode points
                NSRect originalFrame = super.view.frame;
                CGFloat oldHeight = originalFrame.size.height;

                // replace text storage of UnicodesTextView (for customizing line-break)
                unicodesTextView.horizontallyResizable = YES;
                unicodesTextView.verticallyResizable = YES;
                NSAttributedString *aStr = [unicodesTextView.textStorage attributedSubstringFromRange:NSMakeRange(0, unicodesTextView.textStorage.length)];
                MyGlyphPopoverUnicodesTextStorage *newStorage = [[MyGlyphPopoverUnicodesTextStorage alloc] initWithAttributedString:aStr];
                [unicodesTextView.layoutManager replaceTextStorage:newStorage];
                
                // extend popover height (if necessary)
                [unicodesTextView sizeToFit];
                NSRect rect = [unicodesTextView.layoutManager usedRectForTextContainer:unicodesTextView.textContainer];
                CGFloat newHeight = rect.size.height + 50;
                
                newHeight = (newHeight < oldHeight) ? oldHeight : MIN(newHeight, 300); // maximal height of popover
                
                // resize
                super.view.frame = NSMakeRect(originalFrame.origin.x, originalFrame.origin.y, originalFrame.size.width, newHeight);
            }
        } else {
            // unicode character name
            unichar theChar = [character characterAtIndex:0];
            
            if ((self.unicodeName = [NSString controlCharacterNameWithCharacter:theChar])) {
                self.glyph = @"";
            } else {
                self.unicodeName = character.unicodeName;
            }
            
            if (variationSelectorAdditional) {
                self.unicodeName = [NSString stringWithFormat:@"%@ (%@)", self.unicodeName, localizedString(variationSelectorAdditional)];
            }
            
            if (unicodes.count > 1) {
                self.unicode = [(NSArray<NSString*>*)[unicodes mapUsingBlock:^NSString*(UnicodeInfo *unicodeInfo) {
                    return [unicodeInfo stringExpressionWithUnicodeName];
                }] componentsJoinedByString:@"\n"];
            } else {
                self.unicode = [unicodes[0] stringExpressionWithSurrogatePairInfomation];
            }
            self.unicodeBlockName = character.localizedBlockName;
        }
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    if (!self.unicodeBlockName) {
        [self.unicodeBlockNameField removeFromSuperviewWithoutNeedingDisplay];
    }
}

- (void)showPopoverRelativeToRect:(NSRect)positioningRect ofView:(NSView*)parentView
{
    NSPopover *popover = [NSPopover new];
    popover.contentViewController = self;
    popover.behavior = NSPopoverBehaviorSemitransient;
    [popover showRelativeToRect:positioningRect ofView:parentView preferredEdge:NSMinYEdge];
    [parentView.window makeFirstResponder:parentView];
}

@end


