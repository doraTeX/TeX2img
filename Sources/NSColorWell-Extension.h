#import <Cocoa/Cocoa.h>

@interface NSColorWell (Extension)
- (void)saveColorToMutableDictionary:(NSMutableDictionary*)dictionary;
- (void)restoreColorFromDictionary:(NSDictionary*)dictionary;
@end
