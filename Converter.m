#import <stdio.h>
#import <unistd.h>
#import <Quartz/Quartz.h>
//#import <OgreKit/OgreKit.h>
#include <regex.h>
#import "global.h"

#define MAX_LEN 1024

#import "NSDictionary-Extension.h"
#import "NSString-Extension.h"
#import "NSMutableString-Extension.h"
#import "Converter.h"

@interface Converter()
@property NSString* platexPath;
@property NSString* dvipdfmxPath;
@property NSString* gsPath;
@property NSString* encoding;
@property NSString* outputFilePath;
@property NSString* preambleStr;
@property float resolutionLevel;
@property NSInteger leftMargin, rightMargin, topMargin, bottomMargin;
@property BOOL leaveTextFlag, transparentPngFlag, showOutputDrawerFlag, previewFlag, deleteTmpFileFlag, embedInIllustratorFlag, ungroupFlag, ignoreErrorsFlag, utfExportFlag, quietFlag;
@property id<OutputController> controller;
@property NSFileManager* fileManager;
@property NSString* tempdir;
@property pid_t pid;
@property NSString* tempFileBaseName;
@property NSString* pdfcropPath;
@property NSString* epstopdfPath;
@property NSUInteger pageCount;
@property BOOL useBP;
@end

@implementation Converter
@synthesize platexPath;
@synthesize dvipdfmxPath;
@synthesize gsPath;
@synthesize encoding;
@synthesize outputFilePath;
@synthesize preambleStr;
@synthesize resolutionLevel;
@synthesize leftMargin, rightMargin, topMargin, bottomMargin;
@synthesize leaveTextFlag, transparentPngFlag, showOutputDrawerFlag, previewFlag, deleteTmpFileFlag, embedInIllustratorFlag, ungroupFlag, ignoreErrorsFlag, utfExportFlag, quietFlag;
@synthesize controller;
@synthesize fileManager;
@synthesize tempdir;
@synthesize pid;
@synthesize tempFileBaseName;
@synthesize pdfcropPath;
@synthesize epstopdfPath;
@synthesize pageCount;
@synthesize useBP;


- (Converter*)initWithProfile:(NSDictionary*)aProfile
{
    pageCount = 1;
    
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
	embedInIllustratorFlag = [aProfile boolForKey:@"embedInIllustrator"];
	ungroupFlag = [aProfile boolForKey:@"ungroup"];
	ignoreErrorsFlag = [aProfile boolForKey:@"ignoreError"];
	utfExportFlag = [aProfile boolForKey:@"utfExport"];
	quietFlag = [aProfile boolForKey:@"quiet"];
	controller = aProfile[@"controller"];
    useBP = ([aProfile integerForKey:@"unit"] == BPUNITTAG);

	fileManager = NSFileManager.defaultManager;
	tempdir = NSTemporaryDirectory();
	pid = getpid();
	tempFileBaseName = [NSString stringWithFormat:@"temp%d", pid]; 
	
	return self;
}

+ (Converter*)converterWithProfile:(NSDictionary*)aProfile
{
	return [Converter.alloc initWithProfile:aProfile];
}



