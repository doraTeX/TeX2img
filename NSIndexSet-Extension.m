#import "NSIndexSet-Extension.h"

@implementation NSIndexSet (Extension)
-(unsigned int)countOfIndexesInRange:(NSRange)range
{
	unsigned int start, end, count;
	
	if ((start == 0) && (range.length == 0))
	{
		return 0;	
	}
	
	start	= range.location;
	end		= start + range.length;
	count	= 0;
	
	unsigned int currentIndex = [self indexGreaterThanOrEqualToIndex:start];
	
	while ((currentIndex != NSNotFound) && (currentIndex < end))
	{
		count++;
		currentIndex = [self indexGreaterThanIndex:currentIndex];
	}
	
	return count;
}
@end
