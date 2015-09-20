#import <Cocoa/Cocoa.h>

@interface NSArray <__covariant ObjectType> (Extension)
- (NSIndexSet*)indexesOfTrueValue;
- (NSArray*)mapUsingBlock:(id (^)(ObjectType))block;
@end
