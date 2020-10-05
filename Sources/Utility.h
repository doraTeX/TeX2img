#ifndef TeX2img_Utility_h
#define TeX2img_Utility_h
#import "global.h"
#import <Quartz/Quartz.h>

NSString* execCommand(NSString *cmdline);
NSString* getFullPath(NSString *aPath);
void previewFiles(NSArray<NSString*> *files, NSString *app);
BOOL isTeX2imgAnnotation(PDFAnnotation *annotation);
NSString* systemVersion(void);

#endif
