#import <Quartz/Quartz.h>
#import <sys/xattr.h>
#import "ControllerG.h"
#import "TeX2img-Swift.h"
#import "NSArray-Extension.h"
#import "NSDictionary-Extension.h"
#import "NSString-Extension.h"
#import "NSMutableString-Extension.h"
#import "TeXTextView.h"
#import "UtilityG.h"

#define ENABLED @"enabled"
#define DISABLED @"disabled"

typedef enum {
    DIRECT = 0,
    FROMFILE = 1
} InputMethod;

typedef enum {
    NONE = 0,
    UTF8 = 1,
    SJIS = 2,
    JIS = 3,
    EUC = 4
} EncodingTag;

#define AutoSavedProfileName @"*AutoSavedProfile*"
#define TemplateDirectoryName @"Templates"

@interface ControllerG()
@property (nonatomic, strong) IBOutlet ProfileController *profileController;
@property (nonatomic, strong) IBOutlet NSWindow *mainWindow;
@property (nonatomic, strong) IBOutlet NSWindow *outputWindow;
@property (nonatomic, strong) IBOutlet NSTextView *outputTextView;
@property (nonatomic, strong) IBOutlet NSTextField *outputFileTextField;
@property (nonatomic, strong) IBOutlet NSPopUpButton *extensionPopupButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *templatePopupButton;

@property (nonatomic, strong) IBOutlet NSWindow *preambleWindow;
@property (nonatomic, strong) IBOutlet TeXTextView *preambleTextView;
@property (nonatomic, strong) IBOutlet NSMenuItem *convertYenMarkMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *richTextMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *outputWindowMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *preambleWindowMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *generateMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *abortMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *autoCompleteMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *autoIndentMenuItem;

@property (nonatomic, strong) IBOutlet NSButton *flashInMovingCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *highlightContentCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *beepCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *flashBackgroundCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *checkBraceCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *checkBracketCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *checkSquareCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *checkParenCheckBox;

@property (nonatomic, strong) IBOutlet NSTextField *fontTextField;
@property (nonatomic, strong) IBOutlet NSTextField *tabWidthTextField;
@property (nonatomic, strong) IBOutlet NSStepper *tabWidthStepper;
@property (nonatomic, strong) IBOutlet NSButton *tabIndentCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *wrapLineCheckBox;

@property (nonatomic, strong) IBOutlet NSButton *showTabCharacterCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *showSpaceCharacterCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *showNewLineCharacterCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *showFullwidthSpaceCharacterCheckBox;

@property (nonatomic, strong) IBOutlet NSMatrix *commandCompletionKeyMatrix;

@property (nonatomic, strong) IBOutlet NSWindow *colorPalleteWindow;
@property (nonatomic, strong) IBOutlet NSMenuItem *colorPalleteWindowMenuItem;
@property (nonatomic, strong) IBOutlet NSColorWell *colorPalleteColorWell;
@property (nonatomic, strong) IBOutlet NSMatrix *colorStyleMatrix;
@property (nonatomic, strong) IBOutlet NSTextField *colorTextField;

@property (nonatomic, strong) IBOutlet NSButton *directInputButton;
@property (nonatomic, strong) IBOutlet NSButton *inputSourceFileButton;
@property (nonatomic, strong) IBOutlet NSTextField *inputSourceFileTextField;
@property (nonatomic, strong) IBOutlet NSButton *browseSourceFileButton;

@property (nonatomic, strong) IBOutlet NSButton *generateButton;

@property (nonatomic, strong) IBOutlet NSButton *autoRestoreCheckBox;

@property (nonatomic, strong) IBOutlet NSButton *transparentCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *plainTextCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *deleteDisplaySizeCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *mergeOutputsCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *keepPageSizeCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *showOutputWindowCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *sendNotificationCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *previewCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *deleteTmpFileCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *toClipboardCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *embedSourceCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *autoPasteCheckBox;
@property (nonatomic, strong) IBOutlet NSPopUpButton *autoPasteDestinationPopUpButton;
@property (nonatomic, strong) IBOutlet NSButton *embedInIllustratorCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *ungroupCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *keepPageSizeAdvancedButton;
@property (nonatomic, strong) IBOutlet NSButton *mergeOutputAdvancedButton;

@property (nonatomic, strong) IBOutlet NSWindow *preferenceWindow;

@property (nonatomic, strong) IBOutlet NSTextField *resolutionTextField;
@property (nonatomic, strong) IBOutlet NSTextField *dpiTextField;
@property (nonatomic, strong) IBOutlet NSTextField *leftMarginTextField;
@property (nonatomic, strong) IBOutlet NSTextField *rightMarginTextField;
@property (nonatomic, strong) IBOutlet NSTextField *topMarginTextField;
@property (nonatomic, strong) IBOutlet NSTextField *bottomMarginTextField;

@property (nonatomic, strong) IBOutlet NSStepper *resolutionStepper;
@property (nonatomic, strong) IBOutlet NSStepper *dpiStepper;
@property (nonatomic, strong) IBOutlet NSStepper *leftMarginStepper;
@property (nonatomic, strong) IBOutlet NSStepper *rightMarginStepper;
@property (nonatomic, strong) IBOutlet NSStepper *topMarginStepper;
@property (nonatomic, strong) IBOutlet NSStepper *bottomMarginStepper;

@property (nonatomic, strong) IBOutlet NSTextField *latexPathTextField;
@property (nonatomic, strong) IBOutlet NSTextField *dviDriverPathTextField;
@property (nonatomic, strong) IBOutlet NSTextField *gsPathTextField;
@property (nonatomic, strong) IBOutlet NSButton *guessCompilationButton;
@property (nonatomic, strong) IBOutlet NSTextField *numberOfCompilationTextField;
@property (nonatomic, strong) IBOutlet NSStepper *numberOfCompilationStepper;
@property (nonatomic, strong) IBOutlet NSButton *textPdfCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *ignoreErrorCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *utfExportCheckBox;
@property (nonatomic, strong) IBOutlet NSPopUpButton *encodingPopUpButton;
@property (nonatomic, strong) IBOutlet NSMatrix *unitMatrix;
@property (nonatomic, strong) IBOutlet NSMatrix *priorityMatrix;
@property (nonatomic, strong) IBOutlet NSButton *workInInputFileDirectoryCheckBox;
@property (nonatomic, copy) NSString *lastSavedPath;

@property (nonatomic, strong) NSWindow *lastActiveWindow;
@property (nonatomic, copy) NSMutableDictionary<NSString*,NSColor*> *lastColorDict;

@property (nonatomic, strong) IBOutlet NSColorWell *fillColorWell;

@property (nonatomic, strong) IBOutlet NSColorWell *lightModeForegroundColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *lightModeBackgroundColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *lightModeCursorColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *lightModeBraceColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *lightModeCommentColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *lightModeCommandColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *lightModeInvisibleColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *lightModeHighlightedBraceColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *lightModeEnclosedContentBackgroundColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *lightModeFlashingBackgroundColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *lightModeConsoleForegroundColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *lightModeConsoleBackgroundColorWell;

@property (nonatomic, strong) IBOutlet NSColorWell *darkModeForegroundColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *darkModeBackgroundColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *darkModeCursorColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *darkModeBraceColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *darkModeCommentColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *darkModeCommandColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *darkModeInvisibleColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *darkModeHighlightedBraceColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *darkModeEnclosedContentBackgroundColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *darkModeFlashingBackgroundColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *darkModeConsoleForegroundColorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *darkModeConsoleBackgroundColorWell;

@property (nonatomic, strong) IBOutlet NSButton *makeatletterEnabledCheckBox;

@property (nonatomic, strong) IBOutlet NSViewController *autoDetectionTargetSettingViewController;
@property (nonatomic, strong) IBOutlet NSMatrix *autoDetectionTargetMatrix;

@property (nonatomic, strong) IBOutlet NSBox *invisibleCharacterBox;

@property (nonatomic, strong) IBOutlet NSButton *spaceCharacterKindButton;
@property (nonatomic, strong) IBOutlet NSButton *fullwidthSpaceCharacterKindButton;
@property (nonatomic, strong) IBOutlet NSButton *returnCharacterKindButton;
@property (nonatomic, strong) IBOutlet NSButton *tabCharacterKindButton;

@property (nonatomic, strong) IBOutlet NSViewController *spaceCharacterKindSettingViewController;
@property (nonatomic, strong) IBOutlet NSMatrix *spaceCharacterKindMatrix;

@property (nonatomic, strong) IBOutlet NSViewController *fullwidthSpaceCharacterKindSettingViewController;
@property (nonatomic, strong) IBOutlet NSMatrix *fullwidthSpaceCharacterKindMatrix;

@property (nonatomic, strong) IBOutlet NSViewController *returnCharacterKindSettingViewController;
@property (nonatomic, strong) IBOutlet NSMatrix *returnCharacterKindMatrix;

@property (nonatomic, strong) IBOutlet NSViewController *tabCharacterKindSettingViewController;
@property (nonatomic, strong) IBOutlet NSMatrix *tabCharacterKindMatrix;

@property (nonatomic, strong) IBOutlet NSViewController *pageBoxSettingViewController;
@property (nonatomic, strong) IBOutlet NSMatrix *pageBoxMatrix;

@property (nonatomic, strong) IBOutlet NSViewController *animationParameterSettingViewController;
@property (nonatomic, strong) IBOutlet NSTextField *delayTextField;;
@property (nonatomic, strong) IBOutlet NSStepper *delayStepper;
@property (nonatomic, strong) IBOutlet NSTextField *loopCountTextField;
@property (nonatomic, strong) IBOutlet NSStepper *loopCountStepper;

@property (nonatomic, strong) IBOutlet NSButton *cuiToolInstallButton;
@property (nonatomic, strong) IBOutlet NSImageView *cuiToolStatusView;
@property (nonatomic, strong) IBOutlet NSTextField *cuiToolStatusTextField;

@property (atomic, strong) Converter *converter;
@property (atomic, strong) NSTask *runningTask;
@property (atomic, strong) NSPipe *outputPipe;
@property (atomic, assign) BOOL taskKilled;
@property (atomic, assign) NSFont *sourceFont;
@property (atomic, strong) UserNotificationDelegate *userNotificationDelegate;

@end

@implementation ControllerG
@synthesize profileController;
@synthesize mainWindow;
@synthesize sourceTextView;
@synthesize outputWindow;
@synthesize outputTextView;
@synthesize preambleWindow;
@synthesize preambleTextView;
@synthesize convertYenMarkMenuItem;
@synthesize richTextMenuItem;
@synthesize outputWindowMenuItem;
@synthesize preambleWindowMenuItem;
@synthesize generateMenuItem;
@synthesize abortMenuItem;
@synthesize flashInMovingCheckBox;
@synthesize highlightContentCheckBox;
@synthesize beepCheckBox;
@synthesize flashBackgroundCheckBox;
@synthesize checkBraceCheckBox;
@synthesize checkBracketCheckBox;
@synthesize checkSquareCheckBox;
@synthesize checkParenCheckBox;
@synthesize autoCompleteMenuItem;
@synthesize autoIndentMenuItem;
@synthesize showTabCharacterCheckBox;
@synthesize showSpaceCharacterCheckBox;
@synthesize showNewLineCharacterCheckBox;
@synthesize showFullwidthSpaceCharacterCheckBox;
@synthesize outputFileTextField;
@synthesize fontTextField;
@synthesize tabWidthStepper;
@synthesize tabWidthTextField;
@synthesize tabIndentCheckBox;
@synthesize wrapLineCheckBox;

@synthesize commandCompletionKeyMatrix;

@synthesize templatePopupButton;

@synthesize colorPalleteWindow;
@synthesize colorPalleteWindowMenuItem;
@synthesize colorPalleteColorWell;
@synthesize colorStyleMatrix;
@synthesize colorTextField;

@synthesize directInputButton;
@synthesize inputSourceFileButton;
@synthesize inputSourceFileTextField;
@synthesize browseSourceFileButton;

@synthesize generateButton;

@synthesize autoRestoreCheckBox;
@synthesize transparentCheckBox;
@synthesize plainTextCheckBox;
@synthesize deleteDisplaySizeCheckBox;
@synthesize mergeOutputsCheckBox;
@synthesize keepPageSizeCheckBox;
@synthesize showOutputWindowCheckBox;
@synthesize sendNotificationCheckBox;
@synthesize previewCheckBox;
@synthesize deleteTmpFileCheckBox;
@synthesize toClipboardCheckBox;
@synthesize embedSourceCheckBox;
@synthesize autoPasteCheckBox;
@synthesize autoPasteDestinationPopUpButton;
@synthesize embedInIllustratorCheckBox;
@synthesize ungroupCheckBox;
@synthesize preferenceWindow;

@synthesize resolutionTextField;
@synthesize dpiTextField;
@synthesize leftMarginTextField;
@synthesize rightMarginTextField;
@synthesize topMarginTextField;
@synthesize bottomMarginTextField;

@synthesize resolutionStepper;
@synthesize dpiStepper;
@synthesize leftMarginStepper;
@synthesize rightMarginStepper;
@synthesize topMarginStepper;
@synthesize bottomMarginStepper;

@synthesize latexPathTextField;
@synthesize dviDriverPathTextField;
@synthesize gsPathTextField;
@synthesize guessCompilationButton;
@synthesize numberOfCompilationTextField;
@synthesize numberOfCompilationStepper;
@synthesize textPdfCheckBox;
@synthesize ignoreErrorCheckBox;
@synthesize utfExportCheckBox;
@synthesize encodingPopUpButton;
@synthesize unitMatrix;
@synthesize priorityMatrix;
@synthesize workInInputFileDirectoryCheckBox;
@synthesize lastSavedPath;

@synthesize lastActiveWindow;
@synthesize lastColorDict;

@synthesize fillColorWell;

@synthesize lightModeForegroundColorWell;
@synthesize lightModeBackgroundColorWell;
@synthesize lightModeCursorColorWell;
@synthesize lightModeBraceColorWell;
@synthesize lightModeCommentColorWell;
@synthesize lightModeCommandColorWell;
@synthesize lightModeInvisibleColorWell;
@synthesize lightModeHighlightedBraceColorWell;
@synthesize lightModeEnclosedContentBackgroundColorWell;
@synthesize lightModeFlashingBackgroundColorWell;
@synthesize lightModeConsoleForegroundColorWell;
@synthesize lightModeConsoleBackgroundColorWell;

@synthesize darkModeForegroundColorWell;
@synthesize darkModeBackgroundColorWell;
@synthesize darkModeCursorColorWell;
@synthesize darkModeBraceColorWell;
@synthesize darkModeCommentColorWell;
@synthesize darkModeCommandColorWell;
@synthesize darkModeInvisibleColorWell;
@synthesize darkModeHighlightedBraceColorWell;
@synthesize darkModeEnclosedContentBackgroundColorWell;
@synthesize darkModeFlashingBackgroundColorWell;
@synthesize darkModeConsoleForegroundColorWell;
@synthesize darkModeConsoleBackgroundColorWell;

@synthesize makeatletterEnabledCheckBox;

@synthesize autoDetectionTargetSettingViewController;
@synthesize autoDetectionTargetMatrix;

@synthesize invisibleCharacterBox;

@synthesize spaceCharacterKindButton;
@synthesize fullwidthSpaceCharacterKindButton;
@synthesize returnCharacterKindButton;
@synthesize tabCharacterKindButton;

@synthesize spaceCharacterKindSettingViewController;
@synthesize spaceCharacterKindMatrix;

@synthesize fullwidthSpaceCharacterKindSettingViewController;
@synthesize fullwidthSpaceCharacterKindMatrix;

@synthesize returnCharacterKindSettingViewController;
@synthesize returnCharacterKindMatrix;

@synthesize tabCharacterKindSettingViewController;
@synthesize tabCharacterKindMatrix;

@synthesize pageBoxSettingViewController;
@synthesize pageBoxMatrix;

@synthesize animationParameterSettingViewController;
@synthesize delayTextField;
@synthesize delayStepper;
@synthesize loopCountTextField;
@synthesize loopCountStepper;

@synthesize cuiToolInstallButton;
@synthesize cuiToolStatusView;
@synthesize cuiToolStatusTextField;

@synthesize keepPageSizeAdvancedButton;
@synthesize mergeOutputAdvancedButton;

@synthesize extensionPopupButton;

@synthesize commandCompletionList;

@synthesize converter;
@synthesize runningTask;
@synthesize outputPipe;
@synthesize taskKilled;
@synthesize sourceFont;
@synthesize userNotificationDelegate;


