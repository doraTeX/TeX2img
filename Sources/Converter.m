#import <Quartz/Quartz.h>
#import <sys/xattr.h>
#import "TeX2img-Swift.h"
#import "Utility.h"

#define RESOLUTION_SCALE 5.0
#define EMPTY_BBOX @"%%BoundingBox: 0 0 0 0\n"

#import "NSArray-Extension.h"
#import "NSString-Extension.h"
#import "NSString-Conversion.h"
#import "NSDictionary-Extension.h"
#import "NSMutableString-Extension.h"
#import "Converter.h"

@interface Converter()
@property (nonatomic, copy) NSString *latexPath;
@property (nonatomic, copy) NSString *dviDriverPath;
@property (nonatomic, copy) NSString *gsPath;
@property (nonatomic, copy) NSString *encoding;
@property (nonatomic, copy) NSString *outputFilePath;
@property (nonatomic, copy) NSString *preambleStr;
@property (nonatomic, assign) float resolutionLevel;
@property (nonatomic, assign) NSInteger dpi;
@property (nonatomic, assign) BOOL guessCompilation;
@property (nonatomic, assign) NSInteger numberOfCompilation;
@property (nonatomic, assign) BOOL leaveTextFlag, transparentFlag, plainTextFlag, deleteDisplaySizeFlag, mergeOutputsFlag, showOutputWindowFlag, sendNotificationFlag, previewFlag, deleteTmpFileFlag, autoPasteFlag, embedInIllustratorFlag, ungroupFlag, ignoreErrorsFlag, utfExportFlag, quietFlag;
@property (nonatomic, assign) AutoPasteDestination autoPasteDestination;
@property (nonatomic, strong) NSObject<OutputController> *controller;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, assign) NSInteger workingDirectoryType;
@property (nonatomic, copy) NSString *workingDirectory;
@property (nonatomic, assign) pid_t pid;
@property (nonatomic, copy) NSString *tempFileBaseName;
@property (nonatomic, copy) NSString *epstopdfPath;
@property (nonatomic, copy) NSString *mudrawPath;
@property (nonatomic, copy) NSString *pdftopsPath;
@property (nonatomic, assign) NSUInteger pageCount;
@property (nonatomic, assign) BOOL useBP;
@property (nonatomic, assign) BOOL speedPriorityMode;
@property (nonatomic, assign) BOOL embedSource;
@property (nonatomic, assign) BOOL copyToClipboard;
@property (nonatomic, copy) NSString *additionalInputPath;
@property (nonatomic, assign) BOOL pdfInputMode;
@property (nonatomic, assign) BOOL psInputMode;
@property (nonatomic, assign) BOOL errorsIgnored;
@property (nonatomic, assign) float delay;
@property (nonatomic, assign) NSInteger loopCount;
@property (nonatomic, copy) NSNumber *usingNewGsFlag; // nilable BOOL として使用
@property (nonatomic, copy) NSMutableArray<NSNumber*> *emptyPageFlags;
@property (nonatomic, copy) NSMutableArray<NSNumber*> *whitePageFlags;
@property (nonatomic, copy) NSMutableDictionary<NSString*,NSString*> *bboxDictionary;
@property (nonatomic, copy) NSColor *fillColor;
@end

@implementation Converter
@synthesize latexPath;
@synthesize dviDriverPath;
@synthesize gsPath;
@synthesize encoding;
@synthesize outputFilePath;
@synthesize preambleStr;
@synthesize resolutionLevel;
@synthesize dpi;
@synthesize guessCompilation;
@synthesize leftMargin, rightMargin, topMargin, bottomMargin, numberOfCompilation;
@synthesize leaveTextFlag, transparentFlag, plainTextFlag, deleteDisplaySizeFlag, mergeOutputsFlag, keepPageSizeFlag, showOutputWindowFlag, sendNotificationFlag, previewFlag, deleteTmpFileFlag, autoPasteFlag, embedInIllustratorFlag, ungroupFlag, ignoreErrorsFlag, utfExportFlag, quietFlag;
@synthesize autoPasteDestination;
@synthesize controller;
@synthesize fileManager;
@synthesize workingDirectoryType;
@synthesize workingDirectory;
@synthesize pid;
@synthesize tempFileBaseName;
@synthesize epstopdfPath;
@synthesize mudrawPath;
@synthesize pdftopsPath;
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
@synthesize delay;
@synthesize loopCount;
@synthesize usingNewGsFlag;
@synthesize emptyPageFlags;
@synthesize whitePageFlags;
@synthesize bboxDictionary;
@synthesize fillColor;

- (instancetype)initWithProfile:(Profile*)aProfile
{
    pageCount = 1;
    
    latexPath = [aProfile stringForKey:LatexPathKey];
    dviDriverPath = [aProfile stringForKey:DviDriverPathKey];
    gsPath = [aProfile stringForKey:GsPathKey];
    epstopdfPath = [aProfile stringForKey:EpstopdfPathKey];
    mudrawPath = [aProfile stringForKey:MudrawPathKey];
    pdftopsPath = [aProfile stringForKey:PdftopsPathKey];
    guessCompilation = [aProfile boolForKey:GuessCompilationKey];
    numberOfCompilation = [aProfile integerForKey:NumberOfCompilationKey];
    
    outputFilePath = [aProfile stringForKey:OutputFileKey].stringByStandardizingPath;
    preambleStr = [aProfile stringForKey:PreambleKey];
    
    encoding = [aProfile stringForKey:EncodingKey];
    resolutionLevel = [aProfile floatForKey:ResolutionKey] / RESOLUTION_SCALE;
    dpi = [aProfile integerForKey:DPIKey];
    leftMargin = [aProfile integerForKey:LeftMarginKey];
    rightMargin = [aProfile integerForKey:RightMarginKey];
    topMargin = [aProfile integerForKey:TopMarginKey];
    bottomMargin = [aProfile integerForKey:BottomMarginKey];
    leaveTextFlag = ![aProfile boolForKey:GetOutlineKey];
    transparentFlag = [aProfile boolForKey:TransparentKey];
    plainTextFlag = [aProfile boolForKey:PlainTextKey];
    deleteDisplaySizeFlag = [aProfile boolForKey:DeleteDisplaySizeKey];
    mergeOutputsFlag = [aProfile boolForKey:MergeOutputsKey];
    keepPageSizeFlag = [aProfile boolForKey:KeepPageSizeKey];
    showOutputWindowFlag = [aProfile boolForKey:ShowOutputWindowKey];
    sendNotificationFlag = [aProfile boolForKey:SendNotificationKey];
    previewFlag = [aProfile boolForKey:PreviewKey];
    deleteTmpFileFlag = [aProfile boolForKey:DeleteTmpFileKey];
    copyToClipboard = [aProfile boolForKey:CopyToClipboardKey];
    autoPasteFlag = [aProfile boolForKey:AutoPasteKey];
    autoPasteDestination = (AutoPasteDestination)[aProfile integerForKey:AutoPasteDestinationKey];
    embedInIllustratorFlag = [aProfile boolForKey:EmbedInIllustratorKey];
    ungroupFlag = [aProfile boolForKey:UngroupKey];
    ignoreErrorsFlag = [aProfile boolForKey:IgnoreErrorKey];
    utfExportFlag = [aProfile boolForKey:UtfExportKey];
    quietFlag = [aProfile boolForKey:QuietKey];
    controller = aProfile[ControllerKey];
    useBP = ([aProfile integerForKey:UnitKey] == BP_UNIT_TAG);
    speedPriorityMode = ([aProfile integerForKey:PriorityKey] == SPEED_PRIORITY_TAG);
    embedSource = [aProfile boolForKey:EmbedSourceKey];
    pageBoxType = (CGPDFBox)[aProfile integerForKey:PageBoxKey];
    delay = [aProfile floatForKey:DelayKey];
    loopCount = [aProfile integerForKey:LoopCountKey];
    fillColor = [aProfile colorForKey:FillColorKey];
    workingDirectoryType = [aProfile integerForKey:WorkingDirectoryTypeKey];

    switch (workingDirectoryType) {
        case WorkingDirectoryCurrent:
            workingDirectory = [aProfile stringForKey:WorkingDirectoryPathKey];
            break;
        default:
            workingDirectory = NSTemporaryDirectory();
            break;
    }

    usingNewGsFlag = nil;
    additionalInputPath = nil;
    pdfInputMode = NO;
    psInputMode = NO;
    errorsIgnored = NO;
    
	fileManager = NSFileManager.defaultManager;
    
	tempFileBaseName = [NSString stringWithFormat:@"temp%d-%@", getpid(), NSString.UUIDString];
    
    bboxDictionary = [NSMutableDictionary<NSString*,NSString*> dictionary];
	
	return self;
}

+ (instancetype)converterWithProfile:(Profile*)aProfile
{
	return [[Converter alloc] initWithProfile:aProfile];
}

- (void)exitCurrentThread
{
    [NSThread.currentThread cancel];
    if (NSThread.currentThread.isCancelled) {
        [self deleteTemporaryFiles];
        [controller generationDidFinish:ExitStatusAborted];
        [NSThread exit];
    }
}


// JIS X 0208 外の文字を \UTF に置き換える
- (NSMutableString*)substituteUTF:(NSString*)dataString
{
    return [NSMutableString stringWithString:dataString.stringByReplacingUnicodeCharactersWithUTF];
}


// 文字列の円マーク・バックスラッシュを全てバックスラッシュに統一してファイルに書き込む。
// 返り値：書き込みの正否(BOOL)
- (BOOL)writeStringWithYenBackslashConverting:(NSString*)targetString
                                       toFile:(NSString*)path
{
    NSMutableString *mstr = [NSMutableString string];
	[mstr appendString:targetString];
	
	[mstr replaceYenWithBackSlash];
		
    if (utfExportFlag) {
        mstr = [self substituteUTF:mstr];
    }
	
	unsigned long enc;
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
    NSMutableString *cmdline = [NSMutableString stringWithFormat:@"export PATH=$PATH:%@:%@;",
                                latexPath.programPath.stringByDeletingLastPathComponent.stringByQuotingWithDoubleQuotations,
                                gsPath.programPath.stringByDeletingLastPathComponent.stringByQuotingWithDoubleQuotations];
    
    if (additionalInputPath) {
        [cmdline appendFormat:@"export TEXINPUTS=\"%@:`kpsewhich -progname=%@ -expand-var=\\\\$TEXINPUTS`\";", additionalInputPath, latexPath.programName];
    }
    
    return cmdline;
}

- (BOOL)compileWithArguments:(NSArray<NSString*>*)arguments
{
    NSMutableString *cmdline = self.preliminaryCommandsForEnvironmentVariables;
    
    [cmdline appendFormat:@"%@", latexPath];
    
    BOOL status = [controller execCommand:cmdline
                              atDirectory:workingDirectory
                            withArguments:arguments
                                    quiet:quietFlag];
    return status;
}

