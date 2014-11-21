#import "ProfileController.h"
#import "TeXTextView.h"
#import "global.h"
#import "ControllerG.h"
#import "NSDictionary-Extension.h"
//#import <Sparkle/Sparkle.h>

@class ProfileController;
@class TeXTextView;

#define AutoSavedProfileName @"*AutoSavedProfile*"
//#define SNOWLEOPARD 678

@interface ControllerG()
@property IBOutlet ProfileController *profileController;
@property IBOutlet NSWindow *mainWindow;
@property IBOutlet TeXTextView *sourceTextView;
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
@property IBOutlet NSButton *generateButton;
@property IBOutlet NSButton *transparentCheckBox;
@property IBOutlet NSButton *showOutputDrawerCheckBox;
@property IBOutlet NSButton *threadingCheckBox;
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
@property IBOutlet NSTextField *platexPathTextField;
@property IBOutlet NSTextField *dvipdfmxPathTextField;
@property IBOutlet NSTextField *gsPathTextField;
@property IBOutlet NSTextField *numberOfCompilationTextField;
@property IBOutlet NSButton *getOutlineCheckBox;
@property IBOutlet NSButton *ignoreErrorCheckBox;
@property IBOutlet NSButton *utfExportCheckBox;
@property IBOutlet NSButtonCell *sjisRadioButton;
@property IBOutlet NSButtonCell *eucRadioButton;
@property IBOutlet NSButtonCell *jisRadioButton;
@property IBOutlet NSButtonCell *utf8RadioButton;
@property IBOutlet NSButtonCell *upTeXRadioButton;
@property IBOutlet NSMatrix *unitMatrix;
@property IBOutlet NSMatrix *priorityMatrix;
@property HighlightPattern highlightPattern;
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
@synthesize generateButton;
@synthesize transparentCheckBox;
@synthesize showOutputDrawerCheckBox;
@synthesize threadingCheckBox;
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
@synthesize platexPathTextField;
@synthesize dvipdfmxPathTextField;
@synthesize gsPathTextField;
@synthesize numberOfCompilationTextField;
@synthesize getOutlineCheckBox;
@synthesize ignoreErrorCheckBox;
@synthesize utfExportCheckBox;
@synthesize sjisRadioButton;
@synthesize eucRadioButton;
@synthesize jisRadioButton;
@synthesize utf8RadioButton;
@synthesize upTeXRadioButton;
@synthesize unitMatrix;
@synthesize priorityMatrix;
@synthesize highlightPattern;

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
	if (str != nil) {
		[outputTextView.textStorage.mutableString appendString:str];
		[outputTextView scrollRangeToVisible: NSMakeRange(outputTextView.string.length, 0)]; // 最下部までスクロール
		//[outputTextView display]; // 再描画
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
/*	if(![outputWindow isVisible])
	{
		NSRect mainWindowRect = [mainWindow frame];
		NSRect outputWindowRect = [outputWindow frame];
		[outputWindow setFrame:NSMakeRect(NSMinX(mainWindowRect) + NSWidth(mainWindowRect), 
										  NSMinY(mainWindowRect) + NSHeight(mainWindowRect) - NSHeight(outputWindowRect), 
										  NSWidth(outputWindowRect), NSHeight(outputWindowRect))
					   display:NO];
	}
	[outputWindow makeKeyAndOrderFront:nil];*/
}

- (void)showExtensionError
{
	NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"extensionErrMsg", nil), @"OK", nil, nil);	
}

- (void)showNotFoundError:(NSString*)aPath
{
	NSRunAlertPanel(NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"%@%@", aPath, NSLocalizedString(@"programNotFoundErrorMsg", nil)], @"OK", nil, nil);
}

- (BOOL)platexExistsAtPath:(NSString*)platexPath dvipdfmxPath:(NSString*)dvipdfmxPath gsPath:(NSString*)gsPath
{
	NSFileManager* fileManager = NSFileManager.defaultManager;
	
	if (![fileManager fileExistsAtPath:[platexPath componentsSeparatedByString:@" "][0]]) {
		[self showNotFoundError:platexPath];
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
	NSRunAlertPanel(NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"%@%@", aPath, NSLocalizedString(@"fileGenerateErrorMsg", nil)], @"OK", nil, nil);
}

