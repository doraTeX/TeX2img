#import <stdio.h>
#import <unistd.h> 
#import <getopt.h>
#import "Converter.h"
#import "ControllerC.h"

#define OPTION_NUM 14
#define MAX_LEN 1024
#define VERSION "1.3.7"

static void version()
{
    printf("tex2img Ver.%s\n", VERSION); 
}

static void usage()
{ 
	version();
    printf("Usage: tex2img [options] InputTeXFile OutputFile\n"); 
    printf("Arguments:\n"); 
    printf("  InputTeXFile            : path of TeX source file (ShiftJIS)\n"); 
    printf("  OutputFile              : path of output file (extension: eps/png/jpg/pdf)\n"); 
    printf("Options:\n"); 
    printf("  --resolution RESOLUTION : set resolution level   (default: 6)\n"); 
    printf("  --left-margin    MARGIN : set left margin   (px) (default: 0)\n"); 
    printf("  --right-margin   MARGIN : set right margin  (px) (default: 0)\n"); 
    printf("  --top-margin     MARGIN : set top margin    (px) (default: 0)\n"); 
    printf("  --bottom-margin  MARGIN : set bottom margin (px) (default: 0)\n"); 
    printf("  --create-outline        : create outline of text to prevent garbling (for JPEG/PNG/PDF)\n"); 
    printf("  --transparent           : generate transparent PNG file\n"); 
    printf("  --kanji ENCODING        : set Japanese encoding  (default: sjis)\n"); 
    printf("  --ignore-errors         : force converting by ignoring nonfatal errors\n"); 
    printf("  --utf-export            : substitute \\UTF{xxxx} for non-SJIS characters\n"); 
    printf("  --no-delete             : do not delete temporary files (for debug)\n"); 
    printf("  --version               : display version\n"); 
    printf("  --help                  : display this message\n"); 
    exit(1); 
}

NSString* getPath(char* cmdName)
{
	char str[MAX_LEN];
	FILE* fp;
	char* pStr;

	if((fp=popen([[NSString stringWithFormat:@"which %s", cmdName] cString],"r"))==NULL){
		return NO;
	}
	fgets(str, MAX_LEN-1, fp);
	
	pStr = str;
	while((*pStr != '\r') && (*pStr != '\n') && (*pStr != EOF)) pStr++;
	*pStr = '\0';
	
	pclose(fp);

	return [NSString stringWithCString:str];
}

NSString* getFullPath(NSString* filename)
{
	char str[MAX_LEN];
	FILE* fp;
	
	if((fp=popen([[NSString stringWithFormat:@"ruby -e \"print File::expand_path('%@')\"", filename] cString],"r"))==NULL){
		return NO;
	}
	fgets(str, MAX_LEN-1, fp);
	pclose(fp);
	
	return [NSString stringWithCString:str];
}

int strtoi(char* str)
{
	char *endptr;
	long val;

    errno = 0;    /* To distinguish success/failure after call */
    val = strtol(str, &endptr, 10);
	
    if ((errno == ERANGE && (val == LONG_MAX || val == LONG_MIN))
		|| (errno != 0 && val == 0))
	{
		fprintf(stderr, "error : %s cannot be converted to a number.\n", str);
		exit(1);
    }
	
    if (*endptr != '\0')
	{
		fprintf(stderr, "error : %s is not a number.\n", str);
		exit(1);
	}
	
	return (int)val;
}

int main (int argc, char *argv[]) { 
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSApplicationLoad(); // PDFKit を使ったときに _NXCreateWindow: error setting window property のエラーを防ぐため

	int resolutoinLevel = 6;
	int leftMargin = 0;
	int rightMargin = 0;
	int topMargin = 0;
	int bottomMargin = 0;
	bool leaveTextFlag = YES;
	bool transparentPngFlag = NO;
	bool deleteTmpFileFlag = YES;
	bool ignoreErrorFlag = NO;
	bool utfExportFlag = NO;
	NSString* encoding = @"sjis";

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

	while(1){
		// オプションの取得
		opt = getopt_long(argc, argv, "", options, &option_index);

		// オプション文字が見つからなくなればオプション解析終了
		if(opt == -1){
			break;
		}
		
		switch(opt){
			case 0:
				break;
			case 1: // --resolution
				if(optarg)
				{
					resolutoinLevel = strtoi(optarg);
				}
				else
				{
					usage();
				}
				break;
			case 2: // --left-margin
				if(optarg)
				{
					leftMargin = strtoi(optarg);
				}
				else
				{
					usage();
				}
				break;
			case 3: // --right-margin
				if(optarg)
				{
					rightMargin = strtoi(optarg);
				}
				else
				{
					usage();
				}
				break;
			case 4: // --top-margin
				if(optarg)
				{
					topMargin = strtoi(optarg);
				}
				else
				{
					usage();
				}
				break;
			case 5: // --bottom-margin
				if(optarg)
				{
					bottomMargin = strtoi(optarg);
				}
				else
				{
					usage();
				}
				break;
			case 6: // --create-outline
				leaveTextFlag = NO;
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
				if(optarg)
				{
					encoding = [NSString stringWithCString:optarg];
				}
				else
				{
					usage();
				}
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
	
    if (argc != 2) usage();
	
	NSString* inputFilePath = [NSString stringWithCString:argv[0]];
	NSString* outputFilePath = getFullPath([NSString stringWithCString:argv[1]]);

	version();
	if(![[NSFileManager defaultManager] fileExistsAtPath:inputFilePath])
	{
		fprintf(stderr, "tex2img : %s : No such file or directory\n", [inputFilePath cString]);
		exit(1);
	}
	
	ControllerC* controller = [[[ControllerC alloc] init] autorelease];
	Converter* converter = [Converter converterWithPlatex:getPath("platex") dvipdfmx:getPath("dvipdfmx") gs:getPath("gs")
										  withPdfcropPath:getPath("pdfcrop") withEpstopdfPath:getPath("epstopdf")
												 encoding:encoding
										  resolutionLevel:resolutoinLevel leftMargin:leftMargin rightMargin:rightMargin topMargin:topMargin bottomMargin:bottomMargin 
												leaveText:leaveTextFlag transparentPng:transparentPngFlag
										 showOutputWindow:NO preview:NO deleteTmpFile:deleteTmpFileFlag 
											 ignoreErrors:ignoreErrorFlag
												utfExport:utfExportFlag
											   controller:controller];
	bool succeed = [converter compileAndConvertWithInputPath:inputFilePath outputFilePath:outputFilePath];
	
	if(succeed)
	{
		printf("\n%s is generated.\n", [outputFilePath cString]);
	}

	[pool release];

	return succeed ? 0 : 1;
}
