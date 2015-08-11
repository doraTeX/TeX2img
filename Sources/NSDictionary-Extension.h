#import <Cocoa/Cocoa.h>
#import "NSColor-Extension.h"

@interface NSDictionary (Extension)
- (float)floatForKey:(NSString*)aKey;
- (int)integerForKey:(NSString*)aKey;
- (BOOL)boolForKey:(NSString*)aKey;
- (NSString*)stringForKey:(NSString*)aKey;
- (NSMutableArray*)mutableArrayForKey:(NSString*)aKey;
- (NSArray*)arrayForKey:(NSString*)aKey;
- (NSDictionary*)dictionaryForKey:(NSString*)aKey;
- (NSColor*)colorForKey:(NSString*)aKey;
@end
