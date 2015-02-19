#import "NSDate-Extension.h"

@implementation NSDate (Extension)

- (BOOL)isNewerThan:(NSDate*)date
{
    NSComparisonResult result = [self compare:date];

    switch (result) {
        case NSOrderedDescending:
            return YES;
            break;
        case NSOrderedSame:
            return YES;
            break;
        default:
            return NO;
            break;
    }
}

@end
