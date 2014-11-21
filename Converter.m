#import <stdio.h>
#import <unistd.h>
#import <Quartz/Quartz.h>
//#import <OgreKit/OgreKit.h>
#include <regex.h>

#define MAX_LEN 1024

#import "NSDictionary-Extension.h"
#import "NSMutableString-Extension.h"
#import "Converter.h"

@implementation Converter
- (Converter*)initWithProfile:(NSDictionary*)aProfile
{
	platexPath = [aProfile stringForKey:@"platexPath"];
	dvipdfmxPath = [aProfile stringForKey:@"dvipdfmxPath"];
	gsPath = [aProfile stringForKey:@"gsPath"];
	pdfcropPath = [aProfile stringForKey:@"pdfcropPath"];
	epstopdfPath = [aProfile stringForKey:@"epstopdfPath"];
	
	outputFilePath = [aProfile stringForKey:@"outputFile"];
	preambleStr = [aProfile stringForKey:@"preamble"];
	
	encoding = [aProfile stringForKey:@"encoding"];
	resolutionLevel = [aProfile floatForKey:@"resolution"] / 5.0;
	leftMargin = [aProfile integerForKey:@"leftMargin"];
	rightMargin = [aProfile integerForKey:@"rightMargin"];
	topMargin = [aProfile integerForKey:@"topMargin"];
	bottomMargin = [aProfile integerForKey:@"bottomMargin"];
	leaveTextFlag = ![aProfile boolForKey:@"getOutline"];
	transparentPngFlag = [aProfile boolForKey:@"transparent"];
	showOutputDrawerFlag = [aProfile boolForKey:@"showOutputDrawer"];
	previewFlag = [aProfile boolForKey:@"preview"];
	deleteTmpFileFlag = [aProfile boolForKey:@"deleteTmpFile"];
	ignoreErrorsFlag = [aProfile boolForKey:@"ignoreError"];
	utfExportFlag = [aProfile boolForKey:@"utfExport"];
	quietFlag = [aProfile boolForKey:@"quiet"];
	controller = [aProfile objectForKey:@"controller"];

	fileManager = [NSFileManager defaultManager];
	tempdir = NSTemporaryDirectory();
	pid = (int)getpid();
	tempFileBaseName = [NSString stringWithFormat:@"temp%d", pid]; 
	
	return self;
}

+ (Converter*)converterWithProfile:(NSDictionary*)aProfile
{
	Converter* converter = [Converter alloc];
	[converter initWithProfile:aProfile];
	return [converter autorelease];
}


// JIS 外の文字を \UTF に置き換える
- (NSMutableString *)substituteUTF:(NSString*)dataString
{
	NSMutableString *utfString, *newString = [NSMutableString string];
	int g_texChar = 0x5c;
	NSRange charRange;
	NSString *subString;
	unsigned startl, endl, end;
	
	charRange = NSMakeRange(0,1);
	endl = 0;
	while (charRange.location < [dataString length])
	{
		if (charRange.location == endl)
		{
			[dataString getLineStart:&startl end:&endl contentsEnd:&end forRange:charRange];
		}
		charRange = [dataString rangeOfComposedCharacterSequenceAtIndex: charRange.location];
		subString = [dataString substringWithRange: charRange];
		
		if (![subString canBeConvertedToEncoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP)])
		{
			if ( [subString characterAtIndex: 0] == 0x2015)
			{
				utfString = [NSMutableString stringWithFormat:@"%C", 0x2014];
			}
			else
			{
				utfString = [NSMutableString stringWithFormat:@"%CUTF{%04X}",
							 g_texChar, [subString characterAtIndex: 0]];
			}
			if ((charRange.location + charRange.length) == end)
			{
				[utfString appendString: @"%"];
			}
			[newString appendString: utfString];
		}
		else
		{
			[newString appendString: subString];
		}
		charRange.location += charRange.length;
		charRange.length = 1;
	}
	
	return newString;
}


