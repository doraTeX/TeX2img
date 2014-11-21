#import <Cocoa/Cocoa.h>

@protocol OutputController
- (void)showExtensionError;
- (void)showNotFoundError:(NSString*)aPath;
- (bool)checkPlatexPath:(NSString*)platexPath dvipdfmxPath:(NSString*)dvipdfmxPath gsPath:(NSString*)gsPath;
- (bool)checkPdfcropExistence;
- (bool)checkEpstopdfExistence;
- (void)showFileGenerateError:(NSString*)aPath;
- (void)showExecError:(NSString*)command;
- (void)showCannotOverrideError:(NSString*)path;
- (void)showCompileError;
- (void)appendOutputAndScroll:(NSMutableString*)mStr quiet:(bool)quiet;
- (void)clearOutputTextView;
- (void)showOutputWindow;
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
	bool leaveTextFlag, transparentPngFlag, showOutputWindowFlag, previewFlag, deleteTmpFileFlag, ignoreErrorsFlag, utfExportFlag, quietFlag;
	id<OutputController> controller;

	NSFileManager* fileManager;
	NSString* tempdir;
	int pid;
	NSString* tempFileBaseName; 
	NSString* pdfcropPath;
	NSString* epstopdfPath;
}
+ (Converter*)converterWithProfile:(NSDictionary*)aProfile;
- (bool)compileAndConvertWithInputPath:(NSString*)texSourcePath;
- (bool)compileAndConvertWithSource:(NSString*)texSourceStr;
- (bool)compileAndConvertWithBody:(NSString*)texBodyStr;
@end