- (void)showExecError:(NSString*)command
{
	NSRunAlertPanel(NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"%@%@", command, NSLocalizedString(@"execErrorMsg", nil)], @"OK", nil, nil);
}

- (void)showCannotOverwriteError:(NSString*)path
{
	NSRunAlertPanel(NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"%@%@", path, NSLocalizedString(@"cannotOverwriteErrorMsg", nil)], @"OK", nil, nil);
}

- (void)showCannotCreateDirectoryError:(NSString*)dir
{
    NSRunAlertPanel(NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"%@%@", dir, NSLocalizedString(@"cannotCreateDirectoryErrorMsg", nil)], @"OK", nil, nil);
}

- (void)showCompileError
{
	NSRunAlertPanel(NSLocalizedString(@"Alert", nil), NSLocalizedString(@"compileErrorMsg", nil), @"OK", nil, nil);
}

#pragma mark -
#pragma mark プロファイルの読み書き関連
- (void)loadSettingForTextField:(NSTextField*)textField fromProfile:(NSDictionary*)aProfile forKey:(NSString*)aKey
{
	NSString* tempStr = [aProfile stringForKey:aKey];
	
	if (tempStr != nil) {
		textField.StringValue = tempStr;
	}
}

- (void)loadSettingForTextView:(NSTextView*)textView fromProfile:(NSDictionary*)aProfile forKey:(NSString*)aKey
{
	NSString* tempStr = [aProfile stringForKey:aKey];
	
	if (tempStr != nil) {
		textView.textStorage.mutableString.String = tempStr;
	}
}

