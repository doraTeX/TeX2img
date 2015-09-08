#import "PDFDocument-Extension.h"

@implementation PDFDocument (Extension)
+ (instancetype)documentWithFilePath:(NSString*)path
{
    return [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:path]];
}

+ (instancetype)documentWithMergingPDFFiles:(NSArray*)paths
{
    if (paths.count == 0) {
        return nil;
    }
    
    PDFDocument *doc = [PDFDocument documentWithFilePath:paths[0]];
    
    NSUInteger pageCount = doc.pageCount;
    for (NSUInteger i=1; i<paths.count; i++) {
        PDFDocument *insertedDoc = [PDFDocument documentWithFilePath:paths[i]];
        for (NSUInteger j=0; j<insertedDoc.pageCount; j++) {
            [doc insertPage:[insertedDoc pageAtIndex:j] atIndex:pageCount];
            pageCount++;
        }
    }
    
    return doc;
}

- (PDFPageBox*)pageBoxAtIndex:(NSUInteger)index
{
    return [self pageAtIndex:index].pageBox;
}

@end
