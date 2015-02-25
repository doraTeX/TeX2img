#import <stdio.h>
#import <getopt.h>
#import "Converter.h"
#import "ControllerC.h"
#import "global.h"

#define OPTION_NUM 24
#define MAX_LEN 1024
#define VERSION "1.8.8.1"
#define DEFAULT_MAXIMAL_NUMBER_OF_COMPILATION 3

static void version()
{
    printf("tex2img Ver.%s\n", VERSION);
}

static void usage()
{
	version();
    printf("Usage: tex2img [options] InputTeXFile OutputFile\n");
    printf("Arguments:\n");
    printf("  InputTeXFile            : path of TeX source file\n");
    printf("  OutputFile              : path of output file (extension: eps/png/jpg/pdf)\n");
    printf("Options:\n");
    printf("  --compiler   COMPILER   : set compiler      (default: platex)\n");
    printf("  --guess-compile         : guess the appropriate number of compilation\n");
    printf("  --num        NUMBER     : set the (maximal) number of compilation\n");
    printf("  --dvipdfmx   DVIPDFMX   : set dvipdfmx      (default: dvipdfmx)\n");
    printf("  --gs         GS         : set ghostscript   (default: gs)\n");
    printf("  --resolution RESOLUTION : set resolution level (default: 15)\n");
    printf("  --left-margin    MARGIN : set left margin   (default: 0)\n");
    printf("  --right-margin   MARGIN : set right margin  (default: 0)\n");
    printf("  --top-margin     MARGIN : set top margin    (default: 0)\n");
    printf("  --bottom-margin  MARGIN : set bottom margin (default: 0)\n");
    printf("  --unit UNIT             : set the unit of margins to \"px\" or \"bp\" (default: px) (*bp is always used for EPS/PDF)\n");
    printf("  --create-outline        : outline text in PDF\n");
    printf("  --transparent           : generate transparent PNG file\n");
    printf("  --no-embed-source       : do not embed the source in image files\n");
    printf("  --quick                 : convert in a speed priority mode\n");
    printf("  --kanji ENCODING        : set Japanese encoding  (no|utf8|sjis|jis|euc) (default: no)\n");
    printf("  --ignore-errors         : force conversion by ignoring nonfatal errors\n");
    printf("  --utf-export            : substitute \\UTF{xxxx} for non-JIS X 0208 characters\n");
    printf("  --quiet                 : do not output logs or messages\n");
    printf("  --no-delete             : do not delete temporary files (for debug)\n");
    printf("  --preview               : open the generated file(s)\n");
    printf("  --version               : display version info\n");
    printf("  --help                  : display this message\n");
    exit(1);
}

NSString* getPath(NSString *cmdName)
{
	char str[MAX_LEN];
	FILE *fp;
	char *pStr;
    
	if ((fp = popen([NSString stringWithFormat:@"which %@", cmdName].UTF8String, "r")) == NULL) {
		return nil;
	}
	fgets(str, MAX_LEN-1, fp);
	
	pStr = str;
    while ((*pStr != '\r') && (*pStr != '\n') && (*pStr != EOF)) {
        pStr++;
    }
	*pStr = '\0';
	
	pclose(fp);
    
	return @(str);
}

NSString* getFullPath(NSString *filename)
{
	char str[MAX_LEN];
	FILE *fp;
	
	if ((fp = popen([NSString stringWithFormat:@"perl -e \"use File::Spec;print File::Spec->rel2abs('%@');\"", filename].UTF8String, "r")) == NULL) {
		return nil;
	}
	fgets(str, MAX_LEN-1, fp);
	pclose(fp);
	
	return @(str);
}