- (void)adoptProfile:(NSDictionary*)aProfile
{
    if (aProfile == nil) {
        return;
    }
	
	[self loadSettingForTextField:outputFileTextField fromProfile:aProfile forKey:@"outputFile"];
	
	showOutputDrawerCheckBox.State = [aProfile integerForKey:@"showOutputDrawer"];
	threadingCheckBox.State = [aProfile integerForKey:@"threading"];
	previewCheckBox.State = [aProfile integerForKey:@"preview"];
	deleteTmpFileCheckBox.State = [aProfile integerForKey:@"deleteTmpFile"];

	embedInIllustratorCheckBox.State = [aProfile integerForKey:@"embedInIllustrator"];
	ungroupCheckBox.State = [aProfile integerForKey:@"ungroup"];
	
	transparentCheckBox.State = [aProfile boolForKey:@"transparent"];
	getOutlineCheckBox.State = [aProfile boolForKey:@"getOutline"];
	
	ignoreErrorCheckBox.State = [aProfile boolForKey:@"ignoreError"];
	utfExportCheckBox.State = [aProfile boolForKey:@"utfExport"];
	
	convertYenMarkMenuItem.State = [aProfile boolForKey:@"convertYenMark"];
	colorizeTextMenuItem.State = [aProfile boolForKey:@"colorizeText"];
	
	highlightPattern = [aProfile integerForKey:@"highlightPattern"];
	[self changeHighlight:nil];

	flashInMovingMenuItem.State = [aProfile boolForKey:@"flashInMoving"];

	highlightContentMenuItem.State = [aProfile boolForKey:@"highlightContent"];
	beepMenuItem.State = [aProfile boolForKey:@"beep"];
	flashBackgroundMenuItem.State = [aProfile boolForKey:@"flashBackground"];

	checkBraceMenuItem.State = [aProfile boolForKey:@"checkBrace"];
	checkBracketMenuItem.State = [aProfile boolForKey:@"checkBracket"];
	checkSquareBracketMenuItem.State = [aProfile boolForKey:@"checkSquareBracket"];
	checkParenMenuItem.State = [aProfile boolForKey:@"checkParen"];

	autoCompleteMenuItem.State = [aProfile boolForKey:@"autoComplete"];
	showTabCharacterMenuItem.State = [aProfile boolForKey:@"showTabCharacter"];
	showSpaceCharacterMenuItem.State = [aProfile boolForKey:@"showSpaceCharacter"];
	showFullwidthSpaceCharacterMenuItem.State = [aProfile boolForKey:@"showFullwidthSpaceCharacter"];
	showNewLineCharacterMenuItem.State = [aProfile boolForKey:@"showNewLineCharacter"];

    NSString *encoding = [aProfile stringForKey:@"encoding"];
    if (encoding) {
        sjisRadioButton.State = NSOffState;
        jisRadioButton.State = NSOffState;
        eucRadioButton.State = NSOffState;
        utf8RadioButton.State = NSOffState;
        upTeXRadioButton.State = NSOffState;
        
        if ([encoding isEqualToString:@"jis"]) {
            jisRadioButton.State = NSOnState;
        } else if ([encoding isEqualToString:@"euc"]) {
            eucRadioButton.State = NSOnState;
        } else if ([encoding isEqualToString:@"utf8"]) {
            utf8RadioButton.State = NSOnState;
        } else if ([encoding isEqualToString:@"uptex"]) {
            upTeXRadioButton.State = NSOnState;
        } else {
            sjisRadioButton.State = NSOnState;
        }
    }
	
	[self loadSettingForTextField:platexPathTextField fromProfile:aProfile forKey:@"platexPath"];
	[self loadSettingForTextField:dvipdfmxPathTextField fromProfile:aProfile forKey:@"dvipdfmxPath"];
	[self loadSettingForTextField:gsPathTextField fromProfile:aProfile forKey:@"gsPath"];
	
	[self loadSettingForTextField:resolutionLabel fromProfile:aProfile forKey:@"resolutionLabel"];
	[self loadSettingForTextField:leftMarginLabel fromProfile:aProfile forKey:@"leftMarginLabel"];
	[self loadSettingForTextField:rightMarginLabel fromProfile:aProfile forKey:@"rightMarginLabel"];
	[self loadSettingForTextField:topMarginLabel fromProfile:aProfile forKey:@"topMarginLabel"];
	[self loadSettingForTextField:bottomMarginLabel fromProfile:aProfile forKey:@"bottomMarginLabel"];
	
    numberOfCompilationTextField.IntValue = MAX(1, [aProfile integerForKey:@"numberOfCompilation"]);
	resolutionSlider.FloatValue = [aProfile integerForKey:@"resolution"];
	leftMarginSlider.IntValue = [aProfile integerForKey:@"leftMargin"];
	rightMarginSlider.IntValue = [aProfile integerForKey:@"rightMargin"];
	topMarginSlider.IntValue = [aProfile integerForKey:@"topMargin"];
	bottomMarginSlider.IntValue = [aProfile integerForKey:@"bottomMargin"];
    
    NSInteger unitTag = [aProfile integerForKey:@"unit"];
    [unitMatrix selectCellWithTag:unitTag];

    NSInteger priorityTag = [aProfile integerForKey:@"priority"];
    [priorityMatrix selectCellWithTag:priorityTag];

	[self loadSettingForTextView:preambleTextView fromProfile:aProfile forKey:@"preamble"];
	
	NSFont *aFont = [NSFont fontWithName:[aProfile stringForKey:@"sourceFontName"] size:[aProfile floatForKey:@"sourceFontSize"]];
	if (aFont != nil) {
		sourceTextView.Font = aFont;
	}
	
	aFont = [NSFont fontWithName:[aProfile stringForKey:@"preambleFontName"] size:[aProfile floatForKey:@"preambleFontSize"]];
	if (aFont != nil) {
		preambleTextView.Font = aFont;
	}
	[preambleTextView colorizeText:[aProfile boolForKey:@"colorizeText"]];
}

- (BOOL)adoptProfileWithWindowFrameForName:(NSString*)profileName
{
	NSDictionary* aProfile = [profileController profileForName:profileName];
    if (aProfile == nil){
        return NO;
    }
	
	[self adoptProfile:aProfile];

	float x, y, mainWindowWidth, mainWindowHeight; 
	x = [aProfile floatForKey:@"x"];
	y = [aProfile floatForKey:@"y"];
	mainWindowWidth = [aProfile floatForKey:@"mainWindowWidth"];
	mainWindowHeight = [aProfile floatForKey:@"mainWindowHeight"];
	
	if (x!=0 && y!=0 && mainWindowWidth!=0 && mainWindowHeight!=0) {
		[mainWindow setFrame:NSMakeRect(x, y, mainWindowWidth, mainWindowHeight) display:YES];
	}
	
	return YES;
}



