#import <Cocoa/Cocoa.h>

@interface NSMutableString (Extension)
- (NSMutableString*)replaceYenWithBackSlash;
- (NSMutableString*)replaceFirstOccuarnceOfString:(NSString*)target replacment:(NSString*)replacement;
@end
