#import <Cocoa/Cocoa.h>

@interface NSDictionary (Extension)
-(float)floatForKey:(NSString *)aKey;
-(int)integerForKey:(NSString *)aKey;
-(bool)boolForKey:(NSString *)aKey;
-(NSString*)stringForKey:(NSString *)aKey;
-(NSMutableArray*)mutableArrayForKey:(NSString *)aKey;
-(NSArray*)arrayForKey:(NSString *)aKey;
-(NSDictionary*)dictionaryForKey:(NSString *)aKey;
@end
