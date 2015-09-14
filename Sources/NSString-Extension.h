#import <Foundation/Foundation.h>

@interface NSString (Extension)
+ (NSString*)UUIDString;
- (NSString*)pathStringByAppendingPageNumber:(NSUInteger)page;
- (NSString*)stringByDeletingLastReturnCharacters;
- (NSString*)stringByQuotingWithDoubleQuotations;
- (NSString*)programPath;
- (NSString*)programName;
- (NSString*)argumentsString;
- (NSString*)stringByAppendingStringSeparetedBySpace:(NSString*)string;
- (NSUInteger)numberOfComposedCharacters;
- (NSString*)unicodeName;
+ (NSString*)stringWithUTF32Char:(UTF32Char)character;
+ (NSString*)stringWithAutoEncodingDetectionOfData:(NSData*)data detectedEncoding:(NSStringEncoding*)encoding;
@end
