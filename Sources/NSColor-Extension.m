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

- (NSString*)descriptionString
{
    NSColor *export = [self colorUsingColorSpace:NSColorSpace.deviceRGBColorSpace];
    NSUInteger r = round(export.redComponent   * 255);
    NSUInteger g = round(export.greenComponent * 255);
    NSUInteger b = round(export.blueComponent  * 255);
    return [NSString stringWithFormat:@"#%02lx%02lx%02lx (R=%ld, G=%ld, B=%ld)", r, g, b, r, g, b].uppercaseString;
}


+ (NSColor*)colorWithSerializedString:(NSString*)string
{
    CGFloat components[4];
    NSArray<NSString*> *chunks = [string componentsSeparatedByString:@":"];
    
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


+ (NSColor*)colorWithCSSName:(NSString*)name
{
    name = name.lowercaseString;
    
    if ([name isEqualToString:@"aliceblue"]) {
        return [NSColor colorWithDeviceRed:0.941176470588235 green:0.972549019607843 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"antiquewhite"]) {
        return [NSColor colorWithDeviceRed:0.980392156862745 green:0.92156862745098 blue:0.843137254901961 alpha:1.0];
    } else if ([name isEqualToString:@"aqua"]) {
        return [NSColor colorWithDeviceRed:0.0 green:1.0 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"aquamarine"]) {
        return [NSColor colorWithDeviceRed:0.498039215686275 green:1.0 blue:0.831372549019608 alpha:1.0];
    } else if ([name isEqualToString:@"azure"]) {
        return [NSColor colorWithDeviceRed:0.941176470588235 green:1.0 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"beige"]) {
        return [NSColor colorWithDeviceRed:0.96078431372549 green:0.96078431372549 blue:0.862745098039216 alpha:1.0];
    } else if ([name isEqualToString:@"bisque"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.894117647058824 blue:0.768627450980392 alpha:1.0];
    } else if ([name isEqualToString:@"black"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"blanchedalmond"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.92156862745098 blue:0.803921568627451 alpha:1.0];
    } else if ([name isEqualToString:@"blue"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"blueviolet"]) {
        return [NSColor colorWithDeviceRed:0.541176470588235 green:0.168627450980392 blue:0.886274509803922 alpha:1.0];
    } else if ([name isEqualToString:@"brown"]) {
        return [NSColor colorWithDeviceRed:0.647058823529412 green:0.164705882352941 blue:0.164705882352941 alpha:1.0];
    } else if ([name isEqualToString:@"burlywood"]) {
        return [NSColor colorWithDeviceRed:0.870588235294118 green:0.72156862745098 blue:0.529411764705882 alpha:1.0];
    } else if ([name isEqualToString:@"cadetblue"]) {
        return [NSColor colorWithDeviceRed:0.372549019607843 green:0.619607843137255 blue:0.627450980392157 alpha:1.0];
    } else if ([name isEqualToString:@"chartreuse"]) {
        return [NSColor colorWithDeviceRed:0.498039215686275 green:1.0 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"chocolate"]) {
        return [NSColor colorWithDeviceRed:0.823529411764706 green:0.411764705882353 blue:0.117647058823529 alpha:1.0];
    } else if ([name isEqualToString:@"coral"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.498039215686275 blue:0.313725490196078 alpha:1.0];
    } else if ([name isEqualToString:@"cornflowerblue"]) {
        return [NSColor colorWithDeviceRed:0.392156862745098 green:0.584313725490196 blue:0.929411764705882 alpha:1.0];
    } else if ([name isEqualToString:@"cornsilk"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.972549019607843 blue:0.862745098039216 alpha:1.0];
    } else if ([name isEqualToString:@"crimson"]) {
        return [NSColor colorWithDeviceRed:0.862745098039216 green:0.0784313725490196 blue:0.235294117647059 alpha:1.0];
    } else if ([name isEqualToString:@"cyan"]) {
        return [NSColor colorWithDeviceRed:0.0 green:1.0 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"darkblue"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.545098039215686 alpha:1.0];
    } else if ([name isEqualToString:@"darkcyan"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.545098039215686 blue:0.545098039215686 alpha:1.0];
    } else if ([name isEqualToString:@"darkgoldenrod"]) {
        return [NSColor colorWithDeviceRed:0.72156862745098 green:0.525490196078431 blue:0.0431372549019608 alpha:1.0];
    } else if ([name isEqualToString:@"darkgray"]) {
        return [NSColor colorWithDeviceRed:0.662745098039216 green:0.662745098039216 blue:0.662745098039216 alpha:1.0];
    } else if ([name isEqualToString:@"darkgreen"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.392156862745098 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"darkkhaki"]) {
        return [NSColor colorWithDeviceRed:0.741176470588235 green:0.717647058823529 blue:0.419607843137255 alpha:1.0];
    } else if ([name isEqualToString:@"darkmagenta"]) {
        return [NSColor colorWithDeviceRed:0.545098039215686 green:0.0 blue:0.545098039215686 alpha:1.0];
    } else if ([name isEqualToString:@"darkolivegreen"]) {
        return [NSColor colorWithDeviceRed:0.333333333333333 green:0.419607843137255 blue:0.184313725490196 alpha:1.0];
    } else if ([name isEqualToString:@"darkorange"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.549019607843137 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"darkorchid"]) {
        return [NSColor colorWithDeviceRed:0.6 green:0.196078431372549 blue:0.8 alpha:1.0];
    } else if ([name isEqualToString:@"darkred"]) {
        return [NSColor colorWithDeviceRed:0.545098039215686 green:0.0 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"darksalmon"]) {
        return [NSColor colorWithDeviceRed:0.913725490196078 green:0.588235294117647 blue:0.47843137254902 alpha:1.0];
    } else if ([name isEqualToString:@"darkseagreen"]) {
        return [NSColor colorWithDeviceRed:0.56078431372549 green:0.737254901960784 blue:0.56078431372549 alpha:1.0];
    } else if ([name isEqualToString:@"darkslateblue"]) {
        return [NSColor colorWithDeviceRed:0.282352941176471 green:0.23921568627451 blue:0.545098039215686 alpha:1.0];
    } else if ([name isEqualToString:@"darkslategray"]) {
        return [NSColor colorWithDeviceRed:0.184313725490196 green:0.309803921568627 blue:0.309803921568627 alpha:1.0];
    } else if ([name isEqualToString:@"darkturquoise"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.807843137254902 blue:0.819607843137255 alpha:1.0];
    } else if ([name isEqualToString:@"darkviolet"]) {
        return [NSColor colorWithDeviceRed:0.580392156862745 green:0.0 blue:0.827450980392157 alpha:1.0];
    } else if ([name isEqualToString:@"deeppink"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.0784313725490196 blue:0.576470588235294 alpha:1.0];
    } else if ([name isEqualToString:@"deepskyblue"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.749019607843137 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"dimgray"]) {
        return [NSColor colorWithDeviceRed:0.411764705882353 green:0.411764705882353 blue:0.411764705882353 alpha:1.0];
    } else if ([name isEqualToString:@"dodgerblue"]) {
        return [NSColor colorWithDeviceRed:0.117647058823529 green:0.564705882352941 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"firebrick"]) {
        return [NSColor colorWithDeviceRed:0.698039215686274 green:0.133333333333333 blue:0.133333333333333 alpha:1.0];
    } else if ([name isEqualToString:@"floralwhite"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.980392156862745 blue:0.941176470588235 alpha:1.0];
    } else if ([name isEqualToString:@"forestgreen"]) {
        return [NSColor colorWithDeviceRed:0.133333333333333 green:0.545098039215686 blue:0.133333333333333 alpha:1.0];
    } else if ([name isEqualToString:@"fuchsia"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.0 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"gainsboro"]) {
        return [NSColor colorWithDeviceRed:0.862745098039216 green:0.862745098039216 blue:0.862745098039216 alpha:1.0];
    } else if ([name isEqualToString:@"ghostwhite"]) {
        return [NSColor colorWithDeviceRed:0.972549019607843 green:0.972549019607843 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"gold"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.843137254901961 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"goldenrod"]) {
        return [NSColor colorWithDeviceRed:0.854901960784314 green:0.647058823529412 blue:0.125490196078431 alpha:1.0];
    } else if ([name isEqualToString:@"gray"]) {
        return [NSColor colorWithDeviceRed:0.501960784313725 green:0.501960784313725 blue:0.501960784313725 alpha:1.0];
    } else if ([name isEqualToString:@"green"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.501960784313725 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"greenyellow"]) {
        return [NSColor colorWithDeviceRed:0.67843137254902 green:1.0 blue:0.184313725490196 alpha:1.0];
    } else if ([name isEqualToString:@"honeydew"]) {
        return [NSColor colorWithDeviceRed:0.941176470588235 green:1.0 blue:0.941176470588235 alpha:1.0];
    } else if ([name isEqualToString:@"hotpink"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.411764705882353 blue:0.705882352941177 alpha:1.0];
    } else if ([name isEqualToString:@"indianred "]) {
        return [NSColor colorWithDeviceRed:0.803921568627451 green:0.36078431372549 blue:0.36078431372549 alpha:1.0];
    } else if ([name isEqualToString:@"indigo "]) {
        return [NSColor colorWithDeviceRed:0.294117647058824 green:0.0 blue:0.509803921568627 alpha:1.0];
    } else if ([name isEqualToString:@"ivory"]) {
        return [NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.941176470588235 alpha:1.0];
    } else if ([name isEqualToString:@"khaki"]) {
        return [NSColor colorWithDeviceRed:0.941176470588235 green:0.901960784313726 blue:0.549019607843137 alpha:1.0];
    } else if ([name isEqualToString:@"lavender"]) {
        return [NSColor colorWithDeviceRed:0.901960784313726 green:0.901960784313726 blue:0.980392156862745 alpha:1.0];
    } else if ([name isEqualToString:@"lavenderblush"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.941176470588235 blue:0.96078431372549 alpha:1.0];
    } else if ([name isEqualToString:@"lawngreen"]) {
        return [NSColor colorWithDeviceRed:0.486274509803922 green:0.988235294117647 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"lemonchiffon"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.980392156862745 blue:0.803921568627451 alpha:1.0];
    } else if ([name isEqualToString:@"lightblue"]) {
        return [NSColor colorWithDeviceRed:0.67843137254902 green:0.847058823529412 blue:0.901960784313726 alpha:1.0];
    } else if ([name isEqualToString:@"lightcoral"]) {
        return [NSColor colorWithDeviceRed:0.941176470588235 green:0.501960784313725 blue:0.501960784313725 alpha:1.0];
    } else if ([name isEqualToString:@"lightcyan"]) {
        return [NSColor colorWithDeviceRed:0.87843137254902 green:1.0 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"lightgoldenrodyellow"]) {
        return [NSColor colorWithDeviceRed:0.980392156862745 green:0.980392156862745 blue:0.823529411764706 alpha:1.0];
    } else if ([name isEqualToString:@"lightgray"]) {
        return [NSColor colorWithDeviceRed:0.827450980392157 green:0.827450980392157 blue:0.827450980392157 alpha:1.0];
    } else if ([name isEqualToString:@"lightgreen"]) {
        return [NSColor colorWithDeviceRed:0.564705882352941 green:0.933333333333333 blue:0.564705882352941 alpha:1.0];
    } else if ([name isEqualToString:@"lightpink"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.713725490196078 blue:0.756862745098039 alpha:1.0];
    } else if ([name isEqualToString:@"lightsalmon"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.627450980392157 blue:0.47843137254902 alpha:1.0];
    } else if ([name isEqualToString:@"lightseagreen"]) {
        return [NSColor colorWithDeviceRed:0.125490196078431 green:0.698039215686274 blue:0.666666666666667 alpha:1.0];
    } else if ([name isEqualToString:@"lightskyblue"]) {
        return [NSColor colorWithDeviceRed:0.529411764705882 green:0.807843137254902 blue:0.980392156862745 alpha:1.0];
    } else if ([name isEqualToString:@"lightslategray"]) {
        return [NSColor colorWithDeviceRed:0.466666666666667 green:0.533333333333333 blue:0.6 alpha:1.0];
    } else if ([name isEqualToString:@"lightsteelblue"]) {
        return [NSColor colorWithDeviceRed:0.690196078431373 green:0.768627450980392 blue:0.870588235294118 alpha:1.0];
    } else if ([name isEqualToString:@"lightyellow"]) {
        return [NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.87843137254902 alpha:1.0];
    } else if ([name isEqualToString:@"lime"]) {
        return [NSColor colorWithDeviceRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"limegreen"]) {
        return [NSColor colorWithDeviceRed:0.196078431372549 green:0.803921568627451 blue:0.196078431372549 alpha:1.0];
    } else if ([name isEqualToString:@"linen"]) {
        return [NSColor colorWithDeviceRed:0.980392156862745 green:0.941176470588235 blue:0.901960784313726 alpha:1.0];
    } else if ([name isEqualToString:@"magenta"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.0 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"maroon"]) {
        return [NSColor colorWithDeviceRed:0.501960784313725 green:0.0 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"mediumaquamarine"]) {
        return [NSColor colorWithDeviceRed:0.4 green:0.803921568627451 blue:0.666666666666667 alpha:1.0];
    } else if ([name isEqualToString:@"mediumblue"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.803921568627451 alpha:1.0];
    } else if ([name isEqualToString:@"mediumorchid"]) {
        return [NSColor colorWithDeviceRed:0.729411764705882 green:0.333333333333333 blue:0.827450980392157 alpha:1.0];
    } else if ([name isEqualToString:@"mediumpurple"]) {
        return [NSColor colorWithDeviceRed:0.576470588235294 green:0.43921568627451 blue:0.858823529411765 alpha:1.0];
    } else if ([name isEqualToString:@"mediumseagreen"]) {
        return [NSColor colorWithDeviceRed:0.235294117647059 green:0.701960784313725 blue:0.443137254901961 alpha:1.0];
    } else if ([name isEqualToString:@"mediumslateblue"]) {
        return [NSColor colorWithDeviceRed:0.482352941176471 green:0.407843137254902 blue:0.933333333333333 alpha:1.0];
    } else if ([name isEqualToString:@"mediumspringgreen"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.980392156862745 blue:0.603921568627451 alpha:1.0];
    } else if ([name isEqualToString:@"mediumturquoise"]) {
        return [NSColor colorWithDeviceRed:0.282352941176471 green:0.819607843137255 blue:0.8 alpha:1.0];
    } else if ([name isEqualToString:@"mediumvioletred"]) {
        return [NSColor colorWithDeviceRed:0.780392156862745 green:0.0823529411764706 blue:0.52156862745098 alpha:1.0];
    } else if ([name isEqualToString:@"midnightblue"]) {
        return [NSColor colorWithDeviceRed:0.0980392156862745 green:0.0980392156862745 blue:0.43921568627451 alpha:1.0];
    } else if ([name isEqualToString:@"mintcream"]) {
        return [NSColor colorWithDeviceRed:0.96078431372549 green:1.0 blue:0.980392156862745 alpha:1.0];
    } else if ([name isEqualToString:@"mistyrose"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.894117647058824 blue:0.882352941176471 alpha:1.0];
    } else if ([name isEqualToString:@"moccasin"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.894117647058824 blue:0.709803921568627 alpha:1.0];
    } else if ([name isEqualToString:@"navajowhite"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.870588235294118 blue:0.67843137254902 alpha:1.0];
    } else if ([name isEqualToString:@"navy"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.501960784313725 alpha:1.0];
    } else if ([name isEqualToString:@"oldlace"]) {
        return [NSColor colorWithDeviceRed:0.992156862745098 green:0.96078431372549 blue:0.901960784313726 alpha:1.0];
    } else if ([name isEqualToString:@"olive"]) {
        return [NSColor colorWithDeviceRed:0.501960784313725 green:0.501960784313725 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"olivedrab"]) {
        return [NSColor colorWithDeviceRed:0.419607843137255 green:0.556862745098039 blue:0.137254901960784 alpha:1.0];
    } else if ([name isEqualToString:@"orange"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.647058823529412 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"orangered"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.270588235294118 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"orchid"]) {
        return [NSColor colorWithDeviceRed:0.854901960784314 green:0.43921568627451 blue:0.83921568627451 alpha:1.0];
    } else if ([name isEqualToString:@"palegoldenrod"]) {
        return [NSColor colorWithDeviceRed:0.933333333333333 green:0.909803921568627 blue:0.666666666666667 alpha:1.0];
    } else if ([name isEqualToString:@"palegreen"]) {
        return [NSColor colorWithDeviceRed:0.596078431372549 green:0.984313725490196 blue:0.596078431372549 alpha:1.0];
    } else if ([name isEqualToString:@"paleturquoise"]) {
        return [NSColor colorWithDeviceRed:0.686274509803922 green:0.933333333333333 blue:0.933333333333333 alpha:1.0];
    } else if ([name isEqualToString:@"palevioletred"]) {
        return [NSColor colorWithDeviceRed:0.858823529411765 green:0.43921568627451 blue:0.576470588235294 alpha:1.0];
    } else if ([name isEqualToString:@"papayawhip"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.937254901960784 blue:0.835294117647059 alpha:1.0];
    } else if ([name isEqualToString:@"peachpuff"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.854901960784314 blue:0.725490196078431 alpha:1.0];
    } else if ([name isEqualToString:@"peru"]) {
        return [NSColor colorWithDeviceRed:0.803921568627451 green:0.52156862745098 blue:0.247058823529412 alpha:1.0];
    } else if ([name isEqualToString:@"pink"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.752941176470588 blue:0.796078431372549 alpha:1.0];
    } else if ([name isEqualToString:@"plum"]) {
        return [NSColor colorWithDeviceRed:0.866666666666667 green:0.627450980392157 blue:0.866666666666667 alpha:1.0];
    } else if ([name isEqualToString:@"powderblue"]) {
        return [NSColor colorWithDeviceRed:0.690196078431373 green:0.87843137254902 blue:0.901960784313726 alpha:1.0];
    } else if ([name isEqualToString:@"purple"]) {
        return [NSColor colorWithDeviceRed:0.501960784313725 green:0.0 blue:0.501960784313725 alpha:1.0];
    } else if ([name isEqualToString:@"rebeccapurple"]) {
        return [NSColor colorWithDeviceRed:0.4 green:0.2 blue:0.6 alpha:1.0];
    } else if ([name isEqualToString:@"red"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"rosybrown"]) {
        return [NSColor colorWithDeviceRed:0.737254901960784 green:0.56078431372549 blue:0.56078431372549 alpha:1.0];
    } else if ([name isEqualToString:@"royalblue"]) {
        return [NSColor colorWithDeviceRed:0.254901960784314 green:0.411764705882353 blue:0.882352941176471 alpha:1.0];
    } else if ([name isEqualToString:@"saddlebrown"]) {
        return [NSColor colorWithDeviceRed:0.545098039215686 green:0.270588235294118 blue:0.0745098039215686 alpha:1.0];
    } else if ([name isEqualToString:@"salmon"]) {
        return [NSColor colorWithDeviceRed:0.980392156862745 green:0.501960784313725 blue:0.447058823529412 alpha:1.0];
    } else if ([name isEqualToString:@"sandybrown"]) {
        return [NSColor colorWithDeviceRed:0.956862745098039 green:0.643137254901961 blue:0.376470588235294 alpha:1.0];
    } else if ([name isEqualToString:@"seagreen"]) {
        return [NSColor colorWithDeviceRed:0.180392156862745 green:0.545098039215686 blue:0.341176470588235 alpha:1.0];
    } else if ([name isEqualToString:@"seashell"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.96078431372549 blue:0.933333333333333 alpha:1.0];
    } else if ([name isEqualToString:@"sienna"]) {
        return [NSColor colorWithDeviceRed:0.627450980392157 green:0.32156862745098 blue:0.176470588235294 alpha:1.0];
    } else if ([name isEqualToString:@"silver"]) {
        return [NSColor colorWithDeviceRed:0.752941176470588 green:0.752941176470588 blue:0.752941176470588 alpha:1.0];
    } else if ([name isEqualToString:@"skyblue"]) {
        return [NSColor colorWithDeviceRed:0.529411764705882 green:0.807843137254902 blue:0.92156862745098 alpha:1.0];
    } else if ([name isEqualToString:@"slateblue"]) {
        return [NSColor colorWithDeviceRed:0.415686274509804 green:0.352941176470588 blue:0.803921568627451 alpha:1.0];
    } else if ([name isEqualToString:@"slategray"]) {
        return [NSColor colorWithDeviceRed:0.43921568627451 green:0.501960784313725 blue:0.564705882352941 alpha:1.0];
    } else if ([name isEqualToString:@"snow"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.980392156862745 blue:0.980392156862745 alpha:1.0];
    } else if ([name isEqualToString:@"springgreen"]) {
        return [NSColor colorWithDeviceRed:0.0 green:1.0 blue:0.498039215686275 alpha:1.0];
    } else if ([name isEqualToString:@"steelblue"]) {
        return [NSColor colorWithDeviceRed:0.274509803921569 green:0.509803921568627 blue:0.705882352941177 alpha:1.0];
    } else if ([name isEqualToString:@"tan"]) {
        return [NSColor colorWithDeviceRed:0.823529411764706 green:0.705882352941177 blue:0.549019607843137 alpha:1.0];
    } else if ([name isEqualToString:@"teal"]) {
        return [NSColor colorWithDeviceRed:0.0 green:0.501960784313725 blue:0.501960784313725 alpha:1.0];
    } else if ([name isEqualToString:@"thistle"]) {
        return [NSColor colorWithDeviceRed:0.847058823529412 green:0.749019607843137 blue:0.847058823529412 alpha:1.0];
    } else if ([name isEqualToString:@"tomato"]) {
        return [NSColor colorWithDeviceRed:1.0 green:0.388235294117647 blue:0.27843137254902 alpha:1.0];
    } else if ([name isEqualToString:@"turquoise"]) {
        return [NSColor colorWithDeviceRed:0.250980392156863 green:0.87843137254902 blue:0.815686274509804 alpha:1.0];
    } else if ([name isEqualToString:@"violet"]) {
        return [NSColor colorWithDeviceRed:0.933333333333333 green:0.509803921568627 blue:0.933333333333333 alpha:1.0];
    } else if ([name isEqualToString:@"wheat"]) {
        return [NSColor colorWithDeviceRed:0.96078431372549 green:0.870588235294118 blue:0.701960784313725 alpha:1.0];
    } else if ([name isEqualToString:@"white"]) {
        return [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    } else if ([name isEqualToString:@"whitesmoke"]) {
        return [NSColor colorWithDeviceRed:0.96078431372549 green:0.96078431372549 blue:0.96078431372549 alpha:1.0];
    } else if ([name isEqualToString:@"yellow"]) {
        return [NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.0 alpha:1.0];
    } else if ([name isEqualToString:@"yellowgreen"]) {
        return [NSColor colorWithDeviceRed:0.603921568627451 green:0.803921568627451 blue:0.196078431372549 alpha:1.0];
    } else {
        return nil;
    }
}

@end
