#import <Cocoa/Cocoa.h>
#import "global.h"

@protocol OutputController
- (void)showExtensionError;
- (void)showNotFoundError:(NSString*)aPath;
- (BOOL)latexExistsAtPath:(NSString*)latexPath dviDriverPath:(NSString*)dviDriverPath gsPath:(NSString*)gsPath;
- (BOOL)epstopdfExists;
- (BOOL)mudrawExists;
- (BOOL)pdftopsExists;
- (void)showFileFormatError:(NSString*)aPath;
- (void)showFileGenerationError:(NSString*)aPath;
- (void)showExecError:(NSString*)command;
- (void)showCannotOverwriteError:(NSString*)path;
- (void)showCannotCreateDirectoryError:(NSString*)dir;
- (void)showCompileError;
- (void)showImageSizeError;
- (void)appendOutputAndScroll:(NSString*)str quiet:(BOOL)quiet;
- (void)prepareOutputTextView;
- (void)releaseOutputTextView;
- (void)showOutputWindow;
- (void)showMainWindow;
- (void)showErrorsIgnoredWarning;
- (void)showPageSkippedWarning:(NSArray<NSNumber*>*)pages;
- (void)showWhitePageWarning:(NSArray<NSNumber*>*)pages;
- (BOOL)execCommand:(NSString*)command atDirectory:(NSString*)path withArguments:(NSArray<NSString*>*)arguments quiet:(BOOL)quiet;
- (void)previewFiles:(NSArray<NSString*>*)files withApplication:(NSString*)app;
- (void)printResult:(NSArray<NSString*>*)generatedFiles quiet:(BOOL)quiet;
- (void)generationDidFinish:(ExitStatus)status;
- (void)exitCurrentThreadIfTaskKilled;
@end

@interface Converter : NSObject
+ (instancetype)converterWithProfile:(Profile*)aProfile;
- (BOOL)compileAndConvertWithInputPath:(NSString*)sourcePath;
- (BOOL)compileAndConvertWithSource:(NSString*)texSourceStr;
- (BOOL)compileAndConvertWithBody:(NSString*)texBodyStr;
- (void)deleteTemporaryFiles;
- (NSString*)bboxStringOfPdf:(NSString*)pdfPath
                        page:(NSInteger)page
                       hires:(BOOL)hires;
@property (nonatomic, assign) BOOL keepPageSizeFlag;
@property (nonatomic, assign) NSInteger leftMargin, rightMargin, topMargin, bottomMargin;
@property (nonatomic, assign) CGPDFBox pageBoxType;
@end
