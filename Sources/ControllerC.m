#import <stdio.h>
#import <stdarg.h>
#import "ControllerC.h"
#import "global.h"
#import "UtilityC.h"

BOOL checkWhich(NSString *cmdName)
{
	int status = system([NSString stringWithFormat:@"PATH=$PATH:%@; /usr/bin/which %@ > /dev/null", ADDITIONAL_PATH, cmdName].UTF8String);
	return (status == 0) ? YES : NO;
}

@implementation ControllerC
#pragma mark OutputController プロトコルの実装
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
	printStdErr("tex2img : %s cannot be found.\nCheck the environment variable $PATH.\n", aPath.UTF8String);
}

- (BOOL)latexExistsAtPath:(NSString*)latexPath dvipdfmxPath:(NSString*)dvipdfmxPath gsPath:(NSString*)gsPath
{
	if (!checkWhich(latexPath)) {
		[self showNotFoundError:@"LaTeX"];
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

- (BOOL)epstopdfExists;
{
	if (!checkWhich(@"epstopdf")) {
		[self showNotFoundError:@"epstopdf"];
		return NO;
	}
	
	return YES;
}

- (BOOL)mudrawExists;
{
    if (!checkWhich(@"mudraw")) {
        [self showNotFoundError:@"mudraw"];
        return NO;
    }
    
    return YES;
}

- (void)showExtensionError
{
    printStdErr("tex2img : The extention of output file must be either eps/png/jpg/pdf/svg.\n");
}

- (void)showFileGenerateError:(NSString*)aPath
{
	printStdErr("tex2img : %s cannot be created, and so generation has been aborted.\nCheck permission.\n", aPath.UTF8String);
}

- (void)showExecError:(NSString*)command
{
	printStdErr("tex2img : %s cannot be executed.\nCheck errors in the source code.\n", command.UTF8String);
}

- (void)showCannotOverwriteError:(NSString*)path
{
	printStdErr("tex2img : %s cannot be overwritten.\n", path.UTF8String);
}

- (void)showCannotCreateDirectoryError:(NSString*)dir
{
    printStdErr("tex2img : Directory %s cannot be overwritten.\n", dir.UTF8String);
}

- (void)showCompileError
{
	printStdErr("tex2img : TeX Compile error.\nCheck errors in the source code.\n");
}

- (void)appendOutputAndScroll:(NSString*)str quiet:(BOOL)quiet
{
    if (!quiet) {
        printf("%s", str.UTF8String);
    }
}
#pragma mark -


@end
