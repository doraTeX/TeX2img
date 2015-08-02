#import "global.h"
#import "Utility.h"

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
