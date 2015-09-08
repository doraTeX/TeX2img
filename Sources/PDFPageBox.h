#import <Quartz/Quartz.h>

@interface PDFPageBox : NSObject
- (instancetype)initWithPage:(PDFPage*)page;
+ (instancetype)pageBoxWithPage:(PDFPage*)page;
@end
