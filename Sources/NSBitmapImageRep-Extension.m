#import "NSBitmapImageRep-Extension.h"

@implementation NSBitmapImageRep (Extension)
-(NSData*)representationUsingType:(CFStringRef)type usingDPI:(NSInteger)dpi
{
    NSDictionary<NSString*, id> *prop = @{(__bridge_transfer NSString*)kCGImageDestinationLossyCompressionQuality : @(1.0),
                                          (__bridge_transfer NSString*)kCGImagePropertyDPIWidth : @(dpi),
                                          (__bridge_transfer NSString*)kCGImagePropertyDPIHeight : @(dpi)
                                          };

    NSMutableData *outputData = [NSMutableData data];
    CGImageDestinationRef destination =  CGImageDestinationCreateWithData((CFMutableDataRef)outputData, type, 1, NULL);
    CGImageDestinationAddImage(destination, self.CGImage, (CFDictionaryRef)prop);
    CGImageDestinationFinalize(destination);
    
    CFRelease(destination);
    
    return outputData;
}
@end
