#import <sys/xattr.h>
#import "ProfileController.h"
#import "global.h"
#import "ControllerG.h"
#import "NSDictionary-Extension.h"
#import "NSString-Extension.h"
#import "NSMutableString-Extension.h"
#import "NSFileManager-Extension.h"
#import "NSColor-Extension.h"
#import "NSColorWell-Extension.h"
#import "NSPipe-Extension.h"
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

@class ProfileController;
@class TeXTextView;

#define AutoSavedProfileName @"*AutoSavedProfile*"
#define TemplateDirectoryName @"Templates"

@interface ControllerG()
@property IBOutlet ProfileController *profileController;
@property IBOutlet NSWindow *mainWindow;
@property IBOutlet NSDrawer *outputDrawer;
@property IBOutlet NSTextView *outputTextView;
@property IBOutlet NSTextField *outputFileTextField;
@property IBOutlet NSPopUpButton *templatePopupButton;

@property IBOutlet NSWindow *preambleWindow;
@property IBOutlet TeXTextView *preambleTextView;
@property IBOutlet NSMenuItem *convertYenMarkMenuItem;
@property IBOutlet NSMenuItem *outputDrawerMenuItem;
@property IBOutlet NSMenuItem *preambleWindowMenuItem;
@property IBOutlet NSMenuItem *generateMenuItem;
@property IBOutlet NSMenuItem *abortMenuItem;
@property IBOutlet NSMenuItem *autoCompleteMenuItem;

@property IBOutlet NSButton *flashInMovingCheckBox;
@property IBOutlet NSButton *highlightContentCheckBox;
@property IBOutlet NSButton *beepCheckBox;
@property IBOutlet NSButton *flashBackgroundCheckBox;
@property IBOutlet NSButton *checkBraceCheckBox;
@property IBOutlet NSButton *checkBracketCheckBox;
@property IBOutlet NSButton *checkSquareCheckBox;
@property IBOutlet NSButton *checkParenCheckBox;

@property IBOutlet NSTextField *fontTextField;
@property IBOutlet NSTextField *tabWidthTextField;
@property IBOutlet NSStepper *tabWidthStepper;
@property IBOutlet NSButton *tabIndentCheckBox;
@property IBOutlet NSButton *wrapLineCheckBox;

@property IBOutlet NSButton *showTabCharacterCheckBox;
@property IBOutlet NSButton *showSpaceCharacterCheckBox;
@property IBOutlet NSButton *showNewLineCharacterCheckBox;
@property IBOutlet NSButton *showFullwidthSpaceCharacterCheckBox;

@property IBOutlet NSWindow *colorPalleteWindow;
@property IBOutlet NSMenuItem *colorPalleteWindowMenuItem;
@property IBOutlet NSColorWell *colorPalleteColorWell;
@property IBOutlet NSMatrix *colorStyleMatrix;
@property IBOutlet NSTextField *colorTextField;

@property IBOutlet NSButton *directInputButton;
@property IBOutlet NSButton *inputSourceFileButton;
@property IBOutlet NSTextField *inputSourceFileTextField;
@property IBOutlet NSButton *browseSourceFileButton;

@property IBOutlet NSButton *generateButton;
@property IBOutlet NSButton *transparentCheckBox;
@property IBOutlet NSButton *deleteDisplaySizeCheckBox;
@property IBOutlet NSButton *showOutputDrawerCheckBox;
@property IBOutlet NSButton *previewCheckBox;
@property IBOutlet NSButton *deleteTmpFileCheckBox;
@property IBOutlet NSButton *toClipboardCheckBox;
@property IBOutlet NSButton *embedSourceCheckBox;
@property IBOutlet NSButton *embedInIllustratorCheckBox;
@property IBOutlet NSButton *ungroupCheckBox;
@property IBOutlet NSWindow *preferenceWindow;
@property IBOutlet NSTextField *resolutionLabel;
@property IBOutlet NSTextField *leftMarginLabel;
@property IBOutlet NSTextField *rightMarginLabel;
@property IBOutlet NSTextField *topMarginLabel;
@property IBOutlet NSTextField *bottomMarginLabel;
@property IBOutlet NSSlider *resolutionSlider;
@property IBOutlet NSSlider *leftMarginSlider;
@property IBOutlet NSSlider *rightMarginSlider;
@property IBOutlet NSSlider *topMarginSlider;
@property IBOutlet NSSlider *bottomMarginSlider;
@property IBOutlet NSTextField *latexPathTextField;
@property IBOutlet NSTextField *dviwarePathTextField;
@property IBOutlet NSTextField *gsPathTextField;
@property IBOutlet NSButton *guessCompilationButton;
@property IBOutlet NSTextField *numberOfCompilationTextField;
@property IBOutlet NSStepper *numberOfCompilationStepper;
@property IBOutlet NSButton *textPdfCheckBox;
@property IBOutlet NSButton *ignoreErrorCheckBox;
@property IBOutlet NSButton *utfExportCheckBox;
@property IBOutlet NSPopUpButton *encodingPopUpButton;
@property IBOutlet NSMatrix *unitMatrix;
@property IBOutlet NSMatrix *priorityMatrix;
@property NSString *lastSavedPath;

@property NSWindow *lastActiveWindow;
@property NSMutableDictionary *lastColorDict;

@property IBOutlet NSColorWell *foregroundColorWell;
@property IBOutlet NSColorWell *backgroundColorWell;
@property IBOutlet NSColorWell *cursorColorWell;
@property IBOutlet NSColorWell *braceColorWell;
@property IBOutlet NSColorWell *commentColorWell;
@property IBOutlet NSColorWell *commandColorWell;
@property IBOutlet NSColorWell *invisibleColorWell;
@property IBOutlet NSColorWell *highlightedBraceColorWell;
@property IBOutlet NSColorWell *enclosedContentBackgroundColorWell;
@property IBOutlet NSColorWell *flashingBackgroundColorWell;
@property IBOutlet NSButton *makeatletterEnabledCheckBox;

@property IBOutlet NSViewController *autoDetectionTargetSettingViewController;
@property IBOutlet NSMatrix *autoDetectionTargetMatrix;

@property Converter *converter;
@property NSTask *runningTask;
@property NSPipe *outputPipe;
@property BOOL *taskKilled;

@end

@implementation ControllerG
@synthesize profileController;
@synthesize mainWindow;
@synthesize sourceTextView;
@synthesize outputDrawer;
@synthesize outputTextView;
@synthesize preambleWindow;
@synthesize preambleTextView;
@synthesize convertYenMarkMenuItem;
@synthesize outputDrawerMenuItem;
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
@synthesize transparentCheckBox;
@synthesize deleteDisplaySizeCheckBox;
@synthesize showOutputDrawerCheckBox;
@synthesize previewCheckBox;
@synthesize deleteTmpFileCheckBox;
@synthesize toClipboardCheckBox;
@synthesize embedSourceCheckBox;
@synthesize embedInIllustratorCheckBox;
@synthesize ungroupCheckBox;
@synthesize preferenceWindow;
@synthesize resolutionLabel;
@synthesize leftMarginLabel;
@synthesize rightMarginLabel;
@synthesize topMarginLabel;
@synthesize bottomMarginLabel;
@synthesize resolutionSlider;
@synthesize leftMarginSlider;
@synthesize rightMarginSlider;
@synthesize topMarginSlider;
@synthesize bottomMarginSlider;
@synthesize latexPathTextField;
@synthesize dviwarePathTextField;
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
@synthesize lastSavedPath;

@synthesize lastActiveWindow;
@synthesize lastColorDict;

