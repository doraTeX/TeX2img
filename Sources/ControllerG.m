#include <sys/xattr.h>
#import "ProfileController.h"
#import "global.h"
#import "ControllerG.h"
#import "NSDictionary-Extension.h"
#import "NSString-Extension.h"
#import "NSMutableString-Extension.h"
#import "NSFileManager-Extension.h"
#import "TeXTextView.h"

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
@property IBOutlet NSWindow *preambleWindow;
@property IBOutlet TeXTextView *preambleTextView;
@property IBOutlet NSMenuItem *convertYenMarkMenuItem;
@property IBOutlet NSMenuItem *colorizeTextMenuItem;
@property IBOutlet NSMenuItem *outputDrawerMenuItem;
@property IBOutlet NSMenuItem *preambleWindowMenuItem;
@property IBOutlet NSMenuItem *generateMenuItem;
@property IBOutlet NSMenuItem *flashHighlightMenuItem;
@property IBOutlet NSMenuItem *solidHighlightMenuItem;
@property IBOutlet NSMenuItem *noHighlightMenuItem;
@property IBOutlet NSMenuItem *flashInMovingMenuItem;
@property IBOutlet NSMenuItem *highlightContentMenuItem;
@property IBOutlet NSMenuItem *beepMenuItem;
@property IBOutlet NSMenuItem *flashBackgroundMenuItem;
@property IBOutlet NSMenuItem *checkBraceMenuItem;
@property IBOutlet NSMenuItem *checkBracketMenuItem;
@property IBOutlet NSMenuItem *checkSquareBracketMenuItem;
@property IBOutlet NSMenuItem *checkParenMenuItem;
@property IBOutlet NSMenuItem *autoCompleteMenuItem;
@property IBOutlet NSMenuItem *showTabCharacterMenuItem;
@property IBOutlet NSMenuItem *showSpaceCharacterMenuItem;
@property IBOutlet NSMenuItem *showNewLineCharacterMenuItem;
@property IBOutlet NSMenuItem *showFullwidthSpaceCharacterMenuItem;
@property IBOutlet NSTextField *outputFileTextField;

@property IBOutlet NSPopUpButton *templatePopupButton;

@property IBOutlet NSButton *directInputButton;
@property IBOutlet NSButton *inputSourceFileButton;
@property IBOutlet NSTextField *inputSourceFileTextField;
@property IBOutlet NSButton *browseSourceFileButton;

@property IBOutlet NSButton *generateButton;
@property IBOutlet NSButton *transparentCheckBox;
@property IBOutlet NSButton *showOutputDrawerCheckBox;
@property IBOutlet NSButton *previewCheckBox;
@property IBOutlet NSButton *deleteTmpFileCheckBox;
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
@property IBOutlet NSTextField *dvipdfmxPathTextField;
@property IBOutlet NSTextField *gsPathTextField;
@property IBOutlet NSButton *guessCompilationButton;
@property IBOutlet NSTextField *numberOfCompilationTextField;
@property IBOutlet NSButton *getOutlineCheckBox;
@property IBOutlet NSButton *ignoreErrorCheckBox;
@property IBOutlet NSButton *utfExportCheckBox;
@property IBOutlet NSPopUpButton *encodingPopUpButton;
@property IBOutlet NSMatrix *unitMatrix;
@property IBOutlet NSMatrix *priorityMatrix;
@property HighlightPattern highlightPattern;
@property NSString *lastSavedPath;
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
@synthesize colorizeTextMenuItem;
@synthesize outputDrawerMenuItem;
@synthesize preambleWindowMenuItem;
@synthesize generateMenuItem;
@synthesize flashHighlightMenuItem;
@synthesize solidHighlightMenuItem;
@synthesize noHighlightMenuItem;
@synthesize flashInMovingMenuItem;
@synthesize highlightContentMenuItem;
@synthesize beepMenuItem;
@synthesize flashBackgroundMenuItem;
@synthesize checkBraceMenuItem;
@synthesize checkBracketMenuItem;
@synthesize checkSquareBracketMenuItem;
@synthesize checkParenMenuItem;
@synthesize autoCompleteMenuItem;
@synthesize showTabCharacterMenuItem;
@synthesize showSpaceCharacterMenuItem;
@synthesize showNewLineCharacterMenuItem;
@synthesize showFullwidthSpaceCharacterMenuItem;
@synthesize outputFileTextField;

@synthesize templatePopupButton;

@synthesize directInputButton;
@synthesize inputSourceFileButton;
@synthesize inputSourceFileTextField;
@synthesize browseSourceFileButton;

@synthesize generateButton;
@synthesize transparentCheckBox;
@synthesize showOutputDrawerCheckBox;
@synthesize previewCheckBox;
@synthesize deleteTmpFileCheckBox;
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
@synthesize dvipdfmxPathTextField;
@synthesize gsPathTextField;
@synthesize guessCompilationButton;
@synthesize numberOfCompilationTextField;
@synthesize getOutlineCheckBox;
@synthesize ignoreErrorCheckBox;
@synthesize utfExportCheckBox;
@synthesize encodingPopUpButton;
@synthesize unitMatrix;
@synthesize priorityMatrix;
@synthesize highlightPattern;
@synthesize lastSavedPath;

