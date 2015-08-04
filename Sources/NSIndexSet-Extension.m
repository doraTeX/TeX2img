#import "NSIndexSet-Extension.h"

@implementation NSIndexSet (Extension)
- (NSArray*)arrayOfIndexesPlusOne
{
    NSMutableArray *array = NSMutableArray.array;
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [array addObject:@(idx+1)];
    }];
    return array;
}
@end
