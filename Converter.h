//
//  Converter.h
//  TeX2img
//
//  Created by Taylor on 08/12/29.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol OutputController
- (void)showExtensionError;
- (void)showNotFoundError:(NSString*)aPath;
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
	int resolutionLevel, leftMargin, rightMargin, topMargin, bottomMargin;
	bool leaveTextFlag, transparentPngFlag, showOutputWindowFlag, previewFlag, deleteTmpFileFlag;
	id<OutputController> controller;

	NSFileManager* fileManager;
	NSString* tempdir;
	int pid;
	NSString* tempFileBaseName; 
	NSString* pdfcropPath;
	NSString* epstopdfPath;
}
+ (Converter*)converterWithPlatex:(NSString*) _platexPath dvipdfmx:(NSString*)_dvipdfmxPath gs:(NSString*)_gsPath
				  resolutionLevel:(int)_resolutionLevel leftMargin:(int)_leftMargin rightMargin:(int)_rightMargin topMargin:(int)_topMargin bottomMargin:(int)_bottomMargin 
						leaveText:(bool)_leaveTextFlag transparentPng:(bool)_transparentPngFlag 
				 showOutputWindow:(bool)_showOutputWindowFlag preview:(bool)_previewFlag deleteTmpFile:(bool)_deleteTmpFileFlag
					   controller:(id<OutputController>)_controller;
- (void)compileAndConvertWithPreamble:(NSString*)preambleStr withBody:(NSString*)texBodyStr outputFilePath:(NSString*)outputFilePath;
@end
