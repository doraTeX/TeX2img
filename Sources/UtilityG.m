#import "UtilityG.h"
#import "NSDictionary-Extension.h"
#import "TeX2img-Swift.h"

void runOkPanel(NSString *title, NSString *message, ...)
{
    va_list arguments;
    va_start(arguments, message);
    NSString *msg = [[NSString alloc] initWithFormat:message arguments:arguments];
    NSAlert *alert = [NSAlert new];
    alert.messageText = title;
    alert.informativeText = msg;
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
    va_end(arguments);
}

void runErrorPanel(NSString *message, ...)
{
    va_list arguments;
    va_start(arguments, message);
    NSString *msg = [[NSString alloc] initWithFormat:message arguments:arguments];
    NSAlert *alert = [NSAlert new];
    alert.messageText = localizedString(@"Error");
    alert.informativeText = msg;
    alert.alertStyle = NSAlertStyleCritical;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
    va_end(arguments);
}

void runWarningPanel(NSString *message, ...)
{
    va_list arguments;
    va_start(arguments, message);
    NSString *msg = [[NSString alloc] initWithFormat:message arguments:arguments];
    NSAlert *alert = [NSAlert new];
    alert.messageText = localizedString(@"Warning");
    alert.informativeText = msg;
    alert.alertStyle = NSAlertStyleWarning;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
    va_end(arguments);
}

BOOL runConfirmPanel(NSString *message, ...)
{
    va_list arguments;
    va_start(arguments, message);
    NSString *msg = [[NSString alloc] initWithFormat:message arguments:arguments];
    NSAlert *alert = [NSAlert new];
    alert.messageText = localizedString(@"Confirm");
    alert.informativeText = msg;
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:localizedString(@"Cancel")];
    NSModalResponse result = [alert runModal];
    va_end(arguments);
    
    return (result == NSAlertFirstButtonReturn);
}


BOOL isJapaneseLanguage()
{
    static BOOL isJapanese;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *locale = NSLocale.preferredLanguages[0];
        isJapanese = [locale isEqualToString:@"ja"] || [locale isEqualToString:@"ja-JP"];
    });
    return isJapanese;
}

NSColor *readColorFromProfile(Profile *profile,
                              NSString *lightModeKey,
                              NSString *darkModeKey,
                              NSColor *defaultColor)
{
    NSColor *theColor = [profile colorForKey:NSApp.isDarkMode ? darkModeKey : lightModeKey];
    if (!theColor) {
        theColor = defaultColor;
    }
    return theColor;
}

NSColor *foregroundColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                ForegroundColorForLightModeKey,
                                ForegroundColorForDarkModeKey,
                                NSColor.defaultForegroundColor);
}

NSColor *backgroundColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                BackgroundColorForLightModeKey,
                                BackgroundColorForDarkModeKey,
                                NSColor.defaultBackgroundColor);
}

NSColor *cursorColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                CursorColorForLightModeKey,
                                CursorColorForDarkModeKey,
                                NSColor.defaultCursorColor);
}

NSColor *braceColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                BraceColorForLightModeKey,
                                BraceColorForDarkModeKey,
                                NSColor.defaultBraceColor);
}

NSColor *commentColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                CommentColorForLightModeKey,
                                CommentColorForDarkModeKey,
                                NSColor.defaultCommentColor);
}

NSColor *commandColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                CommandColorForLightModeKey,
                                CommandColorForDarkModeKey,
                                NSColor.defaultCommandColor);
}

NSColor *invisibleColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                InvisibleColorForLightModeKey,
                                InvisibleColorForDarkModeKey,
                                NSColor.defaultInvisibleColor);
}

NSColor *highlightedBraceColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                HighlightedBraceColorForLightModeKey,
                                HighlightedBraceColorForDarkModeKey,
                                NSColor.defaultHighlightedBraceColor);
}

NSColor *enclosedContentBackgroundColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                EnclosedContentBackgroundColorForLightModeKey,
                                EnclosedContentBackgroundColorForDarkModeKey,
                                NSColor.defaultEnclosedContentBackgroundColor);
}

NSColor *flashingBackgroundColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                FlashingBackgroundColorForLightModeKey,
                                FlashingBackgroundColorForDarkModeKey,
                                NSColor.defaultFlashingBackgroundColor);
}

NSColor *consoleForegroundColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                ConsoleForegroundColorForLightModeKey,
                                ConsoleForegroundColorForDarkModeKey,
                                NSColor.defaultConsoleForegroundColor);
}

NSColor *consoleBackgroundColorInProfile(Profile *profile)
{
    return readColorFromProfile(profile,
                                ConsoleBackgroundColorForLightModeKey,
                                ConsoleBackgroundColorForDarkModeKey,
                                NSColor.defaultConsoleBackgroundColor);
}

