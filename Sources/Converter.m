#import <Quartz/Quartz.h>
#import <sys/xattr.h>
#import "global.h"
#import "Utility.h"

#define RESOLUTION_SCALE 5.0
#define EMPTY_BBOX @"%%BoundingBox: 0 0 0 0\n"

#import "NSArray-Extension.h"
#import "NSIndexSet-Extension.h"
#import "NSString-Extension.h"
#import "NSDictionary-Extension.h"
#import "NSMutableString-Extension.h"
#import "NSDate-Extension.h"
#import "NSPipe-Extension.h"
#import "PDFDocument-Extension.h"
#import "Converter.h"

@interface Converter()
@property NSString *latexPath;
@property NSString *dviwarePath;
@property NSString *gsPath;
@property NSString *encoding;
@property NSString *outputFilePath;
@property NSString *preambleStr;
@property float resolutionLevel;
@property BOOL guessCompilation;
@property NSInteger leftMargin, rightMargin, topMargin, bottomMargin, numberOfCompilation;
@property BOOL leaveTextFlag, transparentFlag, deleteDisplaySizeFlag, mergeOutputsFlag, keepPageSizeFlag, showOutputDrawerFlag, previewFlag, deleteTmpFileFlag, embedInIllustratorFlag, ungroupFlag, ignoreErrorsFlag, utfExportFlag, quietFlag;
@property NSObject<OutputController> *controller;
@property NSFileManager *fileManager;
@property NSString *tempdir;
@property pid_t pid;
@property NSString *tempFileBaseName;
@property NSString *epstopdfPath;
@property NSString *mudrawPath;
@property NSUInteger pageCount;
@property BOOL useBP;
@property BOOL speedPriorityMode;
@property BOOL embedSource;
@property BOOL copyToClipboard;
@property NSString *additionalInputPath;
@property BOOL pdfInputMode;
@property BOOL psInputMode;
@property BOOL errorsIgnored;
@property CGPDFBox pageBoxType;
@property NSMutableArray *emptyPageFlags;
@property NSMutableArray *whitePageFlags;
@end

@implementation Converter
@synthesize latexPath;
@synthesize dviwarePath;
@synthesize gsPath;
@synthesize encoding;
@synthesize outputFilePath;
@synthesize preambleStr;
@synthesize resolutionLevel;
@synthesize guessCompilation;
@synthesize leftMargin, rightMargin, topMargin, bottomMargin, numberOfCompilation;
@synthesize leaveTextFlag, transparentFlag, deleteDisplaySizeFlag, mergeOutputsFlag, keepPageSizeFlag, showOutputDrawerFlag, previewFlag, deleteTmpFileFlag, embedInIllustratorFlag, ungroupFlag, ignoreErrorsFlag, utfExportFlag, quietFlag;
@synthesize controller;
@synthesize fileManager;
@synthesize tempdir;
@synthesize pid;
@synthesize tempFileBaseName;
@synthesize epstopdfPath;
@synthesize mudrawPath;
@synthesize pageCount;
@synthesize useBP;
@synthesize speedPriorityMode;
@synthesize embedSource;
@synthesize copyToClipboard;
@synthesize additionalInputPath;
@synthesize pdfInputMode;
@synthesize psInputMode;
@synthesize errorsIgnored;
@synthesize pageBoxType;
@synthesize emptyPageFlags;
@synthesize whitePageFlags;


- (Converter*)initWithProfile:(NSDictionary*)aProfile
{
    pageCount = 1;
    
    latexPath = [aProfile stringForKey:LatexPathKey];
    dviwarePath = [aProfile stringForKey:DviwarePathKey];
    gsPath = [aProfile stringForKey:GsPathKey];
    epstopdfPath = [aProfile stringForKey:EpstopdfPathKey];
    mudrawPath = [aProfile stringForKey:MudrawPathKey];
    guessCompilation = [aProfile boolForKey:GuessCompilationKey];
    numberOfCompilation = [aProfile integerForKey:NumberOfCompilationKey];
    
    outputFilePath = [aProfile stringForKey:OutputFileKey];
    preambleStr = [aProfile stringForKey:PreambleKey];
    
    encoding = [aProfile stringForKey:EncodingKey];
    resolutionLevel = [aProfile floatForKey:ResolutionKey] / RESOLUTION_SCALE;
    leftMargin = [aProfile integerForKey:LeftMarginKey];
    rightMargin = [aProfile integerForKey:RightMarginKey];
    topMargin = [aProfile integerForKey:TopMarginKey];
    bottomMargin = [aProfile integerForKey:BottomMarginKey];
    leaveTextFlag = ![aProfile boolForKey:GetOutlineKey];
    transparentFlag = [aProfile boolForKey:TransparentKey];
    deleteDisplaySizeFlag = [aProfile boolForKey:DeleteDisplaySizeKey];
    mergeOutputsFlag = [aProfile boolForKey:MergeOutputsKey];
    keepPageSizeFlag = [aProfile boolForKey:KeepPageSizeKey];
    showOutputDrawerFlag = [aProfile boolForKey:ShowOutputDrawerKey];
    previewFlag = [aProfile boolForKey:PreviewKey];
    deleteTmpFileFlag = [aProfile boolForKey:DeleteTmpFileKey];
    copyToClipboard = [aProfile boolForKey:CopyToClipboardKey];
    embedInIllustratorFlag = [aProfile boolForKey:EmbedInIllustratorKey];
    ungroupFlag = [aProfile boolForKey:UngroupKey];
    ignoreErrorsFlag = [aProfile boolForKey:IgnoreErrorKey];
    utfExportFlag = [aProfile boolForKey:UtfExportKey];
    quietFlag = [aProfile boolForKey:QuietKey];
    controller = aProfile[ControllerKey];
    useBP = ([aProfile integerForKey:UnitKey] == BP_UNIT_TAG);
    speedPriorityMode = ([aProfile integerForKey:PriorityKey] == SPEED_PRIORITY_TAG);
    embedSource = [aProfile boolForKey:EmbedSourceKey];
    pageBoxType = [aProfile integerForKey:PageBoxKey];
    additionalInputPath = nil;
    pdfInputMode = NO;
    psInputMode = NO;
    errorsIgnored = NO;
    
	fileManager = NSFileManager.defaultManager;
	tempdir = NSTemporaryDirectory();
    
	tempFileBaseName = [NSString stringWithFormat:@"temp%d-%@", getpid(), NSString.UUIDString];
	
	return self;
}

+ (Converter*)converterWithProfile:(NSDictionary*)aProfile
{
	return [[Converter alloc] initWithProfile:aProfile];
}

- (void)exitCurrentThread
{
    [NSThread.currentThread cancel];
    if (NSThread.currentThread.isCancelled) {
        [self deleteTemporaryFiles];
        [controller generationDidFinish];
        [NSThread exit];
    }
}


