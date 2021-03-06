#import "NSDictionary-Extension.h"
#import "TeX2img-Swift.h"

@implementation NSDictionary (Extension)
- (float)floatForKey:(NSString*)aKey
{
	return ((NSNumber*)self[aKey]).floatValue;
}

- (NSInteger)integerForKey:(NSString*)aKey
{
	return ((NSNumber*)self[aKey]).integerValue;
}

- (BOOL)boolForKey:(NSString*)aKey
{
	return ((NSNumber*)self[aKey]).boolValue;
}

- (NSString*)stringForKey:(NSString*)aKey
{
	return (NSString*)self[aKey];
}

- (NSArray*)arrayForKey:(NSString*)aKey
{
	return (NSArray*)self[aKey];
}

- (NSMutableArray*)mutableArrayForKey:(NSString*)aKey;
{
	return [NSMutableArray arrayWithArray:(NSArray*)self[aKey]];
}

- (NSDictionary*)dictionaryForKey:(NSString*)aKey
{
	return (NSDictionary*)self[aKey];
}

- (NSColor*)colorForKey:(NSString*)aKey
{
    return [[NSColor alloc] initWithSerializedString:[self stringForKey:aKey]];
}

@end
