#import "ControllerC.h"
#import <stdio.h>

BOOL checkWhich(NSString* cmdName)
{
	int status = system([[NSString stringWithFormat:@"which %@ > /dev/null", cmdName] cString]);
	return (status==0) ? YES : NO;
}

@implementation ControllerC
////// ここから OutputController プロトコルの実装 //////
- (void)clearOutputTextView
{	
}

- (void)showOutputDrawer
{
}

- (void)showMainWindow
{	
}

- (void)showNotFoundError:(NSString*)aPath
{
	fprintf(stderr, [[NSString stringWithFormat:@"tex2img : %@ can't be found.\nCheck environment variable $PATH.\n", aPath] cString]);
}

- (BOOL)checkPlatexPath:(NSString*)platexPath dvipdfmxPath:(NSString*)dvipdfmxPath gsPath:(NSString*)gsPath
{
	if(!checkWhich(platexPath))
	{
		[self showNotFoundError:@"platex"];
		return NO;
	}
	if(!checkWhich(dvipdfmxPath))
	{
		[self showNotFoundError:@"dvipdfmx"];
		return NO;
	}
	if(!checkWhich(gsPath))
	{
		[self showNotFoundError:@"gs"];
		return NO;
	}
	return YES;
}

- (BOOL)checkPdfcropExistence;
{
	if(!checkWhich(@"pdfcrop"))
	{
		[self showNotFoundError:@"epstopdf"];
		return NO;
	}

	return YES;
}

- (BOOL)checkEpstopdfExistence;
{
	if(!checkWhich(@"pdfcrop"))
	{
		[self showNotFoundError:@"pdfcrop"];
		return NO;
	}
	
	return YES;
}

- (void)showExtensionError
{
	fprintf(stderr, [@"tex2img : The extention of output file must be either .eps/.png/.jpg/.pdf.\n" cString]);
}

- (void)showFileGenerateError:(NSString*)aPath
{
	fprintf(stderr, [[NSString stringWithFormat:@"tex2img : %@ can't be created so generation has been aborted.\nCheck permission.\n", aPath] cString]);	
}

- (void)showExecError:(NSString*)command
{
	fprintf(stderr, [[NSString stringWithFormat:@"tex2img : %@ can't be executed.\nCheck errors in the source code.\n", command] cString]);
}

- (void)showCannotOverrideError:(NSString*)path
{
	fprintf(stderr, [[NSString stringWithFormat:@"tex2img : %@ can't be overridden.\n", path] cString]);
}

- (void)showCompileError
{
	fprintf(stderr, [@"tex2img : TeX Compile error.\nCheck errors in the source code.\n" cString]);
}

- (void)appendOutputAndScroll:(NSString*)str quiet:(BOOL)quiet
{
	if(!quiet) printf([str cString]);
}
////// ここまで OutputController プロトコルの実装 //////


@end
