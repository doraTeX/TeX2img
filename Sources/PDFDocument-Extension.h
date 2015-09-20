#import <Quartz/Quartz.h>
#import "PDFPage-Extension.h"

@interface PDFDocument (Extension)
+ (instancetype)documentWithFilePath:(NSString*)path;
+ (instancetype)documentWithMergingPDFFiles:(NSArray<NSString*>*)paths;
- (PDFPageBox*)pageBoxAtIndex:(NSUInteger)index;
@end
