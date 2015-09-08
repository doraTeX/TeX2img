#import <Quartz/Quartz.h>

@interface PDFDocument (Extension)
+ (instancetype)documentWithFilePath:(NSString*)path;
@end
