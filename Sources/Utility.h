#import <stdarg.h>
#ifndef TeX2img_Utility_h
#define TeX2img_Utility_h

void runOkPanel(NSString *title, NSString *message, ...);
void runErrorPanel(NSString *message, ...);
BOOL runConfirmPanel(NSString *message, ...);

#endif
