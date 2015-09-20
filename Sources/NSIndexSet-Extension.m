#import "NSIndexSet-Extension.h"

@implementation NSIndexSet (Extension)
- (NSArray<NSNumber*>*)arrayOfIndexesPlusOne
{
    NSMutableArray<NSNumber*> *array = [NSMutableArray<NSNumber*> array];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [array addObject:@(idx+1)];
    }];
    return array;
}
@end
