#import "NSString-Normalization.h"

@implementation NSString (Normalization)
- (NSString*)normalizedStringWithModifiedNFD
{
    CFStringRef sourceStr = (__bridge CFStringRef)self;
    CFIndex length = CFStringGetMaximumSizeOfFileSystemRepresentation(sourceStr);
    char *destStr = (char*)malloc(length);
    Boolean success = CFStringGetFileSystemRepresentation(sourceStr, destStr, length);
    NSString *result = success ? [NSString stringWithUTF8String:destStr] : self;
    free(destStr);
    return result;
}
@end
