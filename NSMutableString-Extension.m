#import "NSMutableString-Extension.h"

@implementation NSMutableString (Extension)
- (NSMutableString*)replaceYenWithBackSlash
{
	NSString* yenMark = @"\xC2\xA5";
	NSString* backslash = @"\x5C";
	
	// 円マーク (0xC20xA5) をバックスラッシュ（0x5C）に置換
	[self replaceOccurrencesOfString:yenMark withString:backslash options:0 range:NSMakeRange(0, self.length)];
	return self;
}
@end
