#import <stdio.h>
#import <stdarg.h>
#import "UtilityC.h"
#import "global.h"

void printStdErr(const char *format, ...)
{
    va_list list;
    va_start(list, format);
    vfprintf(stderr, format, list);
    va_end(list);
}

BOOL checkWhich(NSString *cmdName)
{
    int status = system([NSString stringWithFormat:@"PATH=$PATH:%@; /usr/bin/which %@ > /dev/null", ADDITIONAL_PATH, cmdName].UTF8String);
    return (status == 0) ? YES : NO;
}

NSString* getPath(NSString *cmdName)
{
    char str[MAX_LEN];
    FILE *fp;
    char *pStr;
    
    if ((fp = popen([NSString stringWithFormat:@"PATH=$PATH:%@; /usr/bin/which %@", ADDITIONAL_PATH, cmdName].UTF8String, "r")) == NULL) {
        return nil;
    }
    fgets(str, MAX_LEN-1, fp);
    
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