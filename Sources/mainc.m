#import <stdio.h>
#import <stdarg.h>
#import <getopt.h>
#import "Converter.h"
#import "ControllerC.h"
#import "global.h"
#import "UtilityC.h"
#import "NSString-Extension.h"
#import "NSDictionary-Extension.h"

#define OPTION_NUM 38
#define VERSION "1.9.8b4"
#define DEFAULT_MAXIMAL_NUMBER_OF_COMPILATION 3

static void version()
{
    printf("tex2img Ver.%s\n", VERSION);
}

static void usage()
{
	version();
    printf("Usage: tex2img [options] InputFile OutputFile\n");
    printf("Arguments:\n");
    printf("  InputFile  : path of a TeX source or PDF file\n");
    printf("  OutputFile : path of an output file\n");
    printf("               (*extension: eps/pdf/svg/jpg/png/gif/tiff/bmp)\n");
    printf("Options:\n");
    printf("  --compiler   COMPILER      : set the LaTeX compiler (default: platex)\n");
    printf("  --kanji ENCODING           : set the Japanese encoding (no|utf8|sjis|jis|euc) (default: no)\n");
    printf("  --[no-]guess-compile       : disable/enable guessing the appropriate number of compilation (default: enabled)\n");
    printf("  --num        NUMBER        : set the (maximal) number of compilation\n");
    printf("  --dvipdfmx   DVIPDFMX      : set dvipdfmx    (default: dvipdfmx)\n");
    printf("  --gs         GS            : set ghostscript (default: gs)\n");
    printf("  --resolution RESOLUTION    : set the resolution level (default: 15)\n");
    printf("  --left-margin    MARGIN    : set the left margin   (default: 0)\n");
    printf("  --right-margin   MARGIN    : set the right margin  (default: 0)\n");
    printf("  --top-margin     MARGIN    : set the top margin    (default: 0)\n");
    printf("  --bottom-margin  MARGIN    : set the bottom margin (default: 0)\n");
    printf("  --unit UNIT                : set the unit of margins to \"px\" or \"bp\" (default: px)\n");
    printf("                               (*bp is always used for EPS/PDF/SVG)\n");
    printf("  --[no-]transparent         : disable/enable transparent PNG/GIF/TIFF (default: enabled)\n");
    printf("  --[no-]with-text           : disable/enable text-embedded PDF (default: disabled)\n");
    printf("  --[no-]delete-display-size : disable/enable deleting width and height attributes of SVG (default: disabled)\n");
    printf("  --[no-]ignore-errors       : disable/enable ignoring nonfatal errors (default: disabled)\n");
    printf("  --[no-]utf-export          : disable/enable substitution of \\UTF{xxxx} for non-JIS X 0208 characters (default: disabled)\n");
    printf("  --[no-]quick               : disable/enable speed priority mode (default: disabled)\n");
    printf("  --[no-]preview             : disable/enable opening products (default: disabled)\n");
    printf("  --[no-]delete-tmpfiles     : disable/enable deleting temporary files (default: enabled)\n");
    printf("  --[no-]embed-source        : disable/enable embedding of the source in products (default: enabled)\n");
    printf("  --[no-]copy-to-clipboard   : disable/enable copying products to the clipboard (default: disabled)\n");
    printf("  --[no-]quiet               : disable/enable quiet mode (default: disabled)\n");
    printf("  --version                  : display version info\n");
    printf("  --help                     : display this message\n");
    exit(1);
}

int strtoi(char *str)
{
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
	
	return (int)val;
}

