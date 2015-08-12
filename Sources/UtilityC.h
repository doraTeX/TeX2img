#import "Utility.h"

#ifndef TeX2img_UtilityC_h
#define TeX2img_UtilityC_h

void printStdErr(const char *format, ...);
BOOL checkWhich(NSString *cmdName);
NSString* getPath(NSString *cmdName);

#endif
