#import <Cocoa/Cocoa.h>
#import "ControllerG.h"
@class ControllerG;

@interface ProfileController : NSObject
- (void)initProfiles;
- (void)loadProfilesFromPlist;
- (void)removeProfileForName:(NSString*)profileName;
- (NSMutableDictionary*)profileForName:(NSString*)profileName;
- (void)updateProfile:(NSDictionary*)aProfile forName:(NSString*)profileName;
- (void)saveProfiles;
- (void)showProfileWindow;
@end