// JIS 外の文字を \UTF に置き換える
- (NSMutableString*)substituteUTF:(NSString*)dataString
{
	NSMutableString *utfString, *newString = NSMutableString.string;
	NSInteger texChar = 0x5c;
	NSRange charRange;
	NSString *subString;
	NSUInteger startl, endl, end;
	
	charRange = NSMakeRange(0,1);
	endl = 0;
	while (charRange.location < dataString.length) {
		if (charRange.location == endl) {
			[dataString getLineStart:&startl end:&endl contentsEnd:&end forRange:charRange];
		}
		charRange = [dataString rangeOfComposedCharacterSequenceAtIndex: charRange.location];
		subString = [dataString substringWithRange: charRange];
		
		if (![subString canBeConvertedToEncoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP)]) {
			if ([subString characterAtIndex: 0] == 0x2015) {
				utfString = [NSMutableString stringWithFormat:@"%C", (unsigned short)0x2014];
			} else {
				utfString = [NSMutableString stringWithFormat:@"%CUTF{%04X}",
							 (unsigned short)texChar, [subString characterAtIndex: 0]];
			}
			if ((charRange.location + charRange.length) == end) {
				[utfString appendString:@"%"];
			}
			[newString appendString:utfString];
		} else {
			[newString appendString:subString];
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
    NSMutableString* mstr = NSMutableString.string;
	[mstr appendString:targetString];
	
	[mstr replaceYenWithBackSlash];
		
    if (utfExportFlag) {
        mstr = [self substituteUTF:mstr];
    }
	
	UInt32 enc;
	if ([encoding isEqualToString:@"sjis"]) {
		enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese);
	} else if ([encoding isEqualToString:@"euc"]) {
		enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_JP);
	} else if ([encoding isEqualToString:@"jis"]) {
		enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP);
    } else { // utf8 or uptex
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
 - (NSInteger)execCommand:(NSString*)command atDirectory:(NSString*)path withArguments:(NSArray*)arguments withStdout:(NSMutableString*)stdoutMStr withStdErr:(NSMutableString*)stderrMStr
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
	
	chdir(path.UTF8String);
	
	NSMutableString *cmdline = NSMutableString.string;
	[cmdline appendString:command];
	[cmdline appendString:@" "];
	
	for (NSString *argument in arguments) {
		[cmdline appendString:argument];
		[cmdline appendString:@" "];
	}
	[cmdline appendString:@" 2>&1"];
	[controller appendOutputAndScroll:[NSString stringWithFormat:@"$ %@\n", cmdline] quiet:quietFlag];

	if ((fp=popen(cmdline.UTF8String,"r")) == NULL) {
		return NO;
	}
	while (YES) {
		if (fgets(str, MAX_LEN-1, fp) == NULL) {
			break;
		}
		[controller appendOutputAndScroll:[NSMutableString stringWithUTF8String:str] quiet:quietFlag];
	}
	NSInteger status = pclose(fp);
	return (ignoreErrorsFlag || status == 0) ? YES : NO;
	
}

- (BOOL)tex2dvi:(NSString*)teXFilePath
{
	BOOL status = [self execCommand:platexPath atDirectory:tempdir withArguments:@[@"-interaction=nonstopmode", [NSString stringWithFormat:@"-kanji=%@", encoding], teXFilePath]];
	[controller appendOutputAndScroll:@"\n" quiet:quietFlag];
	
	return status;
}

- (BOOL)dvi2pdf:(NSString*)dviFilePath
{
	BOOL status = [self execCommand:dvipdfmxPath atDirectory:tempdir withArguments:@[@"-vv", dviFilePath]];
	[controller appendOutputAndScroll:@"\n" quiet:quietFlag];	
	
	return status;
}

- (BOOL)pdfcrop:(NSString*)pdfPath outputFileName:(NSString*)outputFileName addMargin:(BOOL)addMargin
{
	if (!controller.pdfcropExists) {
		return NO;
	}
	
	BOOL status = [self execCommand:[NSString stringWithFormat:@"export PATH=$PATH:\"%@\":\"%@\";/usr/bin/perl \"%@\"",
                                    platexPath.stringByDeletingLastPathComponent,
                                    gsPath.stringByDeletingLastPathComponent,
                                    pdfcropPath]
                       atDirectory:tempdir
					 withArguments:@[addMargin ? [NSString stringWithFormat:@"--margins \"%ld %ld %ld %ld\"", leftMargin, topMargin, rightMargin, bottomMargin] : @"",
									pdfPath.lastPathComponent,
									outputFileName]];
	return status;
}