- (NSMutableDictionary*)currentProfile
{
	NSMutableDictionary *currentProfile = NSMutableDictionary.dictionary;
	@try {
		currentProfile[@"x"] = @(NSMinX(mainWindow.frame));
		currentProfile[@"y"] = @(NSMinY(mainWindow.frame));
        currentProfile[@"mainWindowWidth"] = @(NSWidth(mainWindow.frame));
        currentProfile[@"mainWindowHeight"] = @(NSHeight(mainWindow.frame));
        currentProfile[@"outputFile"] = outputFileTextField.stringValue;
        
        currentProfile[@"showOutputDrawer"] = @(showOutputDrawerCheckBox.state);
        currentProfile[@"threading"] = @(threadingCheckBox.state);
        currentProfile[@"preview"] = @(previewCheckBox.state);
        currentProfile[@"deleteTmpFile"] = @(deleteTmpFileCheckBox.state);
        
        currentProfile[@"embedInIllustrator"] = @(embedInIllustratorCheckBox.state);
        currentProfile[@"ungroup"] = @(ungroupCheckBox.state);
        
        currentProfile[@"transparent"] = @(transparentCheckBox.state);
        currentProfile[@"getOutline"] = @(getOutlineCheckBox.state);
        currentProfile[@"ignoreError"] = @(ignoreErrorCheckBox.state);
        currentProfile[@"utfExport"] = @(utfExportCheckBox.state);
        
        currentProfile[@"platexPath"] = platexPathTextField.stringValue;
        currentProfile[@"dvipdfmxPath"] = dvipdfmxPathTextField.stringValue;
        currentProfile[@"gsPath"] = gsPathTextField.stringValue;
        currentProfile[@"numberOfCompilation"] = @(numberOfCompilationTextField.integerValue);
        
        currentProfile[@"resolutionLabel"] = resolutionLabel.stringValue;
        currentProfile[@"leftMarginLabel"] = leftMarginLabel.stringValue;
        currentProfile[@"rightMarginLabel"] = rightMarginLabel.stringValue;
        currentProfile[@"topMarginLabel"] = topMarginLabel.stringValue;
        currentProfile[@"bottomMarginLabel"] = bottomMarginLabel.stringValue;
        
        currentProfile[@"resolution"] = @(resolutionLabel.floatValue);
        currentProfile[@"leftMargin"] = @(leftMarginLabel.intValue);
        currentProfile[@"rightMargin"] = @(rightMarginLabel.intValue);
        currentProfile[@"topMargin"] = @(topMarginLabel.intValue);
        currentProfile[@"bottomMargin"] = @(bottomMarginLabel.intValue);
        
        currentProfile[@"unit"] = @(unitMatrix.selectedTag);
        currentProfile[@"priority"] = @(priorityMatrix.selectedTag);
        
        currentProfile[@"convertYenMark"] = @(convertYenMarkMenuItem.state);
        currentProfile[@"colorizeText"] = @(colorizeTextMenuItem.state);
        currentProfile[@"highlightPattern"] = @(highlightPattern);
        currentProfile[@"flashInMoving"] = @(flashInMovingMenuItem.state);
        currentProfile[@"highlightContent"] = @(highlightContentMenuItem.state);
        currentProfile[@"beep"] = @(beepMenuItem.state);
        currentProfile[@"flashBackground"] = @(flashBackgroundMenuItem.state);
        currentProfile[@"checkBrace"] = @(checkBraceMenuItem.state);
        currentProfile[@"checkBracket"] = @(checkBracketMenuItem.state);
        currentProfile[@"checkSquareBracket"] = @(checkSquareBracketMenuItem.state);
        currentProfile[@"checkParen"] = @(checkParenMenuItem.state);
        currentProfile[@"autoComplete"] = @(autoCompleteMenuItem.state);
        currentProfile[@"showTabCharacter"] = @(showTabCharacterMenuItem.state);
        currentProfile[@"showSpaceCharacter"] = @(showSpaceCharacterMenuItem.state);
        currentProfile[@"showFullwidthSpaceCharacter"] = @(showFullwidthSpaceCharacterMenuItem.state);
        currentProfile[@"showNewLineCharacter"] = @(showNewLineCharacterMenuItem.state);
        currentProfile[@"sourceFontName"] = sourceTextView.font.fontName;
        currentProfile[@"sourceFontSize"] = @(sourceTextView.font.pointSize);
        currentProfile[@"preambleFontName"] = preambleTextView.font.fontName;
        currentProfile[@"preambleFontSize"] = @(preambleTextView.font.pointSize);
		
		currentProfile[@"preamble"] = [NSString stringWithString:preambleTextView.textStorage.string]; // stringWithString は必須
	}
	@catch (NSException * e) {
	}
	
	if (sjisRadioButton.state) {
		currentProfile[@"encoding"] = @"sjis";
	} else if (eucRadioButton.state) {
		currentProfile[@"encoding"] = @"euc";
	} else if (jisRadioButton.state) {
		currentProfile[@"encoding"] = @"jis";
	} else if (utf8RadioButton.state) {
		currentProfile[@"encoding"] = @"utf8";
	} else if (upTeXRadioButton.state) {
		currentProfile[@"encoding"] = @"uptex";
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
    NSMutableArray* searchPaths = [NSMutableArray arrayWithArray:[userPath componentsSeparatedByString:@":"]];

    [searchPaths addObjectsFromArray: @[@"/Applications/TeXLive/texlive/2014/bin/x86_64-darwin",
                                        @"/Applications/TeXLive/texlive/2013/bin/x86_64-darwin",
                                        @"/usr/local/texlive/2014/bin/x86_64-darwin",
                                        @"/usr/local/texlive/2013/bin/x86_64-darwin",
                                        @"/opt/local/texlive/2014/bin/x86_64-darwin",
                                        @"/opt/local/texlive/2013/bin/x86_64-darwin",
                                        @"/opt/texlive/2014/bin/x86_64-darwin",
                                        @"/opt/texlive/2013/bin/x86_64-darwin",
                                        @"/Applications/pTeX.app/teTeX/bin",
                                        @"/Applications/UpTeX.app/teTeX/bin",
                                        @"/usr/texbin",
                                        @"/usr/local/teTeX/bin",
                                        @"/usr/local/bin",
                                        @"/opt/local/bin",
                                        @"/sw/bin"
                                        ]];
    
	NSFileManager* fileManager = NSFileManager.defaultManager;
	
	for (NSString *aPath in searchPaths) {
		NSString *aFullPath = [aPath stringByAppendingPathComponent:programName];
        if ([fileManager fileExistsAtPath:aFullPath]) {
            return aFullPath;
        }
	}
	
	return nil;
}

- (void)restoreDefaultPreambleLogic
{
	preambleTextView.textStorage.mutableString.String = @"\\documentclass[fleqn,papersize]{jsarticle}\n\\usepackage{amsmath,amssymb}\n\\pagestyle{empty}\n";
}

#pragma mark -
#pragma mark デリゲート・ノティフィケーションのコールバック
- (void)awakeFromNib
{
	//SUUpdater* updater = [SUUpdater updaterForBundle:[NSBundle bundleForClass:[self class]];
	//[updater setAutomaticallyChecksForUpdates:YES];
	//[updater resetUpdateCycle];
	//[updater checkForUpdates:self];	
	
	//	以下は Interface Builder 上で設定できる
	//	[mainWindow setReleasedWhenClosed:NO];
	//	[outputWindow setReleasedWhenClosed:NO];
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
	
	/*
	// アウトプットウィンドウが閉じられるときにメニューのチェックを外す
	[aCenter addObserver: self
				selector: @selector(uncheckOutputWindowMenuItem:)
					name: NSWindowWillCloseNotification
				  object: outputWindow];
	 */
	
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
	
	// デフォルトのアウトプットファイルのパスをセット
	outputFileTextField.StringValue = [NSString stringWithFormat:@"%@/Desktop/equation.eps", NSHomeDirectory()];
	
	// 保存された設定を読み込む
	NSFileManager* fileManager = NSFileManager.defaultManager;
	NSString* plistFile = [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", NSHomeDirectory(), [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
	
	BOOL loadLastProfileSuccess = NO;
	
	if ([fileManager fileExistsAtPath:plistFile]) {
		[profileController loadProfilesFromPlist];
		loadLastProfileSuccess = [self adoptProfileWithWindowFrameForName:AutoSavedProfileName];
		[profileController removeProfileForName:AutoSavedProfileName];
	}
    
	if (!loadLastProfileSuccess) { // 初回起動時の各種プログラムのパスの自動設定
		[profileController initProfiles];
		[self restoreDefaultPreambleLogic];
		
		NSString *platexPath;
		NSString *dvipdfmxPath;
		NSString *gsPath;
		
		if (!(platexPath = [self searchProgram:@"platex"])) {
			platexPath = @"/usr/local/bin/platex";
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
		
		platexPathTextField.StringValue = platexPath;
		dvipdfmxPathTextField.StringValue = dvipdfmxPath;
		gsPathTextField.StringValue = gsPath;
		
        [self performSelectorOnMainThread:@selector(showInitMessage:)
                               withObject:@{@"platexPath": platexPath,
                                            @"dvipdfmxPath": dvipdfmxPath,
                                            @"gsPath": gsPath
                                            }
                            waitUntilDone:NO];
		
		NSFont *defaultFont = [NSFont fontWithName:@"Osaka-Mono" size:13];
		if (defaultFont != nil) {
			sourceTextView.Font = defaultFont;
			preambleTextView.Font = defaultFont;
		}
		
		[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"SUEnableAutomaticChecks"];
		
	}
	
	// Leopard 以外では文字化け対策チェックボックスを無効化
//	if(!((NSFoundationVersionNumber > LEOPARD) && (NSFoundationVersionNumber < SNOWLEOPARD)))
//	{
//		[getOutlineCheckBox.State = NO];
//		[getOutlineCheckBox setEnabled:NO];
//	}

	// CommandComepletion.txt のロード
	unichar esc = 0x001B;
	g_commandCompletionChar = [NSString stringWithCharacters:&esc length: 1];
	NSData 	*myData = nil;

	NSString *completionPath = @"~/Library/TeXShop/CommandCompletion/CommandCompletion.txt".stringByStandardizingPath;
	if ([NSFileManager.defaultManager fileExistsAtPath:completionPath])
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

}

- (void)showInitMessage:(NSDictionary*)paths
{
    NSRunAlertPanel(NSLocalizedString(@"initSettingsMsg", nil),
                    [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@",
                     NSLocalizedString(@"setPathMsg1", nil), paths[@"platexPath"], paths[@"dvipdfmxPath"], paths[@"gsPath"], NSLocalizedString(@"setPathMsg2", nil)],
                    @"OK", nil, nil);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[profileController updateProfile:self.currentProfile forName:AutoSavedProfileName];
	[profileController saveProfiles];
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)closeOtherWindows:(NSNotification *)aNotification
{
	[preambleWindow close];
	[preferenceWindow close];
	//[outputWindow close];
}

- (void)uncheckOutputDrawerMenuItem:(NSNotification *)aNotification
{
	outputDrawerMenuItem.State = NO;
}

- (void)uncheckPreambleWindowMenuItem:(NSNotification *)aNotification
{
	preambleWindowMenuItem.State = NO;
}

- (IBAction)showMainWindow:(id)sender
{
	[self showMainWindow];
}
#pragma mark -

- (IBAction)restoreDefaultPreamble:(id)sender
{
	if (NSRunAlertPanel(NSLocalizedString(@"Confirm", nil), NSLocalizedString(@"resotreDefaultPreambleMsg", nil), @"OK", NSLocalizedString(@"Cancel", nil), nil) == NSOKButton) {
		[self restoreDefaultPreambleLogic];
	}
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


- (IBAction)showSavePanel:(id)sender
{
	NSSavePanel* aPanel = NSSavePanel.savePanel;
	if ([aPanel runModal] == NSFileHandlingPanelOKButton) {
		outputFileTextField.StringValue = aPanel.URL.path;
	}
}

- (IBAction)toggleMenuItem:(id)sender
{
    [sender setState:![sender state]];
	
	BOOL colorize = [self.currentProfile boolForKey:@"colorizeText"];
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
        [preambleTextView colorizeText:[self.currentProfile boolForKey:@"colorizeText"]];
	}
    
}

- (IBAction)closeWindow:(id)sender
{
	[[NSApp keyWindow] close];
}

- (IBAction)showFontPanelOfSource:(id)sender
{
	NSFontPanel* panel = NSFontPanel.sharedFontPanel;
	[panel makeKeyAndOrderFront:self];
	[panel setPanelFont:sourceTextView.font isMultiple:NO];
}

- (IBAction)showFontPanelOfPreamble:(id)sender
{
	NSFontPanel* panel = NSFontPanel.sharedFontPanel;
	[panel makeKeyAndOrderFront:self];
	[panel setPanelFont:preambleTextView.font isMultiple:NO];
	
	/*
	 NSFontManager *fontManager = [NSFontManager sharedFontManager];
	 [fontManager setDelegate:self];
	 [fontManager orderFrontFontPanel:self];
	 [fontManager setSelectedFont:[sourceTextView font] isMultiple:NO];
	 [fontManager setSelectedFont:[preambleTextView font] isMultiple:NO];
	 [fontManager setSelectedFont:[outputTextView font] isMultiple:NO];
	 */
}


- (IBAction)searchPrograms:(id)sender
{
	NSString* platexPath;
	NSString* dvipdfmxPath;
	NSString* gsPath;
	
	platexPath = (upTeXRadioButton.state == NSOnState) ? [self searchProgram:@"uplatex"] : [self searchProgram:@"platex"];
	if (!platexPath) {
		platexPath = @"";
		[self showNotFoundError:@"platex"];
	}
    if (!(dvipdfmxPath = [self searchProgram:@"dvipdfmx"])) {
		dvipdfmxPath = @"";
		[self showNotFoundError:@"dvipdfmx"];
	}
	if (!(gsPath = [self searchProgram:@"gs"])) {
		gsPath = @"";
		[self showNotFoundError:@"ghostscript"];
	}
	
	platexPathTextField.StringValue = platexPath;
	dvipdfmxPathTextField.StringValue = dvipdfmxPath;
	gsPathTextField.StringValue = gsPath;
}

- (IBAction)setParametersForTeXLive:(id)sender
{
    sjisRadioButton.State = NSOffState;
    jisRadioButton.State = NSOffState;
    eucRadioButton.State = NSOffState;
    utf8RadioButton.State = NSOffState;
    upTeXRadioButton.State = NSOnState;
	platexPathTextField.StringValue = @"/usr/texbin/uplatex";
	dvipdfmxPathTextField.StringValue = @"/usr/texbin/dvipdfmx";
	gsPathTextField.StringValue = @"/usr/local/bin/gs";
    
    if (NSRunAlertPanel(NSLocalizedString(@"Confirm", @"Confirm"), NSLocalizedString(@"preambleForTeXLiveMsg", @"preambleForTeXLiveMsg"), @"OK", NSLocalizedString(@"Cancel", @"Cancel"), nil) == NSOKButton) {
        preambleTextView.textStorage.mutableString.String = @"\\documentclass[fleqn,papersize,uplatex]{jsarticle}\n\\usepackage{amsmath,amssymb}\n\\pagestyle{empty}\n";
    }
}

- (void)doGeneratingThread
{
    @autoreleasepool {
        BOOL threading = (threadingCheckBox.state == NSOnState);
        
        NSMutableDictionary *aProfile = self.currentProfile;
        aProfile[@"pdfcropPath"] = [NSBundle.mainBundle pathForResource:@"pdfcrop" ofType:nil];
        aProfile[@"epstopdfPath"] = [NSBundle.mainBundle pathForResource:@"epstopdf" ofType:nil];
        aProfile[@"quiet"] = @(NO);
        aProfile[@"controller"] = self;
        
        Converter* converter = [Converter converterWithProfile:aProfile];
        
        NSString* texBodyStr = sourceTextView.textStorage.string;
        
        [converter compileAndConvertWithBody:texBodyStr];
        
        generateButton.Enabled = YES;
        generateMenuItem.Enabled = YES;
        
        if (threading) {
            [outputTextView display]; // 再描画
            [NSThread exit];
        }
    }
}

- (IBAction)generate:(id)sender
{
    if (showOutputDrawerCheckBox.state) {
        [self showOutputDrawer];
    }
	
    generateButton.Enabled = NO;
	generateMenuItem.Enabled = NO;

    if (threadingCheckBox.state) {
		[NSThread detachNewThreadSelector:@selector(doGeneratingThread) toTarget:self withObject:nil];
	} else {
		[self doGeneratingThread];
	}
}

@end