- (BOOL)sudoCommand:(NSString*)command
        atDirectory:(NSString*)path
      withArguments:(NSArray<NSString*>*)arguments
       stdoutString:(NSString**)output
   errorDescription:(NSString**)errorDescription
{
    NSString *arg = [arguments componentsJoinedByString:@" "];
    NSString *shellscript = [[NSString stringWithFormat:@"cd '%@'; '%@' %@", path, command, arg] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];

    NSDictionary *errorInfo = [NSDictionary dictionary];
    NSString *script = [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", shellscript];

    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];

    NSAppleEventDescriptor *eventResult = [appleScript executeAndReturnError:&errorInfo];
    
    if (!eventResult) {
        *errorDescription = nil;
        
        if ([errorInfo valueForKey:NSAppleScriptErrorNumber]) {
            NSNumber *errorNumber = (NSNumber*)[errorInfo valueForKey:NSAppleScriptErrorNumber];
        
            if (errorNumber.intValue == -128) {
                *errorDescription = localizedString(@"Admin password required");
            }
        }
        
        if (*errorDescription == nil) {
            if ([errorInfo valueForKey:NSAppleScriptErrorMessage]) {
                *errorDescription = (NSString*)[errorInfo valueForKey:NSAppleScriptErrorMessage];
            }
        }
        
        return NO;
    
    } else {
        *output = eventResult.stringValue;
        
        return YES;
    }

}

#pragma mark - OutputController プロトコルの実装
- (void)exitCurrentThreadIfTaskKilled
{
    if (taskKilled) {
        taskKilled = NO;
        [NSThread.currentThread cancel];
        [self appendOutputAndScroll:[NSString stringWithFormat:@"\n\nTeX2img: %@\n\n", localizedString(@"processAborted")] quiet:NO];
    }
    
    if (NSThread.currentThread.isCancelled) {
        [self generationDidFinish:ExitStatusAborted];
        [NSThread exit];
    }
}

- (BOOL)execCommand:(NSString*)command atDirectory:(NSString*)path withArguments:(NSArray<NSString*>*)arguments quiet:(BOOL)quiet
{
    [self exitCurrentThreadIfTaskKilled];
    
    NSMutableString *cmdline = [NSMutableString string];
    [cmdline appendString:command];
    [cmdline appendString:@" "];
    
    for (NSString *argument in arguments) {
        [cmdline appendString:argument];
        [cmdline appendString:@" "];
    }
    [cmdline appendString:@"2>&1"];
    [self appendOutputAndScroll:[NSString stringWithFormat:@"$ %@\n", cmdline] quiet:quiet];
    
    runningTask = [NSTask new];
    outputPipe = [NSPipe pipe];
    [outputPipe.fileHandleForReading readInBackgroundAndNotify];
    
    runningTask.environment = @{@"PATH" : @"/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"};
    runningTask.currentDirectoryPath = path;
    runningTask.launchPath = BASH_PATH;
    runningTask.standardOutput = outputPipe;
    runningTask.standardError = outputPipe;
    runningTask.arguments = @[@"-c", cmdline];
    taskKilled = NO;
    
    [runningTask launch];
    [runningTask waitUntilExit];
    
    [self appendOutputAndScroll:@"\n" quiet:quiet];

    [self exitCurrentThreadIfTaskKilled];
    
    return (runningTask.terminationStatus == 0) ? YES : NO;
}

- (void)showMainWindow
{
    [mainWindow performSelectorOnMainThread:@selector(makeKeyAndOrderFront:) withObject:nil waitUntilDone:NO];
}

- (void)refreshTextView:(NSTextView*)textView
        foregroundColor:(NSColor*)foregroundColor
        backgroundColor:(NSColor*)backgroundColor
        cursorColor:(NSColor*)cursorColor
{
    if (!foregroundColor) foregroundColor = NSColor.defaultForegroundColor;
    if (!backgroundColor) backgroundColor = NSColor.defaultBackgroundColor;
    if (!cursorColor) cursorColor = NSColor.defaultCursorColor;
    
    textView.textColor = foregroundColor;
    textView.backgroundColor = backgroundColor;
    textView.insertionPointColor = cursorColor;

    NSRange entireRange = NSMakeRange(0, textView.string.length);
    [textView.textStorage setAttributes:@{NSForegroundColorAttributeName: foregroundColor,
                                          NSBackgroundColorAttributeName: backgroundColor }
                                  range:entireRange];
}

- (void)appendOutputAndScrollOnMainThread:(NSString*)str
{
    [outputTextView.textStorage.mutableString appendString:str];
    
    Profile *currentProfile = self.currentProfile;

    [self refreshTextView:outputTextView
          foregroundColor:consoleForegroundColorInProfile(currentProfile)
          backgroundColor:consoleBackgroundColorInProfile(currentProfile)
              cursorColor:cursorColorInProfile(currentProfile)];

    [outputTextView scrollRangeToVisible:NSMakeRange(outputTextView.string.length, 0)]; // 最下部までスクロール
    outputTextView.font = sourceFont;
}

- (void)appendOutputAndScroll:(NSString*)str quiet:(BOOL)quiet
{
    if (quiet) {
        return;
    }
	if (str) {
        [self performSelectorOnMainThread:@selector(appendOutputAndScrollOnMainThread:) withObject:str waitUntilDone:YES];
	}
}

- (void)prepareOutputTextView
{
    // NSTask からのアウトプットを受ける
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(readOutputData:)
                                               name:NSFileHandleReadCompletionNotification
                                             object:nil];
}

- (void)releaseOutputTextView
{
    // NSTask からのアウトプットの受け取りを中止
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:NSFileHandleReadCompletionNotification
                                                object:nil];
}

- (void)showOutputWindowOnMainThread
{
    if (mainWindow.isInFullScreenMode) {
        [outputWindow makeKeyAndOrderFront:nil];
        return;
    }
    
    if (outputWindow.isVisible) {
        [outputWindow makeKeyAndOrderFront:nil]; // 裏に隠れていても前面に持ってくる
        return;
    }
    
    outputWindowMenuItem.state = NSOnState;

    NSRect outputWindowRect = outputWindow.frame;
    NSScreen *screen = mainWindow.screen;
    
    CGFloat outputWindowNewOriginY = MAX(NSMinY(mainWindow.frame), NSMinY(screen.visibleFrame));
    CGFloat outputWindowNewHeight = MAX(NSMaxY(mainWindow.frame) - outputWindowNewOriginY, outputWindow.minSize.height);
    
    NSRect newRect = NSMakeRect(NSMaxX(mainWindow.frame),
                                outputWindowNewOriginY,
                                NSWidth(outputWindowRect),
                                outputWindowNewHeight);
    
    if (NSMaxX(newRect) <= NSMaxX(screen.visibleFrame)) { // 右に表示する余裕があるとき
        [outputWindow setFrame:newRect display:NO];
    } else {
        newRect = NSMakeRect(NSMinX(mainWindow.frame) - NSWidth(outputWindowRect),
                             outputWindowNewOriginY,
                             NSWidth(outputWindowRect),
                             outputWindowNewHeight);

        if (NSMinX(screen.visibleFrame) <= NSMinX(newRect)) { // 左に表示する余裕があるとき
            [outputWindow setFrame:newRect display:NO];
        } else { // 左右ともに表示する余裕がないとき
            // メインウィンドウを縮められる限り縮める
            CGFloat newWidth = MAX(NSMaxX(screen.visibleFrame) - NSWidth(outputWindowRect) - NSMinX(mainWindow.frame) - 1, mainWindow.minSize.width);
            newRect = NSMakeRect(NSMinX(mainWindow.frame),
                                 NSMinY(mainWindow.frame),
                                 newWidth,
                                 NSHeight(mainWindow.frame));
            [mainWindow setFrame:newRect display:YES animate:YES];

            // 画面右端までアウトプットウィンドウを表示
            newRect = NSMakeRect(NSMaxX(mainWindow.frame),
                                 outputWindowNewOriginY,
                                 NSMaxX(screen.visibleFrame) - NSMaxX(mainWindow.frame),
                                 outputWindowNewHeight);
            [outputWindow setFrame:newRect display:NO];
        }
    }

    [outputWindow makeKeyAndOrderFront:nil];
}

- (void)showOutputWindow
{
    [self performSelectorOnMainThread:@selector(showOutputWindowOnMainThread) withObject:nil waitUntilDone:YES];
}

- (void)showExtensionErrorOnMainThread
{
    runErrorPanel(localizedString(@"extensionErrMsg"));
}

- (void)showExtensionError
{
    [self performSelectorOnMainThread:@selector(showExtensionErrorOnMainThread) withObject:nil waitUntilDone:YES];
}

- (void)showNotFoundErrorOnMainThread:(NSString*)aPath
{
    runErrorPanel(localizedString(@"programNotFoundErrorMsg"), aPath);
}

- (void)showNotFoundError:(NSString*)aPath
{
    [self performSelectorOnMainThread:@selector(showNotFoundErrorOnMainThread:) withObject:aPath waitUntilDone:YES];
}

- (BOOL)latexExistsAtPath:(NSString*)latexPath dviDriverPath:(NSString*)dviDriverPath gsPath:(NSString*)gsPath
{
	NSFileManager *fileManager = NSFileManager.defaultManager;
	
	if (![fileManager fileExistsAtPath:latexPath.programPath]) {
		[self showNotFoundError:latexPath];
		return NO;
	}
	if (![fileManager fileExistsAtPath:dviDriverPath.programPath]) {
		[self showNotFoundError:dviDriverPath];
		return NO;
	}
	if (![fileManager fileExistsAtPath:gsPath.programPath]) {
		[self showNotFoundError:gsPath];
		return NO;
	}
	
	return YES;
}

- (BOOL)epstopdfExists;
{
	return YES;
}

- (BOOL)mudrawExists;
{
    return YES;
}

- (BOOL)pdftopsExists;
{
    return YES;
}

- (void)showFileFormatErrorOnMainThread:(NSString*)aPath
{
    runErrorPanel(localizedString(@"fileFormatErrorMsg"), aPath);
}

- (void)showFileFormatError:(NSString*)aPath
{
    [self performSelectorOnMainThread:@selector(showFileFormatErrorOnMainThread:) withObject:aPath waitUntilDone:YES];
}

- (void)showFileGenerationErrorOnMainThread:(NSString*)aPath
{
    runErrorPanel(localizedString(@"fileGenerationErrorMsg"), aPath);
}

- (void)showFileGenerationError:(NSString*)aPath
{
    [self performSelectorOnMainThread:@selector(showFileGenerationErrorOnMainThread:) withObject:aPath waitUntilDone:YES];
}

- (void)showExecErrorOnMainThread:(NSString*)command
{
    runErrorPanel(localizedString(@"execErrorMsg"), command);
}

- (void)showExecError:(NSString*)command
{
    [self performSelectorOnMainThread:@selector(showExecErrorOnMainThread:) withObject:command waitUntilDone:YES];
}

- (void)showCannotOverwriteErrorOnMainThread:(NSString*)path
{
    runErrorPanel(localizedString(@"cannotOverwriteErrorMsg"), path);
}

- (void)showCannotOverwriteError:(NSString*)path
{
    [self performSelectorOnMainThread:@selector(showCannotOverwriteErrorOnMainThread:) withObject:path waitUntilDone:YES];
}

- (void)showCannotCreateDirectoryErrorOnMainThread:(NSString*)dir
{
    runErrorPanel(localizedString(@"cannotCreateDirectoryErrorMsg"), dir);
}

- (void)showCannotCreateDirectoryError:(NSString*)dir
{
    [self performSelectorOnMainThread:@selector(showCannotCreateDirectoryErrorOnMainThread:) withObject:dir waitUntilDone:YES];
}

- (void)showCompileErrorOnMainThread
{
    runErrorPanel(localizedString(@"compileErrorMsg"));
}

- (void)showCompileError
{
    [self performSelectorOnMainThread:@selector(showCompileErrorOnMainThread) withObject:nil waitUntilDone:YES];
}

- (void)showImageSizeErrorOnMainThread
{
    runErrorPanel(localizedString(@"imageSizeErrorMsg"));
}

- (void)showImageSizeError
{
    [self performSelectorOnMainThread:@selector(showImageSizeErrorOnMainThread) withObject:nil waitUntilDone:YES];
}

- (void)showErrorsIgnoredWarningOnMainThread
{
    runWarningPanel(localizedString(@"errorsIgnoredWarning"));
}

- (void)showErrorsIgnoredWarning
{
    [self performSelectorOnMainThread:@selector(showErrorsIgnoredWarningOnMainThread) withObject:nil waitUntilDone:YES];
}

- (void)showPageSkippedWarning:(NSArray<NSNumber*>*)pages
{
    [self appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: [%@] ", localizedString(@"Warning")] quiet:NO];
    
    if (pages.count > 1) {
        [self appendOutputAndScroll:[NSString stringWithFormat:localizedString(@"pagesSkippedWarning"), [pages componentsJoinedByString:@", "]]
                              quiet:NO];
    } else {
        [self appendOutputAndScroll:[NSString stringWithFormat:localizedString(@"pageSkippedWarning"), pages[0].stringValue]
                              quiet:NO];
    }

    [self appendOutputAndScroll:@"\n" quiet:NO];
}

- (void)showWhitePageWarning:(NSArray<NSNumber*>*)pages
{
    [self appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: [%@] ", localizedString(@"Warning")] quiet:NO];
    
    if (pages.count > 1) {
        [self appendOutputAndScroll:[NSString stringWithFormat:localizedString(@"whitePagesWarning"), [pages componentsJoinedByString:@", "]]
                              quiet:NO];
    } else {
        [self appendOutputAndScroll:[NSString stringWithFormat:localizedString(@"whitePageWarning"), pages[0].stringValue]
                              quiet:NO];
    }
    
    [self appendOutputAndScroll:@"\n" quiet:NO];
}

- (void)previewFilesOnMainThread:(NSArray*)parameters
{
    NSArray<NSString*> *files = (NSArray<NSString*>*)(parameters[0]);
    NSString *app = (NSString*)(parameters[1]);
    
    if ([app isEqualToString:SVG_PREVIEWER] && ![NSFileManager.defaultManager fileExistsAtPath:SVG_PREVIEWER]) {
        NSAlert *alert = [NSAlert new];
        alert.messageText = localizedString(@"Warning");
        alert.informativeText = localizedString(@"Gapplin required");
        alert.alertStyle = NSAlertStyleInformational;
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:localizedString(@"Open in App Store")];
        NSModalResponse result = [alert runModal];
        
        if (result == NSAlertSecondButtonReturn) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:GAPPLIN_URL]];
        }

    } else {
        previewFiles(files, app);
    }
}

- (void)previewFiles:(NSArray<NSString*>*)files withApplication:(NSString*)app
{
    [self performSelectorOnMainThread:@selector(previewFilesOnMainThread:) withObject:@[files, app] waitUntilDone:NO];
}

- (void)printResult:(NSArray<NSString*>*)generatedFiles quiet:(BOOL)quiet
{
    NSUInteger count = generatedFiles.count;
    
    if (count > 1) {
        [self appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: %@\n", [NSString stringWithFormat:localizedString(@"generatedFilesMessage"), count]]
                              quiet:quiet];
    } else {
        [self appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: %@\n", [NSString stringWithFormat:localizedString(@"generatedFileMessage"), count]]
                              quiet:quiet];
    }
}

#pragma mark - プロファイルの読み書き関連
- (void)loadStringSettingForTextField:(NSTextField*)textField fromProfile:(Profile*)aProfile forKey:(NSString*)aKey
{
	NSString *tempStr = [aProfile stringForKey:aKey];
	
	if (tempStr) {
		textField.stringValue = tempStr;
        [self outputFilePathChanged:nil];
	}
}

- (void)loadNumberSettingForTextField:(NSTextField*)textField fromProfile:(Profile*)aProfile forKey:(NSString*)aKey
{
    NSNumber *tempNumber = (NSNumber*)(aProfile[aKey]);
    
    if (tempNumber) {
        textField.floatValue = tempNumber.floatValue;
    }
}

- (void)loadSettingForTextView:(NSTextView*)textView fromProfile:(Profile*)aProfile forKey:(NSString*)aKey
{
	NSString *tempStr = [aProfile stringForKey:aKey];
	
	if (tempStr) {
		textView.textStorage.mutableString.string = tempStr;
	}
}

