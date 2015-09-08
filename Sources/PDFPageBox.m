#import "PDFPageBox.h"

@interface PDFPageBox ()
{
    PDFPage *pdfPage;
}
@end

@implementation PDFPageBox
- (instancetype)initWithPage:(PDFPage*)page
{
    if (!(self = [super init])) {
        return nil;
    } else {
        pdfPage = page;
    }
    return self;
}

+ (instancetype)pageBoxWithPage:(PDFPage*)page
{
    return [[PDFPageBox alloc] initWithPage:page];
}

- (NSString*)bboxStringOfBox:(CGPDFBox)boxType hires:(BOOL)hires clipWithMediaBox:(BOOL)clip
{
    CGPDFPageRef pageRef = pdfPage.pageRef;
    CGRect mediaBoxRect = CGPDFPageGetBoxRect(pageRef, kCGPDFMediaBox);
    CGRect rect = CGPDFPageGetBoxRect(pageRef, boxType);
    rect = clip ? CGRectIntersection(rect, mediaBoxRect) : rect;
    
    return hires ? [NSString stringWithFormat:@"%f %f %f %f",
                    rect.origin.x,
                    rect.origin.y,
                    rect.origin.x + rect.size.width,
                    rect.origin.y + rect.size.height] :
    [NSString stringWithFormat:@"%ld %ld %ld %ld",
     (NSInteger)floor(rect.origin.x),
     (NSInteger)floor(rect.origin.y),
     (NSInteger)floor(rect.origin.x) + (NSInteger)ceil(rect.size.width),
     (NSInteger)floor(rect.origin.y) + (NSInteger)ceil(rect.size.height)];
}
@end