// JIS X 0208 外の文字を \UTF に置き換える
- (NSMutableString*)substituteUTF:(NSString*)dataString
{
	NSMutableString *utfString, *newString = [NSMutableString string];
	unichar texChar = 0x5c;
	NSRange charRange;
	NSString *subString;
	NSUInteger startl, endl, end;
	
	charRange = NSMakeRange(0,1);
	endl = 0;
	while (charRange.location < dataString.length) {
		if (charRange.location == endl) {
			[dataString getLineStart:&startl end:&endl contentsEnd:&end forRange:charRange];
		}
		charRange = [dataString rangeOfComposedCharacterSequenceAtIndex:charRange.location];
		subString = [dataString substringWithRange: charRange];
		
		if (![subString canBeConvertedToEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP)]) {
			if ([subString characterAtIndex:0] == 0x2015) {
				utfString = [NSMutableString stringWithFormat:@"%C", 0x2014];
			} else {
				utfString = [NSMutableString stringWithFormat:@"%CUTF{%04X}", texChar, [subString characterAtIndex: 0]];
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
    NSMutableString* mstr = [NSMutableString string];
	[mstr appendString:targetString];
	
	[mstr replaceYenWithBackSlash];
		
    if (utfExportFlag) {
        mstr = [self substituteUTF:mstr];
    }
	
	UInt32 enc;
	if ([encoding isEqualToString:PTEX_ENCODING_SJIS]) {
		enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese);
	} else if ([encoding isEqualToString:PTEX_ENCODING_EUC]) {
		enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_JP);
	} else if ([encoding isEqualToString:PTEX_ENCODING_JIS]) {
		enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP);
    } else { // utf8
		enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8);
	}
	
	return [mstr writeToFile:path atomically:NO encoding:enc error:NULL];
}

- (NSMutableString*)preliminaryCommandsForEnvironmentVariables
{
    NSMutableString *cmdline = [NSMutableString stringWithFormat:@"export PATH=$PATH:\"%@\":\"%@\";", latexPath.programPath.stringByDeletingLastPathComponent, gsPath.programPath.stringByDeletingLastPathComponent];
    
    if (additionalInputPath) {
        [cmdline appendFormat:@"export TEXINPUTS=\"%@:`kpsewhich -progname=%@ -expand-var=\\\\$TEXINPUTS`\";", additionalInputPath, latexPath.programName];
    }
    
    return cmdline;
}

- (BOOL)compileWithArguments:(NSArray*)arguments
{
    NSMutableString *cmdline = self.preliminaryCommandsForEnvironmentVariables;
    
    [cmdline appendFormat:@"%@", latexPath];
    
    BOOL status = [controller execCommand:cmdline
                              atDirectory:tempdir
                            withArguments:arguments
                                    quiet:quietFlag];
    return status;
}

- (BOOL)tex2dvi:(NSString*)teXFilePath
{
    NSMutableArray *arguments = [NSMutableArray arrayWithObject:@"-interaction=nonstopmode"];
 
    if (![encoding isEqualToString:PTEX_ENCODING_NONE]) {
        [arguments addObject:[NSString stringWithFormat:@"-kanji=%@", encoding]];
    }
    
    [arguments addObject:teXFilePath];
    
    NSString *auxFilePath = [NSString stringWithFormat:@"%@.aux", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
    
    // まず aux を削除
    if ([fileManager fileExistsAtPath:auxFilePath isDirectory:nil] && ![fileManager removeItemAtPath:auxFilePath error:nil]) {
        return NO;
    }
    
    BOOL success = [self compileWithArguments:arguments];
    if (!success && !ignoreErrorsFlag) {
        return NO;
    }
    
    if (guessCompilation) {
        NSData *oldAuxData = [NSData dataWithContentsOfFile:auxFilePath];
        NSData *newAuxData = nil;
        
        // aux が \relax のみのときは終了
        if ([oldAuxData isEqualToData:[@"\\relax \n" dataUsingEncoding:NSUTF8StringEncoding]]) {
            return success;
        }
 
        for (NSInteger i=1; i<numberOfCompilation; i++) {
            success = [self compileWithArguments:arguments];
            if (!success && !ignoreErrorsFlag) {
                return NO;
            }
            newAuxData = [NSData dataWithContentsOfFile:auxFilePath];
            if ([newAuxData isEqualToData:oldAuxData]) {
                return success;
            }
            oldAuxData = newAuxData;
        }
    } else {
        for (NSInteger i=1; i<numberOfCompilation; i++) {
            success = [self compileWithArguments:arguments];
            if (!success && !ignoreErrorsFlag) {
                return NO;
            }
        }
    }
    
    return success;
}

- (BOOL)execDVIware:(NSString*)dviFilePath
{
    NSMutableString *cmdline = self.preliminaryCommandsForEnvironmentVariables;
    [cmdline appendString:dviwarePath];
    
	BOOL status = [controller execCommand:cmdline
                              atDirectory:tempdir
                            withArguments:@[dviFilePath]
                                    quiet:quietFlag];
	[controller appendOutputAndScroll:@"\n" quiet:quietFlag];	
	
	return status;
}

- (BOOL)ps2pdf:(NSString*)psFilePath outputFile:(NSString*)pdfFilePath
{
    NSMutableString *cmdline = self.preliminaryCommandsForEnvironmentVariables;
    [cmdline appendString:gsPath];
    BOOL status = [controller execCommand:cmdline
                              atDirectory:tempdir
                            withArguments:@[@"-dSAFER",
                                            @"-dNOPAUSE",
                                            @"-dBATCH",
                                            [@"-sOutputFile=" stringByAppendingString:pdfFilePath],
                                            @"-sDEVICE=pdfwrite",
                                            @"-dAutoRotatePages=/None",
                                            @"-c",
                                            @".setpdfwrite",
                                            @"-f",
                                            psFilePath]
                                    quiet:quietFlag];
    [controller appendOutputAndScroll:@"\n" quiet:quietFlag];
    
    return status;
}

// gsを実行して(非HiRes)BoundingBox情報を取得
- (NSString*)bboxStringOfPdf:(NSString*)pdfPath page:(NSUInteger)page
{
    NSString *cmdline = [NSString stringWithFormat:@"\"%@\" -dBATCH -dNOPAUSE -q -sDEVICE=bbox -dFirstPage=%ld -dLastPage=%ld \"%@\" 2>&1 | /usr/bin/grep %%%%BoundingBox", gsPath.programPath, page, page, pdfPath];
    return execCommand(cmdline);

}

// gsを実行してHiResBoundingBox情報を取得
- (NSString*)hiresBBoxStringOfPdf:(NSString*)pdfPath page:(NSUInteger)page
{
    NSString *cmdline = [NSString stringWithFormat:@"\"%@\" -dBATCH -dNOPAUSE -q -sDEVICE=bbox -dFirstPage=%ld -dLastPage=%ld \"%@\" 2>&1 | /usr/bin/grep %%%%HiResBoundingBox", gsPath.programPath, page, page, pdfPath];
    return execCommand(cmdline);
}

- (BOOL)isEmptyPage:(NSString*)pdfPath page:(NSUInteger)page
{
    return [[self bboxStringOfPdf:pdfPath page:page] isEqualToString:EMPTY_BBOX];
}

- (BOOL)willEmptyPageBeCreated:(NSString*)pdfPath page:(NSUInteger)page
{
    return (!keepPageSizeFlag && [self isEmptyPage:pdfPath page:page] && ((leftMargin + rightMargin == 0) || (topMargin + bottomMargin == 0)));
}

- (NSString*)buildCropTeXSource:(NSString*)pdfPath page:(NSUInteger)page addMargin:(BOOL)addMargin
{
    NSInteger leftmargin = addMargin ? leftMargin : 0;
    NSInteger rightmargin = addMargin ? rightMargin : 0;
    NSInteger topmargin = addMargin ? topMargin : 0;
    NSInteger bottommargin = addMargin ? bottomMargin : 0;
    
    NSString *bbStr = keepPageSizeFlag ?
    [[PDFPageBox pageBoxWithFilePath:pdfPath page:page] bboxStringOfBox:pageBoxType hires:NO clipWithMediaBox:YES relativeToMediaBox:YES addHeader:YES] :
    [self bboxStringOfPdf:pdfPath page:page];
    // ここで HiResBoundingBox を使うと，速度優先でビットマップ画像を生成する際に，小数点以下が切り捨てられて端が欠けてしまうことがある。よって，大きめに見積もる非HiReSのBBoxを使うのが得策。
    
    return [NSString stringWithFormat:@"{\\catcode37=13 \\catcode13=12 \\def^^25^^25#1: #2^^M{\\gdef\\do{\\proc[#2]}}%@\\relax}{}\\def\\proc[#1 #2 #3 #4]{\\pdfhorigin=-#1bp\\relax\\pdfvorigin=#2bp\\relax\\pdfpagewidth=\\dimexpr#3bp-#1bp\\relax\\pdfpageheight=\\dimexpr#4bp-#2bp\\relax}\\do\\advance\\pdfhorigin by %ldbp\\relax\\advance\\pdfpagewidth by %ldbp\\relax\\advance\\pdfpagewidth by %ldbp\\relax\\advance\\pdfvorigin by -%ldbp\\relax\\advance\\pdfpageheight by %ldbp\\relax\\advance\\pdfpageheight by %ldbp\\relax\\setbox0=\\hbox{\\pdfximage page %ld mediabox{%@}\\pdfrefximage\\pdflastximage}\\ht0=\\pdfpageheight\\relax\\shipout\\box0\\relax", bbStr, leftmargin, leftmargin, rightmargin, bottommargin, bottommargin, topmargin, page, pdfPath];
}

// pdfcrop類似処理
// page に 0 を与えると全ページをクロップした複数ページPDFを生成する。正の値を指定すると，そのページだけをクロップした単一ページPDFを生成する。
- (BOOL)pdfcrop:(NSString*)pdfPath outputFileName:(NSString*)outputFileName page:(NSUInteger)page addMargin:(BOOL)addMargin
{
    NSUInteger totalPages = [PDFDocument documentWithFilePath:pdfPath].pageCount;
    NSMutableString *cropTeX = [NSMutableString stringWithString:@"\\pdfoutput=1"];
    if (page > 0) {
        [cropTeX appendString:[self buildCropTeXSource:pdfPath page:page addMargin:addMargin]];
    } else {
        for (NSUInteger i=1; i<=totalPages; i++) {
            [cropTeX appendString:[self buildCropTeXSource:pdfPath page:i addMargin:addMargin]];
        }
    }
    [cropTeX appendString:@"\\end"];
    
    NSString *cropFileBasePath = [[tempdir stringByAppendingPathComponent:tempFileBaseName] stringByAppendingString:@"-pdfcrop"];
    NSString *cropTeXSourcePath = [cropFileBasePath stringByAppendingString:@".tex"];
    NSString *cropPdfSourcePath = [cropFileBasePath stringByAppendingString:@".pdf"];
    NSString *cropLogSourcePath = [cropFileBasePath stringByAppendingString:@".log"];
    
    [fileManager removeItemAtPath:cropTeXSourcePath error:nil];
    [cropTeX writeToFile:cropTeXSourcePath atomically:NO encoding:NSUTF8StringEncoding error:nil];

    NSString *pdfTeXPath = [latexPath.programPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"pdftex"];
    
	BOOL status = [controller execCommand:pdfTeXPath
                              atDirectory:tempdir
                            withArguments:@[@"-no-shell-escape", @"-interaction=batchmode", cropFileBasePath.lastPathComponent]
                                    quiet:quietFlag];
    
    [fileManager removeItemAtPath:cropTeXSourcePath error:nil];
    [fileManager removeItemAtPath:cropLogSourcePath error:nil];

    if (!status) {
        return NO;
    }
    
    [fileManager removeItemAtPath:outputFileName error:nil];
    [fileManager moveItemAtPath:cropPdfSourcePath toPath:outputFileName error:nil];
    
	return YES;
}

- (BOOL)shouldUseEps2WriteDevice
{
    BOOL result = YES;
    
    NSString *gsVerFileName = @"tex2img-gsver";
    NSString *gsVerFilePath = [tempdir stringByAppendingPathComponent:gsVerFileName];
    
    // 中断ボタンによる中断を可能とするため，あえて controller を通して実行する。
    // この出力は出力ビューの方に流れてしまうので，リダイレクトによってテキストファイル経由で gs のバージョンを受け取ることにする。
    // https://github.com/doraTeX/TeX2img/issues/40
    BOOL success = [controller execCommand:gsPath.programPath atDirectory:tempdir withArguments:@[@"--version", [@"> " stringByAppendingString:gsVerFileName]] quiet:YES];
    
    if (!success) {
        return YES;
    }
    
    NSString *versionString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:gsVerFilePath] encoding:NSUTF8StringEncoding error:NULL];
    [NSFileManager.defaultManager removeItemAtPath:gsVerFilePath error:nil];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d+(?:\\.\\d+)?" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:versionString options:0 range:NSMakeRange(0, versionString.length)];
    
    if (match) {
        double version = [versionString substringWithRange:[match rangeAtIndex:0]].doubleValue;
        if (version < 9.15) {
            result = NO;
        }
    }
    
    return result;
}