- (void)adoptProfile:(Profile*)aProfile
{
    if (!aProfile) {
        return;
    }
    
    NSArray<NSString*> *keys = aProfile.allKeys;
	
	[self loadStringSettingForTextField:outputFileTextField fromProfile:aProfile forKey:OutputFileKey];

    if ([keys containsObject:AutoRestoreSourceKey]) {
        autoRestoreCheckBox.state = [aProfile integerForKey:AutoRestoreSourceKey];
    } else {
        autoRestoreCheckBox.state = NSOnState;
    }

	showOutputWindowCheckBox.state = [aProfile integerForKey:ShowOutputWindowKey];
    sendNotificationCheckBox.state = [aProfile integerForKey:SendNotificationKey];
	previewCheckBox.state = [aProfile integerForKey:PreviewKey];
	deleteTmpFileCheckBox.state = [aProfile integerForKey:DeleteTmpFileKey];

    if ([keys containsObject:EmbedSourceKey]) {
        embedSourceCheckBox.state = [aProfile integerForKey:EmbedSourceKey];
    } else {
        embedSourceCheckBox.state = NSOnState;
    }

    toClipboardCheckBox.state = [aProfile integerForKey:CopyToClipboardKey];

    autoPasteCheckBox.state = [aProfile integerForKey:AutoPasteKey];
    
    AutoPasteDestination autoPasteDestionation = (AutoPasteDestination)[aProfile integerForKey:AutoPasteDestinationKey];
    if (autoPasteDestionation == 0) {
        autoPasteDestionation = apWord;
    }
    [autoPasteDestinationPopUpButton selectItemWithTag:autoPasteDestionation];
    
	embedInIllustratorCheckBox.state = [aProfile integerForKey:EmbedInIllustratorKey];
	ungroupCheckBox.state = [aProfile integerForKey:UngroupKey];
	
	transparentCheckBox.state = [aProfile boolForKey:TransparentKey];
    plainTextCheckBox.state = [aProfile boolForKey:PlainTextKey];
	textPdfCheckBox.state = ![aProfile boolForKey:GetOutlineKey];
    deleteDisplaySizeCheckBox.state = [aProfile boolForKey:DeleteDisplaySizeKey];
    mergeOutputsCheckBox.state = [aProfile boolForKey:MergeOutputsKey];
    keepPageSizeCheckBox.state = [aProfile boolForKey:KeepPageSizeKey];

	ignoreErrorCheckBox.state = [aProfile boolForKey:IgnoreErrorKey];
	utfExportCheckBox.state = [aProfile boolForKey:UtfExportKey];
    workInInputFileDirectoryCheckBox.state = ([aProfile integerForKey:WorkingDirectoryTypeKey] == WorkingDirectoryFile) ? NSOnState : NSOffState;
	
	convertYenMarkMenuItem.state = [aProfile boolForKey:ConvertYenMarkKey];
    richTextMenuItem.state = [aProfile boolForKey:RichTextKey];

	flashInMovingCheckBox.state = [aProfile boolForKey:FlashInMovingKey];

	highlightContentCheckBox.state = [aProfile boolForKey:HighlightContentKey];
	beepCheckBox.state = [aProfile boolForKey:BeepKey];
	flashBackgroundCheckBox.state = [aProfile boolForKey:FlashBackgroundKey];

	checkBraceCheckBox.state = [aProfile boolForKey:CheckBraceKey];
	checkBracketCheckBox.state = [aProfile boolForKey:CheckBracketKey];
	checkSquareCheckBox.state = [aProfile boolForKey:CheckSquareBracketKey];
	checkParenCheckBox.state = [aProfile boolForKey:CheckParenKey];
    
    NSInteger tabWidth = [aProfile integerForKey:TabWidthKey];
    if (tabWidth > 0) {
        tabWidthTextField.integerValue = tabWidth;
    } else {
        tabWidthTextField.integerValue = 4;
    }
    [tabWidthStepper takeIntegerValueFrom:tabWidthTextField];

    if ([keys containsObject:TabIndentKey]) {
        tabIndentCheckBox.state = [aProfile integerForKey:TabIndentKey];
    } else {
        tabIndentCheckBox.state = NSOnState;
    }
    
    if ([keys containsObject:WrapLineKey]) {
        wrapLineCheckBox.state = [aProfile integerForKey:WrapLineKey];
    } else {
        wrapLineCheckBox.state = NSOnState;
    }

    //// 色設定の読み取り
    if ([keys containsObject:FillColorKey]) {
        fillColorWell.color = [aProfile colorForKey:FillColorKey];
    } else {
        fillColorWell.color = NSColor.whiteColor;
    }
    [fillColorWell saveColorTo:lastColorDict];

    
#pragma mark - 配色設定 (Light Mode)
    if ([keys containsObject:ForegroundColorForLightModeKey]) {
        lightModeForegroundColorWell.color = [aProfile colorForKey:ForegroundColorForLightModeKey];
    } else {
        lightModeForegroundColorWell.color = NSColor.defaultForegroundColorForLightMode;
    }
    [lightModeForegroundColorWell saveColorTo:lastColorDict];

    if ([keys containsObject:BackgroundColorForLightModeKey]) {
        lightModeBackgroundColorWell.color = [aProfile colorForKey:BackgroundColorForLightModeKey];
    } else {
        lightModeBackgroundColorWell.color = NSColor.defaultBackgroundColorForLightMode;
    }
    [lightModeBackgroundColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:CursorColorForLightModeKey]) {
        lightModeCursorColorWell.color = [aProfile colorForKey:CursorColorForLightModeKey];
    } else {
        lightModeCursorColorWell.color = NSColor.defaultCursorColorForLightMode;
    }
    [lightModeCursorColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:BraceColorForLightModeKey]) {
        lightModeBraceColorWell.color = [aProfile colorForKey:BraceColorForLightModeKey];
    } else {
        lightModeBraceColorWell.color = NSColor.defaultBraceColorForLightMode;
    }
    [lightModeBraceColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:CommentColorForLightModeKey]) {
        lightModeCommentColorWell.color = [aProfile colorForKey:CommentColorForLightModeKey];
    } else {
        lightModeCommentColorWell.color = NSColor.defaultCommentColorForLightMode;
    }
    [lightModeCommentColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:CommandColorForLightModeKey]) {
        lightModeCommandColorWell.color = [aProfile colorForKey:CommandColorForLightModeKey];
    } else {
        lightModeCommandColorWell.color = NSColor.defaultCommandColorForLightMode;
    }
    [lightModeCommandColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:InvisibleColorForLightModeKey]) {
        lightModeInvisibleColorWell.color = [aProfile colorForKey:InvisibleColorForLightModeKey];
    } else {
        lightModeInvisibleColorWell.color = NSColor.defaultInvisibleColorForLightMode;
    }
    [lightModeInvisibleColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:HighlightedBraceColorForLightModeKey]) {
        lightModeHighlightedBraceColorWell.color = [aProfile colorForKey:HighlightedBraceColorForLightModeKey];
    } else {
        lightModeHighlightedBraceColorWell.color = NSColor.defaultHighlightedBraceColorForLightMode;
    }
    [lightModeHighlightedBraceColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:EnclosedContentBackgroundColorForLightModeKey]) {
        lightModeEnclosedContentBackgroundColorWell.color = [aProfile colorForKey:EnclosedContentBackgroundColorForLightModeKey];
    } else {
        lightModeEnclosedContentBackgroundColorWell.color = NSColor.defaultEnclosedContentBackgroundColorForLightMode;
    }
    [lightModeEnclosedContentBackgroundColorWell saveColorTo:lastColorDict];

    if ([keys containsObject:FlashingBackgroundColorForLightModeKey]) {
        lightModeFlashingBackgroundColorWell.color = [aProfile colorForKey:FlashingBackgroundColorForLightModeKey];
    } else {
        lightModeFlashingBackgroundColorWell.color = NSColor.defaultFlashingBackgroundColorForLightMode;
    }
    [lightModeFlashingBackgroundColorWell saveColorTo:lastColorDict];

    if ([keys containsObject:ConsoleForegroundColorForLightModeKey]) {
        lightModeConsoleForegroundColorWell.color = [aProfile colorForKey:ConsoleForegroundColorForLightModeKey];
    } else {
        lightModeConsoleForegroundColorWell.color = NSColor.defaultConsoleForegroundColorForLightMode;
    }
    [lightModeConsoleForegroundColorWell saveColorTo:lastColorDict];

    if ([keys containsObject:ConsoleBackgroundColorForLightModeKey]) {
        lightModeConsoleBackgroundColorWell.color = [aProfile colorForKey:ConsoleBackgroundColorForLightModeKey];
    } else {
        lightModeConsoleBackgroundColorWell.color = NSColor.defaultConsoleBackgroundColorForLightMode;
    }
    [lightModeConsoleBackgroundColorWell saveColorTo:lastColorDict];

#pragma mark - 配色設定 (Dark Mode)
    if ([keys containsObject:ForegroundColorForDarkModeKey]) {
        darkModeForegroundColorWell.color = [aProfile colorForKey:ForegroundColorForDarkModeKey];
    } else {
        darkModeForegroundColorWell.color = NSColor.defaultForegroundColorForDarkMode;
    }
    [darkModeForegroundColorWell saveColorTo:lastColorDict];

    if ([keys containsObject:BackgroundColorForDarkModeKey]) {
        darkModeBackgroundColorWell.color = [aProfile colorForKey:BackgroundColorForDarkModeKey];
    } else {
        darkModeBackgroundColorWell.color = NSColor.defaultBackgroundColorForDarkMode;
    }
    [darkModeBackgroundColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:CursorColorForDarkModeKey]) {
        darkModeCursorColorWell.color = [aProfile colorForKey:CursorColorForDarkModeKey];
    } else {
        darkModeCursorColorWell.color = NSColor.defaultCursorColorForDarkMode;
    }
    [darkModeCursorColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:BraceColorForDarkModeKey]) {
        darkModeBraceColorWell.color = [aProfile colorForKey:BraceColorForDarkModeKey];
    } else {
        darkModeBraceColorWell.color = NSColor.defaultBraceColorForDarkMode;
    }
    [darkModeBraceColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:CommentColorForDarkModeKey]) {
        darkModeCommentColorWell.color = [aProfile colorForKey:CommentColorForDarkModeKey];
    } else {
        darkModeCommentColorWell.color = NSColor.defaultCommentColorForDarkMode;
    }
    [darkModeCommentColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:CommandColorForDarkModeKey]) {
        darkModeCommandColorWell.color = [aProfile colorForKey:CommandColorForDarkModeKey];
    } else {
        darkModeCommandColorWell.color = NSColor.defaultCommandColorForDarkMode;
    }
    [darkModeCommandColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:InvisibleColorForDarkModeKey]) {
        darkModeInvisibleColorWell.color = [aProfile colorForKey:InvisibleColorForDarkModeKey];
    } else {
        darkModeInvisibleColorWell.color = NSColor.defaultInvisibleColorForDarkMode;
    }
    [darkModeInvisibleColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:HighlightedBraceColorForDarkModeKey]) {
        darkModeHighlightedBraceColorWell.color = [aProfile colorForKey:HighlightedBraceColorForDarkModeKey];
    } else {
        darkModeHighlightedBraceColorWell.color = NSColor.defaultHighlightedBraceColorForDarkMode;
    }
    [darkModeHighlightedBraceColorWell saveColorTo:lastColorDict];

    if ([keys containsObject:EnclosedContentBackgroundColorForDarkModeKey]) {
        darkModeEnclosedContentBackgroundColorWell.color = [aProfile colorForKey:EnclosedContentBackgroundColorForDarkModeKey];
    } else {
        darkModeEnclosedContentBackgroundColorWell.color = NSColor.defaultEnclosedContentBackgroundColorForDarkMode;
    }
    [darkModeEnclosedContentBackgroundColorWell saveColorTo:lastColorDict];

    if ([keys containsObject:FlashingBackgroundColorForDarkModeKey]) {
        darkModeFlashingBackgroundColorWell.color = [aProfile colorForKey:FlashingBackgroundColorForDarkModeKey];
    } else {
        darkModeFlashingBackgroundColorWell.color = NSColor.defaultFlashingBackgroundColorForDarkMode;
    }
    [darkModeFlashingBackgroundColorWell saveColorTo:lastColorDict];

    if ([keys containsObject:ConsoleForegroundColorForDarkModeKey]) {
        darkModeConsoleForegroundColorWell.color = [aProfile colorForKey:ConsoleForegroundColorForDarkModeKey];
    } else {
        darkModeConsoleForegroundColorWell.color = NSColor.defaultConsoleForegroundColorForDarkMode;
    }
    [darkModeConsoleForegroundColorWell saveColorTo:lastColorDict];

    if ([keys containsObject:ConsoleBackgroundColorForDarkModeKey]) {
        darkModeConsoleBackgroundColorWell.color = [aProfile colorForKey:ConsoleBackgroundColorForDarkModeKey];
    } else {
        darkModeConsoleBackgroundColorWell.color = NSColor.defaultConsoleBackgroundColorForDarkMode;
    }
    [darkModeConsoleBackgroundColorWell saveColorTo:lastColorDict];

#pragma mark -
    
    if ([keys containsObject:ColorPalleteColorKey]) {
        colorPalleteColorWell.color = [aProfile colorForKey:ColorPalleteColorKey];
    } else {
        colorPalleteColorWell.color = NSColor.redColor;
    }
    [colorPalleteColorWell saveColorTo:lastColorDict];
    
    if ([keys containsObject:MakeatletterEnabledKey]) {
        makeatletterEnabledCheckBox.state = [aProfile boolForKey:MakeatletterEnabledKey];
    } else {
        makeatletterEnabledCheckBox.state = NSOnState;
    }

	autoCompleteMenuItem.state = [aProfile boolForKey:AutoCompleteKey];
    autoIndentMenuItem.state = [aProfile boolForKey:AutoIndentKey];
	showTabCharacterCheckBox.state = [aProfile boolForKey:ShowTabCharacterKey];
	showSpaceCharacterCheckBox.state = [aProfile boolForKey:ShowSpaceCharacterKey];
	showFullwidthSpaceCharacterCheckBox.state = [aProfile boolForKey:ShowFullwidthSpaceCharacterKey];
	showNewLineCharacterCheckBox.state = [aProfile boolForKey:ShowNewLineCharacterKey];
	guessCompilationButton.state = [aProfile boolForKey:GuessCompilationKey];
    
    NSString *encoding = [aProfile stringForKey:EncodingKey];
    if (encoding) {
        EncodingTag tag = NONE;
        
        if ([encoding isEqualToString:PTEX_ENCODING_UTF8] || [encoding isEqualToString:@"uptex"]) { // "uptex" は旧バージョンからの設定引き継ぎ用
            tag = UTF8;
        } else if ([encoding isEqualToString:PTEX_ENCODING_SJIS]) {
            tag = SJIS;
        } else if ([encoding isEqualToString:PTEX_ENCODING_JIS]) {
            tag = JIS;
        } else if ([encoding isEqualToString:PTEX_ENCODING_EUC]) {
            tag = EUC;
        }
        
        [encodingPopUpButton selectItemWithTag:tag];
    }
	
	[self loadStringSettingForTextField:latexPathTextField fromProfile:aProfile forKey:LatexPathKey];
	[self loadStringSettingForTextField:dviDriverPathTextField fromProfile:aProfile forKey:DviDriverPathKey];
	[self loadStringSettingForTextField:gsPathTextField fromProfile:aProfile forKey:GsPathKey];
	
	[self loadNumberSettingForTextField:resolutionTextField fromProfile:aProfile forKey:ResolutionKey];
    [self loadNumberSettingForTextField:dpiTextField fromProfile:aProfile forKey:DPIKey];
    [self loadNumberSettingForTextField:leftMarginTextField fromProfile:aProfile forKey:LeftMarginKey];
    [self loadNumberSettingForTextField:rightMarginTextField fromProfile:aProfile forKey:RightMarginKey];
    [self loadNumberSettingForTextField:topMarginTextField fromProfile:aProfile forKey:TopMarginKey];
    [self loadNumberSettingForTextField:bottomMarginTextField fromProfile:aProfile forKey:BottomMarginKey];
    
    [resolutionStepper takeFloatValueFrom:resolutionTextField];
    [dpiStepper takeFloatValueFrom:dpiTextField];
    [leftMarginStepper takeIntValueFrom:leftMarginTextField];
    [rightMarginStepper takeIntValueFrom:rightMarginTextField];
    [topMarginStepper takeIntValueFrom:topMarginTextField];
    [bottomMarginStepper takeIntValueFrom:bottomMarginTextField];
    
    numberOfCompilationTextField.integerValue = MAX(1, [aProfile integerForKey:NumberOfCompilationKey]);
    [numberOfCompilationStepper takeIntegerValueFrom:numberOfCompilationTextField];
    
    NSInteger unitTag = [aProfile integerForKey:UnitKey];
    [unitMatrix selectCellWithTag:unitTag];
    
    NSInteger priorityTag = [aProfile integerForKey:PriorityKey];
    [priorityMatrix selectCellWithTag:priorityTag];

    if ([keys containsObject:AutoDetectionTargetKey]) {
        [autoDetectionTargetMatrix selectCellWithTag:[aProfile integerForKey:AutoDetectionTargetKey]];
    }

    if ([keys containsObject:SpaceCharacterKindKey]) {
        [spaceCharacterKindMatrix selectCellWithTag:[aProfile integerForKey:SpaceCharacterKindKey]];
    }

    if ([keys containsObject:FullwidthSpaceCharacterKindKey]) {
        [fullwidthSpaceCharacterKindMatrix selectCellWithTag:[aProfile integerForKey:FullwidthSpaceCharacterKindKey]];
    }

    if ([keys containsObject:ReturnCharacterKindKey]) {
        [returnCharacterKindMatrix selectCellWithTag:[aProfile integerForKey:ReturnCharacterKindKey]];
    }

    if ([keys containsObject:TabCharacterKindKey]) {
        [tabCharacterKindMatrix selectCellWithTag:[aProfile integerForKey:TabCharacterKindKey]];
    }

    if ([keys containsObject:PageBoxKey]) {
        [pageBoxMatrix selectCellWithTag:[aProfile integerForKey:PageBoxKey]];
    }

    if ([keys containsObject:DelayKey]) {
        delayTextField.floatValue = MAX(0, [aProfile floatForKey:DelayKey]);
        [delayStepper takeFloatValueFrom:delayTextField];
    }
    
    if ([keys containsObject:LoopCountKey]) {
        loopCountTextField.integerValue = MAX(0, [aProfile integerForKey:LoopCountKey]);
        [loopCountStepper takeIntValueFrom:loopCountTextField];
    }
    
    if ([keys containsObject:CommandCompletionKeyKey]) {
        NSInteger commandCompletionKeyTag = [aProfile integerForKey:CommandCompletionKeyKey];
        [commandCompletionKeyMatrix selectCellWithTag:commandCompletionKeyTag];
    }

    [self invisibleCharacterKindChanged:nil];

    [self loadSettingForTextView:preambleTextView fromProfile:aProfile forKey:PreambleKey];
    [self refreshOutputTextViewUsingProfile:aProfile];

    NSFont *aFont = [NSFont fontWithName:[aProfile stringForKey:SourceFontNameKey] size:[aProfile floatForKey:SourceFontSizeKey]];
    if (aFont) {
        sourceFont = aFont;
        sourceTextView.font = aFont;
        preambleTextView.font = aFont;
        outputTextView.font = aFont;
        [self setupFontTextField:aFont];
    } else {
        [self loadDefaultFont];
    }
    [sourceTextView fixupTabs];
    [sourceTextView refreshWordWrap];
    
    [preambleTextView colorizeText];
    [preambleTextView fixupTabs];
    [preambleTextView refreshWordWrap];


    // 不可視文字表示の選択肢のフォントを更新
    NSFont *displayFont = [NSFont fontWithName:sourceFont.fontName size:spaceCharacterKindButton.font.pointSize];
    [self setInvisibleCharacterFont:displayFont];
    
    NSString *inputSourceFilePath = [aProfile stringForKey:InputSourceFilePathKey];
    if (inputSourceFilePath) {
        inputSourceFileTextField.stringValue = inputSourceFilePath;
    }
    
    InputMethod inputMethod = (InputMethod)[aProfile integerForKey:InputMethodKey];
    switch (inputMethod) {
        case DIRECT:
            [self sourceSettingChanged:directInputButton];
            break;
        case FROMFILE:
            [self sourceSettingChanged:inputSourceFileButton];
            break;
        default:
            break;
    }
}

