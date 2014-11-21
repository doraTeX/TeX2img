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
- (void)appendOutputAndScroll:(NSMutableString*)mStr quiet:(BOOL)quiet;
- (void)clearOutputTextView;
- (void)showOutputDrawer;
- (void)showMainWindow;
@end

@interface Converter : NSObject {
	NSString* platexPath;
	NSString* dvipdfmxPath;
	NSString* gsPath;
	NSString* encoding;
	NSString* outputFilePath;
	NSString* preambleStr;
	float resolutionLevel;
	int leftMargin, rightMargin, topMargin, bottomMargin;
	BOOL leaveTextFlag, transparentPngFlag, showOutputDrawerFlag, previewFlag, deleteTmpFileFlag, ignoreErrorsFlag, utfExportFlag, quietFlag;
	id<OutputController> controller;

	NSFileManager* fileManager;
	NSString* tempdir;
	int pid;
	NSString* tempFileBaseName; 
	NSString* pdfcropPath;
	NSString* epstopdfPath;
}
+ (Converter*)converterWithProfile:(NSDictionary*)aProfile;
- (BOOL)compileAndConvertWithInputPath:(NSString*)texSourcePath;
- (BOOL)compileAndConvertWithSource:(NSString*)texSourceStr;
- (BOOL)compileAndConvertWithBody:(NSString*)texBodyStr;
@end
