#import <Cocoa/Cocoa.h>
#import "ControllerG.h"
@class ControllerG;

@interface ProfileController : NSObject
- (void)initProfiles;
- (void)loadProfilesFromPlist;
- (void)removeProfileForName:(NSString*)profileName;
- (NSMutableDictionary<NSString*,id>*)profileForName:(NSString*)profileName;
- (void)updateProfile:(NSDictionary<NSString*,id>*)aProfile forName:(NSString*)profileName;
- (void)saveProfiles;
- (void)showProfileWindow;
@end