- (void)refreshOutputTextViewUsingProfile:(Profile*)aProfile
{
    if (!aProfile) {
        aProfile = [self currentProfile];
    }
    
    [self refreshTextView:outputTextView
          foregroundColor:consoleForegroundColorInProfile(aProfile)
          backgroundColor:consoleBackgroundColorInProfile(aProfile)
              cursorColor:cursorColorInProfile(aProfile)];
}

- (void)setInvisibleCharacterFont:(NSFont*)font
{
    [spaceCharacterKindMatrix setCellFont:font];
    [fullwidthSpaceCharacterKindMatrix setCellFont:font];
    [returnCharacterKindMatrix setCellFont:font];
    [tabCharacterKindMatrix setCellFont:font];
    
    spaceCharacterKindButton.font = font;
    fullwidthSpaceCharacterKindButton.font = font;
    returnCharacterKindButton.font = font;
    tabCharacterKindButton.font = font;
}

- (BOOL)adoptProfileDuringLauching
{
	Profile *aProfile = [profileController profileForName:AutoSavedProfileName];
    if (!aProfile) {
        return NO;
    }
	
	[self adoptProfile:aProfile];

	float x, y, mainWindowWidth, mainWindowHeight; 
	x = [aProfile floatForKey:XKey];
	y = [aProfile floatForKey:YKey];
	mainWindowWidth = [aProfile floatForKey:MainWindowWidthKey];
	mainWindowHeight = [aProfile floatForKey:MainWindowHeightKey];
	
	if (x!=0 && y!=0 && mainWindowWidth!=0 && mainWindowHeight!=0) {
		[mainWindow setFrame:NSMakeRect(x, y, mainWindowWidth, mainWindowHeight) display:YES];
	}
    
    BOOL autoRestore = [aProfile boolForKey:AutoRestoreSourceKey];
    NSString *body = [aProfile stringForKey:SourceBodyKey];

    if (autoRestore && body) {
        [sourceTextView replaceEntireContentsWithString:body];
    }
    
	return YES;
}



- (MutableProfile*)currentProfile
{
	MutableProfile *currentProfile = [MutableProfile dictionary];
	@try {
        currentProfile[TeX2imgVersionKey] = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        
        currentProfile[XKey] = @(NSMinX(mainWindow.frame));
        currentProfile[YKey] = @(NSMinY(mainWindow.frame));
        currentProfile[MainWindowWidthKey] = @(NSWidth(mainWindow.frame));
        currentProfile[MainWindowHeightKey] = @(NSHeight(mainWindow.frame));
        currentProfile[OutputFileKey] = outputFileTextField.stringValue;
        
        currentProfile[AutoRestoreSourceKey] = @(autoRestoreCheckBox.state);
        
        currentProfile[ShowOutputWindowKey] = @(showOutputWindowCheckBox.state);
        currentProfile[SendNotificationKey] = @(sendNotificationCheckBox.state);
        currentProfile[PreviewKey] = @(previewCheckBox.state);
        currentProfile[DeleteTmpFileKey] = @(deleteTmpFileCheckBox.state);
        
        currentProfile[EmbedSourceKey] = @(embedSourceCheckBox.state);
        currentProfile[CopyToClipboardKey] = @(toClipboardCheckBox.state);
        currentProfile[AutoPasteKey] = @(autoPasteCheckBox.state);
        currentProfile[AutoPasteDestinationKey] = @(autoPasteDestinationPopUpButton.selectedTag);
        currentProfile[EmbedInIllustratorKey] = @(embedInIllustratorCheckBox.state);
        currentProfile[UngroupKey] = @(ungroupCheckBox.state);
        
        currentProfile[TransparentKey] = @(transparentCheckBox.state);
        currentProfile[PlainTextKey] = @(plainTextCheckBox.state);
        currentProfile[GetOutlineKey] = @(!textPdfCheckBox.state);
        currentProfile[DeleteDisplaySizeKey] = @(deleteDisplaySizeCheckBox.state);
        currentProfile[MergeOutputsKey] = @(mergeOutputsCheckBox.state);
        currentProfile[KeepPageSizeKey] = @(keepPageSizeCheckBox.state);
        currentProfile[IgnoreErrorKey] = @(ignoreErrorCheckBox.state);
        currentProfile[UtfExportKey] = @(utfExportCheckBox.state);
        
        currentProfile[LatexPathKey] = latexPathTextField.stringValue;
        currentProfile[DviDriverPathKey] = dviDriverPathTextField.stringValue;
        currentProfile[GsPathKey] = gsPathTextField.stringValue;
        currentProfile[GuessCompilationKey] = @(guessCompilationButton.state);
        currentProfile[NumberOfCompilationKey] = @(numberOfCompilationTextField.integerValue);
        
        currentProfile[ResolutionKey] = @(resolutionTextField.floatValue);
        currentProfile[DPIKey] = @(dpiTextField.floatValue);
        currentProfile[LeftMarginKey] = @(leftMarginTextField.integerValue);
        currentProfile[RightMarginKey] = @(rightMarginTextField.integerValue);
        currentProfile[TopMarginKey] = @(topMarginTextField.integerValue);
        currentProfile[BottomMarginKey] = @(bottomMarginTextField.integerValue);
        
        NSInteger tabWidth = tabWidthTextField.integerValue;
        currentProfile[TabWidthKey] = @((tabWidth > 0) ? tabWidth : 4);
        
        currentProfile[TabIndentKey] = @(tabIndentCheckBox.state);
        
        currentProfile[WrapLineKey] = @(wrapLineCheckBox.state);
        
        currentProfile[UnitKey] = @(unitMatrix.selectedTag);
        currentProfile[PriorityKey] = @(priorityMatrix.selectedTag);
        
        currentProfile[CommandCompletionKeyKey] = @(commandCompletionKeyMatrix.selectedTag);

        currentProfile[AutoDetectionTargetKey] = @(autoDetectionTargetMatrix.selectedTag);

        currentProfile[SpaceCharacterKindKey] = @(spaceCharacterKindMatrix.selectedTag);
        currentProfile[FullwidthSpaceCharacterKindKey] = @(fullwidthSpaceCharacterKindMatrix.selectedTag);
        currentProfile[ReturnCharacterKindKey] = @(returnCharacterKindMatrix.selectedTag);
        currentProfile[TabCharacterKindKey] = @(tabCharacterKindMatrix.selectedTag);

        currentProfile[PageBoxKey] = @(pageBoxMatrix.selectedTag);
        
        currentProfile[DelayKey] = @(delayTextField.floatValue);
        currentProfile[LoopCountKey] = @(loopCountTextField.integerValue);

        currentProfile[ConvertYenMarkKey] = @(convertYenMarkMenuItem.state);
        currentProfile[RichTextKey] = @(richTextMenuItem.state);
        currentProfile[FlashInMovingKey] = @(flashInMovingCheckBox.state);
        currentProfile[HighlightContentKey] = @(highlightContentCheckBox.state);
        currentProfile[BeepKey] = @(beepCheckBox.state);
        currentProfile[FlashBackgroundKey] = @(flashBackgroundCheckBox.state);
        currentProfile[CheckBraceKey] = @(checkBraceCheckBox.state);
        currentProfile[CheckBracketKey] = @(checkBracketCheckBox.state);
        currentProfile[CheckSquareBracketKey] = @(checkSquareCheckBox.state);
        currentProfile[CheckParenKey] = @(checkParenCheckBox.state);
        currentProfile[AutoCompleteKey] = @(autoCompleteMenuItem.state);
        currentProfile[AutoIndentKey] = @(autoIndentMenuItem.state);
        currentProfile[ShowTabCharacterKey] = @(showTabCharacterCheckBox.state);
        currentProfile[ShowSpaceCharacterKey] = @(showSpaceCharacterCheckBox.state);
        currentProfile[ShowFullwidthSpaceCharacterKey] = @(showFullwidthSpaceCharacterCheckBox.state);
        currentProfile[ShowNewLineCharacterKey] = @(showNewLineCharacterCheckBox.state);
        currentProfile[SourceFontNameKey] = sourceFont.fontName;
        currentProfile[SourceFontSizeKey] = @(sourceFont.pointSize);
        
        currentProfile[PreambleKey] = [NSString stringWithString:preambleTextView.textStorage.string]; // stringWithString は必須
        currentProfile[SourceBodyKey] = [NSString stringWithString:sourceTextView.textStorage.string]; // stringWithString は必須
        
        currentProfile[InputMethodKey] = (directInputButton.state == NSOnState) ? @(DIRECT) : @(FROMFILE);
        currentProfile[InputSourceFilePathKey] = inputSourceFileTextField.stringValue;
        
        currentProfile[WorkingDirectoryTypeKey] = (workInInputFileDirectoryCheckBox.state == NSOnState) ? @(WorkingDirectoryFile) : @(WorkingDirectoryTmp);
        currentProfile[WorkingDirectoryPathKey] = (([currentProfile integerForKey:WorkingDirectoryTypeKey] == WorkingDirectoryFile) && ([currentProfile integerForKey:InputMethodKey] == FROMFILE)) ?
        [currentProfile stringForKey:InputSourceFilePathKey].stringByDeletingLastPathComponent : NSTemporaryDirectory();

        currentProfile[FillColorKey] = fillColorWell.color.serializedString;

        currentProfile[ForegroundColorForLightModeKey] = lightModeForegroundColorWell.color.serializedString;
        currentProfile[BackgroundColorForLightModeKey] = lightModeBackgroundColorWell.color.serializedString;
        currentProfile[CursorColorForLightModeKey] = lightModeCursorColorWell.color.serializedString;
        currentProfile[BraceColorForLightModeKey] = lightModeBraceColorWell.color.serializedString;
        currentProfile[CommentColorForLightModeKey] = lightModeCommentColorWell.color.serializedString;
        currentProfile[CommandColorForLightModeKey] = lightModeCommandColorWell.color.serializedString;
        currentProfile[InvisibleColorForLightModeKey] = lightModeInvisibleColorWell.color.serializedString;
        currentProfile[HighlightedBraceColorForLightModeKey] = lightModeHighlightedBraceColorWell.color.serializedString;
        currentProfile[EnclosedContentBackgroundColorForLightModeKey] = lightModeEnclosedContentBackgroundColorWell.color.serializedString;
        currentProfile[FlashingBackgroundColorForLightModeKey] = lightModeFlashingBackgroundColorWell.color.serializedString;
        currentProfile[ConsoleForegroundColorForLightModeKey] = lightModeConsoleForegroundColorWell.color.serializedString;
        currentProfile[ConsoleBackgroundColorForLightModeKey] = lightModeConsoleBackgroundColorWell.color.serializedString;

        currentProfile[ForegroundColorForDarkModeKey] = darkModeForegroundColorWell.color.serializedString;
        currentProfile[BackgroundColorForDarkModeKey] = darkModeBackgroundColorWell.color.serializedString;
        currentProfile[CursorColorForDarkModeKey] = darkModeCursorColorWell.color.serializedString;
        currentProfile[BraceColorForDarkModeKey] = darkModeBraceColorWell.color.serializedString;
        currentProfile[CommentColorForDarkModeKey] = darkModeCommentColorWell.color.serializedString;
        currentProfile[CommandColorForDarkModeKey] = darkModeCommandColorWell.color.serializedString;
        currentProfile[InvisibleColorForDarkModeKey] = darkModeInvisibleColorWell.color.serializedString;
        currentProfile[HighlightedBraceColorForDarkModeKey] = darkModeHighlightedBraceColorWell.color.serializedString;
        currentProfile[EnclosedContentBackgroundColorForDarkModeKey] = darkModeEnclosedContentBackgroundColorWell.color.serializedString;
        currentProfile[FlashingBackgroundColorForDarkModeKey] = darkModeFlashingBackgroundColorWell.color.serializedString;
        currentProfile[ConsoleForegroundColorForDarkModeKey] = darkModeConsoleForegroundColorWell.color.serializedString;
        currentProfile[ConsoleBackgroundColorForDarkModeKey] = darkModeConsoleBackgroundColorWell.color.serializedString;

        currentProfile[MakeatletterEnabledKey] = @(makeatletterEnabledCheckBox.state);
        
        currentProfile[ColorPalleteColorKey] = colorPalleteColorWell.color.serializedString;
    }
    @catch (NSException *e) {
    }
    
    switch (encodingPopUpButton.selectedTag) {
        case UTF8:
            currentProfile[EncodingKey] = PTEX_ENCODING_UTF8;
            break;
        case SJIS:
            currentProfile[EncodingKey] = PTEX_ENCODING_SJIS;
            break;
        case JIS:
            currentProfile[EncodingKey] = PTEX_ENCODING_JIS;
            break;
        case EUC:
            currentProfile[EncodingKey] = PTEX_ENCODING_EUC;
            break;
        default:
            currentProfile[EncodingKey] = PTEX_ENCODING_NONE;
            break;
    }
	
	return currentProfile;
}

#pragma mark - プリアンブルの管理
- (void)addTemplateMenuItem:(NSString*)filename atDirectory:(NSString*)directory toMenu:(NSMenu*)menu atIndex:(NSNumber*)index
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *fullPath = [directory stringByAppendingPathComponent:filename];
    
    if ([filename.pathExtension isEqualToString:@"tex"]) {
        NSString *title = filename.stringByDeletingPathExtension;
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(adoptPreambleTemplate:) keyEquivalent:@""];
        menuItem.target = self;
        menuItem.toolTip = fullPath; // tooltip文字列の部分にフルパスを保持
        if (index) {
            [menu insertItem:menuItem atIndex:index.integerValue];
        } else {
            [menu addItem:menuItem];
        }
    }
    
    BOOL isDirectory;
    if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
        NSMenuItem *itemWithSubmenu = [[NSMenuItem alloc] initWithTitle:filename action:nil keyEquivalent:@""];
        NSMenu *submenu = [NSMenu new];
        submenu.autoenablesItems = NO;
        [self constructTemplatePopupRecursivelyAtDirectory:[directory stringByAppendingPathComponent:filename] parentMenu:submenu];
        itemWithSubmenu.submenu = submenu;
        if (index) {
            [menu insertItem:itemWithSubmenu atIndex:index.integerValue];
        } else {
            [menu addItem:itemWithSubmenu];
        }
    }
}

- (void)constructTemplatePopup:(id)sender
{
    NSMenu *menu = templatePopupButton.menu;
    
    while (menu.numberOfItems > 5) { // この数はテンプレートメニューの初期項目数
        [menu removeItemAtIndex:1];
    }
    
    NSString *templateDirectoryPath = self.templateDirectoryPath;
    NSEnumerator<NSString*> *enumerator = [NSFileManager.defaultManager contentsOfDirectoryAtPath:templateDirectoryPath error:nil].reverseObjectEnumerator;
    
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        [self addTemplateMenuItem:filename atDirectory:templateDirectoryPath toMenu:menu atIndex:@(1)];
    }
}