#pragma mark -
#pragma mark OutputController プロトコルの実装
- (void)showMainWindow
{
	[mainWindow makeKeyAndOrderFront:nil];
}

- (void)appendOutputAndScroll:(NSString*)str quiet:(BOOL)quiet
{
    if (quiet) {
        return;
    }
	if (str) {
		[outputTextView.textStorage.mutableString appendString:str];
		[outputTextView scrollRangeToVisible: NSMakeRange(outputTextView.string.length, 0)]; // 最下部までスクロール
	}
}

- (void)clearOutputTextView
{
	outputTextView.textStorage.mutableString.String = @"";
}

- (void)showOutputDrawer
{
	outputDrawerMenuItem.State = YES;
	[outputDrawer open];
}

- (void)showExtensionError
{
	NSRunAlertPanel(localizedString(@"Error"), localizedString(@"extensionErrMsg"), @"OK", nil, nil);
}

- (void)showNotFoundError:(NSString*)aPath
{
	NSRunAlertPanel(localizedString(@"Error"), [NSString stringWithFormat:@"%@%@", aPath, localizedString(@"programNotFoundErrorMsg")], @"OK", nil, nil);
}

- (BOOL)latexExistsAtPath:(NSString*)latexPath dvipdfmxPath:(NSString*)dvipdfmxPath gsPath:(NSString*)gsPath
{
	NSFileManager *fileManager = NSFileManager.defaultManager;
	
	if (![fileManager fileExistsAtPath:[latexPath componentsSeparatedByString:@" "][0]]) {
		[self showNotFoundError:latexPath];
		return NO;
	}
	if (![fileManager fileExistsAtPath:[dvipdfmxPath componentsSeparatedByString:@" "][0]]) {
		[self showNotFoundError:dvipdfmxPath];
		return NO;
	}
	if (![fileManager fileExistsAtPath:[gsPath componentsSeparatedByString:@" "][0]]) {
		[self showNotFoundError:gsPath];
		return NO;
	}
	
	return YES;
}

- (BOOL)pdfcropExists;
{
	return YES;
}

- (BOOL)epstopdfExists;
{
	return YES;
}

- (void)showFileGenerateError:(NSString*)aPath
{
	NSRunAlertPanel(localizedString(@"Error"), [NSString stringWithFormat:@"%@%@", aPath, localizedString(@"fileGenerateErrorMsg")], @"OK", nil, nil);
}

- (void)showExecError:(NSString*)command
{
	NSRunAlertPanel(localizedString(@"Error"), [NSString stringWithFormat:@"%@%@", command, localizedString(@"execErrorMsg")], @"OK", nil, nil);
}

- (void)showCannotOverwriteError:(NSString*)path
{
	NSRunAlertPanel(localizedString(@"Error"), [NSString stringWithFormat:@"%@%@", path, localizedString(@"cannotOverwriteErrorMsg")], @"OK", nil, nil);
}

- (void)showCannotCreateDirectoryError:(NSString*)dir
{
    NSRunAlertPanel(localizedString(@"Error"), [NSString stringWithFormat:@"%@%@", dir, localizedString(@"cannotCreateDirectoryErrorMsg")], @"OK", nil, nil);
}

- (void)showCompileError
{
	NSRunAlertPanel(localizedString(@"Alert"), localizedString(@"compileErrorMsg"), @"OK", nil, nil);
}

#pragma mark -
#pragma mark プロファイルの読み書き関連
- (void)loadSettingForTextField:(NSTextField*)textField fromProfile:(NSDictionary*)aProfile forKey:(NSString*)aKey
{
	NSString *tempStr = [aProfile stringForKey:aKey];
	
	if (tempStr) {
		textField.StringValue = tempStr;
	}
}

- (void)loadSettingForTextView:(NSTextView*)textView fromProfile:(NSDictionary*)aProfile forKey:(NSString*)aKey
{
	NSString *tempStr = [aProfile stringForKey:aKey];
	
	if (tempStr) {
		textView.textStorage.mutableString.String = tempStr;
	}
}

