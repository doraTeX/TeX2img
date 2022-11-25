#import "Utility.h"
#import "NSArray-Extension.h"
#import "TeX2img-Swift.h"

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
    NSURL *url = [NSURL fileURLWithPath:aPath];
    if (!url) return nil;
    
    return [NSString stringWithUTF8String:url.fileSystemRepresentation].stringByStandardizingPath;
}

void previewFiles(NSArray<NSString*> *files, NSString *app)
{
    if (@available(macOS 10.15, *)) {
        NSArray<NSURL*> *targetURLs = [files mapUsingBlock: ^NSURL*(NSString* path){ return [NSURL fileURLWithPath:path]; }];
        [[NSWorkspace sharedWorkspace] openURLs:targetURLs
                           withApplicationAtURL:[NSURL fileURLWithPath:app]
                                  configuration:[NSWorkspaceOpenConfiguration configuration]
                              completionHandler:nil];
    } else {
        [files enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            [[NSWorkspace sharedWorkspace] openFile:path withApplication:app];
        }];
    }

}

BOOL isTeX2imgAnnotation(PDFAnnotation *annotation)
{
    if (![annotation.type isEqualToString:@"Text"]) {
        return NO;
    }
    
    NSString *contents = [annotation.contents stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    
    return ([contents rangeOfString:AnnotationHeader].location == 0);
}