- (void)constructTemplatePopupRecursivelyAtDirectory:(NSString*)directory parentMenu:(NSMenu*)menu
{
    NSArray<NSString*> *files = [NSFileManager.defaultManager contentsOfDirectoryAtPath:directory error:nil];
    [files enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger idx, BOOL *stop) {
        [self addTemplateMenuItem:filename atDirectory:directory toMenu:menu atIndex:nil];
    }];
}

- (void)adoptPreambleTemplate:(id)sender
{
    NSString *templatePath;
    
    if ([sender isKindOfClass:NSMenuItem.class]) { // プリアンブル選択ポップアップがクリックされた場合
        templatePath = ((NSMenuItem*)sender).toolTip; // toolTip 文字列に保管されているフルパスを取得
    } else if ([sender isKindOfClass:NSString.class]) { // フルパスが直接引数に指定された場合
        templatePath = sender;
    } else {
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:templatePath];
    NSStringEncoding detectedEncoding;
    NSString *contents = [NSString stringWithAutoEncodingDetectionOfData:data detectedEncoding:&detectedEncoding];

    if (contents) {
        NSString *message = [NSString stringWithFormat:@"%@\n\n%@", localizedString(@"resotrePreambleMsg"), [contents stringByReplacingOccurrencesOfString:@"%" withString:@"%%"]];
        
        if (runConfirmPanel(message)) {
            [preambleTextView replaceEntireContentsWithString:contents];
        }
    } else {
        runErrorPanel(localizedString(@"cannotReadErrorMsg"), templatePath);
        return;
    }
}

- (NSString*)templateDirectoryPath
{
    NSString *applicationSupportDirectoryPath = NSFileManager.defaultManager.applicationSupportDirectory;
    return [applicationSupportDirectoryPath stringByAppendingPathComponent:TemplateDirectoryName];
}

- (IBAction)restoreDefaultTemplates:(id)sender
{
    if (runConfirmPanel(localizedString(@"restoreTemplatesConfirmationMsg"))) {
        [self restoreDefaultTemplatesLogic];
    }
}

- (void)restoreDefaultTemplatesLogic
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *templateDirectoryPath = self.templateDirectoryPath;
    NSString *originalTemplateDirectory = [NSBundle.mainBundle pathForResource:TemplateDirectoryName ofType:nil];
    
    if (![fileManager fileExistsAtPath:templateDirectoryPath]) {
        [fileManager createDirectoryAtPath:templateDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    system([NSString stringWithFormat:@"/bin/cp -p \"%@\"/* \"%@\"", originalTemplateDirectory, self.templateDirectoryPath].UTF8String);
}


#pragma mark - デリゲート・ノティフィケーションのコールバック
- (void)awakeFromNib
{
    // 通知の設定
    userNotificationDelegate = [UserNotificationDelegate new];
    
    if (@available(macOS 10.14, *)) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = userNotificationDelegate;
    } else {
        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = userNotificationDelegate;
    }
    
    lastColorDict = [NSMutableDictionary<NSString*,NSColor*> dictionary];

	// ノティフィケーションの設定
	NSNotificationCenter *aCenter = NSNotificationCenter.defaultCenter;
	
	// アプリケーションがアクティブになったときにメインウィンドウを表示
	[aCenter addObserver:self
				selector:@selector(showMainWindow:)
					name:NSApplicationDidBecomeActiveNotification
				  object:NSApp];
	
	// プログラム終了時に設定保存実行
	[aCenter addObserver:self
				selector:@selector(applicationWillTerminate:)
					name:NSApplicationWillTerminateNotification
				  object:NSApp];
	
    // 出力ウィンドウが閉じられるときにメニューのチェックを外す
    [aCenter addObserver:self
                selector:@selector(uncheckOutputWindowMenuItem:)
                    name:NSWindowWillCloseNotification
                  object:outputWindow];

	// プリアンブルウィンドウが閉じられるときにメニューのチェックを外す
	[aCenter addObserver:self
				selector:@selector(uncheckPreambleWindowMenuItem:)
					name:NSWindowWillCloseNotification
				  object:preambleWindow];

    // 色入力支援パレットが閉じられるときにメニューのチェックを外す
    [aCenter addObserver:self
                selector:@selector(uncheckColorPalleteWindowMenuItem:)
                    name:NSWindowWillCloseNotification
                  object:colorPalleteWindow];
	
	// メインウィンドウが閉じられるときに他のウィンドウも閉じる
	[aCenter addObserver:self
				selector:@selector(closeOtherWindows:)
					name:NSWindowWillCloseNotification
				  object:mainWindow];
	
	// テキストビューのカーソル移動の通知を受ける
	[aCenter addObserver:sourceTextView
				selector:@selector(textViewDidChangeSelection:)
					name:NSTextViewDidChangeSelectionNotification
				  object:sourceTextView];

	[aCenter addObserver:preambleTextView
				selector:@selector(textViewDidChangeSelection:)
					name:NSTextViewDidChangeSelectionNotification
				  object:preambleTextView];
    
    // テンプレートボタンのポップアップ寸前
    [aCenter addObserver:self
                selector:@selector(constructTemplatePopup:)
                    name:NSPopUpButtonWillPopUpNotification
                  object:templatePopupButton];

    // ウィンドウがアクティブになったときにその通知を受け取る
    [aCenter addObserver:self
                selector:@selector(otherWindowsDidBecomeKey:)
                    name:NSWindowDidBecomeKeyNotification
                  object:mainWindow];
    [aCenter addObserver:self
                selector:@selector(otherWindowsDidBecomeKey:)
                    name:NSWindowDidBecomeKeyNotification
                  object:outputWindow];
    [aCenter addObserver:self
                selector:@selector(otherWindowsDidBecomeKey:)
                    name:NSWindowDidBecomeKeyNotification
                  object:preambleWindow];
    [aCenter addObserver:self
                selector:@selector(preferenceWindowDidBecomeKey:)
                    name:NSWindowDidBecomeKeyNotification
                  object:preferenceWindow];
    [aCenter addObserver:self
                selector:@selector(colorPalleteWindowDidBecomeKey:)
                    name:NSWindowDidBecomeKeyNotification
                  object:colorPalleteWindow];
    
    // 数値を記入した NSTextField の値を変更したときに直ちに関連づけられたステッパーに反映されるように
    // ただし，resolutionTextField は，小数点値を反映させるために対象外としている
    [aCenter addObserver:self
                selector:@selector(refreshRelatedStepperValue:)
                    name:NSControlTextDidChangeNotification
                  object:dpiTextField];
    [aCenter addObserver:self
                selector:@selector(refreshRelatedStepperValue:)
                    name:NSControlTextDidChangeNotification
                  object:leftMarginTextField];
    [aCenter addObserver:self
                selector:@selector(refreshRelatedStepperValue:)
                    name:NSControlTextDidChangeNotification
                  object:rightMarginTextField];
    [aCenter addObserver:self
                selector:@selector(refreshRelatedStepperValue:)
                    name:NSControlTextDidChangeNotification
                  object:topMarginTextField];
    [aCenter addObserver:self
                selector:@selector(refreshRelatedStepperValue:)
                    name:NSControlTextDidChangeNotification
                  object:bottomMarginTextField];
    [aCenter addObserver:self
                selector:@selector(refreshRelatedStepperValue:)
                    name:NSControlTextDidChangeNotification
                  object:numberOfCompilationTextField];

    // タブ幅の変更
    [aCenter addObserver:self
                selector:@selector(refreshTextView:)
                    name:NSControlTextDidChangeNotification
                  object:tabWidthTextField];

    // 出力ファイルパスの変更
    [aCenter addObserver:self
                selector:@selector(outputFilePathChanged:)
                    name:NSControlTextDidChangeNotification
                  object:outputFileTextField];

	// デフォルトのアウトプットファイルのパスをセット
	outputFileTextField.stringValue = [NSString stringWithFormat:@"%@/Desktop/equation.eps", NSHomeDirectory()];

    // 色パレットが表示されていれば消す
    [self closeColorPanel];

    // フォントパネルが表示されていれば消す
    [self closeFontPanel];

    lastActiveWindow = mainWindow;
    
    // 色入力支援パレットにデフォルトの文字を入れる
    colorPalleteColorWell.color = NSColor.redColor;
    [self colorPalleteColorSet:colorPalleteColorWell];
    
    // ポップアップ内の NSMatrix の色設定
    [autoDetectionTargetMatrix setCellColor:NSColor.textColor];
    [spaceCharacterKindMatrix setCellColor:NSColor.textColor];
    [fullwidthSpaceCharacterKindMatrix setCellColor:NSColor.textColor];
    [returnCharacterKindMatrix setCellColor:NSColor.textColor];
    [tabCharacterKindMatrix setCellColor:NSColor.textColor];
    [pageBoxMatrix setCellColor:NSColor.textColor];
	
	// 保存された設定を読み込む
	NSFileManager *fileManager = NSFileManager.defaultManager;
	NSString *plistFile = [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", NSHomeDirectory(), [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
    
	
	BOOL loadLastProfileSuccess = NO;
	
	if ([fileManager fileExistsAtPath:plistFile]) {
		[profileController loadProfilesFromPlist];
		loadLastProfileSuccess = [self adoptProfileDuringLauching];
		[profileController removeProfileForName:AutoSavedProfileName];
	}
    
	if (!loadLastProfileSuccess) { // 初回起動時の各種プログラムのパスの自動設定
		[profileController initProfiles];
        
        [self searchProgramsLogic:@{
                                    @"Title": localizedString(@"initSettingsMsg"),
                                    @"Msg1": localizedString(@"setPathMsg1"),
                                    @"Msg2": localizedString(@"setPathMsg2"),
                                    @"waitUntilDone": @(NO)
                                    }];

        // デフォルトプリアンブルのロード
        NSString *templateName = [autoDetectionTargetMatrix.selectedCell title];
        NSString *originalTemplateDirectory = [NSBundle.mainBundle pathForResource:TemplateDirectoryName ofType:nil];
        NSString *templatePath = [[originalTemplateDirectory stringByAppendingPathComponent:templateName] stringByAppendingPathExtension:@"tex"];
        NSData *data = [NSData dataWithContentsOfFile:templatePath];
        NSStringEncoding detectedEncoding;
        NSString *contents = [NSString stringWithAutoEncodingDetectionOfData:data detectedEncoding:&detectedEncoding];
        
        if (contents) {
            [preambleTextView replaceEntireContentsWithString:contents];
        }

        [self loadDefaultFont];
        [self loadDefaultColors:nil];
		
		[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"SUEnableAutomaticChecks"];
	}
    
	// CommandComepletion.txt のロード
	NSData *completionData;

	NSString *completionPath = @"~/Library/TeXShop/CommandCompletion/CommandCompletion.txt".stringByStandardizingPath;
    if ([fileManager fileExistsAtPath:completionPath]) {
		completionData = [NSData dataWithContentsOfFile:completionPath];
    }
	
	if (completionData) {
		commandCompletionList = [[NSMutableString alloc] initWithData:completionData encoding:NSUTF8StringEncoding];
		
		[commandCompletionList insertString:@"\n" atIndex:0];
        if ([commandCompletionList characterAtIndex:commandCompletionList.length-1] != '\n') {
			[commandCompletionList appendString:@"\n"];
        }
	}

    // Application Support の準備
    NSString *templateDirectoryPath = self.templateDirectoryPath;
    if (![fileManager fileExistsAtPath:templateDirectoryPath]) {
        // 初回起動時には app bundle 内のテンプレートをコピー
        [self restoreDefaultTemplatesLogic];
    }
    
    [self updateCUIToolStatus];
    
    [self preferencesChanged:nil];
    [self outputFilePathChanged:nil];
}

- (void)updateCUIToolStatus
{
    // CUI版のインストール状態チェック
    if ([[NSFileManager defaultManager] fileExistsAtPath:CUI_PATH]) {
        cuiToolInstallButton.title = localizedString(@"Uninstall...");
        cuiToolStatusView.image = [NSImage imageNamed:NSImageNameStatusAvailable];
        cuiToolStatusTextField.stringValue = [NSString stringWithFormat:localizedString(@"Installed"), CUI_PATH];
    } else {
        cuiToolInstallButton.title = localizedString(@"Install...");
        cuiToolStatusView.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
        cuiToolStatusTextField.stringValue = localizedString(@"Not Installed");
    }
}

- (void)loadDefaultFont
{
    NSFont *defaultFont = [NSFont fontWithName:@"Osaka-Mono" size:13];
    if (defaultFont) {
        sourceFont = defaultFont;
        sourceTextView.font = defaultFont;
        preambleTextView.font = defaultFont;
        [self setupFontTextField:defaultFont];
    }
}

- (IBAction)loadDefaultColors:(NSButton*)sender
{
    NSString *modeName = localizedString((sender.tag == LIGHTMODE_TAG) ? @"Light Mode" : @"Dark Mode");
    
    if (sender && !runConfirmPanel([NSString stringWithFormat:localizedString(@"restoreColorsConfirmationMsg"), modeName])) {
        return;
    }
    
    if (!sender || (sender.tag == LIGHTMODE_TAG)) { // 初回起動時，またはライトモードの「デフォルトに戻す」ボタン
        lightModeForegroundColorWell.color = NSColor.defaultForegroundColorForLightMode;
        lightModeBackgroundColorWell.color = NSColor.defaultBackgroundColorForLightMode;
        lightModeCursorColorWell.color = NSColor.defaultCursorColorForLightMode;
        lightModeBraceColorWell.color = NSColor.defaultBraceColorForLightMode;
        lightModeCommentColorWell.color = NSColor.defaultCommentColorForLightMode;
        lightModeCommandColorWell.color = NSColor.defaultCommandColorForLightMode;
        lightModeInvisibleColorWell.color = NSColor.defaultInvisibleColorForLightMode;
        lightModeHighlightedBraceColorWell.color = NSColor.defaultHighlightedBraceColorForLightMode;
        lightModeEnclosedContentBackgroundColorWell.color = NSColor.defaultEnclosedContentBackgroundColorForLightMode;
        lightModeFlashingBackgroundColorWell.color = NSColor.defaultFlashingBackgroundColorForLightMode;
        lightModeConsoleForegroundColorWell.color = NSColor.defaultConsoleForegroundColorForLightMode;
        lightModeConsoleBackgroundColorWell.color = NSColor.defaultConsoleBackgroundColorForLightMode;
        
        [lightModeForegroundColorWell saveColorTo:lastColorDict];
        [lightModeBackgroundColorWell saveColorTo:lastColorDict];
        [lightModeCursorColorWell saveColorTo:lastColorDict];
        [lightModeBraceColorWell saveColorTo:lastColorDict];
        [lightModeCommentColorWell saveColorTo:lastColorDict];
        [lightModeCommandColorWell saveColorTo:lastColorDict];
        [lightModeInvisibleColorWell saveColorTo:lastColorDict];
        [lightModeHighlightedBraceColorWell saveColorTo:lastColorDict];
        [lightModeEnclosedContentBackgroundColorWell saveColorTo:lastColorDict];
        [lightModeFlashingBackgroundColorWell saveColorTo:lastColorDict];
        [lightModeConsoleForegroundColorWell saveColorTo:lastColorDict];
        [lightModeConsoleBackgroundColorWell saveColorTo:lastColorDict];
    }
    if (!sender || (sender.tag == DARKMODE_TAG)) { // 初回起動時，またはダークモードの「デフォルトに戻す」ボタン
        darkModeForegroundColorWell.color = NSColor.defaultForegroundColorForDarkMode;
        darkModeBackgroundColorWell.color = NSColor.defaultBackgroundColorForDarkMode;
        darkModeCursorColorWell.color = NSColor.defaultCursorColorForDarkMode;
        darkModeBraceColorWell.color = NSColor.defaultBraceColorForDarkMode;
        darkModeCommentColorWell.color = NSColor.defaultCommentColorForDarkMode;
        darkModeCommandColorWell.color = NSColor.defaultCommandColorForDarkMode;
        darkModeInvisibleColorWell.color = NSColor.defaultInvisibleColorForDarkMode;
        darkModeHighlightedBraceColorWell.color = NSColor.defaultHighlightedBraceColorForDarkMode;
        darkModeEnclosedContentBackgroundColorWell.color = NSColor.defaultEnclosedContentBackgroundColorForDarkMode;
        darkModeFlashingBackgroundColorWell.color = NSColor.defaultFlashingBackgroundColorForDarkMode;
        darkModeConsoleForegroundColorWell.color = NSColor.defaultConsoleForegroundColorForDarkMode;
        darkModeConsoleBackgroundColorWell.color = NSColor.defaultConsoleBackgroundColorForDarkMode;
        
        [darkModeForegroundColorWell saveColorTo:lastColorDict];
        [darkModeBackgroundColorWell saveColorTo:lastColorDict];
        [darkModeCursorColorWell saveColorTo:lastColorDict];
        [darkModeBraceColorWell saveColorTo:lastColorDict];
        [darkModeCommentColorWell saveColorTo:lastColorDict];
        [darkModeCommandColorWell saveColorTo:lastColorDict];
        [darkModeInvisibleColorWell saveColorTo:lastColorDict];
        [darkModeHighlightedBraceColorWell saveColorTo:lastColorDict];
        [darkModeEnclosedContentBackgroundColorWell saveColorTo:lastColorDict];
        [darkModeFlashingBackgroundColorWell saveColorTo:lastColorDict];
        [darkModeConsoleForegroundColorWell saveColorTo:lastColorDict];
        [darkModeConsoleBackgroundColorWell saveColorTo:lastColorDict];
    }
    
    makeatletterEnabledCheckBox.state = NSOnState;

    [sourceTextView colorizeText];
    [preambleTextView colorizeText];
    [self recolorOutputView];
}

- (void)setupFontTextField:(NSFont*)font
{
    fontTextField.stringValue = [NSString stringWithFormat:@"%@ - %.1fpt", font.displayName, font.pointSize];
}

- (void)showAutoDetectionResult:(NSDictionary<NSString*,NSString*>*)parameters
{
    runOkPanel(parameters[@"Title"],
               @"%@\n%@\n%@\n%@\n%@",
               parameters[@"Msg1"],
               parameters[LatexPathKey],
               parameters[DviDriverPathKey],
               parameters[GsPathKey],
               parameters[@"Msg2"]
               );
}

- (void)applicationWillTerminate:(NSNotification*)aNotification
{
    // 色パレットが表示されていれば消す
    if (NSColorPanel.sharedColorPanelExists) {
        [self closeColorPanel];
    }
    
    // フォントパネルが表示されていれば消す
    if (NSFontPanel.sharedFontPanelExists) {
        [self closeFontPanel];
    }

	[profileController updateProfile:[self currentProfile] forName:AutoSavedProfileName];
	[profileController saveProfiles];
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)closeOtherWindows:(NSNotification*)aNotification
{
    [outputWindow close];
	[preambleWindow close];
    [preferenceWindow close];
}

- (void)uncheckOutputWindowMenuItem:(NSNotification*)aNotification
{
	outputWindowMenuItem.state = NSOffState;
}

- (void)uncheckPreambleWindowMenuItem:(NSNotification*)aNotification
{
	preambleWindowMenuItem.state = NSOffState;
}


- (void)otherWindowsDidBecomeKey:(NSNotification*)aNotification
{
    lastActiveWindow = aNotification.object;

    // 色パレットが表示されていれば消す
    [self closeColorPanel];
}

- (IBAction)showMainWindow:(id)sender
{
	[self showMainWindow];
}

- (void)readOutputData:(NSNotification*)aNotification
{
    NSData *data;
    @try {
        while ((data = outputPipe.fileHandleForReading.availableData) && (data.length > 0)) {
            [self appendOutputAndScroll:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] quiet:NO];
        }
    }
    @catch (NSException *exception) {
    }
    @finally {
        [outputPipe.fileHandleForReading readInBackgroundAndNotify];
    }
}


