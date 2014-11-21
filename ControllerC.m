#import "ControllerC.h"
#import <stdio.h>

BOOL checkWhich(NSString* cmdName)
{
	int status = system([[NSString stringWithFormat:@"which %@ > /dev/null", cmdName] cStringUsingEncoding:NSUTF8StringEncoding]);
	return (status == 0) ? YES : NO;
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
	fprintf(stderr, [[NSString stringWithFormat:@"tex2img : %@ can't be found.\nCheck environment variable $PATH.\n", aPath] cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (BOOL)platexExistsAtPath:(NSString*)platexPath dvipdfmxPath:(NSString*)dvipdfmxPath gsPath:(NSString*)gsPath
{
	if (!checkWhich(platexPath)) {
		[self showNotFoundError:@"platex"];
		return NO;
	}
	if (!checkWhich(dvipdfmxPath)) {
		[self showNotFoundError:@"dvipdfmx"];
		return NO;
	}
	if (!checkWhich(gsPath)) {
		[self showNotFoundError:@"gs"];
		return NO;
	}
	return YES;
}

- (BOOL)pdfcropExists;
{
	if (!checkWhich(@"pdfcrop")) {
		[self showNotFoundError:@"epstopdf"];
		return NO;
	}

	return YES;
}

- (BOOL)epstopdfExists;
{
	if (!checkWhich(@"pdfcrop")) {
		[self showNotFoundError:@"pdfcrop"];
		return NO;
	}
	
	return YES;
}

- (void)showExtensionError
{
	fprintf(stderr, [@"tex2img : The extention of output file must be either .eps/.png/.jpg/.pdf.\n" cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)showFileGenerateError:(NSString*)aPath
{
	fprintf(stderr, [[NSString stringWithFormat:@"tex2img : %@ can't be created so generation has been aborted.\nCheck permission.\n", aPath] cStringUsingEncoding:NSUTF8StringEncoding]);	
}

- (void)showExecError:(NSString*)command
{
	fprintf(stderr, [[NSString stringWithFormat:@"tex2img : %@ can't be executed.\nCheck errors in the source code.\n", command] cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)showCannotOverrideError:(NSString*)path
{
	fprintf(stderr, [[NSString stringWithFormat:@"tex2img : %@ can't be overridden.\n", path] cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)showCompileError
{
	fprintf(stderr, [@"tex2img : TeX Compile error.\nCheck errors in the source code.\n" cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)appendOutputAndScroll:(NSString*)str quiet:(BOOL)quiet
{
    if (!quiet) {
        printf([str cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}
////// ここまで OutputController プロトコルの実装 //////


@end