- (BOOL)tex2dvi:(NSString*)texFilePath
{
    NSMutableArray<NSString*> *arguments = [NSMutableArray arrayWithObject:@"-interaction=nonstopmode"];
 
    if (![encoding isEqualToString:PTEX_ENCODING_NONE]) {
        [arguments addObject:[@"-kanji=" stringByAppendingString:encoding]];
    }
    
    [arguments addObject:texFilePath.stringByQuotingWithDoubleQuotations];
    
    NSString *auxFilePath = [[workingDirectory stringByAppendingPathComponent:tempFileBaseName] stringByAppendingPathExtension:@"aux"];
    
    // まず aux を削除
    if ([fileManager fileExistsAtPath:auxFilePath] && ![fileManager removeItemAtPath:auxFilePath error:nil]) {
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
        if ([oldAuxData isEqualToData:@"\\relax \n".dataUsingUTF8StringEncoding]) {
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

- (BOOL)execDviDriver:(NSString*)dviFilePath
{
    NSMutableString *cmdline = self.preliminaryCommandsForEnvironmentVariables;
    [cmdline appendString:dviDriverPath];
    
	BOOL status = [controller execCommand:cmdline
                              atDirectory:workingDirectory
                            withArguments:@[dviFilePath.stringByQuotingWithDoubleQuotations]
                                    quiet:quietFlag];
	[controller appendOutputAndScroll:@"\n" quiet:quietFlag];	
	
	return status;
}

- (BOOL)ps2pdf:(NSString*)psFilePath
    outputFile:(NSString*)pdfFilePath
{
    NSMutableString *cmdline = self.preliminaryCommandsForEnvironmentVariables;
    [cmdline appendString:gsPath];
    BOOL status = [controller execCommand:cmdline
                              atDirectory:workingDirectory
                            withArguments:@[@"-dSAFER",
                                            @"-dNOPAUSE",
                                            @"-dBATCH",
                                            [@"-sOutputFile=" stringByAppendingString:pdfFilePath.stringByQuotingWithDoubleQuotations],
                                            @"-sDEVICE=pdfwrite",
                                            @"-dCompatibilityLevel=1.5",
                                            @"-dAutoRotatePages=/None",
                                            @"-f",
                                            psFilePath.stringByQuotingWithDoubleQuotations]
                                    quiet:quietFlag];
    [controller appendOutputAndScroll:@"\n" quiet:quietFlag];
    
    if (!status) {
        [controller showExecError:@"Ghostscript"];
    }
    
    return status;
}

- (NSString*)bboxStringOfPdf:(NSString*)pdfPath
                        page:(NSUInteger)page
                       hires:(BOOL)hires
{
    NSString *key = [NSString stringWithFormat:@"%@-%ld-%d", pdfPath.lastPathComponent, page, hires];
    
    if (![bboxDictionary.allKeys containsObject:key]) { // このPDFに対する gs -sDEVICE=bbox の実行が初めてなら
        // gsを実行してBoundingBox情報を取得
        NSString *bboxFileName = [tempFileBaseName stringByAppendingString:@"-bbox"];
        NSString *bboxFilePath = [workingDirectory stringByAppendingPathComponent:bboxFileName];
        
        // 中断ボタンによる中断を可能とするため，あえて controller を通して実行する。
        // この出力は出力ビューの方に流れてしまうので，リダイレクトによってテキストファイル経由でBoundingBox情報を受け取ることにする。
        
        [controller appendOutputAndScroll:@"TeX2img: Getting the bounding box...\n\n" quiet:quietFlag];

        BOOL success = [controller execCommand:gsPath.programPath
                                   atDirectory:workingDirectory
                                 withArguments:@[@"-dBATCH",
                                                 @"-dNOPAUSE",
                                                 @"-sDEVICE=bbox",
                                                 @"-c '<< /WhiteIsOpaque true >> setpagedevice'",
                                                 @"-f",
                                                 pdfPath.lastPathComponent.stringByQuotingWithDoubleQuotations,
                                                 [@"> " stringByAppendingString:bboxFileName],
                                                 ]
                                         quiet:quietFlag];
        
        NSArray<NSString*> *lines = [self extractBoundingBoxLinesFrom:bboxFilePath];
        [fileManager removeItemAtPath:bboxFilePath error:nil];
        
        if (!lines) {
            [controller showExecError:@"Ghostscript"];
            return nil;
        }
        
        // 出力を解析
        NSUInteger currentPage = 0;
        
        for (NSString *line in lines) {
            if ((line.length >= 5) && [[line substringWithRange:NSMakeRange(0, 5)] isEqualToString:@"Page "]) { // "Page "から始まる行について
                currentPage = [line substringFromIndex:5].integerValue;
                success = YES;
                continue;
            }
            if ((line.length >= 14) && [[line substringWithRange:NSMakeRange(0, 14)] isEqualToString:@"%%BoundingBox:"]) { // "%%BoundingBox:"から始まる行について
                bboxDictionary[[NSString stringWithFormat:@"%@-%ld-0", pdfPath.lastPathComponent, currentPage]] = [line stringByAppendingString:@"\n"];
                continue;
            }
            if ((line.length >= 19) && [[line substringWithRange:NSMakeRange(0, 19)] isEqualToString:@"%%HiResBoundingBox:"]) { // "%%HiResBoundingBox:"から始まる行について
                bboxDictionary[[NSString stringWithFormat:@"%@-%ld-1", pdfPath.lastPathComponent, currentPage]] = [line stringByAppendingString:@"\n"];
                continue;
            }
        }

        if (!success) {
            [controller showExecError:@"Ghostscript"];
            return nil;
        }
    }
    
    return bboxDictionary[key];
}

- (BOOL)isEmptyPage:(NSString*)pdfPath
               page:(NSUInteger)page
            success:(BOOL*)success
{
    NSString *bbStr = [self bboxStringOfPdf:pdfPath page:page hires:NO];
    
    if (!bbStr) {
        *success = NO;
        return NO;
    }
    
    *success = YES;
    
    return [bbStr isEqualToString:EMPTY_BBOX];
}

- (BOOL)willEmptyPageBeCreated:(NSString*)pdfPath
                          page:(NSUInteger)page
                       success:(BOOL*)success
{
    BOOL isEmptyPage = [self isEmptyPage:pdfPath page:page success:success];
    
    if (!*success) {
        return NO;
    }
    
    return (!keepPageSizeFlag && isEmptyPage && ((leftMargin + rightMargin == 0) || (topMargin + bottomMargin == 0)));
}


// pdfcrop類似処理
// page に 0 を与えると全ページをクロップした複数ページPDFを生成する。正の値を指定すると，そのページだけをクロップした単一ページPDFを生成する。
- (BOOL)pdfcrop:(NSString*)pdfPath
 outputFileName:(NSString*)outputFileName
           page:(NSUInteger)page
      addMargin:(BOOL)addMargin
       useCache:(BOOL)useCache
 fillBackground:(BOOL)fillBackground
{
    NSString *cropFileBasePath = [NSString stringWithFormat:@"%@-pdfcrop-%ld%d",
                                  [workingDirectory stringByAppendingPathComponent:tempFileBaseName], page, addMargin];
    NSString *cropPdfSourcePath = [cropFileBasePath stringByAppendingPathExtension:@"pdf"];
    
    // 同じものがあれば再利用
    if (useCache && [fileManager fileExistsAtPath:cropPdfSourcePath]) {
        [fileManager removeItemAtPath:outputFileName error:nil];
        return [fileManager copyItemAtPath:cropPdfSourcePath toPath:outputFileName error:nil];
    }
    
    [controller appendOutputAndScroll:@"TeX2img: Adjusting bounding boxes...\n\n" quiet:quietFlag];

    BOOL success = [self generateCroppedPDFOf:pdfPath
                                         page:page
                                           to:cropPdfSourcePath
                                    addMargin:addMargin];
    
    [fileManager removeItemAtPath:outputFileName error:nil];
    
    if (success) {
        if (!useCache || (page > 0)) {
            success = [fileManager moveItemAtPath:cropPdfSourcePath toPath:outputFileName error:nil];
        } else { // 全ページクロップの場合は，他のページで再度使う場合のためにファイルを残しておく
            success = [fileManager copyItemAtPath:cropPdfSourcePath toPath:outputFileName error:nil];
        }
    }
    
    if (!transparentFlag && fillBackground) {
        [PDFDocument fillBackgroundOf:[workingDirectory stringByAppendingPathComponent:outputFileName.lastPathComponent] with:fillColor];
    }

    return success;
    
}

- (BOOL)isUsingNewGS
{
    if (usingNewGsFlag) {
        return usingNewGsFlag.boolValue;
    }
    
    BOOL result = YES;
    
    NSString *gsVerFileName = [tempFileBaseName stringByAppendingString:@"-gsver"];
    NSString *gsVerFilePath = [workingDirectory stringByAppendingPathComponent:gsVerFileName];
    
    // 中断ボタンによる中断を可能とするため，あえて controller を通して実行する。
    // この出力は出力ビューの方に流れてしまうので，リダイレクトによってテキストファイル経由で gs のバージョンを受け取ることにする。
    // https://github.com/doraTeX/TeX2img/issues/40
    BOOL success = [controller execCommand:gsPath.programPath
                               atDirectory:workingDirectory
                             withArguments:@[@"--version", [@"> " stringByAppendingString:gsVerFileName]]
                                     quiet:YES];
    
    if (!success) {
        [controller showExecError:@"Ghostscript"];
        return YES;
    }
    
    NSString *versionString = [NSString stringWithContentsOfFile:gsVerFilePath encoding:NSUTF8StringEncoding error:NULL];
    [fileManager removeItemAtPath:gsVerFilePath error:nil];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d+(?:\\.\\d+)?" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:versionString options:0 range:NSMakeRange(0, versionString.length)];
    
    if (match) {
        double version = [versionString substringWithRange:[match rangeAtIndex:0]].doubleValue;
        if (version < 9.15) {
            result = NO;
        }
    }
    
    usingNewGsFlag = @(result);
    
    return result;
}


- (BOOL)replaceEpsBBox:(NSString*)epsName
         withBBoxOfPdf:(NSString*)pdfName
                  page:(NSUInteger)page
{
    NSString *epsPath = [workingDirectory stringByAppendingPathComponent:epsName];
    NSString *bbStr = [self bboxStringOfPdf:pdfName page:page hires:NO];
    if (!bbStr) {
        return NO;
    }
    if ([bbStr isEqualToString:EMPTY_BBOX]) { // 白紙ページの場合は置換を行わない
        return YES;
    }
    bbStr = [bbStr stringByReplacingOccurrencesOfString:@"%%BoundingBox: " withString:@""];

    NSString *hiresBbStr = [self bboxStringOfPdf:pdfName page:page hires:YES];
    hiresBbStr = hiresBbStr ? [hiresBbStr stringByReplacingOccurrencesOfString:@"%%HiResBoundingBox: " withString:@""] : bbStr;
    
    [self replaceBBoxOfEpsPath:epsPath boundingBox:bbStr hiresBoundingBox:hiresBbStr];
    return YES;
}

- (BOOL)replaceEpsBBoxWithEmptyBBox:(NSString*)epsName
{
    NSString *epsPath = [workingDirectory stringByAppendingPathComponent:epsName];
    NSString *bbStr = @"0 0 0 0\n";
    NSString *hiresBbStr = @"0.000000 0.000000 0.000000 0.000000\n";
    
    [self replaceBBoxOfEpsPath:epsPath boundingBox:bbStr hiresBoundingBox:hiresBbStr];
    return YES;
}

- (BOOL)replaceEpsBBox:(NSString*)epsName
      withPageBoxOfPdf:(NSString*)pdfName
                  page:(NSUInteger)page
{
    PDFPageBox *pageBox = [[PDFPageBox alloc] initWithFilePath:[workingDirectory stringByAppendingPathComponent:pdfName] page:page];
    NSString *epsPath = [workingDirectory stringByAppendingPathComponent:epsName];
    NSString *bbStr = [pageBox bboxStringOf:pageBoxType
                                      hires:NO
                                  addHeader:NO];
    NSString *hiresBbStr = [pageBox bboxStringOf:pageBoxType
                                           hires:YES
                                       addHeader:NO];
    
    [self replaceBBoxOfEpsPath:epsPath boundingBox:bbStr hiresBoundingBox:hiresBbStr];
    return YES;
}


- (BOOL)pdf2eps:(NSString*)pdfName
 outputFileName:(NSString*)epsName
     resolution:(NSInteger)resolution
           page:(NSUInteger)page
{
    NSMutableArray<NSString*> *arguments = [NSMutableArray<NSString*> arrayWithArray:@[@"-dNOPAUSE",
                                                                                       @"-dBATCH",
                                                                                       @"-dAutoRotatePages=/None",
                                                                                       [NSString stringWithFormat:@"-r%ld", resolution],
                                                                                       [NSString stringWithFormat:@"-sOutputFile=%@", epsName.stringByQuotingWithDoubleQuotations],
                                                                                       [NSString stringWithFormat:@"-dFirstPage=%lu", page],
                                                                                       [NSString stringWithFormat:@"-dLastPage=%lu", page],
                                                                                       ]];
    
    BOOL isUsingNewGS = [self isUsingNewGS];
    
    if (isUsingNewGS) {
        [arguments addObject:@"-sDEVICE=eps2write"];
        [arguments addObject:@"-dNoOutputFonts"];
        [arguments addObject:@"-dCompressPages=true"];
        [arguments addObject:@"-dASCII85EncodePages=false"];
    } else {
        [arguments addObject:@"-sDEVICE=epswrite"];
        [arguments addObject:@"-dNOCACHE"];
    }
    
    [arguments addObject:pdfName.stringByQuotingWithDoubleQuotations];

    BOOL status = [controller execCommand:gsPath atDirectory:workingDirectory withArguments:arguments quiet:quietFlag];
    
    if (!status) {
        [controller showExecError:@"Ghostscript"];
        return NO;
    }
    
    BOOL success = YES;
    BOOL isEmpty = [self isEmptyPage:pdfName page:page success:&success];
    
    if (!success) {
        return NO;
    }
    
    if (isEmpty && !keepPageSizeFlag) {
        return [self replaceEpsBBoxWithEmptyBBox:epsName];
    }
    
    if (keepPageSizeFlag) {
        return [self replaceEpsBBox:epsName withPageBoxOfPdf:pdfName page:page];
    } else {
        // 生成したEPSのBBox情報をオリジナルのPDFの gs -sDEVICE=bbox の出力結果で置換する
        // https://github.com/doraTeX/TeX2img/issues/18
        // https://github.com/doraTeX/TeX2img/issues/37
    
        return [self replaceEpsBBox:epsName withBBoxOfPdf:pdfName page:page];
    }
}

- (BOOL)pdf2pdf:(NSString*)pdfName
 outputFileName:(NSString*)outputFileName
     resolution:(NSInteger)resolution
           page:(NSUInteger)page
{
    NSString *pdfOutName = [tempFileBaseName stringByAppendingString:@"-pdfwrite.pdf"];
    NSMutableArray<NSString*> *arguments = [NSMutableArray<NSString*> arrayWithArray:@[@"-dNOPAUSE",
                                                                                       @"-dBATCH",
                                                                                       @"-sDEVICE=pdfwrite",
                                                                                       @"-dCompatibilityLevel=1.5",
                                                                                       @"-dNoOutputFonts",
                                                                                       [NSString stringWithFormat:@"-r%ld", resolution],
                                                                                       [NSString stringWithFormat:@"-sOutputFile=%@", pdfOutName],
                                                                                       [NSString stringWithFormat:@"-dFirstPage=%lu", page],
                                                                                       [NSString stringWithFormat:@"-dLastPage=%lu", page],
                                                                                       @"-dAutoRotatePages=/None",
                                                                                       @"-f",
                                                                                       pdfName
                                                                                       ]];
    
    BOOL status = [controller execCommand:gsPath atDirectory:workingDirectory withArguments:arguments quiet:quietFlag];
    
    if (!status) {
        [controller showExecError:@"Ghostscript"];
        return NO;
    }
    
    NSString *thisOutputPath = [workingDirectory stringByAppendingPathComponent:outputFileName];

    [fileManager removeItemAtPath:thisOutputPath error:nil];
    [fileManager moveItemAtPath:[workingDirectory stringByAppendingPathComponent:pdfOutName]
                         toPath:thisOutputPath
                          error:nil];
 
    return YES;
}


- (BOOL)epstopdf:(NSString*)epsName
  outputFileName:(NSString*)pdfName
{
    if (![controller epstopdfExists]) {
		return NO;
	}
    
    NSString *temporaryOutputPdfFileName = [tempFileBaseName stringByAppendingString:@"-out.pdf"];
	
    // 10.10 以下で --hires を渡すと，その後の Quartz API での処理時に端が欠けてしまうので，10.10 以下では --nohires を渡す
    // https://github.com/doraTeX/TeX2img/issues/58
    NSString *hiresOption;
    if (@available(macOS 10.11, *)) {
        hiresOption = @"--hires";
    } else {
        hiresOption = @"--nohires";
    }
    
	[controller execCommand:[NSString stringWithFormat:@"export PATH=\"%@\";/usr/bin/perl \"%@\"", gsPath.programPath.stringByDeletingLastPathComponent, epstopdfPath]
                atDirectory:workingDirectory
              withArguments:@[[NSString stringWithFormat:@"--outfile=%@", temporaryOutputPdfFileName.stringByQuotingWithDoubleQuotations],
                              hiresOption,
                              epsName]
                      quiet:quietFlag];
    
    NSString *outFilePath = [workingDirectory stringByAppendingPathComponent:pdfName.lastPathComponent];
    [fileManager removeItemAtPath:outFilePath error:nil];
    [fileManager moveItemAtPath:[workingDirectory stringByAppendingPathComponent:temporaryOutputPdfFileName.lastPathComponent]
                         toPath:outFilePath
                          error:nil];
	return YES;
}

- (BOOL)eps2pdf:(NSString*)epsName
 outputFileName:(NSString*)pdfName
      addMargin:(BOOL)addMargin
{
    if (addMargin && (leftMargin + rightMargin + topMargin + bottomMargin > 0)) {
        NSString *trimFileName = [NSString stringWithFormat:@"%@-trim.pdf", epsName.stringByDeletingPathExtension];
        // まず，epstopdf を使って PDF に戻し，次に，pdfcrop類似処理を使って余白を付け加える
        return [self epstopdf:epsName outputFileName:trimFileName] &&
                [self pdfcrop:trimFileName
               outputFileName:pdfName
                         page:0
                    addMargin:YES
                     useCache:NO
               fillBackground:NO];
    } else {
        // epstopdf を使って PDF に戻すのみ
        return [self epstopdf:epsName outputFileName:pdfName];
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
	[fillColor set];
	[NSBezierPath fillRect:NSMakeRect(0, 0, size.width, size.height)];
    [srcImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[backgroundImage unlockFocus];
	return [[NSBitmapImageRep alloc] initWithData:backgroundImage.TIFFRepresentation];
}

- (NSData*)GIF89aDataFromGIF87aData:(NSData*)gif87aData
{
    if (!gif87aData) {
        return  nil;
    }
    
    NSMutableData *gif89aData = [NSMutableData dataWithData:gif87aData];
    const char gif89a = '9';
    [gif89aData replaceBytesInRange:NSMakeRange(4, 1) withBytes:&gif89a];

    return gif89aData;
}

- (BOOL)pdf2image:(NSString*)pdfFilePath
   outputFileName:(NSString*)outputFileName
             page:(NSUInteger)page
             crop:(BOOL)crop
{
	NSString *extension = outputFileName.pathExtension.lowercaseString;
    NSString *cropPdfFilePath = [workingDirectory stringByAppendingPathComponent:[tempFileBaseName stringByAppendingString:@"-image.pdf"]];
    
    BOOL success = YES;
    BOOL isEmpty = [self willEmptyPageBeCreated:pdfFilePath page:page success:&success];
    if (!success) {
        return NO;
    }
    
    if (crop && isEmpty) {
        return YES;
    }

	// PDFのバウンディングボックスで切り取る
    if (crop) {
        BOOL success = [self pdfcrop:pdfFilePath
                      outputFileName:cropPdfFilePath
                                page:0
                           addMargin:NO
                            useCache:YES
                      fillBackground:NO];
        if (!success) {
            [controller showCannotOverwriteError:cropPdfFilePath];
            return NO;
        }
    } else {
        cropPdfFilePath = pdfFilePath;
    }
    
	// PDFの指定ページを読み取り，NSPDFImageRep オブジェクトを作成
	NSData *pageData = [[[PDFDocument alloc] initWithFilePath:cropPdfFilePath] pageAtIndex:(page-1)].dataRepresentation;
    if (!pageData) {
        [controller showFileGenerationError:cropPdfFilePath];
        return NO;
    }

    NSPDFImageRep *pdfImageRep = [[NSPDFImageRep alloc] initWithData:pageData];
    if (!pdfImageRep) {
        [controller showFileGenerationError:cropPdfFilePath];
        return NO;
    }

    [controller appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: PDF → %@ (Page %ld)\n", extension.uppercaseString, page] quiet:quietFlag];

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
    
    if (!(size.height > 0 && size.width > 0)) {
        return NO;
    }
	
	NSImage *image = [[NSImage alloc] initWithSize:size];
	[image lockFocus];
	[pdfImageRep drawInRect:NSMakeRect(thisLeftMargin, thisBottomMargin, width * resolutionLevel, height * resolutionLevel)];
	[image unlockFocus];
	
	// NSImage を TIFF 形式の NSBitmapImageRep に変換する
	NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:image.TIFFRepresentation];

    // 指定のビットマップ形式に変換
    NSData *outputData;
	if ([@"jpg" isEqualToString:extension]) {
		imageRep = [self fillBackground:imageRep];
        outputData = [imageRep representationUsingType:kUTTypeJPEG usingDPI:dpi];
	} else if ([@"png" isEqualToString:extension]) {
		if (!transparentFlag) {
			imageRep = [self fillBackground:imageRep];
		}
        outputData = [imageRep representationUsingType:kUTTypePNG usingDPI:dpi];
    } else if ([@"gif" isEqualToString:extension]) {
        if (!transparentFlag) {
            imageRep = [self fillBackground:imageRep];
        }
        outputData = [self GIF89aDataFromGIF87aData:[imageRep representationUsingType:NSGIFFileType properties:@{}]];
        //outputData = [self GIF89aDataFromGIF87aData:[imageRep representationUsingType:kUTTypeGIF usingDPI:dpi]];
    } else if ([@"tiff" isEqualToString:extension]) {
        if (!transparentFlag) {
            imageRep = [self fillBackground:imageRep];
        }
        outputData = [imageRep representationUsingType:kUTTypeTIFF usingDPI:dpi];
    } else if ([@"bmp" isEqualToString:extension]) {
        imageRep = [self fillBackground:imageRep];
        outputData = [imageRep representationUsingType:kUTTypeBMP usingDPI:dpi];
    }
    NSString *outputPath = [workingDirectory stringByAppendingPathComponent:outputFileName];
	[outputData writeToFile:outputPath atomically:YES];
    
    // 生成物のチェック
    NSImageRep *rep = [NSImageRep imageRepWithContentsOfFile:outputPath];
    if (!rep) {
        [controller showImageSizeError];
        return NO;
    }

    return YES;
}

- (BOOL)pdf2plainTextEps:(NSString*)pdfName
          outputFileName:(NSString*)epsName
                    page:(NSUInteger)page
{
    if (![controller pdftopsExists]) {
        return NO;
    }
    
    NSString *pageStr = @(page).stringValue;
    
    NSArray<NSString*> *arguments = @[@"-f", pageStr, @"-l", pageStr, @"-eps", pdfName, epsName];
    
    return [controller execCommand:pdftopsPath.stringByQuotingWithDoubleQuotations
                       atDirectory:workingDirectory
                     withArguments:arguments
                             quiet:quietFlag];
}


- (BOOL)mergeTIFFFiles:(NSArray<NSString*>*)sourcePaths
                toPath:(NSString*)destPath
{
    NSMutableArray<NSString*> *arguments = [NSMutableArray arrayWithObject:@"-cat"];
    
    [arguments addObjectsFromArray:[sourcePaths mapUsingBlock:^NSString*(NSString *path) {
        return path.stringByQuotingWithDoubleQuotations;
    }]];
    
    [arguments addObject:@"-out"];
    [arguments addObject:destPath.lastPathComponent.stringByQuotingWithDoubleQuotations];
    
    BOOL success = [controller execCommand:@"/usr/bin/tiffutil"
                               atDirectory:workingDirectory
                             withArguments:arguments
                                     quiet:quietFlag];
    if (success) {
        success = [self copyTargetFrom:[workingDirectory stringByAppendingPathComponent:destPath.lastPathComponent] toPath:destPath];
    }
    return success;
}

- (BOOL)generateAnimatedGIFFrom:(NSArray<NSString*>*)sourcePaths
                         toPath:(NSString*)destPath
{
    NSDictionary<NSString*,NSDictionary*> *frameProperties = @{(NSString*)kCGImagePropertyGIFDictionary: @{(NSString*)kCGImagePropertyGIFDelayTime: @(delay)}};
    NSDictionary<NSString*,NSDictionary*> *gifProperties = @{(NSString*)kCGImagePropertyGIFDictionary: @{(NSString*)kCGImagePropertyGIFLoopCount: @(loopCount)}};
    
    __block CFMutableDataRef gifData = CFDataCreateMutable(kCFAllocatorDefault, 0);
    CGImageDestinationRef destination = CGImageDestinationCreateWithData(gifData, kUTTypeGIF, sourcePaths.count, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperties);

    __block BOOL success = YES;
    
    [sourcePaths enumerateObjectsUsingBlock:^(NSString *path, NSUInteger idx, BOOL *stop) {
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:[NSData dataWithContentsOfFile:path]];
        if (rep) {
            CGImageDestinationAddImage(destination, rep.CGImage, (__bridge CFDictionaryRef)frameProperties);
        } else {
            success = NO;
            *stop = YES;
        }
    }];
    
    if (success) {
        CGImageDestinationFinalize(destination);
    
        NSData *animatedData = [NSData dataWithData:(NSData*)CFBridgingRelease(gifData)];
        if (animatedData) {
            animatedData = [self GIF89aDataFromGIF87aData:animatedData];
            if (animatedData) {
                NSString *tempOutPath = [workingDirectory stringByAppendingPathComponent:[tempFileBaseName stringByAppendingString:@"-out.gif"]];
                [fileManager removeItemAtPath:tempOutPath error:nil];
                
                success = [animatedData writeToFile:tempOutPath atomically:YES];
                if (success) {
                    success = [self copyTargetFrom:tempOutPath toPath:destPath];
                }
            } else {
                success = NO;
            }
        } else {
            success = NO;
        }
    }
    
    CFRelease(destination);
        
    return success;
}

- (BOOL)generateAnimatedSVGFrom:(NSArray<NSString*>*)sourcePaths
                         toPath:(NSString*)destPath
{
    NSMutableString __block *result = [NSMutableString string];
    NSMutableArray<NSString*> __block *svgIds = [NSMutableArray<NSString*> array];

    [sourcePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        // 各SVGファイルの内容を取得
        NSMutableString *svg = [NSMutableString stringWithContentsOfFile:path
                                                                encoding:NSUTF8StringEncoding
                                                                   error:NULL];
        
        if (!svg) {
            return;
        }

        // ヘッダ行2行分を削除
        NSMutableArray<NSString*> *lines = [NSMutableArray<NSString*> arrayWithArray:[svg componentsSeparatedByString:@"\n"]];
        [lines removeObjectsInRange:NSMakeRange(0, 2)];
        svg = [NSMutableString stringWithString:[lines componentsJoinedByString:@"\n"]];
        
        // id の定義にプレフックスを付ける
        NSString *idPrefix = [NSString stringWithFormat:@"%@-%ld-",
                              [destPath.lastPathComponent.stringByDeletingPathExtension stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                              idx];
        
        [svg replaceOccurrencesOfString:@" id=\""
                             withString:[NSString stringWithFormat:@" id=\"%@", idPrefix]
                                options:0
                                  range:NSMakeRange(0, svg.length)];

        // id への参照（#から始まり，カラーの16進コードではない）にプレフックスを付ける
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?<!\\&)\\#(?![0-9a-f]{6}(?![0-9a-f]))"
                                                                               options:0
                                                                                 error:nil];
        
        [regex replaceMatchesInString:svg
                              options:0
                                range:NSMakeRange(0, svg.length)
                         withTemplate:[@"#" stringByAppendingString:idPrefix]];
        
        // 全体の svg 要素に一意な id を振る
        NSString *svgId = [idPrefix stringByAppendingString:@"svg"];
        [svgIds addObject:[@"#" stringByAppendingString:svgId]];
        
        [svg replaceFirstOccuarnceOfString:@"<svg "
                                replacment:[NSString stringWithFormat:@"<svg id=\"%@\" ", svgId]];
        
        [result appendString:svg];
    }];
    
    float dur = sourcePaths.count * delay;
    NSString *repeatCount = (loopCount == 0) ? @"indefinite" : @(loopCount).stringValue;
    NSString *svgIdRefs = [svgIds componentsJoinedByString:@";"];
    
    NSString *output = [NSString stringWithFormat:@"<?xml version=\"1.0\" standalone=\"no\"?>\n"
                        @"<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n"
                        @"<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" version=\"1.1\">\n"
                        @"<defs>"
                        @"%@"
                        @"</defs>"
                        @"<use>"
                        @"<animate attributeName=\"xlink:href\" begin=\"0s\" dur=\"%fs\" repeatCount=\"%@\" values=\"%@\" />"
                        @"</use>"
                        @"</svg>",
                        result, dur, repeatCount, svgIdRefs];
    
    NSString *tempOutPath = [workingDirectory stringByAppendingPathComponent:[tempFileBaseName stringByAppendingString:@"-out.svg"]];
    [fileManager removeItemAtPath:tempOutPath error:nil];
    
    if (![output writeToFile:tempOutPath atomically:NO encoding:NSUTF8StringEncoding error:NULL]) {
        return NO;
    }
        
    return [self copyTargetFrom:tempOutPath toPath:destPath];
}

- (BOOL)pdf2svg:(NSString*)pdfFilePath
 outputFileName:(NSString*)svgFilePath
           page:(NSUInteger)page
  skipEmptyPage:(BOOL)skipEmptyPage
{
    if (![controller mudrawExists]) {
        return NO;
    }
    
    if (skipEmptyPage && emptyPageFlags[page-1].boolValue) {
        return YES;
    }
    
    NSArray<NSString*> *arguments = @[@"-o", svgFilePath.stringByQuotingWithDoubleQuotations, pdfFilePath.stringByQuotingWithDoubleQuotations, [NSString stringWithFormat:@"%ld", page]];
    
    BOOL success = [controller execCommand:mudrawPath.stringByQuotingWithDoubleQuotations
                               atDirectory:workingDirectory
                             withArguments:arguments
                                     quiet:quietFlag];
    if (!success) {
        return NO;
    }
    
    // 最近の mudraw はファイル名の後ろにページ番号を付与するので，その形のファイル名のものが生成されていたらそれを除去した形にリネーム
    NSString *outputtedSvgPath = [[svgFilePath.stringByDeletingPathExtension stringByAppendingFormat:@"%ld", page] stringByAppendingPathExtension:@"svg"];
    if ([fileManager fileExistsAtPath:outputtedSvgPath]) {
        NSError *error = nil;
        [fileManager removeItemAtPath:svgFilePath error:nil];
        [fileManager moveItemAtPath:outputtedSvgPath toPath:svgFilePath error:&error];
        if (error) {
            return NO;
        }
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

// PDFを，アウトラインをとったPDFまたはEPSに変換する
- (BOOL)outlinePDF:(NSString*)pdfFileName
intermediateOutlinedFileName:(NSString*)intermediateOutlinedFileName
    outputFileName:(NSString*)outputFileName
              page:(NSUInteger)page
         addMargin:(BOOL)addMargin
          useCache:(BOOL)useCache
    fillBackground:(BOOL)fill
{
    NSString *extension = outputFileName.pathExtension.lowercaseString;
    NSInteger lowResolution = resolutionLevel*((NSInteger)RESOLUTION_SCALE)*2*72;
    NSInteger resolution = speedPriorityMode ? lowResolution : 20016;
    NSString *trimFileName = [NSString stringWithFormat:@"%@-trim.pdf", tempFileBaseName];

    if ([@"eps" isEqualToString:extension]) {
        if ([self isUsingNewGS] && plainTextFlag) { // pdftops 経由の場合
            [self pdfcrop:pdfFileName
           outputFileName:trimFileName
                     page:0
                addMargin:addMargin
                 useCache:useCache
           fillBackground:NO];
            
            BOOL success = YES;
            BOOL isEmpty = [self isEmptyPage:pdfFileName page:page success:&success];
            
            if (!success) {
                return NO;
            }
            
            if (isEmpty) { // 空白ページを経由する場合は pdfwrite が使えない（エラーになる）ので，そこだけpdfcrop類似処理で変換する
                [self pdfcrop:pdfFileName
               outputFileName:intermediateOutlinedFileName
                         page:page
                    addMargin:YES
                     useCache:NO
               fillBackground:NO];
            } else {
                if (![self pdf2pdf:trimFileName outputFileName:intermediateOutlinedFileName resolution:resolution page:page]
                    || ![fileManager fileExistsAtPath:[workingDirectory stringByAppendingPathComponent:intermediateOutlinedFileName]]) {
                    return NO;
                }
            }
            
            if (![self pdf2plainTextEps:intermediateOutlinedFileName outputFileName:outputFileName page:1]) {
                return NO;
            }
        } else { // Ghostscript 経由の場合
            // PDF→EPS の変換の実行（この時点で強制cropされる）
            if (![self pdf2eps:pdfFileName outputFileName:outputFileName resolution:resolution page:page]
                || ![fileManager fileExistsAtPath:[workingDirectory stringByAppendingPathComponent:outputFileName]]) {
                return NO;
            }
        }

    } else if ([@"pdf" isEqualToString:extension]) { // アウトラインを取ったPDFを作成する場合
        BOOL success = YES;
        BOOL isEmpty = [self isEmptyPage:pdfFileName page:page success:&success];
        
        if (!success) {
            return NO;
        }
        
        if (isEmpty) { // 空白ページを経由する場合は epstopdf が使えない（エラーになる）ので，そこだけpdfcrop類似処理で変換する
            [self pdfcrop:pdfFileName
           outputFileName:outputFileName
                     page:page
                addMargin:addMargin
                 useCache:useCache
           fillBackground:NO];
        } else {
            if ([self isUsingNewGS]) { // Ghostscript 9.15 以降の場合は，-sDEVICE=pdfwrite -dNoOutputFonts によって直接アウトライン化PDFを作成する
                [self pdfcrop:pdfFileName
               outputFileName:trimFileName
                         page:page
                    addMargin:addMargin
                     useCache:useCache
               fillBackground:NO];
                
                // PDF→PDF のアウトライン化変換の実行
                if (![self pdf2pdf:trimFileName outputFileName:outputFileName resolution:resolution page:1]
                    || ![fileManager fileExistsAtPath:[workingDirectory stringByAppendingPathComponent:outputFileName]]) {
                    return NO;
                }
            } else {
                // PDF→EPS の変換の実行（この時点で強制cropされる）
                if (![self pdf2eps:pdfFileName outputFileName:intermediateOutlinedFileName resolution:resolution page:page]
                    || ![fileManager fileExistsAtPath:[workingDirectory stringByAppendingPathComponent:intermediateOutlinedFileName]]) {
                    return NO;
                }
                [self eps2pdf:intermediateOutlinedFileName outputFileName:outputFileName addMargin:addMargin];
            }
        }
        if (fill) {
            // 生成したPDFに背景塗りを加える
            if (!transparentFlag) {
                [PDFDocument fillBackgroundOf:[workingDirectory stringByAppendingPathComponent:outputFileName]
                                                    with:fillColor];
            }
        }
    } else {
        return NO;
    }
    
    return YES;
}

// EPSのパスのアウトラインをとる
- (BOOL)modifyEpsForOutliningPaths:(NSString*)epsName
{
    NSData *epsData = [NSData dataWithContentsOfFile:epsName];
    if (!epsData) {
        return NO;
    }
    
    NSMutableData *newData = [NSMutableData dataWithData:@"/oldstroke /stroke load def\n/stroke {strokepath fill} def\n".dataUsingUTF8StringEncoding];
    
    [newData appendData:epsData];
    [newData writeToFile:epsName atomically:NO];
    
    return YES;
}

// PDFをアウトライン化した上で他の形式に変換する
- (BOOL)convertPDF:(NSString*)pdfFileName
intermediateOutlinedFileName:(NSString*)intermediateOutlinedFileName
    outputFileName:(NSString*)outputFileName
              page:(NSUInteger)page
          useCache:(BOOL)useCache
     skipEmptyPage:(BOOL)skipEmptyPage
{
	NSString *extension = outputFileName.pathExtension.lowercaseString;
    NSString *outlinedPdfFileName = [NSString stringWithFormat:@"%@-outline.pdf", tempFileBaseName];
    
    if (!emptyPageFlags || emptyPageFlags.count == 0) {
        [self exitCurrentThread];
    }

    if (skipEmptyPage && emptyPageFlags[page-1].boolValue) {
        return YES;
    }
    
    if ([@"pdf" isEqualToString:extension]) { // アウトラインを取ったPDFを作成する場合
        [self outlinePDF:pdfFileName
intermediateOutlinedFileName:intermediateOutlinedFileName
          outputFileName:outputFileName
                    page:page
               addMargin:YES
                useCache:useCache
          fillBackground:YES];
    } else if ([@"eps" isEqualToString:extension]) { // 最終出力が EPS の場合
        [self outlinePDF:pdfFileName
intermediateOutlinedFileName:outlinedPdfFileName
          outputFileName:intermediateOutlinedFileName
                    page:page
               addMargin:NO
                useCache:useCache
          fillBackground:NO];
        
        // 余白を付け加えるようバウンディングボックスを改変（背景塗りを追加している場合は既に余白が付いているので除く）
        if (transparentFlag && (topMargin + bottomMargin + leftMargin + rightMargin > 0)) {
            [self enlargeBoundingBoxOf:[workingDirectory stringByAppendingPathComponent:intermediateOutlinedFileName]];
        }
        
        // 生成したEPSファイルの名前を最終出力ファイル名へ変更する
        if ([fileManager fileExistsAtPath:outputFileName]) {
            [fileManager removeItemAtPath:outputFileName error:nil];
        }
        [fileManager moveItemAtPath:[workingDirectory stringByAppendingPathComponent:intermediateOutlinedFileName]
                             toPath:outputFileName
                              error:nil];
    } else { // ビットマップ形式出力の場合，PDFのアウトラインをとった上で，それをさらにビットマップ形式に変換する
        [self outlinePDF:pdfFileName
intermediateOutlinedFileName:intermediateOutlinedFileName
          outputFileName:outlinedPdfFileName
                    page:page
               addMargin:NO
                useCache:useCache
          fillBackground:NO];
        
        // PDFを目的の画像ファイルへ変換（ここで余白付与）
        if (![self pdf2image:[workingDirectory stringByAppendingPathComponent:outlinedPdfFileName] outputFileName:outputFileName page:1 crop:NO]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)copyTargetFrom:(NSString*)sourcePath
                toPath:(NSString*)destPath
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

- (void)embedSource:(NSString*)texFilePath
           intoFile:(NSString*)filePath
{
    BOOL isDir;
    if (!embedSource || ![fileManager fileExistsAtPath:texFilePath isDirectory:&isDir] || isDir) {
        return;
    }

    // ソースを取得
    NSData *data = [NSData dataWithContentsOfFile:texFilePath];
    if (!data) {
        return;
    }
    
    // ソース情報を UTF8 文字列に変換
    NSStringEncoding detectedEncoding;
    NSString *contents = [NSString stringWithAutoEncodingDetectionOfData:data detectedEncoding:&detectedEncoding];
    if (!contents) {
        return;
    }
    
    // PDF の場合はアノテーション情報にソースを保存
    NSString *extension = filePath.pathExtension.lowercaseString;
    if ([@"pdf" isEqualToString:extension]) {
        PDFDocument *doc = [[PDFDocument alloc] initWithFilePath:filePath];
        if (!doc) {
            return;
        }
        
        PDFPage *page = [doc pageAtIndex:0];
        if (!page) {
            return;
        }
        
        PDFAnnotation *annotation = [[PDFAnnotationText alloc] initWithBounds:NSZeroRect];
        annotation.shouldDisplay = NO;
        annotation.shouldPrint = NO;
        annotation.contents = [AnnotationHeader stringByAppendingString:contents];
        // annotation.userName にアプリ名を埋め込む方法では，なぜか Preview.app でアノテーション情報を表示させたときにクラッシュしてしまう。
        
        [page addAnnotation:annotation];
        
        [doc writeToFile:filePath];
    }

    // ソース情報を UTF8 で EA に保存（APFSの場合この後ファイルを書き換えるとEAが破損するので注意）
    const char *target = filePath.fileSystemRepresentation;
    const char *val = contents.UTF8String;
    setxattr(target, EA_Key, val, strlen(val), 0, 0);
}

- (NSDate*)fileModificationDateAtPath:(NSString*)filePath
{
    NSDictionary<NSString*,id> *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
    
    if (attributes) {
        return (NSDate*)(attributes[NSFileModificationDate]);
    } else {
        return nil;
    }
}


- (BOOL)convertPDF:(NSString*)pdfFilePath
     toOutlinedSVG:(NSString*)svgFilePath
              page:(NSUInteger)page
{
    NSString *baseName = [tempFileBaseName pathStringByAppendingPageNumber:page];
    NSString *outlinedPdfFileName = [baseName stringByAppendingString:@"-outline.pdf"];
    NSString *croppedPdfFileName = [baseName stringByAppendingString:@"-crop.pdf"];
    NSString *trimmedPdfFileName = [baseName stringByAppendingString:@"-trim.pdf"];
    NSString *tempEpsFileName = [baseName stringByAppendingPathExtension:@"eps"];
    
    if ([self isUsingNewGS]) {
        // まずはpdfcrop類似処理で1ページごとに砕く
        if (![self pdfcrop:pdfFilePath
            outputFileName:croppedPdfFileName
                      page:page
                 addMargin:YES
                  useCache:YES
            fillBackground:NO]) {
            return NO;
        }
        
        // 既にトリミング＋余白付与はしているので，次のアウトライン化段階ではページサイズ維持
        BOOL originalKeppPageSizeFlag = keepPageSizeFlag;
        keepPageSizeFlag = YES;

        // gs pdfwrite でPDF内のフォントをアウトライン化＋Quartzで背景塗り
        if (![self outlinePDF:croppedPdfFileName
 intermediateOutlinedFileName:outlinedPdfFileName
               outputFileName:outlinedPdfFileName
                         page:1
                    addMargin:NO
                     useCache:NO
               fillBackground:YES]) {
            keepPageSizeFlag = originalKeppPageSizeFlag;
            return NO;
        }
        
        keepPageSizeFlag = originalKeppPageSizeFlag;
        
        // 生成した単一ページアウトライン化PDFを mudraw にかけてSVG生成
        [self pdf2svg:outlinedPdfFileName
       outputFileName:svgFilePath
                 page:1
        skipEmptyPage:NO];
        [controller exitCurrentThreadIfTaskKilled];

    } else {
        // まずはpdfcrop類似処理で1ページごとに砕く
        if (![self pdfcrop:pdfFilePath
            outputFileName:croppedPdfFileName
                      page:page
                 addMargin:NO
                  useCache:YES
            fillBackground:NO]) {
            return NO;
        }

        // PDF内のフォントをアウトライン化
        if (![self outlinePDF:croppedPdfFileName
 intermediateOutlinedFileName:tempEpsFileName
               outputFileName:trimmedPdfFileName
                         page:1
                    addMargin:YES
                     useCache:NO
               fillBackground:YES]) {
            return NO;
        }

        // 生成した単一ページアウトライン化PDFを mudraw にかけてSVG生成
        [self pdf2svg:trimmedPdfFileName
       outputFileName:svgFilePath
                 page:1
        skipEmptyPage:NO];
        [controller exitCurrentThreadIfTaskKilled];
    }

    return YES;
}


- (BOOL)gzipSVG:(NSString*)svgPath toSVGZ:(NSString*)svgzPath
{
    return [controller execCommand:@"/usr/bin/gzip"
                       atDirectory:workingDirectory
                     withArguments:@[@"-cfq9",
                                     svgPath.stringByQuotingWithDoubleQuotations,
                                     [@"> " stringByAppendingString:svgzPath.stringByQuotingWithDoubleQuotations]]
                                quiet:quietFlag];
}

- (BOOL)compileAndConvert
{
	NSString *texFilePath = [NSString stringWithFormat:@"%@.tex", [workingDirectory stringByAppendingPathComponent:tempFileBaseName]];
	NSString *dviFilePath = [NSString stringWithFormat:@"%@.dvi", [workingDirectory stringByAppendingPathComponent:tempFileBaseName]];
    NSString *psFilePath  = [NSString stringWithFormat:@"%@.ps",  [workingDirectory stringByAppendingPathComponent:tempFileBaseName]];
	NSString *pdfFilePath = [NSString stringWithFormat:@"%@.pdf", [workingDirectory stringByAppendingPathComponent:tempFileBaseName]];
    NSString *croppedPdfFilePath = [NSString stringWithFormat:@"%@-crop.pdf", [workingDirectory stringByAppendingPathComponent:tempFileBaseName]];
    NSString *pdfFileName = [NSString stringWithFormat:@"%@.pdf", tempFileBaseName];
	NSString *outputEpsFileName = [NSString stringWithFormat:@"%@.eps", tempFileBaseName];
	NSString *outputFileName = outputFilePath.lastPathComponent;
	NSString *extension = outputFilePath.pathExtension.lowercaseString;
    
    if ([@"svgz" isEqualToString:extension]) {
        outputFileName = [outputFileName stringByReplacingPathExtension:@"svg"];
    }
    
    NSDate *texDate, *dviDate, *psDate, *pdfDate;
    BOOL success = NO, compilationSuceeded = NO, requireDviDriver = NO, requireGS = NO;

    errorsIgnored = NO;
    
    [fileManager changeCurrentDirectoryPath:workingDirectory];
    
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
        requireDviDriver = NO;
        
        texDate = [self fileModificationDateAtPath:texFilePath];
        
        if ([fileManager fileExistsAtPath:pdfFilePath]) { // PDF が存在する場合
            pdfDate = [self fileModificationDateAtPath:pdfFilePath];
            if (pdfDate && [pdfDate isNewerThan:texDate]) {
                requireDviDriver = NO; // 新しい PDF が生成されていれば DVI Driver にかける必要なしと見なす
                compilationSuceeded = YES;
            }
        }
        
        if (!compilationSuceeded && [fileManager fileExistsAtPath:dviFilePath]) { // 新しい PDF が存在せず，DVI が存在する場合
            dviDate = [self fileModificationDateAtPath:dviFilePath];
            if (dviDate && [dviDate isNewerThan:texDate]) {
                requireDviDriver = YES; // 新しい PDF が存在せず，新しい DVI が生成されていれば DVI Driver にかける必要ありと見なす
                compilationSuceeded = YES;
            }
        }
        
        if (!compilationSuceeded) {
            [controller showExecError:@"LaTeX"];
            return NO;
        }
        
        // DVI→PDF
        if (requireDviDriver) {
            success = [self execDviDriver:dviFilePath];
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
    
    PDFDocument *pdfDocument = [[PDFDocument alloc] initWithFilePath:pdfFilePath];
    
    if (!pdfDocument) {
        [controller showFileFormatError:pdfFilePath];
        return NO;
    }
    
    pageCount = pdfDocument.pageCount;

    emptyPageFlags = [NSMutableArray<NSNumber*> array];
    for (NSInteger i=1; i<=pageCount; i++) {
        BOOL isEmpty = [self willEmptyPageBeCreated:pdfFilePath page:i success:&success];
        if (!success) {
            break;
        }
        [emptyPageFlags addObject:@(isEmpty)];
    }
    
    if (!success) {
        return NO;
    }

    whitePageFlags = [NSMutableArray<NSNumber*> array];
    for (NSInteger i=1; i<=pageCount; i++) {
        BOOL isWhite = [self isEmptyPage:pdfFilePath page:i success:&success];
        if (!success) {
            break;
        }
        [whitePageFlags addObject:@(isWhite && !(emptyPageFlags[i-1].boolValue))];
    }

    if (!success) {
        return NO;
    }

    // PDFから各形式に変換
    
    // 最終出力がビットマップ形式で「速度優先」の場合は，PDFからQuartzで直接変換
    if ([@[@"jpg", @"png", @"gif", @"tiff", @"bmp"] containsObject:extension] && speedPriorityMode) {
        for (NSUInteger i=1; i<=pageCount; i++) {
            success = [self pdf2image:pdfFilePath outputFileName:[outputFileName pathStringByAppendingPageNumber:i] page:i crop:YES];
            [controller exitCurrentThreadIfTaskKilled];
            if (!success) {
                return success;
            }
        }
	} else if ([@"pdf" isEqualToString:extension] && leaveTextFlag) { // 最終出力が文字埋め込み PDF の場合，ghostscript を経由しなくてよいので，pdfcrop類似処理で直接生成する。
        // 1ページずつバラバラにpdfcrop類似処理にかける
        for (NSUInteger i=1; i<=pageCount; i++) {
            success = [self pdfcrop:pdfFilePath
                     outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                               page:i
                          addMargin:YES
                           useCache:NO
                     fillBackground:!transparentFlag];
            [controller exitCurrentThreadIfTaskKilled];
            if (!success) {
                return success;
            }
        }
    } else if (([@"svg" isEqualToString:extension] || [@"svgz" isEqualToString:extension])
               && leaveTextFlag
               && !(mergeOutputsFlag && (pageCount - emptyPageFlags.indexesOfTrueValue.count > 1))) { // 最終出力がテキスト保持 SVG の場合，pdfcrop類似処理をかけてから1ページずつ mudraw にかける
        if (transparentFlag) { // 透過SVG生成の場合
            // まずは全ページ一括で，pdfcrop類似処理でクロップ＋余白付与
            [self pdfcrop:pdfFilePath
           outputFileName:croppedPdfFilePath
                     page:0
                addMargin:YES
                 useCache:YES
           fillBackground:NO];
            [controller exitCurrentThreadIfTaskKilled];
            
            // クロップ済みPDFから1ページずつ mudraw にかけてSVGを生成
            for (NSUInteger i=1; i<=pageCount; i++) {
                success = [self pdf2svg:croppedPdfFilePath
                         outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                                   page:i
                          skipEmptyPage:YES];
                [controller exitCurrentThreadIfTaskKilled];
                if (!success) {
                    return success;
                }
            }
        } else { // SVGの背景塗りを行う場合，背景塗りがマルチページPDFに未対応のため，1ページずつpdfcrop類似処理を分けて行い，その結果をそれぞれ mudraw にかける
            // まずは1ページのみ切り出して pdfcrop類似処理でクロップ＋余白付与
            [self pdfcrop:pdfFilePath
           outputFileName:croppedPdfFilePath
                     page:1
                addMargin:YES
                 useCache:NO
           fillBackground:YES];
            [controller exitCurrentThreadIfTaskKilled];
            
            // クロップ済み単一ページPDFを mudraw にかけてSVGを生成
            for (NSUInteger i=1; i<=pageCount; i++) {
                [self pdfcrop:pdfFilePath
               outputFileName:[croppedPdfFilePath pathStringByAppendingPageNumber:i]
                         page:i
                    addMargin:YES
                     useCache:NO
               fillBackground:YES];
                [controller exitCurrentThreadIfTaskKilled];
                
                success = [self pdf2svg:[croppedPdfFilePath pathStringByAppendingPageNumber:i]
                         outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                                   page:1
                          skipEmptyPage:NO];
                [controller exitCurrentThreadIfTaskKilled];
                if (!success) {
                    return success;
                }
            }
        }
	} else { // ghostscript を用いたアウトライン化を行う形式(EPS/outlined-PDF/ビットマップ形式(画質優先)/アウトライン化SVG/アニメーションSVG)の場合
        if (transparentFlag || [BitmapExtensionsArray containsObject:extension]) { // 透過ベクター形式，またはビットマップ形式の場合
            if ([@"svg" isEqualToString:extension] || [@"svgz" isEqualToString:extension]) {
                for (NSUInteger i=1; i<=pageCount; i++) {
                    if (emptyPageFlags[i-1].boolValue) {
                        continue;
                    }
                    success = [self convertPDF:pdfFileName
                                 toOutlinedSVG:[outputFileName pathStringByAppendingPageNumber:i]
                                          page:i];
                    [controller exitCurrentThreadIfTaskKilled];
                    if (!success) {
                        return success;
                    }
                }
            } else { // SVG以外の透過ベクター形式，またはビットマップ形式の場合
                // 透過PDFを pdfwrite 経由または epswrite 経由で透過ベクター形式またはビットマップ形式に変換する
                if ([self isUsingNewGS]) {
                    if ([@"eps" isEqualToString:extension]) { // eps2write による出力時には，ページごとにばらしてPDFロンダリングする
                        for (NSUInteger i=1; i<=pageCount; i++) {
                            if (emptyPageFlags[i-1].boolValue) {
                                continue;
                            }
                            
                            // まずはpdfcrop類似処理で余白ありテキスト保持PDFを作る
                            NSString *croppedFile = [croppedPdfFilePath pathStringByAppendingPageNumber:i];
                            [self pdfcrop:pdfFilePath
                           outputFileName:croppedFile
                                     page:i
                                addMargin:NO
                                 useCache:NO
                           fillBackground:NO];
                            [controller exitCurrentThreadIfTaskKilled];
                            
                            // 次に単一ページのテキスト保持PDFを透過ベクター形式またはビットマップ形式に変換する
                            success = [self convertPDF:croppedFile.lastPathComponent
                          intermediateOutlinedFileName:[outputEpsFileName pathStringByAppendingPageNumber:i]
                                        outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                                                  page:1
                                              useCache:NO
                                         skipEmptyPage:NO];
                            [controller exitCurrentThreadIfTaskKilled];
                            if (!success) {
                                return success;
                            }
                        }
                    } else { // Ghostscript 9.15 以上を利用していて，EPS以外の透過ベクター形式，またはビットマップ形式を出力する場合
                        for (NSUInteger i=1; i<=pageCount; i++) {
                            success = [self convertPDF:pdfFileName
                          intermediateOutlinedFileName:[outputEpsFileName pathStringByAppendingPageNumber:i]
                                        outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                                                  page:i
                                              useCache:YES
                                         skipEmptyPage:YES];
                            [controller exitCurrentThreadIfTaskKilled];
                            if (!success) {
                                return success;
                            }
                        }
                    }
                } else { // epswrite を経由する際には，ページごとにばらしてPDFロンダリングする
                    for (NSUInteger i=1; i<=pageCount; i++) {
                        if (emptyPageFlags[i-1].boolValue) {
                            continue;
                        }
                        
                        // まずはpdfcrop類似処理で余白ありテキスト保持PDFを作る
                        NSString *croppedFile = [croppedPdfFilePath pathStringByAppendingPageNumber:i];
                        [self pdfcrop:pdfFilePath
                       outputFileName:croppedFile
                                 page:i
                            addMargin:NO
                             useCache:NO
                       fillBackground:NO];
                        [controller exitCurrentThreadIfTaskKilled];
                        
                        // 次に単一ページのテキスト保持PDFを透過ベクター形式またはビットマップ形式に変換する
                        success = [self convertPDF:croppedFile.lastPathComponent
                      intermediateOutlinedFileName:[outputEpsFileName pathStringByAppendingPageNumber:i]
                                    outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                                              page:1
                                          useCache:NO
                                     skipEmptyPage:NO];
                        [controller exitCurrentThreadIfTaskKilled];
                        if (!success) {
                            return success;
                        }
                    }
                }
            }
        } else { // 背景塗りを行うベクター画像出力場合，背景塗りがマルチページPDFに未対応のため，1ページずつpdfcrop類似処理を分けて行い，その結果をそれぞれ処理する
            if ([@"eps" isEqualToString:extension]) { // 背景塗りのある EPS 画像生成の場合
                for (NSUInteger i=1; i<=pageCount; i++) {
                    if (emptyPageFlags[i-1].boolValue) {
                        continue;
                    }
                    
                    // まずはpdfcrop類似処理で余白ありテキスト保持PDFを作り，その背景を塗る
                    NSString *croppedFile = [croppedPdfFilePath pathStringByAppendingPageNumber:i];
                    
                    [self pdfcrop:pdfFilePath
                   outputFileName:croppedFile
                             page:i
                        addMargin:YES
                         useCache:NO
                   fillBackground:YES];
                    [controller exitCurrentThreadIfTaskKilled];
                    
                    // 次に余白あり・背景塗りあり・単一ページのテキスト保持PDFを，Ghostscript でEPSに変換する
                    success = [self convertPDF:croppedFile.lastPathComponent
                  intermediateOutlinedFileName:[outputEpsFileName pathStringByAppendingPageNumber:i]
                                outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                                          page:1
                                      useCache:NO
                                 skipEmptyPage:NO];
                    [controller exitCurrentThreadIfTaskKilled];
                    if (!success) {
                        return success;
                    }
                }
            } else if ([@"pdf" isEqualToString:extension]) { // 背景塗りのあるPDF生成の場合
                for (NSUInteger i=1; i<=pageCount; i++) {
                    if (emptyPageFlags[i-1].boolValue) {
                        continue;
                    }
                    
                    if (whitePageFlags[i-1].boolValue) { // 白紙ページの場合はEPSを経由させない
                        if ([@"pdf" isEqualToString:extension]) {
                            [self pdfcrop:pdfFilePath
                           outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                                     page:i
                                addMargin:YES
                                 useCache:NO
                           fillBackground:!transparentFlag];
                        }
                    } else { // 白紙ページでない場合
                        // まずはpdfcrop類似処理で余白なし・テキスト保持・単一ページPDFを切り出す
                        [self pdfcrop:pdfFilePath
                       outputFileName:[croppedPdfFilePath pathStringByAppendingPageNumber:i]
                                 page:i
                            addMargin:NO
                             useCache:NO
                       fillBackground:NO];
                        [controller exitCurrentThreadIfTaskKilled];
                        
                        // 次に余白なし・背景塗りなし・単一ページのテキスト保持PDFを，余白なし透過アウトライン化PDF経由で背景塗りのあるPDFまたはアウトライン化SVG/アニメーションSVGに変換する
                        success = [self convertPDF:[croppedPdfFilePath.lastPathComponent pathStringByAppendingPageNumber:i]
                      intermediateOutlinedFileName:[outputEpsFileName pathStringByAppendingPageNumber:i]
                                    outputFileName:[outputFileName pathStringByAppendingPageNumber:i]
                                              page:1
                                          useCache:NO
                                     skipEmptyPage:NO];
                        [controller exitCurrentThreadIfTaskKilled];
                        if (!success) {
                            return success;
                        }
                    }
                }
            } else if ([@"svg" isEqualToString:extension] || [@"svgz" isEqualToString:extension]) { // 背景塗りのあるアウトライン化SVG/アニメーションSVG生成の場合
                for (NSUInteger i=1; i<=pageCount; i++) {
                    if (emptyPageFlags[i-1].boolValue) {
                        continue;
                    }
                    success = [self convertPDF:pdfFileName
                                 toOutlinedSVG:[outputFileName pathStringByAppendingPageNumber:i]
                                          page:i];
                    [controller exitCurrentThreadIfTaskKilled];
                    if (!success) {
                        return success;
                    }
                }
            }
        }
    }

    // 単一PDF出力/マルチページTIFF/アニメーションGIF/アニメーションSVG出力の場合
    if ([MergeableExtensionsArray containsObject:extension] && mergeOutputsFlag) {
        // 実際に生成したファイルのパスを集める
        NSMutableArray<NSString*> *outputFiles = [NSMutableArray<NSString*> array];
        
        for (NSUInteger i=1; i<=pageCount; i++) {
            if (!(emptyPageFlags[i-1].boolValue)) {
                [outputFiles addObject:[workingDirectory stringByAppendingPathComponent:[outputFileName pathStringByAppendingPageNumber:i]]];
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
            
            if (outputFiles.count > 1) {
                [controller appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: Merging %@s...\n\n", extension.uppercaseString] quiet:quietFlag];
            }
            
            if ([@"pdf" isEqualToString:extension]) {
                if (outputFiles.count > 1) { // PDFマージ作業の実行
                    NSString *tempOutPath = [workingDirectory stringByAppendingPathComponent:[tempFileBaseName stringByAppendingString:@"-out.pdf"]];
                    [fileManager removeItemAtPath:tempOutPath error:nil];
                    success = [[[PDFDocument alloc] initWithMerging:outputFiles] writeToFile:tempOutPath];
                    if (success) {
                        success = [self copyTargetFrom:tempOutPath toPath:outputFilePath];
                    }
                } else { // 結局1つしかPDFが生成しなかった場合はあえてマージしない
                    success = [self copyTargetFrom:outputFiles[0] toPath:outputFilePath];
                }
                if (!success) {
                    return NO;
                }
            }
            
            if ([@"tiff" isEqualToString:extension]) {
                if (outputFiles.count > 1) { // マルチページTIFFへのマージ
                    success = [self mergeTIFFFiles:outputFiles toPath:outputFilePath];
                } else { // 結局1つしかTIFFが生成しなかった場合はあえてマージしない
                    success = [self copyTargetFrom:outputFiles[0] toPath:outputFilePath];
                }
                if (!success) {
                    return NO;
                }
            }
            
            if ([@"gif" isEqualToString:extension]) {
                if (outputFiles.count > 1) { // アニメーションGIFの生成
                    success = [self generateAnimatedGIFFrom:outputFiles toPath:outputFilePath];
                } else { // 結局1つしかGIFが生成しなかった場合はあえてマージしない
                    success = [self copyTargetFrom:outputFiles[0] toPath:outputFilePath];
                }
                if (!success) {
                    return NO;
                }
            }

            if ([@"svg" isEqualToString:extension] || [@"svgz" isEqualToString:extension]) {
                if (outputFiles.count > 1) { // アニメーションSVGの生成
                    if ([@"svgz" isEqualToString:extension]) {
                        NSString *newSvgPath = [workingDirectory stringByAppendingPathComponent:[tempFileBaseName stringByAppendingString:@"-merge.svg"]];
                        success = [self generateAnimatedSVGFrom:outputFiles toPath:newSvgPath];
                        if (success) {
                            success = [self gzipSVG:newSvgPath toSVGZ:outputFilePath];
                        }
                    } else {
                        success = [self generateAnimatedSVGFrom:outputFiles toPath:outputFilePath];
                    }
                } else { // 結局1つしかSVGが生成しなかった場合はあえてマージしない
                    if ([@"svgz" isEqualToString:extension]) {
                        success = [self gzipSVG:outputFiles[0] toSVGZ:outputFilePath];
                    } else {
                        success = [self copyTargetFrom:outputFiles[0] toPath:outputFilePath];
                    }
                }
                if (!success) {
                    return NO;
                }
            }

            if (success) {
                [self embedSource:texFilePath intoFile:outputFilePath];
            }
            
            // 生成ファイルをクリップボードへコピー
            if (copyToClipboard) {
                NSPasteboard *pboard = NSPasteboard.generalPasteboard;
                [pboard declareTypes:@[NSURLPboardType] owner:nil];
                [pboard clearContents];
                [pboard writeObjects:@[[NSURL fileURLWithPath:outputFilePath]]];
            }
        }

    } else { // バラバラ出力の場合
        // 最終出力ファイルを目的地へコピー
        NSMutableArray<NSURL*> *destURLs = [NSMutableArray<NSURL*> array];
        
        for (NSUInteger i=1; i<=pageCount; i++) {
            if (!(emptyPageFlags[i-1].boolValue)) {
                NSString *destPath = [outputFilePath pathStringByAppendingPageNumber:i];
                [destURLs addObject:[NSURL fileURLWithPath:destPath]];
                
                NSString *origPath = [workingDirectory stringByAppendingPathComponent:[outputFileName pathStringByAppendingPageNumber:i]];
                if ([@"svgz" isEqualToString:extension]) {
                    success = [self gzipSVG:origPath toSVGZ:destPath];
                } else {
                    success = [self copyTargetFrom:origPath toPath:destPath];
                }

                if (success) {
                    [self embedSource:texFilePath intoFile:destPath];
                } else {
                    return NO;
                }
            }
        }
        
        // 生成ファイルをクリップボードへコピー
        if (copyToClipboard) {
            NSPasteboard *pboard = NSPasteboard.generalPasteboard;
            [pboard declareTypes:@[NSURLPboardType] owner:nil];
            
            if (destURLs.count > 0) {
                [pboard clearContents];
                [pboard writeObjects:destURLs];
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
	if (![controller latexExistsAtPath:latexPath.programPath dviDriverPath:dviDriverPath.programPath gsPath:gsPath.programPath]) {
        [controller generationDidFinish:ExitStatusFailed];
		return NO;
	}
	
	NSString *extension = outputFilePath.pathExtension.lowercaseString;

    if (![TargetExtensionsArray containsObject:extension]) {
		[controller showExtensionError];
        [controller generationDidFinish:ExitStatusFailed];
		return NO;
	}
    
    // 一連のコンパイル処理の開始準備
    [controller prepareOutputTextView];
    if (showOutputWindowFlag) {
        [controller showOutputWindow];
    }
    [controller showMainWindow];
    
    // 一連のコンパイル処理を実行
    BOOL status = [self compileAndConvert];

    [controller releaseOutputTextView];
    
    if (!status) {
        [controller generationDidFinish:ExitStatusFailed];
        return NO;
    }
    
    // 生成ファイルを集める
    NSMutableArray<NSString*> *generatedFiles = [NSMutableArray<NSString*> array];
    NSInteger generatedPageCount = pageCount - emptyPageFlags.indexesOfTrueValue.count;
    
    if ([MergeableExtensionsArray containsObject:extension] && mergeOutputsFlag && (generatedPageCount > 0)) {
        [generatedFiles addObject:outputFilePath];
    } else {
        for (NSUInteger i=1; i<=pageCount; i++) {
            if (!(emptyPageFlags[i-1].boolValue)) {
                [generatedFiles addObject:[outputFilePath pathStringByAppendingPageNumber:i]];
            }
        }
    }
    
    // プレビュー処理
    if (status && previewFlag) {
        NSString *previewApp;
        if ([@"gif" isEqualToString:extension] && mergeOutputsFlag && (generatedPageCount > 1)) {
            previewApp = @"/System/Applications/Safari.app";
            if (![fileManager fileExistsAtPath:previewApp]) {
                previewApp = @"/Applications/Safari.app";
            }
        } else if ([@"svgz" isEqualToString:extension]) {
            previewApp = SVG_PREVIEWER;
        } else if ([@"svg" isEqualToString:extension]) {
            previewApp = SVG_PREVIEWER;
            if (![fileManager fileExistsAtPath:previewApp]) {
                previewApp = @"/System/Applications/Safari.app";
                if (![fileManager fileExistsAtPath:previewApp]) {
                    previewApp = @"/Applications/Safari.app";
                }
            }
        } else {
            previewApp = @"/System/Applications/Preview.app";
            if (![fileManager fileExistsAtPath:previewApp]) {
                previewApp = @"/Applications/Preview.app";
            }
        }
        
        NSArray<NSString*> *pathsForPreview = [generatedFiles mapUsingBlock:^NSString*(NSString *path) {
            // macOS 13 Ventura 以降では Preview.app でEPSファイルのプレビューができなくなったことに対応するため，その場合はEPSプレビュー用のPDFを生成
            if (@available(macOS 13, *)) {
                if ([@"eps" isEqualToString:extension]) {
                    NSString *pdfPathForPreview = [NSTemporaryDirectory() stringByAppendingPathComponent:[path.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"pdf"]];
                    [self epstopdf:path outputFileName:pdfPathForPreview];
                    return pdfPathForPreview;
                } else {
                    return path;
                }
            } else {
                return path;
            }
        }];
        
        [controller previewFiles:pathsForPreview withApplication:previewApp];
    }

    // 自動ペースト
    if (status && copyToClipboard && autoPasteFlag && (autoPasteDestination != 0) && (generatedFiles.count > 0)) {
        NSString *script;
        switch (autoPasteDestination) {
        	case apWord:
        		script = [self appleScriptForWord:generatedFiles];
        		break;
        	case apPowerPoint:
                script = [self appleScriptForPowerPoint:generatedFiles];
        		break;
        	case apPages:
                script = [self appleScriptForiWork:@"Pages"];
        		break;
        	case apNumbers:
                script = [self appleScriptForiWork:@"Numbers"];
        		break;
        	case apKeynote:
                script = [self appleScriptForiWork:@"Keynote"];
        		break;
        	default:
        		break;
        }

        [self performSelectorOnMainThread:@selector(runAppleScriptOnMainThread:)
                               withObject:script
                            waitUntilDone:NO];
    }
    
    // Illustrator に配置
    if (status && embedInIllustratorFlag && (generatedFiles.count > 0)) {
        NSMutableString *script = [NSMutableString string];
        [script appendString:@"tell application \"Adobe Illustrator\"\n"];
        [script appendString:@"activate\n"];
        
        [generatedFiles enumerateObjectsUsingBlock:^(NSString *filePath, NSUInteger idx, BOOL *stop) {
            [script appendFormat:@"embed (make new placed item in current document with properties {file path:(POSIX file \"%@\")})\n", filePath];
            if (self.ungroupFlag) {
                [script appendString:@"move page items of selection of current document to end of current document\n"];
            }
        }];
        
        [script appendString:@"end tell\n"];
        [self performSelectorOnMainThread:@selector(runAppleScriptOnMainThread:)
                               withObject:script
                            waitUntilDone:NO];
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
    
    ExitStatus exitStatus = status ? ExitStatusSucceeded : ExitStatusFailed;
    [controller generationDidFinish:exitStatus]; // GUI版の場合はここでも deleteTemporaryFiles が呼び出されるが，CUI版では呼び出されないので二重呼び出しは仕方ない
    
	return status;
}

- (void)deleteTemporaryFiles
{
    if (deleteTmpFileFlag) {
        NSString *outputFileName = outputFilePath.lastPathComponent;
        NSString *basePath = [workingDirectory stringByAppendingPathComponent:tempFileBaseName];
        NSString *extension = outputFilePath.pathExtension.lowercaseString;
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.tex", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.dvi", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.log", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.aux", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.ps", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.pdf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-crop.pdf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-image.pdf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-outline.pdf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.eps", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-trim.pdf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-pdftops.pdf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-pdftops.eps", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-pdfcrop-00.pdf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-pdfcrop-01.pdf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-out.%@", basePath, extension] error:nil];

        if ([@"svgz" isEqualToString:extension]) {
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-out.svg", basePath] error:nil];
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-merge.svg", basePath] error:nil];
            [fileManager removeItemAtPath:[workingDirectory stringByAppendingPathComponent:[outputFileName stringByReplacingPathExtension:@"svg"]]
                                    error:nil];
        }
        
        NSString *outputDir = outputFilePath.stringByDeletingLastPathComponent;
        for (NSUInteger i=1; i<=pageCount; i++) {
            if (![getFullPath(outputDir) isEqualToString:getFullPath(workingDirectory)]) {
                [fileManager removeItemAtPath:[workingDirectory stringByAppendingPathComponent:[outputFileName pathStringByAppendingPageNumber:i]] error:nil];
            } else if ([MergeableExtensionsArray containsObject:outputFilePath.pathExtension] && mergeOutputsFlag && (i>=2)) {
                [fileManager removeItemAtPath:[workingDirectory stringByAppendingPathComponent:[outputFileName pathStringByAppendingPageNumber:i]] error:nil];
            }
            
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-crop-%ld.pdf", basePath, i] error:nil];
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-%ld.eps", basePath, i] error:nil];
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-%ld-outline.pdf", basePath, i] error:nil];
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-%ld-crop.pdf", basePath, i] error:nil];
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-%ld-trim.pdf", basePath, i] error:nil];
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-%ld-pdftops.eps", basePath, i] error:nil];
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-%ld-pdftops.pdf", basePath, i] error:nil];

            if ([@"svgz" isEqualToString:extension]) {
                [fileManager removeItemAtPath:[[workingDirectory stringByAppendingPathComponent:[outputFileName stringByReplacingPathExtension:@"svg"]] pathStringByAppendingPageNumber:i]
                                        error:nil];
            }
        }

        // その他，TeX2img自体が生み出さなくても，TeXコンパイラに渡すエンジンのオプションや，ユーザが用意したコンパイル用補助スクリプトが生み出す可能性がある補助ファイルを削除
        // https://github.com/doraTeX/TeX2img/issues/96
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.bbl", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.bcf", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@-blx.bib", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.blg", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.fls", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.idx", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.ind", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.ilg", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.out", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.run.xml", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.toc", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.synctex", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.synctex.gz", basePath] error:nil];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@.synctex.gz(busy)", basePath] error:nil];

    }
}


- (BOOL)compileAndConvertWithSource:(NSString*)texSourceStr
{
	// TeX ソースを準備
	NSString *tempTeXFilePath = [NSString stringWithFormat:@"%@.tex", [workingDirectory stringByAppendingPathComponent:tempFileBaseName]];
	
	if (![self writeStringWithYenBackslashConverting:texSourceStr toFile:tempTeXFilePath]) {
		[controller showFileGenerationError:tempTeXFilePath];
        [controller generationDidFinish:ExitStatusFailed];
		return NO;
	}
	
	return [self compileAndConvertWithCheck];
}

- (BOOL)compileAndConvertWithBody:(NSString*)texBodyStr
{
    @autoreleasepool {
        // TeX ソースを用意
        NSString *texSourceStr = [NSString stringWithFormat:@"%@\n\\begin{document}\n%@\n\\end{document}", preambleStr, texBodyStr];
        return [self compileAndConvertWithSource:texSourceStr];
    }
}

- (BOOL)compileAndConvertWithInputPath:(NSString*)sourcePath
{
    @autoreleasepool {
        BOOL isDir;
        additionalInputPath = getFullPath(sourcePath).stringByDeletingLastPathComponent;
        if (workingDirectoryType == WorkingDirectoryFile) {
            workingDirectory = additionalInputPath;
        }

        if ([fileManager fileExistsAtPath:sourcePath isDirectory:&isDir] && isDir) {
            [controller showFileFormatError:sourcePath];
            [controller generationDidFinish:ExitStatusFailed];
            return NO;
        }
        
        NSString *ext = sourcePath.pathExtension.lowercaseString;
        pdfInputMode = [ext isEqualToString:@"pdf"];
        psInputMode = [ext isEqualToString:@"ps"] || [ext isEqualToString:@"eps"];
        NSString *basePath = [workingDirectory stringByAppendingPathComponent:tempFileBaseName];
        
        if (pdfInputMode) {
            // PDFの書式チェック
            if (![[PDFDocument alloc] initWithFilePath:sourcePath]) {
                [controller showFileFormatError:sourcePath];
                [controller generationDidFinish:ExitStatusFailed];
                return NO;
            }
            
            NSString *tempPdfFilePath = [basePath stringByAppendingPathExtension:@"pdf"];
            if (![fileManager copyItemAtPath:sourcePath toPath:tempPdfFilePath error:nil]) {
                [controller showFileGenerationError:tempPdfFilePath];
                [controller generationDidFinish:ExitStatusFailed];
                return NO;
            }
        } else if (psInputMode) {
            NSString *tempPsFilePath = [basePath stringByAppendingPathExtension:@"ps"];
            if (![fileManager copyItemAtPath:sourcePath toPath:tempPsFilePath error:nil]) {
                [controller showFileGenerationError:tempPsFilePath];
                [controller generationDidFinish:ExitStatusFailed];
                return NO;
            }
        } else {
            NSString *tempTeXFilePath = [basePath stringByAppendingPathExtension:@"tex"];
            if (![fileManager copyItemAtPath:sourcePath toPath:tempTeXFilePath error:nil]) {
                [controller showFileGenerationError:tempTeXFilePath];
                [controller generationDidFinish:ExitStatusFailed];
                return NO;
            }
        }
        
        return [self compileAndConvertWithCheck];
    }
}

- (NSString*)appleScriptForWord:(NSArray<NSString*>*)paths
{
    NSMutableString *script = [NSMutableString string];
    [script appendString:@"tell application \"Microsoft Word\"\n"];
    [script appendString:@"activate\n"];
    [script appendString:@"if version < 15 then\n"];
    [script appendString:@"tell selection\n"];
    [script appendString:@"set myStart to selection start\n"];
    [script appendString:@"set myEnd to selection end\n"];
    [script appendString:@"end tell\n"];
    [script appendString:@"tell active document\n"];
    [script appendString:@"set theRange to create range start myStart end myEnd\n"];
    
    NSEnumerator *enumerator = paths.reverseObjectEnumerator;
    NSString *posixPath;
    
    while ((posixPath = [enumerator nextObject])) {
        [script appendFormat:@"make new inline picture at theRange with properties {file name:(POSIX file \"%@\") as Unicode text, save with document:true}\n", posixPath];
    }
    
    [script appendString:@"end tell\n"];
    [script appendString:@"else\n"];
    [script appendString:@"tell active document\n"];
    [script appendString:@"tell application \"System Events\" to (keystroke \"v\" using command down)\n"];
    [script appendString:@"end tell\n"];
    [script appendString:@"end if\n"];
    [script appendString:@"end tell\n"];

    return script;
}

- (NSString*)appleScriptForPowerPoint:(NSArray<NSString*>*)paths
{
    NSMutableString *script = [NSMutableString string];
    [script appendString:@"tell application \"Microsoft PowerPoint\"\n"];
    [script appendString:@"activate\n"];
    [script appendString:@"if version < 15 then\n"];
    [script appendString:@"set thisSlide to slide index of slide of view of active window\n"];
    [script appendString:@"tell slide thisSlide of active presentation\n"];
    
    for (NSString *posixPath in paths) {
        [script appendFormat:@"set thePicture to make new picture at end with properties {file name:(POSIX file \"%@\") as Unicode text, save with document:true}\n", posixPath];
        [script appendString:@"tell thePicture\n"];
        [script appendString:@"scale height factor 1 scale scale from top left with relative to original size\n"];
        [script appendString:@"scale width factor 1 scale scale from top left with relative to original size\n"];
        [script appendString:@"end tell\n"];
    }
    
    [script appendString:@"end tell\n"];
    [script appendString:@"else\n"];
    [script appendString:@"tell active presentation\n"];
    [script appendString:@"tell application \"System Events\" to (keystroke \"v\" using command down)\n"];
    [script appendString:@"end tell\n"];
    [script appendString:@"end if\n"];
    [script appendString:@"end tell\n"];
    
    return script;
}

- (NSString*)appleScriptForiWork:(NSString*)appName
{
    NSMutableString *script = [NSMutableString string];

    [script appendFormat:@"tell application \"%@\"\n", appName];
    [script appendString:@"activate\n"];
    [script appendString:@"tell document\n"];
    [script appendString:@"tell application \"System Events\" to (keystroke \"v\" using command down)\n"];
    [script appendString:@"end tell\n"];
    [script appendString:@"end tell\n"];
    
    return script;
}

@end