- (void)adoptProfile:(NSDictionary*)aProfile
{
    if (!aProfile) {
        return;
    }
	
	[self loadSettingForTextField:outputFileTextField fromProfile:aProfile forKey:OutputFileKey];
	
	showOutputDrawerCheckBox.State = [aProfile integerForKey:ShowOutputDrawerKey];
	previewCheckBox.State = [aProfile integerForKey:PreviewKey];
	deleteTmpFileCheckBox.State = [aProfile integerForKey:DeleteTmpFileKey];

	embedInIllustratorCheckBox.State = [aProfile integerForKey:EmbedInIllustratorKey];
	ungroupCheckBox.State = [aProfile integerForKey:UngroupKey];
	
	transparentCheckBox.State = [aProfile boolForKey:TransparentKey];
	getOutlineCheckBox.State = [aProfile boolForKey:GetOutlineKey];
	
	ignoreErrorCheckBox.State = [aProfile boolForKey:IgnoreErrorKey];
	utfExportCheckBox.State = [aProfile boolForKey:UtfExportKey];
	
	convertYenMarkMenuItem.State = [aProfile boolForKey:ConvertYenMarkKey];
	colorizeTextMenuItem.State = [aProfile boolForKey:ColorizeTextKey];
	
	highlightPattern = [aProfile integerForKey:HighlightPatternKey];
	[self changeHighlight:nil];

	flashInMovingMenuItem.State = [aProfile boolForKey:FlashInMovingKey];

	highlightContentMenuItem.State = [aProfile boolForKey:HighlightContentKey];
	beepMenuItem.State = [aProfile boolForKey:BeepKey];
	flashBackgroundMenuItem.State = [aProfile boolForKey:FlashBackgroundKey];

	checkBraceMenuItem.State = [aProfile boolForKey:CheckBraceKey];
	checkBracketMenuItem.State = [aProfile boolForKey:CheckBracketKey];
	checkSquareBracketMenuItem.State = [aProfile boolForKey:CheckSquareBracketKey];
	checkParenMenuItem.State = [aProfile boolForKey:CheckParenKey];

	autoCompleteMenuItem.State = [aProfile boolForKey:AutoCompleteKey];
	showTabCharacterMenuItem.State = [aProfile boolForKey:ShowTabCharacterKey];
	showSpaceCharacterMenuItem.State = [aProfile boolForKey:ShowSpaceCharacterKey];
	showFullwidthSpaceCharacterMenuItem.State = [aProfile boolForKey:ShowFullwidthSpaceCharacterKey];
	showNewLineCharacterMenuItem.State = [aProfile boolForKey:ShowNewLineCharacterKey];
	guessCompilationButton.State = [aProfile boolForKey:GuessCompilationKey];
    
    NSString *encoding = [aProfile stringForKey:EncodingKey];
    if (encoding) {
        EncodingTag tag = NONE;
        
        if ([encoding isEqualToString:PTEX_ENCODING_UTF8] || [encoding isEqualToString:@"uptex"]) {
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
	[self loadSettingForTextField:dvipdfmxPathTextField fromProfile:aProfile forKey:DvipdfmxPathKey];
	[self loadSettingForTextField:gsPathTextField fromProfile:aProfile forKey:GsPathKey];
	
	[self loadSettingForTextField:resolutionLabel fromProfile:aProfile forKey:ResolutionLabelKey];
    [self loadSettingForTextField:leftMarginLabel fromProfile:aProfile forKey:LeftMarginLabelKey];
    [self loadSettingForTextField:rightMarginLabel fromProfile:aProfile forKey:RightMarginLabelKey];
    [self loadSettingForTextField:topMarginLabel fromProfile:aProfile forKey:TopMarginLabelKey];
    [self loadSettingForTextField:bottomMarginLabel fromProfile:aProfile forKey:BottomMarginLabelKey];
    
    numberOfCompilationTextField.IntValue = MAX(1, [aProfile integerForKey:NumberOfCompilationKey]);
    resolutionSlider.FloatValue = [aProfile integerForKey:ResolutionKey];
    leftMarginSlider.IntValue = [aProfile integerForKey:LeftMarginKey];
    rightMarginSlider.IntValue = [aProfile integerForKey:RightMarginKey];
    topMarginSlider.IntValue = [aProfile integerForKey:TopMarginKey];
    bottomMarginSlider.IntValue = [aProfile integerForKey:BottomMarginKey];
    
    NSInteger unitTag = [aProfile integerForKey:UnitKey];
    [unitMatrix selectCellWithTag:unitTag];
    
    NSInteger priorityTag = [aProfile integerForKey:PriorityKey];
    [priorityMatrix selectCellWithTag:priorityTag];
    
    [self loadSettingForTextView:preambleTextView fromProfile:aProfile forKey:PreambleKey];
    
    NSFont *aFont = [NSFont fontWithName:[aProfile stringForKey:SourceFontNameKey] size:[aProfile floatForKey:SourceFontSizeKey]];
    if (aFont) {
        sourceTextView.Font = aFont;
    }
    
    aFont = [NSFont fontWithName:[aProfile stringForKey:PreambleFontNameKey] size:[aProfile floatForKey:PreambleFontSizeKey]];
    if (aFont) {
        preambleTextView.Font = aFont;
    }
    [preambleTextView colorizeText:[aProfile boolForKey:ColorizeTextKey]];
    
    NSString *inputSourceFilePath = [aProfile stringForKey:InputSourceFilePathKey];
    if (inputSourceFilePath) {
        inputSourceFileTextField.stringValue = inputSourceFilePath;
    }
    
    InputMethod inputMethod = [aProfile integerForKey:InputMethodKey];
    switch (inputMethod) {
        case FROMFILE:
            [self sourceSettingChanged:inputSourceFileButton];
            break;
        default:
            [self sourceSettingChanged:directInputButton];
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
	NSMutableDictionary *currentProfile = NSMutableDictionary.dictionary;
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
        
        currentProfile[EmbedInIllustratorKey] = @(embedInIllustratorCheckBox.state);
        currentProfile[UngroupKey] = @(ungroupCheckBox.state);
        
        currentProfile[TransparentKey] = @(transparentCheckBox.state);
        currentProfile[GetOutlineKey] = @(getOutlineCheckBox.state);
        currentProfile[IgnoreErrorKey] = @(ignoreErrorCheckBox.state);
        currentProfile[UtfExportKey] = @(utfExportCheckBox.state);
        
        currentProfile[LatexPathKey] = latexPathTextField.stringValue;
        currentProfile[DvipdfmxPathKey] = dvipdfmxPathTextField.stringValue;
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
        
        currentProfile[UnitKey] = @(unitMatrix.selectedTag);
        currentProfile[PriorityKey] = @(priorityMatrix.selectedTag);
        
        currentProfile[ConvertYenMarkKey] = @(convertYenMarkMenuItem.state);
        currentProfile[ColorizeTextKey] = @(colorizeTextMenuItem.state);
        currentProfile[HighlightPatternKey] = @(highlightPattern);
        currentProfile[FlashInMovingKey] = @(flashInMovingMenuItem.state);
        currentProfile[HighlightContentKey] = @(highlightContentMenuItem.state);
        currentProfile[BeepKey] = @(beepMenuItem.state);
        currentProfile[FlashBackgroundKey] = @(flashBackgroundMenuItem.state);
        currentProfile[CheckBraceKey] = @(checkBraceMenuItem.state);
        currentProfile[CheckBracketKey] = @(checkBracketMenuItem.state);
        currentProfile[CheckSquareBracketKey] = @(checkSquareBracketMenuItem.state);
        currentProfile[CheckParenKey] = @(checkParenMenuItem.state);
        currentProfile[AutoCompleteKey] = @(autoCompleteMenuItem.state);
        currentProfile[ShowTabCharacterKey] = @(showTabCharacterMenuItem.state);
        currentProfile[ShowSpaceCharacterKey] = @(showSpaceCharacterMenuItem.state);
        currentProfile[ShowFullwidthSpaceCharacterKey] = @(showFullwidthSpaceCharacterMenuItem.state);
        currentProfile[ShowNewLineCharacterKey] = @(showNewLineCharacterMenuItem.state);
        currentProfile[SourceFontNameKey] = sourceTextView.font.fontName;
        currentProfile[SourceFontSizeKey] = @(sourceTextView.font.pointSize);
        currentProfile[PreambleFontNameKey] = preambleTextView.font.fontName;
        currentProfile[PreambleFontSizeKey] = @(preambleTextView.font.pointSize);
        
        currentProfile[PreambleKey] = [NSString stringWithString:preambleTextView.textStorage.string]; // stringWithString は必須
        
        currentProfile[InputMethodKey] = (directInputButton.state == NSOnState) ? @(DIRECT) : @(FROMFILE);
        currentProfile[InputSourceFilePathKey] = inputSourceFileTextField.stringValue;
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

#pragma mark -
#pragma mark 他のメソッドから呼び出されるユーティリティメソッド
- (NSString*)searchProgram:(NSString*)programName
{
    NSDictionary *errorInfo = NSDictionary.new;
    NSString *script =  [NSString stringWithFormat:@"do shell script \"%@\"", @"eval `/usr/libexec/path_helper -s`; echo $PATH"];
    
    NSAppleScript *appleScript = [NSAppleScript.alloc initWithSource:script];
    NSAppleEventDescriptor *eventResult = [appleScript executeAndReturnError:&errorInfo];
    
    NSString *userPath = eventResult.stringValue;
    NSMutableArray *searchPaths = [NSMutableArray arrayWithArray:[userPath componentsSeparatedByString:@":"]];

    [searchPaths addObjectsFromArray: @[@"/Applications/TeXLive/texlive/2014/bin/x86_64-darwin",
                                        @"/Applications/TeXLive/texlive/2013/bin/x86_64-darwin",
                                        @"/usr/local/texlive/2014/bin/x86_64-darwin",
                                        @"/usr/local/texlive/2013/bin/x86_64-darwin",
                                        @"/opt/local/texlive/2014/bin/x86_64-darwin",
                                        @"/opt/local/texlive/2013/bin/x86_64-darwin",
                                        @"/opt/texlive/2014/bin/x86_64-darwin",
                                        @"/opt/texlive/2013/bin/x86_64-darwin",
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

#pragma mark -
#pragma mark プリアンブルの管理
- (NSString*)defaultPreamble
{
   return @"\\documentclass[fleqn,papersize]{jsarticle}\n"
          @"\\usepackage{amsmath,amssymb}\n"
          @"\\pagestyle{empty}\n";
}

- (void)restoreDefaultPreambleLogic
{
    BOOL colorizeText = [self.currentProfile boolForKey:ColorizeTextKey];
    [preambleTextView replaceEntireContentsWithString:[self defaultPreamble] colorize:colorizeText];
}

- (void)constructTemplatePopup:(id)sender
{
    NSMenu *menu = templatePopupButton.menu;
    
    while (menu.numberOfItems > 5) { // この数はテンプレートメニューの初期項目数
        [menu removeItemAtIndex:1];
    }
    
    NSString *templateDirectoryPath = self.templateDirectoryPath;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSEnumerator *enumerator = [[fileManager contentsOfDirectoryAtPath:templateDirectoryPath error:nil] reverseObjectEnumerator];
    
    NSString *filename;
    while ((filename = enumerator.nextObject) != nil) {
        NSString *fullPath = [templateDirectoryPath stringByAppendingPathComponent:filename];
        
        if ([filename hasSuffix:@"tex"]) {
            NSString *title = filename.stringByDeletingPathExtension;
            NSMenuItem *menuItem = [NSMenuItem.alloc initWithTitle:title action:@selector(templateSelected:) keyEquivalent:@""];
            menuItem.target = self;
            menuItem.toolTip = fullPath; // tooltip文字列の部分にフルパスを保持
            [menu insertItem:menuItem atIndex:1];
        }
        
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
            NSMenuItem *itemWithSubmenu = [NSMenuItem.alloc initWithTitle:filename action:nil keyEquivalent:@""];
            NSMenu *submenu = NSMenu.new;
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
            NSMenuItem *menuItem = [NSMenuItem.alloc initWithTitle:title action:@selector(templateSelected:) keyEquivalent:@""];
            menuItem.target = self;
            menuItem.toolTip = fullPath; // tooltip文字列の部分にフルパスを保持
            [menu addItem:menuItem];
        }
        
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
            NSMenuItem *itemWithSubmenu = [NSMenuItem.alloc initWithTitle:filename action:nil keyEquivalent:@""];
            NSMenu *submenu = NSMenu.new;
            submenu.autoenablesItems = NO;
            [self constructTemplatePopupRecursivelyAtDirectory:[directory stringByAppendingPathComponent:filename] parentMenu:submenu];
            itemWithSubmenu.submenu = submenu;
            [menu addItem:itemWithSubmenu];
        }
    }
}

- (void)templateSelected:(id)sender
{
    NSString *templatePath = ((NSMenuItem*)sender).toolTip;
    NSData *data = [NSData dataWithContentsOfFile:templatePath];
    NSStringEncoding detectedEncoding;
    NSString *contents = [NSString stringWithAutoEncodingDetectionOfData:data detectedEncoding:&detectedEncoding];

    if (contents) {
        NSString *message = [NSString stringWithFormat:@"%@\n\n%@", localizedString(@"resotrePreambleMsg"), [contents stringByReplacingOccurrencesOfString:@"%" withString:@"%%"]];
        
        if (NSRunAlertPanel(localizedString(@"Confirm"), message, @"OK", localizedString(@"Cancel"), nil) == NSOKButton) {
            BOOL colorizeText = [self.currentProfile boolForKey:ColorizeTextKey];
            [preambleTextView replaceEntireContentsWithString:contents colorize:colorizeText];
        }
    } else {
        NSRunAlertPanel(localizedString(@"Error"), [NSString stringWithFormat:localizedString(@"cannotReadErrorMsg"), templatePath], @"OK", nil, nil);
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
    if (NSRunAlertPanel(localizedString(@"Confirm"), localizedString(@"restoreTemplatesConfirmationMsg"), @"OK", localizedString(@"Cancel"), nil) == NSOKButton) {
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


#pragma mark -
#pragma mark デリゲート・ノティフィケーションのコールバック
- (void)awakeFromNib
{
	//	以下は Interface Builder 上で設定できる
	//	[mainWindow setReleasedWhenClosed:NO];
	//	[preambleWindow setReleasedWhenClosed:NO];
	
	// ノティフィケーションの設定
	NSNotificationCenter *aCenter = NSNotificationCenter.defaultCenter;
	
	// アプリケーションがアクティブになったときにメインウィンドウを表示
	[aCenter addObserver: self
				selector: @selector(showMainWindow:)
					name: NSApplicationDidBecomeActiveNotification
				  object: NSApp];
	
	// プログラム終了時に設定保存実行
	[aCenter addObserver: self
				selector: @selector(applicationWillTerminate:)
					name: NSApplicationWillTerminateNotification
				  object: NSApp];
	
	// プリアンブルウィンドウが閉じられるときにメニューのチェックを外す
	[aCenter addObserver: self
				selector: @selector(uncheckPreambleWindowMenuItem:)
					name: NSWindowWillCloseNotification
				  object: preambleWindow];
	
	// メインウィンドウが閉じられるときに他のウィンドウも閉じる
	[aCenter addObserver: self
				selector: @selector(closeOtherWindows:)
					name: NSWindowWillCloseNotification
				  object: mainWindow];
	
	// テキストビューのカーソル移動の通知を受ける
	[aCenter addObserver: sourceTextView
				selector: @selector(textViewDidChangeSelection:)
					name: NSTextViewDidChangeSelectionNotification
				  object: sourceTextView];

	[aCenter addObserver: preambleTextView
				selector: @selector(textViewDidChangeSelection:)
					name: NSTextViewDidChangeSelectionNotification
				  object: preambleTextView];
    
    // テンプレートボタンのポップアップ寸前
    [aCenter addObserver: self
                selector: @selector(constructTemplatePopup:)
                    name: NSPopUpButtonWillPopUpNotification
                  object: templatePopupButton];
	
	// デフォルトのアウトプットファイルのパスをセット
	outputFileTextField.StringValue = [NSString stringWithFormat:@"%@/Desktop/equation.eps", NSHomeDirectory()];
	
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
		[self restoreDefaultPreambleLogic];
		
		NSString *latexPath;
		NSString *dvipdfmxPath;
		NSString *gsPath;
		
		if (!(latexPath = [self searchProgram:@"platex"])) {
			latexPath = @"/usr/local/bin/platex";
			[self showNotFoundError:@"platex"];
		}
		if (!(dvipdfmxPath = [self searchProgram:@"dvipdfmx"])) {
			dvipdfmxPath = @"/usr/local/bin/dvipdfmx";
			[self showNotFoundError:@"dvipdfmx"];
		}
		if (!(gsPath = [self searchProgram:@"gs"])) {
			gsPath = @"/usr/local/bin/gs";
			[self showNotFoundError:@"ghostscript"];
		}
		
		latexPathTextField.StringValue = latexPath;
		dvipdfmxPathTextField.StringValue = dvipdfmxPath;
		gsPathTextField.StringValue = gsPath;
		
        [self performSelectorOnMainThread:@selector(showInitMessage:)
                               withObject:@{LatexPathKey: latexPath,
                                            DvipdfmxPathKey: dvipdfmxPath,
                                            GsPathKey: gsPath
                                            }
                            waitUntilDone:NO];
		
		NSFont *defaultFont = [NSFont fontWithName:@"Osaka-Mono" size:13];
		if (defaultFont) {
			sourceTextView.Font = defaultFont;
			preambleTextView.Font = defaultFont;
		}
		
		[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"SUEnableAutomaticChecks"];
		
	}

	// CommandComepletion.txt のロード
	unichar esc = 0x001B;
	g_commandCompletionChar = [NSString stringWithCharacters:&esc length: 1];
	NSData 	*myData = nil;

	NSString *completionPath = @"~/Library/TeXShop/CommandCompletion/CommandCompletion.txt".stringByStandardizingPath;
	if ([fileManager fileExistsAtPath:completionPath])
		myData = [NSData dataWithContentsOfFile:completionPath];
	
	if (myData) {
		NSStringEncoding myEncoding = NSUTF8StringEncoding;
		g_commandCompletionList = [NSMutableString.alloc initWithData:myData encoding:myEncoding];
		if (! g_commandCompletionList) {
			g_commandCompletionList = [NSMutableString.alloc initWithData:myData encoding:myEncoding];
		}
		
		[g_commandCompletionList insertString:@"\n" atIndex:0];
		if ([g_commandCompletionList characterAtIndex:g_commandCompletionList.length-1] != '\n')
			[g_commandCompletionList appendString:@"\n"];
	}

    // Application Support の準備
    NSString *templateDirectoryPath = self.templateDirectoryPath;
    if (![fileManager fileExistsAtPath:templateDirectoryPath isDirectory:nil]) {
        // 初回起動時には app bundle 内のテンプレートをコピー
        [self restoreDefaultTemplatesLogic];
    }
    
}

- (void)showInitMessage:(NSDictionary*)paths
{
    NSRunAlertPanel(localizedString(@"initSettingsMsg"),
                    [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@",
                     localizedString(@"setPathMsg1"), paths[LatexPathKey], paths[DvipdfmxPathKey], paths[GsPathKey], localizedString(@"setPathMsg2")],
                    @"OK", nil, nil);
}

- (void)applicationWillTerminate:(NSNotification*)aNotification
{
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
	outputDrawerMenuItem.State = NO;
}

- (void)uncheckPreambleWindowMenuItem:(NSNotification*)aNotification
{
	preambleWindowMenuItem.State = NO;
}

- (IBAction)showMainWindow:(id)sender
{
	[self showMainWindow];
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
    
    NSRegularExpression *regex = [NSRegularExpression.alloc initWithPattern:@"^(.*?)(?:\\r|\\n|\\r\\n)*(?:\\\\|¥)begin\\{document\\}(?:\\r|\\n|\\r\\n)*(.*)(?:\\\\|¥)end\\{document\\}" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:contents options:0 range:NSMakeRange(0, contents.length)];
    if (match) {
        preamble = [[contents substringWithRange: [match rangeAtIndex: 1]] stringByAppendingString:@"\n"];
        body = [[[contents substringWithRange: [match rangeAtIndex: 2]] stringByDeletingLastReturnCharacters] stringByAppendingString:@"\n"];
    } else {
        body = contents;
    }
    
    return @[preamble, body];
}

- (void)placeImportedSource:(NSString*)contents
{
    BOOL colorizeText = [self.currentProfile boolForKey:ColorizeTextKey];

    NSArray *parts = [self analyzeContents:contents];
    NSString *preamble = (NSString*)(parts[0]);
    NSString *body = (NSString*)(parts[1]);
    
    if (![preamble isEqualToString:@""]) {
        [preambleTextView replaceEntireContentsWithString:preamble colorize:colorizeText];
    }
    if (![body isEqualToString:@""]) {
        [sourceTextView replaceEntireContentsWithString:body colorize:colorizeText];
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
    if (NSRunAlertPanel(localizedString(@"Confirm"), localizedString(@"overwriteContentsWarningMsg"), @"OK", localizedString(@"Cancel"), nil) == NSOKButton) {

        NSString *contents = nil;
        
        if ([inputPath.pathExtension isEqualToString:@"tex"]) { // TeX ソースのインプット
            NSData *data = [NSData dataWithContentsOfFile:inputPath];
            NSStringEncoding detectedEncoding;
            contents = [NSString stringWithAutoEncodingDetectionOfData:data detectedEncoding:&detectedEncoding];
        } else { // 画像ファイルのインプット
            int bufferLength = getxattr(inputPath.UTF8String, EAKey, NULL, 0, 0, 0);
            if (bufferLength < 0){
                NSRunAlertPanel(localizedString(@"Error"), [NSString stringWithFormat:localizedString(@"doesNotContainSource"), inputPath], @"OK", nil, nil);
                return;
            } else {
                // make a buffer of sufficient length
                char *buffer = malloc(bufferLength);
                
                // now actually get the attribute string
                getxattr(inputPath.UTF8String, EAKey, buffer, bufferLength, 0, 0);
                
                // convert to NSString
                contents = [NSString.alloc initWithBytes:buffer length:bufferLength encoding:NSUTF8StringEncoding];
                
                // release buffer
                free(buffer);
            }
        }
        
        if (contents) {
            [self placeImportedSource:contents];
        } else {
            NSRunAlertPanel(localizedString(@"Error"), [NSString stringWithFormat:localizedString(@"cannotReadErrorMsg"), inputPath], @"OK", nil, nil);
        }
    }
}

- (IBAction)importSource:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.AllowedFileTypes = @[@"tex", @"pdf", @"eps", @"jpg", @"png"];
    
    [openPanel beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            [self importSourceLogic:openPanel.URL.path];
        }
    }];
}

- (IBAction)exportSource:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.AllowedFileTypes = @[@"tex"];
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
                NSRunAlertPanel(localizedString(@"Error"), [NSString stringWithFormat:localizedString(@"cannotWriteErrorMsg"), outputPath], @"OK", nil, nil);
            }
        
        }
    }];
}