// 文字列の円マーク・バックスラッシュを全てバックスラッシュに統一してファイルに書き込む。
// 返り値：書き込みの正否(BOOL)
- (BOOL)writeStringWithYenBackslashConverting:(NSString*)targetString toFile:(NSString*)path
{
	NSMutableString* mstr = [[[NSMutableString alloc] initWithCapacity:0] autorelease];
	[mstr appendString:targetString];
	
	[mstr replaceYenWithBackSlash];
		
	if(utfExportFlag) mstr = [self substituteUTF:mstr];
	
	UInt32 enc;
	if([encoding isEqualToString:@"sjis"])
	{
		enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese);
	}
	else if([encoding isEqualToString:@"euc"])
	{
		enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_JP);
	}
	else if([encoding isEqualToString:@"jis"])
	{
		enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP);
	}
	else // utf8 or uptex
	{
		enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8);
	}
	
	return [mstr writeToFile:path atomically:NO encoding:enc error:NULL];
	
	// バックスラッシュ（0x5C）を円マーク (0xC20xA5) に置換
	//NSString* yenMark = NSLocalizedString(@"YenMark", @"");
	//NSString* backslash = NSLocalizedString(@"Backslash", @"");
	//[mstr replaceOccurrencesOfString:backslash withString:yenMark options:0 range:NSMakeRange(0, [mstr length])];
	
	//// CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS) で保存すると，円マークは0x5cに，バックスラッシュは全角になって保存される。
	//return [mstr writeToFile:path atomically:NO encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS) error:NULL];

}


/*
 - (int)execCommand:(NSString*)command atDirectory:(NSString*)path withArguments:(NSArray*)arguments withStdout:(NSMutableString*)stdoutMStr withStdErr:(NSMutableString*)stderrMStr
 {
 NSTask* task = [[[NSTask alloc] init] autorelease];
 [task setCurrentDirectoryPath:path];
 [task setLaunchPath:command];
 [task setArguments:arguments];
 
 NSPipe* pipeStdout = [NSPipe pipe];
 NSPipe* pipeStdErr = [NSPipe pipe];
 [task setStandardOutput:pipeStdout];
 [task setStandardError:pipeStdErr];
 
 [task launch];
 [task waitUntilExit];
 
 char* stdoutChars = [[[pipeStdout fileHandleForReading] availableData] bytes];
 char* stderrChars = [[[pipeStdErr fileHandleForReading] availableData] bytes];
 
 if(stdoutMStr != nil && stdoutChars != nil)
 {
 [stdoutMStr appendString:[NSString stringWithUTF8String:stdoutChars]];
 }
 if(stderrMStr != nil && stderrChars != nil)
 {
 [stderrMStr appendString:[NSString stringWithUTF8String:stderrChars]];
 }
 
 return [task terminationStatus];
 }
*/

- (BOOL)execCommand:(NSString*)command atDirectory:(NSString*)path withArguments:(NSArray*)arguments
{
	char str[MAX_LEN];
	FILE *fp;
	
	chdir([path UTF8String]);
	
	NSMutableString *cmdline = [NSMutableString stringWithCapacity:0];
	[cmdline appendString:command];
	[cmdline appendString:@" "];
	
	NSEnumerator *enumerator = [arguments objectEnumerator];
	NSString *argument;
	while(argument = [enumerator nextObject])
	{
		[cmdline appendString:argument];
		[cmdline appendString:@" "];
	}
	[cmdline appendString:@" 2>&1"];
	[controller appendOutputAndScroll:[NSString stringWithFormat:@"$ %@\n", cmdline] quiet:quietFlag];

	if((fp=popen([cmdline UTF8String],"r"))==NULL)
	{
		return NO;
	}
	while(YES)
	{
		if(fgets(str, MAX_LEN-1, fp) == NULL)
		{
			break;
		}
		[controller appendOutputAndScroll:[NSMutableString stringWithUTF8String:str] quiet:quietFlag];
	}
	int status = pclose(fp);
	return (ignoreErrorsFlag || status==0) ? YES : NO;
	
}

