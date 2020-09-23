#import "PDFDocument-Extension.h"

@implementation PDFDocument (Extension)
+ (instancetype)documentWithFilePath:(NSString*)path
{
    return [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:path]];
}

+ (instancetype)documentWithMergingPDFFiles:(NSArray<NSString*>*)paths
{
    if (paths.count == 0) {
        return nil;
    }
    
    PDFDocument *doc = [PDFDocument documentWithFilePath:paths[0]];
    if (!doc) {
        return nil;
    }
    
    NSUInteger pageCount = doc.pageCount;
    for (NSUInteger i=1; i<paths.count; i++) {
        PDFDocument *insertedDoc = [PDFDocument documentWithFilePath:paths[i]];
        if (!insertedDoc) {
            return nil;
        }
        for (NSUInteger j=0; j<insertedDoc.pageCount; j++) {
            [doc insertPage:[insertedDoc pageAtIndex:j] atIndex:pageCount];
            pageCount++;
        }
    }
    
    return doc;
}

- (void)appendPage:(PDFPage*)page
{
    [self insertPage:page atIndex:self.pageCount];
}

- (PDFPageBox*)pageBoxAtIndex:(NSUInteger)index
{
    return [self pageAtIndex:index].pageBox;
}

+ (void)fillBackgroundOfPdfFilePath:(NSString*)path withColor:(NSColor*)fillColor
{
    PDFDocument *doc = [PDFDocument documentWithFilePath:path];
    NSUInteger pageCount = doc.pageCount;

    CGColorRef fillColorRef;
    
    if ([fillColor respondsToSelector:@selector(CGColor)]) {
        fillColorRef = fillColor.CGColor;
    } else {
        CGFloat components[fillColor.numberOfComponents];
        [fillColor getComponents:(CGFloat*)&components];
        fillColorRef = (CGColorRef)CGColorCreate(fillColor.colorSpace.CGColorSpace, components);
    }

    for (NSUInteger i = 0; i < pageCount; i++) {
        CGPDFPageRef pdfPageRef = [doc pageAtIndex:i].pageRef;
        const CGRect mediaBoxRect = CGPDFPageGetBoxRect(pdfPageRef, kCGPDFMediaBox);

        CGContextRef contextRef = CGPDFContextCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], &mediaBoxRect, NULL);

        CGPDFContextBeginPage(contextRef, NULL);

        CGContextSaveGState(contextRef);
        
        CGContextSetFillColorWithColor(contextRef, fillColorRef);
        CGRect drawRect = CGRectMake(mediaBoxRect.origin.x-1, mediaBoxRect.origin.y-1, mediaBoxRect.size.width+2, mediaBoxRect.size.height+2);
        CGContextFillRect(contextRef, drawRect);
        CGContextDrawPDFPage(contextRef, pdfPageRef);
        
        CGContextRestoreGState(contextRef);

        CGPDFContextEndPage(contextRef);
        CGContextRelease(contextRef);
    }
}


@end
