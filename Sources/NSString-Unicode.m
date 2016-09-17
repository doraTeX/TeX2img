#import "NSString-Extension.h"
#import "NSString-Unicode.h"
#import "icu/unorm2.h"
#import "icu/ustring.h"
#import "icu/uchar.h"

#define COMPOSITION_EXCLUSION_REGEX @"([\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}]*)([^\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}]+)([\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}]*)"

#define C0_CONTROL_CHAR_NAMES (@[@"NULL",\
@"START OF HEADING",\
@"START OF TEXT",\
@"END OF TEXT",\
@"END OF TRANSMISSION",\
@"ENQUIRY",\
@"ACKNOWLEDGE",\
@"BELL",\
@"BACKSPACE",\
@"HORIZONTAL TABULATION",\
@"LINE FEED",\
@"VERTICAL TABULATION",\
@"FORM FEED",\
@"CARRIAGE RETURN",\
@"SHIFT OUT",\
@"SHIFT IN",\
@"DATA LINK ESCAPE",\
@"DEVICE CONTROL ONE",\
@"DEVICE CONTROL TWO",\
@"DEVICE CONTROL THREE",\
@"DEVICE CONTROL FOUR",\
@"NEGATIVE ACKNOWLEDGE",\
@"SYNCHRONOUS IDLE",\
@"END OF TRANSMISSION BLOCK",\
@"CANCEL",\
@"END OF MEDIUM",\
@"SUBSTITUTE",\
@"ESCAPE",\
@"FILE SEPARATOR",\
@"GROUP SEPARATOR",\
@"RECORD SEPARATOR",\
@"UNIT SEPARATOR",\
@"SPACE"])

#define C1_CONTROL_CHAR_NAMES (@[@"PADDING CHARACTER",\
@"HIGH OCTET PRESET",\
@"BREAK PERMITTED HERE",\
@"NO BREAK HERE",\
@"INDEX",\
@"NEXT LINE",\
@"START OF SELECTED AREA",\
@"END OF SELECTED AREA",\
@"CHARACTER TABULATION SET",\
@"CHARACTER TABULATION WITH JUSTIFICATION",\
@"LINE TABULATION SET",\
@"PARTIAL LINE FORWARD",\
@"PARTIAL LINE BACKWARD",\
@"REVERSE LINE FEED",\
@"SINGLE SHIFT TWO",\
@"SINGLE SHIFT THREE",\
@"DEVICE CONTROL STRING",\
@"PRIVATE USE ONE",\
@"PRIVATE USE TWO",\
@"SET TRANSMIT STATE",\
@"CANCEL CHARACTER",\
@"MESSAGE WAITING",\
@"START OF PROTECTED AREA",\
@"END OF PROTECTED AREA",\
@"START OF STRING",\
@"SINGLE GRAPHIC CHARACTER INTRODUCER",\
@"SINGLE CHARACTER INTRODUCER",\
@"CONTROL SEQUENCE INTRODUCER",\
@"STRING TERMINATOR",\
@"OPERATING SYSTEM COMMAND",\
@"PRIVACY MESSAGE",\
@"APPLICATION PROGRAM COMMAND"])

#define FACTOR 256

@implementation NSString (Unicode)
- (NSString*)unicodeName
{
    NSMutableString *mutableUnicodeName = [self mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)mutableUnicodeName, NULL, CFSTR("Any-Name"), NO);
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{(.+?)\\}" options:0 error:nil];
    NSTextCheckingResult *firstMatch = [regex firstMatchInString:mutableUnicodeName
                                                         options:0
                                                           range:NSMakeRange(0, mutableUnicodeName.length)];
    return [mutableUnicodeName substringWithRange:[firstMatch rangeAtIndex:1]];
}

- (NSString*)blockName
{
    int32_t prop = u_getIntPropertyValue([self utf32char], UCHAR_BLOCK);
    const char *blockNameChars = u_getPropertyValueName(UCHAR_BLOCK, prop, U_LONG_PROPERTY_NAME);
    
    return [@(blockNameChars) stringByReplacingOccurrencesOfString:@"_" withString:@" "];  // sanitize
}

- (NSString*)localizedBlockName
{
    NSString *blockName = self.blockName;
    
    blockName = [NSString sanitizeBlockName:blockName];
    
    return NSLocalizedStringFromTable(blockName, @"UnicodeBlocks", nil);
}

