#import "NSArray-Extension.h"

@implementation NSArray (Extension)
- (NSIndexSet*)indexesOfTrueValue
{
    return [self indexesOfObjectsPassingTest:^BOOL(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        return (obj.boolValue == YES);
    }];
}
@end