@synthesize foregroundColorWell;
@synthesize backgroundColorWell;
@synthesize cursorColorWell;
@synthesize braceColorWell;
@synthesize commentColorWell;
@synthesize commandColorWell;
@synthesize invisibleColorWell;
@synthesize highlightedBraceColorWell;
@synthesize enclosedContentBackgroundColorWell;
@synthesize flashingBackgroundColorWell;
@synthesize makeatletterEnabledCheckBox;

@synthesize autoDetectionTargetSettingViewController;
@synthesize autoDetectionTargetMatrix;

@synthesize converter;
@synthesize runningTask;
@synthesize outputPipe;
@synthesize taskKilled;


#pragma mark - OutputController プロトコルの実装
- (void)exitCurrentThreadIfTaskKilled
{
    if (taskKilled) {
        taskKilled = NO;
        [NSThread.currentThread cancel];
    }
    
    if (NSThread.currentThread.isCancelled) {
        [self generationDidFinish];
        [NSThread exit];
    }
}

- (BOOL)execCommand:(NSString*)command atDirectory:(NSString*)path withArguments:(NSArray*)arguments quiet:(BOOL)quiet
{
    [self exitCurrentThreadIfTaskKilled];
    
    NSMutableString *cmdline = [NSMutableString string];
    [cmdline appendString:command];
    [cmdline appendString:@" "];
    
    for (NSString *argument in arguments) {
        [cmdline appendString:argument];
        [cmdline appendString:@" "];
    }
    [cmdline appendString:@" 2>&1"];
    [self appendOutputAndScroll:[NSString stringWithFormat:@"$ %@\n", cmdline] quiet:NO];
    
    runningTask = [NSTask new];
    outputPipe = [NSPipe pipe];
    [outputPipe.fileHandleForReading readInBackgroundAndNotify];
    
    runningTask.currentDirectoryPath = path;
    runningTask.launchPath = BASH_PATH;
    runningTask.standardOutput = outputPipe;
    runningTask.standardError = outputPipe;
    runningTask.arguments = @[@"-c", cmdline];
    taskKilled = NO;
    
    [runningTask launch];
    [runningTask waitUntilExit];
    
    [self appendOutputAndScroll:@"\n" quiet:NO];

    [self exitCurrentThreadIfTaskKilled];
    
    return (runningTask.terminationStatus == 0) ? YES : NO;
}

- (void)showMainWindow
{
	[mainWindow makeKeyAndOrderFront:nil];
}

