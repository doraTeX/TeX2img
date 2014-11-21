#import "ControllerG.h"
#import "NSDictionary-Extension.h"
#import "NSMutableDictionary-Extension.h"
#define AutoSavedProfileName @"*AutoSavedProfile*"
#define LEOPARD 568
#define SNOWLEOPARD 678

@implementation ControllerG
////// ここから OutputController プロトコルの実装 //////
- (void)showMainWindow
{
	[mainWindow makeKeyAndOrderFront:nil];
}

- (void)appendOutputAndScroll:(NSMutableString*)mStr quiet:(BOOL)quiet
{
	if(quiet) return;
	if(mStr != nil)
	{
		[[[outputTextView textStorage] mutableString] appendString:mStr];
		[outputTextView scrollRangeToVisible: NSMakeRange([[outputTextView string] length], 0)]; // 最下部までスクロール
		//[outputTextView display]; // 再描画
	}
}

- (void)clearOutputTextView
{
	[[[outputTextView textStorage] mutableString] setString:@""];
}

- (void)showOutputDrawer
{
	[outputDrawerMenuItem setState:YES];
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

- (BOOL)checkPlatexPath:(NSString*)platexPath dvipdfmxPath:(NSString*)dvipdfmxPath gsPath:(NSString*)gsPath
{
	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	if(![fileManager fileExistsAtPath:[[platexPath componentsSeparatedByString:@" "] objectAtIndex:0]])
	{
		[self showNotFoundError:platexPath];
		return NO;
	}
	if(![fileManager fileExistsAtPath:[[dvipdfmxPath componentsSeparatedByString:@" "] objectAtIndex:0]])
	{
		[self showNotFoundError:dvipdfmxPath];
		return NO;
	}
	if(![fileManager fileExistsAtPath:[[gsPath componentsSeparatedByString:@" "] objectAtIndex:0]])
	{
		[self showNotFoundError:gsPath];
		return NO;
	}
	
	return YES;
}

- (BOOL)checkPdfcropExistence;
{
	return YES;
}

- (BOOL)checkEpstopdfExistence;
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

- (void)showCannotOverrideError:(NSString*)path
{
	NSRunAlertPanel(NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"%@%@", path, NSLocalizedString(@"cannotOverrideErrorMsg", nil)], @"OK", nil, nil);
}

- (void)showCompileError
{
	NSRunAlertPanel(NSLocalizedString(@"Alert", nil), NSLocalizedString(@"compileErrorMsg", nil), @"OK", nil, nil);
}
////// ここまで OutputController プロトコルの実装 //////


////// ここからプロファイルの読み書き関連 //////
- (void)loadSettingForTextField:(NSTextField*)textField fromProfile:(NSDictionary*)aProfile forKey:(NSString*)aKey
{
	NSString* tempStr = [aProfile stringForKey:aKey];
	
	if(tempStr != nil)
	{
		[textField setStringValue:tempStr];	
	}
}

- (void)loadSettingForTextView:(NSTextView*)textView fromProfile:(NSDictionary*)aProfile forKey:(NSString*)aKey
{
	NSString* tempStr = [aProfile stringForKey:aKey];
	
	if(tempStr != nil)
	{
		[[[textView textStorage] mutableString] setString:tempStr];
	}
}

