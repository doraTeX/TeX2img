#import <Cocoa/Cocoa.h>

@interface NSMutableString (Extension)
- (NSMutableString*)replaceYenWithBackSlash;
- (NSMutableString*)replaceFirstOccuarnceOfString:(NSString*)target replacment:(NSString*)replacement;
- (void)replaceAllOccurrencesOfPattern:(NSString*)pattern withString:(NSString*)replacement;
- (void)replaceAllOccurrencesOfPattern:(NSString*)pattern usingBlock:(NSString* (^)(NSString*, NSArray<NSString*>*))replace;
- (void)replaceAllOccurrencesOfString:(NSString*)target withString:(NSString*)replacement addingPercentForEndOfLine:(BOOL)addingPercent;
@end
