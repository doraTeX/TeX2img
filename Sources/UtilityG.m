#import "UtilityG.h"

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

