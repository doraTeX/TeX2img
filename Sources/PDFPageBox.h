#import <Quartz/Quartz.h>

@interface PDFPageBox : NSObject
- (instancetype)initWithPage:(PDFPage*)page;
+ (instancetype)pageBoxWithPage:(PDFPage*)page;
+ (instancetype)pageBoxWithFilePath:(NSString*)path page:(NSUInteger)page;
- (NSString*)bboxStringOfBox:(CGPDFBox)boxType hires:(BOOL)hires clipWithMediaBox:(BOOL)clip addHeader:(BOOL)addHeader;
@end
