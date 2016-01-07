#import <Foundation/Foundation.h>

@interface NSString (Unicode)
- (NSString*)unicodeName;
- (NSString*)blockName;
- (NSString*)localizedBlockName;
- (NSString*)normalizedStringWithModifiedNFC;
- (NSString*)normalizedStringWithModifiedNFD;
- (NSString*)normalizedStringWithNFKC_CF;
+ (NSString*)controlCharacterNameWithCharacter:(unichar)character;
@end
