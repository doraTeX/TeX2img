#import "NSMutableString-Extension.h"

@implementation NSMutableString (Extension)
- (NSMutableString*)replaceYenWithBackSlash
{
	NSString *yenMark = @"\xC2\xA5";
	NSString *backslash = @"\x5C";
	
	// 円マーク (0xC20xA5) をバックスラッシュ（0x5C）に置換
	[self replaceOccurrencesOfString:yenMark withString:backslash options:0 range:NSMakeRange(0, self.length)];
	return self;
}

- (NSMutableString*)replaceFirstOccuarnceOfString:(NSString*)target replacment:(NSString*)replacement
{
    NSRange range = [self rangeOfString:target];
    if (range.location != NSNotFound) {
        [self replaceCharactersInRange:range withString:replacement];
    }
    return self;
}

- (void)replaceAllOccurrencesOfPattern:(NSString*)pattern withString:(NSString*)replacement
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    
    NSArray<NSTextCheckingResult*> *matches = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    
    NSEnumerator<NSTextCheckingResult*> *enumerator = matches.reverseObjectEnumerator;
    NSTextCheckingResult *match;
    
    while ((match = [enumerator nextObject])) {
        [self replaceCharactersInRange:match.range withString:replacement];
    }
}

- (void)replaceAllOccurrencesOfString:(NSString*)target withString:(NSString*)replacement addingPercentForEndOfLine:(BOOL)addingPercent
{
    if (addingPercent) {
        NSString *src;
        NSString *dest;
        
        src = [NSString stringWithFormat:@"%@\r\n", target];
        dest = [NSString stringWithFormat:@"%@%%\r\n", replacement];
        [self replaceOccurrencesOfString:src withString:dest options:0 range:NSMakeRange(0, self.length)];
        
        src = [NSString stringWithFormat:@"%@\r", target];
        dest = [NSString stringWithFormat:@"%@%%\r", replacement];
        [self replaceOccurrencesOfString:src withString:dest options:0 range:NSMakeRange(0, self.length)];
        
        src = [NSString stringWithFormat:@"%@\n", target];
        dest = [NSString stringWithFormat:@"%@%%\n", replacement];
        [self replaceOccurrencesOfString:src withString:dest options:0 range:NSMakeRange(0, self.length)];
    }
    
    [self replaceOccurrencesOfString:target withString:replacement options:0 range:NSMakeRange(0, self.length)];
}


@end
