#import "NSString-Normalization.h"
#import "unorm2.h"
#import "ustring.h"

#define COMPOSITION_EXCLUSION_REGEX @"([\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}]*)([^\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}]+)([\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}]*)"

#define FACTOR 256

@implementation NSString (Normalization)
- (NSString*)normalizedStringConsideringCompositionExclusionsWithBaseNormalizationSelector:(SEL)aSelector
{
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:COMPOSITION_EXCLUSION_REGEX
                                                                            options:0
                                                                              error:nil];
    NSMutableString *result = NSMutableString.string;
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
    return [self normalizedStringConsideringCompositionExclusionsWithBaseNormalizationSelector:@selector(decomposedStringWithCanonicalMapping)];
}


- (NSString*)normalizedStringWithNFKC_CF
{
    UErrorCode e = U_ZERO_ERROR;

    const UNormalizer2 *normalizer = unorm2_getNFKCCasefoldInstance(&e);
    
    if (U_FAILURE(e)) {
        NSLog(@"unorm2_getNFKCCasefoldInstance failed - %s", u_errorName(e));
        return self;
    }
    
    const char *utf8_src = self.UTF8String;
    unsigned long length = strlen(utf8_src) * FACTOR;
    
    UChar *utf16_src = (UChar*)malloc(sizeof(UChar) * length);
    u_strFromUTF8(utf16_src, length, NULL, utf8_src, -1, &e);

    if (U_FAILURE(e)) {
        NSLog(@"u_strFromUTF8 failed - %s", u_errorName(e));
        free(utf16_src);
        return self;
    }
    
    UChar *utf16_dest = (UChar*)malloc(sizeof(UChar) * length);
    unorm2_normalize(normalizer, utf16_src, -1, utf16_dest, length, &e);
    free(utf16_src);

    if (U_FAILURE(e)) {
        NSLog(@"unorm2_normalize failed - %s", u_errorName(e));
        free(utf16_dest);
        return self;
    }

    char *utf8_dest = (char*)malloc(sizeof(char) * length);
    u_strToUTF8(utf8_dest, length, NULL, utf16_dest, -1, &e);
    free(utf16_dest);

    if (U_FAILURE(e)) {
        NSLog(@"u_strToUTF8 failed - %s", u_errorName(e));
        free(utf8_dest);
        return self;
    }
    
    NSString *result = [NSString stringWithUTF8String:utf8_dest];
    free(utf8_dest);
    return result;
}
@end
