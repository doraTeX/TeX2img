#import <Cocoa/Cocoa.h>

@interface NSBitmapImageRep (Extension)
-(NSData*)representationUsingType:(CFStringRef)type usingDPI:(NSInteger)dpi;
@end