- (void)adoptProfile:(NSDictionary*)aProfile
{
	if(aProfile == nil) return;
	
	[self loadSettingForTextField:outputFileTextField fromProfile:aProfile forKey:@"outputFile"];
	
	[showOutputDrawerCheckBox setState:[aProfile integerForKey:@"showOutputDrawer"]];
	[threadingCheckBox setState:[aProfile integerForKey:@"threading"]];
	[previewCheckBox setState:[aProfile integerForKey:@"preview"]];
	[deleteTmpFileCheckBox setState:[aProfile integerForKey:@"deleteTmpFile"]];
	
	[transparentCheckBox setState:[aProfile boolForKey:@"transparent"]];
	[getOutlineCheckBox setState:[aProfile boolForKey:@"getOutline"]];
	
	[ignoreErrorCheckBox setState:[aProfile boolForKey:@"ignoreError"]];
	[utfExportCheckBox setState:[aProfile boolForKey:@"utfExport"]];
	
	[convertYenMarkMenuItem setState:[aProfile boolForKey:@"convertYenMark"]];
	[colorizeTextMenuItem setState:[aProfile boolForKey:@"colorizeText"]];
	[highlightBraceMenuItem setState:[aProfile boolForKey:@"highlightBrace"]];
	
	NSString *encoding = [aProfile stringForKey:@"encoding"];
	[sjisRadioButton setState:NSOffState];
	[jisRadioButton setState:NSOffState];
	[eucRadioButton setState:NSOffState];
	[utf8RadioButton setState:NSOffState];
	[upTeXRadioButton setState:NSOffState];

	if([encoding isEqualToString:@"jis"])
	{
		[jisRadioButton setState:NSOnState];
	}
	else if([encoding isEqualToString:@"euc"])
	{
		[eucRadioButton setState:NSOnState];
	}
	else if([encoding isEqualToString:@"utf8"])
	{
		[utf8RadioButton setState:NSOnState];
	}
	else if([encoding isEqualToString:@"uptex"])
	{
		[upTeXRadioButton setState:NSOnState];
	}
	else
	{
		[sjisRadioButton setState:NSOnState];
	}
	
	
	[self loadSettingForTextField:platexPathTextField fromProfile:aProfile forKey:@"platexPath"];
	[self loadSettingForTextField:dvipdfmxPathTextField fromProfile:aProfile forKey:@"dvipdfmxPath"];
	[self loadSettingForTextField:gsPathTextField fromProfile:aProfile forKey:@"gsPath"];
	
	[self loadSettingForTextField:resolutionLabel fromProfile:aProfile forKey:@"resolutionLabel"];
	[self loadSettingForTextField:leftMarginLabel fromProfile:aProfile forKey:@"leftMarginLabel"];
	[self loadSettingForTextField:rightMarginLabel fromProfile:aProfile forKey:@"rightMarginLabel"];
	[self loadSettingForTextField:topMarginLabel fromProfile:aProfile forKey:@"topMarginLabel"];
	[self loadSettingForTextField:bottomMarginLabel fromProfile:aProfile forKey:@"bottomMarginLabel"];
	
	[resolutionSlider setFloatValue:[aProfile integerForKey:@"resolution"]];
	[leftMarginSlider setIntValue:[aProfile integerForKey:@"leftMargin"]];
	[rightMarginSlider setIntValue:[aProfile integerForKey:@"rightMargin"]];
	[topMarginSlider setIntValue:[aProfile integerForKey:@"topMargin"]];
	[bottomMarginSlider setIntValue:[aProfile integerForKey:@"bottomMargin"]];
	
	[self loadSettingForTextView:preambleTextView fromProfile:aProfile forKey:@"preamble"];
	
	NSFont *aFont = [NSFont fontWithName:[aProfile stringForKey:@"sourceFontName"] size:[aProfile floatForKey:@"sourceFontSize"]];
	if(aFont != nil)
	{
		[sourceTextView setFont:aFont];
	}
	
	aFont = [NSFont fontWithName:[aProfile stringForKey:@"preambleFontName"] size:[aProfile floatForKey:@"preambleFontSize"]];
	if(aFont != nil)
	{
		[preambleTextView setFont:aFont];
	}
	[preambleTextView colorizeText:[aProfile boolForKey:@"colorizeText"]];
	
}

- (BOOL)adoptProfileWithWindowFrameForName:(NSString*)profileName
{
	NSDictionary* aProfile = [profileController profileForName:profileName];
	if(aProfile == nil) return NO;
	
	[self adoptProfile:aProfile];

	float x, y, mainWindowWidth, mainWindowHeight; 
	x = [aProfile floatForKey:@"x"];
	y = [aProfile floatForKey:@"y"];
	mainWindowWidth = [aProfile floatForKey:@"mainWindowWidth"];
	mainWindowHeight = [aProfile floatForKey:@"mainWindowHeight"];
	
	if(x!=0 && y!=0 && mainWindowWidth!=0 && mainWindowHeight!=0)
	{
		[mainWindow setFrame:NSMakeRect(x, y, mainWindowWidth, mainWindowHeight) display:YES];
	}
	
	return YES;
}



