#import "PDFPage-Extension.h"

@implementation PDFPage (Extension)
- (PDFPageBox*)pageBox
{
    return [PDFPageBox pageBoxWithPDFPage:self];
}
@end
