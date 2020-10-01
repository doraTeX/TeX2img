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

NSString* systemVersion()
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    return (NSString*)[dict objectForKey:@"ProductVersion"];
}

NSInteger systemMajorVersion()
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\.(\\d+)\\.?"
                                                                           options:0
                                                                             error:nil];
    NSString *version = systemVersion();
    NSTextCheckingResult *match = [regex firstMatchInString:version options:0 range:NSMakeRange(0, version.length)];
    return [[version substringWithRange:[match rangeAtIndex:1]] intValue];
}