#pragma mark - Drag & Drop

- (void)textViewDroppedFile:(NSString*)file;
{
    [self importSourceLogic:file];
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
    
    NSWindow *dialog = [NSWindow.alloc initWithContentRect:dialogRect
                                                 styleMask:(NSTitledWindowMask|NSResizableWindowMask)
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
    [dialog setFrame:dialogRect display:NO];
    dialog.minSize = NSMakeSize(250, dialogSize.height);
    dialog.maxSize = NSMakeSize(10000, dialogSize.height);
    dialog.title = localizedString(@"saveCurrentPreambleAsTemplate");
    
    NSTextField *input = NSTextField.new;
    input.frame = NSMakeRect(17, 54, dialogSize.width - 40, 25);
    input.autoresizingMask = NSViewWidthSizable;
    [dialog.contentView addSubview:input];
    
    if ([sender isKindOfClass:NSString.class]) {
        input.stringValue = (NSString*)sender;
    }
    
    NSButton* cancelButton = NSButton.new;
    cancelButton.title = localizedString(@"Cancel");
    cancelButton.frame = NSMakeRect(dialogSize.width - 206, 12, 96, 32);
    cancelButton.bezelStyle = NSRoundedBezelStyle;
    cancelButton.autoresizingMask = NSViewMinXMargin;
    cancelButton.keyEquivalent = @"\033";
    cancelButton.target = self;
    cancelButton.action = @selector(dialogCancel:);
    [dialog.contentView addSubview:cancelButton];
    
    NSButton* okButton = NSButton.new;
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
        
        if ([fileManager fileExistsAtPath:filePath isDirectory:nil] && (NSRunAlertPanel(localizedString(@"Confirm"), localizedString(@"profileOverwriteMsg"), @"OK", localizedString(@"Cancel"), nil) == NSCancelButton)) {
            [self saveAsTemplate:title];
        } else {
            NSString *preamble = preambleTextView.textStorage.mutableString;
            BOOL success = [preamble writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
            if (!success) {
                NSRunAlertPanel(localizedString(@"Error"), [NSString stringWithFormat:localizedString(@"cannotWriteErrorMsg"), filePath], @"OK", nil, nil);
            }
        }
    }
}

- (IBAction)openTemplateDirectory:(id)sender
{
    [NSWorkspace.sharedWorkspace openFile:self.templateDirectoryPath withApplication:@"Finder.app"];
}

- (IBAction)openTempDir:(id)sender
{
	[NSWorkspace.sharedWorkspace openFile:NSTemporaryDirectory() withApplication:@"Finder.app"];
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
    openPanel.AllowedFileTypes = @[@"tex"];
    
    [openPanel beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            inputSourceFileTextField.stringValue = openPanel.URL.path;
        }
    }];
    
}

