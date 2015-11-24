#import <Quartz/Quartz.h>
#import <sys/xattr.h>
#import "ControllerG.h"
#import "NSDictionary-Extension.h"
#import "NSString-Extension.h"
#import "NSMutableString-Extension.h"
#import "NSFileManager-Extension.h"
#import "NSColor-Extension.h"
#import "NSColorWell-Extension.h"
#import "NSPipe-Extension.h"
#import "NSMatrix-Extension.h"
#import "PDFDocument-Extension.h"
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
@property (nonatomic, strong) IBOutlet NSDrawer *outputDrawer;
@property (nonatomic, strong) IBOutlet NSTextView *outputTextView;
@property (nonatomic, strong) IBOutlet NSTextField *outputFileTextField;
@property (nonatomic, strong) IBOutlet NSPopUpButton *templatePopupButton;

@property (nonatomic, strong) IBOutlet NSWindow *preambleWindow;
@property (nonatomic, strong) IBOutlet TeXTextView *preambleTextView;
@property (nonatomic, strong) IBOutlet NSMenuItem *convertYenMarkMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *outputDrawerMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *preambleWindowMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *generateMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *abortMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem *autoCompleteMenuItem;

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
@property (nonatomic, strong) IBOutlet NSButton *transparentCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *plainTextCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *deleteDisplaySizeCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *mergeOutputsCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *keepPageSizeCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *showOutputDrawerCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *previewCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *deleteTmpFileCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *toClipboardCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *embedSourceCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *embedInIllustratorCheckBox;
@property (nonatomic, strong) IBOutlet NSButton *ungroupCheckBox;
@property (nonatomic, strong) IBOutlet NSWindow *preferenceWindow;

@property (nonatomic, strong) IBOutlet NSTextField *resolutionTextField;
@property (nonatomic, strong) IBOutlet NSTextField *leftMarginTextField;
@property (nonatomic, strong) IBOutlet NSTextField *rightMarginTextField;
@property (nonatomic, strong) IBOutlet NSTextField *topMarginTextField;
@property (nonatomic, strong) IBOutlet NSTextField *bottomMarginTextField;

@property (nonatomic, strong) IBOutlet NSStepper *resolutionStepper;
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

@property (nonatomic, strong) IBOutlet NSBox *invisibleCharacterBox;

@property (nonatomic, strong) IBOutlet NSPopUpButton *autoDetectionTargetPopupButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *pageBoxPopupButton;

@property (nonatomic, strong) IBOutlet NSTextField *delayTextField;;
@property (nonatomic, strong) IBOutlet NSStepper *delayStepper;
@property (nonatomic, strong) IBOutlet NSTextField *loopCountTextField;
@property (nonatomic, strong) IBOutlet NSStepper *loopCountStepper;

@property (atomic, strong) Converter *converter;
@property (atomic, strong) NSTask *runningTask;
@property (atomic, strong) NSPipe *outputPipe;
@property (atomic, assign) BOOL *taskKilled;

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
@synthesize transparentCheckBox;
@synthesize plainTextCheckBox;
@synthesize deleteDisplaySizeCheckBox;
@synthesize mergeOutputsCheckBox;
@synthesize keepPageSizeCheckBox;
@synthesize showOutputDrawerCheckBox;
@synthesize previewCheckBox;
@synthesize deleteTmpFileCheckBox;
@synthesize toClipboardCheckBox;
@synthesize embedSourceCheckBox;
@synthesize embedInIllustratorCheckBox;
@synthesize ungroupCheckBox;
@synthesize preferenceWindow;

@synthesize resolutionTextField;
@synthesize leftMarginTextField;
@synthesize rightMarginTextField;
@synthesize topMarginTextField;
@synthesize bottomMarginTextField;

@synthesize resolutionStepper;
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

@synthesize invisibleCharacterBox;

@synthesize autoDetectionTargetPopupButton;
@synthesize pageBoxPopupButton;

@synthesize delayTextField;
@synthesize delayStepper;
@synthesize loopCountTextField;
@synthesize loopCountStepper;

