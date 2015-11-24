#import "Utility.h"
#import "NSArray-Extension.h"
#import "NSPipe-Extension.h"

NSString* execCommand(NSString *cmdline)
{
    NSTask *task = [NSTask new];
    NSPipe *pipe = [NSPipe pipe];
    task.launchPath = BASH_PATH;
    task.arguments = @[@"-c", cmdline];
    task.standardOutput = pipe;
    [task launch];
    [task waitUntilExit];
    
    return pipe.stringValue;
}

NSString* getFullPath(NSString *aPath)
{
    char str[MAX_LEN];
    FILE *fp;
    
    if ((fp = popen([NSString stringWithFormat:@"/usr/bin/perl -e \"use File::Spec;print File::Spec->rel2abs('%@');\"", aPath].UTF8String, "r")) == NULL) {
        return nil;
    }
    fgets(str, MAX_LEN-1, fp);
    pclose(fp);
    
    return @(str);
}

void previewFiles(NSArray<NSString*> *files, NSString *app)
{
    [files enumerateObjectsUsingBlock:^(NSString * _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
        [NSWorkspace.sharedWorkspace openFile:file withApplication:app];
    }];
}

BOOL isTeX2imgAnnotation(PDFAnnotation *annotation)
{
    if (![annotation.type isEqualToString:@"Text"]) {
        return NO;
    }
    
    NSString *contents = [annotation.contents stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    
    return ([contents rangeOfString:AnnotationHeader].location == 0);
}