- (void)replaceBBoxOfEps:(NSString*)epsPath bb:(NSString*)bbStr hiresBb:(NSString*)hiresBbStr
{
    NSString *script = [NSString stringWithFormat:@"s=File.open('%@', 'rb'){|f| f.read}.sub(/%%%%BoundingBox\\: .+?\\n/){ \"%%%%BoundingBox: %@\"}.sub(/%%%%HiResBoundingBox\\: .+?\\n/){ \"%%%%HiResBoundingBox: %@\"};File.open('%@', 'wb') {|f| f.write s}",
                        epsPath,
                        bbStr,
                        hiresBbStr,
                        epsPath
                        ];
    NSString *scriptPath = [tempdir stringByAppendingPathComponent:@"tex2img-replaceBB"];
    
    FILE *fp = fopen(scriptPath.UTF8String, "w");
    fputs(script.UTF8String, fp);
    fclose(fp);
    
    system([NSString stringWithFormat:@"/usr/bin/ruby \"%@\"; rm \"%@\"", scriptPath, scriptPath].UTF8String);
}

- (BOOL)replaceEpsBBox:(NSString*)epsName withBBoxOfPdf:(NSString*)pdfName page:(NSUInteger)page
{
    NSString *epsPath = [tempdir stringByAppendingPathComponent:epsName];
    NSString *bbStr = [self bboxStringOfPdf:pdfName page:page];
    NSString *hiresBbStr = [self hiresBBoxStringOfPdf:pdfName page:page];
    
    if (!bbStr) {
        return NO;
    }
    
    if ([bbStr isEqualToString:EMPTY_BBOX]) { // 白紙ページの場合は置換を行わない
        return YES;
    }
    
    bbStr = [bbStr stringByReplacingOccurrencesOfString:@"%%BoundingBox: " withString:@""];
    hiresBbStr = hiresBbStr ? [hiresBbStr stringByReplacingOccurrencesOfString:@"%%HiResBoundingBox: " withString:@""] : bbStr;
    
    [self replaceBBoxOfEps:epsPath bb:bbStr hiresBb:hiresBbStr];
    return YES;
}

