#import <Foundation/Foundation.h>

@interface NSString (Normalization)
- (NSString*)normalizedStringWithModifiedNFC;
- (NSString*)normalizedStringWithModifiedNFD;
- (NSString*)normalizedStringWithNFKC_CF;
@end