- (IBAction)showSavePanel:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.AllowedFileTypes = @[@"eps", @"png", @"jpg", @"pdf"];
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
	
	BOOL colorize = [self.currentProfile boolForKey:ColorizeTextKey];
	[sourceTextView colorizeText:colorize];
	[preambleTextView colorizeText:colorize];
}

- (IBAction)toggleOutputDrawer:(id)sender 
{
	if (outputDrawer.state == NSDrawerOpenState) {
		outputDrawerMenuItem.State = NO;
		[outputDrawer close];
	} else {
		[self showOutputDrawer];
	}
    
}

-(IBAction)changeHighlight:(id)sender
{
	flashHighlightMenuItem.State = NSOffState;
	solidHighlightMenuItem.State = NSOffState;
	noHighlightMenuItem.State = NSOffState;
    
	if (sender == flashHighlightMenuItem) {
		highlightPattern = FLASH;
	}
	if (sender == solidHighlightMenuItem) {
		highlightPattern = SOLID;
	}
	if (sender == noHighlightMenuItem) {
		highlightPattern = NOHIGHLIGHT;
	}
	
	switch (highlightPattern) {
		case FLASH:
			flashHighlightMenuItem.State = NSOnState;
			break;
		case SOLID:
			solidHighlightMenuItem.State = NSOnState;
			break;
		case NOHIGHLIGHT:
			noHighlightMenuItem.State = NSOnState;
			break;
		default:
			break;
	}
	
}


