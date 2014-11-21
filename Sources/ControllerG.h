#import <Cocoa/Cocoa.h>
#import "Converter.h"

typedef enum  {
	FLASH, SOLID, NOHIGHLIGHT
} HighlightPattern;

@interface ControllerG : NSObject<OutputController>
- (void)adoptProfile:(NSDictionary*)aProfile;
- (NSMutableDictionary*)currentProfile;
@end
