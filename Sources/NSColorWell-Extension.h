#import <Cocoa/Cocoa.h>

@interface NSColorWell (Extension)
- (void)saveColorToMutableDictionary:(NSMutableDictionary<NSString*,NSColor*>*)dictionary;
- (void)restoreColorFromDictionary:(NSDictionary<NSString*,NSColor*>*)dictionary;
@end
