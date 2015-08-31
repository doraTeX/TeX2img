#import "UtilityG.h"
#import "NSDictionary-Extension.h"

void runOkPanel(NSString *title, NSString *message, ...)
{
    va_list arguments;
    va_start(arguments, message);
    NSString *msg = [[NSString alloc] initWithFormat:message arguments:arguments];
    NSRunAlertPanel(title, @"%@", @"OK", nil, nil, msg);
    va_end(arguments);
}

void runErrorPanel(NSString *message, ...)
{
    va_list arguments;
    va_start(arguments, message);
    NSString *msg = [[NSString alloc] initWithFormat:message arguments:arguments];
    runOkPanel(localizedString(@"Error"), msg);
    va_end(arguments);
}

void runWarningPanel(NSString *message, ...)
{
    va_list arguments;
    va_start(arguments, message);
    NSString *msg = [[NSString alloc] initWithFormat:message arguments:arguments];
    runOkPanel(localizedString(@"Warning"), msg);
    va_end(arguments);
}

BOOL runConfirmPanel(NSString *message, ...)
{
    va_list arguments;
    va_start(arguments, message);
    NSString *msg = [[NSString alloc] initWithFormat:message arguments:arguments];
    NSInteger result = NSRunAlertPanel(localizedString(@"Confirm"), @"%@", @"OK", localizedString(@"Cancel"), nil, msg);
    va_end(arguments);
    
    return (result == NSOKButton);
}

NSString* systemVersion()
{
    return [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] stringForKey:@"ProductVersion"];
}

NSInteger systemMajorVersion()
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\.(\\d+)\\.?"
                                                                           options:0
                                                                             error:nil];
    NSString *version = systemVersion();
    NSTextCheckingResult *match = [regex firstMatchInString:version options:0 range:NSMakeRange(0, version.length)];
    return [version substringWithRange:[match rangeAtIndex:1]].integerValue;
}

