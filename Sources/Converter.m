#import <stdio.h>
#import <Quartz/Quartz.h>
#include <sys/xattr.h>
#import "global.h"
#import "Utility.h"

#define MAX_LEN 1024

#import "NSDictionary-Extension.h"
#import "NSString-Extension.h"
#import "NSMutableString-Extension.h"
#import "NSDate-Extension.h"
#import "Converter.h"

@interface Converter()
@property NSString* latexPath;
@property NSString* dvipdfmxPath;
@property NSString* gsPath;
@property NSString* encoding;
@property NSString* outputFilePath;
@property NSString* preambleStr;
@property float resolutionLevel;
@property BOOL guessCompilation;
@property NSInteger leftMargin, rightMargin, topMargin, bottomMargin, numberOfCompilation;
@property BOOL leaveTextFlag, transparentFlag, deleteDisplaySizeFlag, showOutputDrawerFlag, previewFlag, deleteTmpFileFlag, embedInIllustratorFlag, ungroupFlag, ignoreErrorsFlag, utfExportFlag, quietFlag;
@property id<OutputController> controller;
@property NSFileManager* fileManager;
@property NSString* tempdir;
@property pid_t pid;
@property NSString* tempFileBaseName;
@property NSString* epstopdfPath;
@property NSString* mudrawPath;
@property NSUInteger pageCount;
@property BOOL useBP;
@property BOOL speedPriorityMode;
@property BOOL embedSource;
@property NSString* additionalInputPath;
@end

@implementation Converter
@synthesize latexPath;
@synthesize dvipdfmxPath;
@synthesize gsPath;
@synthesize encoding;
@synthesize outputFilePath;
@synthesize preambleStr;
@synthesize resolutionLevel;
@synthesize guessCompilation;
@synthesize leftMargin, rightMargin, topMargin, bottomMargin, numberOfCompilation;
@synthesize leaveTextFlag, transparentFlag, deleteDisplaySizeFlag, showOutputDrawerFlag, previewFlag, deleteTmpFileFlag, embedInIllustratorFlag, ungroupFlag, ignoreErrorsFlag, utfExportFlag, quietFlag;
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
@synthesize additionalInputPath;


- (Converter*)initWithProfile:(NSDictionary*)aProfile
{
    pageCount = 1;
    
    latexPath = [aProfile stringForKey:LatexPathKey];
    dvipdfmxPath = [aProfile stringForKey:DvipdfmxPathKey];
    gsPath = [aProfile stringForKey:GsPathKey];
    epstopdfPath = [aProfile stringForKey:EpstopdfPathKey];
    mudrawPath = [aProfile stringForKey:MudrawPathKey];
    guessCompilation = [aProfile boolForKey:GuessCompilationKey];
    numberOfCompilation = [aProfile integerForKey:NumberOfCompilationKey];
    
    outputFilePath = [aProfile stringForKey:OutputFileKey];
    preambleStr = [aProfile stringForKey:PreambleKey];
    
    encoding = [aProfile stringForKey:EncodingKey];
    resolutionLevel = [aProfile floatForKey:ResolutionKey] / 5.0;
    leftMargin = [aProfile integerForKey:LeftMarginKey];
    rightMargin = [aProfile integerForKey:RightMarginKey];
    topMargin = [aProfile integerForKey:TopMarginKey];
    bottomMargin = [aProfile integerForKey:BottomMarginKey];
    leaveTextFlag = ![aProfile boolForKey:GetOutlineKey];
    transparentFlag = [aProfile boolForKey:TransparentKey];
    deleteDisplaySizeFlag = [aProfile boolForKey:DeleteDisplaySizeKey];
    showOutputDrawerFlag = [aProfile boolForKey:ShowOutputDrawerKey];
    previewFlag = [aProfile boolForKey:PreviewKey];
    deleteTmpFileFlag = [aProfile boolForKey:DeleteTmpFileKey];
    embedInIllustratorFlag = [aProfile boolForKey:EmbedInIllustratorKey];
    ungroupFlag = [aProfile boolForKey:UngroupKey];
    ignoreErrorsFlag = [aProfile boolForKey:IgnoreErrorKey];
    utfExportFlag = [aProfile boolForKey:UtfExportKey];
    quietFlag = [aProfile boolForKey:QuietKey];
    controller = aProfile[ControllerKey];
    useBP = ([aProfile integerForKey:UnitKey] == BPUNITTAG);
    speedPriorityMode = ([aProfile integerForKey:PriorityKey] == SPEED_PRIORITY_TAG);
    embedSource = [aProfile boolForKey:EmbedSourceKey];
    additionalInputPath = nil;
    
	fileManager = NSFileManager.defaultManager;
	tempdir = NSTemporaryDirectory();
    
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    
    pid = getpid();
	tempFileBaseName = [NSString stringWithFormat:@"temp%d-%@", pid, uuidStr];
	
	return self;
}

