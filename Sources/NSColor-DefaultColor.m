#import <Foundation/Foundation.h>

#import "UtilityG.h"

@implementation NSColor (DefaultColor)

#pragma mark - Light Mode Defaults
+ (NSColor*)defaultForegroundColorForLightMode
{
    return NSColor.textColor;
}

+ (NSColor*)defaultBackgroundColorForLightMode
{
    return NSColor.controlBackgroundColor;
}

+ (NSColor*)defaultCursorColorForLightMode
{
    return NSColor.textColor;
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

+ (NSColor*)defaultConsoleBackgroundColorForLightMode
{
    return [NSColor colorWithCalibratedRed:1.0 green:0.95 blue:1.0 alpha:1.0];
}

#pragma mark - Dark Mode Defaults
+ (NSColor*)defaultForegroundColorForDarkMode
{
    return NSColor.textColor;
}

+ (NSColor*)defaultBackgroundColorForDarkMode
{
    return NSColor.controlBackgroundColor;
}

+ (NSColor*)defaultCursorColorForDarkMode
{
    return NSColor.textColor;
}

+ (NSColor*)defaultBraceColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:0.02 green:0.51 blue:0.13 alpha:1.0];
}

+ (NSColor*)defaultCommentColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0];
}

+ (NSColor*)defaultCommandColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0];
}

+ (NSColor*)defaultInvisibleColorForDarkMode
{
    return NSColor.orangeColor;
}

+ (NSColor*)defaultHighlightedBraceColorForDarkMode
{
    return NSColor.magentaColor;
}

+ (NSColor*)defaultEnclosedContentBackgroundColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.5 alpha:1.0];
}

+ (NSColor*)defaultFlashingBackgroundColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:1.0 green:0.95 blue:1.0 alpha:1.0];
}

+ (NSColor*)defaultConsoleBackgroundColorForDarkMode
{
    return [NSColor colorWithCalibratedRed:1.0 green:0.95 blue:1.0 alpha:1.0];
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

+ (NSColor*)defaultConsoleBackgroundColor
{
    return isDarkMode() ? NSColor.defaultConsoleBackgroundColorForDarkMode : NSColor.defaultConsoleBackgroundColorForLightMode;
}


@end
