#import "PDFDocument-Extension.h"

@implementation PDFDocument (Extension)
+ (instancetype)documentWithFilePath:(NSString*)path
{
    return [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:path]];
}

@end
