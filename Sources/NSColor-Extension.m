#import "NSColor-Extension.h"

@implementation NSColor (Extension)
- (NSString*)serializedString
{
    NSColor *export = [self colorUsingColorSpace:NSColorSpace.deviceRGBColorSpace];
    
    return [NSString stringWithFormat:@"%lf:%lf:%lf:%lf",
            export.redComponent,
            export.greenComponent,
            export.blueComponent,
            export.alphaComponent];
}

+ (NSColor*)colorWithSerializedString:(NSString*)string
{
    CGFloat components[4];
    NSArray* chunks = [string componentsSeparatedByString:@":"];
    
    if (chunks.count != 4) {
        return nil;
    } else {
        for (NSUInteger i = 0; i < 4; i++) {
            components[i] = ((NSString*)chunks[i]).floatValue;
        }
        
        return [NSColor colorWithDeviceRed:components[0]
                                     green:components[1]
                                      blue:components[2]
                                     alpha:components[3]];
    }
}

+ (NSColor*)braceColor
{
    return [NSColor colorWithCalibratedRed:0.02 green:0.51 blue:0.13 alpha:1.0];
}

+ (NSColor*)commentColor
{
    return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0];
}

+ (NSColor*)commandColor
{
    return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0];
}

+ (NSColor*)invisibleColor
{
    return NSColor.orangeColor;
}

+ (NSColor*)highlightedBraceColor
{
    return NSColor.magentaColor;
}

+ (NSColor*)enclosedContentBackgroundColor
{
    return [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.5 alpha:1.0];
}

+ (NSColor*)flashingBackgroundColor
{
    return [NSColor colorWithCalibratedRed:1.0 green:0.95 blue:1.0 alpha:1.0];
}

@end
