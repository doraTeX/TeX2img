#import <Cocoa/Cocoa.h>
#import "ControllerG.h"
@class ControllerG;

@interface ProfileController : NSObject {
	NSMutableArray *profiles;
	NSMutableArray *profileNames;
	IBOutlet NSWindow *profilesWindow;
    IBOutlet NSTableView *profilesTableView;
    IBOutlet NSTextField *saveAsTextField;
	IBOutlet ControllerG *controllerG;
}
- (void)initProfiles;
- (void)loadProfilesFromPlist;
- (void)removeProfileForName:(NSString*)profileName;
- (NSMutableDictionary*)profileForName:(NSString*)profileName;
- (void)updateProfile:(NSDictionary*)aProfile forName:(NSString*)profileName;
- (void)saveProfiles;
- (IBAction)addProfile:(id)sender;
- (IBAction)loadProfile:(id)sender;
- (IBAction)removeProfile:(id)sender;
- (void)showProfileWindow;
@end