- (NSString*)epswriteOptionString
{
    NSString *result = @"eps2write";
    
    NSTask *task = NSTask.new;
    NSPipe *pipe = NSPipe.new;
    task.LaunchPath = gsPath;
    task.Arguments = @[@"--version"];
    task.StandardOutput = pipe;
    [task launch];
    
    NSData *data = pipe.fileHandleForReading.readDataToEndOfFile;
    NSString *versionString = [NSString.alloc initWithData:data encoding:NSUTF8StringEncoding];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d+(?:\\.\\d+)?" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:versionString options:0 range:NSMakeRange(0, versionString.length)];
    
    if (match) {
        double version = [versionString substringWithRange:[match rangeAtIndex:0]].doubleValue;
        if (version < 9.14) {
            result = @"epswrite";
        }
    }
    
    return result;
}

- (BOOL)pdf2eps:(NSString*)pdfName outputEpsFileName:(NSString*)outputEpsFileName resolution:(NSInteger)resolution page:(NSUInteger)page;
{
    NSString *epswriteOption = [NSString stringWithFormat:@"-sDEVICE=%@", self.epswriteOptionString];
    
	BOOL status = [self execCommand:gsPath atDirectory:tempdir
					 withArguments:@[epswriteOption,
									@"-dNOPAUSE",
									@"-dBATCH",
									[NSString stringWithFormat:@"-dFirstPage=%lu", page],
									[NSString stringWithFormat:@"-dLastPage=%lu", page],
									[NSString stringWithFormat:@"-r%ld", resolution],
									[NSString stringWithFormat:@"-sOutputFile=%@", outputEpsFileName],
									[NSString stringWithFormat:@"%@.pdf", tempFileBaseName]]];
	return status;
}

- (BOOL)epstopdf:(NSString*)epsName outputPdfFileName:(NSString*)outputPdfFileName
{
    if (!controller.epstopdfExists) {
		return NO;
	}
	
	[self execCommand:[NSString stringWithFormat:@"export PATH=\"%@\";/usr/bin/perl \"%@\"", gsPath.stringByDeletingLastPathComponent, epstopdfPath] atDirectory:tempdir
					 withArguments:@[[NSString stringWithFormat:@"--outfile=%@", outputPdfFileName],
									epsName]];
	return YES;
}

- (BOOL)eps2pdf:(NSString*)epsName outputFileName:(NSString*)outputFileName
{
	// まず，epstopdf を使って PDF に戻し，次に，pdfcrop を使って余白を付け加える
	NSString* trimFileName = [NSString stringWithFormat:@"%@.trim.pdf", epsName];
	if ([self epstopdf:epsName outputPdfFileName:trimFileName] && [self pdfcrop:trimFileName outputFileName:outputFileName addMargin:YES]) {
		return YES;
	}
	return NO;
}

