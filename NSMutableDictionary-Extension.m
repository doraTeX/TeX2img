#import "NSMutableDictionary-Extension.h"

@implementation NSMutableDictionary (Extension)
-(void)setFloat:(float)value forKey:(NSString *)aKey
{
	[self setObject:[NSNumber numberWithFloat:value] forKey:aKey];
}

-(void)setInteger:(int)value forKey:(NSString *)aKey
{
	[self setObject:[NSNumber numberWithInt:value] forKey:aKey];
}

-(void)setBool:(bool)value forKey:(NSString *)aKey
{
	[self setObject:[NSNumber numberWithBool:value] forKey:aKey];
}

@end