+ (NSString*)sanitizeBlockName:(NSString*)blockName
{
    blockName = [blockName stringByReplacingOccurrencesOfString:@" ([A-Z])$" withString:@"-$1"
                                                        options:NSRegularExpressionSearch range:NSMakeRange(0, blockName.length)];
    blockName = [blockName stringByReplacingOccurrencesOfString:@"Extension-" withString:@"Ext. "];
    blockName = [blockName stringByReplacingOccurrencesOfString:@" And " withString:@" and "];
    blockName = [blockName stringByReplacingOccurrencesOfString:@" For " withString:@" for "];
    blockName = [blockName stringByReplacingOccurrencesOfString:@" Mathematical " withString:@" Math "];
    blockName = [blockName stringByReplacingOccurrencesOfString:@"Latin 1" withString:@"Latin-1"];
    
    return blockName;
}

- (NSString*)normalizedStringConsideringCompositionExclusionsWithBaseNormalizationSelector:(SEL)aSelector
{
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:COMPOSITION_EXCLUSION_REGEX
                                                                            options:0
                                                                              error:nil];
    NSMutableString *result = [NSMutableString string];
    [regexp enumerateMatchesInString:self
                             options:0
                               range:NSMakeRange(0, self.length)
                          usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                              [result appendFormat:@"%@%@%@",
                               [self substringWithRange:[match rangeAtIndex:1]],
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                               (NSString*)[[self substringWithRange:[match rangeAtIndex:2]] performSelector:aSelector],
#pragma clang diagnostic pop
                               [self substringWithRange:[match rangeAtIndex:3]]
                               ];
                          }];
    return result;
}

- (NSString*)normalizedStringWithModifiedNFC
{
    return [self normalizedStringConsideringCompositionExclusionsWithBaseNormalizationSelector:@selector(precomposedStringWithCanonicalMapping)];
}

- (NSString*)normalizedStringWithModifiedNFD
{
    CFStringRef sourceStr = (__bridge CFStringRef)self;
    CFIndex length = CFStringGetMaximumSizeOfFileSystemRepresentation(sourceStr);
    char *destStr = (char*)malloc(length);
    Boolean success = CFStringGetFileSystemRepresentation(sourceStr, destStr, length);
    NSString *result = success ? [NSString stringWithUTF8String:destStr] : self;
    free(destStr);
    return result;
}


- (NSString*)normalizedStringWithNFKC_CF
{
    UErrorCode error = U_ZERO_ERROR;

    const UNormalizer2 *normalizer = unorm2_getInstance(NULL, "nfkc_cf", UNORM2_COMPOSE, &error);
    
    if (U_FAILURE(error)) {
        NSLog(@"unorm2_getInstance failed - %s", u_errorName(error));
        return self;
    }
    
    const char *utf8_src = self.UTF8String;
    int length = (int)(strlen(utf8_src) * FACTOR);
    
    UChar *utf16_src = (UChar*)malloc(sizeof(UChar) * length);
    u_strFromUTF8(utf16_src, length, NULL, utf8_src, -1, &error);

    if (U_FAILURE(error)) {
        NSLog(@"u_strFromUTF8 failed - %s", u_errorName(error));
        free(utf16_src);
        return self;
    }
    
    UChar *utf16_dest = (UChar*)malloc(sizeof(UChar) * length);
    unorm2_normalize(normalizer, utf16_src, -1, utf16_dest, length, &error);
    free(utf16_src);

    if (U_FAILURE(error)) {
        NSLog(@"unorm2_normalize failed - %s", u_errorName(error));
        free(utf16_dest);
        return self;
    }

    char *utf8_dest = (char*)malloc(sizeof(char) * length);
    u_strToUTF8(utf8_dest, length, NULL, utf16_dest, -1, &error);
    free(utf16_dest);

    if (U_FAILURE(error)) {
        NSLog(@"u_strToUTF8 failed - %s", u_errorName(error));
        free(utf8_dest);
        return self;
    }
    
    NSString *result = [NSString stringWithUTF8String:utf8_dest];
    free(utf8_dest);
    return result;
}


+ (NSString*)controlCharacterNameWithCharacter:(unichar)character
{
    if ((character >= 0x0000) && (character <= 0x0020)) {
        return C0_CONTROL_CHAR_NAMES[character];

    } else if (character == 0x007F) {
        return @"DELETE";
    
    } else if ((character >= 0x0080) && (character <= 0x009F)) {
        return C1_CONTROL_CHAR_NAMES[character - 0x0080];
    }
    
    return nil;
}

@end
