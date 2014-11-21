#import <Cocoa/Cocoa.h>


@interface NSMutableDictionary (Extension)
-(void)setFloat:(float)value forKey:(NSString *)aKey;
-(void)setInteger:(int)value forKey:(NSString *)aKey;
-(void)setBool:(BOOL)value forKey:(NSString *)aKey;
@end
