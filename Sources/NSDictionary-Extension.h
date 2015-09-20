#import <Cocoa/Cocoa.h>

@interface NSDictionary (Extension)
- (float)floatForKey:(NSString*)aKey;
- (NSInteger)integerForKey:(NSString*)aKey;
- (BOOL)boolForKey:(NSString*)aKey;
- (NSString*)stringForKey:(NSString*)aKey;
- (NSMutableArray*)mutableArrayForKey:(NSString*)aKey;
- (NSArray*)arrayForKey:(NSString*)aKey;
- (NSDictionary*)dictionaryForKey:(NSString*)aKey;
- (NSColor*)colorForKey:(NSString*)aKey;
@end
