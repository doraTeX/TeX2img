#import <stdio.h>
#import <stdarg.h>
#import <getopt.h>
#import <Quartz/Quartz.h>
#import "Converter.h"
#import "ControllerC.h"
#import "global.h"
#import "UtilityC.h"
#import "NSString-Extension.h"
#import "NSDictionary-Extension.h"
#import "NSColor-Extension.h"

#define OPTION_NUM 53
#define VERSION "2.1.7"
#define DEFAULT_MAXIMAL_NUMBER_OF_COMPILATION 3

#define ENABLED "enabled"
#define DISABLED "disabled"

void version()
{
    printf("tex2img Ver.%s\n", VERSION);
}

void usage()
{
    version();
    printf("Usage: tex2img [options] InputFile OutputFile\n");
    printf("\n");
    printf("Arguments:\n");
    printf("  InputFile  : path of a TeX source or PDF/PS/EPS file\n");
    printf("  OutputFile : path of an output file\n");
    printf("               (*extension: eps/pdf/svg/svgz/emf/jpg/png/gif/tiff/bmp)\n");
    printf("\n");
    printf("Conversion Settings:\n");
    printf("  --latex      COMPILER      : set the LaTeX compiler (default: platex)\n");
    printf("   *synonym: --compiler\n");
    printf("  --kanji      ENCODING      : set the Japanese encoding (no|utf8|sjis|jis|euc) (default: no)\n");
    printf("  --[no-]guess-compile       : disable/enable guessing the appropriate number of compilation (default: enabled)\n");
    printf("  --num        NUMBER        : set the (maximal) number of compilation\n");
    printf("  --dvidriver  DRIVER        : set the DVI driver    (default: dvipdfmx)\n");
    printf("   *synonym: --dviware, --dvipdfmx\n");
    printf("  --gs         GS            : set ghostscript (default: gs)\n");
    printf("  --resolution RESOLUTION    : set the resolution level (default: 15)\n");
    printf("  --[no-]ignore-errors       : disable/enable ignoring nonfatal errors (default: disabled)\n");
    printf("  --[no-]utf-export          : disable/enable substitution of \\UTF / \\CID for non-JIS X 0208 characters (default: disabled)\n");
    printf("  --[no-]quick               : disable/enable speed priority mode (default: disabled)\n");
    printf("  --workingdir DIR           : set the working directory (tmp|file|current) (default: tmp)\n");
    printf("   *DIR values:\n");
    printf("      tmp            : Standard user temporary directory ($TMPDIR)\n");
    printf("      file           : The same directory as the input file\n");
    printf("      current        : Current directory\n");
    printf("\n");
    printf("Image Settings:\n");
    printf("  --margins    \"VALUE\"       : set the margins (default: \"0 0 0 0\")\n");
    printf("   *VALUE format:\n");
    printf("      a single value : used for all margins\n");
    printf("      two values     : left/right and top/bottom margins\n");
    printf("      four values    : left, top, right, and bottom margin respectively\n");
    printf("  --left-margin    MARGIN    : set the left margin   (default: 0)\n");
    printf("  --top-margin     MARGIN    : set the top margin    (default: 0)\n");
    printf("  --right-margin   MARGIN    : set the right margin  (default: 0)\n");
    printf("  --bottom-margin  MARGIN    : set the bottom margin (default: 0)\n");
    printf("  --unit UNIT                : set the unit of margins to \"px\" or \"bp\" (default: px)\n");
    printf("                               (*bp is always used for EPS/PDF/SVG/SVGZ/EMF)\n");
    printf("  --[no-]keep-page-size      : disable/enable keeping the original page size (default: disabled)\n");
    printf("  --pagebox BOX              : select the page box type used as the page size (media|crop|bleed|trim|art) (default: crop)\n");
    printf("  --[no-]transparent         : disable/enable transparent (if possible) (default: enabled)\n");
    printf("  --background-color COLOR   : set the background color (default: white)\n");
    printf("   *COLOR format examples:\n");
    printf("      magenta     : CSS-style color name\n");
    printf("      FF00FF      : CSS-style 6-digit HEX format\n");
    printf("      F0F         : CSS-style 3-digit HEX format\n");
    printf("      \"255 0 255\" : RGB integers (0..255)\n");
    printf("\n");
    printf("Image Settings (peculiar to image formats):\n");
    printf("  --[no-]with-text           : disable/enable text-embedded PDF/SVG/SVGZ (default: disabled)\n");
    printf("  --[no-]plain-text          : disable/enable outputting EPS as a plain text (default: disabled)\n");
    printf("  --[no-]merge-output-files  : disable/enable merging products as a single file (PDF/TIFF) or an animation GIF/SVG/SVGZ (default: disabled)\n");
    printf("  --animation-delay TIME     : set the delay time (sec) of an animated GIF/SVG/SVGZ (default: 1)\n");
    printf("  --animation-loop  NUMBER   : set the number of times to repeat an animated GIF/SVG/SVGZ (default: 0 (infinity))\n");
    printf("  --[no-]delete-display-size : disable/enable deleting width and height attributes of SVG/SVGZ (default: disabled)\n");
    printf("\n");
    printf("Behavior After Compiling:\n");
    printf("  --[no-]preview             : disable/enable opening products (default: disabled)\n");
    printf("  --[no-]delete-tmpfiles     : disable/enable deleting temporary files (default: enabled)\n");
    printf("  --[no-]embed-source        : disable/enable embedding of the source in products (default: enabled)\n");
    printf("  --[no-]copy-to-clipboard   : disable/enable copying products to the clipboard (default: disabled)\n");
    printf("\n");
    printf("Other Options:\n");
    printf("  --[no-]quiet               : disable/enable quiet mode (default: disabled)\n");
    printf("  --version                  : display version info\n");
    printf("  --help                     : display this message\n");
    exit(1);
}

