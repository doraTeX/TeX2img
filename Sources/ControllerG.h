#import <Cocoa/Cocoa.h>
#import "Converter.h"

@class TeXTextView;

@protocol DnDDelegate <NSObject>
- (void)textViewDroppedFile:(NSString*)file;
@end

typedef enum  {
	FLASH = 0,
    SOLID = 1,
    NOHIGHLIGHT = 2
} HighlightPattern;

@interface ControllerG : NSObject<OutputController, DnDDelegate>
- (void)adoptProfile:(NSDictionary*)aProfile;
- (NSMutableDictionary*)currentProfile;
@property IBOutlet TeXTextView *sourceTextView;
@end
