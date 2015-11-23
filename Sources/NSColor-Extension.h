#import <Foundation/Foundation.h>

@interface NSColor (Extension)
- (NSString*)serializedString;
- (NSString*)descriptionString;
+ (NSColor*)colorWithSerializedString:(NSString*)string;
+ (NSColor*)braceColor;
+ (NSColor*)commentColor;
+ (NSColor*)commandColor;
+ (NSColor*)invisibleColor;
+ (NSColor*)highlightedBraceColor;
+ (NSColor*)enclosedContentBackgroundColor;
+ (NSColor*)flashingBackgroundColor;
+ (NSColor*)colorWithCSSName:(NSString*)name;
@end