- (void)appendOutputAndScrollOnMainThread:(NSString*)str
{
    [outputTextView.textStorage.mutableString appendString:str];
    [outputTextView scrollRangeToVisible:NSMakeRange(outputTextView.string.length, 0)]; // 最下部までスクロール
    outputTextView.font = sourceTextView.font;
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

- (void)showOutputDrawerOnMainThread
{
    outputDrawerMenuItem.state = YES;
    [outputDrawer open];
}

- (void)showOutputDrawer
{
    [self performSelectorOnMainThread:@selector(showOutputDrawerOnMainThread) withObject:nil waitUntilDone:YES];
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
    runErrorPanel(@"%@%@", aPath, localizedString(@"programNotFoundErrorMsg"));
}

- (void)showNotFoundError:(NSString*)aPath
{
    [self performSelectorOnMainThread:@selector(showNotFoundErrorOnMainThread:) withObject:aPath waitUntilDone:YES];
}

- (BOOL)latexExistsAtPath:(NSString*)latexPath dviwarePath:(NSString*)dviwarePath gsPath:(NSString*)gsPath
{
	NSFileManager *fileManager = NSFileManager.defaultManager;
	
	if (![fileManager fileExistsAtPath:latexPath.programPath]) {
		[self showNotFoundError:latexPath];
		return NO;
	}
	if (![fileManager fileExistsAtPath:dviwarePath.programPath]) {
		[self showNotFoundError:dviwarePath];
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

- (void)showFileGenerateErrorOnMainThread:(NSString*)aPath
{
    runErrorPanel(@"%@%@", aPath, localizedString(@"fileGenerateErrorMsg"));
}

- (void)showFileGenerateError:(NSString*)aPath
{
    [self performSelectorOnMainThread:@selector(showFileGenerateErrorOnMainThread:) withObject:aPath waitUntilDone:YES];
}

- (void)showExecErrorOnMainThread:(NSString*)command
{
    runErrorPanel(@"%@%@", command, localizedString(@"execErrorMsg"));
}

- (void)showExecError:(NSString*)command
{
    [self performSelectorOnMainThread:@selector(showExecErrorOnMainThread:) withObject:command waitUntilDone:YES];
}

- (void)showCannotOverwriteErrorOnMainThread:(NSString*)path
{
    runErrorPanel(@"%@%@", path, localizedString(@"cannotOverwriteErrorMsg"));
}

- (void)showCannotOverwriteError:(NSString*)path
{
    [self performSelectorOnMainThread:@selector(showCannotOverwriteErrorOnMainThread:) withObject:path waitUntilDone:YES];
}

- (void)showCannotCreateDirectoryErrorOnMainThread:(NSString*)dir
{
    runErrorPanel(@"%@%@", dir, localizedString(@"cannotCreateDirectoryErrorMsg"));
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

- (void)showErrorsIgnoredWarningOnMainThread
{
    runWarningPanel(localizedString(@"errorsIgnoredWarning"));
}

- (void)showErrorsIgnoredWarning
{
    [self performSelectorOnMainThread:@selector(showErrorsIgnoredWarningOnMainThread) withObject:nil waitUntilDone:YES];
}

- (void)showPageSkippedWarning:(NSArray*)pages
{
    [self appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: [%@] ", localizedString(@"Warning")] quiet:NO];
    
    if (pages.count > 1) {
        [self appendOutputAndScroll:[NSString stringWithFormat:localizedString(@"pagesSkippedWarning"), [pages componentsJoinedByString:@", "]]
                              quiet:NO];
    } else {
        [self appendOutputAndScroll:[NSString stringWithFormat:localizedString(@"pageSkippedWarning"), [pages[0] stringValue]]
                              quiet:NO];
    }

    [self appendOutputAndScroll:@"\n" quiet:NO];
}

- (void)showWhitePageWarning:(NSArray*)pages
{
    [self appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: [%@] ", localizedString(@"Warning")] quiet:NO];
    
    if (pages.count > 1) {
        [self appendOutputAndScroll:[NSString stringWithFormat:localizedString(@"whitePagesWarning"), [pages componentsJoinedByString:@", "]]
                              quiet:NO];
    } else {
        [self appendOutputAndScroll:[NSString stringWithFormat:localizedString(@"whitePageWarning"), [pages[0] stringValue]]
                              quiet:NO];
    }
    
    [self appendOutputAndScroll:@"\n" quiet:NO];
}

- (void)previewFilesOnMainThread:(NSArray*)parameters
{
    NSArray *files = (NSArray*)(parameters[0]);
    NSString *app = (NSString*)(parameters[1]);
    previewFiles(files, app);
}

- (void)previewFiles:(NSArray*)files withApplication:(NSString*)app
{
    [self performSelectorOnMainThread:@selector(previewFilesOnMainThread:) withObject:@[files, app] waitUntilDone:NO];
}

- (void)printResult:(NSArray*)generatedFiles quiet:(BOOL)quiet
{
    NSUInteger count = generatedFiles.count;
    
    if (count > 1) {
        [self appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: %@\n", [NSString stringWithFormat:localizedString(@"generatedFilesMessage"), count]]
                              quiet:NO];
    } else {
        [self appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: %@\n", [NSString stringWithFormat:localizedString(@"generatedFileMessage"), count]]
                              quiet:NO];
    }
}

#pragma mark - プロファイルの読み書き関連
- (void)loadSettingForTextField:(NSTextField*)textField fromProfile:(NSDictionary*)aProfile forKey:(NSString*)aKey
{
	NSString *tempStr = [aProfile stringForKey:aKey];
	
	if (tempStr) {
		textField.stringValue = tempStr;
	}
}

- (void)loadSettingForTextView:(NSTextView*)textView fromProfile:(NSDictionary*)aProfile forKey:(NSString*)aKey
{
	NSString *tempStr = [aProfile stringForKey:aKey];
	
	if (tempStr) {
		textView.textStorage.mutableString.string = tempStr;
	}
}

- (void)adoptProfile:(NSDictionary*)aProfile
{
    if (!aProfile) {
        return;
    }
    
    NSArray *keys = aProfile.allKeys;
	
	[self loadSettingForTextField:outputFileTextField fromProfile:aProfile forKey:OutputFileKey];
	
	showOutputDrawerCheckBox.state = [aProfile integerForKey:ShowOutputDrawerKey];
	previewCheckBox.state = [aProfile integerForKey:PreviewKey];
	deleteTmpFileCheckBox.state = [aProfile integerForKey:DeleteTmpFileKey];

    if ([keys containsObject:EmbedSourceKey]) {
        embedSourceCheckBox.state = [aProfile integerForKey:EmbedSourceKey];
    } else {
        embedSourceCheckBox.state = NSOnState;
    }

    toClipboardCheckBox.state = [aProfile integerForKey:CopyToClipboardKey];
    
	embedInIllustratorCheckBox.state = [aProfile integerForKey:EmbedInIllustratorKey];
	ungroupCheckBox.state = [aProfile integerForKey:UngroupKey];
	
	transparentCheckBox.state = [aProfile boolForKey:TransparentKey];
	textPdfCheckBox.state = ![aProfile boolForKey:GetOutlineKey];
    deleteDisplaySizeCheckBox.state = [aProfile boolForKey:DeleteDisplaySizeKey];

	ignoreErrorCheckBox.state = [aProfile boolForKey:IgnoreErrorKey];
	utfExportCheckBox.state = [aProfile boolForKey:UtfExportKey];
	
	convertYenMarkMenuItem.state = [aProfile boolForKey:ConvertYenMarkKey];
	
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
        tabWidthTextField.intValue = tabWidth;
    } else {
        tabWidthTextField.intValue = 4;
    }
    [tabWidthStepper takeIntValueFrom:tabWidthTextField];

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
    if ([keys containsObject:ForegroundColorKey]) {
        foregroundColorWell.color = [aProfile colorForKey:ForegroundColorKey];
    } else {
        foregroundColorWell.color = NSColor.textColor;
    }

    if ([keys containsObject:BackgroundColorKey]) {
        backgroundColorWell.color = [aProfile colorForKey:BackgroundColorKey];
    } else {
        backgroundColorWell.color = NSColor.controlBackgroundColor;
    }
    
    if ([keys containsObject:CursorColorKey]) {
        cursorColorWell.color = [aProfile colorForKey:CursorColorKey];
    } else {
        cursorColorWell.color = NSColor.blackColor;
    }
    
    if ([keys containsObject:BraceColorKey]) {
        braceColorWell.color = [aProfile colorForKey:BraceColorKey];
    } else {
        braceColorWell.color = NSColor.braceColor;
    }
    
    if ([keys containsObject:CommentColorKey]) {
        commentColorWell.color = [aProfile colorForKey:CommentColorKey];
    } else {
        commentColorWell.color = NSColor.commentColor;
    }
    
    if ([keys containsObject:CommandColorKey]) {
        commandColorWell.color = [aProfile colorForKey:CommandColorKey];
    } else {
        commandColorWell.color = NSColor.commandColor;
    }
    
    if ([keys containsObject:InvisibleColorKey]) {
        invisibleColorWell.color = [aProfile colorForKey:InvisibleColorKey];
    } else {
        invisibleColorWell.color = NSColor.invisibleColor;
    }
    
    if ([keys containsObject:HighlightedBraceColorKey]) {
        highlightedBraceColorWell.color = [aProfile colorForKey:HighlightedBraceColorKey];
    } else {
        highlightedBraceColorWell.color = NSColor.highlightedBraceColor;
    }
    
    if ([keys containsObject:EnclosedContentBackgroundColorKey]) {
        enclosedContentBackgroundColorWell.color = [aProfile colorForKey:EnclosedContentBackgroundColorKey];
    } else {
        enclosedContentBackgroundColorWell.color = NSColor.enclosedContentBackgroundColor;
    }

    if ([keys containsObject:FlashingBackgroundColorKey]) {
        flashingBackgroundColorWell.color = [aProfile colorForKey:FlashingBackgroundColorKey];
    } else {
        flashingBackgroundColorWell.color = NSColor.flashingBackgroundColor;
    }

    if ([keys containsObject:ColorPalleteColorKey]) {
        colorPalleteColorWell.color = [aProfile colorForKey:ColorPalleteColorKey];
    } else {
        colorPalleteColorWell.color = NSColor.redColor;
    }
    
    if ([keys containsObject:MakeatletterEnabledKey]) {
        makeatletterEnabledCheckBox.state = [aProfile boolForKey:MakeatletterEnabledKey];
    } else {
        makeatletterEnabledCheckBox.state = NSOnState;
    }

	autoCompleteMenuItem.state = [aProfile boolForKey:AutoCompleteKey];
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
	
	[self loadSettingForTextField:latexPathTextField fromProfile:aProfile forKey:LatexPathKey];
	[self loadSettingForTextField:dviwarePathTextField fromProfile:aProfile forKey:DviwarePathKey];
	[self loadSettingForTextField:gsPathTextField fromProfile:aProfile forKey:GsPathKey];
	
	[self loadSettingForTextField:resolutionLabel fromProfile:aProfile forKey:ResolutionLabelKey];
    [self loadSettingForTextField:leftMarginLabel fromProfile:aProfile forKey:LeftMarginLabelKey];
    [self loadSettingForTextField:rightMarginLabel fromProfile:aProfile forKey:RightMarginLabelKey];
    [self loadSettingForTextField:topMarginLabel fromProfile:aProfile forKey:TopMarginLabelKey];
    [self loadSettingForTextField:bottomMarginLabel fromProfile:aProfile forKey:BottomMarginLabelKey];
    
    numberOfCompilationTextField.intValue = MAX(1, [aProfile integerForKey:NumberOfCompilationKey]);
    [numberOfCompilationStepper takeIntValueFrom:numberOfCompilationTextField];
    
    resolutionSlider.floatValue = [aProfile integerForKey:ResolutionKey];
    leftMarginSlider.intValue = [aProfile integerForKey:LeftMarginKey];
    rightMarginSlider.intValue = [aProfile integerForKey:RightMarginKey];
    topMarginSlider.intValue = [aProfile integerForKey:TopMarginKey];
    bottomMarginSlider.intValue = [aProfile integerForKey:BottomMarginKey];
    
    NSInteger unitTag = [aProfile integerForKey:UnitKey];
    [unitMatrix selectCellWithTag:unitTag];
    
    NSInteger priorityTag = [aProfile integerForKey:PriorityKey];
    [priorityMatrix selectCellWithTag:priorityTag];

    if ([keys containsObject:AutoDetectionTargetKey]) {
        NSInteger autoDetectionTargetTag = [aProfile integerForKey:AutoDetectionTargetKey];
        [autoDetectionTargetMatrix selectCellWithTag:autoDetectionTargetTag];
    }

    [self loadSettingForTextView:preambleTextView fromProfile:aProfile forKey:PreambleKey];
    
    NSFont *aFont = [NSFont fontWithName:[aProfile stringForKey:SourceFontNameKey] size:[aProfile floatForKey:SourceFontSizeKey]];
    if (aFont) {
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
    
    NSString *inputSourceFilePath = [aProfile stringForKey:InputSourceFilePathKey];
    if (inputSourceFilePath) {
        inputSourceFileTextField.stringValue = inputSourceFilePath;
    }
    
    InputMethod inputMethod = [aProfile integerForKey:InputMethodKey];
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

- (BOOL)adoptProfileWithWindowFrameForName:(NSString*)profileName
{
	NSDictionary *aProfile = [profileController profileForName:profileName];
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
	
	return YES;
}



- (NSMutableDictionary*)currentProfile
{
	NSMutableDictionary *currentProfile = [NSMutableDictionary dictionary];
	@try {
        currentProfile[TeX2imgVersionKey] = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        
        currentProfile[XKey] = @(NSMinX(mainWindow.frame));
        currentProfile[YKey] = @(NSMinY(mainWindow.frame));
        currentProfile[MainWindowWidthKey] = @(NSWidth(mainWindow.frame));
        currentProfile[MainWindowHeightKey] = @(NSHeight(mainWindow.frame));
        currentProfile[OutputFileKey] = outputFileTextField.stringValue;
        
        currentProfile[ShowOutputDrawerKey] = @(showOutputDrawerCheckBox.state);
        currentProfile[PreviewKey] = @(previewCheckBox.state);
        currentProfile[DeleteTmpFileKey] = @(deleteTmpFileCheckBox.state);
        
        currentProfile[EmbedSourceKey] = @(embedSourceCheckBox.state);
        currentProfile[CopyToClipboardKey] = @(toClipboardCheckBox.state);
        currentProfile[EmbedInIllustratorKey] = @(embedInIllustratorCheckBox.state);
        currentProfile[UngroupKey] = @(ungroupCheckBox.state);
        
        currentProfile[TransparentKey] = @(transparentCheckBox.state);
        currentProfile[GetOutlineKey] = @(!textPdfCheckBox.state);
        currentProfile[DeleteDisplaySizeKey] = @(deleteDisplaySizeCheckBox.state);
        currentProfile[IgnoreErrorKey] = @(ignoreErrorCheckBox.state);
        currentProfile[UtfExportKey] = @(utfExportCheckBox.state);
        
        currentProfile[LatexPathKey] = latexPathTextField.stringValue;
        currentProfile[DviwarePathKey] = dviwarePathTextField.stringValue;
        currentProfile[GsPathKey] = gsPathTextField.stringValue;
        currentProfile[GuessCompilationKey] = @(guessCompilationButton.state);
        currentProfile[NumberOfCompilationKey] = @(numberOfCompilationTextField.integerValue);
        
        currentProfile[ResolutionLabelKey] = resolutionLabel.stringValue;
        currentProfile[LeftMarginLabelKey] = leftMarginLabel.stringValue;
        currentProfile[RightMarginLabelKey] = rightMarginLabel.stringValue;
        currentProfile[TopMarginLabelKey] = topMarginLabel.stringValue;
        currentProfile[BottomMarginLabelKey] = bottomMarginLabel.stringValue;
        
        currentProfile[ResolutionKey] = @(resolutionLabel.floatValue);
        currentProfile[LeftMarginKey] = @(leftMarginLabel.intValue);
        currentProfile[RightMarginKey] = @(rightMarginLabel.intValue);
        currentProfile[TopMarginKey] = @(topMarginLabel.intValue);
        currentProfile[BottomMarginKey] = @(bottomMarginLabel.intValue);
        
        NSInteger tabWidth = tabWidthTextField.integerValue;
        currentProfile[TabWidthKey] = @((tabWidth > 0) ? tabWidth : 4);
        
        currentProfile[TabIndentKey] = @(tabIndentCheckBox.state);
        
        currentProfile[WrapLineKey] = @(wrapLineCheckBox.state);
        
        currentProfile[UnitKey] = @(unitMatrix.selectedTag);
        currentProfile[PriorityKey] = @(priorityMatrix.selectedTag);
        
        currentProfile[AutoDetectionTargetKey] = @(autoDetectionTargetMatrix.selectedTag);
        
        currentProfile[ConvertYenMarkKey] = @(convertYenMarkMenuItem.state);
        currentProfile[FlashInMovingKey] = @(flashInMovingCheckBox.state);
        currentProfile[HighlightContentKey] = @(highlightContentCheckBox.state);
        currentProfile[BeepKey] = @(beepCheckBox.state);
        currentProfile[FlashBackgroundKey] = @(flashBackgroundCheckBox.state);
        currentProfile[CheckBraceKey] = @(checkBraceCheckBox.state);
        currentProfile[CheckBracketKey] = @(checkBracketCheckBox.state);
        currentProfile[CheckSquareBracketKey] = @(checkSquareCheckBox.state);
        currentProfile[CheckParenKey] = @(checkParenCheckBox.state);
        currentProfile[AutoCompleteKey] = @(autoCompleteMenuItem.state);
        currentProfile[ShowTabCharacterKey] = @(showTabCharacterCheckBox.state);
        currentProfile[ShowSpaceCharacterKey] = @(showSpaceCharacterCheckBox.state);
        currentProfile[ShowFullwidthSpaceCharacterKey] = @(showFullwidthSpaceCharacterCheckBox.state);
        currentProfile[ShowNewLineCharacterKey] = @(showNewLineCharacterCheckBox.state);
        currentProfile[SourceFontNameKey] = sourceTextView.font.fontName;
        currentProfile[SourceFontSizeKey] = @(sourceTextView.font.pointSize);
        
        currentProfile[PreambleKey] = [NSString stringWithString:preambleTextView.textStorage.string]; // stringWithString は必須
        
        currentProfile[InputMethodKey] = (directInputButton.state == NSOnState) ? @(DIRECT) : @(FROMFILE);
        currentProfile[InputSourceFilePathKey] = inputSourceFileTextField.stringValue;
        
        currentProfile[ForegroundColorKey] = foregroundColorWell.color.serializedString;
        currentProfile[BackgroundColorKey] = backgroundColorWell.color.serializedString;
        currentProfile[CursorColorKey] = cursorColorWell.color.serializedString;
        currentProfile[BraceColorKey] = braceColorWell.color.serializedString;
        currentProfile[CommentColorKey] = commentColorWell.color.serializedString;
        currentProfile[CommandColorKey] = commandColorWell.color.serializedString;
        currentProfile[InvisibleColorKey] = invisibleColorWell.color.serializedString;
        currentProfile[HighlightedBraceColorKey] = highlightedBraceColorWell.color.serializedString;
        currentProfile[EnclosedContentBackgroundColorKey] = enclosedContentBackgroundColorWell.color.serializedString;
        currentProfile[FlashingBackgroundColorKey] = flashingBackgroundColorWell.color.serializedString;
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

#pragma mark - 他のメソッドから呼び出されるユーティリティメソッド
- (NSString*)searchProgram:(NSString*)programName
{
    NSTask *task = [NSTask new];
    NSPipe *pipe = [NSPipe pipe];
    task.launchPath = BASH_PATH;
    task.arguments = @[@"-c", @"eval `/usr/libexec/path_helper -s`; echo $PATH"];
    task.standardOutput = pipe;
    [task launch];
    [task waitUntilExit];
    
    NSMutableArray *searchPaths = [NSMutableArray arrayWithArray:[pipe.stringValue componentsSeparatedByString:@":"]];

    [searchPaths addObjectsFromArray: @[
                                        @"/Applications/Ghostscript.app/bin",
                                        @"/Applications/TeXLive/texlive/2016/bin/x86_64-darwin",
                                        @"/Applications/TeXLive/texlive/2015/bin/x86_64-darwin",
                                        @"/Applications/TeXLive/texlive/2014/bin/x86_64-darwin",
                                        @"/Applications/TeXLive/texlive/2013/bin/x86_64-darwin",
                                        @"/usr/local/texlive/2016/bin/x86_64-darwin",
                                        @"/usr/local/texlive/2015/bin/x86_64-darwin",
                                        @"/usr/local/texlive/2014/bin/x86_64-darwin",
                                        @"/usr/local/texlive/2013/bin/x86_64-darwin",
                                        @"/opt/local/texlive/2016/bin/x86_64-darwin",
                                        @"/opt/local/texlive/2015/bin/x86_64-darwin",
                                        @"/opt/local/texlive/2014/bin/x86_64-darwin",
                                        @"/opt/local/texlive/2013/bin/x86_64-darwin",
                                        @"/opt/texlive/2016/bin/x86_64-darwin",
                                        @"/opt/texlive/2015/bin/x86_64-darwin",
                                        @"/opt/texlive/2014/bin/x86_64-darwin",
                                        @"/opt/texlive/2013/bin/x86_64-darwin",
                                        @"/Library/TeX/texbin",
                                        @"/usr/texbin",
                                        @"/Applications/pTeX.app/teTeX/bin",
                                        @"/Applications/UpTeX.app/teTeX/bin",
                                        @"/usr/local/teTeX/bin",
                                        @"/usr/local/bin",
                                        @"/opt/local/bin",
                                        @"/sw/bin"
                                        ]];
    
	NSFileManager *fileManager = NSFileManager.defaultManager;
	
	for (NSString *aPath in searchPaths) {
		NSString *aFullPath = [aPath stringByAppendingPathComponent:programName];
        if ([fileManager fileExistsAtPath:aFullPath]) {
            return aFullPath;
        }
	}
	
	return nil;
}

#pragma mark - プリアンブルの管理
- (void)constructTemplatePopup:(id)sender
{
    NSMenu *menu = templatePopupButton.menu;
    
    while (menu.numberOfItems > 5) { // この数はテンプレートメニューの初期項目数
        [menu removeItemAtIndex:1];
    }
    
    NSString *templateDirectoryPath = self.templateDirectoryPath;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSEnumerator *enumerator = [fileManager contentsOfDirectoryAtPath:templateDirectoryPath error:nil].reverseObjectEnumerator;
    
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        NSString *fullPath = [templateDirectoryPath stringByAppendingPathComponent:filename];
        
        if ([filename hasSuffix:@"tex"]) {
            NSString *title = filename.stringByDeletingPathExtension;
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(adoptPreambleTemplate:) keyEquivalent:@""];
            menuItem.target = self;
            menuItem.toolTip = fullPath; // tooltip文字列の部分にフルパスを保持
            [menu insertItem:menuItem atIndex:1];
        }
        
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
            NSMenuItem *itemWithSubmenu = [[NSMenuItem alloc] initWithTitle:filename action:nil keyEquivalent:@""];
            NSMenu *submenu = [NSMenu new];
            submenu.autoenablesItems = NO;
            [self constructTemplatePopupRecursivelyAtDirectory:[templateDirectoryPath stringByAppendingPathComponent:filename] parentMenu:submenu];
            itemWithSubmenu.submenu = submenu;
            [menu insertItem:itemWithSubmenu atIndex:1];
        }
    }
}

- (void)constructTemplatePopupRecursivelyAtDirectory:(NSString*)directory parentMenu:(NSMenu*)menu
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:directory error:nil];
    
    for (NSString *filename in files) {
        NSString *fullPath = [directory stringByAppendingPathComponent:filename];
        
        if ([filename hasSuffix:@"tex"]) {
            NSString *title = filename.stringByDeletingPathExtension;
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(adoptPreambleTemplate:) keyEquivalent:@""];
            menuItem.target = self;
            menuItem.toolTip = fullPath; // tooltip文字列の部分にフルパスを保持
            [menu addItem:menuItem];
        }
        
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
            NSMenuItem *itemWithSubmenu = [[NSMenuItem alloc] initWithTitle:filename action:nil keyEquivalent:@""];
            NSMenu *submenu = [NSMenu new];
            submenu.autoenablesItems = NO;
            [self constructTemplatePopupRecursivelyAtDirectory:[directory stringByAppendingPathComponent:filename] parentMenu:submenu];
            itemWithSubmenu.submenu = submenu;
            [menu addItem:itemWithSubmenu];
        }
    }
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
    
    if (![fileManager fileExistsAtPath:templateDirectoryPath isDirectory:nil]) {
        [fileManager createDirectoryAtPath:templateDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    system([NSString stringWithFormat:@"/bin/cp -p \"%@\"/* \"%@\"", originalTemplateDirectory, self.templateDirectoryPath].UTF8String);
}


#pragma mark - デリゲート・ノティフィケーションのコールバック
- (void)awakeFromNib
{
	//	以下は Interface Builder 上で設定できる
	//	[mainWindow setReleasedWhenClosed:NO];
	//	[preambleWindow setReleasedWhenClosed:NO];

    lastColorDict = [NSMutableDictionary dictionary];

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
                  object:preambleWindow];
    [aCenter addObserver:self
                selector:@selector(preferenceWindowDidBecomeKey:)
                    name:NSWindowDidBecomeKeyNotification
                  object:preferenceWindow];
    [aCenter addObserver:self
                selector:@selector(colorPalleteWindowDidBecomeKey:)
                    name:NSWindowDidBecomeKeyNotification
                  object:colorPalleteWindow];
    
    // コンパイル回数の変更
    [aCenter addObserver:self
                selector:@selector(refreshNumberOfCompilation:)
                    name:NSControlTextDidChangeNotification
                  object:numberOfCompilationTextField];

    // タブ幅の変更
    [aCenter addObserver:self
                selector:@selector(refreshTextView:)
                    name:NSControlTextDidChangeNotification
                  object:tabWidthTextField];
	
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
    
    // 自動判定エンジン選択ポップアップの色設定
    [autoDetectionTargetMatrix.cells enumerateObjectsUsingBlock:^(NSButtonCell *cell, NSUInteger idx, BOOL *stop){
        NSMutableAttributedString *colorTitle =
        [[NSMutableAttributedString alloc] initWithAttributedString:cell.attributedTitle];
        
        [colorTitle addAttribute:NSForegroundColorAttributeName
                           value:NSColor.textColor
                           range:NSMakeRange(0, colorTitle.length)];
        
        cell.attributedTitle = colorTitle;
    }];
	
	// 保存された設定を読み込む
	NSFileManager *fileManager = NSFileManager.defaultManager;
	NSString *plistFile = [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", NSHomeDirectory(), [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
    
	
	BOOL loadLastProfileSuccess = NO;
	
	if ([fileManager fileExistsAtPath:plistFile]) {
		[profileController loadProfilesFromPlist];
		loadLastProfileSuccess = [self adoptProfileWithWindowFrameForName:AutoSavedProfileName];
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
	unichar esc = 0x001B;
	commandCompletionChar = [NSString stringWithCharacters:&esc length:1];
	NSData 	*myData = nil;

	NSString *completionPath = @"~/Library/TeXShop/CommandCompletion/CommandCompletion.txt".stringByStandardizingPath;
	if ([fileManager fileExistsAtPath:completionPath])
		myData = [NSData dataWithContentsOfFile:completionPath];
	
	if (myData) {
		NSStringEncoding myEncoding = NSUTF8StringEncoding;
		commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding:myEncoding];
		if (!commandCompletionList) {
			commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding:myEncoding];
		}
		
		[commandCompletionList insertString:@"\n" atIndex:0];
        if ([commandCompletionList characterAtIndex:commandCompletionList.length-1] != '\n') {
			[commandCompletionList appendString:@"\n"];
        }
	}

    // Application Support の準備
    NSString *templateDirectoryPath = self.templateDirectoryPath;
    if (![fileManager fileExistsAtPath:templateDirectoryPath isDirectory:nil]) {
        // 初回起動時には app bundle 内のテンプレートをコピー
        [self restoreDefaultTemplatesLogic];
    }
    
}

- (void)loadDefaultFont
{
    NSFont *defaultFont = [NSFont fontWithName:@"Osaka-Mono" size:13];
    if (defaultFont) {
        sourceTextView.font = defaultFont;
        preambleTextView.font = defaultFont;
        [self setupFontTextField:defaultFont];
    }
}

- (IBAction)loadDefaultColors:(id)sender
{
    if (sender && !runConfirmPanel(localizedString(@"restoreColorsConfirmationMsg"))) {
        return;
    }
    
    foregroundColorWell.color = NSColor.textColor;
    backgroundColorWell.color = NSColor.controlBackgroundColor;
    cursorColorWell.color = NSColor.blackColor;
    braceColorWell.color = NSColor.braceColor;
    commentColorWell.color = NSColor.commentColor;
    commandColorWell.color = NSColor.commandColor;
    invisibleColorWell.color = NSColor.invisibleColor;
    highlightedBraceColorWell.color = NSColor.highlightedBraceColor;
    enclosedContentBackgroundColorWell.color = NSColor.enclosedContentBackgroundColor;
    flashingBackgroundColorWell.color = NSColor.flashingBackgroundColor;
    
    [foregroundColorWell saveColorToMutableDictionary:lastColorDict];
    [backgroundColorWell saveColorToMutableDictionary:lastColorDict];
    [cursorColorWell saveColorToMutableDictionary:lastColorDict];
    [braceColorWell saveColorToMutableDictionary:lastColorDict];
    [commentColorWell saveColorToMutableDictionary:lastColorDict];
    [commandColorWell saveColorToMutableDictionary:lastColorDict];
    [invisibleColorWell saveColorToMutableDictionary:lastColorDict];
    [highlightedBraceColorWell saveColorToMutableDictionary:lastColorDict];
    [enclosedContentBackgroundColorWell saveColorToMutableDictionary:lastColorDict];
    [flashingBackgroundColorWell saveColorToMutableDictionary:lastColorDict];
    
    makeatletterEnabledCheckBox.state = NSOnState;

    [sourceTextView colorizeText];
    [preambleTextView colorizeText];
}

- (void)setupFontTextField:(NSFont*)font
{
    fontTextField.stringValue = [NSString stringWithFormat:@"%@ - %.1fpt", font.displayName, font.pointSize];
}

- (void)showAutoDetectionResult:(NSDictionary*)parameters
{
    runOkPanel(parameters[@"Title"],
               @"%@\n%@\n%@\n%@\n%@",
               parameters[@"Msg1"],
               parameters[LatexPathKey],
               parameters[DviwarePathKey],
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

	[profileController updateProfile:self.currentProfile forName:AutoSavedProfileName];
	[profileController saveProfiles];
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)closeOtherWindows:(NSNotification*)aNotification
{
	[preambleWindow close];
	[preferenceWindow close];
}

- (void)uncheckOutputDrawerMenuItem:(NSNotification*)aNotification
{
	outputDrawerMenuItem.state = NO;
}

- (void)uncheckPreambleWindowMenuItem:(NSNotification*)aNotification
{
	preambleWindowMenuItem.state = NO;
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

- (NSArray*)analyzeContents:(NSString*)contents
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
    NSArray *parts = [self analyzeContents:contents];
    NSString *preamble = (NSString*)(parts[0]);
    NSString *body = (NSString*)(parts[1]);
    
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

- (void)importSourceLogic:(NSString*)inputPath
{
    [NSApp activateIgnoringOtherApps:YES];
    if (runConfirmPanel(localizedString(@"overwriteContentsWarningMsg"))) {

        NSString *contents = nil;
        
        if ([inputPath.pathExtension isEqualToString:@"tex"]) { // TeX ソースのインプット
            NSData *data = [NSData dataWithContentsOfFile:inputPath];
            NSStringEncoding detectedEncoding;
            contents = [NSString stringWithAutoEncodingDetectionOfData:data detectedEncoding:&detectedEncoding];
        } else { // 画像ファイルのインプット
            int bufferLength = getxattr(inputPath.UTF8String, EA_Key, NULL, 0, 0, 0); // EAを取得
            if (bufferLength < 0) { // ソース情報が含まれない画像ファイルの場合はエラー
                runErrorPanel(localizedString(@"doesNotContainSource"), inputPath);
                return;
            } else { // ソース情報が含まれる画像ファイルの場合はそれをEAから取得して contents にセット（EAに保存されたソースは常にUTF8）
                char *buffer = malloc(bufferLength);
                getxattr(inputPath.UTF8String, EA_Key, buffer, bufferLength, 0, 0);
                contents = [[NSString alloc] initWithBytes:buffer length:bufferLength encoding:NSUTF8StringEncoding];
                free(buffer);
            }
        }
        
        if (contents) {
            [self placeImportedSource:contents];
        } else {
            runErrorPanel(localizedString(@"cannotReadErrorMsg"), inputPath);
        }
    }
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
            [self importSourceLogic:openPanel.URL.path];
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
            lastSavedPath = outputPath;
            NSString *preamble = preambleTextView.textStorage.mutableString;
            NSString *body = sourceTextView.textStorage.mutableString;
            NSString *contents = [NSString stringWithFormat:@"%@\n\\begin{document}\n%@\n\\end{document}\n", preamble, body];
            NSStringEncoding encoding = [self stringEncodingFromEncodingOption:[self.currentProfile stringForKey:EncodingKey]];
            
            if (![contents writeToFile:outputPath atomically:YES encoding:encoding error:nil]) {
                runErrorPanel(localizedString(@"cannotWriteErrorMsg"), outputPath);
            }
        }
    }];
}

#pragma mark - Drag & Drop

- (void)textViewDroppedFile:(NSString*)file;
{
    [self importSourceLogic:file];
}

#pragma mark - 色選択パネル
- (IBAction)toggleColorPalleteWindow:(id)sender {
    if (colorPalleteWindow.isVisible) {
        [colorPalleteWindow close];
    } else {
        colorPalleteWindowMenuItem.state = YES;
        [colorPalleteWindow makeKeyAndOrderFront:nil];
        [colorStyleMatrix sendAction];
    }
}


- (IBAction)colorPalleteColorSet:(id)sender {
    if (!colorPalleteWindow.isKeyWindow) {
        return;
    }

    [colorPalleteColorWell saveColorToMutableDictionary:lastColorDict];

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
    colorPalleteWindowMenuItem.state = NO;
    if (NSColorPanel.sharedColorPanelExists) {
        [NSColorPanel.sharedColorPanel orderOut:self];
    }
}

- (void)preferenceWindowDidBecomeKey:(NSNotification*)aNotification
{
    lastActiveWindow = aNotification.object;
    
    [foregroundColorWell restoreColorFromDictionary:lastColorDict];
    [backgroundColorWell restoreColorFromDictionary:lastColorDict];
    [cursorColorWell restoreColorFromDictionary:lastColorDict];
    [braceColorWell restoreColorFromDictionary:lastColorDict];
    [commentColorWell restoreColorFromDictionary:lastColorDict];
    [commandColorWell restoreColorFromDictionary:lastColorDict];
    [invisibleColorWell restoreColorFromDictionary:lastColorDict];
    [highlightedBraceColorWell restoreColorFromDictionary:lastColorDict];
    [enclosedContentBackgroundColorWell restoreColorFromDictionary:lastColorDict];
    [flashingBackgroundColorWell restoreColorFromDictionary:lastColorDict];
}

- (void)colorPalleteWindowDidBecomeKey:(NSNotification*)aNotification
{
    [colorPalleteColorWell restoreColorFromDictionary:lastColorDict];
}

- (void)closeColorPanel
{
    [foregroundColorWell deactivate];
    [backgroundColorWell deactivate];
    [cursorColorWell deactivate];
    [braceColorWell deactivate];
    [commentColorWell deactivate];
    [commandColorWell deactivate];
    [invisibleColorWell deactivate];
    [highlightedBraceColorWell deactivate];
    [enclosedContentBackgroundColorWell deactivate];
    [flashingBackgroundColorWell deactivate];
    
    [colorPalleteColorWell deactivate];
    
    [NSColorPanel.sharedColorPanel performSelector:@selector(orderOut:) withObject:self afterDelay:0];

    [foregroundColorWell restoreColorFromDictionary:lastColorDict];
    [backgroundColorWell restoreColorFromDictionary:lastColorDict];
    [cursorColorWell restoreColorFromDictionary:lastColorDict];
    [braceColorWell restoreColorFromDictionary:lastColorDict];
    [commentColorWell restoreColorFromDictionary:lastColorDict];
    [commandColorWell restoreColorFromDictionary:lastColorDict];
    [invisibleColorWell restoreColorFromDictionary:lastColorDict];
    [highlightedBraceColorWell restoreColorFromDictionary:lastColorDict];
    [enclosedContentBackgroundColorWell restoreColorFromDictionary:lastColorDict];
    [flashingBackgroundColorWell restoreColorFromDictionary:lastColorDict];

    [colorPalleteColorWell restoreColorFromDictionary:lastColorDict];
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
    
    NSButton* cancelButton = [NSButton new];
    cancelButton.title = localizedString(@"Cancel");
    cancelButton.frame = NSMakeRect(dialogSize.width - 206, 12, 96, 32);
    cancelButton.bezelStyle = NSRoundedBezelStyle;
    cancelButton.autoresizingMask = NSViewMinXMargin;
    cancelButton.keyEquivalent = @"\033";
    cancelButton.target = self;
    cancelButton.action = @selector(dialogCancel:);
    [dialog.contentView addSubview:cancelButton];
    
    NSButton* okButton = [NSButton new];
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
        
        if ([fileManager fileExistsAtPath:filePath isDirectory:nil]
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
            inputSourceFileTextField.stringValue = openPanel.URL.path;
        }
    }];
    
}

