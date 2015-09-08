#import <Quartz/Quartz.h>
#import "PDFPage-Extension.h"

@interface PDFDocument (Extension)
+ (instancetype)documentWithFilePath:(NSString*)path;
- (PDFPageBox*)pageBoxAtIndex:(NSUInteger)index;
@end
