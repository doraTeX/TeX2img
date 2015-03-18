#import "ControllerC.h"
#import "global.h"
#import <stdio.h>
#import <stdarg.h>

BOOL checkWhich(NSString *cmdName)
{
	int status = system([NSString stringWithFormat:@"PATH=$PATH:%@; /usr/bin/which %@ > /dev/null", ADDITIONAL_PATH, cmdName].UTF8String);
	return (status == 0) ? YES : NO;
}

@implementation ControllerC
- (void)printStdErr:(NSString*)format, ...
{
    va_list arguments;
    va_start(arguments, format);
    NSString *msg = [NSString.alloc initWithFormat:format arguments:arguments];
    fprintf(stderr, "%s", msg.UTF8String);
    va_end(arguments);
}

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
	[self printStdErr:@"tex2img : %@ cannot be found.\nCheck environment variable $PATH.\n", aPath];
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
    [self printStdErr:@"tex2img : The extention of output file must be either eps/png/jpg/pdf/svg.\n"];
}

- (void)showFileGenerateError:(NSString*)aPath
{
	[self printStdErr:@"tex2img : %@ cannot be created, and so generation has been aborted.\nCheck permission.\n", aPath];
}

- (void)showExecError:(NSString*)command
{
	[self printStdErr:@"tex2img : %@ cannot be executed.\nCheck errors in the source code.\n", command];
}

- (void)showCannotOverwriteError:(NSString*)path
{
	[self printStdErr:@"tex2img : %@ cannot be overwritten.\n", path];
}

- (void)showCannotCreateDirectoryError:(NSString*)dir
{
    [self printStdErr:@"tex2img : Directory %@ cannot be overwritten.\n", dir];
}

- (void)showCompileError
{
	[self printStdErr:@"tex2img : TeX Compile error.\nCheck errors in the source code.\n"];
}

- (void)appendOutputAndScroll:(NSString*)str quiet:(BOOL)quiet
{
    if (!quiet) {
        printf("%s", str.UTF8String);
    }
}
#pragma mark -


@end
