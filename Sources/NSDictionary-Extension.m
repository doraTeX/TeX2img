#import "NSDictionary-Extension.h"

@implementation NSDictionary (Extension)
- (float)floatForKey:(NSString*)aKey
{
	return ((NSNumber*)self[aKey]).floatValue;
}

- (int)integerForKey:(NSString*)aKey
{
	return ((NSNumber*)self[aKey]).intValue;
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
    return [NSColor colorWithSerializedString:[self stringForKey:aKey]];
}

@end