int strtoi(char *str)
{
	char *endptr;
	long val;
    
    errno = 0;    /* To distinguish success/failure after call */
    val = strtol(str, &endptr, 10);
	
    if ((errno == ERANGE && (val == LONG_MAX || val == LONG_MIN))
		|| (errno != 0 && val == 0)) {
		fprintf(stderr, "error : %s cannot be converted to a number.\n", str);
		exit(1);
    }
	
    if (*endptr != '\0') {
		fprintf(stderr, "error : %s is not a number.\n", str);
		exit(1);
	}
	
	return (int)val;
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
        BOOL getOutline = NO;
        BOOL transparentPngFlag = NO;
        BOOL deleteTmpFileFlag = YES;
        BOOL ignoreErrorFlag = NO;
        BOOL utfExportFlag = NO;
        BOOL quietFlag = NO;
        BOOL quickFlag = NO;
        BOOL guessFlag = NO;
        BOOL previewFlag = NO;
        BOOL embedSourceFlag = YES;
        NSString *encoding = @"no";
        NSString *compiler = @"platex";
        NSString *dvipdfmx = @"dvipdfmx";
        NSString *gs       = @"gs";
        NSNumber *unitTag = @(PXUNITTAG);
        
        // getopt_long を使った，長いオプション対応のオプション解析
        struct option *options;
        int option_index;
        int opt;
        
        options = malloc(sizeof(struct option) * OPTION_NUM);
        
        options[0].name = "resolution";
        options[0].has_arg = required_argument;
        options[0].flag = NULL;
        options[0].val = 1;
        
        options[1].name = "left-margin";
        options[1].has_arg = required_argument;
        options[1].flag = NULL;
        options[1].val = 2;
        
        options[2].name = "right-margin";
        options[2].has_arg = required_argument;
        options[2].flag = NULL;
        options[2].val = 3;
        
        options[3].name = "top-margin";
        options[3].has_arg = required_argument;
        options[3].flag = NULL;
        options[3].val = 4;
        
        options[4].name = "bottom-margin";
        options[4].has_arg = required_argument;
        options[4].flag = NULL;
        options[4].val = 5;
        
        options[5].name = "create-outline";
        options[5].has_arg = no_argument;
        options[5].flag = NULL;
        options[5].val = 6;
        
        options[6].name = "transparent";
        options[6].has_arg = no_argument;
        options[6].flag = NULL;
        options[6].val = 7;
        
        options[7].name = "no-delete";
        options[7].has_arg = no_argument;
        options[7].flag = NULL;
        options[7].val = 8;
        
        options[8].name = "ignore-errors";
        options[8].has_arg = no_argument;
        options[8].flag = NULL;
        options[8].val = 9;
        
        options[9].name = "utf-export";
        options[9].has_arg = no_argument;
        options[9].flag = NULL;
        options[9].val = 10;
        
        options[10].name = "kanji";
        options[10].has_arg = required_argument;
        options[10].flag = NULL;
        options[10].val = 11;
        
        options[11].name = "quiet";
        options[11].has_arg = no_argument;
        options[11].flag = NULL;
        options[11].val = 12;
        
        options[12].name = "compiler";
        options[12].has_arg = required_argument;
        options[12].flag = NULL;
        options[12].val = 13;

        options[13].name = "unit";
        options[13].has_arg = required_argument;
        options[13].flag = NULL;
        options[13].val = 14;

        options[14].name = "quick";
        options[14].has_arg = no_argument;
        options[14].flag = NULL;
        options[14].val = 15;

        options[15].name = "num";
        options[15].has_arg = required_argument;
        options[15].flag = NULL;
        options[15].val = 16;
        
        options[16].name = "guess-compile";
        options[16].has_arg = no_argument;
        options[16].flag = NULL;
        options[16].val = 17;

        options[17].name = "preview";
        options[17].has_arg = no_argument;
        options[17].flag = NULL;
        options[17].val = 18;
        
        options[18].name = "dvipdfmx";
        options[18].has_arg = required_argument;
        options[18].flag = NULL;
        options[18].val = 19;

        options[19].name = "gs";
        options[19].has_arg = required_argument;
        options[19].flag = NULL;
        options[19].val = 20;

        options[20].name = "no-embed-source";
        options[20].has_arg = no_argument;
        options[20].flag = NULL;
        options[20].val = 21;
        
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
                case 6: // --create-outline
                    getOutline = YES;
                    break;
                case 7: // --transparent
                    transparentPngFlag = YES;
                    break;
                case 8: // --no-delete
                    deleteTmpFileFlag = NO;
                    break;
                case 9: // --ignore-errors
                    ignoreErrorFlag = YES;
                    break;
                case 10: // --utf-export
                    utfExportFlag = YES;
                    break;
                case 11: // --kanji
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
                case 12: // --quiet
                    quietFlag = YES;
                    break;
                case 13: // --compiler
                    if (optarg) {
                        compiler = @(optarg);
                    } else {
                        printf("--compiler is wrong.\n");
                        usage();
                    }
                    break;
                case 14: // --unit
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
                case 15: // --quick
                    quickFlag = YES;
                    break;
                case 16: // --num
                    if (optarg) {
                        numberOfCompilation = strtoi(optarg);
                    } else {
                        printf("--num is wrong.\n");
                        usage();
                    }
                    break;
                case 17: // --guess-compile
                    guessFlag = YES;
                    break;
                case 18: // --preview
                    previewFlag = YES;
                    break;
                case 19: // --dvipdfmx
                    if (optarg) {
                        dvipdfmx = @(optarg);
                    } else {
                        printf("--dvipdfmx is wrong.\n");
                        usage();
                    }
                    break;
                case 20: // --gs
                    if (optarg) {
                        gs = @(optarg);
                    } else {
                        printf("--gs is wrong.\n");
                        usage();
                    }
                    break;
                case 21: // --no-embed-source
                    embedSourceFlag = NO;
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
            fprintf(stderr, "tex2img : %s : No such file or directory\n", inputFilePath.UTF8String);
            exit(1);
        }
        
        // --num が指定されなかった場合のデフォルト値の適用
        if (numberOfCompilation == -1) {
            numberOfCompilation = guessFlag ? DEFAULT_MAXIMAL_NUMBER_OF_COMPILATION : 1;
        }
        
        ControllerC *controller = ControllerC.new;
        
        // 実行プログラムのパスチェック
        NSString *latexPath = getPath(compiler);
        NSString *dvipdfmxPath = getPath(dvipdfmx);
        NSString *gsPath = getPath(gs);
        NSString *pdfcropPath = getPath(@"pdfcrop");
        NSString *epstopdfPath = getPath(@"epstopdf");
        
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
        if (!pdfcropPath) {
            [controller showNotFoundError:@"pdfcrop"];
            return 1;
        }
        if (!epstopdfPath) {
            [controller showNotFoundError:@"epstopdf"];
            return 1;
        }
        
        NSMutableDictionary *aProfile = NSMutableDictionary.dictionary;
        aProfile[LatexPathKey] = latexPath;
        aProfile[DvipdfmxPathKey] = dvipdfmxPath;
        aProfile[GsPathKey] = gsPath;
        aProfile[PdfcropPathKey] = pdfcropPath;
        aProfile[EpstopdfPathKey] = epstopdfPath;
        
        aProfile[OutputFileKey] = outputFilePath;
        
        aProfile[EncodingKey] = encoding;
        aProfile[NumberOfCompilationKey] = @(numberOfCompilation);
        aProfile[ResolutionKey] = @(resolutoinLevel);
        aProfile[LeftMarginKey] = @(leftMargin);
        aProfile[RightMarginKey] = @(rightMargin);
        aProfile[TopMarginKey] = @(topMargin);
        aProfile[BottomMarginKey] = @(bottomMargin);
        aProfile[GetOutlineKey] = @(getOutline);
        aProfile[TransparentKey] = @(transparentPngFlag);
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
        aProfile[EmbedSourceKey] = @(embedSourceFlag);
        
        Converter *converter = [Converter converterWithProfile:aProfile];
        BOOL success = [converter compileAndConvertWithInputPath:inputFilePath];
        
        if (success && !quietFlag) {
            printf("\n%s is generated.\n", outputFilePath.UTF8String);
        }
        
        return success ? 0 : 1;
    }
    
}