@synthesize commandCompletionList;

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
        [self appendOutputAndScroll:[NSString stringWithFormat:@"\n\nTeX2img: %@\n\n", localizedString(@"processAborted")] quiet:NO];
    }
    
    if (NSThread.currentThread.isCancelled) {
        [self generationDidFinish];
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

- (BOOL)eps2emfExists;
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
    previewFiles(files, app);
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
    plainTextCheckBox.state = [aProfile boolForKey:PlainTextKey];
	textPdfCheckBox.state = ![aProfile boolForKey:GetOutlineKey];
    deleteDisplaySizeCheckBox.state = [aProfile boolForKey:DeleteDisplaySizeKey];
    mergeOutputsCheckBox.state = [aProfile boolForKey:MergeOutputsKey];
    keepPageSizeCheckBox.state = [aProfile boolForKey:KeepPageSizeKey];

	ignoreErrorCheckBox.state = [aProfile boolForKey:IgnoreErrorKey];
	utfExportCheckBox.state = [aProfile boolForKey:UtfExportKey];
    workInInputFileDirectoryCheckBox.state = ([aProfile integerForKey:WorkingDirectoryTypeKey] == WorkingDirectoryFile) ? NSOnState : NSOffState;
	
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
	
	[self loadStringSettingForTextField:latexPathTextField fromProfile:aProfile forKey:LatexPathKey];
	[self loadStringSettingForTextField:dviDriverPathTextField fromProfile:aProfile forKey:DviDriverPathKey];
	[self loadStringSettingForTextField:gsPathTextField fromProfile:aProfile forKey:GsPathKey];
	
	[self loadNumberSettingForTextField:resolutionTextField fromProfile:aProfile forKey:ResolutionKey];
    [self loadNumberSettingForTextField:leftMarginTextField fromProfile:aProfile forKey:LeftMarginKey];
    [self loadNumberSettingForTextField:rightMarginTextField fromProfile:aProfile forKey:RightMarginKey];
    [self loadNumberSettingForTextField:topMarginTextField fromProfile:aProfile forKey:TopMarginKey];
    [self loadNumberSettingForTextField:bottomMarginTextField fromProfile:aProfile forKey:BottomMarginKey];
    
    [resolutionStepper takeFloatValueFrom:resolutionTextField];
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

    [self loadSettingForTextView:preambleTextView fromProfile:aProfile forKey:PreambleKey];

    if ([keys containsObject:AutoDetectionTargetKey]) {
        [autoDetectionTargetPopupButton selectItemWithTag:[aProfile integerForKey:AutoDetectionTargetKey]];
    }
    
    if ([keys containsObject:PageBoxKey]) {
        [pageBoxPopupButton selectItemWithTag:[aProfile integerForKey:PageBoxKey]];
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
	Profile *aProfile = [profileController profileForName:profileName];
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
        
        currentProfile[ShowOutputDrawerKey] = @(showOutputDrawerCheckBox.state);
        currentProfile[PreviewKey] = @(previewCheckBox.state);
        currentProfile[DeleteTmpFileKey] = @(deleteTmpFileCheckBox.state);
        
        currentProfile[EmbedSourceKey] = @(embedSourceCheckBox.state);
        currentProfile[CopyToClipboardKey] = @(toClipboardCheckBox.state);
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
        
        currentProfile[AutoDetectionTargetKey] = @(autoDetectionTargetPopupButton.selectedTag);
        currentProfile[PageBoxKey] = @(pageBoxPopupButton.selectedTag);

        currentProfile[DelayKey] = @(delayTextField.floatValue);
        currentProfile[LoopCountKey] = @(loopCountTextField.integerValue);

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
        
        currentProfile[WorkingDirectoryTypeKey] = (workInInputFileDirectoryCheckBox.state == NSOnState) ? @(WorkingDirectoryFile) : @(WorkingDirectoryTmp);
        currentProfile[WorkingDirectoryPathKey] = (([currentProfile integerForKey:WorkingDirectoryTypeKey] == WorkingDirectoryFile) && ([currentProfile integerForKey:InputMethodKey] == FROMFILE)) ?
        [currentProfile stringForKey:InputSourceFilePathKey].stringByDeletingLastPathComponent : NSTemporaryDirectory();

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
    
    NSMutableArray<NSString*> *searchPaths = [NSMutableArray arrayWithArray:[pipe.stringValue componentsSeparatedByString:@":"]];

    [searchPaths addObjectsFromArray: @[
                                        @"/Applications/Ghostscript.app/bin",
                                        @"/Applications/TeXLive/Library/mactexaddons/bin",
                                        @"/Applications/TeXLive/Library/texlive/2016/bin/x86_64-darwin",
                                        @"/Applications/TeXLive/Library/texlive/2015/bin/x86_64-darwin",
                                        @"/Applications/TeXLive/Library/texlive/2014/bin/x86_64-darwin",
                                        @"/Applications/TeXLive/Library/texlive/2013/bin/x86_64-darwin",
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
                                        @"/Applications/TeXLive/Library/texlive/2016/bin/universal-darwin",
                                        @"/Applications/TeXLive/Library/texlive/2015/bin/universal-darwin",
                                        @"/Applications/TeXLive/Library/texlive/2014/bin/universal-darwin",
                                        @"/Applications/TeXLive/Library/texlive/2013/bin/universal-darwin",
                                        @"/Applications/TeXLive/texlive/2016/bin/universal-darwin",
                                        @"/Applications/TeXLive/texlive/2015/bin/universal-darwin",
                                        @"/Applications/TeXLive/texlive/2014/bin/universal-darwin",
                                        @"/Applications/TeXLive/texlive/2013/bin/universal-darwin",
                                        @"/usr/local/texlive/2016/bin/universal-darwin",
                                        @"/usr/local/texlive/2015/bin/universal-darwin",
                                        @"/usr/local/texlive/2014/bin/universal-darwin",
                                        @"/usr/local/texlive/2013/bin/universal-darwin",
                                        @"/opt/local/texlive/2016/bin/universal-darwin",
                                        @"/opt/local/texlive/2015/bin/universal-darwin",
                                        @"/opt/local/texlive/2014/bin/universal-darwin",
                                        @"/opt/local/texlive/2013/bin/universal-darwin",
                                        @"/opt/texlive/2016/bin/universal-darwin",
                                        @"/opt/texlive/2015/bin/universal-darwin",
                                        @"/opt/texlive/2014/bin/universal-darwin",
                                        @"/opt/texlive/2013/bin/universal-darwin",
                                        @"/Library/TeX/texbin",
                                        @"/usr/texbin",
                                        @"/Applications/UpTeX.app/Contents/Resources/TEX/texbin/",
                                        @"/Applications/UpTeX.app/Contents/Resources/texbin/",
                                        @"/Applications/UpTeX.app/teTeX/bin",
                                        @"/Applications/pTeX.app/teTeX/bin",
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
    
    // 数値を記入した NSTextField の値を変更したときに直ちに関連づけられたステッパーに反映されるように
    // ただし，resolutionTextField は，小数点値を反映させるために対象外としている
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
        NSString *templateName = autoDetectionTargetPopupButton.selectedItem.title;
        NSString *originalTemplateDirectory = [NSBundle.mainBundle pathForResource:TemplateDirectoryName ofType:nil];
        NSString *templatePath = [[originalTemplateDirectory stringByAppendingPathComponent:templateName] stringByAppendingPathExtension:@"tex"];
        NSData *data = [NSData dataWithContentsOfFile:templatePath];
        NSStringEncoding detectedEncoding;
        NSString *contents = [NSString stringWithAutoEncodingDetectionOfData:data detectedEncoding:&detectedEncoding];
        
        if (contents) {
            [preambleTextView replaceEntireContentsWithString:contents];
        }

        [self loadDefaultFont];
		
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

- (NSArray<NSString*>*)analyzeContents:(NSString*)contents
{
    BOOL convertYenMark = [[self currentProfile] boolForKey:ConvertYenMarkKey];
    if (convertYenMark) {
        contents = [[NSMutableString stringWithString:contents] replaceYenWithBackSlash];
    }
    
    NSString *preamble = @"";
    NSString *body = @"";
    
    NSRange range = [contents rangeOfString:@"\n\\begin{document}\n"];
    
    if (range.location == NSNotFound) {
        body = contents;
    } else {
        preamble = [contents substringWithRange:NSMakeRange(0, range.location)];
        body = [contents substringWithRange:NSMakeRange(range.location + range.length, contents.length - range.location - range.length)];
        range = [body rangeOfString:@"\n\\end{document}"];
        if (range.location != NSNotFound) {
            body = [body substringWithRange:NSMakeRange(0, range.location)];
        }
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

- (BOOL)importSourceFromFilePathOrPDFDocument:(id)input
{
    [NSApp activateIgnoringOtherApps:YES];
    
    NSString *contents = nil;
    
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
                    PDFDocument *doc = [PDFDocument documentWithFilePath:inputPath];
                    contents = [self extractTeXSourceStringFromAnnotationOfPDF:doc];
                    if (!contents) {
                        runErrorPanel(localizedString(@"doesNotContainSource"), inputPath);
                        return NO;
                    }
                } else {
                    runErrorPanel(localizedString(@"doesNotContainSource"), inputPath);
                    return NO;
                }
            } else { // ソース情報が含まれる画像ファイルの場合はそれをEAから取得して contents にセット（EAに保存されたソースは常にUTF8）
                char *buffer = (char*)malloc(bufferLength);
                getxattr(inputPath.UTF8String, EA_Key, buffer, bufferLength, 0, 0);
                contents = [[NSString alloc] initWithBytes:buffer length:bufferLength encoding:NSUTF8StringEncoding];
                free(buffer);
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
        if (runConfirmPanel(localizedString(@"overwriteContentsWarningMsg"))) {
            [self placeImportedSource:contents];
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
            [self importSourceFromFilePathOrPDFDocument:openPanel.URL.path];
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
            NSStringEncoding encoding = [self stringEncodingFromEncodingOption:[[self currentProfile] stringForKey:EncodingKey]];
            
            if (![contents writeToFile:outputPath atomically:YES encoding:encoding error:nil]) {
                runErrorPanel(localizedString(@"cannotWriteErrorMsg"), outputPath);
            }
        }
    }];
}

#pragma mark - Drag & Drop

- (void)textViewDroppedFile:(id)file;
{
    [self importSourceFromFilePathOrPDFDocument:file];
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
}

- (void)colorPalleteWindowDidBecomeKey:(NSNotification*)aNotification
{
    [colorPalleteColorWell restoreColorFromDictionary:lastColorDict];
}

- (void)closeColorPanel
{
    [colorPalleteColorWell deactivate];
    
    [NSColorPanel.sharedColorPanel performSelector:@selector(orderOut:) withObject:self afterDelay:0];

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

- (void)searchProgramsLogic:(NSDictionary<NSString*,NSString*>*)parameters
{
    NSString *latexPath;
    NSString *dviDriverPath;
    NSString *gsPath;
    
    NSString *templateName = autoDetectionTargetPopupButton.selectedItem.title;
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
                                        @"Title": parameters[@"Title"],
                                        @"Msg1": parameters[@"Msg1"],
                                        @"Msg2": parameters[@"Msg2"],
                                        LatexPathKey: [latexPath isEqualToString:@""] ? @"LaTeX: Not Found" : latexPath,
                                        DviDriverPathKey: [dviDriverPath isEqualToString:@""] ? @"DVI Driver: Not Found" : dviDriverPath,
                                        GsPathKey: [gsPath isEqualToString:@""] ? @"Ghostscript: Not Found" : gsPath
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
    NSString *templateName = autoDetectionTargetPopupButton.selectedItem.title;
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
    taskKilled = NO;
}

- (void)generationDidFinishOnMainThread
{
    [self performSelector:@selector(generationDidFinishOnMainThreadAfterDelay) withObject:nil afterDelay:0.3];
}

- (void)generationDidFinish
{
    [self performSelectorOnMainThread:@selector(generationDidFinishOnMainThread) withObject:nil waitUntilDone:YES];
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
    
    NSString *ext = outputFilePath.pathExtension;
    NSString *unit = (([aProfile integerForKey:UnitKey] == PX_UNIT_TAG) &&
                      ([ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"] || [ext isEqualToString:@"tiff"])) ?
                        @"px" : @"bp";
    
    [output appendFormat:@"Left   margin: %ld%@\n", [aProfile integerForKey:LeftMarginKey], unit];
    [output appendFormat:@"Right  margin: %ld%@\n", [aProfile integerForKey:RightMarginKey], unit];
    [output appendFormat:@"Top    margin: %ld%@\n", [aProfile integerForKey:TopMarginKey], unit];
    [output appendFormat:@"Bottom margin: %ld%@\n", [aProfile integerForKey:BottomMarginKey], unit];
    
    [output appendFormat:@"Transparent: %@\n", [aProfile boolForKey:TransparentKey] ? ENABLED : DISABLED];
    
    if ([ext isEqualToString:@"pdf"]) {
        [output appendFormat:@"Text embedded PDF: %@\n", [aProfile boolForKey:GetOutlineKey] ? DISABLED : ENABLED];
    }
    if ([ext isEqualToString:@"eps"]) {
        [output appendFormat:@"Plain text EPS: %@\n", [aProfile boolForKey:PlainTextKey] ? ENABLED : DISABLED];
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
    MutableProfile *aProfile = [self currentProfile];
    aProfile[EpstopdfPathKey] = [NSBundle.mainBundle pathForResource:@"epstopdf" ofType:nil];
    aProfile[MudrawPathKey] = [[NSBundle.mainBundle pathForResource:@"mupdf" ofType:nil] stringByAppendingPathComponent:@"mudraw"];
    aProfile[PdftopsPathKey] = [[NSBundle.mainBundle pathForResource:@"pdftops" ofType:nil] stringByAppendingPathComponent:@"pdftops"];
    aProfile[Eps2emfPathKey] = [[NSBundle.mainBundle pathForResource:@"eps2emf" ofType:nil] stringByAppendingPathComponent:@"eps2emf"];
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
    // 余白設定・解像度設定などの数値の妥当性チェック
    __block BOOL valid = YES;

    [@[leftMarginTextField, rightMarginTextField, topMarginTextField, bottomMarginTextField, resolutionTextField, numberOfCompilationTextField, tabWidthTextField] enumerateObjectsUsingBlock:^(NSTextField *label, NSUInteger idx, BOOL *stop) {
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
    taskKilled = YES;
    
    if (runningTask && runningTask.isRunning) {
        [runningTask terminate];
        runningTask = nil;
        [self generationDidFinish];
    }
}

- (NSString*)spaceCharacter
{
    return @"␣";
}

- (NSString*)fullwidthSpaceCharacter
{
    return @"□";
}

- (NSString*)returnCharacter
{
    return @"↵";
}

- (NSString*)tabCharacter
{
    return @"‣";
}

@end
