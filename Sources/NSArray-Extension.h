#import <Cocoa/Cocoa.h>

@interface NSArray (Extension)
- (NSIndexSet*)indexesOfTrueValue;
- (NSArray*)mapUsingBlock:(id (^)(id))block;
@end