- (BOOL)replaceEpsBBoxWithEmptyBBox:(NSString*)epsName
{
    NSString *epsPath = [tempdir stringByAppendingPathComponent:epsName];
    NSString *bbStr = @"0 0 0 0\n";
    NSString *hiresBbStr = @"0.000000 0.000000 0.000000 0.000000\n";
    
    [self replaceBBoxOfEps:epsPath bb:bbStr hiresBb:hiresBbStr];
    return YES;
}

- (BOOL)replaceEpsBBox:(NSString*)epsName withPageBoxOfPdf:(NSString*)pdfName page:(NSUInteger)page
{
    PDFPageBox *pageBox = [PDFPageBox pageBoxWithFilePath:[tempdir stringByAppendingPathComponent:pdfName] page:page];
    NSString *epsPath = [tempdir stringByAppendingPathComponent:epsName];
    NSString *bbStr = [pageBox bboxStringOfBox:pageBoxType hires:NO clipWithMediaBox:YES relativeToMediaBox:YES addHeader:NO];
    NSString *hiresBbStr = [pageBox bboxStringOfBox:pageBoxType hires:YES clipWithMediaBox:YES relativeToMediaBox:YES addHeader:NO];
    
    [self replaceBBoxOfEps:epsPath bb:bbStr hiresBb:hiresBbStr];
    return YES;
}


- (BOOL)pdf2eps:(NSString*)pdfName outputEpsFileName:(NSString*)outputEpsFileName resolution:(NSInteger)resolution page:(NSUInteger)page;
{
    NSMutableArray *arguments = [NSMutableArray arrayWithArray:@[@"-dNOPAUSE",
                                                                 @"-dBATCH",
                                                                 [NSString stringWithFormat:@"-r%ld", resolution],
                                                                 [NSString stringWithFormat:@"-sOutputFile=%@", outputEpsFileName],
                                                                 [NSString stringWithFormat:@"-dFirstPage=%lu", page],
                                                                 [NSString stringWithFormat:@"-dLastPage=%lu", page],
                                                                 ]];
    
    BOOL shouldUseEps2WriteDevice = [self shouldUseEps2WriteDevice];
    
    if (shouldUseEps2WriteDevice) {
        [arguments addObject:@"-sDEVICE=eps2write"];
        [arguments addObject:@"-dNoOutputFonts"];
    } else {
        [arguments addObject:@"-sDEVICE=epswrite"];
        [arguments addObject:@"-dNOCACHE"];
    }
    
    [arguments addObject:pdfName];

    BOOL status = [controller execCommand:gsPath atDirectory:tempdir withArguments:arguments quiet:quietFlag];
    
    if (!status) {
        return NO;
    }
    
    if ([self isEmptyPage:pdfName page:page]) {
        return [self replaceEpsBBoxWithEmptyBBox:outputEpsFileName];
    }
    
    if (keepPageSizeFlag) {
        return [self replaceEpsBBox:outputEpsFileName withPageBoxOfPdf:pdfName page:page];
    } else {
        // 生成したEPSのBBox情報をオリジナルのPDFの gs -sDEVICE=bbox の出力結果で置換する
        // https://github.com/doraTeX/TeX2img/issues/18
        // https://github.com/doraTeX/TeX2img/issues/37
    
        return [self replaceEpsBBox:outputEpsFileName withBBoxOfPdf:pdfName page:page];
    }
}

- (BOOL)epstopdf:(NSString*)epsName outputPdfFileName:(NSString*)outputPdfFileName
{
    if (![controller epstopdfExists]) {
		return NO;
	}
	
	[controller execCommand:[NSString stringWithFormat:@"export PATH=\"%@\";/usr/bin/perl \"%@\"", gsPath.programPath.stringByDeletingLastPathComponent, epstopdfPath]
                atDirectory:tempdir
              withArguments:@[[NSString stringWithFormat:@"--outfile=%@", outputPdfFileName],
                              epsName]
                      quiet:quietFlag];
	return YES;
}

- (BOOL)eps2pdf:(NSString*)epsName outputFileName:(NSString*)outputFileName addMargin:(BOOL)addMargin
{
    if (addMargin && (leftMargin + rightMargin + topMargin + bottomMargin > 0)) {
        NSString* trimFileName = [NSString stringWithFormat:@"%@.trim.pdf", epsName];
        // まず，epstopdf を使って PDF に戻し，次に，pdfcrop類似処理を使って余白を付け加える
        return [self epstopdf:epsName outputPdfFileName:trimFileName] && [self pdfcrop:trimFileName outputFileName:outputFileName page:0 addMargin:YES];
    } else {
        // epstopdf を使って PDF に戻すのみ
        return [self epstopdf:epsName outputPdfFileName:outputFileName];
    }
    
    return NO;
}

// NSBitmapImageRep の背景を白く塗りつぶす
- (NSBitmapImageRep*)fillBackground:(NSBitmapImageRep*)bitmapRep
{
	NSImage *srcImage = [NSImage new];
	[srcImage addRepresentation:bitmapRep];
	NSSize size = srcImage.size;
	
	NSImage *backgroundImage = [[NSImage alloc] initWithSize:size];
	[backgroundImage lockFocus];
	[NSColor.whiteColor set];
	[NSBezierPath fillRect:NSMakeRect(0, 0, size.width, size.height)];
    [srcImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[backgroundImage unlockFocus];
	return [[NSBitmapImageRep alloc] initWithData:backgroundImage.TIFFRepresentation];
}

- (void)pdf2image:(NSString*)pdfFilePath outputFileName:(NSString*)outputFileName page:(NSUInteger)page crop:(BOOL)crop
{
	NSString* extension = outputFileName.pathExtension.lowercaseString;
    
    if ([self willEmptyPageBeCreated:pdfFilePath page:page]) {
        return;
    }

	// PDFのバウンディングボックスで切り取る
    if (crop) {
        [self pdfcrop:pdfFilePath outputFileName:pdfFilePath page:0 addMargin:NO];
    }
	
	// PDFの指定ページを読み取り，NSPDFImageRep オブジェクトを作成
	NSData* pageData = [[PDFDocument documentWithFilePath:pdfFilePath] pageAtIndex:(page-1)].dataRepresentation;
	NSPDFImageRep *pdfImageRep = [[NSPDFImageRep alloc] initWithData:pageData];

	// 新しい NSImage オブジェクトを作成し，その中に NSPDFImageRep オブジェクトの中身を描画
    NSRect rect = pdfImageRep.bounds;
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    CGFloat thisLeftMargin = (CGFloat)leftMargin;
    CGFloat thisRightMargin = (CGFloat)rightMargin;
    CGFloat thisTopMargin = (CGFloat)topMargin;
    CGFloat thisBottomMargin = (CGFloat)bottomMargin;

    if (useBP) {
        thisLeftMargin *= resolutionLevel;
        thisRightMargin *= resolutionLevel;
        thisTopMargin *= resolutionLevel;
        thisBottomMargin *= resolutionLevel;
    } else {
        CGFloat factor = NSScreen.mainScreen.backingScaleFactor; // for Retina Display
        thisLeftMargin /= factor;
        thisRightMargin /= factor;
        thisTopMargin /= factor;
        thisBottomMargin /= factor;
    }
    
	NSSize size = NSMakeSize((NSInteger)(width * resolutionLevel) + thisLeftMargin + thisRightMargin,
                             (NSInteger)(height * resolutionLevel) + thisTopMargin + thisBottomMargin);
	
	NSImage* image = [[NSImage alloc] initWithSize:size];
	[image lockFocus];
	[pdfImageRep drawInRect:NSMakeRect(thisLeftMargin, thisBottomMargin, width * resolutionLevel, height * resolutionLevel)];
	[image unlockFocus];
	
	// NSImage を TIFF 形式の NSBitmapImageRep に変換する
	NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:image.TIFFRepresentation];
    
	// 指定のビットマップ形式に変換
    NSData *outputData;
	if ([@"jpg" isEqualToString:extension]) {
		imageRep = [self fillBackground:imageRep];
        NSDictionary *prop = @{NSImageCompressionFactor: @1.0f};
		outputData = [imageRep representationUsingType:NSJPEGFileType properties:prop];
	} else if ([@"png" isEqualToString:extension]) {
		if (!transparentFlag) {
			imageRep = [self fillBackground:imageRep];
		}
		outputData = [imageRep representationUsingType:NSPNGFileType properties:nil];
    } else if ([@"gif" isEqualToString:extension]) {
        if (!transparentFlag) {
            imageRep = [self fillBackground:imageRep];
        }
        outputData = [imageRep representationUsingType:NSGIFFileType properties:nil];
    } else if ([@"tiff" isEqualToString:extension]) {
        if (!transparentFlag) {
            imageRep = [self fillBackground:imageRep];
        }
        NSDictionary *prop = @{NSImageCompressionFactor: @1.0f};
        outputData = [imageRep representationUsingType:NSTIFFFileType properties:prop];
    } else if ([@"bmp" isEqualToString:extension]) {
        imageRep = [self fillBackground:imageRep];
        outputData = [imageRep representationUsingType:NSBMPFileType properties:nil];
    }
	[outputData writeToFile:[tempdir stringByAppendingPathComponent:outputFileName] atomically: YES];

}