- (IBAction)showSavePanel:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = TargetExtensionsArray;
    savePanel.extensionHidden = NO;
    savePanel.canSelectHiddenExtension = NO;
    
    NSString *defaultFilePath = outputFileTextField.stringValue;
    savePanel.nameFieldStringValue = defaultFilePath.lastPathComponent;
        savePanel.directoryURL = [NSURL fileURLWithPath:defaultFilePath.stringByDeletingLastPathComponent];
    
    [savePanel beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            outputFileTextField.stringValue = savePanel.URL.path;
        }
    }];
}

- (IBAction)toggleMenuItem:(id)sender
{
    [sender setState:![sender state]];
    [self refreshTextView:sender];
}

- (IBAction)refreshTextView:(id)sender
{
    [tabWidthStepper takeIntValueFrom:tabWidthTextField];
    [sourceTextView refreshWordWrap];
    [sourceTextView colorizeText];
    [sourceTextView fixupTabs];
    [preambleTextView refreshWordWrap];
    [preambleTextView colorizeText];
    [preambleTextView fixupTabs];
}

- (IBAction)tabWidthStepperPressed:(id)sender
{
    [tabWidthTextField takeIntValueFrom:tabWidthStepper];
    [self refreshTextView:sender];
}

- (void)refreshNumberOfCompilation:(id)sender
{
    [numberOfCompilationStepper takeIntValueFrom:numberOfCompilationTextField];
}

