#import "PDFPage-Extension.h"

@implementation PDFPage (Extension)
- (PDFPageBox*)pageBox
{
    return [PDFPageBox pageBoxWithPage:self];
}
@end
