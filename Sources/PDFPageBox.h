#import <Quartz/Quartz.h>

@interface PDFPageBox : NSObject
- (instancetype)initWithPDFPage:(PDFPage*)page;
+ (instancetype)pageBoxWithPDFPage:(PDFPage*)page;
+ (instancetype)pageBoxWithFilePath:(NSString*)path page:(NSUInteger)page;
- (NSString*)bboxStringOfBox:(CGPDFBox)boxType hires:(BOOL)hires clipWithMediaBox:(BOOL)clip relativeToMediaBox:(BOOL)relativeToMediaBox addHeader:(BOOL)addHeader;
@end