- (IBAction)toggleOutputDrawer:(id)sender
{
	if (outputDrawer.state == NSDrawerOpenState) {
		outputDrawerMenuItem.state = NO;
		[outputDrawer close];
	} else {
		[self showOutputDrawer];
	}
}

- (IBAction)togglePreambleWindow:(id)sender
{
	if (preambleWindow.isVisible) {
		[preambleWindow close];
	} else {
		preambleWindowMenuItem.state = YES;

		NSRect mainWindowRect = mainWindow.frame;
		NSRect preambleWindowRect = preambleWindow.frame;
		[preambleWindow setFrame:NSMakeRect(NSMinX(mainWindowRect) - NSWidth(preambleWindowRect), 
											NSMinY(mainWindowRect) + NSHeight(mainWindowRect) - NSHeight(preambleWindowRect), 
											NSWidth(preambleWindowRect), NSHeight(preambleWindowRect))
						 display:NO];
		[preambleWindow makeKeyAndOrderFront:nil];
        [preambleTextView colorizeText];
	}
    
}

- (IBAction)closeWindow:(id)sender
{
	[[NSApp keyWindow] close];
}

- (IBAction)showFontPanelOfSource:(id)sender
{
    NSFontManager *fontMgr = NSFontManager.sharedFontManager;
    fontMgr.target = self;
    fontMgr.action = @selector(changeFont:);
    
    NSFontPanel *panel = [fontMgr fontPanel:YES];
    [panel setPanelFont:sourceTextView.font isMultiple:NO];
    [panel makeKeyAndOrderFront:self];
    panel.enabled = YES;
}

