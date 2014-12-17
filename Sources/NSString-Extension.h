#import <Foundation/Foundation.h>

@interface NSString (Extension)
- (NSString*)pathStringByAppendingPageNumber:(NSUInteger)page;
+ (NSString*)stringWithAutoEncodingDetectionOfData:(NSData *)data;
@end
