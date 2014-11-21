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
- (void)appendOutputAndScroll:(NSMutableString*)mStr;
- (void)clearOutputTextView;
- (void)showOutputWindow;
- (void)showMainWindow;
@end

@interface Converter : NSObject {
	NSString* platexPath;
	NSString* dvipdfmxPath;
	NSString* gsPath;
	NSString* encoding;
	int resolutionLevel, leftMargin, rightMargin, topMargin, bottomMargin;
	bool leaveTextFlag, transparentPngFlag, showOutputWindowFlag, previewFlag, deleteTmpFileFlag, ignoreErrorsFlag, utfExportFlag;
	id<OutputController> controller;

	NSFileManager* fileManager;
	NSString* tempdir;
	int pid;
	NSString* tempFileBaseName; 
	NSString* pdfcropPath;
	NSString* epstopdfPath;
}
+ (Converter*)converterWithPlatex:(NSString*) _platexPath dvipdfmx:(NSString*)_dvipdfmxPath gs:(NSString*)_gsPath
				  withPdfcropPath:(NSString*)_pdfcropPath withEpstopdfPath:(NSString*)_epstopdfPath
						 encoding:(NSString*)_encoding
				  resolutionLevel:(int)_resolutionLevel leftMargin:(int)_leftMargin rightMargin:(int)_rightMargin topMargin:(int)_topMargin bottomMargin:(int)_bottomMargin 
						leaveText:(bool)_leaveTextFlag transparentPng:(bool)_transparentPngFlag 
				 showOutputWindow:(bool)_showOutputWindowFlag preview:(bool)_previewFlag deleteTmpFile:(bool)_deleteTmpFileFlag
					 ignoreErrors:(bool)_ignoreErrors
						utfExport:(bool)_utfExport
					   controller:(id<OutputController>)_controller;
- (bool)compileAndConvertWithInputPath:(NSString*)texSourcePath outputFilePath:(NSString*)outputFilePath;
- (bool)compileAndConvertWithSource:(NSString*)texSourceStr outputFilePath:(NSString*)outputFilePath;
- (bool)compileAndConvertWithPreamble:(NSString*)preambleStr withBody:(NSString*)texBodyStr outputFilePath:(NSString*)outputFilePath;
@end
