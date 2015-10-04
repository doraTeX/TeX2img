#import "NSString-Normalization.h"

#define FACTOR 256

@implementation NSString (Normalization)
- (NSString*)normalizedStringWithModifiedNFD
{
    CFStringRef sourceStr = (__bridge CFStringRef)self;
    size_t length = strlen(self.UTF8String) * FACTOR;
    char *destStr = (char*)malloc(sizeof(char) * length);
    Boolean success = CFStringGetFileSystemRepresentation(sourceStr, destStr, length);
    NSString *result = success ? [NSString stringWithUTF8String:destStr] : self;
    free(destStr);
    return result;
}
@end