- (int)tex2dvi:(NSString*)teXFilePath
{
	int status = [self execCommand:platexPath atDirectory:tempdir withArguments:[NSArray arrayWithObjects:@"-interaction=nonstopmode", [NSString stringWithFormat:@"-kanji=%@", encoding], teXFilePath, nil]];
	[controller appendOutputAndScroll:@"\n" quiet:quietFlag];
	
	return status;
}

- (int)dvi2pdf:(NSString*)dviFilePath
{
	int status = [self execCommand:dvipdfmxPath atDirectory:tempdir withArguments:[NSArray arrayWithObjects:@"-vv", dviFilePath, nil]];
	[controller appendOutputAndScroll:@"\n" quiet:quietFlag];	
	
	return status;
}

- (int)pdfcrop:(NSString*)pdfPath outputFileName:(NSString*)outputFileName addMargin:(BOOL)addMargin
{
	if(![controller checkPdfcropExistence])
	{
		return NO;
	}
	
	int status = [self execCommand:[NSString stringWithFormat:@"export PATH=$PATH:%@;%@", [gsPath stringByDeletingLastPathComponent], pdfcropPath] atDirectory:tempdir
					 withArguments:[NSArray arrayWithObjects:
									addMargin ? [NSString stringWithFormat:@"--margins \"%d %d %d %d\"", leftMargin, topMargin, rightMargin, bottomMargin] : @"",
									[pdfPath lastPathComponent],
									outputFileName,
									nil]];
	return (status==0) ? YES : NO;
}

- (int)pdf2eps:(NSString*)pdfName outputEpsFileName:(NSString*)outputEpsFileName resolution:(int)resolution;
{
	int status = [self execCommand:gsPath atDirectory:tempdir 
					 withArguments:[NSArray arrayWithObjects:
									@"-sDEVICE=epswrite",
									@"-dNOPAUSE",
									@"-dBATCH",
									[NSString stringWithFormat:@"-r%d", resolution],
									[NSString stringWithFormat:@"-sOutputFile=%@", outputEpsFileName],
									[NSString stringWithFormat:@"%@.pdf", tempFileBaseName],
									nil]];
	return status;
}

- (BOOL)epstopdf:(NSString*)epsName outputPdfFileName:(NSString*)outputPdfFileName
{
	if(![controller checkEpstopdfExistence])
	{
		return NO;
	}
	
	[self execCommand:[NSString stringWithFormat:@"export PATH=%@;/usr/bin/perl %@", [gsPath stringByDeletingLastPathComponent], epstopdfPath] atDirectory:tempdir 
					 withArguments:[NSArray arrayWithObjects:
									[NSString stringWithFormat:@"--outfile=%@", outputPdfFileName],
									epsName,
									nil]];
	return YES;
}

- (BOOL)eps2pdf:(NSString*)epsName outputFileName:(NSString*)outputFileName
{
	// まず，epstopdf を使って PDF に戻し，次に，pdfcrop を使って余白を付け加える
	NSString* trimFileName = [NSString stringWithFormat:@"%@.trim.pdf", epsName];
	if([self epstopdf:epsName outputPdfFileName:trimFileName] && [self pdfcrop:trimFileName outputFileName:outputFileName addMargin:YES])
	{
		return YES;
	}
	return NO;
}

// NSBitmapImageRep の背景を白く塗りつぶす
- (NSBitmapImageRep*)fillBackground:(NSBitmapImageRep*)bitmapRep
{
	NSImage *srcImage = [[[NSImage alloc] init] autorelease];
	[srcImage addRepresentation:bitmapRep];
	NSSize size = [srcImage size];
	
	NSImage *backgroundImage = [[[NSImage alloc] initWithSize:size] autorelease];
	[backgroundImage lockFocus];
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:NSMakeRect(0, 0, size.width, size.height)];
	[srcImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
	[backgroundImage unlockFocus];
	return [[[NSBitmapImageRep alloc] initWithData:[backgroundImage TIFFRepresentation]] autorelease];
}

