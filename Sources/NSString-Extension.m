#import "NSString-Extension.h"

@implementation NSString (Extension)
- (NSString*)pathStringByAppendingPageNumber:(NSUInteger)page
{
    NSString *dir = self.stringByDeletingLastPathComponent;
    NSString *basename = self.lastPathComponent.stringByDeletingPathExtension;
    NSString *ext = self.pathExtension;
    return [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%lu.%@", basename, page, ext]];
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

// データから指定エンコードで文字列を得る
// CotEditor の CEDocument.m より借用
+ (NSString*)stringWithAutoEncodingDetectionOfData:(NSData *)data
{
    NSString *string = nil;
    BOOL shouldSkipISO2022JP = NO;
    BOOL shouldSkipUTF8 = NO;
    BOOL shouldSkipUTF16 = NO;
    NSStringEncoding encoding = 0;
    
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
                encoding = NSUTF8StringEncoding;
            }
            // UTF-16判定
        } else if ((memchr(data.bytes, 0xfffe, 2) != NULL) || (memchr(data.bytes, 0xfeff, 2) != NULL)) {
            shouldSkipUTF16 = YES;
            string = [NSString.alloc initWithData:data encoding:NSUnicodeStringEncoding];
            if (string) {
                encoding = NSUnicodeStringEncoding;
            }
            // ISO 2022-JP判定
        } else if (memchr(data.bytes, 0x1b, data.length) != NULL) {
            shouldSkipISO2022JP = YES;
            string = [NSString.alloc initWithData:data encoding:NSISO2022JPStringEncoding];
            if (string) {
                encoding = NSISO2022JPStringEncoding;
            }
        }
    }
    
    if (!string) {
        for (NSUInteger i=0; i<kSizeOfCFStringEncodingList; i++) {
            encoding = CFStringConvertEncodingToNSStringEncoding(StringEncodingList[i]);
            if ((encoding == NSISO2022JPStringEncoding) && shouldSkipISO2022JP) {
                break;
            } else if ((encoding == NSUTF8StringEncoding) && shouldSkipUTF8) {
                break;
            } else if ((encoding == NSUnicodeStringEncoding) && shouldSkipUTF16) {
                break;
            } else if (encoding == NSProprietaryStringEncoding) {
                NSLog(@"encoding == NSProprietaryStringEncoding");
                break;
            }
            string = [[NSString alloc] initWithData:data encoding:encoding];
            if (string) {
                break;
            }
        }
    }
    
    return string;
}

@end
