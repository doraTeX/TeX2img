#import <Cocoa/Cocoa.h>
#import "global.h"
#import "ControllerG.h"

@interface ProfileController : NSObject
- (void)initProfiles;
- (void)loadProfilesFromPlist;
- (void)removeProfileForName:(NSString*)profileName;
- (MutableProfile*)profileForName:(NSString*)profileName;
- (void)updateProfile:(Profile*)aProfile forName:(NSString*)profileName;
- (void)saveProfiles;
- (void)showProfileWindow;
@end
