#import "NSColorWell-Extension.h"

@implementation NSColorWell (Extension)
- (void)saveColorToMutableDictionary:(NSMutableDictionary*)dictionary
{
    dictionary[self.description] = self.color;
}

- (void)restoreColorFromDictionary:(NSDictionary*)dictionary
{
    if ([dictionary.allKeys containsObject:self.description]) {
        self.color = (NSColor*)(dictionary[self.description]);
    }
}

@end