- (void)pdf2image:(NSString*)pdfFilePath outputFileName:(NSString*)outputFileName
{
	NSString* extension = [[outputFileName pathExtension] lowercaseString];

	// PDFのバウンディングボックスで切り取る
	[self pdfcrop:pdfFilePath outputFileName:pdfFilePath addMargin:NO];
	
	// PDFの先頭ページを読み取り，NSPDFImageRep オブジェクトを作成
	NSData* pageData = [[[[[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:pdfFilePath]] autorelease] pageAtIndex:0] dataRepresentation];
	NSPDFImageRep *pdfImageRep = [[[NSPDFImageRep alloc] initWithData:pageData] autorelease];

	// 新しい NSImage オブジェクトを作成し，その中に NSPDFImageRep オブジェクトの中身を描画
	NSSize size;
	size.width  = (int)([pdfImageRep pixelsWide] * resolutionLevel) + leftMargin + rightMargin;
	size.height = (int)([pdfImageRep pixelsHigh] * resolutionLevel) + topMargin + bottomMargin;
	
	NSImage* image = [[[NSImage alloc] initWithSize:size] autorelease];
	[image lockFocus];
	[pdfImageRep drawInRect:NSMakeRect(leftMargin, bottomMargin, (int)([pdfImageRep pixelsWide] * resolutionLevel), (int)([pdfImageRep pixelsHigh] * resolutionLevel))];
	[image unlockFocus];
	
	// NSImage を TIFF 形式の NSBitmapImageRep に変換する
	NSBitmapImageRep *imageRep = [[[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]] autorelease];
	
	NSData *outputData;
	if([@"jpg" isEqualToString:extension])
	{
		NSDictionary *propJpeg = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithFloat: 1.0],
								  NSImageCompressionFactor,
								  nil];
		imageRep = [self fillBackground:imageRep];
		outputData = [imageRep representationUsingType:NSJPEGFileType properties:propJpeg];
	}
	else // png出力の場合
	{
		if(!transparentPngFlag)
		{
			imageRep = [self fillBackground:imageRep];
		}
		NSDictionary *propPng = [NSDictionary dictionaryWithObjectsAndKeys:nil];
		outputData = [imageRep representationUsingType:NSPNGFileType properties:propPng];
	}
	[outputData writeToFile:[tempdir stringByAppendingPathComponent:outputFileName] atomically: YES];

}

- (void)enlargeBB:(NSString*)epsName
{
	regex_t regexBB, regexHiResBB;
	size_t nmatch = 5;
	regmatch_t pmatch[nmatch];
	
	regcomp(&regexBB, "^\\%\\%BoundingBox\\: ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)$", REG_EXTENDED|REG_NEWLINE);
	regcomp(&regexHiResBB, "^\\%\\%HiResBoundingBox\\: ([0-9\\.]+) ([0-9\\.]+) ([0-9\\.]+) ([0-9\\.]+)$", REG_EXTENDED|REG_NEWLINE);

	int leftbottom_x = 0;
	int leftbottom_y = 0;
	int righttop_x = 0;
	int righttop_y = 0;

	char str[MAX_LEN];
	NSMutableArray* lines = [NSMutableArray arrayWithArray:0];

	FILE *fp;
	NSString* epsFilePath = [tempdir stringByAppendingPathComponent:epsName];

	fp = fopen([epsFilePath UTF8String], "r");
	while ((fgets(str, MAX_LEN - 1, fp)) != NULL)
	{
		NSString* line = [NSString stringWithUTF8String:str];
		if(regexec(&regexBB, str, nmatch, pmatch, 0) == 0)
		{
			leftbottom_x  = [[line substringWithRange:NSMakeRange(pmatch[1].rm_so, pmatch[1].rm_eo - pmatch[1].rm_so)] intValue] - leftMargin;
			leftbottom_y  = [[line substringWithRange:NSMakeRange(pmatch[2].rm_so, pmatch[2].rm_eo - pmatch[2].rm_so)] intValue] - bottomMargin;
			righttop_x    = [[line substringWithRange:NSMakeRange(pmatch[3].rm_so, pmatch[3].rm_eo - pmatch[3].rm_so)] intValue]  + rightMargin;
			righttop_y    = [[line substringWithRange:NSMakeRange(pmatch[4].rm_so, pmatch[4].rm_eo - pmatch[4].rm_so)] intValue] + topMargin;
			[lines addObject:[NSString stringWithFormat:@"%%%%BoundingBox: %d %d %d %d\n", leftbottom_x, leftbottom_y, righttop_x, righttop_y]];
			continue;
		}
		
		if(regexec(&regexHiResBB, str, nmatch, pmatch, 0) == 0)
		{
			continue;
		}
		
		[lines addObject:line];
	}
	fclose(fp);
	
	fp = fopen([epsFilePath UTF8String], "w");
	
	NSEnumerator* enumerator = [lines objectEnumerator];
	NSString* line;
	while(line = [enumerator nextObject])
	{
		fputs([line UTF8String], fp);
	}
	fclose(fp);
	
	regfree(&regexBB);
	regfree(&regexHiResBB);	
}

