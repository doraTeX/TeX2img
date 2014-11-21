#import "Controller.h"

@implementation Controller
////// ここから OutputController プロトコルの実装 //////
- (void)showMainWindow
{
	[mainWindow makeKeyAndOrderFront:nil];
}

- (void)appendOutputAndScroll:(NSMutableString*)mStr
{
	[[[outputTextView textStorage] mutableString] appendString:mStr];
	[outputTextView scrollRangeToVisible: NSMakeRange([[outputTextView string] length], 0)]; // 最下部までスクロール
}

- (void)clearOutputTextView
{
	[[[outputTextView textStorage] mutableString] setString:@""];
}

- (void)showOutputWindow
{
	[outputWindowMenuItem setState:YES];
	
	if(![outputWindow isVisible])
	{
		NSRect mainWindowRect = [mainWindow frame];
		NSRect outputWindowRect = [outputWindow frame];
		[outputWindow setFrame:NSMakeRect(mainWindowRect.origin.x + mainWindowRect.size.width, 
										  mainWindowRect.origin.y + mainWindowRect.size.height - outputWindowRect.size.height, 
										  outputWindowRect.size.width, outputWindowRect.size.height)
					   display:NO];
	}
	[outputWindow makeKeyAndOrderFront:nil];
}

- (void)showExtensionError
{
	NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"extensionErrMsg", nil), @"OK", nil, nil);	
}

- (void)showNotFoundError:(NSString*)aPath
{
	NSRunAlertPanel(NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"%@%@", aPath, NSLocalizedString(@"programNotFoundErrorMsg", nil)], @"OK", nil, nil);
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


- (void)restoreDefaultPreambleLogic
{
	[[[preambleTextView textStorage] mutableString] setString:@"\\documentclass[fleqn]{jsarticle}\n\\usepackage{amsmath,amssymb}\n\\pagestyle{empty}\n"];
}

- (IBAction)openTempDir:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:NSTemporaryDirectory() withApplication:@"Finder.app"];
}

- (IBAction)showPreferenceWindow:(id)sender
{
	[preferenceWindow makeKeyAndOrderFront:nil];
}

- (IBAction)showSavePanel:(id)sender
{
	NSSavePanel* aPanel = [NSSavePanel savePanel];
	if([aPanel runModal] == NSFileHandlingPanelOKButton)
	{
		[outputFileTextField setStringValue:[aPanel filename]];
	}
}

- (void)loadSettingForTextField:(NSTextField*)textField fromKey:(NSString*)key
{
	NSString* tempStr = [[NSUserDefaults standardUserDefaults] stringForKey:key];
	
	if(tempStr != nil)
	{
		[textField setStringValue:tempStr];	
	}
}

- (void)loadSettingForTextView:(NSTextView*)textView fromKey:(NSString*)key
{
	NSString* tempStr = [[NSUserDefaults standardUserDefaults] stringForKey:key];
	
	if(tempStr != nil)
	{
		[[[textView textStorage] mutableString] setString:tempStr];
	}
}

