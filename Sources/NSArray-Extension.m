#import "NSArray-Extension.h"

@implementation NSArray (Extension)
- (NSIndexSet*)indexesOfTrueValue
{
    return [self indexesOfObjectsPassingTest:^BOOL(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        return (obj.boolValue == YES);
    }];
}

- (NSArray*)mapUsingBlock:(id (^)(id))block
{
    NSMutableArray *array = [NSMutableArray array];
    [self enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
        [array addObject:block(item)];
    }];
    return array;
}
@end
