#import "PDFPageBox.h"
#import "PDFDocument-Extension.h"

@interface PDFPageBox ()
{
    PDFPage *pdfPage;
}
@end

@implementation PDFPageBox
- (instancetype)initWithPDFPage:(PDFPage*)page
{
    if (!(self = [super init])) {
        return nil;
    } else {
        pdfPage = page;
    }
    return self;
}

+ (instancetype)pageBoxWithPDFPage:(PDFPage*)page
{
    return [[PDFPageBox alloc] initWithPDFPage:page];
}

+ (instancetype)pageBoxWithFilePath:(NSString*)path page:(NSUInteger)page
{
    PDFDocument *doc = [PDFDocument documentWithFilePath:path];
    if (!doc) {
        return nil;
    }
    return [doc pageAtIndex:page-1].pageBox;
}

- (NSRect)mediaBoxRect
{
    CGRect rect = CGPDFPageGetBoxRect(pdfPage.pageRef, kCGPDFMediaBox);
    return *(NSRect*)&rect;
}

- (NSRect)cropBoxRect
{
    CGRect rect = CGPDFPageGetBoxRect(pdfPage.pageRef, kCGPDFCropBox);
    return *(NSRect*)&rect;
}

- (NSRect)bleedBoxRect
{
    CGRect rect = CGPDFPageGetBoxRect(pdfPage.pageRef, kCGPDFBleedBox);
    return *(NSRect*)&rect;
}

- (NSRect)trimBoxRect
{
    CGRect rect = CGPDFPageGetBoxRect(pdfPage.pageRef, kCGPDFTrimBox);
    return *(NSRect*)&rect;
}

- (NSRect)artBoxRect
{
    CGRect rect = CGPDFPageGetBoxRect(pdfPage.pageRef, kCGPDFArtBox);
    return *(NSRect*)&rect;
}

- (NSString*)bboxStringOfBox:(CGPDFBox)boxType
                       hires:(BOOL)hires
            clipWithMediaBox:(BOOL)clip
          relativeToMediaBox:(BOOL)relativeToMediaBox
                   addHeader:(BOOL)addHeader
{
    CGPDFPageRef pageRef = pdfPage.pageRef;
    CGRect mediaBoxRect = CGPDFPageGetBoxRect(pageRef, kCGPDFMediaBox);
    CGRect rect = CGPDFPageGetBoxRect(pageRef, boxType);
    rect = clip ? CGRectIntersection(rect, mediaBoxRect) : rect;

    if (relativeToMediaBox) {
        rect.origin.x -= mediaBoxRect.origin.x;
        rect.origin.y -= mediaBoxRect.origin.y;
    }
   
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