#pragma mark - Import / Export

- (NSArray<NSString*>*)analyzeContents:(NSString*)contents
{
    BOOL convertYenMark = [self.currentProfile boolForKey:ConvertYenMarkKey];
    if (convertYenMark) {
        contents = [[NSMutableString stringWithString:contents] replaceYenWithBackSlash];
    }
    
    NSString *preamble = @"";
    NSString *body = @"";
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^(.*?)(?:\\r|\\n|\\r\\n)*(?:\\\\|¥)begin\\{document\\}(?:\\r|\\n|\\r\\n)*(.*)(?:\\\\|¥)end\\{document\\}"
                                                                      options:NSRegularExpressionDotMatchesLineSeparators
                                                                        error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:contents
                                                    options:0
                                                      range:NSMakeRange(0, contents.length)];

    if (match) {
        preamble = [[contents substringWithRange:[match rangeAtIndex:1]] stringByAppendingString:@"\n"];
        body = [[contents substringWithRange:[match rangeAtIndex:2]].stringByDeletingLastReturnCharacters stringByAppendingString:@"\n"];
    } else {
        body = contents;
    }
    
    return @[preamble, body];
}

- (void)placeImportedSource:(NSString*)contents
{
    NSArray<NSString*> *parts = [self analyzeContents:contents];
    NSString *preamble = parts[0];
    NSString *body = parts[1];
    
    if (![preamble isEqualToString:@""]) {
        [preambleTextView replaceEntireContentsWithString:preamble];
    }
    if (![body isEqualToString:@""]) {
        [sourceTextView replaceEntireContentsWithString:body];
    }
    [self sourceSettingChanged:directInputButton];
}

- (NSStringEncoding)stringEncodingFromEncodingOption:(NSString*)option
{
    NSStringEncoding encoding = NSUTF8StringEncoding;
    
    if ([option isEqualToString:PTEX_ENCODING_SJIS]) {
        encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese);
    } else if ([option isEqualToString:PTEX_ENCODING_EUC]) {
        encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_JP);
    } else if ([option isEqualToString:PTEX_ENCODING_JIS]) {
        encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP);
    }
    
    return encoding;
}

- (NSString*)extractTeXSourceStringFromAnnotationOfPDF:(PDFDocument*)document
{
    if (!document) {
        return nil;
    }
    
    NSString *contents = nil;
    
    PDFPage *page = [document pageAtIndex:0];
    if (!page) {
        runErrorPanel(localizedString(@"doesNotContainSource"), [document description]);
        return nil;
    }
    
    NSArray<PDFAnnotation*> *annotations = page.annotations;
    if (!annotations) {
        runErrorPanel(localizedString(@"doesNotContainSource"), [document description]);
        return nil;
    }
    
    // TeX2img によって埋め込まれたソース情報が含まれるかどうかのチェック
    for (PDFAnnotation *annotation in annotations) {
        if (isTeX2imgAnnotation(annotation)) {
            contents = [[annotation.contents stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"] substringFromIndex:[AnnotationHeader length]];
            break;
        }
    }
    
    return contents;
}

- (BOOL)importSourceFromFilePathOrPDFDocument:(id)input skipConfirm:(BOOL)skipConfirm
{
    [NSApp activateIgnoringOtherApps:YES];
    
    NSString *contents = nil;
    NSString *outputFilePath = nil;
    
    if ([input isKindOfClass:NSString.class]) { // ファイルパスが指定されたインポート
        NSString *inputPath = (NSString*)input;
        NSString *extension = inputPath.pathExtension.lowercaseString;
        if ([@"tex" isEqualToString:extension]) { // TeX ソースのインプット
            NSData *data = [NSData dataWithContentsOfFile:inputPath];
            NSStringEncoding detectedEncoding;
            contents = [NSString stringWithAutoEncodingDetectionOfData:data detectedEncoding:&detectedEncoding];
            lastSavedPath = inputPath;
        } else { // 画像ファイルのインプット
            ssize_t bufferLength = getxattr(inputPath.UTF8String, EA_Key, NULL, 0, 0, 0); // EAを取得
            if (bufferLength < 0) { // ソース情報が含まれない画像ファイルの場合
                // PDFの場合はファイル内のアノテーション情報も探索を試みる
                if ([@"pdf" isEqualToString:extension]) {
                    PDFDocument *doc = [[PDFDocument alloc] initWithFilePath:inputPath];
                    contents = [self extractTeXSourceStringFromAnnotationOfPDF:doc];
                    if (!contents) {
                        runErrorPanel(localizedString(@"doesNotContainSource"), inputPath);
                        return NO;
                    }
                    outputFilePath = inputPath;
                } else {
                    runErrorPanel(localizedString(@"doesNotContainSource"), inputPath);
                    return NO;
                }
            } else { // ソース情報が含まれる画像ファイルの場合はそれをEAから取得して contents にセット（EAに保存されたソースは常にUTF8）
                char *buffer = (char*)malloc(bufferLength);
                getxattr(inputPath.UTF8String, EA_Key, buffer, bufferLength, 0, 0);
                contents = [[NSString alloc] initWithBytes:buffer length:bufferLength encoding:NSUTF8StringEncoding];
                free(buffer);
                outputFilePath = inputPath;
            }
        }
    } else if ([input isKindOfClass:PDFDocument.class]) { // PDFからのインポート
        contents = [self extractTeXSourceStringFromAnnotationOfPDF:input];
        if (!contents) {
            runErrorPanel(localizedString(@"doesNotContainSource"), [input description]);
            return NO;
        }
    } else {
        runErrorPanel(localizedString(@"doesNotContainSource"), [input description]);
        return NO;
    }
    
    if (contents) {
        if (skipConfirm || runConfirmPanel(localizedString(@"overwriteContentsWarningMsg"))) {
            [self placeImportedSource:contents];
            if (outputFilePath) {
                outputFileTextField.stringValue = outputFilePath;
            }
        }
    } else {
        runErrorPanel(localizedString(@"cannotReadErrorMsg"), [input description]);
        return NO;
    }
    return YES;
}

- (IBAction)importSource:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.allowedFileTypes = ImportExtensionsArray;
    
    [openPanel beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            [self importSourceFromFilePathOrPDFDocument:openPanel.URL.path skipConfirm:NO];
        }
    }];
}

- (IBAction)exportSource:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = @[@"tex"];
    savePanel.extensionHidden = NO;
    savePanel.canSelectHiddenExtension = YES;
    
    if (lastSavedPath) {
        savePanel.nameFieldStringValue = lastSavedPath.lastPathComponent;
        savePanel.directoryURL = [NSURL fileURLWithPath:lastSavedPath.stringByDeletingLastPathComponent];
    }
    
    [savePanel beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            NSString *outputPath = savePanel.URL.path;
            self.lastSavedPath = outputPath;
            NSString *preamble = self.preambleTextView.textStorage.mutableString;
            NSString *body = self.sourceTextView.textStorage.mutableString;
            NSString *contents = [NSString stringWithFormat:@"%@\n\\begin{document}\n%@\n\\end{document}\n", preamble, body];
            NSStringEncoding encoding = [self stringEncodingFromEncodingOption:[self.currentProfile stringForKey:EncodingKey]];
            
            if (![contents writeToFile:outputPath atomically:YES encoding:encoding error:nil]) {
                runErrorPanel(localizedString(@"cannotWriteErrorMsg"), outputPath);
            }
        }
    }];
}

#pragma mark - Drag & Drop

- (void)textViewDroppedFile:(id)file;
{
    [self importSourceFromFilePathOrPDFDocument:file skipConfirm:NO];
}


#pragma mark - 色選択パネル
- (IBAction)toggleColorPalleteWindow:(id)sender {
    if (colorPalleteWindow.isVisible) {
        [colorPalleteWindow close];
    } else {
        colorPalleteWindowMenuItem.state = NSOnState;
        [colorPalleteWindow makeKeyAndOrderFront:nil];
        [colorStyleMatrix sendAction];
    }
}


- (IBAction)colorPalleteColorSet:(id)sender {
    if (!colorPalleteWindow.isKeyWindow) {
        return;
    }

    [colorPalleteColorWell saveColorTo:lastColorDict];

    NSColor *color = colorPalleteColorWell.color;
    
    NSString *formatString;
    CGFloat r, g, b;
    @try {
        r = color.redComponent;
        g = color.greenComponent;
        b = color.blueComponent;
        switch (colorStyleMatrix.selectedTag) {
            case COLOR_TAG:
                formatString = @"\\color[rgb]{%lf,%lf,%lf}";
                break;
            case TEXTCOLOR_TAG:
                formatString = @"\\textcolor[rgb]{%lf,%lf,%lf}{}";
                break;
            case COLORBOX_TAG:
                formatString = @"\\colorbox[rgb]{%lf,%lf,%lf}{}";
                break;
            case DEFINECOLOR_TAG:
                formatString = @"\\definecolor{}{rgb}{%lf,%lf,%lf}";
                break;
            default:
                break;
        }
    }
    @catch (NSException *exception) {
    }
    @finally {
        if (formatString) {
            colorTextField.stringValue = [NSString stringWithFormat:formatString, r, g, b];
        }
    }
}

- (IBAction)insertColorCommand:(id)sender {
    if (lastActiveWindow == mainWindow) {
        [sourceTextView insertTextWithIndicator:colorTextField.stringValue];
    } else if (lastActiveWindow == preambleWindow) {
        [preambleTextView insertTextWithIndicator:colorTextField.stringValue];
    }
}

- (void)uncheckColorPalleteWindowMenuItem:(NSNotification*)aNotification
{
    colorPalleteWindowMenuItem.state = NSOffState;
    if (NSColorPanel.sharedColorPanelExists) {
        [NSColorPanel.sharedColorPanel orderOut:self];
    }
}

- (void)preferenceWindowDidBecomeKey:(NSNotification*)aNotification
{
    lastActiveWindow = aNotification.object;
    
    [fillColorWell restoreColorFrom:lastColorDict];
    
    [lightModeForegroundColorWell restoreColorFrom:lastColorDict];
    [lightModeBackgroundColorWell restoreColorFrom:lastColorDict];
    [lightModeCursorColorWell restoreColorFrom:lastColorDict];
    [lightModeBraceColorWell restoreColorFrom:lastColorDict];
    [lightModeCommentColorWell restoreColorFrom:lastColorDict];
    [lightModeCommandColorWell restoreColorFrom:lastColorDict];
    [lightModeInvisibleColorWell restoreColorFrom:lastColorDict];
    [lightModeHighlightedBraceColorWell restoreColorFrom:lastColorDict];
    [lightModeEnclosedContentBackgroundColorWell restoreColorFrom:lastColorDict];
    [lightModeFlashingBackgroundColorWell restoreColorFrom:lastColorDict];
}

- (void)colorPalleteWindowDidBecomeKey:(NSNotification*)aNotification
{
    [colorPalleteColorWell restoreColorFrom:lastColorDict];
}

- (void)closeColorPanel
{
    [fillColorWell deactivate];
    
    [lightModeForegroundColorWell deactivate];
    [lightModeBackgroundColorWell deactivate];
    [lightModeCursorColorWell deactivate];
    [lightModeBraceColorWell deactivate];
    [lightModeCommentColorWell deactivate];
    [lightModeCommandColorWell deactivate];
    [lightModeInvisibleColorWell deactivate];
    [lightModeHighlightedBraceColorWell deactivate];
    [lightModeEnclosedContentBackgroundColorWell deactivate];
    [lightModeFlashingBackgroundColorWell deactivate];
    [lightModeConsoleForegroundColorWell deactivate];
    [lightModeConsoleBackgroundColorWell deactivate];

    [darkModeForegroundColorWell deactivate];
    [darkModeBackgroundColorWell deactivate];
    [darkModeCursorColorWell deactivate];
    [darkModeBraceColorWell deactivate];
    [darkModeCommentColorWell deactivate];
    [darkModeCommandColorWell deactivate];
    [darkModeInvisibleColorWell deactivate];
    [darkModeHighlightedBraceColorWell deactivate];
    [darkModeEnclosedContentBackgroundColorWell deactivate];
    [darkModeFlashingBackgroundColorWell deactivate];
    [darkModeConsoleForegroundColorWell deactivate];
    [darkModeConsoleBackgroundColorWell deactivate];

    [colorPalleteColorWell deactivate];
    
    [NSColorPanel.sharedColorPanel performSelector:@selector(orderOut:) withObject:self afterDelay:0];

    [fillColorWell restoreColorFrom:lastColorDict];

    [lightModeForegroundColorWell restoreColorFrom:lastColorDict];
    [lightModeBackgroundColorWell restoreColorFrom:lastColorDict];
    [lightModeCursorColorWell restoreColorFrom:lastColorDict];
    [lightModeBraceColorWell restoreColorFrom:lastColorDict];
    [lightModeCommentColorWell restoreColorFrom:lastColorDict];
    [lightModeCommandColorWell restoreColorFrom:lastColorDict];
    [lightModeInvisibleColorWell restoreColorFrom:lastColorDict];
    [lightModeHighlightedBraceColorWell restoreColorFrom:lastColorDict];
    [lightModeEnclosedContentBackgroundColorWell restoreColorFrom:lastColorDict];
    [lightModeFlashingBackgroundColorWell restoreColorFrom:lastColorDict];
    [lightModeConsoleForegroundColorWell restoreColorFrom:lastColorDict];
    [lightModeConsoleBackgroundColorWell restoreColorFrom:lastColorDict];

    [darkModeForegroundColorWell restoreColorFrom:lastColorDict];
    [darkModeBackgroundColorWell restoreColorFrom:lastColorDict];
    [darkModeCursorColorWell restoreColorFrom:lastColorDict];
    [darkModeBraceColorWell restoreColorFrom:lastColorDict];
    [darkModeCommentColorWell restoreColorFrom:lastColorDict];
    [darkModeCommandColorWell restoreColorFrom:lastColorDict];
    [darkModeInvisibleColorWell restoreColorFrom:lastColorDict];
    [darkModeHighlightedBraceColorWell restoreColorFrom:lastColorDict];
    [darkModeEnclosedContentBackgroundColorWell restoreColorFrom:lastColorDict];
    [darkModeFlashingBackgroundColorWell restoreColorFrom:lastColorDict];
    [darkModeConsoleForegroundColorWell restoreColorFrom:lastColorDict];
    [darkModeConsoleBackgroundColorWell restoreColorFrom:lastColorDict];

    [colorPalleteColorWell restoreColorFrom:lastColorDict];
}

