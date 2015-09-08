#import "PDFPageBox.h"
#import "PDFDocument-Extension.h"

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

+ (instancetype)pageBoxWithFilePath:(NSString*)path page:(NSUInteger)page
{
    return [[PDFDocument documentWithFilePath:path] pageAtIndex:page-1].pageBox;
}


- (NSString*)bboxStringOfBox:(CGPDFBox)boxType hires:(BOOL)hires clipWithMediaBox:(BOOL)clip addHeader:(BOOL)addHeader
{
    CGPDFPageRef pageRef = pdfPage.pageRef;
    CGRect mediaBoxRect = CGPDFPageGetBoxRect(pageRef, kCGPDFMediaBox);
    CGRect rect = CGPDFPageGetBoxRect(pageRef, boxType);
    rect = clip ? CGRectIntersection(rect, mediaBoxRect) : rect;
   
    NSString *result;
    
    if (hires) {
       result = [NSString stringWithFormat:@"%@%f %f %f %f\n",
                 (addHeader ? @"%%HiResBoundingBox: " : @""),
                 rect.origin.x,
                 rect.origin.y,
                 rect.origin.x + rect.size.width,
                 rect.origin.y + rect.size.height
                 ];
    } else {
        result = [NSString stringWithFormat:@"%@%ld %ld %ld %ld\n",
                  (addHeader ? @"%%BoundingBox: " : @""),
                  (NSInteger)floor(rect.origin.x),
                  (NSInteger)floor(rect.origin.y),
                  (NSInteger)floor(rect.origin.x) + (NSInteger)ceil(rect.size.width),
                  (NSInteger)floor(rect.origin.y) + (NSInteger)ceil(rect.size.height)
                  ];
    }
    
    return result;
}
@end
