#import <Quartz/Quartz.h>
#import "PDFPageBox.h"

@interface PDFDocument (Extension)
+ (instancetype)documentWithFilePath:(NSString*)path;
+ (instancetype)documentWithMergingPDFFiles:(NSArray<NSString*>*)paths;
- (void)appendPage:(PDFPage*)page;
- (PDFPageBox*)pageBoxAtIndex:(NSUInteger)index;

// 1ページのみの PDF の MediaBox の背景を指定された色で塗りつぶす（複数ページPDFは未対応）。
// 日本語の埋め込みテキストは壊れてしまう。
+ (void)fillBackgroundOfPdfFilePath:(NSString*)path withColor:(NSColor*)color;
@end