+ (Converter*)converterWithProfile:(NSDictionary*)aProfile
{
	return [Converter.alloc initWithProfile:aProfile];
}



// JIS X 0208 外の文字を \UTF に置き換える
- (NSMutableString*)substituteUTF:(NSString*)dataString
{
	NSMutableString *utfString, *newString = NSMutableString.string;
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
    NSMutableString* mstr = NSMutableString.string;
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

// TODO: execCommand を NSTask / NSPipe で書き直す？
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

	if ((fp = popen(cmdline.UTF8String, "r")) == NULL) {
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

- (NSMutableString*)preliminaryCommandsForEnvironmentVariables
{
    NSMutableString *cmdline = [NSMutableString stringWithFormat:@"export PATH=$PATH:\"%@\";", latexPath.programPath.stringByDeletingLastPathComponent];
    
    if (additionalInputPath) {
        [cmdline appendFormat:@"export TEXINPUTS=%@:`kpsewhich -progname=%@ -expand-var=\\\\$TEXINPUTS`;", additionalInputPath, latexPath.programName];
    }
    
    return cmdline;
}

- (BOOL)compileWithArguments:(NSArray*)arguments
{
    NSMutableString *cmdline = self.preliminaryCommandsForEnvironmentVariables;
    
    [cmdline appendFormat:@"%@", latexPath.lastPathComponent];
    
    BOOL status = [self execCommand:cmdline
                        atDirectory:tempdir
                      withArguments:arguments];
    [controller appendOutputAndScroll:@"\n" quiet:quietFlag];
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
    if (!success) {
        return NO;
    }
    
    if (guessCompilation) {
        NSData *oldAuxData = [NSData dataWithContentsOfFile:auxFilePath];
        NSData *newAuxData = nil;
        
        // aux が \relax のみのときは終了
        if ([oldAuxData isEqualToData:[@"\\relax \n" dataUsingEncoding:NSUTF8StringEncoding]]) {
            return YES;
        }
 
        for (NSInteger i=1; i<numberOfCompilation; i++) {
            success = [self compileWithArguments:arguments];
            if (!success) {
                return NO;
            }
            newAuxData = [NSData dataWithContentsOfFile:auxFilePath];
            if ([newAuxData isEqualToData:oldAuxData]) {
                return YES;
            }
            oldAuxData = newAuxData;
        }
    } else {
        for (NSInteger i=1; i<numberOfCompilation; i++) {
            success = [self compileWithArguments:arguments];
            if (!success) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (BOOL)dvi2pdf:(NSString*)dviFilePath
{
    NSMutableString *cmdline = self.preliminaryCommandsForEnvironmentVariables;
    [cmdline appendString:dvipdfmxPath];
	BOOL status = [self execCommand:cmdline atDirectory:tempdir withArguments:@[@"-vv", dviFilePath]];
	[controller appendOutputAndScroll:@"\n" quiet:quietFlag];	
	
	return status;
}

- (NSString*)buildCropTeXSource:(NSString*)pdfPath page:(NSUInteger)page addMargin:(BOOL)addMargin
{
    // gsを実行してbb情報を取得
    char str[MAX_LEN];
    FILE *fp;
    NSMutableString *bbStr = NSMutableString.new;
    
    NSString *cmdline = [NSString stringWithFormat:@"\"%@\" -dBATCH -dNOPAUSE -q -sDEVICE=bbox -dFirstPage=%ld -dLastPage=%ld \"%@\" 2>&1 | /usr/bin/grep %%%%BoundingBox", gsPath, page, page, pdfPath];

    if ((fp = popen(cmdline.UTF8String, "r")) == NULL) {
        return NO;
    }
    while (YES) {
        if (fgets(str, MAX_LEN-1, fp) == NULL) {
            break;
        }
        [bbStr appendString:@(str)];
    }
    if (pclose(fp) != 0) {
        return NO;
    }
    
    NSInteger leftmargin = addMargin ? leftMargin : 0;
    NSInteger rightmargin = addMargin ? rightMargin : 0;
    NSInteger topmargin = addMargin ? topMargin : 0;
    NSInteger bottommargin = addMargin ? bottomMargin : 0;
    
    return [NSString stringWithFormat:@"{\\catcode37=13 \\catcode13=12 \\def^^25^^25#1: #2^^M{\\gdef\\do{\\proc[#2]}}%@\\relax}{}\\def\\proc[#1 #2 #3 #4]{\\pdfhorigin-#1bp \\pdfvorigin#2bp \\pdfpagewidth=\\dimexpr#3bp-#1bp\\relax\\pdfpageheight\\dimexpr#4bp-#2bp\\relax}\\do\\advance\\pdfhorigin by %ldbp\\relax \\advance\\pdfpagewidth by %ldbp\\relax \\advance\\pdfpagewidth by %ldbp\\relax\\advance\\pdfvorigin by -%ldbp\\relax \\advance\\pdfpageheight by %ldbp\\relax \\advance\\pdfpageheight by %ldbp\\relax\\setbox0=\\hbox{\\pdfximage page %ld mediabox{%@}\\pdfrefximage\\pdflastximage}\\ht0=\\pdfpageheight \\shipout\\box0\\relax", bbStr, leftmargin, leftmargin, rightmargin, bottommargin, bottommargin, topmargin, page, pdfPath];
}

// page に 0 を与えると全ページをクロップした複数ページPDFを生成する。正の値を指定すると，そのページだけをクロップした単一ページPDFを生成する。
- (BOOL)pdfcrop:(NSString*)pdfPath outputFileName:(NSString*)outputFileName page:(NSUInteger)page addMargin:(BOOL)addMargin
{
    NSUInteger totalPages = [PDFDocument.alloc initWithURL:[NSURL fileURLWithPath:pdfPath]].pageCount;
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
    
	BOOL status = [self execCommand:pdfTeXPath
                       atDirectory:tempdir
					 withArguments:@[@"-no-shell-escape", @"-interaction=batchmode", cropFileBasePath.lastPathComponent]
                   ];
    
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
    
    NSTask *task = NSTask.new;
    NSPipe *pipe = NSPipe.new;
    task.launchPath = gsPath;
    task.arguments = @[@"--version"];
    task.standardOutput = pipe;
    [task launch];
    
    NSData *data = pipe.fileHandleForReading.readDataToEndOfFile;
    NSString *versionString = [NSString.alloc initWithData:data encoding:NSUTF8StringEncoding];
    
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

- (BOOL)pdf2eps:(NSString*)pdfName outputEpsFileName:(NSString*)outputEpsFileName resolution:(NSInteger)resolution page:(NSUInteger)page;
{
    NSMutableArray *arguments = [NSMutableArray arrayWithArray:@[@"-dNOPAUSE", @"-dBATCH"]];
    
    if (self.shouldUseEps2WriteDevice) {
        [arguments addObject:@"-sDEVICE=eps2write"];
        [arguments addObject:@"-dNoOutputFonts"];
    } else {
        [arguments addObject:@"-sDEVICE=epswrite"];
        [arguments addObject:@"-dNOCACHE"];
    }

    [arguments addObjectsFromArray:@[[NSString stringWithFormat:@"-dFirstPage=%lu", page],
                                     [NSString stringWithFormat:@"-dLastPage=%lu", page],
                                     [NSString stringWithFormat:@"-r%ld", resolution],
                                     [NSString stringWithFormat:@"-sOutputFile=%@", outputEpsFileName],
                                     [NSString stringWithFormat:@"%@.pdf", tempFileBaseName]
                                     ]];

    BOOL status = [self execCommand:gsPath atDirectory:tempdir withArguments:arguments];
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

- (BOOL)eps2pdf:(NSString*)epsName outputFileName:(NSString*)outputFileName addMargin:(BOOL)addMargin
{
    if (addMargin && (leftMargin + rightMargin + topMargin + bottomMargin > 0)) {
        NSString* trimFileName = [NSString stringWithFormat:@"%@.trim.pdf", epsName];
        // まず，epstopdf を使って PDF に戻し，次に，pdfcrop を使って余白を付け加える
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

- (void)pdf2image:(NSString*)pdfFilePath outputFileName:(NSString*)outputFileName page:(NSUInteger)page crop:(BOOL)crop
{
	NSString* extension = outputFileName.pathExtension.lowercaseString;

	// PDFのバウンディングボックスで切り取る
    if (crop) {
        [self pdfcrop:pdfFilePath outputFileName:pdfFilePath page:0 addMargin:NO];
    }
	
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
    
    system([NSString stringWithFormat:@"/usr/bin/ruby %@; rm %@", scriptPath, scriptPath].UTF8String);
}

- (BOOL)pdf2svg:(NSString*)pdfFilePath outputFileName:(NSString*)svgFilePath page:(NSUInteger)page
{
    if (!controller.mudrawExists) {
        return NO;
    }
    
    NSArray *arguments = @[@"-l", @"-o", svgFilePath, pdfFilePath, [NSString stringWithFormat:@"%ld", page]];
    
    BOOL success = [self execCommand:mudrawPath
                         atDirectory:tempdir
                       withArguments:arguments];
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

    NSInteger lowResolution = resolutionLevel*5*2*72;
    NSInteger resolution = speedPriorityMode ? lowResolution : 20016;

    // PDF→EPS の変換の実行（この時点で強制cropされる）
    if (![self pdf2eps:pdfFileName outputEpsFileName:outputEpsFileName resolution:resolution page:page]
        || ![fileManager fileExistsAtPath:[tempdir stringByAppendingPathComponent:outputEpsFileName]]) {
        [controller showExecError:@"ghostscript"];
        return NO;
    }
    
    if ([@"pdf" isEqualToString:extension]) { // アウトラインを取ったPDFを作成する場合，EPSからPDFに戻す（ここでpdfcropで余白付与）
        [self eps2pdf:outputEpsFileName outputFileName:outputFileName addMargin:YES];
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
        [self eps2pdf:outputEpsFileName outputFileName:outlinedPdfFileName addMargin:NO]; // アウトラインを取ったEPSをPDFへ戻す（余白はこの時点では付与しない）
        [self pdf2image:[tempdir stringByAppendingPathComponent:outlinedPdfFileName] outputFileName:outputFileName page:1 crop:NO]; // PDFを目的の画像ファイルへ変換（ここで余白付与）
    }
    
    return YES;
}

- (BOOL)copyTargetFrom:(NSString*)sourcePath toPath:(NSString*)destPath
{
    BOOL isDir;
    BOOL fileExists = [fileManager fileExistsAtPath:destPath isDirectory:&isDir];
    
    if (fileExists) { // 同名ファイルが存在するとき
        if (isDir || ![fileManager removeItemAtPath:destPath error:nil]) { // 既存ファイルがディレクトリであるとき，または既存同名ファイルがファイルであり，その削除に失敗したとき
            [controller showCannotOverwriteError:destPath];
            return NO;
        }
    } else { // 同名ファイルが存在しないとき
        NSString *destDir = [destPath stringByDeletingLastPathComponent];
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
    if (!embedSource) return;
    
    const char *target = filePath.fileSystemRepresentation;
   
    // ソース情報を UTF8 で EA に保存
    NSData *data = [NSData dataWithContentsOfFile:texFilePath];
    NSStringEncoding detectedEncoding;
    NSString *contents = [NSString stringWithAutoEncodingDetectionOfData:data detectedEncoding:&detectedEncoding];
    
    const char *val = contents.UTF8String;
    
    setxattr(target, EAKey, val, strlen(val), 0, 0);
}

- (NSDate*)fileModificationDateAtPath:(NSString*)filePath
{
    NSError *error = nil;
    
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
    
    if (error != nil) {
        return nil;
    } else {
        return (NSDate*)[attributes objectForKey:NSFileModificationDate];
    }
}

- (BOOL)compileAndConvert
{
	NSString* texFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* dviFilePath = [NSString stringWithFormat:@"%@.dvi", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* pdfFilePath = [NSString stringWithFormat:@"%@.pdf", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
    NSString* croppedPdfFilePath = [NSString stringWithFormat:@"%@-crop.pdf", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
    NSString* pdfFileName = [NSString stringWithFormat:@"%@.pdf", tempFileBaseName];
	NSString* outputEpsFileName = [NSString stringWithFormat:@"%@.eps", tempFileBaseName];
	NSString* outputFileName = outputFilePath.lastPathComponent;
	NSString* extension = outputFilePath.pathExtension.lowercaseString;
	
	// TeX コンパイル
	if (![self tex2dvi:texFilePath]) {
		[controller showCompileError];
		return NO;
	}
	
    BOOL compilationSuceeded = NO;
    BOOL requireDvipdfmx = NO;
    
    NSDate *texDate = [self fileModificationDateAtPath:texFilePath];

    if ([fileManager fileExistsAtPath:pdfFilePath]) { // PDF が存在する場合
        NSDate *pdfDate = [self fileModificationDateAtPath:pdfFilePath];
        if (pdfDate && [pdfDate isNewerThan:texDate]) {
            requireDvipdfmx = NO; // 新しい PDF が生成されていれば dvipdfmx の必要なしと見なす
            compilationSuceeded = YES;
        }
    }

    if (!compilationSuceeded && [fileManager fileExistsAtPath:dviFilePath]) { // 新しい PDF が存在せず，DVI が存在する場合
        NSDate *dviDate = [self fileModificationDateAtPath:dviFilePath];
        if (dviDate && [dviDate isNewerThan:texDate]) {
            requireDvipdfmx = YES; // 新しい PDF が存在せず，新しい DVI が生成されていれば dvipdfmx の必要ありと見なす
            compilationSuceeded = YES;
        }
    }
    
    if (!compilationSuceeded) {
        [controller showExecError:@"LaTeX"];
        return NO;
    }
	
	// DVI→PDF
	if (requireDvipdfmx && (![self dvi2pdf:dviFilePath] || ![fileManager fileExistsAtPath:pdfFilePath])) {
		[controller showExecError:@"dvipdfmx"];
		return NO;
	}
    
    pageCount = [PDFDocument.alloc initWithURL:[NSURL fileURLWithPath:pdfFilePath]].pageCount;
	
    // 最終出力がビットマップ形式で「速度優先」の場合は，PDFからQuartzで直接変換
    if ([@[@"jpg", @"png", @"gif", @"tiff", @"bmp"] containsObject:extension] && speedPriorityMode) {
        [self pdf2image:pdfFilePath outputFileName:outputFileName page:1 crop:YES];
        for (NSUInteger i=2; i<=pageCount; i++) {
            [self pdf2image:pdfFilePath outputFileName:[outputFileName pathStringByAppendingPageNumber:i] page:i crop:YES];
        }
	} else if ([@"pdf" isEqualToString:extension] && leaveTextFlag) { // 最終出力が文字埋め込み PDF の場合，EPSを経由しなくてよいので，pdfcrop で直接生成する。
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
    } else if ([@"svg" isEqualToString:extension]) { // 最終出力が SVG の場合，pdfcrop してから1ページずつ mudraw にかける
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
	
	// 最終出力ファイルを目的地へコピー
    [self copyTargetFrom:[tempdir stringByAppendingPathComponent:outputFileName] toPath:outputFilePath];
    [self embedSource:texFilePath intoFile:outputFilePath];

    for (NSUInteger i=2; i<=pageCount; i++) {
        NSString *destPath = [outputFilePath pathStringByAppendingPageNumber:i];
        [self copyTargetFrom:[tempdir stringByAppendingPathComponent:[outputFileName pathStringByAppendingPageNumber:i]]
                      toPath:destPath];
        [self embedSource:texFilePath intoFile:destPath];
    }
	
	return YES;
}

- (BOOL)compileAndConvertWithCheck
{
	// 最初にプログラムの存在確認と出力ファイル形式確認
	if (![controller latexExistsAtPath:latexPath.programPath dvipdfmxPath:dvipdfmxPath gsPath:gsPath]) {
		return NO;
	}
	
	NSString* extension = outputFilePath.pathExtension.lowercaseString;

    if (![TargetExtensionsArray containsObject:extension]) {
		[controller showExtensionError];
		return NO;
	}
    
    // 一連のコンパイル処理の開始準備
    [controller clearOutputTextView];
    if (showOutputDrawerFlag) {
        [controller showOutputDrawer];
    }
    [controller showMainWindow];
    
    // 一連のコンパイル処理を実行
    BOOL status = [self compileAndConvert];
    
    NSString *previewApp = [extension isEqualToString:@"svg"] ? @"Safari.app" : @"Preview.app";
    
    // プレビュー処理
    if (status && previewFlag) {
        [NSWorkspace.sharedWorkspace openFile:outputFilePath withApplication:previewApp];
        if (pageCount > 1) {
            for (NSUInteger i=2; i<=pageCount; i++) {
                [NSWorkspace.sharedWorkspace openFile:[outputFilePath pathStringByAppendingPageNumber:i] withApplication:previewApp];
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
        
        [embededFiles enumerateObjectsUsingBlock:^(NSString* filePath, NSUInteger idx, BOOL *stop) {
            [script appendFormat:@"embed (make new placed item in current document with properties {file path:(POSIX file \"%@\")})\n", filePath];
            if (ungroupFlag) {
                [script appendFormat:@"move page items of selection of current document to end of current document\n"];
            }
        }];
        
        [script appendFormat:@"end tell\n"];
        [[NSAppleScript.alloc initWithSource:script] executeAndReturnError:nil];
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
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-crop.pdf", basePath] error:nil];
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
	// TeX ソースを準備
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
    
    additionalInputPath = getFullPath(texSourcePath.stringByDeletingLastPathComponent);
	
	return [self compileAndConvertWithCheck];
}


@end