void printCurrentStatus(NSString *inputFilePath, NSDictionary *aProfile)
{
    printf("************************************\n");
    printf("  TeX2img settings\n");
    printf("************************************\n");
    printf("Input  File: %s\n", inputFilePath.UTF8String);

    NSString *outputFilePath = [aProfile stringForKey:OutputFileKey];
    printf("Output File: %s\n", outputFilePath.UTF8String);
    
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

    NSString *dvipdfmx = [aProfile stringForKey:DvipdfmxPathKey];
    printf("dvipdfmx: %s %s\n", getPath(dvipdfmx.programName).UTF8String, dvipdfmx.argumentsString.UTF8String);

    NSString *gs = [aProfile stringForKey:GsPathKey];
    printf("Ghostscript: %s %s\n", getPath(gs.programName).UTF8String, gs.argumentsString.UTF8String);

    printf("epstopdf: %s\n", getPath([aProfile stringForKey:EpstopdfPathKey]).UTF8String);
    
    NSString *mudrawPath = getPath([aProfile stringForKey:MudrawPathKey]);
    
    printf("mudraw: %s\n", mudrawPath ? mudrawPath.UTF8String : "NOT FOUND");
    
    printf("Resolution level: %f\n", [aProfile floatForKey:ResolutionKey]);
    
    NSString *ext = outputFilePath.pathExtension;
    NSString *unit = (([aProfile integerForKey:UnitKey] == PXUNITTAG) &&
                      ([ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"] || [ext isEqualToString:@"tiff"])) ?
                        @"px" : @"bp";

    printf("Left   margin: %ld%s\n", [aProfile integerForKey:LeftMarginKey], unit.UTF8String);
    printf("Right  margin: %ld%s\n", [aProfile integerForKey:RightMarginKey], unit.UTF8String);
    printf("Top    margin: %ld%s\n", [aProfile integerForKey:TopMarginKey], unit.UTF8String);
    printf("Bottom margin: %ld%s\n", [aProfile integerForKey:BottomMarginKey], unit.UTF8String);

    if ([ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"] || [ext isEqualToString:@"tiff"]) {
        printf("Transparent PNG/GIF/TIFF: %s\n", [aProfile boolForKey:TransparentKey] ? "enabled" : "disabled");
    }
    if ([ext isEqualToString:@"pdf"]) {
        printf("Text embedded PDF: %s\n", [aProfile boolForKey:GetOutlineKey] ? "disabled" : "enabled");
    }
    if ([ext isEqualToString:@"svg"]) {
        printf("Delete width and height attributes of SVG: %s\n", [aProfile boolForKey:DeleteDisplaySizeKey] ? "enabled" : "disabled");
    }
    printf("Ignore nonfatal errors: %s\n", [aProfile boolForKey:IgnoreErrorKey] ? "enabled" : "disabled");
    printf("Substitute \\UTF{xxxx} for non-JIS X 0208 characters: %s\n", [aProfile boolForKey:UtfExportKey] ? "enabled" : "disabled");
    printf("Conversion mode: %s priority mode\n", ([aProfile integerForKey:PriorityKey] == SPEED_PRIORITY_TAG) ? "speed" : "quality" );
    printf("Preview generated files: %s\n", [aProfile boolForKey:PreviewKey] ? "enabled" : "disabled");
    printf("Delete temporary files: %s\n", [aProfile boolForKey:DeleteTmpFileKey] ? "enabled" : "disabled");
    printf("Embed the source in generated files: %s\n", [aProfile boolForKey:EmbedSourceKey] ? "enabled" : "disabled");
    printf("Copy generated files to the clipboard: %s\n", [aProfile boolForKey:CopyToClipboardKey] ? "enabled" : "disabled");

    printf("************************************\n\n");
}

int main (int argc, char *argv[]) {
	@autoreleasepool {
        NSApplicationLoad(); // PDFKit を使ったときに _NXCreateWindow: error setting window property のエラーを防ぐため
        
        float resolutoinLevel = 15;
        int numberOfCompilation = -1;
        int leftMargin = 0;
        int rightMargin = 0;
        int topMargin = 0;
        int bottomMargin = 0;
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
        NSString *encoding = PTEX_ENCODING_NONE;
        NSString *compiler = @"platex";
        NSString *dvipdfmx = @"dvipdfmx";
        NSString *gs       = @"gs";
        NSNumber *unitTag = @(PXUNITTAG);
        
        // getopt_long を使った，長いオプション対応のオプション解析
        struct option *options;
        int option_index;
        int opt;
        
        options = malloc(sizeof(struct option) * OPTION_NUM);
        
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
        options[i].name = "compiler";
        options[i].has_arg = required_argument;
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
        options[i].name = "dvipdfmx";
        options[i].has_arg = required_argument;
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
                        printf("--resolution is wrong.\n");
                        usage();
                    }
                    break;
                case 2: // --left-margin
                    if (optarg) {
                        leftMargin = strtoi(optarg);
                    } else {
                        printf("--left-margin is wrong.\n");
                        usage();
                    }
                    break;
                case 3: // --right-margin
                    if (optarg) {
                        rightMargin = strtoi(optarg);
                    } else {
                        printf("--right-margin is wrong.\n");
                        usage();
                    }
                    break;
                case 4: // --top-margin
                    if (optarg) {
                        topMargin = strtoi(optarg);
                    } else {
                        printf("--top-margin is wrong.\n");
                        usage();
                    }
                    break;
                case 5: // --bottom-margin
                    if (optarg) {
                        bottomMargin = strtoi(optarg);
                    } else {
                        printf("--bottom-margin is wrong.\n");
                        usage();
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
                            printf("--kanji is wrong.\n");
                            usage();
                        }
                    } else {
                        printf("--kanji is wrong.\n");
                        usage();
                    }
                    break;
                case 17: // --quiet
                    quietFlag = YES;
                    break;
                case 18: // --no-quiet
                    quietFlag = NO;
                    break;
                case 19: // --compiler
                    if (optarg) {
                        compiler = @(optarg);
                    } else {
                        printf("--compiler is wrong.\n");
                        usage();
                    }
                    break;
                case 20: // --unit
                    if (optarg) {
                        NSString *unitString = @(optarg);
                        if ([unitString isEqualToString:@"px"]) {
                            unitTag = @(PXUNITTAG);
                        } else if ([unitString isEqualToString:@"bp"]) {
                            unitTag = @(BPUNITTAG);
                        } else {
                            printf("--unit is wrong.\n");
                            usage();
                        }
                    } else {
                        printf("--unit is wrong.\n");
                        usage();
                    }
                    break;
                case 21: // --quick
                    quickFlag = YES;
                    break;
                case 22: // --no-quick
                    quickFlag = NO;
                    break;
                case 23: // --num
                    if (optarg) {
                        numberOfCompilation = strtoi(optarg);
                    } else {
                        printf("--num is wrong.\n");
                        usage();
                    }
                    break;
                case 24: // --guess-compile
                    guessFlag = YES;
                    break;
                case 25: // --no-guess-compile
                    guessFlag = NO;
                    break;
                case 26: // --preview
                    previewFlag = YES;
                    break;
                case 27: // --no-preview
                    previewFlag = NO;
                    break;
                case 28: // --dvipdfmx
                    if (optarg) {
                        dvipdfmx = @(optarg);
                    } else {
                        printf("--dvipdfmx is wrong.\n");
                        usage();
                    }
                    break;
                case 29: // --gs
                    if (optarg) {
                        gs = @(optarg);
                    } else {
                        printf("--gs is wrong.\n");
                        usage();
                    }
                    break;
                case 30: // --embed-source
                    embedSourceFlag = YES;
                    break;
                case 31: // --no-embed-source
                    embedSourceFlag = NO;
                    break;
                case 32: // --delete-display-size
                    deleteDisplaySizeFlag = YES;
                    break;
                case 33: // --no-delete-display-size
                    deleteDisplaySizeFlag = NO;
                    break;
                case 34: // --copy-to-clipboard
                    copyToClipboardFlag = YES;
                    break;
                case 35: // --no-copy-to-clipboard
                    copyToClipboardFlag = NO;
                    break;
                case (OPTION_NUM - 2): // --version
                    version();
                    exit(1);
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
        
        NSString* inputFilePath = @(argv[0]);
        NSString* outputFilePath = getFullPath(@(argv[1]));
        
        if (!quietFlag) {
            version();
        }
        if (![NSFileManager.defaultManager fileExistsAtPath:inputFilePath]) {
            printStdErr("tex2img : %s : No such file or directory\n", inputFilePath.UTF8String);
            exit(1);
        }
        
        // --num が指定されなかった場合のデフォルト値の適用
        if (numberOfCompilation == -1) {
            numberOfCompilation = guessFlag ? DEFAULT_MAXIMAL_NUMBER_OF_COMPILATION : 1;
        }
        
        ControllerC *controller = ControllerC.new;
        
        // 実行プログラムのパスチェック
        NSString *latexPath = getPath(compiler.programPath);
        NSString *dvipdfmxPath = getPath(dvipdfmx.programPath);
        NSString *gsPath = getPath(gs.programPath);
        NSString *epstopdfPath = getPath(@"epstopdf");
        NSString *mudrawPath = getPath(@"mudraw");
        
        if (!latexPath) {
            [controller showNotFoundError:@"LaTeX"];
            return 1;
        }
        if (!dvipdfmxPath) {
            [controller showNotFoundError:@"dvipdfmx"];
            return 1;
        }
        if (!gsPath) {
            [controller showNotFoundError:@"gs"];
            return 1;
        }
        if (!epstopdfPath) {
            [controller showNotFoundError:@"epstopdf"];
            return 1;
        }
        if (!mudrawPath) {
            mudrawPath = @"mudraw";
        }
        
        NSMutableDictionary *aProfile = NSMutableDictionary.dictionary;
        aProfile[LatexPathKey] = [latexPath stringByAppendingStringSeparetedBySpace:compiler.argumentsString];
        aProfile[DvipdfmxPathKey] = [dvipdfmxPath stringByAppendingStringSeparetedBySpace:dvipdfmx.argumentsString];
        aProfile[GsPathKey] = [gsPath stringByAppendingStringSeparetedBySpace:gs.argumentsString];
        aProfile[EpstopdfPathKey] = epstopdfPath;
        aProfile[MudrawPathKey] = mudrawPath;
        
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
        aProfile[DeleteDisplaySizeKey] = @(deleteDisplaySizeFlag);
        aProfile[ShowOutputDrawerKey] = @(NO);
        aProfile[PreviewKey] = @(previewFlag);
        aProfile[DeleteTmpFileKey] = @(deleteTmpFileFlag);
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
        
        if (!quietFlag) {
            printCurrentStatus(inputFilePath, aProfile);
        }
        
        Converter *converter = [Converter converterWithProfile:aProfile];
        BOOL success = [converter compileAndConvertWithInputPath:inputFilePath];
        
        return success ? 0 : 1;
    }
    
}