- (void)enlargeBB:(NSString*)epsName
{
    NSString *epsPath = [tempdir stringByAppendingPathComponent:epsName];
    NSString *script = [NSString stringWithFormat:@"s=File.open('%@', 'rb'){|f| f.read}.sub(/%%%%BoundingBox\\: (\\-?[0-9]+) (\\-?[0-9]+) (\\-?[0-9]+) (\\-?[0-9]+)\\n/){ \"%%%%BoundingBox: #{$1.to_i-%ld} #{$2.to_i-%ld} #{$3.to_i+%ld} #{$4.to_i+%ld}\\n\"}.sub(/%%%%HiResBoundingBox\\: (\\-?[0-9\\.]+) (\\-?[0-9\\.]+) (\\-?[0-9\\.]+) (\\-?[0-9\\.]+)\\n/){ \"%%%%HiResBoundingBox: #{$1.to_f-%f} #{$2.to_f-%f} #{$3.to_f+%f} #{$4.to_f+%f}\\n\"};File.open('%@', 'wb') {|f| f.write s}",
                          epsPath,
                          leftMargin, bottomMargin, rightMargin, topMargin,
                          (CGFloat)leftMargin, (CGFloat)bottomMargin, (CGFloat)rightMargin, (CGFloat)topMargin,
                          epsPath
                          ];
    NSString *scriptPath = [tempdir stringByAppendingPathComponent:@"tex2img-enlargeBB"];

    FILE *fp = fopen(scriptPath.UTF8String, "w");
    fputs(script.UTF8String, fp);
    fclose(fp);
    
    system([NSString stringWithFormat:@"/usr/bin/ruby \"%@\"; rm \"%@\"", scriptPath, scriptPath].UTF8String);
}

