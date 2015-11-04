#import <Quartz/Quartz.h>

@interface PDFPageBox : NSObject
- (instancetype)initWithPDFPage:(PDFPage*)page;
+ (instancetype)pageBoxWithPDFPage:(PDFPage*)page;
+ (instancetype)pageBoxWithFilePath:(NSString*)path page:(NSUInteger)page;
- (NSRect)mediaBoxRect;
- (NSRect)cropBoxRect;
- (NSRect)bleedBoxRect;
- (NSRect)trimBoxRect;
- (NSRect)artBoxRect;
- (NSString*)bboxStringOfBox:(CGPDFBox)boxType
                       hires:(BOOL)hires
                   addHeader:(BOOL)addHeader;
@end