/*
- (int)eps2image:(NSString*)epsName outputFileName:(NSString*)outputFileName resolution:(int)resolution
{
	NSString* trimFileName = [NSString stringWithFormat:@"%@.trim.eps", epsName];
	NSString* extension = [[outputFileName pathExtension] lowercaseString];

	// まずはEPSファイルのバウンディングボックスを取得
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"^\\%\\%BoundingBox\\: (\\d+) (\\d+) (\\d+) (\\d+)$"]; // バウンディングボックス情報の正規表現
	OGRegularExpressionMatch *match;
	NSEnumerator *matchEnum;
	
	int leftbottom_x  = 0;
	int leftbottom_y  = 0;
	int righttop_x  = 0;
	int righttop_y  = 0;
	
	char line[MAX_LEN];
	FILE *fp;
	fp = fopen([[tempdir stringByAppendingPathComponent:epsName] UTF8String], "r");
	
	while ((fgets(line, MAX_LEN - 1, fp)) != NULL) {
		matchEnum = [regex matchEnumeratorInString:[NSString stringWithUTF8String:line]]; // 正規表現マッチを実行
		if((match = [matchEnum nextObject]) != nil)
		{
			leftbottom_x  = [[match substringAtIndex:1] intValue] - leftMargin / resolutionLevel;
			leftbottom_y  = [[match substringAtIndex:2] intValue] - bottomMargin / resolutionLevel;
			righttop_x  = [[match substringAtIndex:3] intValue] + rightMargin / resolutionLevel;
			righttop_y  = [[match substringAtIndex:4] intValue] + topMargin / resolutionLevel;
			break;
		}
	}
	fclose(fp);
	
	
	// 次にトリミングするためのEPSファイルを作成
	fp = fopen([[tempdir stringByAppendingPathComponent:trimFileName] UTF8String], "w");
	fputs("/NumbDict countdictstack def\n", fp);
	fputs("1 dict begin\n", fp);
	fputs("/showpage {} def\n", fp);
	fputs("userdict begin\n", fp);
	fputs([[NSString stringWithFormat:@"%d.000000 %d.000000 translate\n", -leftbottom_x, -leftbottom_y] UTF8String], fp);
	fputs("1.000000 1.000000 scale\n", fp);
	fputs("0.000000 0.000000 translate\n", fp);
	fputs([[NSString stringWithFormat:@"(%@) run\n", epsName] UTF8String], fp);
	fputs("countdictstack NumbDict sub {end} repeat\n", fp);
	fputs("showpage\n", fp);
	fclose(fp);
	
	// 最後に目的の形式に変換
	NSString *device = @"jpeg";
	if([@"png" isEqualToString:extension])
	{
		device = transparentPngFlag ? @"pngalpha" : @"png256";
	}
	
	int status = [self execCommand:gsPath atDirectory:tempdir withArguments:
				  [NSArray arrayWithObjects:
				   @"-q",
				   [NSString stringWithFormat:@"-sDEVICE=%@", device],
				   [NSString stringWithFormat:@"-sOutputFile=%@", outputFileName],
				   @"-dNOPAUSE",
				   @"-dBATCH",
				   @"-dPDFFitPage",
				   [NSString stringWithFormat:@"-r%d", resolution],
				   [NSString stringWithFormat:@"-g%dx%d", (righttop_x - leftbottom_x) * resolutionLevel, (righttop_y - leftbottom_y) * resolutionLevel],
				   trimFileName,
				   nil]
						withStdout:nil];
	
	return status;
}
*/

