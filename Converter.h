#import <Cocoa/Cocoa.h>

@protocol OutputController
- (void)showExtensionError;
- (void)showNotFoundError:(NSString*)aPath;
- (BOOL)checkPlatexPath:(NSString*)platexPath dvipdfmxPath:(NSString*)dvipdfmxPath gsPath:(NSString*)gsPath;
- (BOOL)checkPdfcropExistence;
- (BOOL)checkEpstopdfExistence;
- (void)showFileGenerateError:(NSString*)aPath;
- (void)showExecError:(NSString*)command;
- (void)showCannotOverrideError:(NSString*)path;
- (void)showCompileError;
- (void)appendOutputAndScroll:(NSString*)str quiet:(BOOL)quiet;
- (void)clearOutputTextView;
- (void)showOutputDrawer;
- (void)showMainWindow;
@end

@interface Converter : NSObject
+ (Converter*)converterWithProfile:(NSDictionary*)aProfile;
- (BOOL)compileAndConvertWithInputPath:(NSString*)texSourcePath;
- (BOOL)compileAndConvertWithSource:(NSString*)texSourceStr;
- (BOOL)compileAndConvertWithBody:(NSString*)texBodyStr;
- (NSUInteger)pageCount;
@end