- (NSMutableDictionary*)currentProfile
{
	NSMutableDictionary *currentProfile = [NSMutableDictionary dictionary];
	[currentProfile setFloat:NSMinX([mainWindow frame]) forKey:@"x"];
	[currentProfile setFloat:NSMinY([mainWindow frame]) forKey:@"y"];
	[currentProfile setFloat:NSWidth([mainWindow frame]) forKey:@"mainWindowWidth"];
	[currentProfile setFloat:NSHeight([mainWindow frame]) forKey:@"mainWindowHeight"];
	[currentProfile setObject:[outputFileTextField stringValue] forKey:@"outputFile"];
	
	[currentProfile setInteger:[showOutputDrawerCheckBox state] forKey:@"showOutputDrawer"];
	[currentProfile setInteger:[threadingCheckBox state] forKey:@"threading"];
	[currentProfile setInteger:[previewCheckBox state] forKey:@"preview"];
	[currentProfile setInteger:[deleteTmpFileCheckBox state] forKey:@"deleteTmpFile"];
	
	[currentProfile setBool:[transparentCheckBox state] forKey:@"transparent"];
	[currentProfile setBool:[getOutlineCheckBox state] forKey:@"getOutline"];
	[currentProfile setBool:[ignoreErrorCheckBox state] forKey:@"ignoreError"];
	[currentProfile setBool:[utfExportCheckBox state] forKey:@"utfExport"];
	
	[currentProfile setObject:[platexPathTextField stringValue] forKey:@"platexPath"];
	[currentProfile setObject:[dvipdfmxPathTextField stringValue] forKey:@"dvipdfmxPath"];
	[currentProfile setObject:[gsPathTextField stringValue] forKey:@"gsPath"];
	
	[currentProfile setObject:[resolutionLabel stringValue] forKey:@"resolutionLabel"];
	[currentProfile setObject:[leftMarginLabel stringValue] forKey:@"leftMarginLabel"];
	[currentProfile setObject:[rightMarginLabel stringValue] forKey:@"rightMarginLabel"];
	[currentProfile setObject:[topMarginLabel stringValue] forKey:@"topMarginLabel"];
	[currentProfile setObject:[bottomMarginLabel stringValue] forKey:@"bottomMarginLabel"];
	
	[currentProfile setFloat:[resolutionLabel floatValue] forKey:@"resolution"];
	[currentProfile setInteger:[leftMarginLabel intValue] forKey:@"leftMargin"];
	[currentProfile setInteger:[rightMarginLabel intValue] forKey:@"rightMargin"];
	[currentProfile setInteger:[topMarginLabel intValue] forKey:@"topMargin"];
	[currentProfile setInteger:[bottomMarginLabel intValue] forKey:@"bottomMargin"];
	
	[currentProfile setInteger:[convertYenMarkMenuItem state] forKey:@"convertYenMark"];
	[currentProfile setInteger:[colorizeTextMenuItem state] forKey:@"colorizeText"];
	[currentProfile setInteger:[highlightBraceMenuItem state] forKey:@"highlightBrace"];
	[currentProfile setObject:[[sourceTextView font] fontName] forKey:@"sourceFontName"];
	[currentProfile setFloat:[[sourceTextView font] pointSize] forKey:@"sourceFontSize"];
	[currentProfile setObject:[[preambleTextView font] fontName] forKey:@"preambleFontName"];
	[currentProfile setFloat:[[preambleTextView font] pointSize] forKey:@"preambleFontSize"];
	
	[currentProfile setObject:[NSString stringWithString:[[preambleTextView textStorage] string]] forKey:@"preamble"];

	if([sjisRadioButton state])
	{
		[currentProfile setObject:@"sjis" forKey:@"encoding"];
	}
	else if([eucRadioButton state])
	{
		[currentProfile setObject:@"euc" forKey:@"encoding"];
	}
	else if([jisRadioButton state])
	{
		[currentProfile setObject:@"jis" forKey:@"encoding"];
	}
	else if([utf8RadioButton state])
	{
		[currentProfile setObject:@"utf8" forKey:@"encoding"];
	}
	else if([upTeXRadioButton state])
	{
		[currentProfile setObject:@"uptex" forKey:@"encoding"];
	}
	
	return currentProfile;
}

////// ここまでプロファイルの読み書き関連 //////

