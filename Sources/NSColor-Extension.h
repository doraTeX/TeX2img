#import <Foundation/Foundation.h>

@interface NSColor (Extension)
- (NSString*)serializedString;
+ (NSColor*)colorWithSerializedString:(NSString*)string;
+ (NSColor*)braceColor;
+ (NSColor*)commentColor;
+ (NSColor*)commandColor;
+ (NSColor*)invisibleColor;
+ (NSColor*)highlightedBraceColor;
+ (NSColor*)enclosedContentBackgroundColor;
+ (NSColor*)flashingBackgroundColor;
@end