- (void)closeFontPanel
{
    [NSFontPanel.sharedFontPanel performSelector:@selector(orderOut:) withObject:self afterDelay:0];
}



#pragma mark - IBAction

- (void)dialogOk:(id)sender
{
    [NSApp stopModalWithCode:YES];
}

- (void)dialogCancel:(id)sender
{
    [NSApp stopModalWithCode:NO];
}

- (IBAction)saveAsTemplate:(id)sender
{
    NSSize dialogSize = NSMakeSize(340, 120);
    NSRect dialogRect = NSMakeRect(0, 0, dialogSize.width, dialogSize.height);
    
    NSWindow *dialog = [[NSWindow alloc] initWithContentRect:dialogRect
                                                   styleMask:(NSTitledWindowMask|NSResizableWindowMask)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [dialog setFrame:dialogRect display:NO];
    dialog.minSize = NSMakeSize(250, dialogSize.height);
    dialog.maxSize = NSMakeSize(10000, dialogSize.height);
    dialog.title = localizedString(@"saveCurrentPreambleAsTemplate");
    
    NSTextField *input = [NSTextField new];
    input.frame = NSMakeRect(17, 54, dialogSize.width - 40, 25);
    input.autoresizingMask = NSViewWidthSizable;
    [dialog.contentView addSubview:input];
    
    if ([sender isKindOfClass:NSString.class]) {
        input.stringValue = (NSString*)sender;
    }
    
    NSButton *cancelButton = [NSButton new];
    cancelButton.title = localizedString(@"Cancel");
    cancelButton.frame = NSMakeRect(dialogSize.width - 206, 12, 96, 32);
    cancelButton.bezelStyle = NSRoundedBezelStyle;
    cancelButton.autoresizingMask = NSViewMinXMargin;
    cancelButton.keyEquivalent = @"\033";
    cancelButton.target = self;
    cancelButton.action = @selector(dialogCancel:);
    [dialog.contentView addSubview:cancelButton];
    
    NSButton *okButton = [NSButton new];
    okButton.title = @"OK";
    okButton.frame = NSMakeRect(dialogSize.width - 110, 12, 96, 32);
    okButton.bezelStyle = NSRoundedBezelStyle;
    okButton.autoresizingMask = NSViewMinXMargin;
    okButton.keyEquivalent = @"\r";
    okButton.target = self;
    okButton.action = @selector(dialogOk:);
    [dialog.contentView addSubview:okButton];
    
    BOOL returnCode = [NSApp runModalForWindow:dialog];
    [dialog orderOut:self];
    
    if (returnCode) {
        NSFileManager *fileManager = NSFileManager.defaultManager;
        NSString *title = input.stringValue;
        
        if ([title isEqualToString:@""]) {
            [self saveAsTemplate:title];
            return;
        }

        NSString *filePath = [self.templateDirectoryPath stringByAppendingPathComponent:[title stringByAppendingPathExtension:@"tex"]];
        
        if ([fileManager fileExistsAtPath:filePath]
            && (!runConfirmPanel(localizedString(@"profileOverwriteMsg")))) {
            [self saveAsTemplate:title];
        } else {
            NSString *preamble = preambleTextView.textStorage.mutableString;
            BOOL success = [preamble writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
            if (!success) {
                runErrorPanel(localizedString(@"cannotWriteErrorMsg"), filePath);
            }
        }
    }
}

- (IBAction)openTemplateDirectory:(id)sender
{
    [NSWorkspace.sharedWorkspace openFile:self.templateDirectoryPath withApplication:@"Finder"];
}

- (IBAction)openTempDir:(id)sender
{
	[NSWorkspace.sharedWorkspace openFile:NSTemporaryDirectory() withApplication:@"Finder"];
}

- (IBAction)showPreferenceWindow:(id)sender
{
	[preferenceWindow makeKeyAndOrderFront:nil];
}

- (IBAction)showProfilesWindow:(id)sender
{
	[profileController showProfileWindow];
}

- (IBAction)sourceSettingChanged:(id)sender
{
    switch ([sender tag]) {
        case DIRECT_INPUT_TAG: // 直接入力
            directInputButton.state = NSOnState;
            inputSourceFileButton.state = NSOffState;
            sourceTextView.enabled = YES;
            [mainWindow endEditingFor:inputSourceFileTextField];  // inputSourceFileTextField の編集内容を強制確定させる
            inputSourceFileTextField.enabled = NO;
            browseSourceFileButton.enabled = NO;
            break;
        case INPUT_FILE_TAG: // ソースファイル読み込み
            directInputButton.state = NSOffState;
            inputSourceFileButton.state = NSOnState;
            sourceTextView.enabled = NO;
            inputSourceFileTextField.enabled = YES;
            browseSourceFileButton.enabled = YES;
            break;
        default:
            break;
    }
}

- (IBAction)showInputSourceFilePanel:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.allowedFileTypes = InputExtensionsArray;
    
    [openPanel beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            self.inputSourceFileTextField.stringValue = openPanel.URL.path;
        }
    }];
    
}

- (IBAction)showSavePanel:(id)sender
{
    // 拡張子選択のビュー
    NSView *accessoryView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 270, 50)];
    
    // 拡張子一覧
    NSPopUpButton *popUpButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(130, 10, 120, 25)];
    [popUpButton addItemsWithTitles:[TargetExtensionsArray mapUsingBlock:^NSString*(NSString *item) {
        return item.uppercaseString;
    }]];
    
    // ラベル
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 15, 100, 18)];
    label.stringValue = localizedString(@"Format");
    label.alignment = NSTextAlignmentRight;
    label.bordered = NO;
    label.selectable = NO;
    label.editable = NO;
    label.backgroundColor = NSColor.clearColor;
    
    [accessoryView addSubview:popUpButton];
    [accessoryView addSubview:label];
    
    // 保存ダイアログ
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = TargetExtensionsArray;
    savePanel.extensionHidden = NO;
    savePanel.canSelectHiddenExtension = NO;
    savePanel.accessoryView = accessoryView;
    
    // アクション設定
    popUpButton.action = @selector(extensionPopUpButtonInSavePanelChanged:);
    popUpButton.target = self;
    
    NSString *defaultFilePath = outputFileTextField.stringValue;
    NSString *defaultExtensionUpper = extensionPopupButton.selectedItem.title;
    NSString *defaultExtensionLower = defaultExtensionUpper.lowercaseString;
    savePanel.nameFieldStringValue = [defaultFilePath.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:defaultExtensionLower];
    [popUpButton selectItemWithTitle:defaultExtensionUpper];
    savePanel.directoryURL = [NSURL fileURLWithPath:defaultFilePath.stringByDeletingLastPathComponent];
    
    [savePanel beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            self.outputFileTextField.stringValue = savePanel.URL.path;
            [self outputFilePathChanged:nil];
        }
    }];
}

- (void)extensionPopUpButtonInSavePanelChanged:(NSPopUpButton*)sender
{
    NSSavePanel *savePanel = (NSSavePanel*)sender.window;
    NSString *oldName = savePanel.nameFieldStringValue;
    NSString *extension = sender.selectedItem.title.lowercaseString;
    NSString *newName = [oldName.stringByDeletingPathExtension stringByAppendingPathExtension:extension];
    savePanel.nameFieldStringValue = newName;
    // allowedFileTypes の先頭に新しい拡張子を持っていくことで入力欄の拡張子を変える
    savePanel.allowedFileTypes = [@[extension] arrayByAddingObjectsFromArray:savePanel.allowedFileTypes];
}

- (IBAction)toggleMenuItem:(id)sender
{
    if ([sender isKindOfClass:NSMenuItem.class]) {
        NSMenuItem *theMenuItem = (NSMenuItem*)sender;
        theMenuItem.state = !theMenuItem.state;
        [self refreshTextView:theMenuItem];
    }
}

- (IBAction)refreshTextView:(id)sender
{
    [tabWidthStepper takeIntegerValueFrom:tabWidthTextField];
    [sourceTextView refreshWordWrap];
    [sourceTextView colorizeText];
    [sourceTextView fixupTabs];
    [preambleTextView refreshWordWrap];
    [preambleTextView colorizeText];
    [preambleTextView fixupTabs];
}

- (IBAction)tabWidthStepperPressed:(id)sender
{
    [tabWidthTextField takeIntegerValueFrom:tabWidthStepper];
    [self refreshTextView:sender];
}

- (void)refreshRelatedStepperValue:(NSNotification*)notification
{
    NSTextField *textField = (NSTextField*)(notification.object);
    
    [(NSStepper*)(textField.target) takeIntValueFrom:textField];
}

- (IBAction)toggleOutputWindow:(id)sender
{
    if (outputWindow.isVisible) {
        [outputWindow close];
    } else {
        [self showOutputWindow];
    }
}

- (IBAction)togglePreambleWindow:(id)sender
{
    if (mainWindow.isInFullScreenMode) {
        [preambleWindow makeKeyAndOrderFront:nil];
        [preambleTextView colorizeText];
        return;
    }
    
	if (preambleWindow.isVisible) {
		[preambleWindow close];
	} else {
		preambleWindowMenuItem.state = NSOnState;
        
        NSRect preambleWindowRect = preambleWindow.frame;
        NSScreen *screen = mainWindow.screen;

        CGFloat preambleWindowNewOriginY = MAX(NSMinY(mainWindow.frame), NSMinY(screen.visibleFrame));
        CGFloat preambleWindowNewHeight = MAX(NSMaxY(mainWindow.frame) - preambleWindowNewOriginY, preambleWindow.minSize.height);

        NSRect newRect = NSMakeRect(NSMinX(mainWindow.frame) - NSWidth(preambleWindowRect),
                                    preambleWindowNewOriginY,
                                    NSWidth(preambleWindowRect),
                                    preambleWindowNewHeight);

        if (NSMinX(screen.visibleFrame) <= NSMinX(newRect)) { // 左に表示する余裕があるとき
            [preambleWindow setFrame:newRect display:NO];
        } else {
            newRect = NSMakeRect(NSMaxX(mainWindow.frame),
                                 preambleWindowNewOriginY,
                                 NSWidth(preambleWindowRect),
                                 preambleWindowNewHeight);
            if (NSMaxX(newRect) <= NSMaxX(screen.visibleFrame)) { // 右に表示する余裕があるとき
                [preambleWindow setFrame:newRect display:NO];
            } else { // 左右ともに表示する余裕がないとき
                // メインウィンドウを縮められる限り縮める
                CGFloat newWidth = MAX(NSMaxX(mainWindow.frame) - NSMinX(screen.visibleFrame) - NSWidth(preambleWindow.frame) - 1, mainWindow.minSize.width);
                CGFloat newX = NSMaxX(mainWindow.frame) - newWidth;
                newRect = NSMakeRect(newX,
                                     mainWindow.frame.origin.y,
                                     newWidth,
                                     NSHeight(mainWindow.frame));
                [mainWindow setFrame:newRect display:YES animate:YES];
                
                // 画面左端からプリアンブルウィンドウを表示
                newRect = NSMakeRect(NSMinX(screen.visibleFrame),
                                     preambleWindowNewOriginY,
                                     NSMinX(mainWindow.frame) - NSMinX(screen.visibleFrame),
                                     preambleWindowNewHeight);
                [preambleWindow setFrame:newRect display:NO];
            }
        }
        
		[preambleWindow makeKeyAndOrderFront:nil];
        [preambleTextView colorizeText];
	}
}

- (IBAction)closeWindow:(id)sender
{
	[[NSApp keyWindow] close];
}

- (IBAction)preferencesChanged:(id)sender
{
    keepPageSizeAdvancedButton.enabled = (keepPageSizeCheckBox.state == NSOnState);
    mergeOutputAdvancedButton.enabled = (mergeOutputsCheckBox.state == NSOnState);
    
    if (toClipboardCheckBox.state == NSOnState) {
        autoPasteCheckBox.enabled = YES;
        autoPasteDestinationPopUpButton.enabled = (autoPasteCheckBox.state == NSOnState);
    } else {
        autoPasteCheckBox.enabled = NO;
        autoPasteDestinationPopUpButton.enabled = NO;
    }
    
    ungroupCheckBox.enabled = (embedInIllustratorCheckBox.state == NSOnState);
}

- (IBAction)showFontPanelOfSource:(id)sender
{
    NSFontManager *fontMgr = NSFontManager.sharedFontManager;
    fontMgr.target = self;
    fontMgr.action = @selector(changeFont:);
    
    NSFontPanel *panel = [fontMgr fontPanel:YES];
    [panel setPanelFont:sourceFont isMultiple:NO];
    [panel makeKeyAndOrderFront:self];
    panel.enabled = YES;
}

- (void)changeFont:(id)sender
{
    NSFont *font = NSFontManager.sharedFontManager.selectedFont;
    [self setupFontTextField:font];
    sourceFont = font;
    sourceTextView.font = font;
    preambleTextView.font = font;
    outputTextView.font = font;
    
    NSFont *displayFont = [NSFont fontWithName:font.fontName size:spaceCharacterKindButton.font.pointSize];
    [self setInvisibleCharacterFont:displayFont];
}

- (IBAction)colorSettingChanged:(id)sender
{
    if (!preferenceWindow.isKeyWindow || ![sender isKindOfClass:NSColorWell.class]) {
        return;
    }
    
    [(NSColorWell*)sender saveColorTo:lastColorDict];

    [sourceTextView performSelector:@selector(textViewDidChangeSelection:) withObject:nil];
    [preambleTextView performSelector:@selector(textViewDidChangeSelection:) withObject:nil];
    [self recolorOutputView];
}

- (void)recolorOutputView
{
    Profile *currentProfile = self.currentProfile;
    
    [self refreshTextView:outputTextView
          foregroundColor:consoleForegroundColorInProfile(currentProfile)
          backgroundColor:consoleBackgroundColorInProfile(currentProfile)
              cursorColor:cursorColorInProfile(currentProfile)];
    
    outputTextView.font = sourceFont;
}

- (void)searchProgramsLogic:(NSDictionary<NSString*,id>*)parameters
{
    NSString *latexPath;
    NSString *dviDriverPath;
    NSString *gsPath;
    
    NSString *templateName = [autoDetectionTargetMatrix.selectedCell title];
    NSString *engineName = [templateName.lowercaseString componentsSeparatedByString:@" "][0];
    NSString *dviDriverName = ([templateName rangeOfString:@"dvips"].location == NSNotFound) ? @"dvipdfmx" : @"dvips";
    
    if (!(latexPath = [self searchProgram:engineName])) {
        latexPath = @"";
        [self showNotFoundError:engineName];
    }
    if (!(dviDriverPath = [self searchProgram:dviDriverName])) {
        dviDriverPath = @"";
        [self showNotFoundError:dviDriverName];
    } else {
        if ([dviDriverName isEqualToString:@"dvipdfmx"]) {
            dviDriverPath = [dviDriverPath stringByAppendingString:@" -vv"];
        }
        if ([dviDriverName isEqualToString:@"dvips"]) {
            dviDriverPath = [dviDriverPath stringByAppendingString:@" -Ppdf"];
        }
    }
    if (!(gsPath = [self searchProgram:@"gs"])) {
        gsPath = @"";
        [self showNotFoundError:@"Ghostscript"];
    }
    

    latexPathTextField.stringValue = latexPath;
    dviDriverPathTextField.stringValue = dviDriverPath;
    gsPathTextField.stringValue = gsPath;
    
    [self performSelectorOnMainThread:@selector(showAutoDetectionResult:)
                           withObject:@{
                                        @"Title": (NSString*)(parameters[@"Title"]),
                                        @"Msg1": (NSString*)(parameters[@"Msg1"]),
                                        @"Msg2": (NSString*)(parameters[@"Msg2"]),
                                        LatexPathKey: [latexPath isEqualToString:@""] ? @"LaTeX: Not Found" : latexPath,
                                        DviDriverPathKey: [dviDriverPath isEqualToString:@""] ? @"DVI Driver: Not Found" : dviDriverPath,
                                        GsPathKey: [gsPath isEqualToString:@""] ? @"Ghostscript: Not Found" : gsPath
                                        }
                        waitUntilDone:[(NSNumber*)(parameters[@"waitUntilDone"]) boolValue]];
}

- (IBAction)searchPrograms:(id)sender
{
    [self searchProgramsLogic:@{
                                @"Title": localizedString(@"autoDetectionResult"),
                                @"Msg1": localizedString(@"setPathMsg1"),
                                @"Msg2": localizedString(@"setPathMsg3"),
                                @"waitUntilDone": @(YES)
                                }];
    
    // デフォルトテンプレートのロード
    NSString *templateName = [autoDetectionTargetMatrix.selectedCell title];
    NSString *originalTemplateDirectory = [NSBundle.mainBundle pathForResource:TemplateDirectoryName ofType:nil];
    NSString *templatePath = [[originalTemplateDirectory stringByAppendingPathComponent:templateName] stringByAppendingPathExtension:@"tex"];
    [self adoptPreambleTemplate:templatePath];
}

