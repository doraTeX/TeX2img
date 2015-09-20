#import <Cocoa/Cocoa.h>
#import "Converter.h"
#import "ProfileController.h"

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
- (void)adoptProfile:(Profile*)aProfile;
- (MutableProfile*)currentProfile;
- (NSString*)spaceCharacter;
- (NSString*)fullwidthSpaceCharacter;
- (NSString*)returnCharacter;
- (NSString*)tabCharacter;
@property (nonatomic, strong) IBOutlet TeXTextView *sourceTextView;
@property (nonatomic, copy) NSMutableString *commandCompletionList;
@end
