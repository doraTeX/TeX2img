#import "NSString-Extension.h"

@implementation NSString (Extension)
- (NSString*)pathStringByAppendingPageNumber:(NSUInteger)page
{
    NSString* dir = self.stringByDeletingLastPathComponent;
    NSString* basename = self.lastPathComponent.stringByDeletingPathExtension;
    NSString* ext = self.pathExtension;
    return [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%lu.%@", basename, page, ext]];
}
@end