////// ここから他のメソッドから呼び出されるユーティリティメソッド //////
- (NSString*)searchProgram:(NSString*)programName
{
	NSArray *searchPaths = [NSArray arrayWithObjects:
							@"/Applications/pTeX.app/teTeX/bin", @"/usr/local/teTeX/bin", @"/usr/local/bin", @"/opt/local/bin", @"/sw/bin", nil];
	NSEnumerator *enumerator = [searchPaths objectEnumerator];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	NSString *aPath;
	NSString *aFullPath;
	
	while(aPath = [enumerator nextObject])
	{
		aFullPath = [NSString stringWithFormat:@"%@/%@", aPath, programName];
		if([fileManager fileExistsAtPath:aFullPath])
		{
			return aFullPath;
		}
	}
	
	return nil;
}

- (void)restoreDefaultPreambleLogic
{
	[[[preambleTextView textStorage] mutableString] setString:@"\\documentclass[fleqn,papersize]{jsarticle}\n\\usepackage{amsmath,amssymb}\n\\pagestyle{empty}\n"];
}

////// ここまで他のメソッドから呼び出されるユーティリティメソッド //////


////// ここからデリゲート・ノティフィケーションのコールバック //////
- (void)awakeFromNib
{
	//	以下は Interface Builder 上で設定できる
	//	[mainWindow setReleasedWhenClosed:NO];
	//	[outputWindow setReleasedWhenClosed:NO];
	//	[preambleWindow setReleasedWhenClosed:NO];
	
	// ノティフィケーションの設定
	NSNotificationCenter *aCenter=[NSNotificationCenter defaultCenter];
	
	// アプリケーションがアクティブになったときにメインウィンドウを表示
	[aCenter addObserver: self
				selector: @selector(showMainWindow:)
					name: @"NSApplicationDidBecomeActiveNotification"
				  object: NSApp];
	
	// プログラム終了時に設定保存実行
	[aCenter addObserver: self
				selector: @selector(applicationWillTerminate:)
					name: @"NSApplicationWillTerminateNotification"
				  object: NSApp];
	
	/*
	// アウトプットウィンドウが閉じられるときにメニューのチェックを外す
	[aCenter addObserver: self
				selector: @selector(uncheckOutputWindowMenuItem:)
					name: @"NSWindowWillCloseNotification"
				  object: outputWindow];
	 */
	
	// プリアンブルウィンドウが閉じられるときにメニューのチェックを外す
	[aCenter addObserver: self
				selector: @selector(uncheckPreambleWindowMenuItem:)
					name: @"NSWindowWillCloseNotification"
				  object: preambleWindow];
	
	// メインウィンドウが閉じられるときに他のウィンドウも閉じる
	[aCenter addObserver: self
				selector: @selector(closeOtherWindows:)
					name: @"NSWindowWillCloseNotification"
				  object: mainWindow];
	
	// テキストビューのカーソル移動の通知を受ける
	[aCenter addObserver: sourceTextView
				selector: @selector(textViewDidChangeSelection:)
					name: @"NSTextViewDidChangeSelectionNotification"
				  object: sourceTextView];

	[aCenter addObserver: preambleTextView
				selector: @selector(textViewDidChangeSelection:)
					name: @"NSTextViewDidChangeSelectionNotification"
				  object: preambleTextView];
	
	// デフォルトのアウトプットファイルのパスをセット
	[outputFileTextField setStringValue:[NSString stringWithFormat:@"%@/Desktop/equation.eps", NSHomeDirectory()]];
	
	// 保存された設定を読み込む
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSString* plistFile = [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", NSHomeDirectory(), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
	
	BOOL loadLastProfileSuccess = NO;
	
	if([fileManager fileExistsAtPath:plistFile])
	{
		[profileController loadProfilesFromPlist];
		loadLastProfileSuccess = [self adoptProfileWithWindowFrameForName:AutoSavedProfileName];
		[profileController removeProfileForName:AutoSavedProfileName];
	}
	if(!loadLastProfileSuccess) // 初回起動時の各種プログラムのパスの自動設定
	{
		[profileController initProfiles];
		[self restoreDefaultPreambleLogic];
		
		NSString *platexPath;
		NSString *dvipdfmxPath;
		NSString *gsPath;
		
		if(!(platexPath = [self searchProgram:@"platex"]))
		{
			platexPath = @"/usr/local/bin/platex";
			[self showNotFoundError:@"platex"];
		}
		if(!(dvipdfmxPath = [self searchProgram:@"dvipdfmx"]))
		{
			dvipdfmxPath = @"/usr/local/bin/dvipdfmx";
			[self showNotFoundError:@"dvipdfmx"];
		}
		if(!(gsPath = [self searchProgram:@"gs"]))
		{
			gsPath = @"/usr/local/bin/gs";
			[self showNotFoundError:@"ghostscript"];
		}
		
		[platexPathTextField setStringValue:platexPath];
		[dvipdfmxPathTextField setStringValue:dvipdfmxPath];
		[gsPathTextField setStringValue:gsPath];
		
		NSRunAlertPanel(NSLocalizedString(@"initSettingsMsg", nil), 
						[NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@",
						 NSLocalizedString(@"setPathMsg1", nil), platexPath, dvipdfmxPath, gsPath, NSLocalizedString(@"setPathMsg2", nil)],
						@"OK", nil, nil);
		
		NSFont *defaultFont = [NSFont fontWithName:@"Osaka-Mono" size:13];
		if(defaultFont != nil)
		{
			[sourceTextView setFont:defaultFont];
			[preambleTextView setFont:defaultFont];
		}
	}
	
	// Leopard 以外では文字化け対策チェックボックスを無効化
//	if(!((NSFoundationVersionNumber > LEOPARD) && (NSFoundationVersionNumber < SNOWLEOPARD)))
//	{
//		[getOutlineCheckBox setState:NO];
//		[getOutlineCheckBox setEnabled:NO];
//	}

	// CommandComepletion.txt のロード
	unichar esc = 0x001B;
	g_commandCompletionChar = [NSString stringWithCharacters: &esc length: 1];
	NSData 	*myData = nil;

	NSString *completionPath = [@"~/Library/TeXShop/CommandCompletion/CommandCompletion.txt" stringByStandardizingPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath: completionPath])
		myData = [NSData dataWithContentsOfFile:completionPath];
	
	if(myData)
	{
		NSStringEncoding myEncoding = NSUTF8StringEncoding;
		g_commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: myEncoding];
		if (! g_commandCompletionList) {
			g_commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: myEncoding];
		}
		
		[g_commandCompletionList insertString: @"\n" atIndex: 0];
		if ([g_commandCompletionList characterAtIndex: [g_commandCompletionList length]-1] != '\n')
			[g_commandCompletionList appendString: @"\n"];
	}

}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[profileController updateProfile:[self currentProfile] forName:AutoSavedProfileName];
	[profileController saveProfiles];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)closeOtherWindows:(NSNotification *)aNotification
{
	[preambleWindow close];
	[preferenceWindow close];
	//[outputWindow close];
}

