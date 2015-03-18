#import <stdio.h>
#import <stdarg.h>
#import "UtilityC.h"

void printStdErr(const char *format, ...)
{
    va_list list;
    va_start(list, format);
    vfprintf(stderr, format, list);
    va_end(list);
}