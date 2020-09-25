#import <Foundation/Foundation.h>

@interface NSColor (Extension)
- (NSString*)serializedString;
- (NSString*)descriptionString;
+ (NSColor*)colorWithSerializedString:(NSString*)string;
+ (NSColor*)colorWithCSSName:(NSString*)name;
@end
