#import <stdio.h>
#import <stdarg.h>
#import "UtilityC.h"

NSString* additionalSearchPath()
{
    NSString *resourcesDir = @"TeX2img.app/Contents/Resources";
    
    __block NSMutableArray<NSString*> *results = [NSMutableArray<NSString*> array];
    [GUI_PATHS enumerateObjectsUsingBlock:^(id  _Nonnull guiPath, NSUInteger idx, BOOL * _Nonnull stop) {
        [results addObject:[guiPath stringByAppendingPathComponent:[resourcesDir stringByAppendingPathComponent:@"mupdf"]]];
        [results addObject:[guiPath stringByAppendingPathComponent:[resourcesDir stringByAppendingPathComponent:@"pdftops"]]];
    }];
     
    return [results componentsJoinedByString:@":"];
}

void printStdErr(const char *format, ...)
{
    va_list list;
    va_start(list, format);
    vfprintf(stderr, format, list);
    va_end(list);
}

void suggestLatexOption()
{
    printStdErr("If you want to use another LaTeX compiler, specify it by using --latex option.\n");
}


BOOL checkWhich(NSString *cmdName)
{
    int status = system([NSString stringWithFormat:@"PATH=%@:$PATH; /usr/bin/which %@ > /dev/null", additionalSearchPath(), cmdName].UTF8String);
    return (status == 0) ? YES : NO;
}

NSString* getPath(NSString *cmdName)
{
    char str[PATH_MAX];
    FILE *fp;
    char *pStr;
    
    if ((fp = popen([NSString stringWithFormat:@"PATH=%@:$PATH; /usr/bin/which %@", additionalSearchPath(), cmdName].UTF8String, "r")) == NULL) {
        return nil;
    }
    fgets(str, PATH_MAX-1, fp);
    
    pStr = str;
    while ((*pStr != '\r') && (*pStr != '\n') && (*pStr != EOF)) {
        pStr++;
    }
    *pStr = '\0';
    
    if (pclose(fp) == 0) {
        return @(str);
    } else {
        return nil;
    }
}
