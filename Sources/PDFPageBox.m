#import "PDFPageBox.h"
#import "PDFDocument-Extension.h"
#import "TeX2img-Swift.h"

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
                   addHeader:(BOOL)addHeader
{
    CGPDFPageRef pageRef = pdfPage.pageRef;
    CGRect mediaBoxRect = CGPDFPageGetBoxRect(pageRef, kCGPDFMediaBox);
    CGRect rect = CGRectIntersection(CGPDFPageGetBoxRect(pageRef, boxType), mediaBoxRect); // MediaBox でクリップ

    // gs がデフォルトで -dUseMediaBox で呼ばれることに対応して，MediaBox に対する相対座標を返す
    rect.origin.x -= mediaBoxRect.origin.x;
    rect.origin.y -= mediaBoxRect.origin.y;
   
    NSString *result;
    
    // 回転情報の考慮
    NSInteger rotation = pdfPage.rotation;
    if (rotation == 90) {
        rect = CGRectMake(rect.origin.y,
                          mediaBoxRect.size.width - rect.origin.x - rect.size.width,
                          rect.size.height,
                          rect.size.width);
    }
    if (rotation == 180) {
        rect = CGRectMake(mediaBoxRect.size.width - rect.origin.x - rect.size.width,
                          mediaBoxRect.size.height - rect.origin.y - rect.size.height,
                          rect.size.width,
                          rect.size.height);
    }
    if (rotation == 270) {
        rect = CGRectMake(mediaBoxRect.size.height - rect.origin.y - rect.size.height,
                          rect.origin.x,
                          rect.size.height,
                          rect.size.width);
    }
    
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