- (BOOL)pdf2svg:(NSString*)pdfFilePath outputFileName:(NSString*)svgFilePath page:(NSUInteger)page
{
    if (![controller mudrawExists]) {
        return NO;
    }
    
    if ([emptyPageFlags[page-1] boolValue]) {
        return YES;
    }
    
    NSArray *arguments = @[@"-o", svgFilePath, pdfFilePath, [NSString stringWithFormat:@"%ld", page]];
    
    BOOL success = [controller execCommand:mudrawPath
                               atDirectory:tempdir
                             withArguments:arguments
                                     quiet:quietFlag];
    if (!success ) {
        return NO;
    }
    
    // SVG の width, height 属性を削除する
    if (deleteDisplaySizeFlag) {
        NSMutableString *mstr = [NSMutableString stringWithString:[NSString stringWithContentsOfFile:svgFilePath encoding:NSUTF8StringEncoding error:nil]];
        NSString *pattern = @"width=\".+?\" height=\".+?\" ";
        NSRange match = [mstr rangeOfString:pattern options:NSRegularExpressionSearch];
        if (match.location != NSNotFound) {
            [mstr replaceCharactersInRange:match withString:@""];
        }
        [mstr writeToFile:svgFilePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
    
    return YES;
}

- (BOOL)convertPDF:(NSString*)pdfFileName outputEpsFileName:(NSString*)outputEpsFileName outputFileName:(NSString*)outputFileName page:(NSUInteger)page
{
	NSString* extension = outputFileName.pathExtension.lowercaseString;
    NSString* outlinedPdfFileName = [NSString stringWithFormat:@"%@.outline.pdf", tempFileBaseName];

    NSInteger lowResolution = resolutionLevel*((NSInteger)RESOLUTION_SCALE)*2*72;
    NSInteger resolution = speedPriorityMode ? lowResolution : 20016;
    
    if (!emptyPageFlags || emptyPageFlags.count == 0) {
        [self exitCurrentThread];
    }

    if ([emptyPageFlags[page-1] boolValue]) {
        return YES;
    }
    
    // PDF→EPS の変換の実行（この時点で強制cropされる）
    if (![self pdf2eps:pdfFileName outputEpsFileName:outputEpsFileName resolution:resolution page:page]
        || ![fileManager fileExistsAtPath:[tempdir stringByAppendingPathComponent:outputEpsFileName]]) {
        [controller showExecError:@"ghostscript"];
        return NO;
    }
    
    if ([@"pdf" isEqualToString:extension]) { // アウトラインを取ったPDFを作成する場合，EPSからPDFに戻す（ここでpdfcrop類似処理で余白付与）
        if ([self isEmptyPage:pdfFileName page:page]) { // 空白ページを経由する場合は epstopdf が使えない（エラーになる）ので，そこだけpdfcrop類似処理で変換する
            [self pdfcrop:pdfFileName outputFileName:outputFileName page:page addMargin:YES];
        } else {
            [self eps2pdf:outputEpsFileName outputFileName:outputFileName addMargin:YES];
        }
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
    } else { // ビットマップ形式出力の場合，EPSをPDFに戻した上で，それをさらにビットマップ形式に変換する
        if ([self isEmptyPage:pdfFileName page:page]) { // 空白ページを経由する場合は epstopdf が使えない（エラーになる）ので，そこだけ Quartz で変換する
            [self pdf2image:[tempdir stringByAppendingPathComponent:pdfFileName] outputFileName:outputFileName page:page crop:YES];
        } else {
            [self eps2pdf:outputEpsFileName outputFileName:outlinedPdfFileName addMargin:NO]; // アウトラインを取ったEPSをPDFへ戻す（余白はこの時点では付与しない）
            [self pdf2image:[tempdir stringByAppendingPathComponent:outlinedPdfFileName] outputFileName:outputFileName page:1 crop:NO]; // PDFを目的の画像ファイルへ変換（ここで余白付与）
        }
    }
    
    return YES;
}

- (BOOL)copyTargetFrom:(NSString*)sourcePath toPath:(NSString*)destPath
{
    if ([sourcePath isEqualToString:destPath]) {
        return YES;
    }
    
    BOOL isDir;
    BOOL fileExists = [fileManager fileExistsAtPath:destPath isDirectory:&isDir];
    
    if (fileExists) { // 同名ファイルが存在するとき
        if (isDir || ![fileManager removeItemAtPath:destPath error:nil]) { // 既存ファイルがディレクトリであるとき，または既存同名ファイルがファイルであり，その削除に失敗したとき
            [controller showCannotOverwriteError:destPath];
            return NO;
        }
    } else { // 同名ファイルが存在しないとき
        NSString *destDir = destPath.stringByDeletingLastPathComponent;
        BOOL dirExists = [fileManager fileExistsAtPath:destDir isDirectory:&isDir];
        
        if ((!dirExists && ![fileManager createDirectoryAtPath:destDir withIntermediateDirectories:YES attributes:nil error:nil]) ||
            (dirExists && !isDir)) { // 出力先新規ディレクトリの作成に失敗したとき，または出力先ディレクトリが存在するが実はファイルであるとき
            [controller showCannotCreateDirectoryError:destDir];
            return NO;
        }
    }

    return [fileManager copyItemAtPath:sourcePath toPath:destPath error:nil];
}

- (void)embedSource:(NSString*)texFilePath intoFile:(NSString*)filePath
{
    if (!embedSource) {
        return;
    }
    
    const char *target = filePath.fileSystemRepresentation;
   
    // ソース情報を UTF8 で EA に保存
    NSData *data = [NSData dataWithContentsOfFile:texFilePath];
    NSStringEncoding detectedEncoding;
    NSString *contents = [NSString stringWithAutoEncodingDetectionOfData:data detectedEncoding:&detectedEncoding];
    
    const char *val = contents.UTF8String;
    
    setxattr(target, EA_Key, val, strlen(val), 0, 0);
}

- (NSDate*)fileModificationDateAtPath:(NSString*)filePath
{
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
    
    if (attributes) {
        return (NSDate*)[attributes objectForKey:NSFileModificationDate];
    } else {
        return nil;
    }
}

- (BOOL)compileAndConvert
{
	NSString* texFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* dviFilePath = [NSString stringWithFormat:@"%@.dvi", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
    NSString* psFilePath  = [NSString stringWithFormat:@"%@.ps",  [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* pdfFilePath = [NSString stringWithFormat:@"%@.pdf", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
    NSString* croppedPdfFilePath = [NSString stringWithFormat:@"%@-crop.pdf", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
    NSString* pdfFileName = [NSString stringWithFormat:@"%@.pdf", tempFileBaseName];
	NSString* outputEpsFileName = [NSString stringWithFormat:@"%@.eps", tempFileBaseName];
	NSString* outputFileName = outputFilePath.lastPathComponent;
	NSString* extension = outputFilePath.pathExtension.lowercaseString;
    NSDate *texDate, *dviDate, *psDate, *pdfDate;
    BOOL success = NO, compilationSuceeded = NO, requireDviware = NO, requireGS = NO;

    errorsIgnored = NO;
    
    [fileManager changeCurrentDirectoryPath:tempdir];
    
    if (!pdfInputMode && !psInputMode) {
        // TeX コンパイル
        success = [self tex2dvi:texFilePath];
        if (!success) {
            if (ignoreErrorsFlag) {
                errorsIgnored = YES;
            } else {
                [controller showCompileError];
                return NO;
            }
        }
        [controller exitCurrentThreadIfTaskKilled];
        
        compilationSuceeded = NO;
        requireDviware = NO;
        
        texDate = [self fileModificationDateAtPath:texFilePath];
        
        if ([fileManager fileExistsAtPath:pdfFilePath]) { // PDF が存在する場合
            pdfDate = [self fileModificationDateAtPath:pdfFilePath];
            if (pdfDate && [pdfDate isNewerThan:texDate]) {
                requireDviware = NO; // 新しい PDF が生成されていれば DVIware にかける必要なしと見なす
                compilationSuceeded = YES;
            }
        }
        
        if (!compilationSuceeded && [fileManager fileExistsAtPath:dviFilePath]) { // 新しい PDF が存在せず，DVI が存在する場合
            dviDate = [self fileModificationDateAtPath:dviFilePath];
            if (dviDate && [dviDate isNewerThan:texDate]) {
                requireDviware = YES; // 新しい PDF が存在せず，新しい DVI が生成されていれば DVIware にかける必要ありと見なす
                compilationSuceeded = YES;
            }
        }
        
        if (!compilationSuceeded) {
            [controller showExecError:@"LaTeX"];
            return NO;
        }
        
        // DVI→PDF
        if (requireDviware) {
            success = [self execDVIware:dviFilePath];
            if (!success) {
                if (ignoreErrorsFlag) {
                    errorsIgnored = YES;
                } else {
                    [controller showExecError:@"DVI driver"];
                    return NO;
                }
            }
            [controller exitCurrentThreadIfTaskKilled];

            compilationSuceeded = NO;
            requireGS = NO;
            
            if ([fileManager fileExistsAtPath:pdfFilePath]) { // PDF が存在する場合
                pdfDate = [self fileModificationDateAtPath:pdfFilePath];
                if (pdfDate && [pdfDate isNewerThan:texDate]) {
                    requireGS = NO;
                    compilationSuceeded = YES;
                }
            }
            
            if (!compilationSuceeded && [fileManager fileExistsAtPath:psFilePath]) { // 新しい PDF が存在せず，PS が存在する場合
                psDate = [self fileModificationDateAtPath:psFilePath];
                if (psDate && [psDate isNewerThan:dviDate]) {
                    requireGS = YES; // 新しい PDF が存在せず，新しい PS が生成されていれば GS にかける必要ありと見なす
                    compilationSuceeded = YES;
                }
            }
            
            if (!compilationSuceeded) {
                [controller showExecError:@"DVI driver"];
                return NO;
            }
        }
    }

    // PS→PDF
    if (psInputMode || requireGS) {
        success = [self ps2pdf:psFilePath outputFile:pdfFilePath];
        if (!success) {
            if (ignoreErrorsFlag) {
                errorsIgnored = YES;
            } else {
                [controller showExecError:@"Ghostscript"];
                return NO;
            }
        }
        [controller exitCurrentThreadIfTaskKilled];
        
        compilationSuceeded = NO;
        
        if ([fileManager fileExistsAtPath:pdfFilePath]) { // PDF が存在する場合
            pdfDate = [self fileModificationDateAtPath:pdfFilePath];
            if (pdfDate && [pdfDate isNewerThan:psDate]) {
                compilationSuceeded = YES;
            }
        }
        
        if (!compilationSuceeded) {
            [controller showExecError:@"Ghostscript"];
            return NO;
        }
    }

    [controller exitCurrentThreadIfTaskKilled];
    
    PDFDocument *pdfDocument = [PDFDocument documentWithFilePath:pdfFilePath];
    
    if (!pdfDocument) {
        [controller showFileFormatError:pdfFilePath];
        return NO;
    }
    
    pageCount = pdfDocument.pageCount;

    emptyPageFlags = [NSMutableArray array];
    for (NSInteger i=1; i<=pageCount; i++) {
        [emptyPageFlags addObject:@([self willEmptyPageBeCreated:pdfFilePath page:i])];
    }

    whitePageFlags = [NSMutableArray array];
    for (NSInteger i=1; i<=pageCount; i++) {
        [whitePageFlags addObject:@([self isEmptyPage:pdfFilePath page:i] && !(((NSNumber*)emptyPageFlags[i-1]).boolValue))];
    }

    // ありうる経路
    // 【gsを通さない経路]
    //  1. 速度優先モードでのビットマップ生成 (PDF →[pdfcrop類似処理でクロップ]→ PDF →[Quartz API でビットマップ化＋余白付与]→ JPEG/PNG/GIF/TIFF/BMP)
    //  2. テキスト情報を残したPDF生成 (PDF →[pdfcrop類似処理でクロップ＋余白付与]→ PDF)
    //  3. テキスト情報を残したSVG生成 (PDF →[pdfcrop類似処理でクロップ＋余白付与]→ PDF →[mudraw]→ SVG)
    //
    // 【gsを通す経路]
    //  4. 画質優先モードでのビットマップ生成 (PDF →[gs(eps(2)write)でアウトライン化[*1]＋クロップ]→ EPS →[epstopdf(gs)]→ PDF →[Quartz API でビットマップ化＋余白付与]→ JEPG/PNG/GIF/TIFF/BMP)
    //  5. アウトライン化PDF生成 (PDF →[gs(eps(2)write)でアウトライン化[*1]＋クロップ] → EPS →[epstopdf(gs)]→ PDF →[pdfcrop類似処理で余白付与]→ PDF)
    //  6. アウトライン化EPS生成 (PDF →[gs(eps(2)write)でアウトライン化[*1]＋クロップ] → EPS →[BB情報を編集して余白付与] → EPS)
    // [*1] このgsによるアウトライン化は，画質優先モードの場合は -r20016 固定，速度優先モードの場合は解像度レベル設定に従う
    
    // 最終出力がビットマップ形式で「速度優先」の場合は，PDFからQuartzで直接変換
    if ([@[@"jpg", @"png", @"gif", @"tiff", @"bmp"] containsObject:extension] && speedPriorityMode) {
        [self pdf2image:pdfFilePath outputFileName:outputFileName page:1 crop:YES];
        for (NSUInteger i=2; i<=pageCount; i++) {
            [self pdf2image:pdfFilePath outputFileName:[outputFileName pathStringByAppendingPageNumber:i] page:i crop:YES];
        }
	} else if ([@"pdf" isEqualToString:extension] && leaveTextFlag) { // 最終出力が文字埋め込み PDF の場合，EPS を経由しなくてよいので，pdfcrop類似処理で直接生成する。
        BOOL success = [self pdfcrop:pdfFilePath outputFileName:outputFileName page:1 addMargin:YES];
        if (!success) {
            return success;
        }
        
        for (NSUInteger i=2; i<=pageCount; i++) {
            success = [self pdfcrop:pdfFilePath
                     outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                               page:i
                          addMargin:YES];
            if (!success) {
                return success;
            }
        }
    } else if ([@"svg" isEqualToString:extension]) { // 最終出力が SVG の場合，pdfcrop類似処理をかけてから1ページずつ mudraw にかける
        [self pdfcrop:pdfFilePath outputFileName:croppedPdfFilePath page:0 addMargin:YES];

        BOOL success = [self pdf2svg:croppedPdfFilePath
                      outputFileName:outputFileName
                                page:1];
        if (!success) {
            return success;
        }
        
        for (NSUInteger i=2; i<=pageCount; i++) {
            success = [self pdf2svg:croppedPdfFilePath
                     outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                               page:i];
            if (!success) {
                return success;
            }
        }
	} else { // EPS を経由する形式(EPS/outlined-PDF/ビットマップ形式)の場合
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
	}

    BOOL copySucceeded = YES;
    
    // 単一PDF出力の場合
    if ([@"pdf" isEqualToString:extension] && mergeOutputsFlag) {
        // 実際に生成したファイルのパスを集める
        NSMutableArray *outputFiles = [NSMutableArray array];
        
        if (![emptyPageFlags[0] boolValue]) {
            [outputFiles addObject:[tempdir stringByAppendingPathComponent:outputFileName]];
        }
        
        for (NSUInteger i=2; i<=pageCount; i++) {
            if (![emptyPageFlags[i-1] boolValue]) {
                [outputFiles addObject:[tempdir stringByAppendingPathComponent:[outputFileName pathStringByAppendingPageNumber:i]]];
            }
        }
        
        // マージして出力
        if (outputFiles.count > 0) {
            // 出力先パスがディレクトリであった場合はエラー
            BOOL isDir;
            if ([fileManager fileExistsAtPath:outputFilePath isDirectory:&isDir] && isDir) {
                [controller showCannotOverwriteError:outputFilePath];
                return NO;
            }
            
            copySucceeded = [[PDFDocument documentWithMergingPDFFiles:outputFiles] writeToFile:outputFilePath];
            if (copySucceeded) {
                [self embedSource:texFilePath intoFile:outputFilePath];
            } else {
                return NO;
            }
            
            // 生成ファイルをクリップボードへコピー
            if (copyToClipboard) {
                NSPasteboard *pboard = NSPasteboard.generalPasteboard;
                [pboard declareTypes:@[NSURLPboardType] owner:nil];
                [pboard clearContents];
                [pboard writeObjects:@[[[NSURL alloc] initFileURLWithPath:outputFilePath]]];
            }
        }

    } else { // バラバラ出力の場合
        // 最終出力ファイルを目的地へコピー
        if (![emptyPageFlags[0] boolValue]) {
            copySucceeded = [self copyTargetFrom:[tempdir stringByAppendingPathComponent:outputFileName] toPath:outputFilePath];
            if (copySucceeded) {
                [self embedSource:texFilePath intoFile:outputFilePath];
            } else {
                return NO;
            }
        }
        
        if (copySucceeded) {
            for (NSUInteger i=2; i<=pageCount; i++) {
                if (![emptyPageFlags[i-1] boolValue]) {
                    NSString *destPath = [outputFilePath pathStringByAppendingPageNumber:i];
                    copySucceeded = [self copyTargetFrom:[tempdir stringByAppendingPathComponent:[outputFileName pathStringByAppendingPageNumber:i]]
                                                  toPath:destPath];
                    if (copySucceeded) {
                        [self embedSource:texFilePath intoFile:destPath];
                    } else {
                        return NO;
                    }
                }
            }
        }
        
        // 生成ファイルをクリップボードへコピー
        if (copyToClipboard) {
            NSPasteboard *pboard = NSPasteboard.generalPasteboard;
            [pboard declareTypes:@[NSURLPboardType] owner:nil];
            NSMutableArray *outputFiles = [NSMutableArray array];
            
            if (![emptyPageFlags[0] boolValue]) {
                [outputFiles addObject:[[NSURL alloc] initFileURLWithPath:outputFilePath]];
            }
            
            for (NSUInteger i=2; i<=pageCount; i++) {
                if (![emptyPageFlags[i-1] boolValue]) {
                    [outputFiles addObject:[[NSURL alloc] initFileURLWithPath:[outputFilePath pathStringByAppendingPageNumber:i]]];
                }
            }
            
            if (outputFiles.count > 0) {
                [pboard clearContents];
                [pboard writeObjects:outputFiles];
            }
        }
    }
	
	return YES;
}

- (void)runAppleScriptOnMainThread:(NSString*)script
{
    [[[NSAppleScript alloc] initWithSource:script] executeAndReturnError:nil];
}

- (BOOL)compileAndConvertWithCheck
{
	// 最初にプログラムの存在確認と出力ファイル形式確認
	if (![controller latexExistsAtPath:latexPath.programPath dviwarePath:dviwarePath.programPath gsPath:gsPath.programPath]) {
        [controller generationDidFinish];
		return NO;
	}
	
	NSString* extension = outputFilePath.pathExtension.lowercaseString;

    if (![TargetExtensionsArray containsObject:extension]) {
		[controller showExtensionError];
        [controller generationDidFinish];
		return NO;
	}
    
    // 一連のコンパイル処理の開始準備
    [controller prepareOutputTextView];
    if (showOutputDrawerFlag) {
        [controller showOutputDrawer];
    }
    [controller showMainWindow];
    
    // 一連のコンパイル処理を実行
    BOOL status = [self compileAndConvert];

    [controller releaseOutputTextView];
    
    // 生成ファイルを集める
    NSMutableArray *generatedFiles = [NSMutableArray array];
    
    if ([extension isEqualToString:@"pdf"] && mergeOutputsFlag && (emptyPageFlags.indexesOfTrueValue.count < pageCount)) {
        [generatedFiles addObject:outputFilePath];
    } else {
        if (![emptyPageFlags[0] boolValue]) {
            [generatedFiles addObject:outputFilePath];
        }
        for (NSUInteger i=2; i<=pageCount; i++) {
            if (![emptyPageFlags[i-1] boolValue]) {
                [generatedFiles addObject:[outputFilePath pathStringByAppendingPageNumber:i]];
            }
        }
    }
    
    // プレビュー処理
    if (status && previewFlag) {
        NSString *previewApp = [extension isEqualToString:@"svg"] ? @"Safari" : @"Preview";
        [controller previewFiles:generatedFiles withApplication:previewApp];
    }
    
    // Illustrator に配置
    if (status && embedInIllustratorFlag && generatedFiles.count > 0) {
        NSMutableString *script = [NSMutableString string];
        [script appendFormat:@"tell application \"Adobe Illustrator\"\n"];
        [script appendFormat:@"activate\n"];
        
        [generatedFiles enumerateObjectsUsingBlock:^(NSString* filePath, NSUInteger idx, BOOL *stop) {
            [script appendFormat:@"embed (make new placed item in current document with properties {file path:(POSIX file \"%@\")})\n", filePath];
            if (ungroupFlag) {
                [script appendFormat:@"move page items of selection of current document to end of current document\n"];
            }
        }];
        
        [script appendFormat:@"end tell\n"];
        [self performSelectorOnMainThread:@selector(runAppleScriptOnMainThread:) withObject:script waitUntilDone:NO];
    }

    // 結果表示
    if (status) {
        [controller printResult:generatedFiles quiet:quietFlag];
    }
    
    // 白紙ページスキップ警告を表示
    NSIndexSet *skippedPageIndexes = emptyPageFlags.indexesOfTrueValue;
    
    if (skippedPageIndexes.count > 0) {
        [controller showPageSkippedWarning:skippedPageIndexes.arrayOfIndexesPlusOne];
    }

    // 白色ページ生成警告を表示
    NSIndexSet *whitePageIndexes = whitePageFlags.indexesOfTrueValue;
    
    if (status && whitePageIndexes.count > 0) {
        [controller showWhitePageWarning:whitePageIndexes.arrayOfIndexesPlusOne];
    }

    // エラーを無視した場合は警告
    if (ignoreErrorsFlag && errorsIgnored) {
        [controller showErrorsIgnoredWarning];
    }
    
    // 後処理
    [self deleteTemporaryFiles];
    [controller generationDidFinish]; // GUI版の場合はここでも deleteTemporaryFiles が呼び出されるが，CUI版では呼び出されないので二重呼び出しは仕方ない
    
	return status;
}

- (void)deleteTemporaryFiles
{
    if (deleteTmpFileFlag) {
        NSString* outputFileName = outputFilePath.lastPathComponent;
        NSString* basePath = [tempdir stringByAppendingPathComponent:tempFileBaseName];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.tex", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.dvi", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.log", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.aux", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.ps", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.pdf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-crop.pdf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.outline.pdf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.eps", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.eps.trim.pdf", basePath] error:nil];
        
        NSString *outputDir = [outputFilePath.stringByDeletingLastPathComponent stringByAppendingString:@"/"];
        if (![outputDir isEqualToString:tempdir]) {
            [fileManager removeItemAtPath:[tempdir stringByAppendingPathComponent:outputFileName] error:nil];
        }
        for (NSUInteger i=2; i<=pageCount; i++) {
            if (![outputDir isEqualToString:tempdir]) {
                [fileManager removeItemAtPath:[tempdir stringByAppendingPathComponent:[outputFileName pathStringByAppendingPageNumber:i]] error:nil];
            }
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-%ld.eps", basePath, i] error:nil];
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-%ld.eps.trim.pdf", basePath, i] error:nil];
        }
    }
}


- (BOOL)compileAndConvertWithSource:(NSString*)texSourceStr
{
	// TeX ソースを準備
	NSString* tempTeXFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	
	if (![self writeStringWithYenBackslashConverting:texSourceStr toFile:tempTeXFilePath]) {
		[controller showFileGenerateError:tempTeXFilePath];
        [controller generationDidFinish];
		return NO;
	}
	
	return [self compileAndConvertWithCheck];
}

- (BOOL)compileAndConvertWithBody:(NSString*)texBodyStr
{
    @autoreleasepool {
        // TeX ソースを用意
        NSString* texSourceStr = [NSString stringWithFormat:@"%@\n\\begin{document}\n%@\n\\end{document}", preambleStr, texBodyStr];
        return [self compileAndConvertWithSource:texSourceStr];
    }
}

- (BOOL)compileAndConvertWithInputPath:(NSString*)sourcePath
{
    @autoreleasepool {
        BOOL isDir;
        if ([fileManager fileExistsAtPath:sourcePath isDirectory:&isDir] && isDir) {
            [controller showFileFormatError:sourcePath];
            [controller generationDidFinish];
            return NO;
        }
        
        NSString *ext = sourcePath.pathExtension.lowercaseString;
        pdfInputMode = [ext isEqualToString:@"pdf"];
        psInputMode = [ext isEqualToString:@"ps"] || [ext isEqualToString:@"eps"];
        
        if (pdfInputMode) {
            // PDFの書式チェック
            if (![PDFDocument documentWithFilePath:sourcePath]) {
                [controller showFileFormatError:sourcePath];
                [controller generationDidFinish];
                return NO;
            }

            NSString *tempPdfFilePath = [NSString stringWithFormat:@"%@.pdf", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
            if (![fileManager copyItemAtPath:sourcePath toPath:tempPdfFilePath error:nil]) {
                [controller showFileGenerateError:tempPdfFilePath];
                [controller generationDidFinish];
                return NO;
            }
        } else if (psInputMode) {
            NSString *tempPsFilePath = [NSString stringWithFormat:@"%@.ps", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
            if (![fileManager copyItemAtPath:sourcePath toPath:tempPsFilePath error:nil]) {
                [controller showFileGenerateError:tempPsFilePath];
                [controller generationDidFinish];
                return NO;
            }
        } else {
            NSString *tempTeXFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
            if (![fileManager copyItemAtPath:sourcePath toPath:tempTeXFilePath error:nil]) {
                [controller showFileGenerateError:tempTeXFilePath];
                [controller generationDidFinish];
                return NO;
            }
        }
        
        additionalInputPath = getFullPath(sourcePath.stringByDeletingLastPathComponent);
        
        return [self compileAndConvertWithCheck];
    }
}


@end