- (IBAction)togglePreambleWindow:(id)sender
{
	if (preambleWindow.isVisible) {
		[preambleWindow close];
	} else {
		preambleWindowMenuItem.State = YES;

		NSRect mainWindowRect = mainWindow.frame;
		NSRect preambleWindowRect = preambleWindow.frame;
		[preambleWindow setFrame:NSMakeRect(NSMinX(mainWindowRect) - NSWidth(preambleWindowRect), 
											NSMinY(mainWindowRect) + NSHeight(mainWindowRect) - NSHeight(preambleWindowRect), 
											NSWidth(preambleWindowRect), NSHeight(preambleWindowRect))
						 display:NO];
		[preambleWindow makeKeyAndOrderFront:nil];
        [preambleTextView colorizeText:[self.currentProfile boolForKey:ColorizeTextKey]];
	}
    
}

- (IBAction)closeWindow:(id)sender
{
	[[NSApp keyWindow] close];
}

- (IBAction)showFontPanelOfSource:(id)sender
{
	NSFontPanel *panel = NSFontPanel.sharedFontPanel;
	[panel makeKeyAndOrderFront:self];
	[panel setPanelFont:sourceTextView.font isMultiple:NO];
}

- (IBAction)showFontPanelOfPreamble:(id)sender
{
	NSFontPanel *panel = NSFontPanel.sharedFontPanel;
	[panel makeKeyAndOrderFront:self];
	[panel setPanelFont:preambleTextView.font isMultiple:NO];
}


