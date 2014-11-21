#import "NSDictionary-Extension.h"

@implementation NSDictionary (Extension)
-(float)floatForKey:(NSString *)aKey
{
	return [((NSNumber*)[self objectForKey:aKey]) floatValue];
}

-(int)integerForKey:(NSString *)aKey
{
	return [((NSNumber*)[self objectForKey:aKey]) intValue];
}

-(bool)boolForKey:(NSString *)aKey
{
	return [((NSNumber*)[self objectForKey:aKey]) boolValue];
}

-(NSString*)stringForKey:(NSString *)aKey
{
	return (NSString*)[self objectForKey:aKey];
}

-(NSArray*)arrayForKey:(NSString *)aKey
{
	return (NSArray*)[self objectForKey:aKey];
}

-(NSMutableArray*)mutableArrayForKey:(NSString *)aKey;
{
	return [NSMutableArray arrayWithArray:(NSArray*)[self objectForKey:aKey]];
}


-(NSDictionary*)dictionaryForKey:(NSString *)aKey
{
	return (NSDictionary*)[self objectForKey:aKey];
}


@end