// NSBitmapImageRep の背景を白く塗りつぶす
- (NSBitmapImageRep*)fillBackground:(NSBitmapImageRep*)bitmapRep
{
	NSImage *srcImage = NSImage.new;
	[srcImage addRepresentation:bitmapRep];
	NSSize size = srcImage.size;
	
	NSImage *backgroundImage = [NSImage.alloc initWithSize:size];
	[backgroundImage lockFocus];
	[NSColor.whiteColor set];
	[NSBezierPath fillRect:NSMakeRect(0, 0, size.width, size.height)];
    [srcImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[backgroundImage unlockFocus];
	return [NSBitmapImageRep.alloc initWithData:backgroundImage.TIFFRepresentation];
}

- (void)pdf2image:(NSString*)pdfFilePath outputFileName:(NSString*)outputFileName page:(NSUInteger)page
{
	NSString* extension = outputFileName.pathExtension.lowercaseString;

	// PDFのバウンディングボックスで切り取る
	[self pdfcrop:pdfFilePath outputFileName:pdfFilePath addMargin:NO];
	
	// PDFの指定ページを読み取り，NSPDFImageRep オブジェクトを作成
	NSData* pageData = [[PDFDocument.alloc initWithURL:[NSURL fileURLWithPath:pdfFilePath]] pageAtIndex:(page-1)].dataRepresentation;
	NSPDFImageRep *pdfImageRep = [NSPDFImageRep.alloc initWithData:pageData];

	// 新しい NSImage オブジェクトを作成し，その中に NSPDFImageRep オブジェクトの中身を描画
    NSRect rect = pdfImageRep.bounds;
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;

    if (useBP) {
        leftMargin *= resolutionLevel;
        rightMargin *= resolutionLevel;
        topMargin *= resolutionLevel;
        bottomMargin *= resolutionLevel;
    }
    
	NSSize size;
	size.width  = (NSInteger)(width * resolutionLevel) + leftMargin + rightMargin;
	size.height = (NSInteger)(height * resolutionLevel) + topMargin + bottomMargin;
	
	NSImage* image = [NSImage.alloc initWithSize:size];
	[image lockFocus];
	[pdfImageRep drawInRect:NSMakeRect(leftMargin, bottomMargin, (NSInteger)(width * resolutionLevel), (NSInteger)(height * resolutionLevel))];
	[image unlockFocus];
	
	// NSImage を TIFF 形式の NSBitmapImageRep に変換する
	NSBitmapImageRep *imageRep = [NSBitmapImageRep.alloc initWithData:image.TIFFRepresentation];
    
	// JPEG / PNG に変換
    NSData *outputData;
	if ([@"jpg" isEqualToString:extension]) {
		NSDictionary *propJpeg = @{NSImageCompressionFactor: @1.0f};
		imageRep = [self fillBackground:imageRep];
		outputData = [imageRep representationUsingType:NSJPEGFileType properties:propJpeg];
	}
	else { // png出力の場合
		if (!transparentPngFlag) {
			imageRep = [self fillBackground:imageRep];
		}
		NSDictionary *propPng = @{};
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

	float leftbottom_x = 0;
	float leftbottom_y = 0;
	float righttop_x = 0;
	float righttop_y = 0;

	char str[MAX_LEN];
    NSMutableArray* lines = NSMutableArray.array;

	FILE *fp;
	NSString* epsFilePath = [tempdir stringByAppendingPathComponent:epsName];

	fp = fopen(epsFilePath.UTF8String, "r");
	while ((fgets(str, MAX_LEN - 1, fp)) != NULL) {
		NSString* line = @(str);
		if (regexec(&regexBB, str, nmatch, pmatch, 0) == 0) {
			leftbottom_x  = [[line substringWithRange:NSMakeRange(pmatch[1].rm_so, pmatch[1].rm_eo - pmatch[1].rm_so)] intValue] - leftMargin;
			leftbottom_y  = [[line substringWithRange:NSMakeRange(pmatch[2].rm_so, pmatch[2].rm_eo - pmatch[2].rm_so)] intValue] - bottomMargin;
			righttop_x    = [[line substringWithRange:NSMakeRange(pmatch[3].rm_so, pmatch[3].rm_eo - pmatch[3].rm_so)] intValue]  + rightMargin;
			righttop_y    = [[line substringWithRange:NSMakeRange(pmatch[4].rm_so, pmatch[4].rm_eo - pmatch[4].rm_so)] intValue] + topMargin;
			[lines addObject:[NSString stringWithFormat:@"%%%%BoundingBox: %ld %ld %ld %ld\n", (NSInteger)leftbottom_x, (NSInteger)leftbottom_y, (NSInteger)righttop_x, (NSInteger)righttop_y]];
			continue;
		}
		
		if (regexec(&regexHiResBB, str, nmatch, pmatch, 0) == 0) {
            leftbottom_x  = [[line substringWithRange:NSMakeRange(pmatch[1].rm_so, pmatch[1].rm_eo - pmatch[1].rm_so)] floatValue] - leftMargin;
            leftbottom_y  = [[line substringWithRange:NSMakeRange(pmatch[2].rm_so, pmatch[2].rm_eo - pmatch[2].rm_so)] floatValue] - bottomMargin;
            righttop_x    = [[line substringWithRange:NSMakeRange(pmatch[3].rm_so, pmatch[3].rm_eo - pmatch[3].rm_so)] floatValue]  + rightMargin;
            righttop_y    = [[line substringWithRange:NSMakeRange(pmatch[4].rm_so, pmatch[4].rm_eo - pmatch[4].rm_so)] floatValue] + topMargin;
            [lines addObject:[NSString stringWithFormat:@"%%%%HiResBoundingBox: %f %f %f %f\n", leftbottom_x, leftbottom_y, righttop_x, righttop_y]];
			continue;
		}
		
		[lines addObject:line];
	}
	fclose(fp);
	
	fp = fopen(epsFilePath.UTF8String, "w");
	
	for (NSString* line in lines) {
		fputs(line.UTF8String, fp);
	}
	fclose(fp);
	
	regfree(&regexBB);
	regfree(&regexHiResBB);	
}

/*
- (NSInteger)eps2image:(NSString*)epsName outputFileName:(NSString*)outputFileName resolution:(NSInteger)resolution
{
	NSString* trimFileName = [NSString stringWithFormat:@"%@.trim.eps", epsName];
	NSString* extension = [[outputFileName pathExtension] lowercaseString];

	// まずはEPSファイルのバウンディングボックスを取得
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"^\\%\\%BoundingBox\\: (\\d+) (\\d+) (\\d+) (\\d+)$"]; // バウンディングボックス情報の正規表現
	OGRegularExpressionMatch *match;
	NSEnumerator *matchEnum;
	
	NSInteger leftbottom_x  = 0;
	NSInteger leftbottom_y  = 0;
	NSInteger righttop_x  = 0;
	NSInteger righttop_y  = 0;
	
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
	
	NSInteger status = [self execCommand:gsPath atDirectory:tempdir withArguments:
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

- (BOOL)convertPDF:(NSString*)pdfFileName outputEpsFileName:(NSString*)outputEpsFileName outputFileName:(NSString*)outputFileName page:(NSUInteger)page
{
	NSString* extension = outputFileName.pathExtension.lowercaseString;

    NSInteger resolution = 20016;

    // PDF→EPS の変換の実行
    if (![self pdf2eps:pdfFileName outputEpsFileName:outputEpsFileName resolution:resolution page:page]
        || ![fileManager fileExistsAtPath:[tempdir stringByAppendingPathComponent:outputEpsFileName]]) {
        [controller showExecError:@"ghostscript"];
        return NO;
    }
    
    if ([@"pdf" isEqualToString:extension]) { // アウトラインを取ったPDFを作成する場合，EPSからPDFに戻す
        [self eps2pdf:outputEpsFileName outputFileName:outputFileName];
    } else if ([@"eps" isEqualToString:extension]) { // 最終出力が EPS の場合
        // 余白を付け加えるようバウンディングボックスを改変
        if (topMargin + bottomMargin + leftMargin + rightMargin > 0) {
            [self enlargeBB:outputEpsFileName];
        }
        //生成したEPSファイルの名前を最終出力ファイル名へ変更する
        if ([fileManager fileExistsAtPath:outputFileName]) {
            [fileManager removeItemAtPath:outputFileName error:nil];
        }
        [fileManager moveItemAtPath:[tempdir stringByAppendingPathComponent:outputEpsFileName] toPath:outputFileName error:nil];
    } else if ([@"jpg" isEqualToString:extension] || [@"png" isEqualToString:extension]) { // JPEG/PNG出力の場合，EPSをPDFに戻した上で，それをさらにJPEG/PNGに変換する
        NSString* outlinedPdfFileName = [NSString stringWithFormat:@"%@.outline.pdf", tempFileBaseName];
        [self eps2pdf:outputEpsFileName outputFileName:outlinedPdfFileName]; // アウトラインを取ったEPSをPDFへ戻す
        [self pdf2image:[tempdir stringByAppendingPathComponent:outlinedPdfFileName] outputFileName:outputFileName page:1]; // PDFを目的の画像ファイルへ変換
    }
    
    return YES;
}

- (BOOL)copyTargetFrom:(NSString*)sourcePath toPath:(NSString*)destPath
{
	if ([fileManager fileExistsAtPath:destPath] && [fileManager removeItemAtPath:destPath error:nil] == NO) {
		[controller showCannotOverrideError:destPath];
		return NO;
	}
	return [fileManager copyItemAtPath:sourcePath toPath:destPath error:nil];
}

- (BOOL)compileAndConvert
{
	NSString* teXFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* dviFilePath = [NSString stringWithFormat:@"%@.dvi", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* pdfFilePath = [NSString stringWithFormat:@"%@.pdf", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
    NSString* pdfFileName = [NSString stringWithFormat:@"%@.pdf", tempFileBaseName];
	NSString* outputEpsFileName = [NSString stringWithFormat:@"%@.eps", tempFileBaseName];
	NSString* outputFileName = outputFilePath.lastPathComponent;
	NSString* extension = outputFilePath.pathExtension.lowercaseString;
	
	// TeX→DVI
	if (![self tex2dvi:teXFilePath]) {
		[controller showCompileError];
		return NO;
	}
	
	if (![fileManager fileExistsAtPath:dviFilePath]) {
		[controller showExecError:@"platex"];
		return NO;
	}
	
	// DVI→PDF
	if (![self dvi2pdf:dviFilePath] || ![fileManager fileExistsAtPath:pdfFilePath]) {
		[controller showExecError:@"dvipdfmx"];
		return NO;
	}
    
    pageCount = [PDFDocument.alloc initWithURL:[NSURL fileURLWithPath:pdfFilePath]].pageCount;
	
    // 最終出力が JPEG/PNG の場合も，PDFの段階でアウトラインを取っておいた方が最終出力が綺麗なので，必ずEPSを経由するようにする
    //if (([@"jpg" isEqualToString:extension] || [@"png" isEqualToString:extension]) && leaveTextFlag) { // jpg/png の場合，PDFから直接変換
	//	[self pdf2image:pdfFilePath outputFileName:outputFileName page:1];
    //    for (NSUInteger i=2; i<=pageCount; i++) {
    //        [self pdf2image:pdfFilePath outputFileName:[outputFileName pathStringByAppendingPageNumber:i] page:i];
    //    }
	//} else
    if ([@"pdf" isEqualToString:extension] && leaveTextFlag) { // 最終出力が文字埋め込み PDF の場合，EPSを経由しなくてよいので，pdfcrop で直接生成する。
		[self pdfcrop:pdfFilePath outputFileName:outputFileName addMargin:YES];
	} else { // EPS を経由する形式(EPS/outlined-PDF/JPEG/PNG)の場合
		/*
		// PDF→EPS の変換の準備
		NSInteger resolution;
		 
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
        
        BOOL success = [self convertPDF:pdfFileName
                      outputEpsFileName:outputEpsFileName
                         outputFileName:outputFileName
                                   page:1];
        if (!success) {
            return success;
        }
        
        for (NSUInteger i=2; i<=pageCount; i++) {
            success = [self convertPDF:pdfFileName
                     outputEpsFileName:[outputEpsFileName pathStringByAppendingPageNumber:i]
                        outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                                  page:i];
            if (!success) {
                return success;
            }
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
    [self copyTargetFrom:[tempdir stringByAppendingPathComponent:outputFileName] toPath:outputFilePath];
    for (NSUInteger i=2; i<=pageCount; i++) {
        [self copyTargetFrom:[tempdir stringByAppendingPathComponent:[outputFileName pathStringByAppendingPageNumber:i]]
                      toPath:[outputFilePath pathStringByAppendingPageNumber:i]];
    }
	
	return YES;
}

- (BOOL)compileAndConvertWithCheck
{
	BOOL status = YES;
	// 最初にプログラムの存在確認と出力ファイル形式確認
	if (![controller platexExistsAtPath:platexPath dvipdfmxPath:dvipdfmxPath gsPath:gsPath]) {
		status = NO;
	}
	
	NSString* extension = outputFilePath.pathExtension.lowercaseString;
	
    if (![@"eps" isEqualToString:extension] && ![@"png" isEqualToString:extension] && ![@"jpg" isEqualToString:extension] && ![@"pdf" isEqualToString:extension]) {
		[controller showExtensionError];
		status = NO;
	}
	
	if (status) {
		// 一連のコンパイル処理の開始準備
		[controller clearOutputTextView];
		if (showOutputDrawerFlag) {
			[controller showOutputDrawer];
		}
		[controller showMainWindow];
		
		// 一連のコンパイル処理を実行
		status = [self compileAndConvert];
		
		// プレビュー処理
		if (status && previewFlag) {
			[NSWorkspace.sharedWorkspace openFile:outputFilePath withApplication:@"Preview.app"];
            if (pageCount > 1 && !([@"pdf" isEqualToString:extension] && leaveTextFlag)) {
                for (NSUInteger i=2; i<=pageCount; i++) {
                    [NSWorkspace.sharedWorkspace openFile:[outputFilePath pathStringByAppendingPageNumber:i] withApplication:@"Preview.app"];
                }
            }
		}

        // Illustrator に配置
        if (status && embedInIllustratorFlag) {
            NSMutableString *script = NSMutableString.string;
            [script appendFormat:@"tell application \"Adobe Illustrator\"\n"];
            [script appendFormat:@"activate\n"];
            
            NSMutableArray *embededFiles = [NSMutableArray arrayWithObject:outputFilePath];
            for (NSUInteger i=2; i<=pageCount; i++) {
                [embededFiles addObject:[outputFilePath pathStringByAppendingPageNumber:i]];
            }
            
            [embededFiles enumerateObjectsUsingBlock:^(NSString* filePath, NSUInteger idx, BOOL *stop){
                [script appendFormat:@"embed (make new placed item in current document with properties {file path:(POSIX file \"%@\")})\n", filePath];
                if (ungroupFlag) {
                    [script appendFormat:@"move page items of selection of current document to end of current document\n"];
                }
            }];
            
            [script appendFormat:@"end tell\n"];
            [[NSAppleScript.alloc initWithSource:script] executeAndReturnError:nil];
        }
	}
	
	// 中間ファイルの削除
	if (deleteTmpFileFlag) {
		NSString* outputFileName = outputFilePath.lastPathComponent;
		NSString* basePath = [tempdir stringByAppendingPathComponent:tempFileBaseName];
		[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.tex", basePath] error:nil];
		[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.dvi", basePath] error:nil];
		[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.log", basePath] error:nil];
		[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.aux", basePath] error:nil];
		[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.pdf", basePath] error:nil];
		[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.outline.pdf", basePath] error:nil];
		[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.eps", basePath] error:nil];
		[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.eps.trim.pdf", basePath] error:nil];
		[fileManager removeItemAtPath:[tempdir stringByAppendingPathComponent:outputFileName] error:nil];
        for (NSUInteger i=2; i<=pageCount; i++) {
            [fileManager removeItemAtPath:[tempdir stringByAppendingPathComponent:[outputFileName pathStringByAppendingPageNumber:i]] error:nil];
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-%ld.eps", basePath, i] error:nil];
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-%ld.eps.trim.pdf", basePath, i] error:nil];
        }
	}
	
	return status;
}

- (BOOL)compileAndConvertWithSource:(NSString*)texSourceStr
{
	//TeX ソースを準備
	NSString* tempTeXFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	
	if (![self writeStringWithYenBackslashConverting:texSourceStr toFile:tempTeXFilePath]) {
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
	if (![fileManager copyItemAtPath:texSourcePath toPath:tempTeXFilePath error:nil]) {
		[controller showFileGenerateError:tempTeXFilePath];
		return NO;
	}
	
	return [self compileAndConvertWithCheck];
}


@end