- (BOOL)compileAndConvert
{
	NSString* teXFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* dviFilePath = [NSString stringWithFormat:@"%@.dvi", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* pdfFilePath = [NSString stringWithFormat:@"%@.pdf", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* outputEpsFileName = [NSString stringWithFormat:@"%@.eps", tempFileBaseName];
	NSString* outputFileName = [outputFilePath lastPathComponent];
	NSString* extension = [[outputFilePath pathExtension] lowercaseString];
	
	// TeX→DVI
	if(![self tex2dvi:teXFilePath])
	{
		[controller showCompileError];
		return NO;
	}
	
	if(![fileManager fileExistsAtPath:dviFilePath])
	{
		[controller showExecError:@"platex"];
		return NO;
	}
	
	// DVI→PDF
	if(![self dvi2pdf:dviFilePath] || ![fileManager fileExistsAtPath:pdfFilePath])
	{
		[controller showExecError:@"dvipdfmx"];
		return NO;
	}
	
	if(([@"jpg" isEqualToString:extension] || [@"png" isEqualToString:extension]) && leaveTextFlag) // 文字化け対策を行わない jpg/png の場合，PDFから直接変換
	{
		[self pdf2image:pdfFilePath outputFileName:outputFileName];
	}
	else if([@"pdf" isEqualToString:extension] && leaveTextFlag) // 最終出力が文字埋め込み PDF の場合，EPSを経由しなくてよいので，pdfcrop で直接生成する。
	{
		[self pdfcrop:pdfFilePath outputFileName:outputFileName addMargin:YES];
	}
	else // EPS を経由する形式(.eps/アウトラインを取ったpdf / 文字化け対策 jpg,png )の場合
	{
		/*
		// PDF→EPS の変換の準備
		int resolution;
		 
		if([@"jpg" isEqualToString:extension] || [@"png" isEqualToString:extension])
		{
			resolution = 72 * resolutionLevel;
			outputEpsFileName = [NSString stringWithFormat:@"%@.eps", tempFileBaseName];
			
		}
		else // .eps/.pdf 出力の場合
		{ 
			resolution = 20016;
			outputEpsFileName = outputFileName;
		}
		*/

		int resolution = 20016;
		
		// PDF→EPS の変換の実行
		if(![self pdf2eps:[NSString stringWithFormat:@"%@.pdf", tempFileBaseName] outputEpsFileName:outputEpsFileName resolution:resolution] 
		   || ![fileManager fileExistsAtPath:[tempdir stringByAppendingPathComponent:outputEpsFileName]])
		{
			[controller showExecError:@"ghostscript"];
			return NO;
		}
		
		if([@"pdf" isEqualToString:extension]) // アウトラインを取ったPDFを作成する場合，EPSからPDFに戻す
		{
			[self eps2pdf:outputEpsFileName outputFileName:outputFileName];
		}
		else if([@"eps" isEqualToString:extension])  // 最終出力が EPS の場合
		{
			// 余白を付け加えるようバウンディングボックスを改変
			if(topMargin + bottomMargin + leftMargin + rightMargin > 0)
			{
				[self enlargeBB:outputEpsFileName];
			}
			//生成したEPSファイルの名前を最終出力ファイル名へ変更する
			if([fileManager fileExistsAtPath:outputFileName])
			{
				[fileManager removeFileAtPath:outputFileName handler:nil];
			}
			[fileManager movePath:[tempdir stringByAppendingPathComponent:outputEpsFileName] toPath:outputFileName handler:nil];
		}
		else if([@"jpg" isEqualToString:extension] || [@"png" isEqualToString:extension]) // 文字化け対策JPEG/PNG出力の場合，EPSをPDFに戻した上で，それをさらにJPEG/PNGに変換する
		{
			NSString* outlinedPdfFileName = [NSString stringWithFormat:@"%@.outline.pdf", tempFileBaseName];
			[self eps2pdf:outputEpsFileName outputFileName:outlinedPdfFileName]; // アウトラインを取ったEPSをPDFへ戻す
			[self pdf2image:[tempdir stringByAppendingPathComponent:outlinedPdfFileName] outputFileName:outputFileName]; // PDFを目的の画像ファイルへ変換
		}
		
		/*
		// 出力画像が JPEG または PNG の場合の EPS からの変換処理
		if([@"jpg" isEqualToString:extension] || [@"png" isEqualToString:extension])
		{
			if(![self eps2image:outputEpsFileName outputFileName:outputFileName resolution:resolution] 
			   || ![fileManager fileExistsAtPath:[tempdir stringByAppendingPathComponent:outputFileName]])
			{
				[controller showExecError:@"ghostscript"];
				return NO;
			}
		}
		*/
	}
	
	// 最終出力ファイルを目的地へコピー
	if([fileManager fileExistsAtPath:outputFilePath] && [fileManager removeFileAtPath:outputFilePath handler:nil]==NO)
	{
		[controller showCannotOverrideError:outputFilePath];
		return NO;
	}
	[fileManager copyPath:[tempdir stringByAppendingPathComponent:outputFileName] toPath:outputFilePath handler:nil];
	
	return YES;
}

- (BOOL)compileAndConvertWithCheck
{
	BOOL status = YES;
	// 最初にプログラムの存在確認と出力ファイル形式確認
	if(![controller checkPlatexPath:platexPath dvipdfmxPath:dvipdfmxPath gsPath:gsPath])
	{
		status = NO;
	}
	
	NSString* extension = [[outputFilePath pathExtension] lowercaseString];
	
	if(![@"eps" isEqualToString:extension] && ![@"png" isEqualToString:extension] && ![@"jpg" isEqualToString:extension] && ![@"pdf" isEqualToString:extension])
	{
		[controller showExtensionError];
		status = NO;
	}
	
	if(status)
	{
		// 一連のコンパイル処理の開始準備
		[controller clearOutputTextView];
		if(showOutputDrawerFlag)
		{
			[controller showOutputDrawer];
		}
		[controller showMainWindow];
		
		// 一連のコンパイル処理を実行
		status = [self compileAndConvert];
		
		// プレビュー処理
		if(status && previewFlag)
		{
			[[NSWorkspace sharedWorkspace] openFile:outputFilePath withApplication:@"Preview.app"];
		}
	}
	
	// 中間ファイルの削除
	if(deleteTmpFileFlag)
	{
		NSString* outputFileName = [outputFilePath lastPathComponent];
		NSString* basePath = [tempdir stringByAppendingPathComponent:tempFileBaseName];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.tex", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.dvi", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.log", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.aux", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.pdf", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.outline.pdf", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.eps", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.eps.trim.pdf", basePath] handler:nil];
		[fileManager removeFileAtPath:[tempdir stringByAppendingPathComponent:outputFileName] handler:nil];
	}
	
	return status;
}

- (BOOL)compileAndConvertWithSource:(NSString*)texSourceStr
{
	//TeX ソースを準備
	NSString* tempTeXFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	
	if(![self writeStringWithYenBackslashConverting:texSourceStr toFile:tempTeXFilePath])
	{
		[controller showFileGenerateError:tempTeXFilePath];
		return NO;
	}
	
	return [self compileAndConvertWithCheck];
}

- (BOOL)compileAndConvertWithBody:(NSString*)texBodyStr
{
	// TeX ソースを用意
	NSString* texSourceStr = [NSString stringWithFormat:@"%@\n\\begin{document}\n%@\n\\end{document}", preambleStr, texBodyStr];
	return [self compileAndConvertWithSource:texSourceStr];
}

- (BOOL)compileAndConvertWithInputPath:(NSString*)texSourcePath
{
	NSString* tempTeXFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	if(![fileManager copyPath:texSourcePath toPath:tempTeXFilePath handler:nil])
	{
		[controller showFileGenerateError:tempTeXFilePath];
		return NO;
	}
	
	return [self compileAndConvertWithCheck];
}


@end