- (void)changeFont:(id)sender
{
    NSFont *font = NSFontManager.sharedFontManager.selectedFont;
    [self setupFontTextField:font];
    sourceTextView.font = font;
    preambleTextView.font = font;
    outputTextView.font = font;
}

- (IBAction)colorSettingChanged:(id)sender
{
    if (!preferenceWindow.isKeyWindow || ![sender isKindOfClass:NSColorWell.class]) {
        return;
    }
    
    [(NSColorWell*)sender saveColorToMutableDictionary:lastColorDict];

    [sourceTextView performSelector:@selector(textViewDidChangeSelection:) withObject:nil];
    [preambleTextView performSelector:@selector(textViewDidChangeSelection:) withObject:nil];
}

- (void)searchProgramsLogic:(NSDictionary*)parameters
{
    NSString *latexPath;
    NSString *dviwarePath;
    NSString *gsPath;
    
    NSString *templateName = [autoDetectionTargetMatrix.selectedCell title];
    NSString *engineName = [templateName.lowercaseString componentsSeparatedByString:@" "][0];
    NSString *dviwareName = ([templateName rangeOfString:@"dvips"].location == NSNotFound) ? @"dvipdfmx" : @"dvips";
    
    if (!(latexPath = [self searchProgram:engineName])) {
        latexPath = @"";
        [self showNotFoundError:@"LaTeX"];
    }
    if (!(dviwarePath = [self searchProgram:dviwareName])) {
        dviwarePath = @"";
        [self showNotFoundError:@"DVIware"];
    }
    if (!(gsPath = [self searchProgram:@"gs"])) {
        gsPath = @"";
        [self showNotFoundError:@"ghostscript"];
    }
    
    dviwarePath = [dviwarePath stringByAppendingString:([dviwareName isEqualToString:@"dvipdfmx"] ? @" -vv" : @" -Ppdf")];
    
    latexPathTextField.stringValue = latexPath;
    dviwarePathTextField.stringValue = dviwarePath;
    gsPathTextField.stringValue = gsPath;
    
    [self performSelectorOnMainThread:@selector(showAutoDetectionResult:)
                           withObject:@{
                                        @"Title": parameters[@"Title"],
                                        @"Msg1": parameters[@"Msg1"],
                                        @"Msg2": parameters[@"Msg2"],
                                        LatexPathKey: latexPath,
                                        DviwarePathKey: dviwarePath,
                                        GsPathKey: gsPath
                                        }
                        waitUntilDone:[parameters[@"waitUntilDone"] boolValue]];
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

- (void)generationDidFinishOnMainThreadAfterDelay
{
    [converter deleteTemporaryFiles]; // スレッドが中断されたときにも確実に中間ファイルを削除するように
    generateButton.title = localizedString(@"Generate");
    generateButton.action = @selector(generate:);
    generateMenuItem.enabled = YES;
    abortMenuItem.enabled = NO;
}

- (void)generationDidFinishOnMainThread
{
    [self performSelector:@selector(generationDidFinishOnMainThreadAfterDelay) withObject:nil afterDelay:0.3];
}

- (void)generationDidFinish
{
    [self performSelectorOnMainThread:@selector(generationDidFinishOnMainThread) withObject:nil waitUntilDone:YES];
}

- (void)printCurrentStatus:(NSDictionary*)aProfile
{
    NSMutableString *output = [NSMutableString string];
    
    [output appendString:@"************************************\n"];
    [output appendString:@"  TeX2img settings\n"];
    [output appendString:@"************************************\n"];
    
    NSString *outputFilePath = [aProfile stringForKey:OutputFileKey];
    [output appendFormat:@"Output File: %@\n", outputFilePath];
    
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
    
    [output appendFormat:@"DVIware: %@\n", [aProfile stringForKey:DviwarePathKey]];
    [output appendFormat:@"Ghostscript: %@\n", [aProfile stringForKey:GsPathKey]];
    
    [output appendFormat:@"Resolution level: %.1f\n", [aProfile floatForKey:ResolutionKey]];
    
    NSString *ext = outputFilePath.pathExtension;
    NSString *unit = (([aProfile integerForKey:UnitKey] == PX_UNIT_TAG) &&
                      ([ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"] || [ext isEqualToString:@"tiff"])) ?
                        @"px" : @"bp";
    
    [output appendFormat:@"Left   margin: %ld%@\n", [aProfile integerForKey:LeftMarginKey], unit];
    [output appendFormat:@"Right  margin: %ld%@\n", [aProfile integerForKey:RightMarginKey], unit];
    [output appendFormat:@"Top    margin: %ld%@\n", [aProfile integerForKey:TopMarginKey], unit];
    [output appendFormat:@"Bottom margin: %ld%@\n", [aProfile integerForKey:BottomMarginKey], unit];
    
    if ([ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"] || [ext isEqualToString:@"tiff"]) {
        [output appendFormat:@"Transparent PNG/GIF/TIFF: %@\n", [aProfile boolForKey:TransparentKey] ? ENABLED : DISABLED];
    }
    if ([ext isEqualToString:@"pdf"]) {
        [output appendFormat:@"Text embedded PDF: %@\n", [aProfile boolForKey:GetOutlineKey] ? DISABLED : ENABLED];
    }
    if ([ext isEqualToString:@"svg"]) {
        [output appendFormat:@"Delete width and height attributes of SVG: %@\n", [aProfile boolForKey:DeleteDisplaySizeKey] ? ENABLED : DISABLED];
    }
    
    [output appendFormat:@"Ignore nonfatal errors: %@\n", [aProfile boolForKey:IgnoreErrorKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Substitute \\UTF{xxxx} for non-JIS X 0208 characters: %@\n", [aProfile boolForKey:UtfExportKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Conversion mode: %@ priority mode\n", ([aProfile integerForKey:PriorityKey] == SPEED_PRIORITY_TAG) ? @"speed" : @"quality"];
    [output appendFormat:@"Preview generated files: %@\n", [aProfile boolForKey:PreviewKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Delete temporary files: %@\n", [aProfile boolForKey:DeleteTmpFileKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Embed the source in generated files: %@\n", [aProfile boolForKey:EmbedSourceKey] ? ENABLED : DISABLED];
    [output appendFormat:@"Copy generated files to the clipboard: %@\n", [aProfile boolForKey:CopyToClipboardKey] ? ENABLED : DISABLED];
    
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
    NSMutableDictionary *aProfile = self.currentProfile;
    aProfile[EpstopdfPathKey] = [NSBundle.mainBundle pathForResource:@"epstopdf" ofType:nil];
    aProfile[MudrawPathKey] = [[NSBundle.mainBundle pathForResource:@"mupdf" ofType:nil] stringByAppendingPathComponent:@"mudraw"];
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
            inputSourceFilePath = [aProfile stringForKey:InputSourceFilePathKey];
            if ([NSFileManager.defaultManager fileExistsAtPath:inputSourceFilePath]) {
                if ([InputExtensionsArray containsObject:inputSourceFilePath.pathExtension]) {
                    [NSThread detachNewThreadSelector:@selector(compileAndConvertWithInputPath:) toTarget:converter withObject:inputSourceFilePath];
                } else {
                    runErrorPanel(localizedString(@"inputFileTypeErrorMsg"), inputSourceFilePath);
                    [self generationDidFinish];
                }
            } else {
                runErrorPanel(localizedString(@"inputFileNotFoundErrorMsg"), inputSourceFilePath);
                [self generationDidFinish];
            }
            break;
        default:
            break;
    }
    
}

- (IBAction)generate:(id)sender
{
    if (showOutputDrawerCheckBox.state) {
        [self showOutputDrawer];
    }
	
    generateButton.title = localizedString(@"Abort");
    generateButton.action = @selector(abortCompilation:);
	generateMenuItem.enabled = NO;
    abortMenuItem.enabled = YES;
    
    [self generateImage];
}

- (IBAction)abortCompilation:(id)sender
{
    if (runningTask && runningTask.isRunning) {
        taskKilled = YES;
        [runningTask terminate];
        runningTask = nil;
        [self appendOutputAndScroll:[NSString stringWithFormat:@"\n\nTeX2img: %@\n\n", localizedString(@"processAborted")] quiet:NO];
        [self generationDidFinish];
    }
}

- (IBAction)showAutoDetectionTargetSettingPopover:(id)sender
{
    NSPopover *popover = [NSPopover new];
    popover.contentViewController = autoDetectionTargetSettingViewController;
    popover.behavior = NSPopoverBehaviorTransient;
    NSRect rect = ((NSButton*)sender).frame;
    rect = NSMakeRect(rect.origin.x + 25, rect.origin.y + 24, rect.size.width, rect.size.height);

    [popover showRelativeToRect:rect ofView:preferenceWindow.contentView preferredEdge:NSMaxXEdge];
}

@end
