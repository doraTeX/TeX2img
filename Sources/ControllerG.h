#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>
#import "Converter.h"
#import "ProfileController.h"

@class TeXTextView;

@protocol DnDDelegate <NSObject>
- (void)textViewDroppedFile:(id)file;
@end

typedef enum  {
	FLASH = 0,
    SOLID = 1,
    NOHIGHLIGHT = 2
} HighlightPattern;

@interface ControllerG : NSObject<OutputController, DnDDelegate, UNUserNotificationCenterDelegate, NSUserNotificationCenterDelegate>
- (void)adoptProfile:(Profile*)aProfile;
- (MutableProfile*)currentProfile;
- (NSString*)spaceCharacter;
- (NSString*)fullwidthSpaceCharacter;
- (NSString*)returnCharacter;
- (NSString*)tabCharacter;
- (BOOL)importSourceFromFilePathOrPDFDocument:(id)input skipConfirm:(BOOL)skipConfirm;
@property (nonatomic, strong) IBOutlet TeXTextView *sourceTextView;
@property (nonatomic, copy) NSMutableString *commandCompletionList;
@end