- (void)uncheckOutputDrawerMenuItem:(NSNotification *)aNotification
{
	[outputDrawerMenuItem setState:NO];
}

- (void)uncheckPreambleWindowMenuItem:(NSNotification *)aNotification
{
	[preambleWindowMenuItem setState:NO];
}

- (IBAction)showMainWindow:(id)sender
{
	[self showMainWindow];
}
////// ここまでデリゲート・ノティフィケーションのコールバック //////

- (IBAction)restoreDefaultPreamble:(id)sender
{
	if(NSRunAlertPanel(NSLocalizedString(@"Confirm", nil), NSLocalizedString(@"resotreDefaultPreambleMsg", nil), @"OK", NSLocalizedString(@"Cancel", nil), nil) == NSOKButton)
	{
		[self restoreDefaultPreambleLogic];
	}
}

- (IBAction)openTempDir:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:NSTemporaryDirectory() withApplication:@"Finder.app"];
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
	NSSavePanel* aPanel = [NSSavePanel savePanel];
	if([aPanel runModal] == NSFileHandlingPanelOKButton)
	{
		[outputFileTextField setStringValue:[aPanel filename]];
	}
}

- (IBAction)toggleMenuItem:(id)sender
{
	[sender setState:![sender state]];
	
	BOOL colorize = [[self currentProfile] boolForKey:@"colorizeText"];
	[sourceTextView colorizeText:colorize];
	[preambleTextView colorizeText:colorize];
}

