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
    if (files.count == 0) {
        return;
    }
    
    NSMutableString *script = [NSMutableString string];
    [script appendString:@"tell application \"Finder\"\n"];
    [script appendString:@"open {"];
    [script appendString:[[files mapUsingBlock:^NSString*(NSString *path) {
        return [NSString stringWithFormat:@"POSIX file (\"%@\")", path];
    }] componentsJoinedByString:@", "]];
    [script appendFormat:@"} using POSIX file \"%@\"\n", app];
    [script appendString:@"end tell\n"];
    
    NSTask *task = [NSTask new];
    NSPipe *pipe = [NSPipe pipe];
    task.launchPath = @"/usr/bin/osascript";
    task.arguments = @[@"-e", script];
    task.standardOutput = pipe;
    task.standardError = pipe;
    
    [task launch];
}

BOOL isTeX2imgAnnotation(PDFAnnotation *annotation)
{
    if (![annotation.type isEqualToString:@"Text"]) {
        return NO;
    }
    
    NSString *contents = [annotation.contents stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    
    return ([contents rangeOfString:AnnotationHeader].location == 0);
}


