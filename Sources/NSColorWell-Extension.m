#import "NSColorWell-Extension.h"

@implementation NSColorWell (Extension)
- (void)saveColorToMutableDictionary:(NSMutableDictionary<NSString*,NSColor*>*)dictionary
{
    dictionary[self.description] = self.color;
}

- (void)restoreColorFromDictionary:(NSDictionary<NSString*,NSColor*>*)dictionary
{
    if ([dictionary.allKeys containsObject:self.description]) {
        self.color = dictionary[self.description];
    }
}

@end
