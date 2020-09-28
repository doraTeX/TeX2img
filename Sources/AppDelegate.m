#import "AppDelegate.h"
#import "ControllerG.h"

@interface AppDelegate()
@property (nonatomic, strong) IBOutlet ControllerG *controllerG;
@end

@implementation AppDelegate

@synthesize controllerG;

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    return [controllerG importSourceFromFilePathOrPDFDocument:filename skipConfirm:YES];
}
@end