- (NSString*)searchProgram:(NSString*)programName
{
	NSArray *searchPaths = [NSArray arrayWithObjects:
							@"/usr/local/bin", @"/opt/local/bin", @"/sw/bin", nil];
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

	// アウトプットウィンドウが閉じられるときにメニューのチェックを外す
	[aCenter addObserver: self
				selector: @selector(uncheckOutputWindowMenuItem:)
					name: @"NSWindowWillCloseNotification"
				  object: outputWindow];

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
	
	
	// デフォルトのアウトプットファイルのパスをセット
	[outputFileTextField setStringValue:[NSString stringWithFormat:@"%@/Desktop/equation.eps", NSHomeDirectory()]];

	// 保存された設定を読み込む
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSString* plistFile = [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", NSHomeDirectory(), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]];

	if([fileManager fileExistsAtPath:plistFile])
	{
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

		float x, y, mainWindowWidth, mainWindowHeight; 
		x = [userDefaults floatForKey:@"x"];
		y = [userDefaults floatForKey:@"y"];
		mainWindowWidth = [userDefaults floatForKey:@"mainWindowWidth"];
		mainWindowHeight = [userDefaults floatForKey:@"mainWindowHeight"];
		
		if(x!=0 && y!=0 && mainWindowWidth!=0 && mainWindowHeight!=0)
		{
			[mainWindow setFrame:NSMakeRect(x, y, mainWindowWidth, mainWindowHeight) display:YES];
		}
		
		[self loadSettingForTextField:outputFileTextField fromKey:@"outputFile"];
		
		[showOutputWindowCheckBox setState:[userDefaults integerForKey:@"showOutputWindow"]];
		[previewCheckBox setState:[userDefaults integerForKey:@"preview"]];
		[deleteTmpFileCheckBox setState:[userDefaults integerForKey:@"deleteTmpFile"]];
		
		[transparentCheckBox setState:[userDefaults boolForKey:@"transparent"]];
		
		[self loadSettingForTextField:platexPathTextField fromKey:@"platexPath"];
		[self loadSettingForTextField:dvipdfmxPathTextField fromKey:@"dvipdfmxPath"];
		[self loadSettingForTextField:gsPathTextField fromKey:@"gsPath"];
		
		[self loadSettingForTextField:resolutionLabel fromKey:@"resolutionLabel"];
		[self loadSettingForTextField:leftMarginLabel fromKey:@"leftMarginLabel"];
		[self loadSettingForTextField:rightMarginLabel fromKey:@"rightMarginLabel"];
		[self loadSettingForTextField:topMarginLabel fromKey:@"topMarginLabel"];
		[self loadSettingForTextField:bottomMarginLabel fromKey:@"bottomMarginLabel"];
		
		[resolutionSlider setIntValue:[userDefaults integerForKey:@"resolution"]];
		[leftMarginSlider setIntValue:[userDefaults integerForKey:@"leftMargin"]];
		[rightMarginSlider setIntValue:[userDefaults integerForKey:@"rightMargin"]];
		[topMarginSlider setIntValue:[userDefaults integerForKey:@"topMargin"]];
		[bottomMarginSlider setIntValue:[userDefaults integerForKey:@"bottomMargin"]];

		[self loadSettingForTextView:preambleTextView fromKey:@"preamble"];
	}
	else // 初回起動時の各種プログラムのパスの自動設定
	{
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
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setFloat:([mainWindow frame]).origin.x forKey:@"x"];
	[userDefaults setFloat:([mainWindow frame]).origin.y forKey:@"y"];
	[userDefaults setFloat:([mainWindow frame]).size.width forKey:@"mainWindowWidth"];
	[userDefaults setFloat:([mainWindow frame]).size.height forKey:@"mainWindowHeight"];
	[userDefaults setObject:[outputFileTextField stringValue] forKey:@"outputFile"];

	[userDefaults setInteger:[showOutputWindowCheckBox state] forKey:@"showOutputWindow"];
	[userDefaults setInteger:[previewCheckBox state] forKey:@"preview"];
	[userDefaults setInteger:[deleteTmpFileCheckBox state] forKey:@"deleteTmpFile"];

	[userDefaults setBool:[transparentCheckBox state] forKey:@"transparent"];
	[userDefaults setObject:[platexPathTextField stringValue] forKey:@"platexPath"];
	[userDefaults setObject:[dvipdfmxPathTextField stringValue] forKey:@"dvipdfmxPath"];
	[userDefaults setObject:[gsPathTextField stringValue] forKey:@"gsPath"];

	[userDefaults setObject:[resolutionLabel stringValue] forKey:@"resolutionLabel"];
	[userDefaults setObject:[leftMarginLabel stringValue] forKey:@"leftMarginLabel"];
	[userDefaults setObject:[rightMarginLabel stringValue] forKey:@"rightMarginLabel"];
	[userDefaults setObject:[topMarginLabel stringValue] forKey:@"topMarginLabel"];
	[userDefaults setObject:[bottomMarginLabel stringValue] forKey:@"bottomMarginLabel"];

	[userDefaults setInteger:[resolutionSlider intValue] forKey:@"resolution"];
	[userDefaults setInteger:[leftMarginSlider intValue] forKey:@"leftMargin"];
	[userDefaults setInteger:[rightMarginSlider intValue] forKey:@"rightMargin"];
	[userDefaults setInteger:[topMarginSlider intValue] forKey:@"topMargin"];
	[userDefaults setInteger:[bottomMarginSlider intValue] forKey:@"bottomMargin"];
	
	[userDefaults setObject:[[preambleTextView textStorage] string] forKey:@"preamble"];

	[userDefaults synchronize];
}


- (void)uncheckOutputWindowMenuItem:(NSNotification *)aNotification
{
	[outputWindowMenuItem setState:NO];
}

- (void)uncheckPreambleWindowMenuItem:(NSNotification *)aNotification
{
	[preambleWindowMenuItem setState:NO];
}

- (void)closeOtherWindows:(NSNotification *)aNotification
{
	[preambleWindow close];
	[preferenceWindow close];
	[outputWindow close];
}

- (IBAction)showMainWindow:(id)sender
{
	[self showMainWindow];
}

- (IBAction)toggleMenuItem:(id)sender
{
	[sender setState:![sender state]];
}

- (IBAction)toggleOutputWindow:(id)sender 
{
	if([outputWindow isVisible])
	{
		[outputWindow close];
	}
	else
	{
		[self showOutputWindow];
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
		[preambleWindow setFrame:NSMakeRect(mainWindowRect.origin.x - preambleWindowRect.size.width, 
											mainWindowRect.origin.y + mainWindowRect.size.height - preambleWindowRect.size.height, 
											preambleWindowRect.size.width, preambleWindowRect.size.height)
						 display:NO];
		[preambleWindow makeKeyAndOrderFront:nil];
	}
    
}

- (IBAction)closeWindow:(id)sender
{
	[[NSApp keyWindow] close];
}

- (IBAction)restoreDefaultPreamble:(id)sender
{
	if(NSRunAlertPanel(NSLocalizedString(@"Confirm", nil), NSLocalizedString(@"resotreDefaultPreambleMsg", nil), @"OK", NSLocalizedString(@"Cancel", nil), nil) == NSOKButton)
	{
		[self restoreDefaultPreambleLogic];
	}
}

- (IBAction)generate:(id)sender
{
	// まずは設定値の取得
    NSString *platexPath = [platexPathTextField stringValue];
    NSString *dvipdfmxPath = [dvipdfmxPathTextField stringValue];
    NSString *gsPath = [gsPathTextField stringValue];
	
	int resolutionLevel = [resolutionSlider intValue];
	int leftMargin = [leftMarginSlider intValue];
	int rightMargin = [rightMarginSlider intValue];
	int topMargin = [topMarginSlider intValue];
	int bottomMargin = [bottomMarginSlider intValue];
	bool leaveTextFlag = [leaveTextCheckBox state];
	bool transparentPngFlag = [transparentCheckBox state];
	
	bool showOutputWindowFlag = [showOutputWindowCheckBox state];
	bool previewFlag = [previewCheckBox state];
	bool deleteTmpFileFlag = [deleteTmpFileCheckBox state];
	
	NSString *outputFilePath = [outputFileTextField stringValue];
	
	NSString* preambleStr = [[preambleTextView textStorage] string];
	NSString* texBodyStr = [[sourceTextView textStorage] string];

	Converter* converter = [Converter converterWithPlatex:platexPath dvipdfmx:dvipdfmxPath gs:gsPath 
			resolutionLevel:resolutionLevel leftMargin:leftMargin rightMargin:rightMargin topMargin:topMargin bottomMargin:bottomMargin
					  leaveText:leaveTextFlag transparentPng:transparentPngFlag showOutputWindow:showOutputWindowFlag preview:previewFlag deleteTmpFile:deleteTmpFileFlag
				   controller:self];
	[converter compileAndConvertWithPreamble:preambleStr withBody:texBodyStr outputFilePath:outputFilePath];
}


@end