- (void)generationDidFinishOnMainThreadAfterDelay:(NSNumber*)status
{
    [converter deleteTemporaryFiles]; // スレッドが中断されたときにも確実に中間ファイルを削除するように
    generateButton.title = localizedString(@"Generate");
    generateButton.action = @selector(generate:);
    generateMenuItem.enabled = YES;
    abortMenuItem.enabled = NO;
    taskKilled = NO;
    
    if ([self.currentProfile boolForKey:SendNotificationKey]) {
        ExitStatus exitStatus = (ExitStatus)(status.intValue);
        [self sendUserNotificationWithStatus:exitStatus];
    }
}

- (void)generationDidFinishOnMainThread:(NSNumber*)status
{
    [self performSelector:@selector(generationDidFinishOnMainThreadAfterDelay:) withObject:status afterDelay:0.3];
}

- (void)generationDidFinish:(ExitStatus)status
{
    [self performSelectorOnMainThread:@selector(generationDidFinishOnMainThread:) withObject:@(status) waitUntilDone:YES];
}

- (void)printCurrentStatus:(Profile*)aProfile
{
    NSMutableString *output = [NSMutableString string];
    
    [output appendString:@"************************************\n"];
    [output appendString:@"  TeX2img settings\n"];
    [output appendString:@"************************************\n"];

    [output appendFormat:@"Version: %@\n", [aProfile stringForKey:TeX2imgVersionKey]];
    
    NSString *outputFilePath = [aProfile stringForKey:OutputFileKey];
    [output appendFormat:@"Output file: %@\n", outputFilePath];
    
    NSString *encoding = [aProfile stringForKey:EncodingKey];
    NSString *kanji;
    
    if ([encoding isEqualToString:PTEX_ENCODING_NONE]) {
        kanji = @"";
    } else {
        kanji = [@" -kanji=" stringByAppendingString:encoding];
    }
    
    [output appendFormat:@"LaTeX compiler: %@ %@\n", [aProfile stringForKey:LatexPathKey], kanji];
    
    [output appendString:@"Auto detection of the number of compilation: "];
    if ([aProfile boolForKey:GuessCompilationKey]) {
        [output appendString:@"enabled\n"];
        [output appendFormat:@"The maximal number of compilation: %ld\n", [aProfile integerForKey:NumberOfCompilationKey]];
    } else {
        [output appendString:@"disabled\n"];
        [output appendFormat:@"The number of compilation: %ld\n", [aProfile integerForKey:NumberOfCompilationKey]];
    }
    
    [output appendFormat:@"DVI Driver: %@\n", [aProfile stringForKey:DviDriverPathKey]];
    [output appendFormat:@"Ghostscript: %@\n", [aProfile stringForKey:GsPathKey]];

    [output appendString:@"Working directory: "];
    
    if (([aProfile integerForKey:WorkingDirectoryTypeKey] == WorkingDirectoryFile) && ([aProfile integerForKey:InputMethodKey] == FROMFILE)) {
        [output appendFormat:@"%@", [aProfile stringForKey:InputSourceFilePathKey].stringByDeletingLastPathComponent];
    } else {
        [output appendFormat:@"%@", NSTemporaryDirectory()];
    }
    [output appendString:@"\n"];

    [output appendFormat:@"Resolution level: %.1f\n", [aProfile floatForKey:ResolutionKey]];
    [output appendFormat:@"DPI: %ld\n", [aProfile integerForKey:DPIKey]];

    NSString *ext = outputFilePath.pathExtension;
    NSString *unit = (([aProfile integerForKey:UnitKey] == PX_UNIT_TAG) &&
                      ([ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"] || [ext isEqualToString:@"tiff"])) ?
                        @"px" : @"bp";
    
    [output appendFormat:@"Left   margin: %ld%@\n", [aProfile integerForKey:LeftMarginKey], unit];
    [output appendFormat:@"Right  margin: %ld%@\n", [aProfile integerForKey:RightMarginKey], unit];
    [output appendFormat:@"Top    margin: %ld%@\n", [aProfile integerForKey:TopMarginKey], unit];
    [output appendFormat:@"Bottom margin: %ld%@\n", [aProfile integerForKey:BottomMarginKey], unit];
    
    [output appendFormat:@"Transparent: %@\n", [aProfile boolForKey:TransparentKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Background color: %@\n", [aProfile colorForKey:FillColorKey].descriptionString];
    
    if ([ext isEqualToString:@"pdf"]) {
        [output appendFormat:@"Text embedded PDF: %@\n", [aProfile boolForKey:GetOutlineKey] ? DISABLED : ENABLED];
    }
    if ([ext isEqualToString:@"eps"]) {
        [output appendFormat:@"Plain text EPS: %@\n", [aProfile boolForKey:PlainTextKey] ? ENABLED : DISABLED];
    }
    if ([ext isEqualToString:@"svg"] || [ext isEqualToString:@"svgz"]) {
        [output appendFormat:@"Delete width and height attributes of SVG: %@\n", [aProfile boolForKey:DeleteDisplaySizeKey] ? ENABLED : DISABLED];
    }
    
    [output appendFormat:@"Ignore nonfatal errors: %@\n", [aProfile boolForKey:IgnoreErrorKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Substitute \\UTF / \\CID for non-JIS X 0208 characters: %@\n", [aProfile boolForKey:UtfExportKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Conversion mode: %@ priority mode\n", ([aProfile integerForKey:PriorityKey] == SPEED_PRIORITY_TAG) ? @"speed" : @"quality"];
    [output appendFormat:@"Send notification: %@\n", [aProfile boolForKey:SendNotificationKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Preview generated files: %@\n", [aProfile boolForKey:PreviewKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Delete temporary files: %@\n", [aProfile boolForKey:DeleteTmpFileKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Embed source into generated files: %@\n", [aProfile boolForKey:EmbedSourceKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Copy generated files to clipboard: %@\n", [aProfile boolForKey:CopyToClipboardKey] ? ENABLED : DISABLED];
    
    [output appendFormat:@"Paste generated files into %@: %@\n",
     autoPasteDestinationPopUpButton.selectedItem.title,
     [aProfile boolForKey:AutoPasteKey] ? ENABLED : DISABLED];
    
    BOOL embedInIllustrator = [aProfile boolForKey:EmbedInIllustratorKey];
    
    [output appendFormat:@"Embed generated files in Illustrator: "];
    if (embedInIllustrator) {
        [output appendString:@"enabled\n"];
        [output appendFormat:@"Ungroup after embedding: %@\n", [aProfile boolForKey:UngroupKey] ? ENABLED : DISABLED];
    } else {
        [output appendString:@"disabled\n"];
    }
    
    [output appendString:@"************************************\n\n"];
    [self appendOutputAndScroll:output quiet:NO];
}

- (void)generateImage
{
    NSString *inputSourceFilePath;
    MutableProfile *aProfile = self.currentProfile;
    aProfile[EpstopdfPathKey] = [NSBundle.mainBundle pathForResource:@"epstopdf" ofType:nil];
    aProfile[MudrawPathKey] = [[NSBundle.mainBundle pathForResource:@"mupdf" ofType:nil] stringByAppendingPathComponent:@"mudraw"];
    aProfile[PdftopsPathKey] = [[NSBundle.mainBundle pathForResource:@"pdftops" ofType:nil] stringByAppendingPathComponent:@"pdftops"];
    aProfile[QuietKey] = @(NO);
    aProfile[ControllerKey] = self;
    
    converter = [Converter converterWithProfile:aProfile];

    // 出力ビューをクリアし，現在の設定を表示
    outputTextView.textStorage.mutableString.string = @"";
    [self printCurrentStatus:aProfile];
    
    switch ([aProfile integerForKey:InputMethodKey]) {
        case DIRECT:
            [NSThread detachNewThreadSelector:@selector(compileAndConvertWithBody:) toTarget:converter withObject:sourceTextView.textStorage.string];
            break;
        case FROMFILE:
            inputSourceFilePath = [aProfile stringForKey:InputSourceFilePathKey].stringByStandardizingPath;
            if ([NSFileManager.defaultManager fileExistsAtPath:inputSourceFilePath]) {
                if ([InputExtensionsArray containsObject:inputSourceFilePath.pathExtension]) {
                    [NSThread detachNewThreadSelector:@selector(compileAndConvertWithInputPath:) toTarget:converter withObject:inputSourceFilePath];
                } else {
                    runErrorPanel(localizedString(@"inputFileTypeErrorMsg"), inputSourceFilePath);
                    [self generationDidFinish:ExitStatusFailed];
                }
            } else {
                runErrorPanel(localizedString(@"inputFileNotFoundErrorMsg"), inputSourceFilePath);
                [self generationDidFinish:ExitStatusFailed];
            }
            break;
        default:
            break;
    }
    
}

- (IBAction)generate:(id)sender
{
    // 余白設定・解像度設定などの数値の妥当性チェック
    __block BOOL valid = YES;

    [@[leftMarginTextField, rightMarginTextField, topMarginTextField, bottomMarginTextField, resolutionTextField, dpiTextField,  numberOfCompilationTextField, tabWidthTextField] enumerateObjectsUsingBlock:^(NSTextField *label, NSUInteger idx, BOOL *stop) {
        NSNumber *value = [(NSNumberFormatter*)(label.formatter) numberFromString:label.stringValue];
        if (value) {
            // 中途半端に入力されている数値を確定させる
            NSString *actionName = NSStringFromSelector(label.action);
            if ([actionName isEqualToString:@"takeIntValueFrom:"]) {
                label.integerValue = value.integerValue;
            } else if ([actionName isEqualToString:@"takeFloatValueFrom:"]) {
                label.floatValue = value.floatValue;
            }
            [label sendAction:label.action to:label.target]; // アクションを実行してスライダーやステッパーに反映
        } else { // 入力値が数値に解釈されなかった場合
            runErrorPanel(localizedString(@"formatErrorMsg"), label.toolTip);
            valid = NO;
        }
    }];
    
    if (!valid) {
        return;
    }
    
    [mainWindow makeKeyWindow]; // これをしておかないと，スレッド発動後に NSNumberFormatter によるフォーマットがコンパイル用スレッドから発動してエラーを引き起こすことがある
    
    if (showOutputWindowCheckBox.state) {
        [self showOutputWindow];
    }
	
    generateButton.title = localizedString(@"Abort");
    generateButton.action = @selector(abortCompilation:);
	generateMenuItem.enabled = NO;
    abortMenuItem.enabled = YES;
    
    [self generateImage];
}

- (IBAction)abortCompilation:(id)sender
{
    taskKilled = YES;
    
    if (runningTask && runningTask.isRunning) {
        [runningTask terminate];
        runningTask = nil;
        [self generationDidFinish:ExitStatusAborted];
    }
}

- (IBAction)showAutoDetectionTargetSettingPopover:(NSButton*)sender
{
    [NSPopover showWith:autoDetectionTargetSettingViewController
              atRightOf:sender
                   view:preferenceWindow.contentView
                offsetX:25
                      y:24];
}

- (IBAction)showPageBoxSettingPopover:(NSButton*)sender
{
    [NSPopover showWith:pageBoxSettingViewController
              atRightOf:sender
                   view:preferenceWindow.contentView
                offsetX:32
                      y:preferenceWindow.frame.size.height - (isJapaneseLanguage() ? 313 : 300)];
                // Japanese.lproj と English.lproj の MainMenu.xib の違いに対応
}

- (IBAction)showAnimationParameterSettingPopover:(NSButton*)sender
{
    [NSPopover showWith:animationParameterSettingViewController
              atRightOf:sender
                   view:preferenceWindow.contentView
                offsetX:32
                      y:preferenceWindow.frame.size.height - 446];
}

- (IBAction)extensionPopUpButtonChanged:(NSPopUpButton*)sender
{
    outputFileTextField.stringValue = [outputFileTextField.stringValue.stringByDeletingPathExtension stringByAppendingPathExtension:sender.selectedItem.title.lowercaseString];
}

- (IBAction)outputFilePathChanged:(id)sender
{
    NSString *newExtension = outputFileTextField.stringValue.lastPathComponent.pathExtension;
    
    if ([TargetExtensionsArray containsObject:newExtension]) {
        [extensionPopupButton selectItemWithTitle:newExtension.uppercaseString];
    }
}

- (IBAction)openSystemPreferencePane:(id)sender
{
    NSURL *paneURL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"];
    [[NSWorkspace sharedWorkspace] openURL:paneURL];
}

- (IBAction)installCUITool:(id)sender
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:CUI_PATH]) { // アンインストール
        NSString *message = [NSString stringWithFormat:localizedString(@"Uninstall CUI Confirmation"), CUI_PATH];
        
        if (runConfirmPanel(message)) {
            NSError *error = nil;
            [fileManager removeItemAtPath:CUI_PATH error:&error]; // まずは管理者権限なしでやってみる
            
            if (error) { // エラーが生じたら管理者権限で
                NSString *output = nil;
                NSString *errorMessage = nil;
                [self sudoCommand:@"/bin/rm"
                      atDirectory:NSTemporaryDirectory()
                    withArguments:@[CUI_PATH]
                     stdoutString:&output
                 errorDescription:&errorMessage];
                
                if (errorMessage) {
                    runErrorPanel(errorMessage);
                }
            }
        }

    } else { // インストール
        NSString *message = [NSString stringWithFormat:localizedString(@"Install CUI Confirmation"), CUI_PATH];
        
        if (runConfirmPanel(message)) {
            NSString *cuiInAppPath = [[[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:@"bin"] stringByAppendingPathComponent:@"tex2img"];

            NSError *error = nil;
            [fileManager createSymbolicLinkAtPath:CUI_PATH
                              withDestinationPath:cuiInAppPath
                                            error:&error];
            
            if (error) { // エラーが生じたら管理者権限で
                NSString *cuiDir = CUI_PATH.stringByDeletingLastPathComponent;
                NSString *bashArg = [NSString stringWithFormat:@"\"mkdir -p '%@'; ln -sf '%@' '%@'\"", cuiDir, cuiInAppPath, CUI_PATH];
                
                NSString *output = nil;
                NSString *errorMessage = nil;
                [self sudoCommand:@"/bin/bash"
                      atDirectory:NSTemporaryDirectory()
                    withArguments:@[@"-c", bashArg]
                     stdoutString:&output
                 errorDescription:&errorMessage];
                
                if (errorMessage) {
                    runErrorPanel(errorMessage);
                }
            }
        }
    }
    
    [self updateCUIToolStatus];
}

#pragma mark - 不可視文字表示の種別設定

- (IBAction)showSpaceCharacterKindSettingPopover:(NSButton*)sender
{
    [NSPopover showWith:spaceCharacterKindSettingViewController
              atRightOf:sender
                   view:invisibleCharacterBox
                offsetX:2
                      y:1];
}

- (IBAction)showFullwidthSpaceCharacterKindSettingPopover:(NSButton*)sender
{
    [NSPopover showWith:fullwidthSpaceCharacterKindSettingViewController
              atRightOf:sender
                   view:invisibleCharacterBox
                offsetX:2
                      y:1];
}

- (IBAction)showReturnCharacterKindSettingPopover:(NSButton*)sender
{
    [NSPopover showWith:returnCharacterKindSettingViewController
              atRightOf:sender
                   view:invisibleCharacterBox
                offsetX:2
                      y:1];
}

- (IBAction)showTabCharacterKindSettingPopover:(NSButton*)sender
{
    [NSPopover showWith:tabCharacterKindSettingViewController
              atRightOf:sender
                   view:invisibleCharacterBox
                offsetX:2
                      y:1];
}

- (IBAction)invisibleCharacterKindChanged:(id)sender
{
    spaceCharacterKindButton.title = self.spaceCharacter;
    fullwidthSpaceCharacterKindButton.title = self.fullwidthSpaceCharacter;
    returnCharacterKindButton.title = self.returnCharacter;
    tabCharacterKindButton.title = self.tabCharacter;

    [sourceTextView colorizeText];
    [preambleTextView colorizeText];
}

- (NSString*)spaceCharacter
{
    return ((NSButton*)(spaceCharacterKindMatrix.selectedCell)).title;
}

- (NSString*)fullwidthSpaceCharacter
{
    return ((NSButton*)(fullwidthSpaceCharacterKindMatrix.selectedCell)).title;
}

- (NSString*)returnCharacter
{
    return ((NSButton*)(returnCharacterKindMatrix.selectedCell)).title;
}

- (NSString*)tabCharacter
{
    return ((NSButton*)(tabCharacterKindMatrix.selectedCell)).title;
}

- (BOOL)showTabCharacterEnabled
{
    return [self.currentProfile boolForKey:ShowTabCharacterKey];
}

- (BOOL)showNewLineCharacterEnabled
{
    return [self.currentProfile boolForKey:ShowNewLineCharacterKey];
}

- (BOOL)showFullwidthSpaceCharacterEnabled
{
    return [self.currentProfile boolForKey:ShowFullwidthSpaceCharacterKey];
}

- (BOOL)showSpaceCharacterEnabled
{
    return [self.currentProfile boolForKey:ShowSpaceCharacterKey];
}

- (NSColor*)invisibleColor
{
    return invisibleColorInProfile(self.currentProfile);
}
@end
