#import "NSString-Extension.h"

#define COMPOSITION_EXCLUSION_REGEX @"([\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}]*)([^\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}]+)([\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}]*)"

@implementation NSString (Extension)
- (NSString*)programPath
{
    return [self componentsSeparatedByString:@" "][0];
}

- (NSString*)programName
{
    return self.programPath.lastPathComponent;
}

- (NSString*)argumentsString
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self componentsSeparatedByString:@" "]];
    [array removeObjectAtIndex:0];
    return [array componentsJoinedByString:@" "];
}


- (NSString*)pathStringByAppendingPageNumber:(NSUInteger)page
{
    NSString *dir = self.stringByDeletingLastPathComponent;
    NSString *basename = self.lastPathComponent.stringByDeletingPathExtension;
    NSString *ext = self.pathExtension;
    return [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%lu.%@", basename, page, ext]];
}

- (NSString*)stringByAppendingStringSeparetedBySpace:(NSString*)string
{
    return [string isEqualToString:@""] ? self : [NSString stringWithFormat:@"%@ %@", self, string];
}

- (NSString*)stringByDeletingLastReturnCharacters
{
    NSRegularExpression *regex = [NSRegularExpression.alloc initWithPattern:@"^(.*?)(?:\\r|\\n|\\r\\n)*$" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    if (match) {
        return [self substringWithRange:[match rangeAtIndex:1]];
    } else {
        return self;
    }
}

- (NSUInteger)numberOfComposedCharacters
{
    // normalize using NFC
    NSString *string = self.precomposedStringWithCanonicalMapping;
    
    // count composed chars
    __block NSUInteger count = 0;
    __block BOOL isRegionalIndicator = NO;
    NSRange regionalIndicatorRange = NSMakeRange(0xDDE6, 0xDDFF - 0xDDE6 + 1);
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length)
                               options:NSStringEnumerationByComposedCharacterSequences | NSStringEnumerationSubstringNotRequired
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
         // skip if the last composed character was a regional indicator surrogate-pair
         // 'Cause the so-called national flag emojis consist of two such surrogate pairs
         // and the first one is already counted in the last loop.
         // (To simplify the process, we don't check whether this character is also a regional indicator.)
         if (isRegionalIndicator) {
             isRegionalIndicator = NO;
             return;
         }
         
         // detect regional surrogate pair.
         if ((substringRange.length == 2) &&
             (NSLocationInRange([string characterAtIndex:substringRange.location + 1], regionalIndicatorRange))) {
             isRegionalIndicator = YES;
         }
         
         count++;
     }];
    
    return count;
}

- (NSString*)unicodeName
{
    NSMutableString *mutableUnicodeName = self.mutableCopy;
    CFStringTransform((__bridge CFMutableStringRef)mutableUnicodeName, NULL, CFSTR("Any-Name"), NO);
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{(.+?)\\}" options:0 error:nil];
    NSTextCheckingResult *firstMatch = [regex firstMatchInString:mutableUnicodeName
                                                         options:0
                                                           range:NSMakeRange(0, mutableUnicodeName.length)];
    return [mutableUnicodeName substringWithRange:[firstMatch rangeAtIndex:1]];
}

- (NSString*)normalizedStringWithModifiedNFC
{
    NSString *pattern = COMPOSITION_EXCLUSION_REGEX;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                            options:0
                                                                              error:nil];
    NSMutableString *result = NSMutableString.string;
    [regexp enumerateMatchesInString:self
                             options:0
                               range:NSMakeRange(0, self.length)
                          usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                              [result appendFormat:@"%@%@%@",
                               [self substringWithRange:[match rangeAtIndex:1]],
                               [self substringWithRange:[match rangeAtIndex:2]].precomposedStringWithCanonicalMapping,
                               [self substringWithRange:[match rangeAtIndex:3]]
                               ];
                          }];
    return result;
}

