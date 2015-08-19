#import "NSPipe-Extension.h"

@implementation NSPipe (Extension)
- (NSString*)stringValue
{
    return [NSString.alloc initWithData:self.fileHandleForReading.readDataToEndOfFile
                               encoding:NSUTF8StringEncoding];
}
@end
