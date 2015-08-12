#import "global.h"
#import "Utility.h"
#import "NSArray-Extension.h"

NSString* execCommand(NSString *cmdline)
{
    NSTask *task = NSTask.new;
    NSPipe *pipe = NSPipe.pipe;
    task.launchPath = BASH_PATH;
    task.arguments = @[@"-c", cmdline];
    task.standardOutput = pipe;
    [task launch];
    [task waitUntilExit];
    
    return [NSString.alloc initWithData:pipe.fileHandleForReading.readDataToEndOfFile encoding:NSUTF8StringEncoding];
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

void previewFiles(NSArray *files, NSString *app)
{
    if (files.count == 0) {
        return;
    }
    
    NSMutableString *script = NSMutableString.string;
    [script appendString:@"tell application \"Finder\"\n"];
    [script appendString:@"open {"];
    [script appendString:[[files mapUsingBlock:^NSString*(NSString *path) {
        return [NSString stringWithFormat:@"POSIX file (\"%@\")", path];
    }] componentsJoinedByString:@", "]];
    [script appendFormat:@"} using POSIX file \"/Applications/%@.app\"\n", app];
    [script appendString:@"end tell\n"];
    
    NSTask *task = NSTask.new;
    task.launchPath = @"/usr/bin/osascript";
    task.arguments = @[@"-e", script];
    task.standardOutput = nil;
    task.standardError = nil;
    
    [task launch];

}