NSInteger strtoi(const char * _Nullable str)
{
    if (str == NULL) {
        printStdErr("error : Not a number.\n");
        exit(1);
    }
    
    char *endptr;
    long val;
    
    errno = 0;    /* To distinguish success/failure after call */
    val = strtol(str, &endptr, 10);
    
    if ((errno == ERANGE && (val == LONG_MAX || val == LONG_MIN))
        || (errno != 0 && val == 0)) {
        printStdErr("error : %s cannot be converted to a number.\n", str);
        exit(1);
    }
    
    if (*endptr != '\0') {
        printStdErr("error : %s is not a number.\n", str);
        exit(1);
    }
    
    return (NSInteger)val;
}

void printCurrentStatus(NSString *inputFilePath, Profile *aProfile)
{
    printf("************************************\n");
    printf("  TeX2img settings\n");
    printf("************************************\n");
    printf("Version: %s\n", VERSION);
    printf("Input  file: %s\n", inputFilePath.UTF8String);
    
    NSString *outputFilePath = [aProfile stringForKey:OutputFileKey];
    printf("Output file: %s\n", outputFilePath.UTF8String);
    
    NSString *latex = [aProfile stringForKey:LatexPathKey];
    NSString *encoding = [aProfile stringForKey:EncodingKey];
    NSString *kanji;
    
    if ([encoding isEqualToString:PTEX_ENCODING_NONE]) {
        kanji = @"";
    } else {
        kanji = [@" -kanji=" stringByAppendingString:encoding];
    }
    
    printf("LaTeX compiler: %s%s %s\n", getPath(latex.programName).UTF8String, kanji.UTF8String, latex.argumentsString.UTF8String);
    
    printf("Auto detection of the number of compilation: ");
    if ([aProfile boolForKey:GuessCompilationKey]) {
        printf("enabled\n");
        printf("The maximal number of compilation: %ld\n", [aProfile integerForKey:NumberOfCompilationKey]);
    } else {
        printf("disabled\n");
        printf("The number of compilation: %ld\n", [aProfile integerForKey:NumberOfCompilationKey]);
    }
    
    NSString *dviDriver = [aProfile stringForKey:DviDriverPathKey];
    printf("DVI Driver: %s %s\n", getPath(dviDriver.programName).UTF8String, dviDriver.argumentsString.UTF8String);
    
    NSString *gs = [aProfile stringForKey:GsPathKey];
    printf("Ghostscript: %s %s\n", getPath(gs.programName).UTF8String, gs.argumentsString.UTF8String);
    
    printf("epstopdf: %s\n", getPath([aProfile stringForKey:EpstopdfPathKey]).UTF8String);
    
    NSString *mudrawPath = getPath([aProfile stringForKey:MudrawPathKey]);
    printf("mudraw: %s\n", mudrawPath ? mudrawPath.UTF8String : "NOT FOUND");
    
    NSString *pdftopsPath = getPath([aProfile stringForKey:PdftopsPathKey]);
    printf("pdftops: %s\n", pdftopsPath ? pdftopsPath.UTF8String : "NOT FOUND");
    
    NSString *eps2emfPath = getPath([aProfile stringForKey:Eps2emfPathKey]);
    printf("eps2emf: %s\n", eps2emfPath ? eps2emfPath.UTF8String : "NOT FOUND");

    printf("Working directory: ");
    switch ([aProfile integerForKey:WorkingDirectoryTypeKey]) {
        case WorkingDirectoryTmp:
            printf("%s", NSTemporaryDirectory().UTF8String);
            break;
        case WorkingDirectoryFile:
            printf("%s", getFullPath(inputFilePath).stringByDeletingLastPathComponent.UTF8String);
            break;
        case WorkingDirectoryCurrent:
            printf("%s", NSFileManager.defaultManager.currentDirectoryPath.UTF8String);
            break;
        default:
            break;
    }
    printf("\n");

    printf("Resolution level: %f\n", [aProfile floatForKey:ResolutionKey]);
    
    NSString *ext = outputFilePath.pathExtension;
    NSString *unit = (([aProfile integerForKey:UnitKey] == PX_UNIT_TAG) &&
                      ([ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"] || [ext isEqualToString:@"tiff"])) ?
                        @"px" : @"bp";
    
    printf("Left   margin: %ld%s\n", [aProfile integerForKey:LeftMarginKey], unit.UTF8String);
    printf("Top    margin: %ld%s\n", [aProfile integerForKey:TopMarginKey], unit.UTF8String);
    printf("Right  margin: %ld%s\n", [aProfile integerForKey:RightMarginKey], unit.UTF8String);
    printf("Bottom margin: %ld%s\n", [aProfile integerForKey:BottomMarginKey], unit.UTF8String);
    
    printf("Transparent: %s\n", [aProfile boolForKey:TransparentKey] ? ENABLED : DISABLED);
    printf("Background color: %s\n", [aProfile colorForKey:FillColorKey].descriptionString.UTF8String);
    
    if ([ext isEqualToString:@"pdf"]) {
        printf("Text embedded PDF: %s\n", [aProfile boolForKey:GetOutlineKey] ? DISABLED : ENABLED);
    }
    if ([ext isEqualToString:@"eps"]) {
        printf("Plain text EPS: %s\n", [aProfile boolForKey:PlainTextKey] ? ENABLED : DISABLED);
    }
    if ([ext isEqualToString:@"svg"] || [ext isEqualToString:@"svgz"]) {
        printf("Delete width and height attributes of SVG: %s\n", [aProfile boolForKey:DeleteDisplaySizeKey] ? ENABLED : DISABLED);
    }
    printf("Ignore nonfatal errors: %s\n", [aProfile boolForKey:IgnoreErrorKey] ? ENABLED : DISABLED);
    printf("Substitute \\UTF / \\CID for non-JIS X 0208 characters: %s\n", [aProfile boolForKey:UtfExportKey] ? ENABLED : DISABLED);
    printf("Conversion mode: %s priority mode\n", ([aProfile integerForKey:PriorityKey] == SPEED_PRIORITY_TAG) ? "speed" : "quality" );
    printf("Preview generated files: %s\n", [aProfile boolForKey:PreviewKey] ? ENABLED : DISABLED);
    printf("Delete temporary files: %s\n", [aProfile boolForKey:DeleteTmpFileKey] ? ENABLED : DISABLED);
    printf("Embed the source in generated files: %s\n", [aProfile boolForKey:EmbedSourceKey] ? ENABLED : DISABLED);
    printf("Copy generated files to the clipboard: %s\n", [aProfile boolForKey:CopyToClipboardKey] ? ENABLED : DISABLED);
    
    printf("************************************\n\n");
}

NSArray<id>* generateConverter (int argc, char *argv[]) {
    NSApplicationLoad(); // PDFKit を使ったときに _NXCreateWindow: error setting window property のエラーを防ぐため
    
    float resolutoinLevel = 15;
    NSInteger numberOfCompilation = -1;
    NSInteger leftMargin = 0;
    NSInteger rightMargin = 0;
    NSInteger topMargin = 0;
    NSInteger bottomMargin = 0;
    BOOL textPdfFlag = NO;
    BOOL transparentFlag = YES;
    BOOL deleteDisplaySizeFlag = NO;
    BOOL deleteTmpFileFlag = YES;
    BOOL ignoreErrorFlag = NO;
    BOOL utfExportFlag = NO;
    BOOL quietFlag = NO;
    BOOL quickFlag = NO;
    BOOL guessFlag = YES;
    BOOL previewFlag = NO;
    BOOL copyToClipboardFlag = NO;
    BOOL embedSourceFlag = YES;
    BOOL mergeFlag = NO;
    BOOL keepPageSizeFlag = NO;
    BOOL plainTextFlag = NO;
    NSString *encoding  = PTEX_ENCODING_NONE;
    NSString *latex     = @"platex";
    NSString *dviDriver = @"dvipdfmx";
    NSString *gs        = @"gs";
    NSNumber *unitTag = @(PX_UNIT_TAG);
    CGPDFBox pageBoxType = kCGPDFCropBox;
    float delay = 1;
    NSInteger loopCount = 0;
    NSInteger workingDirectoryType = WorkingDirectoryTmp;
    NSColor *fillColor = NSColor.whiteColor;
    
    // getopt_long を使った，長いオプション対応のオプション解析
    struct option *options;
    int option_index;
    int opt;
    
    options = (struct option*)malloc(sizeof(struct option) * OPTION_NUM);
    
    int i = 0;
    options[i].name = "resolution";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "left-margin";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "right-margin";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "top-margin";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "bottom-margin";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "with-text";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-with-text";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "transparent";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-transparent";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "delete-tmpfiles";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-delete-tmpfiles";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "ignore-errors";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-ignore-errors";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "utf-export";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-utf-export";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "kanji";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "quiet";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-quiet";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "unit";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "quick";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-quick";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "num";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "guess-compile";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-guess-compile";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "preview";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-preview";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "gs";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "embed-source";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-embed-source";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "delete-display-size";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-delete-display-size";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "copy-to-clipboard";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-copy-to-clipboard";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "latex";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "compiler";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "dvidriver";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "dviware";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "dvipdfmx";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "merge-output-files";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-merge-output-files";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "keep-page-size";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-keep-page-size";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "pagebox";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "animation-delay";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "animation-loop";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "margins";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "plain-text";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "no-plain-text";
    options[i].has_arg = no_argument;
    options[i].flag = NULL;
    options[i].val = i+1;
    
    i++;
    options[i].name = "workingdir";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;

    i++;
    options[i].name = "background-color";
    options[i].has_arg = required_argument;
    options[i].flag = NULL;
    options[i].val = i+1;

    options[OPTION_NUM - 3].name = "version";
    options[OPTION_NUM - 3].has_arg = no_argument;
    options[OPTION_NUM - 3].flag = NULL;
    options[OPTION_NUM - 3].val = OPTION_NUM - 2;
    
    options[OPTION_NUM - 2].name = "help";
    options[OPTION_NUM - 2].has_arg = no_argument;
    options[OPTION_NUM - 2].flag = NULL;
    options[OPTION_NUM - 2].val = OPTION_NUM - 1;
    
    // 配列の最後は全てを0にしておく
    options[OPTION_NUM - 1].name = 0;
    options[OPTION_NUM - 1].has_arg = 0;
    options[OPTION_NUM - 1].flag = 0;
    options[OPTION_NUM - 1].val = 0;
    
    while (YES) {
        // オプションの取得
        opt = getopt_long(argc, argv, "", options, &option_index);
        
        // オプション文字が見つからなくなればオプション解析終了
        if (opt == -1) {
            break;
        }
        
        switch (opt) {
            case 0:
                break;
            case 1: // --resolution
                if (optarg) {
                    resolutoinLevel = strtof(optarg, NULL);
                } else {
                    printf("error: --resolution is invalid.\n");
                    exit(1);
                }
                break;
            case 2: // --left-margin
                if (optarg) {
                    leftMargin = strtoi(optarg);
                } else {
                    printf("error: --left-margin is invalid.\n");
                    exit(1);
                }
                break;
            case 3: // --right-margin
                if (optarg) {
                    rightMargin = strtoi(optarg);
                } else {
                    printf("error: --right-margin is invalid.\n");
                    exit(1);
                }
                break;
            case 4: // --top-margin
                if (optarg) {
                    topMargin = strtoi(optarg);
                } else {
                    printf("error: --top-margin is invalid.\n");
                    exit(1);
                }
                break;
            case 5: // --bottom-margin
                if (optarg) {
                    bottomMargin = strtoi(optarg);
                } else {
                    printf("error: --bottom-margin is invalid.\n");
                    exit(1);
                }
                break;
            case 6: // --with-text
                textPdfFlag = YES;
                break;
            case 7: // --no-with-text
                textPdfFlag = NO;
                break;
            case 8: // --transparent
                transparentFlag = YES;
                break;
            case 9: // --no-transparent
                transparentFlag = NO;
                break;
            case 10: // --delete-tmpfiles
                deleteTmpFileFlag = YES;
                break;
            case 11: // --no-delete-tmpfiles
                deleteTmpFileFlag = NO;
                break;
            case 12: // --ignore-errors
                ignoreErrorFlag = YES;
                break;
            case 13: // --no-ignore-errors
                ignoreErrorFlag = NO;
                break;
            case 14: // --utf-export
                utfExportFlag = YES;
                break;
            case 15: // --no-utf-export
                utfExportFlag = NO;
                break;
            case 16: // --kanji
                if (optarg) {
                    encoding = @(optarg);
                    if ([encoding isEqualToString:@"no"]) {
                        encoding = PTEX_ENCODING_NONE;
                    } else if (![encoding isEqualToString:PTEX_ENCODING_UTF8]
                               && ![encoding isEqualToString:PTEX_ENCODING_SJIS]
                               && ![encoding isEqualToString:PTEX_ENCODING_JIS]
                               && ![encoding isEqualToString:PTEX_ENCODING_EUC]) {
                        printf("error: --kanji is invalid. It must be no/utf8/sjis/jis/euc.\n");
                        exit(1);
                    }
                } else {
                    printf("error: --kanji is invalid. It must be no/utf8/sjis/jis/euc.\n");
                    exit(1);
                }
                break;
            case 17: // --quiet
                quietFlag = YES;
                break;
            case 18: // --no-quiet
                quietFlag = NO;
                break;
            case 19: // --unit
                if (optarg) {
                    NSString *unitString = @(optarg);
                    if ([unitString isEqualToString:@"px"]) {
                        unitTag = @(PX_UNIT_TAG);
                    } else if ([unitString isEqualToString:@"bp"]) {
                        unitTag = @(BP_UNIT_TAG);
                    } else {
                        printf("error: --unit is invalid. It must be \"px\" or \"bp\".\n");
                        exit(1);
                    }
                } else {
                    printf("error: --unit is invalid. It must be \"px\" or \"bp\".\n");
                    exit(1);
                }
                break;
            case 20: // --quick
                quickFlag = YES;
                break;
            case 21: // --no-quick
                quickFlag = NO;
                break;
            case 22: // --num
                if (optarg) {
                    numberOfCompilation = strtoi(optarg);
                } else {
                    printf("error: --num is invalid.\n");
                    exit(1);
                }
                break;
            case 23: // --guess-compile
                guessFlag = YES;
                break;
            case 24: // --no-guess-compile
                guessFlag = NO;
                break;
            case 25: // --preview
                previewFlag = YES;
                break;
            case 26: // --no-preview
                previewFlag = NO;
                break;
            case 27: // --gs
                if (optarg) {
                    gs = @(optarg);
                } else {
                    printf("error: --gs is invalid.\n");
                    exit(1);
                }
                break;
            case 28: // --embed-source
                embedSourceFlag = YES;
                break;
            case 29: // --no-embed-source
                embedSourceFlag = NO;
                break;
            case 30: // --delete-display-size
                deleteDisplaySizeFlag = YES;
                break;
            case 31: // --no-delete-display-size
                deleteDisplaySizeFlag = NO;
                break;
            case 32: // --copy-to-clipboard
                copyToClipboardFlag = YES;
                break;
            case 33: // --no-copy-to-clipboard
                copyToClipboardFlag = NO;
                break;
            case 34: // --latex
                if (optarg) {
                    latex = @(optarg);
                } else {
                    printf("error: --latex is invalid.\n");
                    exit(1);
                }
                break;
            case 35: // --compiler (synonym for --latex)
                if (optarg) {
                    latex = @(optarg);
                } else {
                    printf("error: --compiler is invalid.\n");
                    exit(1);
                }
                break;
            case 36: // --dvidriver
                if (optarg) {
                    dviDriver = @(optarg);
                } else {
                    printf("error: --dvidriver is invalid.\n");
                    exit(1);
                }
                break;
            case 37: // --dviware (synonym for --dvidriver)
                if (optarg) {
                    dviDriver = @(optarg);
                } else {
                    printf("error: --dviware is invalid.\n");
                    exit(1);
                }
                break;
            case 38: // --dvipdfmx (synonym for --dvidriver)
                if (optarg) {
                    dviDriver = @(optarg);
                } else {
                    printf("error: --dvipdfmx is invalid.\n");
                    exit(1);
                }
                break;
            case 39: // --merge-output-files
                mergeFlag = YES;
                break;
            case 40: // --no-merge-output-files
                mergeFlag = NO;
                break;
            case 41: // --keep-page-size
                keepPageSizeFlag = YES;
                break;
            case 42: // --no-keep-page-size
                keepPageSizeFlag = NO;
                break;
            case 43: // --pagebox
                if (optarg) {
                    NSString *pageboxString = @(optarg);
                    if ([pageboxString isEqualToString:@"media"]) {
                        pageBoxType = kCGPDFMediaBox;
                    } else if ([pageboxString isEqualToString:@"crop"]) {
                        pageBoxType = kCGPDFCropBox;
                    } else if ([pageboxString isEqualToString:@"bleed"]) {
                        pageBoxType = kCGPDFBleedBox;
                    } else if ([pageboxString isEqualToString:@"trim"]) {
                        pageBoxType = kCGPDFTrimBox;
                    } else if ([pageboxString isEqualToString:@"art"]) {
                        pageBoxType = kCGPDFArtBox;
                    } else {
                        printf("error: --pagebox is invalid. It must be media/crop/bleed/trim/art.\n");
                        exit(1);
                    }
                } else {
                    printf("error: --pagebox is invalid. It must be media/crop/bleed/trim/art.\n");
                    exit(1);
                }
                break;
            case 44: // --animation-delay
                if (optarg) {
                    delay = strtof(optarg, NULL);
                } else {
                    printf("error: --animation-delay is invalid.\n");
                    exit(1);
                }
                if (delay < 0) {
                    printf("error: --animation-delay is invalid.\n");
                    exit(1);
                }
                break;
            case 45: // --animation-loop
                if (optarg) {
                    loopCount = strtoi(optarg);
                } else {
                    printf("error: --animation-loop is invalid.\n");
                    exit(1);
                }
                if (loopCount < 0) {
                    printf("error: --animation-loop is invalid.\n");
                    exit(1);
                }
                break;
            case 46: // --margins
                if (optarg) {
                    NSString *marginsString = @(optarg);
                    NSMutableArray<NSString*> *marginsArray = [NSMutableArray<NSString*> arrayWithArray:[marginsString componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
                    [marginsArray removeObject:@""];
                    switch (marginsArray.count) {
                        case 1:
                            leftMargin = topMargin = rightMargin = bottomMargin = strtoi(marginsArray[0].UTF8String);
                            break;
                        case 2:
                            leftMargin = rightMargin = strtoi(marginsArray[0].UTF8String);
                            topMargin = bottomMargin = strtoi(marginsArray[1].UTF8String);
                            break;
                        case 4:
                            leftMargin   = strtoi(marginsArray[0].UTF8String);
                            topMargin    = strtoi(marginsArray[1].UTF8String);
                            rightMargin  = strtoi(marginsArray[2].UTF8String);
                            bottomMargin = strtoi(marginsArray[3].UTF8String);
                            break;
                        default:
                            printf("error: The number of \"--margins\" values must be 1, 2 or 4.\n");
                            exit(1);
                            break;
                    }
                } else {
                    printf("error: --margins is invalid.\n");
                    exit(1);
                }
                break;
            case 47: // --plain-text
                plainTextFlag = YES;
                break;
            case 48: // --no-plain-text
                plainTextFlag = NO;
                break;
            case 49: // --workingdir
                if (optarg) {
                    NSString *pageboxString = @(optarg);
                    if ([pageboxString isEqualToString:@"tmp"]) {
                        workingDirectoryType = WorkingDirectoryTmp;
                    } else if ([pageboxString isEqualToString:@"file"]) {
                        workingDirectoryType = WorkingDirectoryFile;
                    } else if ([pageboxString isEqualToString:@"current"]) {
                        workingDirectoryType = WorkingDirectoryCurrent;
                    } else {
                        printf("error: --workingdir is invalid. It must be tmp/file/current.\n");
                        exit(1);
                    }
                } else {
                    printf("error: --workingdir is invalid. It must be tmp/file/current.\n");
                    exit(1);
                }
                break;
            case 50: // --background-color
                transparentFlag = NO;
                if (optarg) {
                    NSString *bgcolorString = @(optarg);
                    NSMutableArray<NSString*> *bgcolorArray = [NSMutableArray<NSString*> arrayWithArray:[bgcolorString componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
                    [bgcolorArray removeObject:@""];
                    switch (bgcolorArray.count) {
                        case 1:
                        {
                            NSString *colorValue = bgcolorArray[0].lowercaseString;
                            NSRegularExpression *hexRegex = [[NSRegularExpression alloc] initWithPattern:@"^\\#?([0-9a-f]{6}|[0-9a-f]{3})$"
                                                                                                 options:0
                                                                                                   error:nil];
                            NSArray<NSTextCheckingResult*>* matches = [hexRegex matchesInString:colorValue options:0 range:NSMakeRange(0, colorValue.length)];
                            
                            if (matches.count > 0) {
                                NSRange hexRange = [matches[0] rangeAtIndex:1];
                                unsigned int result = 0;
                                NSScanner *scanner = [NSScanner scannerWithString:[colorValue substringWithRange:hexRange]];
                                [scanner scanHexInt:&result];
                                
                                NSInteger r, g, b;

                                if (hexRange.length == 6) { // #FF00FF 形式のとき
                                    r = result >> 16;
                                    result -= r << 16;
                                    g = result >> 8;
                                    b = result - (g << 8);
                                } else { // #F0F 形式のとき
                                    r = result >> 8;
                                    result -= r << 8;
                                    g = result >> 4;
                                    b = result - (g << 4);
                                    r = (r << 4) + r;
                                    g = (g << 4) + g;
                                    b = (b << 4) + b;
                                }
                                
                                fillColor = [NSColor colorWithDeviceRed:((CGFloat)r)/255
                                                                  green:((CGFloat)g)/255
                                                                   blue:((CGFloat)b)/255
                                                                  alpha:1.0];
                            } else {
                                fillColor = [NSColor colorWithCSSName:colorValue];
                                if (!fillColor) {
                                    printf("error: --background-color is invalid.\n");
                                    exit(1);
                                }
                            }
                        }
                            break;
                        case 3:
                        {
                            NSString *sr = bgcolorArray[0];
                            NSString *sg = bgcolorArray[1];
                            NSString *sb = bgcolorArray[2];
                            NSString *rgb = [NSString stringWithFormat:@"%@%@%@", sr, sg, sb];
                            NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^\\d+$"
                                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                                error:nil];
                            
                            if ([regex rangeOfFirstMatchInString:rgb options:0 range:NSMakeRange(0, rgb.length)].location != NSNotFound) {
                                NSInteger r = sr.integerValue;
                                NSInteger g = sg.integerValue;
                                NSInteger b = sb.integerValue;
                                
                                if (!((r <= 255) && (g <= 255) && (b <=255))) {
                                    printf("error: --background-color is invalid. Each RGB value must be less than 256.\n");
                                    exit(1);
                                }
                                
                                fillColor = [NSColor colorWithDeviceRed:r/255.0
                                                                  green:g/255.0
                                                                   blue:b/255.0
                                                                  alpha:1.0];
                            } else {
                                printf("error: --background-color is invalid.\n");
                                exit(1);
                            }
                        }
                            break;
                        default:
                            printf("error: The number of --background-color values must be 1 or 3.\n");
                            exit(1);
                            break;
                    }
                } else {
                    printf("error: --background-color is invalid.\n");
                    exit(1);
                }
                break;
            case (OPTION_NUM - 2): // --version
                version();
                exit(0);
                break;
            case (OPTION_NUM - 1): // --help
                usage();
                break;
            default:
                usage();
                break;
        }
    }
    
    argc -= optind;
    argv += optind;
    
    if (argc != 2) {
        usage();
    }
    
    NSString *inputFilePath = @(argv[0]);
    NSString *outputFilePath = getFullPath(@(argv[1]));
    
    if (!quietFlag) {
        version();
    }
    if (![NSFileManager.defaultManager fileExistsAtPath:inputFilePath]) {
        printStdErr("tex2img : No such file or directory - %s\n", inputFilePath.UTF8String);
        exit(1);
    }
    if (![InputExtensionsArray containsObject:inputFilePath.pathExtension]) {
        printStdErr("tex2img : Invalid input file type - %s\n", inputFilePath.UTF8String);
        exit(1);
    }
    
    if (!((leftMargin >= 0) && (rightMargin >= 0) && (topMargin >= 0) && (bottomMargin >= 0))) {
        printStdErr("tex2img : Margins must not be negative.\n");
        exit(1);
    }
    
    // --num が指定されなかった場合のデフォルト値の適用
    if (numberOfCompilation == -1) {
        numberOfCompilation = guessFlag ? DEFAULT_MAXIMAL_NUMBER_OF_COMPILATION : 1;
    }
    
    ControllerC *controller = [ControllerC new];
    
    // 実行プログラムのパスチェック
    NSString *latexPath = getPath(latex.programPath);
    NSString *dviDriverPath = getPath(dviDriver.programPath);
    NSString *gsPath = getPath(gs.programPath);
    NSString *epstopdfPath = getPath(@"epstopdf");
    NSString *mudrawPath = getPath(@"mudraw");
    NSString *pdftopsPath = getPath(@"xpdf-pdftops");
    if (!pdftopsPath) {
        pdftopsPath = getPath(@"pdftops");
    }
    
    NSString *eps2emfPath = getPath(@"eps2emf");
    
    if (!latexPath) {
        [controller showNotFoundError:latex.programName];
        suggestLatexOption();
        exit(1);
    }
    if (!dviDriverPath) {
        [controller showNotFoundError:dviDriver.programName];
        exit(1);
    }
    if (!gsPath) {
        [controller showNotFoundError:gs.programName];
        exit(1);
    }
    if (!epstopdfPath) {
        [controller showNotFoundError:@"epstopdf"];
        exit(1);
    }
    if (!mudrawPath) {
        mudrawPath = @"mudraw";
    }
    
    if (!pdftopsPath) {
        pdftopsPath = @"pdftops";
    }
    
    if (!eps2emfPath) {
        eps2emfPath = @"eps2emf";
    }
    
    MutableProfile *aProfile = [MutableProfile dictionary];
    
    aProfile[LatexPathKey] = [latexPath stringByAppendingStringSeparetedBySpace:latex.argumentsString];
    aProfile[DviDriverPathKey] = [dviDriverPath stringByAppendingStringSeparetedBySpace:dviDriver.argumentsString];
    aProfile[GsPathKey] = [gsPath stringByAppendingStringSeparetedBySpace:gs.argumentsString];
    aProfile[EpstopdfPathKey] = epstopdfPath;
    aProfile[MudrawPathKey] = mudrawPath;
    aProfile[PdftopsPathKey] = pdftopsPath;
    aProfile[Eps2emfPathKey] = eps2emfPath;
    aProfile[OutputFileKey] = outputFilePath;
    aProfile[EncodingKey] = encoding;
    aProfile[NumberOfCompilationKey] = @(numberOfCompilation);
    aProfile[ResolutionKey] = @(resolutoinLevel);
    aProfile[LeftMarginKey] = @(leftMargin);
    aProfile[RightMarginKey] = @(rightMargin);
    aProfile[TopMarginKey] = @(topMargin);
    aProfile[BottomMarginKey] = @(bottomMargin);
    aProfile[GetOutlineKey] = @(!textPdfFlag);
    aProfile[TransparentKey] = @(transparentFlag);
    aProfile[FillColorKey] = fillColor.serializedString;
    aProfile[DeleteDisplaySizeKey] = @(deleteDisplaySizeFlag);
    aProfile[ShowOutputDrawerKey] = @(NO);
    aProfile[PreviewKey] = @(previewFlag);
    aProfile[DeleteTmpFileKey] = @(deleteTmpFileFlag);
    aProfile[AutoPasteKey] = @(NO);
    aProfile[AutoPasteDestinationKey] = @(0);
    aProfile[EmbedInIllustratorKey] = @(NO);
    aProfile[UngroupKey] = @(NO);
    aProfile[IgnoreErrorKey] = @(ignoreErrorFlag);
    aProfile[UtfExportKey] = @(utfExportFlag);
    aProfile[QuietKey] = @(quietFlag);
    aProfile[GuessCompilationKey] = @(guessFlag);
    aProfile[ControllerKey] = controller;
    aProfile[UnitKey] = unitTag;
    aProfile[PriorityKey] = quickFlag ? @(SPEED_PRIORITY_TAG) : @(QUALITY_PRIORITY_TAG);
    aProfile[CopyToClipboardKey] = @(copyToClipboardFlag);
    aProfile[EmbedSourceKey] = @(embedSourceFlag);
    aProfile[MergeOutputsKey] = @(mergeFlag);
    aProfile[KeepPageSizeKey] = @(keepPageSizeFlag);
    aProfile[PlainTextKey] = @(plainTextFlag);
    aProfile[PageBoxKey] = @(pageBoxType);
    aProfile[LoopCountKey] = @(loopCount);
    aProfile[DelayKey] = @(delay);
    aProfile[WorkingDirectoryTypeKey] = @(workingDirectoryType);
    aProfile[WorkingDirectoryPathKey] = (workingDirectoryType == WorkingDirectoryCurrent) ? NSFileManager.defaultManager.currentDirectoryPath : @"";
    
    if (!quietFlag) {
        printCurrentStatus(inputFilePath, aProfile);
    }
    
    return @[[Converter converterWithProfile:aProfile], inputFilePath];
}

int main (int argc, char *argv[]) {
    @autoreleasepool {
        NSArray<id> *array = generateConverter(argc, argv);
        Converter *converter = (Converter*)array[0];
        NSString *inputFilePath = (NSString*)array[1];
        BOOL success = [converter compileAndConvertWithInputPath:inputFilePath];
        
        return success ? 0 : 1;
    }
}