- (IBAction)searchPrograms:(id)sender
{
	NSString *latexPath;
	NSString *dvipdfmxPath;
	NSString *gsPath;
	
	if (!(latexPath = [self searchProgram:@"platex"])) {
		latexPath = @"";
		[self showNotFoundError:@"LaTeX"];
	}
    if (!(dvipdfmxPath = [self searchProgram:@"dvipdfmx"])) {
		dvipdfmxPath = @"";
		[self showNotFoundError:@"dvipdfmx"];
	}
	if (!(gsPath = [self searchProgram:@"gs"])) {
		gsPath = @"";
		[self showNotFoundError:@"ghostscript"];
	}
	
	latexPathTextField.StringValue = latexPath;
	dvipdfmxPathTextField.StringValue = dvipdfmxPath;
	gsPathTextField.StringValue = gsPath;
}

- (void)generateImage
{
    NSString *inputSourceFilePath;
    NSMutableDictionary *aProfile = self.currentProfile;
    aProfile[PdfcropPathKey] = [NSBundle.mainBundle pathForResource:@"pdfcrop" ofType:nil];
    aProfile[EpstopdfPathKey] = [NSBundle.mainBundle pathForResource:@"epstopdf" ofType:nil];
    aProfile[QuietKey] = @(NO);
    aProfile[ControllerKey] = self;
    
    Converter *converter = [Converter converterWithProfile:aProfile];
    
    switch ([aProfile integerForKey:InputMethodKey]) {
        case DIRECT:
            [converter compileAndConvertWithBody:sourceTextView.textStorage.string];
            break;
        case FROMFILE:
            inputSourceFilePath = [aProfile stringForKey:InputSourceFilePathKey];
            if ([NSFileManager.defaultManager fileExistsAtPath:inputSourceFilePath]) {
                [converter compileAndConvertWithInputPath:inputSourceFilePath];
            } else {
                NSRunAlertPanel(localizedString(@"Error"), [NSString stringWithFormat:localizedString(@"inputFileNotFoundErrorMsg"), inputSourceFilePath], @"OK", nil, nil);
            }
            break;
        default:
            break;
    }
    
    generateButton.Enabled = YES;
    generateMenuItem.Enabled = YES;
}

- (IBAction)generate:(id)sender
{
    if (showOutputDrawerCheckBox.state) {
        [self showOutputDrawer];
    }
	
    generateButton.Enabled = NO;
	generateMenuItem.Enabled = NO;
    
    [self generateImage];
}

@end