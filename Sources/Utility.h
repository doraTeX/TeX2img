#ifndef TeX2img_Utility_h
#define TeX2img_Utility_h

NSString* execCommand(NSString *cmdline);
NSString* getFullPath(NSString *aPath);
void previewFiles(NSArray<NSString*> *files, NSString *app);
#endif
