#import <stdarg.h>
#import "Utility.h"
#ifndef TeX2img_UtilityG_h
#define TeX2img_UtilityG_h

#define localizedString(str) (NSLocalizedString(str, nil))

void runOkPanel(NSString *title, NSString *message, ...);
void runErrorPanel(NSString *message, ...);
void runWarningPanel(NSString *message, ...);
BOOL runConfirmPanel(NSString *message, ...);
BOOL isJapaneseLanguage(void);
NSColor *foregroundColorInProfile(Profile *dict);
NSColor *backgroundColorInProfile(Profile *dict);
NSColor *cursorColorInProfile(Profile *dict);
NSColor *braceColorInProfile(Profile *dict);
NSColor *commentColorInProfile(Profile *dict);
NSColor *commandColorInProfile(Profile *dict);
NSColor *invisibleColorInProfile(Profile *dict);
NSColor *highlightedBraceColorInProfile(Profile *dict);
NSColor *enclosedContentBackgroundColorInProfile(Profile *dict);
NSColor *flashingBackgroundColorInProfile(Profile *dict);
NSColor *consoleForegroundColorInProfile(Profile *dict);
NSColor *consoleBackgroundColorInProfile(Profile *dict);

#endif
