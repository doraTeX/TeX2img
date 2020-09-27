#import <Foundation/Foundation.h>
#ifndef NSColor_DefaultColor_h
#define NSColor_DefaultColor_h

@interface NSColor (DefaultColor)
+ (NSColor*)defaultForegroundColorForLightMode;
+ (NSColor*)defaultBackgroundColorForLightMode;
+ (NSColor*)defaultCursorColorForLightMode;
+ (NSColor*)defaultBraceColorForLightMode;
+ (NSColor*)defaultCommentColorForLightMode;
+ (NSColor*)defaultCommandColorForLightMode;
+ (NSColor*)defaultInvisibleColorForLightMode;
+ (NSColor*)defaultHighlightedBraceColorForLightMode;
+ (NSColor*)defaultEnclosedContentBackgroundColorForLightMode;
+ (NSColor*)defaultFlashingBackgroundColorForLightMode;
+ (NSColor*)defaultConsoleForegroundColorForLightMode;
+ (NSColor*)defaultConsoleBackgroundColorForLightMode;

+ (NSColor*)defaultForegroundColorForDarkMode;
+ (NSColor*)defaultBackgroundColorForDarkMode;
+ (NSColor*)defaultCursorColorForDarkMode;
+ (NSColor*)defaultBraceColorForDarkMode;
+ (NSColor*)defaultCommentColorForDarkMode;
+ (NSColor*)defaultCommandColorForDarkMode;
+ (NSColor*)defaultInvisibleColorForDarkMode;
+ (NSColor*)defaultHighlightedBraceColorForDarkMode;
+ (NSColor*)defaultEnclosedContentBackgroundColorForDarkMode;
+ (NSColor*)defaultFlashingBackgroundColorForDarkMode;
+ (NSColor*)defaultConsoleForegroundColorForDarkMode;
+ (NSColor*)defaultConsoleBackgroundColorForDarkMode;

+ (NSColor*)defaultForegroundColor;
+ (NSColor*)defaultBackgroundColor;
+ (NSColor*)defaultCursorColor;
+ (NSColor*)defaultBraceColor;
+ (NSColor*)defaultCommentColor;
+ (NSColor*)defaultCommandColor;
+ (NSColor*)defaultInvisibleColor;
+ (NSColor*)defaultHighlightedBraceColor;
+ (NSColor*)defaultEnclosedContentBackgroundColor;
+ (NSColor*)defaultFlashingBackgroundColor;
+ (NSColor*)defaultConsoleForegroundColor;
+ (NSColor*)defaultConsoleBackgroundColor;
@end

#endif
