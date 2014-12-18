#import <Foundation/Foundation.h>

@interface NSString (Extension)
- (NSString*)pathStringByAppendingPageNumber:(NSUInteger)page;
- (NSString*)stringByDeletingLastReturnCharacters;
+ (NSString*)stringWithAutoEncodingDetectionOfData:(NSData *)data detectedEncoding:(NSStringEncoding*)encoding;
@end
