#import <Quartz/Quartz.h>

@interface PDFPageBox : NSObject
- (instancetype)initWithPage:(PDFPage*)page;
+ (instancetype)pageBoxWithPage:(PDFPage*)page;
- (NSString*)bboxStringOfBox:(CGPDFBox)boxType hires:(BOOL)hires clipWithMediaBox:(BOOL)clip;
@end
