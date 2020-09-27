#import <Foundation/Foundation.h>

#import "UtilityG.h"

@implementation NSColor (DefaultColor)

#pragma mark - Light Mode Defaults
+ (NSColor*)defaultForegroundColorForLightMode
{
    return NSColor.blackColor;
}

+ (NSColor*)defaultBackgroundColorForLightMode
{
    return NSColor.whiteColor;
}

+ (NSColor*)defaultCursorColorForLightMode
{
    return NSColor.blackColor;
}

+ (NSColor*)defaultBraceColorForLightMode
{
    return [NSColor colorWithCalibratedRed:0.02 green:0.51 blue:0.13 alpha:1.0];
}

+ (NSColor*)defaultCommentColorForLightMode
{
    return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0];
}

+ (NSColor*)defaultCommandColorForLightMode
{
    return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0];
}

+ (NSColor*)defaultInvisibleColorForLightMode
{
    return NSColor.orangeColor;
}

+ (NSColor*)defaultHighlightedBraceColorForLightMode
{
    return NSColor.magentaColor;
}

+ (NSColor*)defaultEnclosedContentBackgroundColorForLightMode
{
    return [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.5 alpha:1.0];
}

+ (NSColor*)defaultFlashingBackgroundColorForLightMode
{
    return [NSColor colorWithCalibratedRed:1.0 green:0.95 blue:1.0 alpha:1.0];
}

+ (NSColor*)defaultConsoleForegroundColorForLightMode
{
    return NSColor.blackColor;
}

+ (NSColor*)defaultConsoleBackgroundColorForLightMode
{
    return NSColor.whiteColor;
}

#pragma mark - Dark Mode Defaults
+ (NSColor*)defaultForegroundColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:0.792 green:0.843 blue:0.854 alpha:1.0];
}

+ (NSColor*)defaultBackgroundColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:0.07 green:0.10 blue:0.12 alpha:1.0];
}

+ (NSColor*)defaultCursorColorForDarkMode
{
    return NSColor.defaultForegroundColorForDarkMode;
}

+ (NSColor*)defaultBraceColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:1.00 green:0.980 blue:0.513 alpha:1.0];
}

+ (NSColor*)defaultCommentColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:0.866 green:0.603 blue:0.898 alpha:1.0];
}

+ (NSColor*)defaultCommandColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:0.341 green:0.709 blue:0.494 alpha:1.0];
}

+ (NSColor*)defaultInvisibleColorForDarkMode
{
    return NSColor.orangeColor;
}

+ (NSColor*)defaultHighlightedBraceColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.5 alpha:1.0];
}

+ (NSColor*)defaultEnclosedContentBackgroundColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:0.250 green:0.250 blue:0.215 alpha:1.0];
}

+ (NSColor*)defaultFlashingBackgroundColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:0.04 green:0.13 blue:0.13 alpha:1.0];
}

+ (NSColor*)defaultConsoleForegroundColorForDarkMode
{
    return NSColor.defaultForegroundColorForDarkMode;
}

+ (NSColor*)defaultConsoleBackgroundColorForDarkMode
{
    return NSColor.defaultBackgroundColorForDarkMode;
}

#pragma mark - Automatic Choice
+ (NSColor*)defaultForegroundColor
{
    return isDarkMode() ? NSColor.defaultForegroundColorForDarkMode : NSColor.defaultForegroundColorForLightMode;
}

+ (NSColor*)defaultBackgroundColor
{
    return isDarkMode() ? NSColor.defaultBackgroundColorForDarkMode : NSColor.defaultBackgroundColorForLightMode;
}

+ (NSColor*)defaultCursorColor
{
    return isDarkMode() ? NSColor.defaultCursorColorForDarkMode : NSColor.defaultCursorColorForLightMode;
}

+ (NSColor*)defaultBraceColor
{
    return isDarkMode() ? NSColor.defaultBraceColorForDarkMode : NSColor.defaultBraceColorForLightMode;
}

+ (NSColor*)defaultCommentColor
{
    return isDarkMode() ? NSColor.defaultCommentColorForDarkMode : NSColor.defaultCommentColorForLightMode;
}

+ (NSColor*)defaultCommandColor
{
    return isDarkMode() ? NSColor.defaultCommandColorForDarkMode : NSColor.defaultCommandColorForLightMode;
}

+ (NSColor*)defaultInvisibleColor
{
    return isDarkMode() ? NSColor.defaultInvisibleColorForDarkMode : NSColor.defaultInvisibleColorForLightMode;
}

+ (NSColor*)defaultHighlightedBraceColor
{
    return isDarkMode() ? NSColor.defaultHighlightedBraceColorForDarkMode : NSColor.defaultHighlightedBraceColorForLightMode;
}

+ (NSColor*)defaultEnclosedContentBackgroundColor
{
    return isDarkMode() ? NSColor.defaultEnclosedContentBackgroundColorForDarkMode : NSColor.defaultEnclosedContentBackgroundColorForLightMode;
}

+ (NSColor*)defaultFlashingBackgroundColor
{
    return isDarkMode() ? NSColor.defaultFlashingBackgroundColorForDarkMode : NSColor.defaultFlashingBackgroundColorForLightMode;
}

+ (NSColor*)defaultConsoleForegroundColor
{
    return isDarkMode() ? NSColor.defaultConsoleForegroundColorForDarkMode : NSColor.defaultConsoleForegroundColorForLightMode;
}

+ (NSColor*)defaultConsoleBackgroundColor
{
    return isDarkMode() ? NSColor.defaultConsoleBackgroundColorForDarkMode : NSColor.defaultConsoleBackgroundColorForLightMode;
}


@end