- (IBAction)toggleOutputDrawer:(id)sender 
{
	if([outputDrawer state] == NSDrawerOpenState)
	{
		[outputDrawerMenuItem setState:NO];
		[outputDrawer close];
	}
	else
	{
		[self showOutputDrawer];
	}
    
}

- (IBAction)togglePreambleWindow:(id)sender
{
	if([preambleWindow isVisible])
	{
		[preambleWindow close];
	}
	else
	{
		[preambleWindowMenuItem setState:YES];

		NSRect mainWindowRect = [mainWindow frame];
		NSRect preambleWindowRect = [preambleWindow frame];
		[preambleWindow setFrame:NSMakeRect(NSMinX(mainWindowRect) - NSWidth(preambleWindowRect), 
											NSMinY(mainWindowRect) + NSHeight(mainWindowRect) - NSHeight(preambleWindowRect), 
											NSWidth(preambleWindowRect), NSHeight(preambleWindowRect))
						 display:NO];
		[preambleWindow makeKeyAndOrderFront:nil];
	}
    
}

- (IBAction)closeWindow:(id)sender
{
	[[NSApp keyWindow] close];
}

- (IBAction)showFontPanelOfSource:(id)sender
{
	NSFontPanel* panel = [NSFontPanel sharedFontPanel];
	[panel makeKeyAndOrderFront:self];
	[panel setPanelFont:[sourceTextView font] isMultiple:NO];
}

- (IBAction)showFontPanelOfPreamble:(id)sender
{
	NSFontPanel* panel = [NSFontPanel sharedFontPanel];
	[panel makeKeyAndOrderFront:self];
	[panel setPanelFont:[preambleTextView font] isMultiple:NO];
	
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
	
	platexPath = ([upTeXRadioButton state] == NSOnState) ? [self searchProgram:@"uplatex"] : [self searchProgram:@"platex"];
	if(!platexPath)
	{
		platexPath = @"";
		[self showNotFoundError:@"platex"];
	}
	if(!(dvipdfmxPath = [self searchProgram:@"dvipdfmx"]))
	{
		dvipdfmxPath = @"";
		[self showNotFoundError:@"dvipdfmx"];
	}
	if(!(gsPath = [self searchProgram:@"gs"]))
	{
		gsPath = @"";
		[self showNotFoundError:@"ghostscript"];
	}
	
	[platexPathTextField setStringValue:platexPath];
	[dvipdfmxPathTextField setStringValue:dvipdfmxPath];
	[gsPathTextField setStringValue:gsPath];
}


- (void)doGeneratingThread
{
	NSAutoreleasePool* pool;
	BOOL threading = ([threadingCheckBox state] == NSOnState);
    if(threading) pool = [[NSAutoreleasePool alloc]init];

	NSMutableDictionary *aProfile = [self currentProfile];
	[aProfile setObject:[[NSBundle mainBundle] pathForResource:@"pdfcrop" ofType:nil] forKey:@"pdfcropPath"];
	[aProfile setObject:[[NSBundle mainBundle] pathForResource:@"epstopdf" ofType:nil] forKey:@"epstopdfPath"];
	[aProfile setBool:NO forKey:@"quiet"];
	[aProfile setObject:self forKey:@"controller"];
	
	Converter* converter = [Converter converterWithProfile:aProfile];

	NSString* texBodyStr = [[sourceTextView textStorage] string];
	
	[converter compileAndConvertWithBody:texBodyStr];

	[generateButton setEnabled:YES];
	[generateMenuItem setEnabled:YES];

	if(threading)
	{
		[outputTextView display]; // 再描画
		[pool release];
		[NSThread exit]; 
	}
}

- (IBAction)generate:(id)sender
{
	if([showOutputDrawerCheckBox state]) [self showOutputDrawer];
	[generateButton setEnabled:NO];
	[generateMenuItem setEnabled:NO];
	if ([threadingCheckBox state])
	{
		[NSThread detachNewThreadSelector:@selector(doGeneratingThread) toTarget:self withObject:nil];
	}
	else
	{
		[self doGeneratingThread];
	}

	
}

@end
