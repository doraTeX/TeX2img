#import <Foundation/Foundation.h>

@interface NSString (Extension)
- (NSString*)pathStringByAppendingPageNumber:(NSUInteger)page;
- (NSString*)stringByDeletingLastReturnCharacters;
- (NSString*)programPath;
- (NSString*)programName;
- (NSString*)argumentsString;
- (NSString*)stringByAppendingStringSeparetedBySpace:(NSString*)string;
+ (NSString*)stringWithAutoEncodingDetectionOfData:(NSData*)data detectedEncoding:(NSStringEncoding*)encoding;
@end
