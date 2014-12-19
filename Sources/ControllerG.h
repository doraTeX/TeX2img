#import <Cocoa/Cocoa.h>
#import "Converter.h"

@class TeXTextView;

@protocol DnDDelegate <NSObject>
- (void)textViewDroppedFile:(NSString*)file;
@end

typedef enum  {
	FLASH, SOLID, NOHIGHLIGHT
} HighlightPattern;

@interface ControllerG : NSObject<OutputController, DnDDelegate>
- (void)adoptProfile:(NSDictionary*)aProfile;
- (NSMutableDictionary*)currentProfile;
@property IBOutlet TeXTextView *sourceTextView;
@end