- (NSString*)normalizedStringWithModifiedNFD
{
    NSString *pattern = COMPOSITION_EXCLUSION_REGEX;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                            options:0
                                                                              error:nil];
    NSMutableString *result = NSMutableString.string;
    [regexp enumerateMatchesInString:self
                             options:0
                               range:NSMakeRange(0, self.length)
                          usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                              [result appendFormat:@"%@%@%@",
                               [self substringWithRange:[match rangeAtIndex:1]],
                               [self substringWithRange:[match rangeAtIndex:2]].decomposedStringWithCanonicalMapping,
                               [self substringWithRange:[match rangeAtIndex:3]]
                               ];
                          }];
    return result;
}


+ (NSString*)stringWithUTF32Char:(UTF32Char)character
{
    character = NSSwapHostIntToLittle(character);
    return [NSString.alloc initWithBytes:&character length:4 encoding:NSUTF32LittleEndianStringEncoding];
}


// データから指定エンコードで文字列を得る
// CotEditor の CEDocument.m より借用
+ (NSString*)stringWithAutoEncodingDetectionOfData:(NSData*)data detectedEncoding:(NSStringEncoding*)encoding
{
    NSString *string = nil;
    BOOL shouldSkipISO2022JP = NO;
    BOOL shouldSkipUTF8 = NO;
    BOOL shouldSkipUTF16 = NO;
    *encoding = 0;
    
    CFStringEncodings const StringEncodingList[] = {
        kCFStringEncodingUTF8, // Unicode (UTF-8)
        kCFStringEncodingInvalidId, // ----------
        
        kCFStringEncodingShiftJIS, // Japanese (Shift JIS)
        kCFStringEncodingEUC_JP, // Japanese (EUC)
        kCFStringEncodingDOSJapanese, // Japanese (Windows, DOS)
        kCFStringEncodingShiftJIS_X0213, // Japanese (Shift JIS X0213)
        kCFStringEncodingMacJapanese, // Japanese (Mac OS)
        kCFStringEncodingISO_2022_JP, // Japanese (ISO 2022-JP)
        kCFStringEncodingInvalidId, // ----------
        
        kCFStringEncodingUnicode, // Unicode (UTF-16), kCFStringEncodingUTF16(in 10.4)
        kCFStringEncodingInvalidId, // ----------
        
        kCFStringEncodingMacRoman, // Western (Mac OS Roman)
        kCFStringEncodingWindowsLatin1, // Western (Windows Latin 1)
        kCFStringEncodingInvalidId, // ----------
        
        kCFStringEncodingGB_18030_2000,  // Chinese (GB18030)
        kCFStringEncodingBig5_HKSCS_1999,  // Traditional Chinese (Big 5 HKSCS)
        kCFStringEncodingBig5_E,  // Traditional Chinese (Big 5-E)
        kCFStringEncodingBig5,  // Traditional Chinese (Big 5)
        kCFStringEncodingMacChineseTrad, // Traditional Chinese (Mac OS)
        kCFStringEncodingMacChineseSimp, // Simplified Chinese (Mac OS)
        kCFStringEncodingEUC_TW,  // Traditional Chinese (EUC)
        kCFStringEncodingEUC_CN,  // Simplified Chinese (EUC)
        kCFStringEncodingDOSChineseTrad,  // Traditional Chinese (Windows, DOS)
        kCFStringEncodingDOSChineseSimplif,  // Simplified Chinese (Windows, DOS)
        kCFStringEncodingInvalidId, // ----------
        
        kCFStringEncodingMacKorean, // Korean (Mac OS)
        kCFStringEncodingEUC_KR,  // Korean (EUC)
        kCFStringEncodingDOSKorean,  // Korean (Windows, DOS)
        kCFStringEncodingInvalidId, // ----------
        
        kCFStringEncodingMacArabic, // Arabic (Mac OS)
        kCFStringEncodingMacHebrew, // Hebrew (Mac OS)
        kCFStringEncodingMacGreek, // Greek (Mac OS)
        kCFStringEncodingISOLatinGreek, // Greek (ISO 8859-7)
        kCFStringEncodingMacCyrillic, // Cyrillic (Mac OS)
        kCFStringEncodingISOLatinCyrillic, // Cyrillic (ISO 8859-5)
        kCFStringEncodingMacCentralEurRoman, // Central European (Mac OS)
        kCFStringEncodingMacTurkish, // Turkish (Mac OS)
        kCFStringEncodingMacIcelandic, // Icelandic (Mac OS)
        kCFStringEncodingInvalidId, // ----------
        
        kCFStringEncodingISOLatin1, // Western (ISO Latin 1)
        kCFStringEncodingISOLatin2, // Central European (ISO Latin 2)
        kCFStringEncodingISOLatin3, // Western (ISO Latin 3)
        kCFStringEncodingISOLatin4, // Central European (ISO Latin 4)
        kCFStringEncodingISOLatin5, // Turkish (ISO Latin 5)
        kCFStringEncodingDOSLatinUS, // Latin-US (DOS)
        kCFStringEncodingWindowsLatin2, // Central European (Windows Latin 2)
        kCFStringEncodingNextStepLatin, // Western (NextStep)
        kCFStringEncodingASCII,  // Western (ASCII)
        kCFStringEncodingNonLossyASCII, // Non-lossy ASCII
        kCFStringEncodingInvalidId, // ----------
        
        // Encodings available 10.4 and later (CotEditor added in 0.8.0)
        kCFStringEncodingUTF16BE, // Unicode (UTF-16BE)
        kCFStringEncodingUTF16LE, // Unicode (UTF-16LE)
        kCFStringEncodingUTF32, // Unicode (UTF-32)
        kCFStringEncodingUTF32BE, // Unicode (UTF-32BE)
        kCFStringEncodingUTF32LE, // Unicode (UTF-16LE)
    };
    NSUInteger const kSizeOfCFStringEncodingList = sizeof(StringEncodingList)/sizeof(CFStringEncodings);
    
    if (data.length > 0) {
        const char utf8Bom[] = {0xef, 0xbb, 0xbf}; // UTF-8 BOM
        // BOM付きUTF-8判定
        if (memchr(data.bytes, *utf8Bom, 3) != NULL) {
            shouldSkipUTF8 = YES;
            string = [NSString.alloc initWithData:data encoding:NSUTF8StringEncoding];
            if (string) {
                *encoding = NSUTF8StringEncoding;
            }
            // UTF-16判定
        } else if ((memchr(data.bytes, 0xfffe, 2) != NULL) || (memchr(data.bytes, 0xfeff, 2) != NULL)) {
            shouldSkipUTF16 = YES;
            string = [NSString.alloc initWithData:data encoding:NSUnicodeStringEncoding];
            if (string) {
                *encoding = NSUnicodeStringEncoding;
            }
            // ISO 2022-JP判定
        } else if (memchr(data.bytes, 0x1b, data.length) != NULL) {
            shouldSkipISO2022JP = YES;
            string = [NSString.alloc initWithData:data encoding:NSISO2022JPStringEncoding];
            if (string) {
                *encoding = NSISO2022JPStringEncoding;
            }
        }
    }
    
    if (!string) {
        for (NSUInteger i=0; i<kSizeOfCFStringEncodingList; i++) {
            *encoding = CFStringConvertEncodingToNSStringEncoding(StringEncodingList[i]);
            if ((*encoding == NSISO2022JPStringEncoding) && shouldSkipISO2022JP) {
                break;
            } else if ((*encoding == NSUTF8StringEncoding) && shouldSkipUTF8) {
                break;
            } else if ((*encoding == NSUnicodeStringEncoding) && shouldSkipUTF16) {
                break;
            } else if (*encoding == NSProprietaryStringEncoding) {
                break;
            }
            string = [NSString.alloc initWithData:data encoding:*encoding];
            if (string) {
                break;
            }
        }
    }
    
    return string;
}

@end
